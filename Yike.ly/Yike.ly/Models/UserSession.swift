import Foundation
import Combine

// MARK: - User Role
enum UserRole: String, Codable {
    case user        // standard student — no admin access
    case admin       // bike shop staff — admin mode locked ON
}

// MARK: - UserSession
// Single source of truth for who is logged in.
// Persisted to UserDefaults so the user isn't re-prompted on every launch.
class UserSession: ObservableObject {
    @Published var email: String = ""
    @Published var role: UserRole = .user
    @Published var isLoggedIn: Bool = false

    private let emailKey = "yikely_email"
    private let roleKey  = "yikely_role"

    init() {
        restoreSession()
    }

    // MARK: - Login
    func login(email: String, role: UserRole) {
        self.email = email
        self.role  = role
        self.isLoggedIn = true
        UserDefaults.standard.set(email,      forKey: emailKey)
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
    }

    // MARK: - Logout
    func logout() {
        self.email = ""
        self.role  = .user
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: roleKey)
    }

    // MARK: - Restore persisted session on launch
    private func restoreSession() {
        guard
            let savedEmail = UserDefaults.standard.string(forKey: emailKey),
            let rawRole    = UserDefaults.standard.string(forKey: roleKey),
            let savedRole  = UserRole(rawValue: rawRole)
        else { return }

        self.email     = savedEmail
        self.role      = savedRole
        self.isLoggedIn = true
    }

    // MARK: - Computed helpers
    var isAdmin: Bool { role == .admin }
    var displayName: String { email.components(separatedBy: "@").first ?? email }
}
