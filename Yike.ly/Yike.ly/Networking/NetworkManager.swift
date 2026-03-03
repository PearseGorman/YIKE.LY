import Foundation

// MARK: - Server Configuration
// Change baseURL to match your server when it's live.
// For local testing: "http://localhost:8080"
// For production:   "https://api.yikely.eckerd.edu" (or wherever you host)

enum APIConfig {
    static let baseURL = "http://localhost:8080"
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid server URL."
        case .noData:               return "No data returned from server."
        case .decodingFailed(let e): return "Failed to decode response: \(e)"
        case .serverError(let code): return "Server returned error code \(code)."
        case .networkError(let e):  return "Network error: \(e)"
        }
    }
}

// MARK: - Data Transfer Objects (match your MariaDB schema exactly)
struct BikeDTO: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let state: String          // "available" | "needsRepair" | "hidden"
    let reportedIssue: String?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, state
        case reportedIssue   = "reported_issue"   // matches MariaDB column name
        case lastUpdated     = "last_updated"
    }
}

struct ReportPayload: Codable {
    let state: String
    let reportedIssue: String

    enum CodingKeys: String, CodingKey {
        case state
        case reportedIssue = "reported_issue"
    }
}

// MARK: - NetworkManager
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: GET /api/bikes
    /// Fetches all bikes from the server.
    func fetchBikes() async throws -> [BikeDTO] {
        let url = try makeURL("/api/bikes")
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decode([BikeDTO].self, from: data)
    }

    // MARK: POST /api/bikes/:id/report
    /// Reports an issue on a specific bike.
    func reportBike(id: String, issue: String) async throws {
        let url = try makeURL("/api/bikes/\(id)/report")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ReportPayload(state: "needsRepair", reportedIssue: issue)
        request.httpBody = try JSONEncoder().encode(payload)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: PATCH /api/bikes/:id/state
    /// Admin: updates a bike's state (e.g. mark repaired, send to shop).
    func updateBikeState(id: String, state: String) async throws {
        let url = try makeURL("/api/bikes/\(id)/state")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["state": state]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Helpers
    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
