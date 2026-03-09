import SwiftUI

struct AdminView: View {
    @ObservedObject var store: BikeStore
    @ObservedObject var session: UserSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {

                // MARK: Session Info
                Section("Signed in as") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .foregroundColor(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.email)
                                .font(.subheadline.bold())
                            Text(session.isAdmin ? "Bike Shop Staff" : "Student")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(role: .destructive) {
                        dismiss()
                        session.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // MARK: Admin Mode Toggle
                // Locked ON for bike shop staff — they cannot disable it.
                // Shown as a toggle only so the state is visible; disabled if admin.
                Section {
                    if session.isAdmin {
                        HStack {
                            Label("Admin Mode", systemImage: "wrench.fill")
                            Spacer()
                            Text("Always on")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Toggle(isOn: $store.isAdminMode) {
                            Label("Admin Mode", systemImage: "wrench.fill")
                        }
                        .tint(.orange)
                    }
                } footer: {
                    Text(session.isAdmin
                         ? "Admin mode is permanently enabled for Bike Shop staff."
                         : "When enabled, hidden bikes appear on the map as gray icons.")
                }

                // MARK: All Bikes Management
                Section("All Bikes") {
                    ForEach(store.allBikes) { bike in
                        AdminBikeRow(bike: bike, store: store)
                    }
                }

                // MARK: Stats
                Section("Fleet Summary") {
                    StatRow(label: "Available",    value: store.bikes.filter { $0.state == .available   }.count, color: .yellow)
                    StatRow(label: "Needs Repair", value: store.bikes.filter { $0.state == .needsRepair }.count, color: .red)
                    StatRow(label: "In Shop",      value: store.bikes.filter { $0.state == .hidden      }.count, color: .gray)
                }
            }
            .navigationTitle("Bike Shop Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Admin Bike Row
struct AdminBikeRow: View {
    @ObservedObject var bike: Bike
    @ObservedObject var store: BikeStore

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(bike.name)
                    .font(.subheadline.bold())
                if let issue = bike.reportedIssue {
                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                } else {
                    Text(stateLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if bike.state == .needsRepair {
                    Button {
                        store.markAsRepaired(bike)
                    } label: {
                        Label("Fixed", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }

                Button {
                    store.toggleAdminHidden(bike)
                } label: {
                    if bike.state == .hidden {
                        Label("Return", systemImage: "eye.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    } else {
                        Label("To Shop", systemImage: "eye.slash.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(bike.state == .hidden ? 0.6 : 1.0)
    }

    private var stateColor: Color {
        switch bike.state {
        case .available:   return .yellow
        case .needsRepair: return .red
        case .hidden:      return .gray
        }
    }

    private var stateLabel: String {
        switch bike.state {
        case .available:   return "Available"
        case .needsRepair: return "Needs Repair"
        case .hidden:      return "In Shop"
        }
    }
}

// MARK: - Fleet Stat Row
struct StatRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.subheadline)
            Spacer()
            Text("\(value)").font(.subheadline.bold()).foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdminView(store: BikeStore(), session: UserSession())
}
