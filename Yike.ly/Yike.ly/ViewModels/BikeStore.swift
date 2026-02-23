import Foundation
import Combine

// BikeStore acts as the single source of truth for all bike state.
// When you wire up the MariaDB backend, replace `loadSimulatedData()`
// with a real network call to your server endpoint.

class BikeStore: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isAdminMode: Bool = false  // toggled via the admin UI

    init() {
        loadSimulatedData()
    }

    // MARK: - Data Loading

    /// Loads hardcoded simulated bikes. Swap this out for a real API call later.
    func loadSimulatedData() {
        bikes = Bike.simulatedBikes
    }

    /// Simulates refreshing GPS coordinates from the server.
    /// In production: GET /api/bikes → decode JSON → update bikes array.
    func refreshCoordinates() {
        // TODO: Replace with URLSession call to your MariaDB-backed REST API
        // Example:
        //   URLSession.shared.dataTask(with: URL(string: "http://yourserver/api/bikes")!) { data, _, _ in
        //       guard let data = data else { return }
        //       let decoded = try? JSONDecoder().decode([BikeDTO].self, from: data)
        //       DispatchQueue.main.async { self.bikes = decoded.map { Bike($0) } }
        //   }.resume()
        print("Refresh triggered — plug in your API call here.")
    }

    // MARK: - User Actions

    /// User reports a bike as needing repair with a described issue.
    func reportBike(_ bike: Bike, issue: String) {
        if let index = bikes.firstIndex(where: { $0.id == bike.id }) {
            bikes[index].state = .needsRepair
            bikes[index].reportedIssue = issue
            bikes[index].lastUpdated = Date()
        }
    }

    // MARK: - Admin Actions

    /// Admin toggles a bike's visibility (e.g. pulled into the shop).
    func toggleAdminHidden(_ bike: Bike) {
        if let index = bikes.firstIndex(where: { $0.id == bike.id }) {
            bikes[index].state = bikes[index].state == .hidden ? .available : .hidden
            bikes[index].lastUpdated = Date()
        }
    }

    /// Admin marks a repaired bike back to available.
    func markAsRepaired(_ bike: Bike) {
        if let index = bikes.firstIndex(where: { $0.id == bike.id }) {
            bikes[index].state = .available
            bikes[index].reportedIssue = nil
            bikes[index].lastUpdated = Date()
        }
    }

    // MARK: - Computed helpers

    /// Bikes visible to regular users (available + needsRepair only)
    var visibleBikes: [Bike] {
        bikes.filter { $0.state != .hidden }
    }

    /// All bikes including hidden — for admin view
    var allBikes: [Bike] {
        bikes
    }
}
