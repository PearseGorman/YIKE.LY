# YIKE.LY 🚲
**An Eckerd College Yellow Bike Tracker for iPhone**
*Capstone Project — Eckerd College, Spring 2026*
*Developed by Chris Vogt & Pearse Gorman*

---

## Overview
Yike.ly is a native iOS application that allows Eckerd College students to view the real-time locations of campus Yellow Bikes (Yikes) on an interactive map. Bike Shop staff have access to an admin panel for managing bike states and visibility.

---

## Project File Structure

```
Yike.ly/
├── ContentView.swift                ← Root view, routes between Login and Map
│
├── Models/
│   ├── Bike.swift                   ← Bike data model, BikeState enum, simulated fallback data
│   └── UserSession.swift            ← Auth state, role, and UserDefaults persistence
│
├── ViewModels/
│   └── BikeStore.swift              ← Central state manager, polling loop, DB sync
│
├── Views/
│   ├── MapView.swift                ← Main map screen (MapKit)
│   ├── BikeAnnotationView.swift     ← Custom map pin icons (yellow/red/gray)
│   ├── BikeDetailSheet.swift        ← Tap-a-bike bottom sheet + report form
│   ├── AdminView.swift              ← Bike Shop admin panel
│   ├── LoginView.swift              ← First-launch email entry screen
│   └── ServerErrorView.swift        ← Shown when server is unreachable
│
└── Networking/
    ├── NetworkManager.swift         ← All API calls (fetchAllBikes, report, state)
    └── AuthManager.swift            ← Email validation and role resolution
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| Framework | SwiftUI + MapKit |
| IDE | Xcode 15+ |
| Database | MariaDB (via PHP REST endpoints) |
| Backend | PHP on Ubuntu Linux (OVHcloud VPS) |
| GPS | Python simulator (real tracker integration ready) |
| Source | Public GitHub repository |

---

## Architecture

```
[Python GPS Simulator]
        ↓  writes lat/lon every 30s
[MariaDB — bike_project DB]
        ↓  yellow_bike_coordinates table
[PHP REST API — 51.79.65.180]
        ↓  HTTP JSON
[Yike.ly iPhone App]
    ├── NetworkManager  — fetches all bikes via get_all_bikes.php
    ├── BikeStore       — polls every 30s, manages state
    ├── UserSession     — persists login across launches
    └── MapView         — renders pins, handles user interaction
```

---

## Database Schema

**Table: `yellow_bike_coordinates`** (database: `bike_project`)

| Column | Type | Notes |
|---|---|---|
| `id` | INT | Auto-increment primary key |
| `bike_id` | INT | 1–12, maps to YK-01–YK-12 in app |
| `name` | VARCHAR | e.g. "Yike #1" |
| `latitude` | DOUBLE | Updated by simulator every 30s |
| `longitude` | DOUBLE | Updated by simulator every 30s |
| `timestamp` | TIMESTAMP | Last GPS update time |
| `state` | ENUM | `available`, `needsRepair`, `hidden` |
| `reportedIssue` | VARCHAR | Populated when user reports a problem |

---

## PHP Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/get_all_bikes.php` | GET | Returns all bikes as JSON array |
| `/get_bike_location.php?bike_id=N` | GET | Returns coordinates for a single bike |

---

## Server Files (`/var/www/html/` on VPS)

| File | Purpose |
|---|---|
| `get_all_bikes.php` | Serves full bike list to the app |
| `get_bike_location.php` | Legacy single-bike coordinate endpoint |
| `yikely_simulator.py` | GPS movement simulator (runs as systemd service) |

---

## GPS Simulator

The simulator (`yikely_simulator.py`) runs as a persistent background service on the VPS, updating bike coordinates in MariaDB every 30 seconds. Movement behavior varies by bike state:

- **available** — normal random walk (bike is being ridden/moved around campus)
- **needsRepair** — minimal jitter only (broken bike sitting in place)
- **hidden** — no movement (bike is on a workbench in the shop)

**Managing the simulator:**
```bash
sudo systemctl status yikely-simulator    # check status
sudo systemctl restart yikely-simulator   # restart after changes
sudo systemctl stop yikely-simulator      # stop (e.g. when real trackers go live)
```

**Logs:**
```bash
sudo journalctl -u yikely-simulator -f    # live log stream
cat ~/yikely_simulator.log                # file log
```

---

## Authentication

Login requires a valid `@eckerd.edu` email address. Role resolution:

- Any `@eckerd.edu` address → standard user (map view only)
- Emails in `localAdminEmails` in `AuthManager.swift` → Bike Shop admin (admin panel, locked on)

Admin emails are currently hardcoded in `AuthManager.swift`. When the server-side `users` table is implemented, set `BikeStore.useRealAPI = true` in `AuthManager` to switch to DB-backed role resolution.

**To add an admin email during development:**
```swift
// In AuthManager.swift
private let localAdminEmails: Set<String> = [
    "bikeshop@eckerd.edu",
    "yourname@eckerd.edu",   // ← add here
]
```

---

## Bike States

| State | Map Icon | Meaning |
|---|---|---|
| `available` | 🟡 Yellow | Functional, ready to ride |
| `needsRepair` | 🔴 Red (pulsing) | Reported broken, needs Bike Shop attention |
| `hidden` | ⚫ Gray (admin only) | In shop for maintenance, invisible to students |

---

## For Future Developers

### Swapping in Real GPS Trackers
The simulator is the only piece that needs replacing. When real AirTag/Traccar trackers are live:

1. Stop the simulator:
```bash
sudo systemctl stop yikely-simulator
sudo systemctl disable yikely-simulator
```
2. Point your tracker integration at the same `UPDATE yellow_bike_coordinates SET latitude = ?, longitude = ? WHERE bike_id = ?` query
3. The PHP API, app, and all other server infrastructure require **zero changes**

### Wiring Up Server-Side Auth
When a `users` table exists on the server:
1. Add a `POST /api/auth/role` endpoint to the PHP backend
2. In `AuthManager.swift`, change:
```swift
if BikeStore.useRealAPI && false {   // remove the && false
```

### Known Limitations / Future Work
- Bike state changes (report, repair, hide) are managed locally in the app — not yet persisted back to the DB via PHP endpoints
- Auth is local only — no server-side session or token system
- No `@eckerd.edu` email verification beyond suffix checking
- Potential auxiliary features: push notifications, gamification, pathfinding, Sign in with Apple

---

## Running the Project

1. Clone the repo and open `Yike.ly.xcodeproj` in Xcode 15+
2. Ensure `Info.plist` has `NSAppTransportSecurity` → `NSAllowsArbitraryLoads` = YES (dev only)
3. Add your `@eckerd.edu` email to `localAdminEmails` in `AuthManager.swift` if you need admin access
4. Build and run on iPhone 15 simulator or a physical device
5. Log in with any `@eckerd.edu` address to access the map

---

## Open Source
This project and all non-sensitive source code is free and open to the Eckerd College community. It lives in a public GitHub repository for future student developers to build upon.

