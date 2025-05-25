//
//  MobileCatalogueServiceTests.swift
//  BookxpertTests
//
//  Created by Appaji Tholeti on 25/05/2025.
//

import XCTest
@testable import Bookxpert

final class MobileCatalogueServiceTests: XCTestCase {
    
    func testFetchCatalogueReturnsSuccess() async throws {
        let service = MobileCatalogueService(session: makeMockSession())

        let result = try await service.fetchCatalogue()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "iPhone 15")
    }

    func testFetchCatalogueThrowsServerError() async {
        let mockSession = makeMockSession()
        mockSession.throwError = MobileCatalogueServiceError.serverError
        let service = MobileCatalogueService(session: mockSession)

        do {
            _ = try await service.fetchCatalogue()
            XCTFail("Expected error was not thrown")
        } catch {
            XCTAssertTrue(error is MobileCatalogueServiceError)
        }
    }
    
    private func makeMockSession() -> MockNetworkSession {
        let mockJSON = """
        [
            {
                "id": "1",
                "name": "iPhone 15",
                "data": {
                    "color": "Black",
                    "capacity": "128 GB"
                }
            }
        ]
        """.data(using: .utf8)!

        let url = URL(string: "https://api.restful-api.dev/objects")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        return MockNetworkSession(data: mockJSON, response: response)
    }
}
