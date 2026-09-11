import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    static let shared = AuthManager()
    private init() {}

    // MARK: - Public

    func login(emailOrPhone: String, password: String) async throws {
        let response: AuthResponse = try await APIClient.shared.request(
            .login(emailOrPhone: emailOrPhone, password: password)
        )
        storeTokens(response)
        currentUser = response.user
        isAuthenticated = true
    }

    func register(
        email: String?, phone: String?,
        username: String, firstName: String, lastName: String, password: String
    ) async throws {
        let response: AuthResponse = try await APIClient.shared.request(
            .register(email: email, phone: phone, username: username,
                      firstName: firstName, lastName: lastName, password: password)
        )
        storeTokens(response)
        currentUser = response.user
        isAuthenticated = true
    }

    func logout() async {
        try? await APIClient.shared.requestEmpty(.logout)
        KeychainManager.shared.clearAll()
        withAnimation {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func loadCurrentUser() async {
        defer { isLoading = false }
        guard KeychainManager.shared.getAccessToken() != nil else { return }
        do {
            let user: User = try await APIClient.shared.request(.getMyProfile)
            currentUser = user
            isAuthenticated = true
        } catch {
            KeychainManager.shared.clearAll()
            isAuthenticated = false
        }
    }

    func refreshCurrentUser() async {
        guard isAuthenticated else { return }
        do {
            let user: User = try await APIClient.shared.request(.getMyProfile)
            currentUser = user
        } catch { /* silently fail */ }
    }

    var userRole: UserRole { currentUser?.role ?? .user }

    // MARK: - Private

    private func storeTokens(_ response: AuthResponse) {
        KeychainManager.shared.saveAccessToken(response.accessToken)
        if let refresh = response.refreshToken {
            KeychainManager.shared.saveRefreshToken(refresh)
        }
    }
}
