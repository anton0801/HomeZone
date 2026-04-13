import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Design System
struct DS {
    // Climate colors
    static let cold      = Color(hex: "#1D4ED8")
    static let cool      = Color(hex: "#38BDF8")
    static let neutral   = Color(hex: "#10B981")
    static let warm      = Color(hex: "#FB923C")
    static let hot       = Color(hex: "#EF4444")
    static let mold      = Color(hex: "#06B6D4")
    
    // UI accent
    static let accent    = Color(hex: "#3B82F6")
    static let indigo    = Color(hex: "#6366F1")
    static let neon      = Color(hex: "#22D3EE")
    
    // Backgrounds
    static let bg        = Color(hex: "#F8FAFC")
    static let bgSecond  = Color(hex: "#EEF2F7")
    static let bgDark    = Color(hex: "#0F172A")
    static let cardDark  = Color(hex: "#1E293B")
    static let border    = Color(hex: "#E2E8F0")
    
    // Status
    static let error     = Color(hex: "#DC2626")
    static let warning   = Color(hex: "#FACC15")
    static let success   = Color(hex: "#22C55E")
    
    // Gradients
    static let splashGradient = LinearGradient(
        colors: [Color(hex: "#1D4ED8"), Color(hex: "#EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#6366F1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color(hex: "#1E293B"), Color(hex: "#0F172A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Temperature gradient colors for heat map
    static func tempColor(celsius: Double) -> Color {
        switch celsius {
        case ..<12:   return cold
        case 12..<17: return cool
        case 17..<24: return neutral
        case 24..<29: return warm
        default:      return hot
        }
    }
    
    // Fonts
    struct Font {
        static func display(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .bold, design: .rounded) }
        static func heading(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .semibold, design: .rounded) }
        static func body(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .regular, design: .default) }
        static func mono(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .medium, design: .monospaced) }
        static func caption(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .medium, design: .rounded) }
    }
}
