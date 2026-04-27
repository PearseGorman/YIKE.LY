import Foundation

// MARK: - Server Configuration
enum APIConfig {
    static let baseURL    = "http://51.79.65.180"   // ← your partner's server
    static let bikeCount  = 12                       // ← update if fleet size changes
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

// MARK: - BikeLocation
// Matches your partner's PHP endpoint response exactly.
// { "latitude": 27.7299, "longitude": -82.7143, "timestamp": "..." }
struct BikeLocation: Codable {
    let latitude:  Double
    let longitude: Double
    let timestamp: String
}

// MARK: - BikeDTO
// Used for future full-bike endpoints (state, name, reported_issue etc.)
// when the PHP backend expands to return complete bike objects.
struct BikeDTO: Codable {
    let id:            String
    let name:          String
    let latitude:      Double
    let longitude:     Double
    let state:         String
    let reportedIssue: String?
    let lastUpdated:   String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, state
        case reportedIssue = "reported_issue"
        case lastUpdated   = "last_updated"
    }
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

    // MARK: Fetch coordinates for all bikes
    // Calls your partner's PHP endpoint once per bike ID in parallel,
    // returns a dictionary of [numericID: BikeLocation] for BikeStore to merge.
    // When the PHP backend grows to return a full bike list in one call,
    // replace this method with a single fetchBikes() → [BikeDTO] call.
    func fetchAllCoordinates() async -> [Int: BikeLocation] {
        await withTaskGroup(of: (Int, BikeLocation)?.self) { group in
            for bikeId in 1...APIConfig.bikeCount {
                group.addTask {
                    guard let location = try? await self.fetchCoordinate(for: bikeId)
                    else { return nil }
                    return (bikeId, location)
                }
            }
            var results: [Int: BikeLocation] = [:]
            for await result in group {
                if let (id, location) = result {
                    results[id] = location
                }
            }
            return results
        }
    }

    // MARK: GET /get_bike_location.php?bike_id=N
    private func fetchCoordinate(for bikeId: Int) async throws -> BikeLocation {
        guard let url = URL(string: "\(APIConfig.baseURL)/get_bike_location.php?bike_id=\(bikeId)")
        else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decoder.decode(BikeLocation.self, from: data)
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
