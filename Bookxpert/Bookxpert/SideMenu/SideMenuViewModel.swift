import Foundation
import Combine
import UIKit

@MainActor
protocol SideMenuViewModelDelegate: AnyObject {
    func didSelectPDFViewer()
    func didLogout()
    func didSelectEditProfilePhoto(onSelection: @escaping (UIImage?) -> Void)
}


enum SideMenuItem: String, CaseIterable {
    case pdfViewer = "PDF Viewer"
    case logout = "Logout"
    
    var icon: String {
        switch self {
        case .pdfViewer:
            return "doc.text"
        case .logout:
            return "rectangle.portrait.and.arrow.right"
        }
    }
    
    var isDestructive: Bool {
        switch self {
        case .logout:
            return true
        case .pdfViewer:
            return false
        }
    }
}

enum PhotoSourceOption: String, CaseIterable {
    case camera = "Camera"
    case photoLibrary = "Photo Library"
    
    var icon: String {
        switch self {
        case .camera:
            return "camera"
        case .photoLibrary:
            return "photo"
        }
    }
}

@MainActor
protocol SideMenuViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var profileImage: UIImage? { get set }
    var userName: String { get set }
  
    func handleMenuItemTap(_ item: SideMenuItem)
    func handleProfilePhotoTap()
    func performLogout()
}

@MainActor
final class SideMenuViewModel: SideMenuViewModelProtocol {
    
    @Published var isLoading: Bool = false
    @Published var profileImage: UIImage?
    @Published var userName: String = ""
    
    private weak var delegate: SideMenuViewModelDelegate?
    private let userDetailsRepositry: UserDetailsRepositoryProtcol
    private let catalogueRepository: MobileCatalogueRepositing
    
    init(userDetailsRepositry: UserDetailsRepositoryProtcol,
         catalogueRepository: MobileCatalogueRepositing,
        delegate: SideMenuViewModelDelegate? = nil) {
        self.delegate = delegate
        self.userDetailsRepositry = userDetailsRepositry
        self.catalogueRepository = catalogueRepository
        setUserDetails()
    }
    
    func handleMenuItemTap(_ item: SideMenuItem) {
        switch item {
        case .pdfViewer:
            delegate?.didSelectPDFViewer()
        case .logout:
            performLogout()
        }
    }
    
    func handleProfilePhotoTap() {
        delegate?.didSelectEditProfilePhoto(onSelection: { [weak self] image in
            guard let self = self, let profileImage = image else { return }
            self.saveProfileImage(profileImage)
        })
    }
    
    func performLogout() {
        userDetailsRepositry.deleteUserDetails()
        catalogueRepository.deleteCatalogue()
        delegate?.didLogout()
    }
    
    private func setUserDetails() {
        let userDetails = userDetailsRepositry.getUserDetails()
        userName = userDetails?.displayName ?? ""
        if let data = userDetails?.profileImage {
            profileImage = UIImage(data: data)
        } else {
            profileImage = UIImage(named: "photo-placeholder")
        }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            userDetailsRepositry.saveProfileImage(imageData)
            profileImage = image
        }
    }
}
