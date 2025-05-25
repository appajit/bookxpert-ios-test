
import Foundation
import CoreData


protocol DependencyProviding {
    var authService: AuthenticationServicing { get }
    var mobileCatalogueRepository: MobileCatalogueRepositing { get }
    var userDetailsRepository: UserDetailsRepositoryProtcol { get }
    var pdfRepository: PDFRepositoryProtocol { get }
    var persistentContainer: PersistentContainer { get }
}

struct DependencyProvider: DependencyProviding {
    let authService: AuthenticationServicing = AuthenticationService()
    let userDetailsRepository: UserDetailsRepositoryProtcol
    let mobileCatalogueRepository: MobileCatalogueRepositing
    let pdfRepository: PDFRepositoryProtocol = PDFRepository(pdfService: PDFService())
    let persistentContainer: PersistentContainer
    
    init() {
        persistentContainer = NSPersistentContainer(name: "Bookxpert")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        self.userDetailsRepository = UserDetailsRepository(persistentContainer: persistentContainer)
        self.mobileCatalogueRepository = MobileCatalogueRepository(service: MobileCatalogueService(),
                                                                   persistentContainer: persistentContainer)
    }
}
