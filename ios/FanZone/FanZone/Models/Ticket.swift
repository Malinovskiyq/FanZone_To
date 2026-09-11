import Foundation
import SwiftUI

// MARK: - Match models (already in Match.swift, here is Ticket model standalone)

struct TicketModel: Codable, Identifiable {
    let id: String
    let bookingId: String
    let qrToken: String
    let isUsed: Bool
    let issuedAt: Date
    let usedAt: Date?

    // Joined fields returned by /tickets/:bookingId
    let matchTitle:   String?
    let sectorName:   String?
    let userFullName: String?
    let avatarUrl:    String?
    let scheduledAt:  Date?
    let arenaName:    String?
    let arenaCity:    String?
}
