import Foundation

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case notEckerdEmail
    case emptyEmail
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notEckerdEmail:
            return "Please use your Eckerd College email address (@eckerd.edu)."
        case .emptyEmail:
            return "Please enter your email address."
        case .networkError(let e):
            return "Could not reach the server: \(e.localizedDescription)"
        }
    }
}

// MARK: - AuthManager
class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: - Hardcoded admin list (temporary until DB is connected)
    // Replace this with a real API call to your MariaDB server once it's live.
    // Format: lowercase full eckerd email addresses of bike shop staff.
    private let localAdminEmails: Set<String> = [
        "bikeshop@eckerd.edu",
        // Add your and your partner's emails here during development:
        // "yourname@eckerd.edu",
        "cjvogt@eckerd.edu"
    ]

    // MARK: - Validate & resolve role
    // Steps:
    //   1. Check email is non-empty
    //   2. Check @eckerd.edu suffix
    //   3. Check admin list (local for now, API call later)
    func resolveRole(for email: String) async throws -> UserRole {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmed.isEmpty else { throw AuthError.emptyEmail }
        guard trimmed.hasSuffix("@eckerd.edu") else { throw AuthError.notEckerdEmail }

        // --- Swap this block out for your real API call ---
        if BikeStore.useRealAPI {
            return try await fetchRoleFromServer(email: trimmed)
        } else {
            return localAdminEmails.contains(trimmed) ? .admin : .user
        }
    }

    // MARK: - Future: real API role check
    // POST /api/auth/role  { "email": "..." }  → { "role": "admin" | "user" }
    private func fetchRoleFromServer(email: String) async throws -> UserRole {
        guard let url = URL(string: APIConfig.baseURL + "/api/auth/role") else {
            throw AuthError.networkError(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response  = try JSONDecoder().decode([String: String].self, from: data)
            let rawRole   = response["role"] ?? "user"
            return UserRole(rawValue: rawRole) ?? .user
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
