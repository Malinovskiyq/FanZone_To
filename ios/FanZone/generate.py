import os
import textwrap

files = {
    "README.md": """# FanZone iOS App

## Prerequisites
- Xcode 15+
- iOS 16.0+ deployment target

## How to setup
1. Create a new Xcode project named "FanZone" (iOS App, SwiftUI).
2. Delete the default generated files (except the project.pbxproj).
3. Drag and drop all the generated folders (Core, Models, Design, Features, App) into your Xcode project.
4. Ensure no external dependencies are needed.
5. Configure the API base URL in AppConfiguration.swift.
6. Run on simulator.
""",
    "FanZone/AppConfiguration.swift": """import Foundation

enum AppConfiguration {
    static let apiBaseURL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000/api/v1")!
    static let uploadsBaseURL = URL(string: ProcessInfo.processInfo.environment["UPLOADS_BASE_URL"] ?? "http://localhost:3000")!
    static let clubName = "ХК Сибирь"
    static let clubCity = "Новосибирск"
}
""",
    "FanZone/Models/User.swift": """import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let phone: String?
    let username: String
    let role: UserRole
    let isActive: Bool
    let profile: Profile?
    let socialLinks: [SocialLink]?
    let createdAt: Date
}

enum UserRole: String, Codable {
    case user = "USER"
    case bookingManager = "BOOKING_MANAGER"
    case admin = "ADMIN"
}

struct Profile: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let city: String?
    let avatarUrl: String?
    let bio: String?
    
    var fullName: String { "\\(firstName) \\(lastName)" }
}

struct SocialLink: Codable, Identifiable {
    let id: String
    let platform: String
    let url: String
    let label: String?
}
""",
    "FanZone/Models/Match.swift": """import Foundation

struct Match: Codable, Identifiable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let arena: Arena
    let scheduledAt: Date
    let bookingOpenAt: Date
    let bookingCloseAt: Date
    let description: String?
    let isHome: Bool
    let status: MatchStatus
    let fanSector: FanSector?
    let confirmedBookingsCount: Int?
    let pendingBookingsCount: Int?
}

enum MatchStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case ongoing = "ONGOING"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

struct Team: Codable, Identifiable {
    let id: String
    let name: String
    let city: String?
    let logoUrl: String?
}

struct Arena: Codable, Identifiable {
    let id: String
    let name: String
    let city: String
    let address: String?
}

struct FanSector: Codable, Identifiable {
    let id: String
    let name: String
    let capacity: Int
}
""",
    "FanZone/Models/Booking.swift": """import Foundation
import SwiftUI

struct Booking: Codable, Identifiable {
    let id: String
    let user: User?
    let match: Match
    let status: BookingStatus
    let cancelDeadline: Date?
    let createdAt: Date
    let ticket: Ticket?
    let attendance: AttendanceRecord?
}

enum BookingStatus: String, Codable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"
    
    var displayName: String {
        switch self {
        case .pending: return "На рассмотрении"
        case .confirmed: return "Подтверждено"
        case .rejected: return "Отклонено"
        case .cancelled: return "Отменено"
        }
    }
}

struct Ticket: Codable, Identifiable {
    let id: String
    let bookingId: String
    let qrToken: String
    let isUsed: Bool
    let issuedAt: Date
    let matchTitle: String?
    let sectorName: String?
    let userFullName: String?
    let avatarUrl: String?
}

struct AttendanceRecord: Codable {
    let id: String
    let status: AttendanceStatus
    let markedAt: Date?
}

enum AttendanceStatus: String, Codable {
    case unknown = "UNKNOWN"
    case attended = "ATTENDED"
    case absent = "ABSENT"
    
    var displayName: String {
        switch self {
        case .unknown: return "Не отмечен"
        case .attended: return "Посетил"
        case .absent: return "Не пришёл"
        }
    }
}
""",
    "FanZone/Models/Stats.swift": """import Foundation

struct UserStats: Codable {
    let totalBookings: Int
    let confirmedBookings: Int
    let rejectedBookings: Int
    let cancelledBookings: Int
    let attendedMatches: Int
    let absentMatches: Int
    let homeMatchesAttended: Int
    let awayMatchesAttended: Int
    let recentAttendances: [AttendanceHistoryItem]
}

struct AttendanceHistoryItem: Codable, Identifiable {
    let id: String
    let matchTitle: String
    let scheduledAt: Date
    let isHome: Bool
    let attendanceStatus: AttendanceStatus
    let bookingStatus: BookingStatus
}
""",
    "FanZone/Core/Auth/KeychainManager.swift": """import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let accessTokenKey = "fanzone.accessToken"
    private let refreshTokenKey = "fanzone.refreshToken"
    
    func saveAccessToken(_ token: String) {
        save(key: accessTokenKey, data: token)
    }
    
    func getAccessToken() -> String? {
        return get(key: accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) {
        save(key: refreshTokenKey, data: token)
    }
    
    func getRefreshToken() -> String? {
        return get(key: refreshTokenKey)
    }
    
    func clearAll() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }
    
    private func save(key: String, data: String) {
        let dataToSave = data.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataToSave
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
""",
    "FanZone/Core/Network/APIEndpoint.swift": """import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint {
    case login(emailOrPhone: String, password: String)
    case getMyProfile
    case getMatches(filter: String?)
    
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .getMyProfile: return "/profile/me"
        case .getMatches: return "/matches"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login: return .post
        case .getMyProfile, .getMatches: return .get
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let email, let pwd): return ["emailOrPhone": email, "password": pwd]
        default: return nil
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .login: return false
        default: return true
        }
    }
}
""",
    "FanZone/Core/Network/APIClient.swift": """import Foundation

final class APIClient {
    static let shared = APIClient()
    private let baseURL = AppConfiguration.apiBaseURL
    
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await requestRaw(endpoint)
        return try decoder.decode(T.self, from: data)
    }
    
    func requestRaw(_ endpoint: APIEndpoint) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if endpoint.requiresAuth, let token = KeychainManager.shared.getAccessToken() {
            req.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = endpoint.body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let httpRes = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpRes.statusCode == 401 {
            // Simple logic: clear token. In complete code we'd try to refresh.
            KeychainManager.shared.clearAll()
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpRes.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}
""",
    "FanZone/Core/Auth/AuthManager.swift": """import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    
    static let shared = AuthManager()
    
    func login(emailOrPhone: String, password: String) async throws {
        // Mock
        KeychainManager.shared.saveAccessToken("mock_token")
        isAuthenticated = true
        currentUser = User(id: "1", email: emailOrPhone, phone: nil, username: "user", role: .user, isActive: true, profile: nil, socialLinks: nil, createdAt: Date())
    }
    
    func logout() async {
        KeychainManager.shared.clearAll()
        isAuthenticated = false
        currentUser = nil
    }
    
    func loadCurrentUser() async {
        isLoading = false
        if KeychainManager.shared.getAccessToken() != nil {
            isAuthenticated = true
            currentUser = User(id: "1", email: "test@test.com", phone: nil, username: "user", role: .user, isActive: true, profile: nil, socialLinks: nil, createdAt: Date())
        }
    }
    
    var userRole: UserRole { currentUser?.role ?? .user }
}
""",
    "FanZone/Design/AppTheme.swift": """import SwiftUI

struct AppTheme {
    static let brandPrimary = Color(hex: "0066CC")
    static let brandSecondary = Color(hex: "FFD700")
    
    static let background = Color(hex: "0D0D0D")
    static let surface = Color(hex: "1A1A2E")
    static let surfaceSecondary = Color(hex: "16213E")
    
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E9BAE")
    
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")
    static let neutral = Color(hex: "636366")
    
    static let heroGradient = LinearGradient(
        colors: [brandPrimary.opacity(0.8), background],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
""",
    "FanZone/App/RootView.swift": """import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView()
                    .preferredColorScheme(.dark)
            } else if authManager.isAuthenticated {
                TabView {
                    Text("Home")
                        .tabItem { Label("Home", systemImage: "house") }
                    Text("Matches")
                        .tabItem { Label("Matches", systemImage: "sportscourt") }
                    Text("Profile")
                        .tabItem { Label("Profile", systemImage: "person") }
                }
                .preferredColorScheme(.dark)
            } else {
                LoginView()
            }
        }
        .task {
            await authManager.loadCurrentUser()
        }
    }
}
""",
    "FanZone/FanZoneApp.swift": """import SwiftUI

@main
struct FanZoneApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
""",
    "FanZone/Features/Auth/Views/LoginView.swift": """import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FanZone")
                .font(.largeTitle).bold()
                .foregroundColor(AppTheme.brandPrimary)
            
            TextField("Email / Phone", text: $email)
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(10)
                .foregroundColor(.white)
            
            SecureField("Password", text: $password)
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(10)
                .foregroundColor(.white)
            
            Button("Войти") {
                Task {
                    isLoading = true
                    try? await AuthManager.shared.login(emailOrPhone: email, password: password)
                    isLoading = false
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.brandPrimary)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            if isLoading {
                ProgressView()
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}
"""
}

def create_files():
    base_dir = r"E:\prilox\ios\FanZone"
    os.makedirs(base_dir, exist_ok=True)
    for path_str, content in files.items():
        full_path = os.path.join(base_dir, path_str.replace('/', os.sep))
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content)

if __name__ == "__main__":
    create_files()
    print("Files created successfully.")
