import Foundation
import PDFKit
import Combine

enum PDFViewState {
    case idle
    case loading
    case loaded(PDFDocument)
    case failed(message: String)
}

@MainActor
protocol PDFViewerViewModelProtocol: ObservableObject {
    var viewState: PDFViewState { get set }
    var currentPage: Int { get set }
    var totalPages: Int { get set }
    var zoomScale: Double { get set }
   
    var isLoaded: Bool { get }
    var canGoToPreviousPage: Bool { get }
    var canGoToNextPage: Bool { get }
    var pageDisplayText: String { get }
    var zoomInfo: String { get }

    func loadPDF() async
    func refreshPDF() async
    func goToNextPage()
    func goToPreviousPage()
    func zoomIn()
    func zoomOut()
}

@MainActor
final class PDFViewerViewModel: PDFViewerViewModelProtocol {
    
    @Published var viewState: PDFViewState = .idle
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 0
    @Published var zoomScale: Double = 1.0
    
    private var pdfURL: URL?
    private var cancellables = Set<AnyCancellable>()
    private let pdfRepository: PDFRepositoryProtocol
    
    var isLoaded: Bool {
        if case .loaded = viewState { return true }
        return false
    }
    
    var canGoToPreviousPage: Bool {
        currentPage > 0
    }
    
    var canGoToNextPage: Bool {
        currentPage < totalPages - 1
    }
    
    var zoomInfo: String {
        if zoomScale == -1 {
            return "Fit Width"
        } else if zoomScale == -2 {
            return "Fit Page"
        } else {
            return String(format: "%.0f%%", zoomScale * 100)
        }
    }
    
    var pageDisplayText: String {
        guard totalPages > 0 else { return "No pages" }
        return "\(currentPage + 1) of \(totalPages)"
    }
    
    init(pdfURL: String, pdfRepository: PDFRepositoryProtocol = PDFRepository()) throws {
        guard let url = URL(string: pdfURL) else {
            throw PDFViewerError.invalidURL
        }
        self.pdfURL = url
        self.pdfRepository = pdfRepository
    }

    init(pdfURL: URL, pdfRepository: PDFRepositoryProtocol = PDFRepository()) {
        self.pdfURL = pdfURL
        self.pdfRepository = pdfRepository
    }
    
    func loadPDF() async {
        guard let pdfURL = pdfURL else {
            await MainActor.run {
                self.viewState = .failed(message: "Failed to Load PDF")
            }
            return
        }

        viewState = .loading
     
        do {
            let pdfDocument = try await pdfRepository.fetchPDFDocument(from: pdfURL)

            await MainActor.run {
                self.viewState = .loaded(pdfDocument)
                self.totalPages = pdfDocument.pageCount
                self.currentPage = 0
                // Start with a reasonable default scale instead of fit mode
                self.zoomScale = 1.0
                
                // Set to fit page after a delay to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.zoomScale = -2 // Fit to page
                }
            }

        } catch {
            await MainActor.run {
                self.viewState = .failed(message: "Failed to Load PDF")
            }
        }
    }
    
    func refreshPDF() async {
        viewState = .idle
        await loadPDF()
    }
    
    func goToNextPage() {
        guard canGoToNextPage else { return }
        currentPage += 1
    }
    
    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        currentPage -= 1
    }
    
    func zoomIn() {
        if zoomScale < 0 {
            // If currently in fit mode, start from 1.0
            zoomScale = 1.25
        } else {
            zoomScale = min(zoomScale * 1.25, 5.0)
        }
    }
    
    func zoomOut() {
        if zoomScale < 0 {
            // If currently in fit mode, start from 1.0
            zoomScale = 0.8
        } else {
            zoomScale = max(zoomScale / 1.25, 0.25)
        }
    }
}

