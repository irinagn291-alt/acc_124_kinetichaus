import Foundation
import Network

enum Endpoint {
    case openFoodFactsSearch(query: String)
    case openLibrarySearch(query: String, language: String?)

    var url: URL {
        switch self {
        case .openFoodFactsSearch(let query):
            var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
            components.queryItems = [
                URLQueryItem(name: "search_terms", value: query),
                URLQueryItem(name: "search_simple", value: "1"),
                URLQueryItem(name: "action", value: "process"),
                URLQueryItem(name: "json", value: "1"),
                URLQueryItem(name: "page_size", value: "20")
            ]
            return components.url!

        case .openLibrarySearch(let query, let language):
            var components = URLComponents(string: "https://openlibrary.org/search.json")!
            var items = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "20")
            ]
            if let language {
                items.append(URLQueryItem(name: "language", value: language))
            }
            components.queryItems = items
            return components.url!
        }
    }

    var method: String { "GET" }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case offline
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid request URL."
        case .invalidResponse: "Invalid server response."
        case .httpStatus(let code): "Server error. Code: \(code)."
        case .decodingFailed: "Failed to process received data."
        case .offline: "No Internet Connection."
        case .timeout: "The request timed out."
        case .unknown: "Something went wrong."
        }
    }
}

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class APIClient: APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("KineticHaus/1.0 (offline-first fitness planner)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpStatus(httpResponse.statusCode)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut: throw APIError.timeout
            case .notConnectedToInternet, .networkConnectionLost: throw APIError.offline
            default: throw APIError.unknown
            }
        } catch {
            throw APIError.unknown
        }
    }
}

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
