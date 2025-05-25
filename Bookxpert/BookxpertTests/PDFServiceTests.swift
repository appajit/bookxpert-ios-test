//
//  PDFServiceTests.swift
//  BookxpertTests
//
//  Created by Appaji Tholeti on 25/05/2025.
//

import XCTest
import PDFKit
@testable import Bookxpert

final class PDFServiceTests: XCTestCase {
    func testDownloadPDFReturnsValidDocument() async throws {
        guard let pdfPath = Bundle(for: type(of: self)).url(forResource: "sample", withExtension: "pdf"),
              let pdfData = try? Data(contentsOf: pdfPath) else {
            XCTFail("Missing or unreadable sample.pdf in test bundle")
            return
        }

        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!

        let mockSession = MockNetworkSession(data: pdfData, response: response)
        let service = PDFService(session: mockSession)

        let result = try await service.downloadPDF(from: URL(string: "https://example.com")!)
        XCTAssertNotNil(result)
        XCTAssertTrue(result.pageCount > 0)
    }

    func testDownloadPDFThrowsOnInvalidResponse() async throws {
        let dummyData = Data()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 404,
                                       httpVersion: nil,
                                       headerFields: nil)!

        let mockSession = MockNetworkSession(data: dummyData, response: response)
        let service = PDFService(session: mockSession)

        do {
            _ = try await service.downloadPDF(from: URL(string: "https://example.com")!)
            XCTFail("Expected error was not thrown")
        } catch {
            guard case PDFViewerError.networkError(let message) = error else {
                XCTFail("Unexpected error type: \(error)")
                return
            }
            XCTAssertTrue(message.contains("HTTP 404"))
        }
    }
}
