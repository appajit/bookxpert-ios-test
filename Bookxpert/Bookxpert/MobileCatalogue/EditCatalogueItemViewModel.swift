import Foundation
import Combine

enum ValidationResult {
    case valid
    case invalid([String])
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessages: [String] {
        switch self {
        case .valid:
            return []
        case .invalid(let errors):
            return errors
        }
    }
}


@MainActor
protocol EditCatalogueItemViewModelProtocol: ObservableObject {
    var editedName: String { get set }
    var editableFields: [String: String] { get set }
    var validationErrors: [String] { get set }
    var isValid: Bool { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get }

    func saveItem() async
    func cancelEditing()
    func updateField(key: String, value: String)
}

@MainActor
final class EditCatalogueItemViewModel: EditCatalogueItemViewModelProtocol {
    
    @Published var editedName: String
    @Published var editableFields: [String: String] = [:]
    @Published var validationErrors: [String] = []
    @Published var isValid: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let originalItem: MobileCatalogueItem
    private let repository: MobileCatalogueRepositing
    private var cancellables = Set<AnyCancellable>()
    
    private weak var delegate: EditCatalogueItemViewModelDelegate?
    
    init(item: MobileCatalogueItem, repository: MobileCatalogueRepositing, delegate: EditCatalogueItemViewModelDelegate) {
        self.originalItem = item
        self.repository = repository
        self.editedName = item.name
        self.delegate = delegate
        // Initialize editable fields from item data
        setupEditableFields()
        
        // Setup validation observers
        setupValidationObservers()
    }
    
    func saveItem() async {
        isLoading = true
        do {
            let updatedItem = createUpdatedItem()
            try repository.updateCatalogueItem(updatedItem)
            isLoading = false
            delegate?.finished()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelEditing() {
        delegate?.cancelled()
    }
    
    func updateField(key: String, value: String) {
        editableFields[key] = value
    }
    
    func validateField(key: String, value: String) -> [String] {
        var errors: [String] = []
        
        switch key.lowercased() {
        case "price":
            if !value.isEmpty && Double(value) == nil {
                errors.append("Price must be a valid number")
            }
            if let price = Double(value), price < 0 {
                errors.append("Price cannot be negative")
            }
            
        case "capacity", "storage":
            if !value.isEmpty && !isValidCapacity(value) {
                errors.append("Capacity must be a valid format (e.g., '64 GB', '128GB', '1TB')")
            }
            
        case "year":
            if !value.isEmpty && Int(value) == nil {
                errors.append("Year must be a valid number")
            }
            if let year = Int(value), year < 1900 || year > 2030 {
                errors.append("Year must be between 1900 and 2030")
            }
            
        case "screen size", "screensize":
            if !value.isEmpty && Double(value) == nil {
                errors.append("Screen size must be a valid number")
            }
            
        default:
            // Generic validation for other fields
            if value.count > 100 {
                errors.append("\(key.capitalized) cannot exceed 100 characters")
            }
        }
        
        return errors
    }
    
    private func setupEditableFields() {
        editableFields.removeAll()
        
        if let data = originalItem.data {
            for (key, value) in data {
                editableFields[key] = value.stringValue
            }
        }
    }
    
    private func setupValidationObservers() {
        // Observe name changes
        $editedName
            .dropFirst()
            .sink { [weak self] _ in
                self?.validateCurrentState()
            }
            .store(in: &cancellables)
        
        // Observe field changes
        $editableFields
            .dropFirst()
            .sink { [weak self] _ in
                self?.validateCurrentState()
            }
            .store(in: &cancellables)
    }
    
    
    private func validateCurrentState() {
        let tempItem = createUpdatedItem()
        let result = validateCompleteItem(tempItem)
        
        validationErrors = result.errorMessages
        isValid = result.isValid
    }
    
    private func validateCompleteItem(_ item: MobileCatalogueItem) -> ValidationResult {
        var errors: [String] = []
        
        // Validate name
        if item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name cannot be empty")
        }
        
        if item.name.count > 50 {
            errors.append("Name cannot exceed 50 characters")
        }
        
        // Validate each field
        for (key, value) in editableFields {
            let fieldErrors = validateField(key: key, value: value)
            errors.append(contentsOf: fieldErrors)
        }
        
        // Check for duplicate field names (case insensitive)
        let lowercaseKeys = editableFields.keys.map { $0.lowercased() }
        let uniqueKeys = Set(lowercaseKeys)
        if lowercaseKeys.count != uniqueKeys.count {
            errors.append("Duplicate field names are not allowed")
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    func createUpdatedItem() -> MobileCatalogueItem {
        var updatedData: [String: JSONValue] = [:]
        
        for (key, value) in editableFields {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else { continue }
            
            // Try to preserve original data type or infer new type
            if let originalData = originalItem.data,
               let originalValue = originalData[key] {
                updatedData[key] = convertToOriginalType(value: trimmedValue, originalType: originalValue)
            } else {
                updatedData[key] = inferJSONValueType(from: trimmedValue)
            }
        }
        
        return MobileCatalogueItem(
            id: originalItem.id,
            name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
            data: updatedData.isEmpty ? nil : updatedData
        )
    }
    
    private func convertToOriginalType(value: String, originalType: JSONValue) -> JSONValue {
        switch originalType {
        case .bool(_):
            if let boolValue = Bool(value.lowercased()) {
                return .bool(boolValue)
            }
            // If can't convert to bool, fall back to string
            return .string(value)
            
        case .int(_):
            if let intValue = Int(value) {
                return .int(intValue)
            }
            // If can't convert to int, fall back to string
            return .string(value)
            
        case .double(_):
            if let doubleValue = Double(value) {
                return .double(doubleValue)
            }
            // If can't convert to double, fall back to string
            return .string(value)
            
        case .string(_):
            return .string(value)
        }
    }
    
    private func inferJSONValueType(from value: String) -> JSONValue {
        // Try bool first
        let lowercased = value.lowercased()
        if lowercased == "true" || lowercased == "false" {
            return .bool(lowercased == "true")
        }
        
        // Try int
        if let intValue = Int(value) {
            return .int(intValue)
        }
        
        // Try double
        if let doubleValue = Double(value) {
            return .double(doubleValue)
        }
        
        // Default to string
        return .string(value)
    }
    
    private func isValidCapacity(_ value: String) -> Bool {
        let pattern = #"^\d+\s*(GB|TB|MB|gb|tb|mb)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex?.firstMatch(in: value, range: range) != nil
    }
    
    private func clearValidationErrors() {
        validationErrors.removeAll()
        isValid = true
    }
}


extension EditCatalogueItemViewModel {
    
    var validationSummary: String {
        guard !validationErrors.isEmpty else { return "" }
        return validationErrors.joined(separator: "\n")
    }
    
    var hasChanges: Bool {
        let currentItem = createUpdatedItem()
        return !areItemsEqual(originalItem, currentItem)
    }
    
    private func areItemsEqual(_ item1: MobileCatalogueItem, _ item2: MobileCatalogueItem) -> Bool {
        guard item1.id == item2.id && item1.name == item2.name else { return false }
        
        // Compare data dictionaries
        let data1 = item1.data ?? [:]
        let data2 = item2.data ?? [:]
        
        guard data1.keys.count == data2.keys.count else { return false }
        
        for (key, value1) in data1 {
            guard let value2 = data2[key],
                  value1.stringValue == value2.stringValue else {
                return false
            }
        }
        
        return true
    }
}
