import Foundation
import SwiftUI

// MARK: - User
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    
    static let demo = User(name: "Alex Demo", email: "demo@homezone.app")
}

// MARK: - Project
struct Project: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var rooms: [Room] = []
    var notes: String = ""
    
    static func demo() -> [Project] {
        var p1 = Project(name: "Home Renovation 2024")
        p1.rooms = Room.demoRooms()
        var p2 = Project(name: "Apartment Insulation Check")
        p2.rooms = [Room(name: "Living Room", width: 5.0, height: 4.0)]
        return [p1, p2]
    }
}


// MARK: - Room
struct Room: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var width: Double = 4.0   // meters
    var height: Double = 3.5  // meters
    var measurements: [MeasurementPoint] = []
    var createdAt: Date = Date()
    
    static func demoRooms() -> [Room] {
        var living = Room(name: "Living Room", width: 6.0, height: 4.5)
        living.measurements = MeasurementPoint.demoPoints(roomID: living.id)
        var bedroom = Room(name: "Bedroom", width: 4.0, height: 3.5)
        bedroom.measurements = MeasurementPoint.demoPointsBedroom(roomID: bedroom.id)
        let kitchen = Room(name: "Kitchen", width: 3.0, height: 3.0)
        return [living, bedroom, kitchen]
    }
}

// MARK: - MeasurementPoint
struct MeasurementPoint: Codable, Identifiable {
    var id: UUID = UUID()
    var roomID: UUID
    var x: Double // 0.0 - 1.0 relative
    var y: Double // 0.0 - 1.0 relative
    var temperature: Double // Celsius
    var humidity: Double    // %
    var timestamp: Date = Date()
    var label: String = ""
    
    var problemType: ProblemType {
        if humidity > 70 { return .mold }
        if temperature < 16 { return .cold }
        if temperature > 28 { return .hot }
        if temperature < 19 { return .cool }
        return .normal
    }
    
    static func demoPoints(roomID: UUID) -> [MeasurementPoint] {
        [
            MeasurementPoint(roomID: roomID, x: 0.1, y: 0.1, temperature: 13.5, humidity: 72, label: "Window corner"),
            MeasurementPoint(roomID: roomID, x: 0.5, y: 0.5, temperature: 21.0, humidity: 50, label: "Center"),
            MeasurementPoint(roomID: roomID, x: 0.9, y: 0.1, temperature: 14.2, humidity: 68, label: "North wall"),
            MeasurementPoint(roomID: roomID, x: 0.8, y: 0.8, temperature: 23.5, humidity: 45, label: "Radiator zone"),
            MeasurementPoint(roomID: roomID, x: 0.2, y: 0.9, temperature: 18.0, humidity: 55, label: "Door area"),
            MeasurementPoint(roomID: roomID, x: 0.5, y: 0.1, temperature: 15.0, humidity: 65, label: "Window center"),
        ]
    }
    
    static func demoPointsBedroom(roomID: UUID) -> [MeasurementPoint] {
        [
            MeasurementPoint(roomID: roomID, x: 0.15, y: 0.15, temperature: 16.0, humidity: 60, label: "Corner"),
            MeasurementPoint(roomID: roomID, x: 0.5, y: 0.5, temperature: 20.5, humidity: 48, label: "Center"),
            MeasurementPoint(roomID: roomID, x: 0.85, y: 0.85, temperature: 22.0, humidity: 44, label: "Heater"),
        ]
    }
}

// MARK: - ProblemType
enum ProblemType: String, Codable, CaseIterable {
    case cold = "Cold Spot"
    case cool = "Cool Zone"
    case normal = "Normal"
    case hot = "Hot Zone"
    case mold = "Mold Risk"
    
    var color: Color {
        switch self {
        case .cold: return Color(hex: "#1D4ED8")
        case .cool: return Color(hex: "#38BDF8")
        case .normal: return Color(hex: "#10B981")
        case .hot: return Color(hex: "#FB923C")
        case .mold: return Color(hex: "#06B6D4")
        }
    }
    
    var icon: String {
        switch self {
        case .cold: return "thermometer.snowflake"
        case .cool: return "wind"
        case .normal: return "checkmark.circle.fill"
        case .hot: return "flame.fill"
        case .mold: return "drop.fill"
        }
    }
    
