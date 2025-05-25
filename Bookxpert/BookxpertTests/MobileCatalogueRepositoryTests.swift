import XCTest
import CoreData
import Combine
@testable import Bookxpert

final class MockMobileCatalogueService: MobileCatalogueServicing {
    
    var fetchCatalogueResult: Result<[MobileCatalogueItem], Error>?
    var fetchCatalogueCallCount = 0
    var shouldDelay = false
    var delayDuration: TimeInterval = 0.1
    
    func fetchCatalogue() async throws -> [MobileCatalogueItem] {
        fetchCatalogueCallCount += 1
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        guard let result = fetchCatalogueResult else {
            throw MockServiceError.noResultSet
        }
        
        switch result {
        case .success(let items):
            return items
        case .failure(let error):
            throw error
        }
    }
    
    func setSuccessResult(_ items: [MobileCatalogueItem]) {
        fetchCatalogueResult = .success(items)
    }
    
    func setFailureResult(_ error: Error) {
        fetchCatalogueResult = .failure(error)
    }
    
    func reset() {
        fetchCatalogueResult = nil
        fetchCatalogueCallCount = 0
        shouldDelay = false
        delayDuration = 0.1
    }
}

enum MockServiceError: Error, LocalizedError {
    case noResultSet
    case networkError
    case serverError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noResultSet:
            return "No mock result set for test"
        case .networkError:
            return "Network connection failed"
        case .serverError:
            return "Server returned an error"
        case .invalidData:
            return "Invalid data received"
        }
    }
}

final class MobileCatalogueRepositoryTests: XCTestCase {
    
    private var repository: MobileCatalogueRepository!
    private var mockService: MockMobileCatalogueService!
    private var mockContainer: MockPersistentContainer!
    private var cancellables: Set<AnyCancellable>!
    
    private let testItem1 = MobileCatalogueItem(
        id: "item-1",
        name: "iPhone 15 Pro",
        data: ["brand": .string("Apple"), "price": .double(999.99), "storage": .string("256GB")]
    )
    
    private let testItem2 = MobileCatalogueItem(
        id: "item-2",
        name: "Samsung Galaxy S24",
        data: ["brand": .string("Samsung"), "price": .double(899.99), "color": .string("Black")]
    )
    
    private let testItem3 = MobileCatalogueItem(
        id: "item-3",
        name: "Google Pixel 8",
        data: nil
    )
    
    private var testItems: [MobileCatalogueItem] {
        return [testItem1, testItem2, testItem3]
    }
    
