import CoreServices
import SwiftUI

final class AppCoordinator: Coordinator, ObservableObject {
    private let dependencies: DependencyProviding
    private var childCoordinator: (any Coordinator)?
    
    private let window: UIWindow
    private let navigationController: UINavigationController
    
    init(window: UIWindow, dependencies: DependencyProviding) {
        self.window = window
        self.navigationController = UINavigationController()
        self.dependencies = dependencies
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    }

    func start() {
        if dependencies.userDetailsRepository.isUserLoggedIn {
            showMobileCatalogue()
        } else {
            showLogin()
        }
    }
    
    private func showLogin() {
        let loginCoordinator = LoginCoordinator(
            navigationController: navigationController,
            dependencies: dependencies,
            completion: showMobileCatalogue
        )
        loginCoordinator.start()
        childCoordinator = loginCoordinator
    }
    
    private func showMobileCatalogue() {
        let mobileCatalogueCoordinator = MobileCatalogueCoordinator(
            navigationController: navigationController,
            dependencies: dependencies) { [weak self] result in
                switch result {
                case .loggedOut:
                    self?.showLogin()
                }
            }
        
        mobileCatalogueCoordinator.start()
        childCoordinator = mobileCatalogueCoordinator
   
    }
    
}
