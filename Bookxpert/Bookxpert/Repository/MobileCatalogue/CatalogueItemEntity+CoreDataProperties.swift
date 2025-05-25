
import Foundation
import CoreData


extension CatalogueItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatalogueItemEntity> {
        return NSFetchRequest<CatalogueItemEntity>(entityName: "CatalogueItemEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var data: Data?

}

extension CatalogueItemEntity : Identifiable {

}
