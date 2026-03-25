import Foundation
import CoreLocation
import Combine

// MARK: - Bike State
enum BikeState: String, CaseIterable {
    case available   // Yellow  - functional, ready to ride
    case needsRepair // Red     - reported broken, needs Bike Shop attention
    case hidden      // Invisible - in shop for maintenance (admin only)
}

// MARK: - Reported Issue
enum BikeIssue: String, CaseIterable, Identifiable {
    case missingChain   = "Chain missing or broken"
    case brokenPedals   = "Broken pedals"
    case missingSeat    = "Seat missing or damaged"
    case flatTire       = "Flat tire"
    case brokenBrakes   = "Brakes not working"
    case bentFrame      = "Bent or cracked frame"
    case brokenHandlebar = "Broken handlebars"
    case other          = "Other issue"

    var id: String { rawValue }
}

// MARK: - Bike Model
class Bike: Identifiable, ObservableObject {
    let id: String
    let name: String          // e.g. "Yike #7"
    @Published var state: BikeState
    @Published var coordinate: CLLocationCoordinate2D
    @Published var reportedIssue: String?
    @Published var lastUpdated: Date

    init(id: String, name: String, state: BikeState, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.state = state
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.reportedIssue = nil
        self.lastUpdated = Date()
    }
}

// MARK: - Convenience init from network DTO
extension Bike {
    convenience init(from dto: BikeDTO) {
        let state: BikeState
        switch dto.state {
        case "needsRepair": state = .needsRepair
        case "hidden":      state = .hidden
        default:            state = .available
        }
        self.init(id: dto.id, name: dto.name, state: state,
                  latitude: dto.latitude, longitude: dto.longitude)
        self.reportedIssue = dto.reportedIssue
    }
}

// MARK: - Simulated Campus Bike Data
// Coordinates are approximate locations around Eckerd College, St. Petersburg, FL
// Replace with real GPS data once your MariaDB + tracker pipeline is live.
extension Bike {
    static let simulatedBikes: [Bike] = [
        Bike(id: "YK-01", name: "Yike #1",  state: .available,   latitude: 27.7155, longitude: -82.6892),
        Bike(id: "YK-02", name: "Yike #2",  state: .available,   latitude: 27.7160, longitude: -82.6900),
        Bike(id: "YK-03", name: "Yike #3",  state: .available,   latitude: 27.7133, longitude: -82.6918),
        Bike(id: "YK-04", name: "Yike #4",  state: .needsRepair, latitude: 27.7112, longitude: -82.6895),
        Bike(id: "YK-05", name: "Yike #5",  state: .available,   latitude: 27.7123, longitude: -82.6884),
        Bike(id: "YK-06", name: "Yike #6",  state: .available,   latitude: 27.7133, longitude: -82.6871),
        Bike(id: "YK-07", name: "Yike #7",  state: .needsRepair, latitude: 27.7144, longitude: -82.6869),
        Bike(id: "YK-08", name: "Yike #8",  state: .hidden,      latitude: 27.7181, longitude: -82.6898), // In shop
        Bike(id: "YK-09", name: "Yike #9",  state: .available,   latitude: 27.7178, longitude: -82.6885),
        Bike(id: "YK-10", name: "Yike #10", state: .available,   latitude: 27.7170, longitude: -82.6885),
        Bike(id: "YK-11", name: "Yike #11", state: .hidden,      latitude: 27.7149, longitude: -82.6820), // In shop
        Bike(id: "YK-12", name: "Yike #12", state: .available,   latitude: 27.7124, longitude: -82.6859),
    ]
}
