import Foundation
@testable import Bookxpert

class MockNetworkSession: NetworkSessioning {
        let data: Data
        let response: URLResponse

        var throwError: Error?
        init(data: Data, response: URLResponse) {
            self.data = data
            self.response = response
        }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if throwError != nil {
                throw throwError!
            } else {
                return (data, response)
            }
        }
    }
