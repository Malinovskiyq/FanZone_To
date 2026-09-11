import Foundation
import SwiftUI

// MARK: - Match Status

enum MatchStatus: String, Codable, CaseIterable {
    case scheduled = "SCHEDULED"
    case ongoing   = "ONGOING"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .scheduled: return "Запланирован"
        case .ongoing:   return "Идёт"
        case .completed: return "Завершён"
        case .cancelled: return "Отменён"
        }
    }
}

// MARK: - Booking Window Status (derived)

enum BookingWindowStatus {
    case open
    case almostFull(available: Int)
    case closed
    case completed

    var displayName: String {
        switch self {
        case .open:                 return "Бронирование открыто"
        case .almostFull(let n):    return "Мест мало (\(n))"
        case .closed:               return "Бронирование закрыто"
        case .completed:            return "Матч завершён"
        }
    }

    var emoji: String {
        switch self {
        case .open:       return "🟢"
        case .almostFull: return "🟡"
        case .closed:     return "🔴"
        case .completed:  return "⚪"
        }
    }

    var color: Color {
        switch self {
        case .open:       return AppTheme.success
        case .almostFull: return AppTheme.warning
        case .closed:     return AppTheme.error
        case .completed:  return AppTheme.neutral
        }
    }
}

// MARK: - Team

struct Team: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let city: String?
    let logoUrl: String?
    let isHome: Bool?

    var logoURL: URL? {
        guard let path = logoUrl, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return AppConfiguration.uploadsBaseURL.appendingPathComponent(path)
    }
}

// MARK: - Arena

struct Arena: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let city: String
    let address: String?
}

// MARK: - Fan Sector

struct FanSector: Codable, Identifiable, Equatable {
    let id: String
    let matchId: String?
    let name: String
    let capacity: Int
}

// MARK: - Match

struct Match: Codable, Identifiable, Equatable {
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
    let cancelDeadlineHours: Int?
    let fanSector: FanSector?
    let confirmedBookingsCount: Int?
    let pendingBookingsCount: Int?
    let createdAt: Date?

    static func == (lhs: Match, rhs: Match) -> Bool { lhs.id == rhs.id }

    // MARK: Computed

    var title: String { "\(homeTeam.name) — \(awayTeam.name)" }

    var isUpcoming: Bool { scheduledAt > Date() && status == .scheduled }
    var isPast: Bool     { scheduledAt < Date() || status == .completed }

    var availableSeats: Int {
        guard let sector = fanSector, let confirmed = confirmedBookingsCount else { return 0 }
        return max(0, sector.capacity - confirmed)
    }

    var bookingWindowStatus: BookingWindowStatus {
        let now = Date()
        if status == .completed || status == .cancelled { return .completed }
        if now < bookingOpenAt || now > bookingCloseAt  { return .closed }
        let available = availableSeats
        if available == 0 { return .closed }
        if available <= 10 { return .almostFull(available: available) }
        return .open
    }

    var isBookingOpen: Bool {
        if case .open       = bookingWindowStatus { return true }
        if case .almostFull = bookingWindowStatus { return true }
        return false
    }

    var formattedSchedule: String {
        scheduledAt.ruDateTimeString
    }

    var occupancyPercent: Double {
        guard let sector = fanSector, sector.capacity > 0,
              let confirmed = confirmedBookingsCount else { return 0 }
        return Double(confirmed) / Double(sector.capacity)
    }
}

// MARK: - Match Participant (for manager view)

struct MatchParticipant: Codable, Identifiable {
    let id: String          // booking id
    let user: User
    let status: BookingStatus
    let attendance: AttendanceRecord?
    let createdAt: Date
}
