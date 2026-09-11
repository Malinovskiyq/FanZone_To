import os

base_dir = r"E:\prilox\ios\FanZone\FanZone"
files = {
    r"Core\Network\APIClient.swift": """import Foundation
enum NetworkError: LocalizedError {
    case invalidURL, noData, unauthorized, networkUnavailable
    case decodingError(Error), serverError(Int, String)
}
final class APIClient {
    static let shared = APIClient()
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T { fatalError() }
}
struct APIErrorResponse: Decodable { let error: String? }
struct AppConfiguration { static let apiBaseURL = URL(string: "https://api.fanzone.example.com")! }
""",
    r"Core\Network\APIEndpoint.swift": """import Foundation
enum APIEndpoint {
    case getMatches(filter: String?)
    var path: String { return "" }
    var method: String { return "GET" }
}
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let user: User?
}
""",
    r"Core\Auth\AuthManager.swift": """import Foundation
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    func login(emailOrPhone: String, password: String) async throws {}
    func register(email: String?, phone: String?, username: String, firstName: String, lastName: String, password: String) async throws {}
    func logout() async {}
    func loadCurrentUser() async {}
    var userRole: UserRole { currentUser?.role ?? .user }
}
""",
    r"Core\Auth\KeychainManager.swift": """class KeychainManager {
    static let shared = KeychainManager()
    func saveAccessToken(_ token: String) {}
    func getAccessToken() -> String? { return nil }
    func saveRefreshToken(_ token: String) {}
    func getRefreshToken() -> String? { return nil }
    func clearAll() {}
}
""",
    r"App\RootView.swift": """import SwiftUI
struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    var body: some View { Text("Root") }
}
struct UserTabView: View { var body: some View { Text("UserTab") } }
struct ManagerTabView: View { var body: some View { Text("ManagerTab") } }
struct AdminTabView: View { var body: some View { Text("AdminTab") } }
""",
    r"Design\AppTheme.swift": """import SwiftUI
struct AppTheme {
    static let brandPrimary = Color.blue
    static let background = Color.black
    static let surface = Color.gray
    static let textSecondary = Color.gray
    static let error = Color.red
    static let radiusMedium: CGFloat = 8
}
""",
    r"Models\User.swift": """enum UserRole: String, Codable { case user, bookingManager, admin }
struct User: Codable, Identifiable { let id, username, firstName, lastName: String; let email, phone, city, bio, avatarUrl: String?; let role: UserRole; let isActive: Bool? }
""",
    r"Models\Match.swift": """import Foundation
struct Match: Codable, Identifiable { let id, homeTeam, awayTeam, arena, city: String; let date: Date; let description: String?; let fanSectorCapacity, fanSectorConfirmed, fanSectorPending: Int; let isHomeGame: Bool }
""",
    r"Models\Booking.swift": """import Foundation
enum BookingStatus: String, Codable { case pending, confirmed, rejected, cancelled, attended, missed }
struct Booking: Codable, Identifiable { let id, matchId, userId: String; let status: BookingStatus; let createdAt: Date; let qrToken: String? }
""",
    r"Models\Ticket.swift": """import Foundation
struct Ticket: Codable, Identifiable { let id, bookingId: String; let match: Match; let user: User; let qrToken: String }
""",
    r"Models\Stats.swift": """struct UserStats: Codable { let attended, confirmed, booked, cancelled: Int }
struct AdminStats: Codable { let totalUsers, totalMatches, totalBookings: Int }
""",
    r"Models\Notification.swift": """import Foundation
struct NotificationModel: Codable, Identifiable { let id, title, body: String; let isRead: Bool; let createdAt: Date }
""",
    r"Features\Auth\Views\AuthRootView.swift": """import SwiftUI
struct AuthRootView: View { var body: some View { Text("AuthRoot") } }
""",
    r"Features\Auth\Views\LoginView.swift": """import SwiftUI
struct LoginView: View { var onRegister: ()->Void; var onForgotPassword: ()->Void; var body: some View { Text("Login") } }
""",
    r"Features\Auth\Views\RegisterView.swift": """import SwiftUI
struct RegisterView: View { var body: some View { Text("Register") } }
""",
    r"Features\Auth\Views\ForgotPasswordView.swift": """import SwiftUI
struct ForgotPasswordView: View { var body: some View { Text("Forgot Password") } }
""",
    r"Features\Auth\ViewModels\AuthViewModel.swift": """import Foundation
class AuthViewModel: ObservableObject {}
""",
    r"Features\Home\Views\HomeView.swift": """import SwiftUI
struct HomeView: View { var body: some View { Text("Home") } }
""",
    r"Features\Matches\Views\MatchesView.swift": """import SwiftUI
struct MatchesView: View { var body: some View { Text("Matches") } }
""",
    r"Features\Matches\Views\MatchDetailView.swift": """import SwiftUI
struct MatchDetailView: View { var body: some View { Text("MatchDetail") } }
""",
    r"Features\Bookings\Views\MyBookingsView.swift": """import SwiftUI
struct MyBookingsView: View { var body: some View { Text("MyBookings") } }
""",
    r"Features\Bookings\Views\TicketView.swift": """import SwiftUI
struct TicketView: View { let qrToken: String; var body: some View { Text("Ticket") } }
""",
    r"Features\Profile\Views\ProfileView.swift": """import SwiftUI
struct ProfileView: View { var body: some View { Text("Profile") } }
""",
    r"Features\BookingManager\Views\BookingRequestsView.swift": """import SwiftUI
struct BookingRequestsView: View { var body: some View { Text("Requests") } }
""",
    r"Features\BookingManager\Views\MatchParticipantsView.swift": """import SwiftUI
struct MatchParticipantsView: View { var body: some View { Text("Participants") } }
""",
    r"Features\BookingManager\Views\QRScannerScreenView.swift": """import SwiftUI
struct QRScannerScreenView: View { var body: some View { Text("Scanner") } }
""",
    r"Features\Admin\Views\AdminMatchesView.swift": """import SwiftUI
struct AdminMatchesView: View { var body: some View { Text("Admin Matches") } }
""",
    r"Features\Admin\Views\AdminUsersView.swift": """import SwiftUI
struct AdminUsersView: View { var body: some View { Text("Admin Users") } }
""",
    r"Features\Admin\Views\AdminStatsView.swift": """import SwiftUI
struct AdminStatsView: View { var body: some View { Text("Admin Stats") } }
""",
    r"FanZoneApp.swift": """import SwiftUI
@main struct FanZoneApp: App { var body: some Scene { WindowGroup { RootView() } } }
""",
    r"Core\Extensions\Date+Extensions.swift": """import Foundation
extension Date { var isUpcoming: Bool { true } }
""",
    r"Core\Extensions\View+Extensions.swift": """import SwiftUI
extension View { func cardStyle() -> some View { self } }
""",
    r"Design\Components\FZButton.swift": """import SwiftUI
struct FZButton: View { let title: String; let action: ()->Void; var body: some View { Button(title, action: action) } }
""",
    r"Design\Components\FZCard.swift": """import SwiftUI
struct FZCard<Content: View>: View { let content: Content; init(@ViewBuilder content: () -> Content) { self.content = content() }; var body: some View { content } }
"""
}
for rel_path, content in files.items():
    full_path = os.path.join(base_dir, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)
print("Files generated.")
