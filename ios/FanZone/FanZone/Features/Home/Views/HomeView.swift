import SwiftUI

// MARK: - Home ViewModel

@MainActor
class HomeViewModel: ObservableObject {
    @Published var upcomingMatches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var nextMatch: Match? { upcomingMatches.first }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let matches: [Match] = try await APIClient.shared.request(.getMatches(filter: "upcoming"))
            upcomingMatches = matches
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Home View

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var auth: AuthManager
    @State private var selectedMatch: Match?
    @State private var showBookingForm = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting
                    greetingSection

                    // Next match hero
                    if let match = vm.nextMatch {
                        heroMatchCard(match: match)
                    } else if vm.isLoading {
                        heroSkeleton
                    } else {
                        emptyHeroCard
                    }

                    // Upcoming matches scroll
                    if vm.upcomingMatches.count > 1 {
                        upcomingSection
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .navigationBarHidden(true)
        .sheet(isPresented: $showBookingForm) {
            if let match = selectedMatch {
                BookingFormView(match: match)
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Text(auth.currentUser?.profile?.firstName ?? auth.currentUser?.username ?? "Болельщик")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            UserAvatarView(user: auth.currentUser, size: 44, showBorder: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "Доброе утро,"
        case 12..<18: return "Добрый день,"
        case 18..<23: return "Добрый вечер,"
        default:      return "Доброй ночи,"
        }
    }

    // MARK: - Hero Match Card

    private func heroMatchCard(match: Match) -> some View {
        VStack(spacing: 0) {
            // Gradient header with teams
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                    .fill(AppTheme.heroGradient)
                    .frame(height: 260)

                VStack(spacing: 16) {
                    // Teams row
                    HStack(spacing: 0) {
                        // Home team
                        VStack(spacing: 8) {
                            teamLogoHero(team: match.homeTeam)
                            Text(match.homeTeam.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                        }

                        VStack(spacing: 4) {
                            Text("VS")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.brandSecondary)
                            BookingWindowBadge(status: match.bookingWindowStatus)
                        }
                        .frame(width: 80)

                        // Away team
                        VStack(spacing: 8) {
                            teamLogoHero(team: match.awayTeam)
                            Text(match.awayTeam.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                        }
                    }

                    // Match info pills
                    HStack(spacing: 8) {
                        infoPill(icon: "calendar", text: match.scheduledAt.ruShortDateString)
                        infoPill(icon: "clock", text: match.scheduledAt.ruTimeString)
                        infoPill(icon: "building.2", text: match.arena.name)
                    }
                }
                .padding()
            }

            // Bottom action area
            VStack(spacing: 12) {
                // Sector info
                if let sector = match.fanSector {
                    HStack {
                        Label("\(sector.name)", systemImage: "person.3.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(match.availableSeats) мест свободно")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(
                                match.availableSeats > 10 ? AppTheme.success : AppTheme.warning
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }

                // Book button
                FZPrimaryButton(match.isBookingOpen ? "ЗАБРОНИРОВАТЬ БИЛЕТ" : "БРОНИРОВАНИЕ ЗАКРЫТО") {
                    selectedMatch = match
                    showBookingForm = true
                }
                .disabled(!match.isBookingOpen)
                .opacity(match.isBookingOpen ? 1 : 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous))
            .offset(y: -20)
        }
        .padding(.horizontal, 16)
    }

    private func teamLogoHero(team: Team) -> some View {
        Group {
            if let url = team.logoURL {
                AsyncImage(url: url) { p in
                    if case .success(let img) = p { img.resizable().scaledToFit() }
                    else { teamLogoFallback(name: team.name, size: 64) }
                }
            } else {
                teamLogoFallback(name: team.name, size: 64)
            }
        }
        .frame(width: 64, height: 64)
    }

    private func teamLogoFallback(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(AppTheme.surfaceElevated.opacity(0.5))
            Text(name.prefix(2).uppercased())
                .font(.system(size: size * 0.3, weight: .black))
                .foregroundColor(AppTheme.brandPrimary)
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2.weight(.medium))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Upcoming section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ближайшие матчи")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(vm.upcomingMatches.dropFirst()) { match in
                        MatchCard(match: match) {
                            selectedMatch = match
                            showBookingForm = true
                        }
                        .frame(width: 300)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Skeleton / Empty

    private var heroSkeleton: some View {
        RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
            .fill(AppTheme.surface)
            .frame(height: 300)
            .padding(.horizontal, 16)
            .shimmer()
    }

    private var emptyHeroCard: some View {
        FZCard(padding: 32) {
            EmptyStateView(
                icon: "hockey.puck",
                title: "Нет предстоящих матчей",
                subtitle: "Следите за расписанием — новые матчи появятся скоро"
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.06), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 400 - 200)
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear { phase = 1 }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous))
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}
