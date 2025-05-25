import SwiftUI

struct MobileCatalogueView<ViewModel>: View where ViewModel: MobileCatalogueViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    @State private var showingDeleteAlert = false
    @State private var selectedItem: MobileCatalogueItem?
    @State private var showingErrorAlert = false


    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .loading(let message):
                    VStack {
                        ProgressView(message)
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let title, let message):
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let list):
                    List {
                        ForEach(list, id: \.id) { item in
                            catalogueItemView(for: item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.showSideMenu()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.fetchCatalogue(forceUpdate: true)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.fetchCatalogue()
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedItem = nil
                }
                Button("Delete", role: .destructive) {
                    if let item = selectedItem {
                        viewModel.deleteItem(item)
                    }
                    selectedItem = nil
                }
            } message: {
                if let item = selectedItem {
                    Text("Are you sure you want to delete '\(item.name)'? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $showingErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            })
            .onChange(of: viewModel.errorMessage) { newValue in
                if newValue != nil {
                    showingErrorAlert = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func catalogueItemView(for item: MobileCatalogueItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.headline)

            ForEach(item.keyValueList, id: \.key) { pair in
                Text("\(pair.key): \(pair.value)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                selectedItem = item
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                viewModel.editItem(item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

}
