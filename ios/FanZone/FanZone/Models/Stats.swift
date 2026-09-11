import Foundation

// MARK: - User Stats

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

    var pendingBookings: Int {
        max(0, totalBookings - confirmedBookings - rejectedBookings - cancelledBookings)
    }
}

// MARK: - Attendance History Item

struct AttendanceHistoryItem: Codable, Identifiable {
    let id: String
    let matchTitle: String
    let scheduledAt: Date
    let isHome: Bool
    let attendanceStatus: AttendanceStatus
    let bookingStatus: BookingStatus
    let arenaName: String?
    let arenaCity: String?
}

// MARK: - Admin Overview Stats

struct AdminOverviewStats: Codable {
    let totalUsers: Int
    let activeUsers: Int
    let totalBookings: Int
    let confirmedBookings: Int
    let rejectedBookings: Int
    let cancelledBookings: Int
    let totalAttended: Int
    let totalAbsent: Int
    let upcomingMatches: Int
    let completedMatches: Int
}

// MARK: - Admin Match Stats

struct AdminMatchStats: Codable, Identifiable {
    let id: String
    let matchTitle: String
    let scheduledAt: Date
    let totalCapacity: Int
    let totalBookings: Int
    let confirmedBookings: Int
    let pendingBookings: Int
    let attended: Int
    let absent: Int

    var availableSeats: Int { max(0, totalCapacity - confirmedBookings) }
    var occupancyPercent: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(confirmedBookings) / Double(totalCapacity)
    }
}
