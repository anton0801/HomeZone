import SwiftUI

final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    private var trackingBuf: [AnyHashable: Any] = [:]
    private var navigationBuf: [AnyHashable: Any] = [:]
    private var timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) {
        trackingBuf = data
        scheduleTimer()
        if !navigationBuf.isEmpty { merge() }
    }
    
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "hz_first_launch_flag") else { return }
        navigationBuf = data
        onNavigation?(data)
        timer?.invalidate()
        if !trackingBuf.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = trackingBuf
        navigationBuf.forEach { k, v in
            let key = "deep_\(k)"
            if result[key] == nil { result[key] = v }
        }
        onTracking?(result)
    }
}

struct HZButton: View {
    let title: String
    let style: HZButtonStyle
    let action: () -> Void
    var icon: String? = nil
    @State private var isPressed = false
    
    enum HZButtonStyle {
        case primary, secondary, ghost, danger
        var gradient: LinearGradient {
            switch self {
            case .primary:   return DS.accentGradient
            case .secondary: return LinearGradient(colors: [DS.bgSecond, DS.bgSecond], startPoint: .leading, endPoint: .trailing)
            case .ghost:     return LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
            case .danger:    return LinearGradient(colors: [DS.error, DS.error.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            }
        }
        var textColor: Color {
            switch self {
            case .primary, .danger: return .white
            case .secondary: return DS.accent
            case .ghost: return DS.accent
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(DS.Font.heading(16))
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(style.gradient)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .secondary ? DS.border : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in isPressed = true }
            .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - HZCard
struct HZCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    @Environment(\.colorScheme) var colorScheme
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(colorScheme == .dark ? DS.cardDark : .white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.07), radius: 12, x: 0, y: 4)
    }
}

// MARK: - HZTextField
struct HZTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(focused ? DS.accent : .secondary)
                    .font(.system(size: 16))
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .focused($focused)
                .font(DS.Font.body(15))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(colorScheme == .dark ? DS.cardDark : DS.bgSecond)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focused ? DS.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @State private var appear = false
    
    var body: some View {
        HZCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(DS.Font.display(26))
                    .foregroundColor(.primary)
                    .scaleEffect(appear ? 1 : 0.7)
                    .opacity(appear ? 1 : 0)
                Text(title)
                    .font(DS.Font.caption(12))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) { appear = true }
        }
    }
}

// MARK: - ClimateTag
struct ClimateTag: View {
    let type: ProblemType
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: type.icon)
                .font(.system(size: 11))
            Text(type.rawValue)
                .font(DS.Font.caption(11))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(type.color.opacity(0.15))
        .foregroundColor(type.color)
        .cornerRadius(20)
    }
}

// MARK: - SectionHeader
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(DS.Font.heading(18))
                .foregroundColor(.primary)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DS.Font.caption(13))
                        .foregroundColor(DS.accent)
                }
            }
        }
    }
}

// MARK: - LoadingShimmer
struct ShimmerBox: View {
    @State private var shimmer = false
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                    startPoint: shimmer ? .trailing : .leading,
                    endPoint: shimmer ? .leading : .trailing
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { shimmer = true }
            }
    }
}

// MARK: - TempBadge
struct TempBadge: View {
    let value: Double
    let unit: TemperatureUnit
    
    var color: Color { DS.tempColor(celsius: value) }
    var displayValue: Double { unit.convert(value) }
    
    var body: some View {
        Text(String(format: "%.1f%@", displayValue, unit.symbol))
            .font(DS.Font.mono(13))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DS.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(DS.accent)
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(DS.Font.heading(18))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(DS.Font.body(14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let buttonTitle = buttonTitle, let action = action {
                HZButton(title: buttonTitle, style: .primary, action: action)
                    .frame(width: 180)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - NavigationBarStyle
struct HZNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Row separator
struct HZDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.border)
            .frame(height: 1)
    }
}
