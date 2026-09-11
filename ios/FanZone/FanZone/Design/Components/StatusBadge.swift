import SwiftUI

// MARK: - Status Badge (Booking)

struct BookingStatusBadge: View {
    let status: BookingStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.systemImage)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(status.color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Booking Window Status Badge

struct BookingWindowBadge: View {
    let status: BookingWindowStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.color)
                .frame(width: 7, height: 7)
            Text(status.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(status.color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Attendance Status Badge

struct AttendanceStatusBadge: View {
    let status: AttendanceStatus

    var body: some View {
        HStack(spacing: 5) {
            Text(status.emoji)
            Text(status.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Role Badge

struct RoleBadge: View {
    let role: UserRole

    private var color: Color {
        switch role {
        case .user:           return AppTheme.info
        case .bookingManager: return AppTheme.warning
        case .admin:          return AppTheme.error
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: role.systemImage).font(.caption2)
            Text(role.displayName).font(.caption2.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
