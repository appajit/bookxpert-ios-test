import XCTest
import CoreData
@testable import Bookxpert


final class UserDetailsRepositoryTests: XCTestCase {
    
    private var repository: UserDetailsRepository!
    private var mockContainer: MockPersistentContainer!
    
    private let testUserDetails = UserDetails(
        email: "test@example.com",
        displayName: "Test User",
        uid: "test-uid-123",
        profileImage: Data("test-image".utf8)
    )
    
    private let updatedUserDetails = UserDetails(
        email: "updated@example.com",
        displayName: "Updated User",
        uid: "test-uid-123",
        profileImage: Data("updated-image".utf8)
    )
    
    override func setUp() {
        super.setUp()
        mockContainer = MockPersistentContainer()
        repository = UserDetailsRepository(persistentContainer: mockContainer)
    }
    
    override func tearDown() {
        // Clear data first, then nil the objects
        mockContainer?.clearAllData()
        repository = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func testSaveUserDetails_WithValidData_SavesSuccessfully() {
        // When
        repository.saveUserDetails(testUserDetails)
        
        // Then
        let savedDetails = repository.getUserDetails()
        XCTAssertNotNil(savedDetails)
        XCTAssertEqual(savedDetails?.email, testUserDetails.email)
        XCTAssertEqual(savedDetails?.displayName, testUserDetails.displayName)
        XCTAssertEqual(savedDetails?.uid, testUserDetails.uid)
        XCTAssertEqual(savedDetails?.profileImage, testUserDetails.profileImage)
    }
    
    func testSaveUserDetails_WithNilEmail_SavesCorrectly() {
        // Given
        let userDetailsWithNilEmail = UserDetails(
            email: nil,
            displayName: "Test User",
            uid: "test-uid",
            profileImage: nil
        )
        
        // When
        repository.saveUserDetails(userDetailsWithNilEmail)
        
        // Then
        let savedDetails = repository.getUserDetails()
        XCTAssertNotNil(savedDetails)
        XCTAssertNil(savedDetails?.email)
        XCTAssertEqual(savedDetails?.displayName, "Test User")
        XCTAssertEqual(savedDetails?.uid, "test-uid")
    }
    
   
    
    func testGetUserDetails_WhenDataExists_ReturnsCorrectData() {
        // Given
        repository.saveUserDetails(testUserDetails)
        
        // When
        let retrievedDetails = repository.getUserDetails()
        
        // Then
        XCTAssertNotNil(retrievedDetails)
        XCTAssertEqual(retrievedDetails?.email, testUserDetails.email)
        XCTAssertEqual(retrievedDetails?.displayName, testUserDetails.displayName)
        XCTAssertEqual(retrievedDetails?.uid, testUserDetails.uid)
        XCTAssertEqual(retrievedDetails?.profileImage, testUserDetails.profileImage)
    }
    
    func testGetUserDetails_UsesCachedDataOnSubsequentCalls() {
        // Given
        repository.saveUserDetails(testUserDetails)
        
        // When - Call getUserDetails multiple times
        let firstCall = repository.getUserDetails()
        let secondCall = repository.getUserDetails()
        let thirdCall = repository.getUserDetails()
        
        // Then - All calls should return the same data
        XCTAssertNotNil(firstCall)
        XCTAssertNotNil(secondCall)
        XCTAssertNotNil(thirdCall)
        
        XCTAssertEqual(firstCall?.uid, testUserDetails.uid)
        XCTAssertEqual(secondCall?.uid, testUserDetails.uid)
        XCTAssertEqual(thirdCall?.uid, testUserDetails.uid)
    }
    
    func testIsUserLoggedIn_WhenNoUserExists_ReturnsFalse() {
        // When
        let isLoggedIn = repository.isUserLoggedIn
        
        // Then
        XCTAssertFalse(isLoggedIn)
    }
    
    func testIsUserLoggedIn_WhenUserExists_ReturnsTrue() {
        // Given
        repository.saveUserDetails(testUserDetails)
        
        // When
        let isLoggedIn = repository.isUserLoggedIn
        
        // Then
        XCTAssertTrue(isLoggedIn)
    }
    
    
    func testSaveProfileImage_WhenUserExists_UpdatesImage() {
        // Given
        repository.saveUserDetails(testUserDetails)
        let newImageData = Data("new-profile-image".utf8)
        
        // When
        repository.saveProfileImage(newImageData)
        
        // Then
        let updatedDetails = repository.getUserDetails()
        XCTAssertNotNil(updatedDetails)
        XCTAssertEqual(updatedDetails?.profileImage, newImageData)
        XCTAssertEqual(updatedDetails?.email, testUserDetails.email) // Other data unchanged
        XCTAssertEqual(updatedDetails?.displayName, testUserDetails.displayName)
        XCTAssertEqual(updatedDetails?.uid, testUserDetails.uid)
    }
    
   
    
    func testDeleteUserDetails_WhenUserExists_RemovesData() {
        // Given
        repository.saveUserDetails(testUserDetails)
        XCTAssertNotNil(repository.getUserDetails())
        
        // When
        repository.deleteUserDetails()
        
        // Then
        XCTAssertNil(repository.getUserDetails())
        XCTAssertFalse(repository.isUserLoggedIn)
    }
    
    func testDeleteUserDetails_WhenNoUserExists_DoesNothing() {
        // Given - No user exists
        XCTAssertNil(repository.getUserDetails())
        
        // When
        repository.deleteUserDetails()
        
        // Then - Should still be nil and not crash
        XCTAssertNil(repository.getUserDetails())
        XCTAssertFalse(repository.isUserLoggedIn)
    }
    

}

extension UserDetailsRepositoryTests {
    
    private func getUserDetailsEntityCount() -> Int {
        let context = mockContainer.viewContext
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        return (try? context.fetch(request).count) ?? 0
    }
    
    private func getFirstUserDetailsEntity() -> UserDetailsEntity? {
        let context = mockContainer.viewContext
        let request: NSFetchRequest<UserDetailsEntity> = UserDetailsEntity.fetchRequest()
        return try? context.fetch(request).first
    }
}
