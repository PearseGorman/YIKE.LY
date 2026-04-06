import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: UserSession

    @State private var emailInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo / Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 90, height: 90)
                        Image(systemName: "bicycle")
                            .font(.system(size: 44))
                            .foregroundColor(.yellow)
                    }

                    Text("YIKE.LY")
                        .font(.system(size: 36, weight: .black, design: .rounded))

                    Text("Eckerd College Yellow Bikes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 48)

                // MARK: Email Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sign in with your Eckerd email")
                        .font(.headline)

                    // Email field
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                        TextField("yourname@eckerd.edu", text: $emailInput)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($emailFocused)
                            .submitLabel(.go)
                            .onSubmit { Task { await attemptLogin() } }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(errorMessage != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )

                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Submit button
                    Button {
                        Task { await attemptLogin() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidFormat ? Color.yellow : Color.gray.opacity(0.4))
                        .foregroundColor(isValidFormat ? Color(.systemBrown) : .secondary)
                        .cornerRadius(12)
                    }
                    .disabled(!isValidFormat || isLoading)
                }
                .padding(24)
                .background(Color(.systemGroupedBackground))

                Spacer()

                // Footer note
                Text("Only @eckerd.edu addresses are accepted.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { emailFocused = true }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    // MARK: - Validation
    // Live-checks format so the button enables as soon as it looks like a valid address
    private var isValidFormat: Bool {
        emailInput.lowercased().hasSuffix("@eckerd.edu") && emailInput.count > "@eckerd.edu".count
    }

    // MARK: - Login attempt
    private func attemptLogin() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let role = try await AuthManager.shared.resolveRole(for: emailInput)
            await MainActor.run {
                session.login(email: emailInput.lowercased().trimmingCharacters(in: .whitespaces), role: role)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserSession())
}
