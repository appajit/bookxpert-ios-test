import SwiftUI
import UIKit
import AVFoundation
import Photos

enum MobileCatalogueResult {
    case loggedOut
}


@MainActor
final class MobileCatalogueCoordinator: Coordinator {
    private let dependencies: DependencyProviding
    private let navigationController: UINavigationController
    private var childCoordinator: Coordinator?
    private let completion: (MobileCatalogueResult) -> Void
 
    
    init(navigationController: UINavigationController,
         dependencies: DependencyProviding,
         completion: @escaping (MobileCatalogueResult) -> Void
    ){
        self.navigationController = navigationController
        self.dependencies = dependencies
        self.completion = completion
    }
    
    func start() {
        let viewModel = MobileCatalogueViewModel(
            repository: dependencies.mobileCatalogueRepository,
            delegate: self
        )
        let view = MobileCatalogueView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.setViewControllers([hostingController], animated: false)
    }
}
extension MobileCatalogueCoordinator: MobileCatalogueViewModelDelegate {
    
    func didSelectEditItem(_ item: MobileCatalogueItem) {
        let viewModel = EditCatalogueItemViewModel(item: item, repository: dependencies.mobileCatalogueRepository, delegate: self)
        let view = EditCatalogueItemView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .pageSheet
    
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        navigationController.present(hostingController, animated: true)
    }
    
    func didSelectSideMenu() {
        let sideMenuCoordinator = SideMenuCoordinator(
            navigationController: navigationController,
            dependencies: dependencies,
            completion: { [weak self] result in
                switch result {
                case .loggedOut:
                    self?.completion(.loggedOut)
                }
            }
        )
                                                     
        sideMenuCoordinator.start()
        childCoordinator = sideMenuCoordinator
    }
}

@MainActor
protocol EditCatalogueItemViewModelDelegate: AnyObject {
    func finished()
    func cancelled()
}

extension MobileCatalogueCoordinator: EditCatalogueItemViewModelDelegate {
    func finished() {
       navigationController.dismiss(animated: true)
    }
    
    func cancelled() {
        navigationController.dismiss(animated: true)
    }
}
