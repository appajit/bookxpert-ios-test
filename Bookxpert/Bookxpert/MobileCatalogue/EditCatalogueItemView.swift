import SwiftUI
import Combine

struct EditCatalogueItemView<ViewModel>: View where ViewModel: EditCatalogueItemViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Catalogue Item Details") {
                    TextField("Name", text: $viewModel.editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !viewModel.validationErrors.isEmpty {
                        ValidationErrorView(errors: viewModel.validationErrors)
                    }
                }
                
                Section {
                    ForEach(Array(viewModel.editableFields.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized)
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.primary)
                            
                            TextField("Value", text: Binding(
                                get: { viewModel.editableFields[key] ?? "" },
                                set: { viewModel.updateField(key: key, value: $0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancelTap()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveItem()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Saving...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
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
    
    private func handleCancelTap() {
        viewModel.cancelEditing()
    }
}

struct ValidationErrorView: View {
    let errors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(errors, id: \.self) { error in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
