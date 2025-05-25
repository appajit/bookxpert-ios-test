import SwiftUI
import UIKit

enum AuthScreen {
    case login
    case signup
    case forgotPassword
}

final class LoginCoordinator: Coordinator {
    private let dependencies: DependencyProviding
    private let completion: () -> Void
    private let navigationController: UINavigationController
 

    init(navigationController: UINavigationController,
         dependencies: DependencyProviding,
         completion: @escaping () -> Void)
    {
        self.navigationController = navigationController
        self.dependencies = dependencies
        self.completion = completion
    }
    
    func start() {
        let loginViewModel = LoginViewModel(
            authService: dependencies.authService,
            googleCredentailProvider: GoogleCredentailProvider(presentingViewController: navigationController),
            userDetailsRepository: dependencies.userDetailsRepository,
            delegate: self
        )
        
        let loginView = LoginView(viewModel: loginViewModel)
        let hostingController = UIHostingController(rootView: loginView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
}

extension LoginCoordinator: LoginViewModelDelegate {
    func didLoginSuccessfully() {
        completion()
    }
}
