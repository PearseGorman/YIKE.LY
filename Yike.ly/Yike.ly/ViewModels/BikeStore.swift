import Foundation
import Combine
internal import _LocationEssentials

class BikeStore: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isAdminMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    static let useRealAPI = true   // ← live — partner's server is up

    init() {
        Task { await loadBikes() }
    }

    // MARK: - Load
    @MainActor
    func loadBikes() async {
        isLoading = true
        errorMessage = nil

        // Always start from the simulated base (names, states, IDs)
        // then overwrite coordinates with live data if the server is reachable.
        bikes = Bike.simulatedBikes

        if BikeStore.useRealAPI {
            await refreshCoordinates()
        }

        isLoading = false
    }

    // MARK: - Refresh coordinates from PHP server
    // Fetches live lat/lon for each bike and merges into the existing bike list.
    // State, name, and reported issues are managed locally until the PHP backend
    // grows to return full bike objects.
    @MainActor
    func refreshCoordinates() async {
        let locations = await NetworkManager.shared.fetchAllCoordinates()

        for (numericId, location) in locations {
            // Bike IDs are "YK-01" ... "YK-12"; numeric IDs are 1...12
            let paddedId = String(format: "YK-%02d", numericId)
            if let index = bikes.firstIndex(where: { $0.id == paddedId }) {
                bikes[index].coordinate.latitude  = location.latitude
                bikes[index].coordinate.longitude = location.longitude
            }
        }
    }

    // MARK: - User Actions
    func reportBike(_ bike: Bike, issue: String) {
        updateLocal(bike.id) {
            $0.state = .needsRepair
            $0.reportedIssue = issue
            $0.lastUpdated = Date()
        }
        if BikeStore.useRealAPI {
            Task { try? await NetworkManager.shared.reportBike(id: bike.id, issue: issue) }
        }
    }

    // MARK: - Admin Actions
    func toggleAdminHidden(_ bike: Bike) {
        let newState: BikeState = bike.state == .hidden ? .available : .hidden
        updateLocal(bike.id) {
            $0.state = newState
            $0.lastUpdated = Date()
        }
        if BikeStore.useRealAPI {
            Task { try? await NetworkManager.shared.updateBikeState(id: bike.id, state: newState.rawValue) }
        }
    }

    func markAsRepaired(_ bike: Bike) {
        updateLocal(bike.id) {
            $0.state = .available
            $0.reportedIssue = nil
            $0.lastUpdated = Date()
        }
        if BikeStore.useRealAPI {
            Task { try? await NetworkManager.shared.updateBikeState(id: bike.id, state: "available") }
        }
    }

    // MARK: - Computed
    var visibleBikes: [Bike] { bikes.filter { $0.state != .hidden } }
    var allBikes: [Bike] { bikes }

    // MARK: - Private
    private func updateLocal(_ id: String, update: (Bike) -> Void) {
        if let index = bikes.firstIndex(where: { $0.id == id }) {
            update(bikes[index])
        }
    }
}
