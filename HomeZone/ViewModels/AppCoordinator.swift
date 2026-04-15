import SwiftUI
import Foundation

@MainActor
final class AppCoordinator: Coordinator, ViewModelDelegate, ObservableObject {
    
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let viewModel: HomeZoneViewModel
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.viewModel = HomeZoneViewModel(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        )
        
        viewModel.delegate = self
    }
    
    // MARK: - Coordinator Protocol
    
    func start() {
        viewModel.initialize()
    }
    
    func navigate(to route: Route) {
        switch route {
        case .main:
            navigateToMain = true
            
        case .web:
            navigateToWeb = true
            
        case .splash, .permission, .offline:
            break
        }
    }
    
    // MARK: - ViewModelDelegate
    
    func didRequestNavigation(to route: Route) {
        navigate(to: route)
    }
    
    func didUpdateState(_ state: ApplicationState) {
        // State updated - можно логировать или отслеживать
    }
    
    // MARK: - Public API (для View)
    
    func getViewModel() -> HomeZoneViewModel {
        viewModel
    }
}
