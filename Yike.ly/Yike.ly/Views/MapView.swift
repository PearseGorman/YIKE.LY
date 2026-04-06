import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var store = BikeStore()
    @EnvironmentObject var session: UserSession

    @State private var selectedBike: Bike? = nil
    @State private var showReportSheet = false
    @State private var showAdminSheet = false
    @State private var mapStyle: MapStyleOption = .standard

    // Eckerd College campus center
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 27.7151, longitude: -82.6866),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: Map
            Map(position: $cameraPosition) {
                UserAnnotation()

                let displayBikes = store.isAdminMode ? store.allBikes : store.visibleBikes
                ForEach(displayBikes) { bike in
                    Annotation(bike.name, coordinate: bike.coordinate) {
                        BikeAnnotationView(bike: bike, isAdminMode: store.isAdminMode)
                            .onTapGesture {
                                selectedBike = bike
                                showReportSheet = true
                            }
                    }
                }
            }
            .mapStyle(mapStyle.mkStyle)
            .mapControls {
                MapUserLocationButton()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)

            // MARK: Top Bar + Bottom Bar
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        // Sync admin mode with session role on appear
        .onAppear {
            if session.isAdmin {
                store.isAdminMode = true
            }
        }
        // MARK: Bike Detail Sheet
        .sheet(item: $selectedBike) { bike in
            BikeDetailSheet(bike: bike, store: store, isAdminMode: store.isAdminMode)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // MARK: Admin Panel Sheet — only reachable for admins
        .sheet(isPresented: $showAdminSheet) {
            AdminView(store: store, session: session)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // App title + logged-in user
            VStack(alignment: .leading, spacing: 2) {
                Text("YIKE.LY")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text("Hi, \(session.displayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Map style picker
            Menu {
                ForEach(MapStyleOption.allCases, id: \.self) { style in
                    Button {
                        mapStyle = style
                    } label: {
                        Label(style.label, systemImage: style.icon)
                    }
                }
            } label: {
                Image(systemName: "map")
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }

            // Admin button — only visible to admins
            if session.isAdmin {
                Button {
                    showAdminSheet = true
                } label: {
                    Image(systemName: "wrench.fill")
                        .padding(10)
                        .background(Color.orange.opacity(0.2), in: Circle())
                        .overlay(Circle().stroke(Color.orange, lineWidth: 1.5))
                }
                .tint(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Legend Bar
    private var bottomBar: some View {
        HStack(spacing: 20) {
            LegendItem(color: .yellow, label: "Available")
            LegendItem(color: .red,    label: "Needs Repair")
            if store.isAdminMode {
                LegendItem(color: .gray, label: "In Shop")
            }
            Spacer()
            Text("\(store.visibleBikes.filter { $0.state == .available }.count) available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Map Style Options
enum MapStyleOption: CaseIterable {
    case standard, satellite, hybrid

    var label: String {
        switch self {
        case .standard:  return "Map"
        case .satellite: return "Satellite"
        case .hybrid:    return "Hybrid"
        }
    }

    var icon: String {
        switch self {
        case .standard:  return "map"
        case .satellite: return "globe.americas.fill"
        case .hybrid:    return "map.fill"
        }
    }

    var mkStyle: MapStyle {
        switch self {
        case .standard:  return .standard
        case .satellite: return .imagery
        case .hybrid:    return .hybrid
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.6), radius: 3)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(UserSession())
}
