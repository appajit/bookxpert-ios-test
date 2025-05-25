
import Foundation
import CoreData
import Combine

enum MobileCatalogueRepositoryError: Error {
    case unableToUpdate
    case unableToDelete
}

protocol MobileCatalogueRepositing {
    func fetchCatalogue(forceUpdate: Bool) async throws
    func updateCatalogueItem(_ item: MobileCatalogueItem) throws
    func deleteCatalogueItem(_ item: MobileCatalogueItem) throws
    func deleteCatalogue()
    var catalogueItemsPublisher: AnyPublisher<[MobileCatalogueItem], Never> { get }
}

extension MobileCatalogueRepositing {
    func fetchCatalogue() async throws {
        try await fetchCatalogue(forceUpdate: false)
    }
}

final class MobileCatalogueRepository: MobileCatalogueRepositing {
    @Published var catalogueItems: [MobileCatalogueItem] = []
    private let service: MobileCatalogueServicing
  
    private let container: PersistentContainer
   
    init(service: MobileCatalogueServicing,
         persistentContainer: PersistentContainer
    ) {
        self.container = persistentContainer
        self.service = service
    }

    var catalogueItemsPublisher: AnyPublisher<[MobileCatalogueItem], Never> {
        $catalogueItems.eraseToAnyPublisher()
    }

    func fetchCatalogue(forceUpdate: Bool)  async throws {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()

        if !forceUpdate,
            let storedItems = try? context.fetch(fetchRequest), !storedItems.isEmpty {
            let result = storedItems.compactMap { entity -> MobileCatalogueItem? in
                var decodedData: [String: JSONValue]? = nil
                if let data = entity.data {
                    do {
                        decodedData = try JSONDecoder().decode([String: JSONValue].self, from: data)
                    } catch {
                    }
                }
                return MobileCatalogueItem(id: entity.id, name: entity.name, data: decodedData)
            }
            self.catalogueItems = result
            return // Exit early if we have stored data
        }

        let items = try await service.fetchCatalogue()

        await context.perform {
            for item in items {
                let entity = CatalogueItemEntity(context: context)
                entity.id = item.id
                entity.name = item.name
                
                // Only encode data if it exists
                if let itemData = item.data {
                    do {
                        entity.data = try JSONEncoder().encode(itemData)
                    } catch {
                        print("Failed to encode data for item \(item.id): \(error)")
                        entity.data = nil
                    }
                } else {
                    entity.data = nil
                }
            }

            do {
                try context.save()
            } catch {
                print("Failed to save catalogue items to Core Data: \(error)")
            }
        }

        self.catalogueItems = items
    }
    
    func updateCatalogueItem(_ item: MobileCatalogueItem) throws {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id)

        guard let existing = try context.fetch(fetchRequest).first else {
            throw MobileCatalogueRepositoryError.unableToUpdate
        }
        
        existing.name = item.name
        // Handle optional data encoding
        if let itemData = item.data {
            existing.data = try? JSONEncoder().encode(itemData)
        } else {
            existing.data = nil
        }
        
        try context.save()

        if let index = catalogueItems.firstIndex(where: { $0.id == item.id }) {
            catalogueItems[index] = item
        }
    }

    func deleteCatalogueItem(_ item: MobileCatalogueItem) throws {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id)

        if let entityToDelete = try context.fetch(fetchRequest).first {
            context.delete(entityToDelete)
            try context.save()

            catalogueItems.removeAll { $0.id == item.id }
        }
    }
    
    func deleteCatalogue() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            catalogueItems.removeAll()
        } catch {
            print("Failed to delete catalogue: \(error)")
        }
    }
}
