import SwiftUI
import PDFKit

struct PDFViewerView<ViewModel>: View where ViewModel: PDFViewerViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // PDF Content
                pdfContentView
                
                // Bottom Controls
                if viewModel.isLoaded {
                    bottomControlsView
                }
            }
            .navigationTitle("PDF Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshPDF()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadPDF()
        }
    }
    
    @ViewBuilder
    private var pdfContentView: some View {
        switch viewModel.viewState {
        case .idle:
            EmptyView()
            
        case .loading:
            loadingView
            
        case .loaded(let pdfDocument):
            PDFKitRepresentable(
                document: pdfDocument,
                currentPage: $viewModel.currentPage,
                zoomScale: $viewModel.zoomScale
            )
            
        case .failed(let error):
            errorView(error)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading PDF...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Please wait while we download the document")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Failed to Load PDF")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.loadPDF()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            Divider()
            
            // Page Navigation
            HStack {
                Button {
                    viewModel.goToPreviousPage()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                .disabled(!viewModel.canGoToPreviousPage)
                
                Spacer()
                
                Text(viewModel.pageDisplayText)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    viewModel.goToNextPage()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .disabled(!viewModel.canGoToNextPage)
            }
            .padding(.horizontal)
            
            // Zoom Controls
            HStack(spacing: 20) {
                Button {
                    viewModel.zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title3)
                }
                
                Text(viewModel.zoomInfo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(minWidth: 50)
                
                Button {
                    viewModel.zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title3)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct PDFKitRepresentable: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var zoomScale: Double
   
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.delegate = context.coordinator
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update current page
        if let page = document.page(at: currentPage), pdfView.currentPage != page {
            pdfView.go(to: page)
        }
        
        // Handle zoom scale changes with delay to ensure bounds are set
        let currentScale = pdfView.scaleFactor
        if abs(currentScale - zoomScale) > 0.01 {
            if zoomScale > 0 {
                pdfView.scaleFactor = zoomScale
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    context.coordinator.fitToPage(pdfView)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFKitRepresentable
        
        init(_ parent: PDFKitRepresentable) {
            self.parent = parent
        }
        
        func pdfViewCurrentPageDidChange(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let pageIndex = pdfView.document?.index(for: currentPage) {
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex
                }
            }
        }
        
        func fitToPage(_ pdfView: PDFView) {
            guard let currentPage = pdfView.currentPage else { return }
            
            let pageRect = currentPage.bounds(for: .mediaBox)
            let pdfViewRect = pdfView.bounds
            
            // Ensure pdfView has valid bounds
            guard pdfViewRect.width > 0 && pdfViewRect.height > 0 else {
                // Retry after a longer delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.fitToPage(pdfView)
                }
                return
            }
            
            // Calculate scale to fit both width and height
            let widthScale = pdfViewRect.width / pageRect.width
            let heightScale = pdfViewRect.height / pageRect.height
            let scale = min(widthScale, heightScale)
            let finalScale = max(scale, 0.1) // Minimum scale of 10%
            
            pdfView.scaleFactor = finalScale
            
            // Update the binding to reflect actual scale
            DispatchQueue.main.async {
                self.parent.zoomScale = finalScale
            }
        }
    }
}
