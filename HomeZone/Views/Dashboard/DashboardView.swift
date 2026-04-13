import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 1 ? "folder.fill" : "folder")
                }
                .tag(1)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: selectedTab == 2 ? "checkmark.circle.fill" : "checkmark.circle")
                }
                .tag(2)
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                }
                .tag(4)
        }
        .accentColor(DS.accent)
        .preferredColorScheme(appState.preferredColorScheme)
    }
}

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false
    
    var avgTemp: Double {
        let all = appState.allMeasurements
        guard !all.isEmpty else { return 0 }
        return all.reduce(0) { $0 + $1.temperature } / Double(all.count)
    }
    
    var avgHumidity: Double {
        let all = appState.allMeasurements
        guard !all.isEmpty else { return 0 }
        return all.reduce(0) { $0 + $1.humidity } / Double(all.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(appState.userName.components(separatedBy: " ").first ?? "there") 👋")
                                .font(DS.Font.caption(14))
                                .foregroundColor(.secondary)
                            Text("Home Overview")
                                .font(DS.Font.display(26))
                        }
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            ZStack {
                                Circle()
                                    .fill(DS.accentGradient)
                                    .frame(width: 42, height: 42)
                                Text(appState.userName.prefix(1).uppercased())
                                    .font(DS.Font.heading(18))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -10)
                    
                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(title: "Rooms", value: "\(appState.totalRooms)", icon: "door.left.hand.open", color: DS.accent)
                        StatCard(title: "Problems", value: "\(appState.problemMeasurements.count)", icon: "exclamationmark.triangle.fill", color: DS.error)
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 12) {
                        StatCard(title: "Avg Temp", value: String(format: "%.1f%@", appState.temperatureUnit.convert(avgTemp), appState.temperatureUnit.symbol), icon: "thermometer.medium", color: DS.warm)
                        StatCard(title: "Avg Humidity", value: String(format: "%.0f%%", avgHumidity), icon: "drop.fill", color: DS.mold)
                    }
                    .padding(.horizontal, 20)
                    
                    // Problem zones
                    if !appState.problemMeasurements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "⚠️ Problem Zones")
                            
                            VStack(spacing: 8) {
                                ForEach(appState.problemMeasurements.prefix(3)) { m in
                                    ProblemZoneRow(measurement: m)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                    }
                    
                    // Recent projects
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "📁 Recent Projects")
                        
                        if appState.projects.isEmpty {
                            HZCard {
                                EmptyStateView(icon: "folder.badge.plus", title: "No Projects Yet", subtitle: "Create your first project to start mapping your home.")
                            }
                        } else {
                            VStack(spacing: 10) {
                                ForEach(appState.projects.prefix(3)) { project in
                                    NavigationLink(destination: ProjectDetailView(project: project)) {
                                        ProjectRowCard(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0)
                    
                    // Recent activity
                    if !appState.activityLog.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "🕐 Recent Activity")
                            HZCard(padding: 0) {
                                VStack(spacing: 0) {
                                    ForEach(appState.activityLog.prefix(4)) { entry in
                                        ActivityRow(entry: entry)
                                        if entry.id != appState.activityLog.prefix(4).last?.id {
                                            HZDivider().padding(.leading, 52)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                    }
                    
                    Spacer().frame(height: 20)
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appear = true }
        }
    }
}

struct ProblemZoneRow: View {
    let measurement: MeasurementPoint
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HZCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(measurement.problemType.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: measurement.problemType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(measurement.problemType.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement.label.isEmpty ? "Measurement point" : measurement.label)
                        .font(DS.Font.heading(14))
                    ClimateTag(type: measurement.problemType)
                }
                Spacer()
                TempBadge(value: measurement.temperature, unit: appState.temperatureUnit)
            }
        }
    }
}

struct ActivityRow: View {
    let entry: ActivityEntry
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DS.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.icon)
                    .font(.system(size: 14))
                    .foregroundColor(DS.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.action)
                    .font(DS.Font.heading(13))
                Text(entry.detail)
                    .font(DS.Font.body(12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(entry.timestamp.relativeString)
                .font(DS.Font.caption(11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

extension Date {
    var relativeString: String {
        let diff = Date().timeIntervalSince(self)
        if diff < 3600 { return "\(Int(diff/60))m ago" }
        if diff < 86400 { return "\(Int(diff/3600))h ago" }
        return "\(Int(diff/86400))d ago"
    }
}
