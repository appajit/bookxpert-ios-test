import Foundation

protocol NetworkSessioning {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSessioning {}
