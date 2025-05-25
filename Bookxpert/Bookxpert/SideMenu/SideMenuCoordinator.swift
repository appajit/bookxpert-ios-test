import SwiftUI
import UIKit
import AVFoundation
import Photos

enum SideMenuResult {
    case loggedOut
}

@MainActor
final class SideMenuCoordinator: Coordinator {
    private var photoPickerController: ProfilePhotoPickerController?
    private var photoSourceOptionsViewController: UIViewController?
    
    private let dependencies: DependencyProviding
    private let navigationController: UINavigationController
    private let completion: (SideMenuResult) -> Void
 
    init(navigationController: UINavigationController,
         dependencies: DependencyProviding,
         completion: @escaping (SideMenuResult) -> Void
    ){
        self.navigationController = navigationController
        self.dependencies = dependencies
        self.completion = completion
    }
    
    func start() {
        let sideMenuViewModel = SideMenuViewModel(
            userDetailsRepositry: dependencies.userDetailsRepository,
            catalogueRepository: dependencies.mobileCatalogueRepository,
            delegate: self)
       let sideMenuContainer = SideMenuContainerView(
        viewModel: sideMenuViewModel,
           onDismiss: { [weak self] in
               self?.navigationController.dismiss(animated: true)
           }
       )

       let hostingController = CustomHostingController(rootView: sideMenuContainer)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve

        navigationController.present(hostingController, animated: true)
    }
}


extension SideMenuCoordinator: SideMenuViewModelDelegate {
    func didSelectEditProfilePhoto(onSelection: @escaping (UIImage?) -> Void) {
      
        let view = ShowPhotoSourceOptionsView { [weak self] option in
            self?.handlePhotoSourceSelection(option, onSelection: onSelection)
        } onCancel: { [weak self] in
            self?.dismissPhotoSourceOptionSourceViewController()
        }

        let hostingController = CustomHostingController(rootView: view)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        
        let presentingViewController = navigationController.presentedViewController ?? navigationController
        presentingViewController.present(hostingController, animated: true)
        self.photoSourceOptionsViewController = hostingController
    }

    private func handlePhotoSourceSelection(_ source: PhotoSourceOption, onSelection: @escaping (UIImage?) -> Void) {
        dismissPhotoSourceOptionSourceViewController { [weak self] in
            guard let self = self else { return }
            let presentingViewController = self.navigationController.presentedViewController ?? self.navigationController
            let photoPickerController = ProfilePhotoPickerController(presentingViewController: presentingViewController) { image in
                onSelection(image)
            }
            switch source {
            case .camera:
                photoPickerController.takePhoto()
            case .photoLibrary:
                photoPickerController.chooseFromPhotos()
            }

            self.photoPickerController = photoPickerController
        }
    }
    
    func didSelectPDFViewer() {
        navigationController.dismiss(animated: true) { [weak self] in
            // Then handle navigation
            self?.showPDFView()
        }
    }

    private func dismissPhotoSourceOptionSourceViewController(completion: (() -> Void)? = nil) {
        photoSourceOptionsViewController?.dismiss(animated: true) { [weak self] in
            self?.photoSourceOptionsViewController = nil
            completion?()
        }
    }
    private func showPDFView() {
        let viewModel =  PDFViewerViewModel(pdfURL: PDFDocumentURLProvider.balanceSheet, pdfRepository: dependencies.pdfRepository)
        let view = PDFViewerView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        navigationController.present(hostingController, animated: true)
    }

    func didLogout() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.completion(.loggedOut)
        }
    }
}
