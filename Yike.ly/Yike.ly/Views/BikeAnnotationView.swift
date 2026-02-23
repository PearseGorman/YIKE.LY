import SwiftUI

/// The icon that appears on the map for each bike.
/// Yellow = available, Red = needs repair, Gray/dashed = hidden (admin only)
struct BikeAnnotationView: View {
    @ObservedObject var bike: Bike
    let isAdminMode: Bool

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Pulse ring for broken bikes
            if bike.state == .needsRepair {
                Circle()
                    .stroke(Color.red.opacity(0.4), lineWidth: 3)
                    .frame(width: isPulsing ? 46 : 36, height: isPulsing ? 46 : 36)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isPulsing)
                    .onAppear { isPulsing = true }
            }

            // Main icon
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 34, height: 34)
                        .shadow(color: shadowColor.opacity(0.5), radius: 4, y: 2)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: bike.state == .hidden ? 1.5 : 0)
                                .strokeStyle(StrokeStyle(lineWidth: 1.5, dash: [3]))
                        )

                    Image(systemName: bikeIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconForeground)
                }

                // Callout pointer
                Triangle()
                    .fill(iconBackground)
                    .frame(width: 10, height: 6)
                    .opacity(bike.state == .hidden ? 0.5 : 1)
            }
        }
        .opacity(bike.state == .hidden ? 0.55 : 1.0)
    }

    // MARK: - Style helpers

    private var iconBackground: Color {
        switch bike.state {
        case .available:   return Color.yellow
        case .needsRepair: return Color.red
        case .hidden:      return Color(.systemGray4)
        }
    }

    private var iconForeground: Color {
        switch bike.state {
        case .available:   return Color(.systemBrown)
        case .needsRepair: return Color.white
        case .hidden:      return Color(.systemGray)
        }
    }

    private var borderColor: Color {
        bike.state == .hidden ? Color.gray : Color.clear
    }

    private var shadowColor: Color {
        switch bike.state {
        case .available:   return .yellow
        case .needsRepair: return .red
        case .hidden:      return .gray
        }
    }

    private var bikeIcon: String {
        switch bike.state {
        case .available:   return "bicycle"
        case .needsRepair: return "bicycle"
        case .hidden:      return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Triangle callout shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}
