import SwiftUI

// MARK: - ProjectsView
struct ProjectsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProject = false
    @State private var appear = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if appState.projects.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No Projects",
                        subtitle: "Start by creating your first climate mapping project.",
                        buttonTitle: "New Project",
                        action: { showAddProject = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(appState.projects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectRowCard(project: project)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { appState.deleteProject(id: project.id) }
                                    } label: {
                                        Label("Delete Project", systemImage: "trash")
                                    }
                                }
                            }
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(DS.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView()
            }
        }
    }
}

struct ProjectRowCard: View {
    let project: Project
    @EnvironmentObject var appState: AppState
    
    var problemCount: Int {
        project.rooms.flatMap { $0.measurements }.filter { $0.problemType != .normal }.count
    }
    var measureCount: Int {
        project.rooms.flatMap { $0.measurements }.count
    }
    
    var body: some View {
        HZCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.accentGradient)
                            .frame(width: 46, height: 46)
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name)
                            .font(DS.Font.heading(16))
                            .foregroundColor(.primary)
                        Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(DS.Font.caption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    Label("\(project.rooms.count) rooms", systemImage: "door.left.hand.open")
                        .font(DS.Font.caption(12))
                        .foregroundColor(.secondary)
                    Label("\(measureCount) points", systemImage: "thermometer")
                        .font(DS.Font.caption(12))
                        .foregroundColor(.secondary)
                    if problemCount > 0 {
                        Label("\(problemCount) problems", systemImage: "exclamationmark.triangle.fill")
                            .font(DS.Font.caption(12))
                            .foregroundColor(DS.error)
                    }
                }
            }
        }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var notes = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project name", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if showError {
                    Section {
                        Label("Please enter a project name.", systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(DS.error)
                            .font(DS.Font.caption(13))
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { showError = true; return }
                        var project = Project(name: n)
                        project.notes = notes
                        appState.addProject(project)
                        dismiss()
                    }
                    .font(DS.Font.heading(16))
                    .foregroundColor(DS.accent)
                }
            }
        }
    }
}

// MARK: - Project Detail
struct ProjectDetailView: View {
    @EnvironmentObject var appState: AppState
    let project: Project
    @State private var showAddRoom = false
    
    var currentProject: Project {
        appState.projects.first(where: { $0.id == project.id }) ?? project
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if currentProject.rooms.isEmpty {
                EmptyStateView(
                    icon: "door.left.hand.open",
                    title: "No Rooms Yet",
                    subtitle: "Add rooms to start mapping climate zones.",
                    buttonTitle: "Add Room",
                    action: { showAddRoom = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        // Stats header
                        HZCard {
                            HStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    Text("\(currentProject.rooms.count)")
                                        .font(DS.Font.display(24))
                                        .foregroundColor(DS.accent)
                                    Text("Rooms")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                Rectangle().fill(DS.border).frame(width: 1, height: 40)
                                let totalMeasure = currentProject.rooms.flatMap { $0.measurements }.count
                                VStack(spacing: 4) {
                                    Text("\(totalMeasure)")
                                        .font(DS.Font.display(24))
                                        .foregroundColor(DS.warm)
                                    Text("Points")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                Rectangle().fill(DS.border).frame(width: 1, height: 40)
                                let probs = currentProject.rooms.flatMap { $0.measurements }.filter { $0.problemType != .normal }.count
                                VStack(spacing: 4) {
                                    Text("\(probs)")
                                        .font(DS.Font.display(24))
                                        .foregroundColor(probs > 0 ? DS.error : DS.success)
                                    Text("Problems")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        ForEach(currentProject.rooms) { room in
                            NavigationLink(destination: RoomDetailView(room: room, projectID: currentProject.id)) {
                                RoomRowCard(room: room)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    appState.deleteRoom(roomID: room.id, fromProject: currentProject.id)
                                } label: {
                                    Label("Delete Room", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 20)
                    }
                }
            }
        }
        .navigationTitle(currentProject.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddRoom = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(DS.accent)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(projectID: currentProject.id)
        }
    }
}

struct RoomRowCard: View {
    let room: Room
    @EnvironmentObject var appState: AppState
    
    var problemCount: Int { room.measurements.filter { $0.problemType != .normal }.count }
    var avgTemp: Double? {
        guard !room.measurements.isEmpty else { return nil }
        return room.measurements.reduce(0) { $0 + $1.temperature } / Double(room.measurements.count)
    }
    
    var body: some View {
        HZCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DS.indigo.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 22))
                        .foregroundColor(DS.indigo)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(room.name)
                        .font(DS.Font.heading(16))
                        .foregroundColor(.primary)
                    HStack(spacing: 10) {
                        Text("\(room.measurements.count) points")
                            .font(DS.Font.caption(12))
                            .foregroundColor(.secondary)
                        if let avg = avgTemp {
                            TempBadge(value: avg, unit: appState.temperatureUnit)
                        }
                        if problemCount > 0 {
                            Text("\(problemCount) ⚠️")
                                .font(DS.Font.caption(12))
                                .foregroundColor(DS.error)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let projectID: UUID
    @State private var name = ""
    @State private var width = "4.0"
    @State private var height = "3.5"
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Room Details")) {
                    TextField("Room name (e.g. Living Room)", text: $name)
                }
                Section(header: Text("Dimensions (meters)")) {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("4.0", text: $width)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("3.5", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                }
                if showError {
                    Section {
                        Label("Please enter a room name.", systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(DS.error)
                    }
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { showError = true; return }
                        let room = Room(name: n,
                                        width: Double(width) ?? 4.0,
                                        height: Double(height) ?? 3.5)
                        appState.addRoom(room, to: projectID)
                        dismiss()
                    }
                    .foregroundColor(DS.accent)
                    .font(DS.Font.heading(16))
                }
            }
        }
    }
}
