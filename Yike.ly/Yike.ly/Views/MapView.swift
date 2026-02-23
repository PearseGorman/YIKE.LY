import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var store = BikeStore()
    @State private var selectedBike: Bike? = nil
    @State private var showReportSheet = false
    @State private var showAdminSheet = false
    @State private var mapStyle: MapStyleOption = .standard

    // Eckerd College campus center
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 27.7308, longitude: -82.7138),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: Map
            Map(position: $cameraPosition) {
                // User location puck
                UserAnnotation()

                // Bike annotations
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

            // MARK: Top Bar
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        // MARK: Report / Detail Sheet
        .sheet(item: $selectedBike) { bike in
            BikeDetailSheet(bike: bike, store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // MARK: Admin Sheet
        .sheet(isPresented: $showAdminSheet) {
            AdminView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // App title
            VStack(alignment: .leading, spacing: 2) {
                Text("YIKE.LY")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text("Eckerd College Yellow Bikes")
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

            // Admin button
            Button {
                showAdminSheet = true
            } label: {
                Image(systemName: store.isAdminMode ? "wrench.fill" : "wrench")
                    .padding(10)
                    .background(store.isAdminMode ? Color.orange.opacity(0.2) : Color(.systemBackground).opacity(0.8),
                                in: Circle())
                    .overlay(Circle().stroke(store.isAdminMode ? Color.orange : Color.clear, lineWidth: 1.5))
            }
            .tint(store.isAdminMode ? .orange : .primary)
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
            // Bike counts
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
}
