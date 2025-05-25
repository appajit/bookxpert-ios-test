import UIKit
import PhotosUI

class ProfilePhotoPickerController: NSObject {
    
    private weak var presentingViewController: UIViewController?
    private let imagePickerController = UIImagePickerController()
    private var photoSelectedCallback: ((UIImage) -> Void)?
    
    init(presentingViewController: UIViewController, photoSelectedCallback: @escaping (UIImage) -> Void) {
        super.init()
        self.presentingViewController = presentingViewController
        self.photoSelectedCallback = photoSelectedCallback
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
    }
    
    func takePhoto() {
        guard let presentingVC = presentingViewController else {
            return
        }
        
        didRequestCameraAccess { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.imagePickerController.sourceType = .camera
                    presentingVC.present(self.imagePickerController, animated: true)
                } else {
                    self.showAlert(title: "Camera Not Available", message: "Your device doesn't support camera functionality.")
                }
            }
        }
    }
    
    func chooseFromPhotos() {
        guard let presentingVC = presentingViewController else {
            return
        }
        
        didRequestPhotoLibraryAccess { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var configuration = PHPickerConfiguration()
                configuration.filter = .images
                configuration.selectionLimit = 1
                
                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                
                presentingVC.present(picker, animated: true)
            }
        }
    }
    
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingViewController?.present(alert, animated: true)
    }
    
       func didRequestCameraAccess(completion: @escaping () -> Void) {
           checkCameraPermission { granted in
               DispatchQueue.main.async {
                   if granted {
                       completion()
                   } else {
                       self.showCameraPermissionAlert()
                   }
               }
           }
       }
       
       func didRequestPhotoLibraryAccess(completion: @escaping () -> Void) {
           checkPhotoLibraryPermission { granted in
               DispatchQueue.main.async {
                   if granted {
                       completion()
                   } else {
                       self.showPhotoLibraryPermissionAlert()
                   }
               }
           }
       }
    
        private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                completion(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    completion(granted)
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
        
        private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
           
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    completion(status == .authorized || status == .limited)
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
        
        private func showCameraPermissionAlert() {
            let alert = UIAlertController(
                title: "Camera Access Required",
                message: "Please allow camera access in Settings to take photos.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            presentingViewController?.present(alert, animated: true)
        }
        
        private func showPhotoLibraryPermissionAlert() {
            let alert = UIAlertController(
                title: "Photo Library Access Required",
                message: "Please allow photo library access in Settings to select photos.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            presentingViewController?.present(alert, animated: true)
        }
    
    
}

extension ProfilePhotoPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage {
            photoSelectedCallback?(image)
        } else if let image = info[.originalImage] as? UIImage {
            photoSelectedCallback?(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension ProfilePhotoPickerController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Could not load image: \(error.localizedDescription)")
                }
                return
            }
            
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.photoSelectedCallback?(image)
                }
            }
        }
    }
}
