import SwiftUI

struct MatchCard: View {
    let match: Match
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // Teams header
                HStack(spacing: 0) {
                    teamSection(team: match.homeTeam, alignment: .leading)
                    vsSection
                    teamSection(team: match.awayTeam, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Divider()
                    .background(AppTheme.surfaceElevated)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // Match info row
                HStack(spacing: 12) {
                    infoItem(icon: "calendar", text: match.scheduledAt.ruShortDateString)
                    infoItem(icon: "clock", text: match.scheduledAt.ruTimeString)
                    Spacer()
                    if !match.isHome {
                        Label("Выездной", systemImage: "airplane")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(AppTheme.brandSecondary)
                    }
                }
                .padding(.horizontal, 16)

                // Sector + status
                HStack {
                    if let sector = match.fanSector {
                        Label("\(sector.name) · \(match.availableSeats) мест", systemImage: "person.3")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Label(match.arena.name, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    BookingWindowBadge(status: match.bookingWindowStatus)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func teamSection(team: Team, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            // Logo
            if let url = team.logoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFit()
                    } else {
                        teamLogoPlaceholder(name: team.name)
                    }
                }
                .frame(width: 42, height: 42)
            } else {
                teamLogoPlaceholder(name: team.name)
                    .frame(width: 42, height: 42)
            }

            Text(team.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private func teamLogoPlaceholder(name: String) -> some View {
        ZStack {
            Circle().fill(AppTheme.surfaceElevated)
            Text(name.prefix(2).uppercased())
                .font(.system(size: 14, weight: .black))
                .foregroundColor(AppTheme.brandPrimary)
        }
    }

    private var vsSection: some View {
        Text("VS")
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundColor(AppTheme.brandSecondary)
            .frame(width: 44)
    }

    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundColor(AppTheme.textSecondary)
            Text(text).font(.caption2).foregroundColor(AppTheme.textSecondary)
        }
    }
}