    override func setUp() {
        super.setUp()
        mockService = MockMobileCatalogueService()
        mockContainer = MockPersistentContainer()
        repository = MobileCatalogueRepository(
            service: mockService,
            persistentContainer: mockContainer
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        mockContainer?.clearAllData()
        repository = nil
        mockService = nil
        mockContainer = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchCatalogue_WithForceUpdateTrue_CallsServiceAndSavesToCoreData() async throws {
        // Given
        mockService.setSuccessResult(testItems)
        
        // When
        try await repository.fetchCatalogue(forceUpdate: true)
        
        // Then
        XCTAssertEqual(mockService.fetchCatalogueCallCount, 1)
        XCTAssertEqual(repository.catalogueItems.count, 3)
        XCTAssertEqual(repository.catalogueItems[0].id, testItem1.id)
        XCTAssertEqual(repository.catalogueItems[0].name, testItem1.name)
        
        // Verify data is saved to Core Data
        let context = mockContainer.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        let entities = try context.fetch(fetchRequest)
        XCTAssertEqual(entities.count, 3)
    }
    
    func testFetchCatalogue_WithForceUpdateFalseAndNoStoredData_CallsServiceAndSaves() async throws {
        // Given
        mockService.setSuccessResult(testItems)
        
        // When
        try await repository.fetchCatalogue(forceUpdate: false)
        
        // Then
        XCTAssertEqual(mockService.fetchCatalogueCallCount, 1)
        XCTAssertEqual(repository.catalogueItems.count, 3)
        
        // Verify data is saved to Core Data
        let context = mockContainer.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        let entities = try context.fetch(fetchRequest)
        XCTAssertEqual(entities.count, 3)
    }
    
    func testFetchCatalogue_WithForceUpdateFalseAndStoredData_DoesNotCallService() async throws {
        // Given - First populate Core Data
        mockService.setSuccessResult(testItems)
        try await repository.fetchCatalogue(forceUpdate: true)
        mockService.reset()
        
        // When - Fetch again without force update
        try await repository.fetchCatalogue(forceUpdate: false)
        
        // Then - Should not call service again
        XCTAssertEqual(mockService.fetchCatalogueCallCount, 0)
        XCTAssertEqual(repository.catalogueItems.count, 3)
    }
    
    func testFetchCatalogue_WithServiceError_ThrowsError() async {
        // Given
        let expectedError = MockServiceError.networkError
        mockService.setFailureResult(expectedError)
        
        // When & Then
        do {
            try await repository.fetchCatalogue(forceUpdate: true)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockServiceError)
            XCTAssertEqual(mockService.fetchCatalogueCallCount, 1)
            XCTAssertTrue(repository.catalogueItems.isEmpty)
        }
    }
    
    func testFetchCatalogue_WithEmptyServiceResponse_UpdatesRepositoryCorrectly() async throws {
        // Given
        mockService.setSuccessResult([])
        
        // When
        try await repository.fetchCatalogue(forceUpdate: true)
        
        // Then
        XCTAssertEqual(mockService.fetchCatalogueCallCount, 1)
        XCTAssertTrue(repository.catalogueItems.isEmpty)
    }
    
    
    // MARK: - Update Catalogue Item Tests
    func testUpdateCatalogueItem_WithExistingItem_UpdatesSuccessfully() async throws {
        // Given - First populate with test data
        mockService.setSuccessResult(testItems)
        try await repository.fetchCatalogue(forceUpdate: true)
        
        let updatedItem = MobileCatalogueItem(
            id: testItem1.id,
            name: "iPhone 15 Pro Max Updated",
            data: ["brand": .string("Apple"), "price": .double(1099.00), "storage": .string("512GB")]
        )
        
        // When
        try repository.updateCatalogueItem(updatedItem)
        
        // Then
        let updatedItemInRepo = repository.catalogueItems.first { $0.id == testItem1.id }
        XCTAssertNotNil(updatedItemInRepo)
        XCTAssertEqual(updatedItemInRepo?.name, "iPhone 15 Pro Max Updated")
      //  XCTAssertEqual(updatedItemInRepo?.data?["price"].doubleValue, 1099.00)
        
        // Verify Core Data is updated
        let context = mockContainer.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", testItem1.id)
        
        let entity = try context.fetch(fetchRequest).first
        XCTAssertNotNil(entity)
        XCTAssertEqual(entity?.name, "iPhone 15 Pro Max Updated")
    }
    
    func testUpdateCatalogueItem_WithNonExistentItem_ThrowsError() async throws {
        // Given - Empty repository
        let nonExistentItem = MobileCatalogueItem(id: "non-existent", name: "Test", data: nil)
        
        // When & Then
        XCTAssertThrowsError(try repository.updateCatalogueItem(nonExistentItem)) { error in
            XCTAssertTrue(error is MobileCatalogueRepositoryError)
            XCTAssertEqual(error as? MobileCatalogueRepositoryError, .unableToUpdate)
        }
    }
    
    // MARK: - Delete Catalogue Item Tests
    func testDeleteCatalogueItem_WithExistingItem_DeletesSuccessfully() async throws {
        // Given
        mockService.setSuccessResult(testItems)
        try await repository.fetchCatalogue(forceUpdate: true)
        
        // When
        try? repository.deleteCatalogueItem(testItem1)
        
        // Then
        XCTAssertEqual(repository.catalogueItems.count, 2)
        XCTAssertFalse(repository.catalogueItems.contains { $0.id == testItem1.id })
        
        // Verify Core Data deletion
        let context = mockContainer.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        let entities = try context.fetch(fetchRequest)
        XCTAssertEqual(entities.count, 2)
        XCTAssertFalse(entities.contains { $0.id == testItem1.id })
    }
    
    
    func testDeleteCatalogue_RemovesAllItems() async throws {
        // Given
        mockService.setSuccessResult(testItems)
        try await repository.fetchCatalogue(forceUpdate: true)
        XCTAssertEqual(repository.catalogueItems.count, 3)
        
        // When
        repository.deleteCatalogue()
        
        // Then
        XCTAssertTrue(repository.catalogueItems.isEmpty)
        
        // Verify Core Data is cleared
        let context = mockContainer.viewContext
        let fetchRequest: NSFetchRequest<CatalogueItemEntity> = CatalogueItemEntity.fetchRequest()
        let entities = try context.fetch(fetchRequest)
        XCTAssertTrue(entities.isEmpty)
    }
    
   
    
    func testCatalogueItemsPublisher_EmitsAfterUpdate() async throws {
        // Given
        mockService.setSuccessResult([testItem1])
        try await repository.fetchCatalogue(forceUpdate: true)
        
        var receivedValues: [[MobileCatalogueItem]] = []
        let expectation = XCTestExpectation(description: "Publisher emits after update")
        
        repository.catalogueItemsPublisher
            .dropFirst() // Skip current state
            .sink { items in
                receivedValues.append(items)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let updatedItem = MobileCatalogueItem(id: testItem1.id, name: "Updated", data: nil)
        
        // When
        try repository.updateCatalogueItem(updatedItem)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues[0][0].name, "Updated")
    }
    
    func testCatalogueItemsPublisher_EmitsAfterDelete() async throws {
        // Given
        mockService.setSuccessResult(testItems)
        try await repository.fetchCatalogue(forceUpdate: true)
        
        var receivedValues: [[MobileCatalogueItem]] = []
        let expectation = XCTestExpectation(description: "Publisher emits after delete")
        
        repository.catalogueItemsPublisher
            .dropFirst() // Skip current state
            .sink { items in
                receivedValues.append(items)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try? repository.deleteCatalogueItem(testItem1)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues[0].count, 2)
    }
}
