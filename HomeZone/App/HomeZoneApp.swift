import SwiftUI

@main
struct HomeZoneApp: App {
    @StateObject private var appState = AppState()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(onFinish: {
                        withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
                    })
                } else {
                    RootView()
                        .environmentObject(appState)
                        .preferredColorScheme(appState.preferredColorScheme)
                }
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
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
            } else {
                NavigationView {
                    OnboardingView()
                        .environmentObject(appState)
                }
            }
        }
        .preferredColorScheme(appState.preferredColorScheme)
    }
}
