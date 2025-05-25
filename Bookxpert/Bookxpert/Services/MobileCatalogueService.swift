import Foundation

struct APIConstants {
    static let catalogueURL = "https://api.restful-api.dev/objects"
}

enum MobileCatalogueServiceError: LocalizedError {
    case invalidURL
    case networkError(String)
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid PDF URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError:
            return "Server Error"
        }
    }
}


protocol MobileCatalogueServicing {
    func fetchCatalogue() async throws -> [MobileCatalogueItem]
}

struct MobileCatalogueItem: Codable {
    let id: String
    let name: String
    let data: [String: JSONValue]?
}

extension MobileCatalogueItem {
    var keyValueList: [(key: String, value: String)] {
        data?.compactMap { key, value in
            (key, value.stringValue)
        }.sorted { $0.key < $1.key } ?? []
    }
}

enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            if doubleVal.truncatingRemainder(dividingBy: 1) == 0 {
                self = .int(Int(doubleVal))
            } else {
                self = .double(doubleVal)
            }
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported value")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .bool(let bool):
            try container.encode(bool)
        }
    }
}
extension JSONValue {
    var stringValue: String {
        switch self {
        case .string(let str): return str
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        }
    }
}

final class MobileCatalogueService: MobileCatalogueServicing {
    private let session: NetworkSessioning

    init(session: NetworkSessioning = URLSession.shared) {
        self.session = session
    }

    func fetchCatalogue() async throws -> [MobileCatalogueItem] {
        guard let url = URL(string: APIConstants.catalogueURL) else {
            throw MobileCatalogueServiceError.invalidURL
        }

        do {
            let request = URLRequest(url: url)
            let (data, _) = try await  session.data(for: request)
            let items = try JSONDecoder().decode([MobileCatalogueItem].self, from: data)
            return items
        } catch {
            throw MobileCatalogueServiceError.serverError
        }
    }
}
