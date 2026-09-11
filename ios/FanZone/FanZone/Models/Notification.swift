import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String?
    let title: String
    let body: String
    let type: NotificationType
    let data: [String: String]?
    let isRead: Bool
    let createdAt: Date
}

enum NotificationType: String, Codable {
    case bookingPending    = "BOOKING_PENDING"
    case bookingConfirmed  = "BOOKING_CONFIRMED"
    case bookingRejected   = "BOOKING_REJECTED"
    case bookingCancelled  = "BOOKING_CANCELLED"
    case matchChanged      = "MATCH_CHANGED"
    case matchReminder     = "MATCH_REMINDER"
    case bookingOpen       = "BOOKING_OPEN"
    case general           = "GENERAL"

    var systemImage: String {
        switch self {
        case .bookingPending:   return "clock.fill"
        case .bookingConfirmed: return "checkmark.seal.fill"
        case .bookingRejected:  return "xmark.seal.fill"
        case .bookingCancelled: return "nosign"
        case .matchChanged:     return "exclamationmark.triangle.fill"
        case .matchReminder:    return "bell.fill"
        case .bookingOpen:      return "ticket.fill"
        case .general:          return "info.circle.fill"
        }
    }
}

struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
    let total: Int
}
