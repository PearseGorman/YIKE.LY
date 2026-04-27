import Foundation

// MARK: - Server Configuration
enum APIConfig {
    static let baseURL   = "http://51.79.65.180"
    static let bikeCount = 12
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
        case .invalidURL:            return "Invalid server URL."
        case .noData:                return "No data returned from server."
        case .decodingFailed(let e): return "Failed to decode response: \(e)"
        case .serverError(let code): return "Server returned error code \(code)."
        case .networkError(let e):   return "Network error: \(e)"
        }
    }
}

// MARK: - BikeDTO
// Matches get_all_bikes.php response exactly.
// bike_id comes back as a String from PHP even though it's an Int in the DB.
struct BikeDTO: Codable {
    let bike_id:       String
    let name:          String
    let latitude:      String   // PHP returns doubles as strings
    let longitude:     String
    let state:         String
    let reportedIssue: String?
}

// MARK: - ReportPayload
struct ReportPayload: Codable {
    let state:         String
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
    private let decoder = JSONDecoder()

    // MARK: GET /get_all_bikes.php
    // Returns all bikes with full data — replaces per-bike coordinate fetching.
    func fetchAllBikes() async throws -> [BikeDTO] {
        guard let url = URL(string: "\(APIConfig.baseURL)/get_all_bikes.php")
        else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decoder.decode([BikeDTO].self, from: data)
    }

    // MARK: POST /api/bikes/:id/report
    func reportBike(id: String, issue: String) async throws {
        let url = try makeURL("/api/bikes/\(id)/report")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ReportPayload(state: "needsRepair", reportedIssue: issue)
        )
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: PATCH /api/bikes/:id/state
    func updateBikeState(id: String, state: String) async throws {
        let url = try makeURL("/api/bikes/\(id)/state")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["state": state])
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Helpers
    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: APIConfig.baseURL + path)
        else { throw APIError.invalidURL }
        return url
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }
    }
}
