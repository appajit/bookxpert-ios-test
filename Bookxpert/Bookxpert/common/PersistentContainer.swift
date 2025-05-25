
import Foundation
import CoreData

protocol PersistentContainer {
    var viewContext: NSManagedObjectContext { get }
    func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, (any Error)?) -> Void)
}

extension NSPersistentContainer: PersistentContainer { }
