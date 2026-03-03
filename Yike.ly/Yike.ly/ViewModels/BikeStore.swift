import Foundation
import Combine

class BikeStore: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isAdminMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Flip this to true once your server is running
    static let useRealAPI = false

    init() {
        Task { await loadBikes() }
    }

    // MARK: - Load

    @MainActor
    func loadBikes() async {
        isLoading = true
        errorMessage = nil

        if BikeStore.useRealAPI {
            do {
                let dtos = try await NetworkManager.shared.fetchBikes()
                self.bikes = dtos.map { Bike(from: $0) }
            } catch {
                self.errorMessage = error.localizedDescription
                self.bikes = Bike.simulatedBikes // fallback gracefully
            }
        } else {
            self.bikes = Bike.simulatedBikes
        }

        isLoading = false
    }

    // MARK: - User Actions

    func reportBike(_ bike: Bike, issue: String) {
        updateLocal(bike.id) {
            $0.state = .needsRepair
            $0.reportedIssue = issue
            $0.lastUpdated = Date()
        }
        if BikeStore.useRealAPI {
            Task {
                try? await NetworkManager.shared.reportBike(id: bike.id, issue: issue)
            }
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
            Task {
                try? await NetworkManager.shared.updateBikeState(id: bike.id, state: newState.rawValue)
            }
        }
    }

    func markAsRepaired(_ bike: Bike) {
        updateLocal(bike.id) {
            $0.state = .available
            $0.reportedIssue = nil
            $0.lastUpdated = Date()
        }
        if BikeStore.useRealAPI {
            Task {
                try? await NetworkManager.shared.updateBikeState(id: bike.id, state: "available")
            }
        }
    }

    // MARK: - Computed

    var visibleBikes: [Bike] {
        bikes.filter { $0.state != .hidden }
    }

    var allBikes: [Bike] { bikes }

    // MARK: - Private helper
    private func updateLocal(_ id: String, update: (Bike) -> Void) {
        if let index = bikes.firstIndex(where: { $0.id == id }) {
            update(bikes[index])
        }
    }
}
