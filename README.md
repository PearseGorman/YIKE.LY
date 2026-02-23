# YIKE.LY 🚲
**An Eckerd College Yellow Bike Tracker for iPhone**

---

## Project File Structure

```
YikeLy/
├── YikeLyApp.swift              ← Entry point (you create this in Xcode)
├── ContentView.swift            ← Root view, mounts MapView
│
├── Models/
│   └── Bike.swift               ← Bike data model, BikeState enum, simulated data
│
├── ViewModels/
│   └── BikeStore.swift          ← Central state manager (ObservableObject)
│
└── Views/
    ├── MapView.swift            ← Main map screen (MapKit)
    ├── BikeAnnotationView.swift ← Custom map pin icons (yellow/red/gray)
    ├── BikeDetailSheet.swift    ← Tap-a-bike bottom sheet + report form
    └── AdminView.swift          ← Bike Shop admin panel
```

---

## Setting Up in Xcode

1. **Create a new Xcode project**
   - File → New → Project → iOS → App
   - Product Name: `YikeLy`
   - Interface: SwiftUI
   - Language: Swift

2. **Add all `.swift` files** to the project by dragging them in or using File → Add Files.

3. **Add location permissions** to `Info.plist`:
   ```
   NSLocationWhenInUseUsageDescription  →  "To show your position on campus."
   ```

4. **Enable MapKit** — it's included in the iOS SDK, no additional setup needed.

5. **Run on a simulator or device** — use the iPhone 15 simulator for best results.

---

## Architecture Overview

```
BikeStore (ObservableObject)
    │
    ├── bikes: [Bike]              ← source of truth
    ├── isAdminMode: Bool
    │
    ├── loadSimulatedData()        ← Currently uses hardcoded coords
    ├── refreshCoordinates()       ← TODO: plug in MariaDB API call here
    ├── reportBike(_:issue:)       ← User action
    ├── toggleAdminHidden(_:)      ← Admin action
    └── markAsRepaired(_:)         ← Admin action

MapView
    ├── reads BikeStore.visibleBikes (or allBikes in admin mode)
    ├── renders BikeAnnotationView per bike
    └── opens BikeDetailSheet on tap

BikeDetailSheet
    └── calls BikeStore.reportBike() on submit

AdminView
    └── calls BikeStore.toggleAdminHidden() / markAsRepaired()
```

---

## Wiring Up Your Real Backend (MariaDB)

When your server is ready, replace `loadSimulatedData()` in `BikeStore.swift`:

### 1. MariaDB Table (SQL)
```sql
CREATE TABLE bikes (
    bikeID      VARCHAR(10) PRIMARY KEY,
    name        VARCHAR(50),
    latitude    DOUBLE,
    longitude   DOUBLE,
    state       ENUM('available', 'needsRepair', 'hidden') DEFAULT 'available',
    reported_issue VARCHAR(255),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 2. Simple REST Endpoint (Node.js / Python / PHP)
Your server should expose:
```
GET  /api/bikes         → returns JSON array of all bikes
POST /api/bikes/:id/report  → updates state + issue
```

Example JSON response:
```json
[
  { "id": "YK-01", "name": "Yike #1", "state": "available",
    "latitude": 27.7299, "longitude": -82.7143, "reportedIssue": null }
]
```

### 3. Swift API Call (replace loadSimulatedData)
```swift
func loadFromServer() {
    guard let url = URL(string: "http://YOUR_SERVER/api/bikes") else { return }
    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
        guard let data = data, error == nil else { return }
        let decoded = try? JSONDecoder().decode([BikeDTO].self, from: data)
        DispatchQueue.main.async {
            self?.bikes = decoded?.map { Bike(from: $0) } ?? []
        }
    }.resume()
}
```

---

## GPS Tracker Integration

Once you select a tracker (Traccar recommended for open-source/budget):

- **Traccar**: Devices push GPS data to your Traccar server → you query Traccar's REST API → store in MariaDB → serve to app
- **AirTag / AirPinpoint**: Requires AirPinpoint enterprise subscription, but overcomes the 32-AirTag-per-AppleID limit

For now, simulated coordinates in `Bike.swift` stand in perfectly for demos and peer review.

---

## Auxiliary Features (Future Work)

| Feature | Notes |
|---|---|
| @eckerd.edu login | Can be faked with string suffix check, or use Sign in with Apple |
| Push notifications | Requires APNs setup + server-side push trigger |
| Gamification | Track "rides started" per user session |
| Pathfinding | Needs a graph of campus paths + Dijkstra/A* — ambitious but doable |

---

## Tech Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI + MapKit
- **IDE**: Xcode 15+
- **Database**: MariaDB (via custom REST backend)
- **GPS**: Simulated → Traccar or AirPinpoint
- **Source**: Public GitHub repo (open source to Eckerd community)
