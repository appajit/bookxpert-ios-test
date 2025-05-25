
import CoreData
@testable import Bookxpert


final class MockPersistentContainer: PersistentContainer {
    func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, (any Error)?) -> Void) {
        inMemoryContainer.loadPersistentStores(completionHandler: block)
    }
    
    private var inMemoryContainer: NSPersistentContainer
    
    init() {
        // Create in-memory Core Data stack for testing
        inMemoryContainer = NSPersistentContainer(name: "Bookxpert") // Replace with your actual model name
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        inMemoryContainer.persistentStoreDescriptions = [description]
        
        
        loadStore()
    }
    
    private func loadStore() {
        // Load the persistent stores
        inMemoryContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return inMemoryContainer.viewContext
    }
    
    // Helper method to clear all data between tests
    func clearAllData() {
        let context = viewContext
        let fetchRequest: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            context.reset() // Reset the context to clear any cached objects
        } catch {
            print("Failed to clear test data: \(error)")
        }
    }
}
