import Foundation

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable, Hashable {
    case user           = "USER"
    case bookingManager = "BOOKING_MANAGER"
    case admin          = "ADMIN"

    var displayName: String {
        switch self {
        case .user:           return "Болельщик"
        case .bookingManager: return "Ответственный"
        case .admin:          return "Администратор"
        }
    }

    var systemImage: String {
        switch self {
        case .user:           return "person.fill"
        case .bookingManager: return "list.clipboard.fill"
        case .admin:          return "shield.fill"
        }
    }
}

// MARK: - User

struct User: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let email: String?
    let phone: String?
    let username: String
    let role: UserRole
    let isActive: Bool
    let fcmToken: String?
    let createdAt: Date?
    let updatedAt: Date?
    let profile: UserProfile?
    let socialLinks: [SocialLink]?

    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var displayName: String {
        if let p = profile { return p.fullName }
        return "@\(username)"
    }

    var avatarURL: URL? {
        guard let avatarPath = profile?.avatarUrl, !avatarPath.isEmpty else { return nil }
        if avatarPath.hasPrefix("http") { return URL(string: avatarPath) }
        return AppConfiguration.uploadsBaseURL.appendingPathComponent(avatarPath)
    }
}

// MARK: - Profile

struct UserProfile: Codable, Equatable, Hashable {
    let id: String?
    let userId: String?
    let firstName: String
    let lastName: String
    let city: String?
    let avatarUrl: String?
    let bio: String?

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return (String(f) + String(l)).uppercased()
    }
}

// MARK: - Social Link

struct SocialLink: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let userId: String?
    let platform: String
    let url: String
    let label: String?

    var socialPlatform: SocialPlatform {
        SocialPlatform(rawValue: platform) ?? .other
    }

    var displayLabel: String { label ?? socialPlatform.displayName }
}

enum SocialPlatform: String, Codable, CaseIterable, Hashable {
    case vk        = "VK"
    case telegram  = "TELEGRAM"
    case instagram = "INSTAGRAM"
    case tiktok    = "TIKTOK"
    case youtube   = "YOUTUBE"
    case x         = "X"
    case other     = "OTHER"

    var displayName: String {
        switch self {
        case .vk:        return "VKontakte"
        case .telegram:  return "Telegram"
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        case .youtube:   return "YouTube"
        case .x:         return "X (Twitter)"
        case .other:     return "Другое"
        }
    }

    var systemImage: String {
        switch self {
        case .vk:        return "v.circle.fill"
        case .telegram:  return "paperplane.fill"
        case .instagram: return "camera.fill"
        case .tiktok:    return "music.note"
        case .youtube:   return "play.rectangle.fill"
        case .x:         return "xmark.circle.fill"
        case .other:     return "link"
        }
    }

    var hexColor: String {
        switch self {
        case .vk:        return "0077FF"
        case .telegram:  return "2AABEE"
        case .instagram: return "E1306C"
        case .tiktok:    return "010101"
        case .youtube:   return "FF0000"
        case .x:         return "14171A"
        case .other:     return "636366"
        }
    }
}

// MARK: - Auth Response

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: User?
}
