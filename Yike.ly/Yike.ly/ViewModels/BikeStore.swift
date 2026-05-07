//
//    Central state manager. Fetches all bike data
//    from the server on launch, polls for coordinate
//    updates every 30 seconds, and handles all user
//    and admin actions (report, repair, hide).
//

import Foundation
import Combine
internal import _LocationEssentials

class BikeStore: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isAdminMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    static let useRealAPI = true
    static let pollInterval: TimeInterval = 30      // 30 second fetch

    private var pollTask: Task<Void, Never>? = nil

    init() {
        Task { await loadBikes() }
    }

    // MARK: - Load
    // Starts with an empty array and populates entirely from the DB.
    // Falls back to an error state if the server is unreachable.
    @MainActor
    func loadBikes() async {
        isLoading = true
        errorMessage = nil
        bikes = []

        if BikeStore.useRealAPI {
            do {
                let dtos = try await NetworkManager.shared.fetchAllBikes()
                bikes = dtos.compactMap { Bike(from: $0) }
                startPolling()
            } catch {
                errorMessage = "Could not reach the Yike.ly server. Please check your connection and try again."
            }
        } else {
            bikes = Bike.simulatedBikes
        }

        isLoading = false
    }

    // MARK: - Polling
    func startPolling() {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(BikeStore.pollInterval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await refreshBikes()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    deinit { stopPolling() }

    // MARK: - Refresh
    // Re-fetches all bike data from the DB and replaces the array,
    // preserving any local state changes (admin hidden, reported issues)
    // that haven't been synced to the server yet.
    @MainActor
    func refreshBikes() async {
        guard let dtos = try? await NetworkManager.shared.fetchAllBikes() else { return }

        var updated = bikes
        for dto in dtos {
            let paddedId = String(format: "YK-%02d", Int(dto.bike_id) ?? 0)
            if let index = updated.firstIndex(where: { $0.id == paddedId }) {
                // Only update coordinates — preserve local state until
                // server-side state management is fully wired up
                updated[index].coordinate.latitude  = Double(dto.latitude)  ?? updated[index].coordinate.latitude
                updated[index].coordinate.longitude = Double(dto.longitude) ?? updated[index].coordinate.longitude
            }
        }
        bikes = updated  // reassign to trigger @Published
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
