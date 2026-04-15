import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var titleOffset: CGFloat = 40
    @State private var subtitleOpacity: Double = 0
    @State private var particles: [ParticleData] = (0..<20).map { _ in ParticleData() }
    @State private var animateParticles = false
    @StateObject private var coordinator: AppCoordinator
    @ObservedObject private var viewModel: HomeZoneViewModel
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        let coord = AppCoordinator(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        )
        
        _coordinator = StateObject(wrappedValue: coord)
        _viewModel = ObservedObject(wrappedValue: coord.getViewModel())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DS.splashGradient.ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image("ll_img")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 9)
                        .opacity(0.6)
                }
                
                // Particles
                ForEach(0..<particles.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: particles[i].size, height: particles[i].size)
                        .offset(
                            x: animateParticles ? particles[i].endX : particles[i].startX,
                            y: animateParticles ? particles[i].endY : particles[i].startY
                        )
                        .animation(
                            .easeInOut(duration: particles[i].duration).repeatForever(autoreverses: true).delay(particles[i].delay),
                            value: animateParticles
                        )
                }
                
                NavigationLink(
                    destination: HomeZoneWebView().navigationBarHidden(true),
                    isActive: $coordinator.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $coordinator.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 24) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 90, height: 90)
                        VStack(spacing: 2) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white)
                            Image(systemName: "house.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    VStack(spacing: 8) {
                        Text("Home Zone")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .offset(y: titleOffset)
                            .opacity(opacity)
                        
                        Text("Loading content...")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(subtitleOpacity)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                HomeZoneNotificationView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                UnavailableView()
            }
            .onAppear {
                animateParticles = true
                setupStreams()
                setupNetworkMonitoring()
                coordinator.start()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0; opacity = 1.0; titleOffset = 0
                }
                withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                    subtitleOpacity = 1
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

struct ParticleData {
    var size: CGFloat = CGFloat.random(in: 6...24)
    var startX: CGFloat = CGFloat.random(in: -180...180)
    var startY: CGFloat = CGFloat.random(in: -380...380)
    var endX: CGFloat = CGFloat.random(in: -180...180)
    var endY: CGFloat = CGFloat.random(in: -380...380)
    var duration: Double = Double.random(in: 2.5...5.0)
    var delay: Double = Double.random(in: 0...2.0)
}

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var showWelcome = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "thermometer.medium.slash",
            gradient: [Color(hex: "#1D4ED8"), Color(hex: "#38BDF8")],
            title: "Track Temperature Zones",
            subtitle: "Map every corner of your home and discover exactly where heat is lost or gained.",
            particle: "❄️"
        ),
        OnboardingPage(
            icon: "flame.fill",
            gradient: [Color(hex: "#FB923C"), Color(hex: "#EF4444")],
            title: "Find Cold & Hot Spots",
            subtitle: "Visualize problem areas with a real-time heat map. No guesswork, just data.",
            particle: "🔥"
        ),
        OnboardingPage(
            icon: "bolt.shield.fill",
            gradient: [Color(hex: "#10B981"), Color(hex: "#6366F1")],
            title: "Improve Insulation",
            subtitle: "Get smart recommendations to save energy, fix drafts, and stop mold before it starts.",
            particle: "🌿"
        ),
    ]
    
    var body: some View {
        if showWelcome {
            WelcomeView().environmentObject(appState)
        } else {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { i in
                    OnboardingPageView(page: pages[i], index: i, total: pages.count,
                        onNext: {
                            if i < pages.count - 1 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage = i + 1 }
                            } else {
                                withAnimation { showWelcome = true }
                            }
                        },
                        onSkip: { withAnimation { showWelcome = true } }
                    ).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let gradient: [Color]
    let title: String
    let subtitle: String
    let particle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    let total: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0
    @State private var tapCount = 0
    
    var body: some View {
        ZStack {
            LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Decorative rings
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                        .frame(width: CGFloat(200 + i * 70))
                }
            }
            .offset(y: -50)
            
            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    if index < total - 1 {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(DS.Font.caption(15))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Icon illustration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 180, height: 180)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 8) {
                        Image(systemName: page.icon)
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(.white)
                        Text(page.particle)
                            .font(.system(size: 30))
                            .opacity(Double(tapCount % 2))
                            .animation(.spring(), value: tapCount)
                    }
                }
                .offset(y: floatOffset)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onTapGesture { tapCount += 1 }
                
                Spacer().frame(height: 48)
                
                // Text
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .offset(y: textOffset)
                .opacity(textOpacity)
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<total, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(i == index ? 1 : 0.35))
                                .frame(width: i == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
                        }
                    }
                    
                    Button(action: onNext) {
                        HStack(spacing: 8) {
                            Text(index == total - 1 ? "Get Started" : "Next")
                                .font(DS.Font.heading(17))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(page.gradient.first ?? DS.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0; iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                textOffset = 0; textOpacity = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var appear = false
    
    var body: some View {
        ZStack {
            DS.bgDark.ignoresSafeArea()
            
            // Background gradient orb
            Circle()
                .fill(DS.accent.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: -80, y: -200)
            Circle()
                .fill(Color(hex: "#EF4444").opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 100, y: 200)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(DS.accentGradient)
                            .frame(width: 96, height: 96)
                        Image(systemName: "house.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
                    
                    VStack(spacing: 8) {
                        Text("Home Zone")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Climate intelligence for your home")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 14) {
                    Button(action: {
                        appState.loginDemo()
                        appState.hasCompletedOnboarding = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Try Demo Account")
                                .font(DS.Font.heading(17))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DS.accentGradient)
                        .cornerRadius(16)
                    }
                    
                    NavigationLink(destination: LoginView().environmentObject(appState)) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                            Text("Log In")
                                .font(DS.Font.heading(17))
                        }
                        .foregroundColor(DS.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DS.accent.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    
                    // Demo badge
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundColor(DS.warning)
                        Text("Demo includes sample data • No account needed")
                            .font(DS.Font.caption(12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) { appear = true }
        }
    }
}

struct HomeZoneNotificationView: View {
    let viewModel: HomeZoneViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "second_home_zone_img" : "main_home_zone_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("NerkoOne-Regular", size: 28))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("NerkoOne-Regular", size: 18))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.requestPermission()
            } label: {
                Image("main_home_zone_b_img")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.deferPermission()
            } label: {
                Image("sec_home_zone_b_img")
                    .resizable()
                    .frame(width: 280, height: 40)
            }
        }
        .padding(.horizontal, 12)
    }
}


struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(geometry.size.width > geometry.size.height ? "ii_sec_img" : "ii_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 2)
                    .opacity(0.8)
                
                Image("ii_a_img")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
