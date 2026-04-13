import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var notifStatus = ""
    @State private var savedBanner = false
    
    var selectedScheme: String {
        switch appState.preferredColorScheme {
        case .light: return "light"
        case .dark: return "dark"
        default: return "system"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile section
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(DS.accentGradient)
                                    .frame(width: 44, height: 44)
                                Text(appState.userName.prefix(1).uppercased())
                                    .font(DS.Font.heading(18))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(appState.userName)
                                    .font(DS.Font.heading(15))
                                Text(appState.userEmail)
                                    .font(DS.Font.caption(12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Appearance
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: Binding(
                        get: { selectedScheme },
                        set: { appState.setColorScheme($0) }
                    )) {
                        Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                        Label("Light", systemImage: "sun.max.fill").tag("light")
                        Label("Dark", systemImage: "moon.fill").tag("dark")
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Units
                Section(header: Text("Units")) {
                    Picker("Temperature", selection: Binding(
                        get: { appState.temperatureUnitRaw },
                        set: { appState.temperatureUnitRaw = $0 }
                    )) {
                        ForEach(TemperatureUnit.allCases, id: \.rawValue) { unit in
                            Text(unit.rawValue).tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Notifications
                Section(header: Text("Notifications")) {
                    Toggle(isOn: Binding(
                        get: { appState.notificationsEnabled },
                        set: { appState.toggleNotifications($0) }
                    )) {
                        Label("Enable Notifications", systemImage: "bell.fill")
                    }
                    .tint(DS.accent)
                    
                    Toggle(isOn: Binding(
                        get: { appState.problemAlertEnabled },
                        set: { appState.problemAlertEnabled = $0 }
                    )) {
                        Label("Problem Alerts", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tint(DS.warning)
                    .disabled(!appState.notificationsEnabled)
                    
                    Toggle(isOn: Binding(
                        get: { appState.weeklyReportEnabled },
                        set: { appState.toggleWeeklyReport($0) }
                    )) {
                        Label("Weekly Report", systemImage: "chart.bar.fill")
                    }
                    .tint(DS.accent)
                    .disabled(!appState.notificationsEnabled)
                    
                    if !appState.notificationsEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("Enable notifications to receive alerts.")
                                .font(DS.Font.caption(12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Data
                Section(header: Text("Data")) {
                    NavigationLink(destination: HistoryView()) {
                        Label("Activity History", systemImage: "clock.arrow.circlepath")
                    }
                    Button(action: { appState.logActivity(action: "Demo Data Reloaded", detail: "Sample data restored", icon: "arrow.clockwise") ; appState.loadDemoData() }) {
                        Label("Reload Demo Data", systemImage: "arrow.clockwise")
                            .foregroundColor(DS.accent)
                    }
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("2024.1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Account actions
                Section {
                    Button(action: { showLogoutConfirm = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Log Out")
                        }
                        .foregroundColor(DS.warning)
                    }
                    
                    Button(action: { showDeleteConfirm = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Account")
                        }
                        .foregroundColor(DS.error)
                    }
                }
            }
            .navigationTitle("Settings")
            .overlay(
                savedBanner ? AnyView(
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                            Text("Settings saved").font(DS.Font.heading(14)).foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(DS.success)
                        .cornerRadius(14)
                        .shadow(radius: 10)
                        .padding(.bottom, 100)
                    }
                ) : AnyView(EmptyView())
            )
            .alert("Log Out", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) { appState.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) { appState.deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data including projects, rooms, and measurements. This action cannot be undone.")
            }
        }
        .preferredColorScheme(appState.preferredColorScheme)
    }
    
    func showSavedBanner() {
        withAnimation { savedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedBanner = false }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var saved = false
    
    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(DS.accentGradient)
                                .frame(width: 80, height: 80)
                            Text(appState.userName.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text(appState.userEmail)
                            .font(DS.Font.caption(13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Personal Info")) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $name)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(DS.accent)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    TextField("Email", text: $email)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(DS.accent)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if saved {
                            Label("Saved!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(DS.success)
                        } else {
                            Text("Save Changes")
                                .foregroundColor(DS.accent)
                                .font(DS.Font.heading(15))
                        }
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Stats")) {
                HStack {
                    Label("Projects", systemImage: "folder.fill")
                    Spacer()
                    Text("\(appState.projects.count)").foregroundColor(.secondary)
                }
                HStack {
                    Label("Rooms", systemImage: "door.left.hand.open")
                    Spacer()
                    Text("\(appState.totalRooms)").foregroundColor(.secondary)
                }
                HStack {
                    Label("Measurements", systemImage: "thermometer")
                    Spacer()
                    Text("\(appState.allMeasurements.count)").foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            name = appState.userName
            email = appState.userEmail
        }
    }
    
    func saveProfile() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        appState.userName = n
        appState.userEmail = email.trimmingCharacters(in: .whitespaces)
        appState.logActivity(action: "Profile Updated", detail: "Name changed to \(n)", icon: "person.fill")
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}
