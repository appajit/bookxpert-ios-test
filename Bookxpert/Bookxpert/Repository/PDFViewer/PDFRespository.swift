
import Foundation
import PDFKit

protocol PDFRepositoryProtocol {
    func fetchPDFDocument(from url: URL) async throws -> PDFDocument
}

final class PDFRepository: PDFRepositoryProtocol {
    private let pdfService: PDFServicing
    private var cache: [URL: PDFDocument] = [:]

    init(pdfService: PDFServicing = PDFService()) {
        self.pdfService = pdfService
    }

    func fetchPDFDocument(from url: URL) async throws -> PDFDocument {
        if let cached = cache[url] {
            return cached
        }

        let document = try await pdfService.downloadPDF(from: url)
        cache[url] = document
        return document
    }
}
