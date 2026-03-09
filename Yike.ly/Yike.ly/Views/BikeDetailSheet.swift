import SwiftUI

/// Bottom sheet shown when a user taps a bike on the map.
/// Displays bike info and allows reporting an issue.
/// In admin mode, hidden bikes show a "Return to Fleet" prompt instead.
struct BikeDetailSheet: View {
    let bike: Bike
    @ObservedObject var store: BikeStore
    let isAdminMode: Bool                   // ← passed in from MapView
    @Environment(\.dismiss) private var dismiss

    @State private var showReportForm = false
    @State private var selectedIssue: BikeIssue? = nil
    @State private var customNote: String = ""
    @State private var didSubmit = false
    @State private var didReturnToFleet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Header
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(stateColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: bike.state == .hidden ? "wrench.and.screwdriver" : "bicycle")
                            .font(.system(size: 26))
                            .foregroundColor(stateColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(bike.name)
                            .font(.title2.bold())
                        HStack(spacing: 6) {
                            Circle().fill(stateColor).frame(width: 8, height: 8)
                            Text(stateLabel)
                                .font(.subheadline)
                                .foregroundColor(stateColor)
                        }
                        Text("ID: \(bike.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                // MARK: Existing issue (if any)
                if let issue = bike.reportedIssue {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Reported: \(issue)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))

                    Divider()
                }

                // MARK: Content — branches by state + role
                if didSubmit {
                    confirmationView(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        title: "Report submitted!",
                        subtitle: "The Bike Shop has been notified."
                    )
                } else if didReturnToFleet {
                    confirmationView(
                        icon: "bicycle.circle.fill",
                        color: .blue,
                        title: "Returned to fleet!",
                        subtitle: "\(bike.name) is now visible to students."
                    )
                } else if showReportForm {
                    reportForm
                } else {
                    actionPrompt
                }
            }
        }
    }

    // MARK: - Action Prompt
    // Branches on bike state and whether the viewer is an admin.
    private var actionPrompt: some View {
        VStack(spacing: 16) {
            switch bike.state {

            case .available:
                Text("Is something wrong with this Yike?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Button {
                    withAnimation { showReportForm = true }
                } label: {
                    Label("Report an Issue", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

            case .needsRepair:
                Text("This Yike has already been reported.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Text("The Bike Shop will address it soon.")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .hidden:
                // Only reachable in admin mode (hidden bikes are invisible to regular users)
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                        .padding(.top, 24)

                    Text("This Yike is currently in the shop.")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("It is not visible to students on the map.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                if isAdminMode {
                    Button {
                        returnToFleet()
                    } label: {
                        Label("Return to Fleet", systemImage: "eye.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
    }

    // MARK: - Report Form
    private var reportForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's the issue?")
                    .font(.headline)
                    .padding(.top, 8)

                ForEach(BikeIssue.allCases) { issue in
                    Button {
                        selectedIssue = issue
                    } label: {
                        HStack {
                            Text(issue.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedIssue == issue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(selectedIssue == issue ? Color.blue.opacity(0.08) : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Additional details (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Describe the issue...", text: $customNote, axis: .vertical)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                Button {
                    submitReport()
                } label: {
                    Text("Submit Report")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedIssue != nil ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedIssue == nil)
                .padding(.top, 4)
            }
            .padding()
        }
    }

    // MARK: - Confirmation View (reusable for both report + return actions)
    private func confirmationView(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color)
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions
    private func submitReport() {
        let issueText = [selectedIssue?.rawValue, customNote.isEmpty ? nil : customNote]
            .compactMap { $0 }
            .joined(separator: " — ")
        store.reportBike(bike, issue: issueText)
        withAnimation { didSubmit = true }
    }

    private func returnToFleet() {
        store.toggleAdminHidden(bike)
        withAnimation { didReturnToFleet = true }
    }

    // MARK: - Style Helpers
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
        case .hidden:      return "In Shop (Admin)"
        }
    }
}
