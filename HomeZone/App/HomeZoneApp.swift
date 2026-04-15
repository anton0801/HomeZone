import SwiftUI

@main
struct HomeZoneApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                SplashView()
            }
        }
    }
}

final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isLoggedIn && appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
            } else if appState.hasCompletedOnboarding {
                NavigationView {
                    WelcomeView()
                        .environmentObject(appState)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else {
                NavigationView {
                    OnboardingView()
                        .environmentObject(appState)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .preferredColorScheme(appState.preferredColorScheme)
    }
}
