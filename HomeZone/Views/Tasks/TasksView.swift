import SwiftUI

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var filter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case done = "Done"
    }
    
    var filtered: [HomeTask] {
        switch filter {
        case .all: return appState.tasks
        case .pending: return appState.tasks.filter { !$0.isCompleted }
        case .done: return appState.tasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Filter", selection: $filter) {
                        ForEach(TaskFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: filter == .done ? "No Completed Tasks" : "No Tasks",
                            subtitle: filter == .done ? "Complete tasks to see them here." : "Add tasks to track insulation fixes and repairs.",
                            buttonTitle: filter == .all ? "Add Task" : nil,
                            action: filter == .all ? { showAdd = true } : nil
                        )
                    } else {
                        List {
                            ForEach(filtered) { task in
                                TaskRowView(task: task)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation { appState.deleteTask(id: task.id) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation { appState.toggleTask(id: task.id) }
                                        } label: {
                                            Label(task.isCompleted ? "Undo" : "Done",
                                                  systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                        }
                                        .tint(task.isCompleted ? DS.warning : DS.success)
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(DS.accent)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

struct TaskRowView: View {
    @EnvironmentObject var appState: AppState
    let task: HomeTask
    
    var body: some View {
        HZCard(padding: 14) {
            HStack(spacing: 12) {
                Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { appState.toggleTask(id: task.id) } }) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? DS.success : DS.border, lineWidth: 2)
                            .frame(width: 28, height: 28)
                        if task.isCompleted {
                            Circle()
                                .fill(DS.success)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(DS.Font.heading(14))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    HStack(spacing: 8) {
                        if !task.roomName.isEmpty {
                            Label(task.roomName, systemImage: "door.left.hand.open")
                                .font(DS.Font.caption(11))
                                .foregroundColor(.secondary)
                        }
                        if let due = task.dueDate {
                            let overdue = due < Date() && !task.isCompleted
                            Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(DS.Font.caption(11))
                                .foregroundColor(overdue ? DS.error : .secondary)
                        }
                    }
                    
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(DS.Font.body(12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Priority dot
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 10, height: 10)
            }
        }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var roomName = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400 * 3)
    @State private var showError = false
    
    var allRooms: [String] {
        appState.projects.flatMap { $0.rooms }.map { $0.name }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task description", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(header: Text("Location")) {
                    Picker("Room", selection: $roomName) {
                        Text("None").tag("")
                        ForEach(allRooms, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: "circle.fill")
                                .foregroundColor(p.color)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set due date", isOn: $hasDueDate)
                        .tint(DS.accent)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                if showError {
                    Section {
                        Label("Please enter a task description.", systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(DS.error)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { showError = true; return }
                        var task = HomeTask(title: t, notes: notes, dueDate: hasDueDate ? dueDate : nil, priority: priority, roomName: roomName)
                        appState.addTask(task)
                        dismiss()
                    }
                    .font(DS.Font.heading(16))
                    .foregroundColor(DS.accent)
                }
            }
        }
    }
}
