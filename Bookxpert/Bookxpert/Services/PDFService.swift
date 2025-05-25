
import Foundation
import PDFKit

enum PDFViewerError: LocalizedError {
    case invalidURL
    case networkError(String)
    case invalidPDFData
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid PDF URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidPDFData:
            return "Invalid PDF data"
        case .downloadFailed:
            return "Failed to download PDF"
        }
    }
}


protocol PDFServicing {
    func downloadPDF(from url: URL) async throws -> PDFDocument
}

struct PDFService: PDFServicing {
    let session: NetworkSessioning

    init(session: NetworkSessioning = URLSession.shared) {
        self.session = session
    }

    func downloadPDF(from url: URL) async throws -> PDFDocument {
        var request = URLRequest(url: url)
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PDFViewerError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw PDFViewerError.networkError("HTTP \(httpResponse.statusCode)")
        }

        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFViewerError.invalidPDFData
        }

        return pdfDocument
    }
}
