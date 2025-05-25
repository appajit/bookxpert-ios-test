
import Foundation
import CoreData


struct UserDetails {
    let email: String?
    let displayName: String?
    let uid: String
    let profileImage: Data?
}

protocol UserDetailsRepositoryProtcol {
    var isUserLoggedIn: Bool { get }
    func saveUserDetails(_ details: UserDetails)
    func getUserDetails() -> UserDetails?
    func saveProfileImage(_ image: Data)
    func deleteUserDetails()
}

final class UserDetailsRepository: UserDetailsRepositoryProtcol {
    private let container: PersistentContainer
    private var userDetails: UserDetails?

    init(persistentContainer: PersistentContainer) {
        self.container = persistentContainer
    }
    
    var isUserLoggedIn: Bool {
        getUserDetails() != nil
    }

    func saveUserDetails(_ details: UserDetails) {
        let context = container.viewContext
        
        // Try to find existing entity first
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        let existingEntity = try? context.fetch(request).first
        
        let session: UserDetailsEntity
        if let existing = existingEntity {
            // Update existing entity
            session = existing
        } else {
            // Create new entity
            session = UserDetailsEntity(context: context)
        }
        
        // Set the properties
        session.uid = details.uid
        session.email = details.email
        session.displayName = details.displayName
        session.profileImage = details.profileImage

        do {
            try context.save()
            userDetails = details
        } catch {
            print("Failed to save user details: \(error)")
        }
    }

    func getUserDetails() -> UserDetails? {
        guard userDetails == nil else {
            return userDetails
        }
        
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        guard let entity = try? container.viewContext.fetch(request).first else {
            return nil
        }
        
        return UserDetails(email: entity.email, displayName: entity.displayName, uid: entity.uid, profileImage: entity.profileImage)
    }

    func saveProfileImage(_ image: Data) {
        let context = container.viewContext
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()

        if let entity = try? context.fetch(request).first {
            entity.profileImage = image
            try? context.save()
            
            userDetails = UserDetails(
                email: entity.email,
                displayName: entity.displayName,
                uid: entity.uid,
                profileImage: image
            )
        }
    }
    
    func deleteUserDetails() {
        let context = container.viewContext
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            try? context.save()
            userDetails = nil
        }
    }
}
