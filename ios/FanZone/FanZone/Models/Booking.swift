import Foundation
import SwiftUI

// MARK: - Booking Status

enum BookingStatus: String, Codable, CaseIterable {
    case pending   = "PENDING"
    case confirmed = "CONFIRMED"
    case rejected  = "REJECTED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .pending:   return "На рассмотрении"
        case .confirmed: return "Подтверждено"
        case .rejected:  return "Отклонено"
        case .cancelled: return "Отменено"
        }
    }

    var emoji: String {
        switch self {
        case .pending:   return "🟡"
        case .confirmed: return "🟢"
        case .rejected:  return "🔴"
        case .cancelled: return "⚪"
        }
    }

    var color: Color {
        switch self {
        case .pending:   return AppTheme.warning
        case .confirmed: return AppTheme.success
        case .rejected:  return AppTheme.error
        case .cancelled: return AppTheme.neutral
        }
    }

    var systemImage: String {
        switch self {
        case .pending:   return "clock.fill"
        case .confirmed: return "checkmark.seal.fill"
        case .rejected:  return "xmark.seal.fill"
        case .cancelled: return "nosign"
        }
    }

    var canCancel: Bool {
        self == .pending || self == .confirmed
    }

    var isActive: Bool {
        self == .pending || self == .confirmed
    }
}

// MARK: - Attendance Status

enum AttendanceStatus: String, Codable {
    case unknown  = "UNKNOWN"
    case attended = "ATTENDED"
    case absent   = "ABSENT"

    var displayName: String {
        switch self {
        case .unknown:  return "Не отмечен"
        case .attended: return "Посетил"
        case .absent:   return "Не пришёл"
        }
    }

    var emoji: String {
        switch self {
        case .unknown:  return "⏳"
        case .attended: return "✅"
        case .absent:   return "❌"
        }
    }

    var color: Color {
        switch self {
        case .unknown:  return AppTheme.textSecondary
        case .attended: return AppTheme.success
        case .absent:   return AppTheme.error
        }
    }
}

// MARK: - Attendance Record

struct AttendanceRecord: Codable, Identifiable {
    let id: String
    let bookingId: String?
    let userId: String?
    let matchId: String?
    let status: AttendanceStatus
    let markedAt: Date?
    let markedById: String?
}

// MARK: - Ticket

struct Ticket: Codable, Identifiable {
    let id: String
    let bookingId: String
    let qrToken: String
    let isUsed: Bool
    let issuedAt: Date
    let usedAt: Date?

    // Joined fields from backend
    let matchTitle: String?
    let sectorName: String?
    let userFullName: String?
    let avatarUrl: String?
    let scheduledAt: Date?
    let arenaName: String?
    let arenaCity: String?
}

// MARK: - Booking

struct Booking: Codable, Identifiable, Equatable {
    let id: String
    let userId: String?
    let matchId: String?
    let user: User?
    let match: Match
    let status: BookingStatus
    let cancelDeadline: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date?
    let ticket: Ticket?
    let attendance: AttendanceRecord?

    static func == (lhs: Booking, rhs: Booking) -> Bool { lhs.id == rhs.id }

    var shortId: String { String(id.prefix(8)).uppercased() }

    var canCancel: Bool {
        guard status.canCancel else { return false }
        if let deadline = cancelDeadline { return Date() < deadline }
        return true
    }

    var sectorName: String? {
        match.fanSector?.name
    }

    var isUpcoming: Bool {
        match.scheduledAt > Date() && status.isActive
    }
}

// MARK: - QR Verification Result

struct QRVerificationResult: Codable {
    let isValid: Bool
    let isUsed: Bool
    let booking: Booking?
    let message: String?
}