    var recommendation: String {
        switch self {
        case .cold: return "Add insulation or check for drafts in this area. Consider weatherstripping windows and doors."
        case .cool: return "Minor temperature drop detected. Check window seals and wall insulation quality."
        case .normal: return "This zone is within optimal comfort range. No action required."
        case .hot: return "Overheating detected. Improve ventilation or adjust heating equipment."
        case .mold: return "High humidity detected. Use a dehumidifier and improve air circulation to prevent mold growth."
        }
    }
}

// MARK: - Task
struct HomeTask: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date?
    var isCompleted: Bool = false
    var priority: TaskPriority = .medium
    var createdAt: Date = Date()
    var roomName: String = ""
    
    static func demo() -> [HomeTask] {
        [
            HomeTask(title: "Fix window insulation - Living Room", notes: "Cold spot detected near north window", dueDate: Date().addingTimeInterval(86400*3), priority: .high, roomName: "Living Room"),
            HomeTask(title: "Install dehumidifier", notes: "Humidity >70% in bedroom corner", dueDate: Date().addingTimeInterval(86400*7), priority: .medium, roomName: "Bedroom"),
            HomeTask(title: "Check radiator valves", notes: "Uneven heating distribution", priority: .low, roomName: "Living Room"),
        ]
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return Color(hex: "#22C55E")
        case .medium: return Color(hex: "#FACC15")
        case .high: return Color(hex: "#DC2626")
        }
    }
}

// MARK: - ActivityEntry
struct ActivityEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var action: String
    var detail: String
    var icon: String
    
    static func demo() -> [ActivityEntry] {
        let cal = Calendar.current
        return [
            ActivityEntry(timestamp: Date(), action: "Measurement Added", detail: "Living Room — 13.5°C at window corner", icon: "thermometer"),
            ActivityEntry(timestamp: cal.date(byAdding: .hour, value: -2, to: Date())!, action: "Problem Detected", detail: "Mold risk in Bedroom corner", icon: "exclamationmark.triangle.fill"),
            ActivityEntry(timestamp: cal.date(byAdding: .day, value: -1, to: Date())!, action: "Room Added", detail: "Kitchen added to Home Renovation 2024", icon: "plus.circle.fill"),
            ActivityEntry(timestamp: cal.date(byAdding: .day, value: -2, to: Date())!, action: "Report Exported", detail: "PDF report generated", icon: "doc.fill"),
            ActivityEntry(timestamp: cal.date(byAdding: .day, value: -3, to: Date())!, action: "Project Created", detail: "Home Renovation 2024 started", icon: "folder.fill"),
        ]
    }
}

// MARK: - TemperatureUnit
enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "Celsius (°C)"
    case fahrenheit = "Fahrenheit (°F)"
    
    func convert(_ value: Double) -> Double {
        switch self {
        case .celsius: return value
        case .fahrenheit: return value * 9/5 + 32
        }
    }
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

protocol Coordinator: AnyObject {
    func start()
    func navigate(to route: Route)
}

enum Route {
    case splash
    case main
    case web
    case permission
    case offline
}

protocol ViewModelDelegate: AnyObject {
    func didRequestNavigation(to route: Route)
    func didUpdateState(_ state: ApplicationState)
}

struct ApplicationState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    var metadata: [String: String]
    var isLocked: Bool
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
        
        var canAsk: Bool {
            guard !isGranted && !isDenied else { return false }
            if let date = lastAsked {
                return Date().timeIntervalSince(date) / 86400 >= 3
            }
            return true
        }
        
        static var initial: PermissionData {
            PermissionData(isGranted: false, isDenied: false, lastAsked: nil)
        }
    }
    
    func isOrganic() -> Bool {
        tracking["af_status"] == "Organic"
    }
    
    func hasTracking() -> Bool {
        !tracking.isEmpty
    }
    
    static var initial: ApplicationState {
        ApplicationState(
            tracking: [:],
            navigation: [:],
            endpoint: nil,
            mode: nil,
            isFirstLaunch: true,
            permission: .initial,
            metadata: [:],
            isLocked: false
        )
    }
}

enum CoordinatorError: Error {
    case validationFailed
    case networkError
    case timeout
}
