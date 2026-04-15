import Foundation
import AppsFlyerLib

@MainActor
final class HomeZoneViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    weak var delegate: ViewModelDelegate?
    
    private let storage: StorageService
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var state: ApplicationState = .initial
    private var timeoutTask: Task<Void, Never>?
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    func initialize() {
        Task {
            let stored = storage.loadState()
            state.tracking = stored.tracking
            state.navigation = stored.navigation
            state.mode = stored.mode
            state.isFirstLaunch = stored.isFirstLaunch
            state.permission = ApplicationState.PermissionData(
                isGranted: stored.permission.isGranted,
                isDenied: stored.permission.isDenied,
                lastAsked: stored.permission.lastAsked
            )
            
            delegate?.didUpdateState(state)
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            let converted = data.mapValues { "\($0)" }
            state.tracking = converted
            storage.saveTracking(converted)
            
            delegate?.didUpdateState(state)
            
            await performValidation()
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            let converted = data.mapValues { "\($0)" }
            state.navigation = converted
            storage.saveNavigation(converted)
            
            delegate?.didUpdateState(state)
        }
    }
    
    func requestPermission() {
        Task {
            // ✅ Локальная копия для избежания inout capture
            var localPermission = state.permission
            
            let updatedPermission = await withCheckedContinuation {
                (continuation: CheckedContinuation<ApplicationState.PermissionData, Never>) in
                
                notification.requestPermission { granted in
                    var permission = localPermission
                    
                    if granted {
                        permission.isGranted = true
                        permission.isDenied = false
                        permission.lastAsked = Date()
                        self.notification.registerForPush()
                    } else {
                        permission.isGranted = false
                        permission.isDenied = true
                        permission.lastAsked = Date()
                    }
                    
                    continuation.resume(returning: permission)
                }
            }
            
            state.permission = updatedPermission
            storage.savePermissions(updatedPermission)
            
            showPermissionPrompt = false
            delegate?.didRequestNavigation(to: .web)
        }
    }
    
    func deferPermission() {
        Task {
            state.permission.lastAsked = Date()
            storage.savePermissions(state.permission)
            
            showPermissionPrompt = false
            delegate?.didRequestNavigation(to: .web)
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    func timeout() {
        Task {
            timeoutTask?.cancel()
            guard !state.isLocked else { return }
            delegate?.didRequestNavigation(to: .main)
        }
    }
    
    // MARK: - Private Logic
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !state.isLocked else { return }
            await timeout()
        }
    }
    
    private var isPassed = false
    
    private func performValidation() async {
//        guard state.hasTracking() else {
//            delegate?.didRequestNavigation(to: .main)
//            return
//        }
        
        if !isPassed {
            do {
                let isValid = try await validation.validate()
                
                isPassed = true
                if isValid {
                    await executeBusinessLogic()
                } else {
                    timeoutTask?.cancel()
                    delegate?.didRequestNavigation(to: .main)
                }
            } catch {
                print("🏠 [HomeZone] Validation error: \(error)")
                timeoutTask?.cancel()
                delegate?.didRequestNavigation(to: .main)
            }
        }
    }
    
    private func executeBusinessLogic() async {
        guard !state.isLocked, state.hasTracking() else {
            delegate?.didRequestNavigation(to: .main)
            return
        }
        
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            await finalizeWithEndpoint(temp)
            return
        }
        
        // Check organic + first launch
        let attributionProcessed = state.metadata["attribution_processed"] == "true"
        if state.isOrganic() && state.isFirstLaunch && !attributionProcessed {
            state.metadata["attribution_processed"] = "true"
            await executeOrganicFlow()
            return
        }
        
        // Fetch endpoint
        await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !state.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await network.fetchAttribution(deviceID: deviceID)
            
            for (key, value) in state.navigation {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            let converted = fetched.mapValues { "\($0)" }
            state.tracking = converted
            storage.saveTracking(converted)
            
            await fetchEndpoint()
        } catch {
            print("🏠 [HomeZone] Attribution error: \(error)")
            delegate?.didRequestNavigation(to: .main)
        }
    }
    
    private func fetchEndpoint() async {
        guard !state.isLocked else { return }
        
        let trackingDict = state.tracking.mapValues { $0 as Any }
        
        do {
            let url = try await network.fetchEndpoint(tracking: trackingDict)
            await finalizeWithEndpoint(url)
        } catch {
            print("🏠 [HomeZone] Endpoint error: \(error)")
            delegate?.didRequestNavigation(to: .main)
        }
    }
    
    private func finalizeWithEndpoint(_ url: String) async {
        state.endpoint = url
        state.mode = "Active"
        state.isFirstLaunch = false
        state.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
        
        if state.permission.canAsk {
            showPermissionPrompt = true
        } else {
            delegate?.didRequestNavigation(to: .web)
        }
    }
}
