
import Foundation
import CoreData


extension UserDetailsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserDetailsEntity> {
        return NSFetchRequest<UserDetailsEntity>(entityName: "UserDetailsEntity")
    }

    @NSManaged public var uid: String
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var profileImage: Data?

}

extension UserDetailsEntity : Identifiable {

}
