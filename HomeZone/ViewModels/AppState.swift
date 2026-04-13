import SwiftUI
import Combine
import UserNotifications

class AppState: ObservableObject {
    // MARK: - Auth
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    
    // MARK: - Theme
    @AppStorage("colorSchemeRaw") private var colorSchemeRaw: String = "system"
    var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
    func setColorScheme(_ scheme: String) { colorSchemeRaw = scheme }
    
    // MARK: - Settings
    @AppStorage("temperatureUnit") var temperatureUnitRaw: String = TemperatureUnit.celsius.rawValue
    var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }
    
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("weeklyReportEnabled") var weeklyReportEnabled: Bool = false
    @AppStorage("problemAlertEnabled") var problemAlertEnabled: Bool = true
    
    // MARK: - Data
    @Published var projects: [Project] = []
    @Published var tasks: [HomeTask] = []
    @Published var activityLog: [ActivityEntry] = []
    
    // MARK: - Persistence
    private let projectsKey = "hz_projects"
    private let tasksKey = "hz_tasks"
    private let activityKey = "hz_activity"
    
    init() {
        loadData()
    }
    
    // MARK: - Auth
    func loginDemo() {
        let u = User.demo
        userName = u.name
        userEmail = u.email
        isLoggedIn = true
        if projects.isEmpty { loadDemoData() }
    }
    
    func login(name: String, email: String) {
        userName = name
        userEmail = email
        isLoggedIn = true
    }
    
    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
    }
    
    func deleteAccount() {
        logout()
        projects = []
        tasks = []
        activityLog = []
        hasCompletedOnboarding = false
        saveData()
    }
    
    // MARK: - Demo Data
    func loadDemoData() {
        projects = Project.demo()
        tasks = HomeTask.demo()
        activityLog = ActivityEntry.demo()
        saveData()
    }
    
    // MARK: - Projects CRUD
    func addProject(_ project: Project) {
        projects.insert(project, at: 0)
        logActivity(action: "Project Created", detail: "\(project.name) started", icon: "folder.fill")
        saveData()
    }
    
    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        saveData()
    }
    
    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            saveData()
        }
    }
    
    // MARK: - Rooms CRUD
    func addRoom(_ room: Room, to projectID: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == projectID }) {
            projects[idx].rooms.append(room)
            logActivity(action: "Room Added", detail: "\(room.name) added", icon: "plus.circle.fill")
            saveData()
        }
    }
    
    func deleteRoom(roomID: UUID, fromProject projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }) {
            projects[pIdx].rooms.removeAll { $0.id == roomID }
            saveData()
        }
    }
    
    func updateRoom(_ room: Room, inProject projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == room.id }) {
            projects[pIdx].rooms[rIdx] = room
            saveData()
        }
    }
    
    // MARK: - Measurements CRUD
    func addMeasurement(_ point: MeasurementPoint, roomID: UUID, projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomID }) {
            projects[pIdx].rooms[rIdx].measurements.append(point)
            logActivity(action: "Measurement Added", detail: "\(projects[pIdx].rooms[rIdx].name) — \(String(format: "%.1f", point.temperature))°C", icon: "thermometer")
            if point.problemType != .normal {
                scheduleProblemAlert(room: projects[pIdx].rooms[rIdx].name, problem: point.problemType)
            }
            saveData()
        }
    }
    
    func deleteMeasurement(measureID: UUID, roomID: UUID, projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomID }) {
            projects[pIdx].rooms[rIdx].measurements.removeAll { $0.id == measureID }
            saveData()
        }
    }
    
    // MARK: - Tasks CRUD
    func addTask(_ task: HomeTask) {
        tasks.insert(task, at: 0)
        logActivity(action: "Task Created", detail: task.title, icon: "checkmark.circle")
        saveData()
        scheduleTaskReminder(task: task)
    }
    
    func toggleTask(id: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].isCompleted.toggle()
            saveData()
        }
    }
    
    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveData()
    }
    
    func updateTask(_ task: HomeTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            saveData()
        }
    }
    
    // MARK: - Activity Log
    func logActivity(action: String, detail: String, icon: String) {
        let entry = ActivityEntry(action: action, detail: detail, icon: icon)
        activityLog.insert(entry, at: 0)
        if activityLog.count > 100 { activityLog = Array(activityLog.prefix(100)) }
        saveData()
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }
    
    func toggleNotifications(_ enabled: Bool) {
        if enabled {
            requestNotificationPermission()
        } else {
            notificationsEnabled = false
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    func toggleWeeklyReport(_ enabled: Bool) {
        weeklyReportEnabled = enabled
        if enabled { scheduleWeeklyReport() } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        }
    }
    
    private func scheduleWeeklyReport() {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Home Zone Weekly Report"
        content.body = "Your weekly climate report is ready. Tap to view."
        content.sound = .default
        var dc = DateComponents()
        dc.weekday = 2; dc.hour = 9; dc.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: "weekly_report", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    
    private func scheduleProblemAlert(room: String, problem: ProblemType) {
        guard notificationsEnabled && problemAlertEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Problem Detected"
        content.body = "\(problem.rawValue) in \(room). Tap to see recommendations."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    
    private func scheduleTaskReminder(task: HomeTask) {
        guard notificationsEnabled, let due = task.dueDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "📋 Task Reminder"
        content.body = task.title
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: due), repeats: false)
        let req = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    
    // MARK: - Computed helpers
    var allMeasurements: [MeasurementPoint] {
        projects.flatMap { $0.rooms }.flatMap { $0.measurements }
    }
    
    var problemMeasurements: [MeasurementPoint] {
        allMeasurements.filter { $0.problemType != .normal }
    }
    
    var totalRooms: Int { projects.flatMap { $0.rooms }.count }
    
    func rooms(in projectID: UUID) -> [Room] {
        projects.first(where: { $0.id == projectID })?.rooms ?? []
    }
    
    // MARK: - Persistence
    func saveData() {
        if let data = try? JSONEncoder().encode(projects) { UserDefaults.standard.set(data, forKey: projectsKey) }
        if let data = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(data, forKey: tasksKey) }
        if let data = try? JSONEncoder().encode(activityLog) { UserDefaults.standard.set(data, forKey: activityKey) }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) { projects = decoded }
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([HomeTask].self, from: data) { tasks = decoded }
        if let data = UserDefaults.standard.data(forKey: activityKey),
           let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) { activityLog = decoded }
    }
}
