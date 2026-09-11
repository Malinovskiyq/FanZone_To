import SwiftUI

// MARK: - Matches Filter

enum MatchFilter: String, CaseIterable {
    case upcoming = "upcoming"
    case past     = "past"
    case home     = "home"
    case away     = "away"

    var displayName: String {
        switch self {
        case .upcoming: return "Ближайшие"
        case .past:     return "Прошедшие"
        case .home:     return "Домашние"
        case .away:     return "Выездные"
        }
    }
}

// MARK: - Matches ViewModel

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: MatchFilter = .upcoming

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [Match] = try await APIClient.shared.request(
                .getMatches(filter: selectedFilter.rawValue)
            )
            matches = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Matches View

struct MatchesView: View {
    @StateObject private var vm = MatchesViewModel()
    @State private var selectedMatch: Match?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter chips
                filterChips
                    .padding(.top, 8)

                // List
                if vm.isLoading && vm.matches.isEmpty {
                    loadingView
                } else if vm.matches.isEmpty {
                    emptyView
                } else {
                    matchesList
                }
            }
        }
        .navigationTitle("Матчи")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .onChange(of: vm.selectedFilter) { _ in
            Task { await vm.load() }
        }
        .navigationDestination(item: $selectedMatch) { match in
            MatchDetailView(match: match)
        }
    }

    // MARK: - Subviews

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MatchFilter.allCases, id: \.self) { filter in
                    Button(filter.displayName) {
                        vm.selectedFilter = filter
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(vm.selectedFilter == filter ? .white : AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        vm.selectedFilter == filter
                        ? AppTheme.brandGradient
                        : LinearGradient(colors: [AppTheme.surface], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.3), value: vm.selectedFilter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var matchesList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(vm.matches) { match in
                    MatchCard(match: match) { selectedMatch = match }
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable { await vm.load() }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous)
                    .fill(AppTheme.surface)
                    .frame(height: 160)
                    .padding(.horizontal, 16)
                    .shimmer()
            }
        }
        .padding(.top, 8)
    }

    private var emptyView: some View {
        ScrollView {
            EmptyStateView(
                icon: "hockey.puck",
                title: "Нет матчей",
                subtitle: "Здесь пока нет матчей в выбранной категории",
                actionTitle: "Обновить"
            ) {
                Task { await vm.load() }
            }
            .padding(.top, 60)
        }
        .refreshable { await vm.load() }
    }
}

// MARK: - Match Detail ViewModel

@MainActor
class MatchDetailViewModel: ObservableObject {
    @Published var match: Match
    @Published var existingBooking: Booking?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(match: Match) { self.match = match }

    func load() async {
        isLoading = true
        // Load fresh match data and check for existing booking
        do {
            async let freshMatch: Match = APIClient.shared.request(.getMatch(id: match.id))
            async let myBookings: [Booking] = APIClient.shared.request(.getMyBookings)
            let (m, bookings) = try await (freshMatch, myBookings)
            match = m
            existingBooking = bookings.first { $0.match.id == match.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    let match: Match
    @StateObject private var vm: MatchDetailViewModel
    @State private var showBookingForm = false

    init(match: Match) {
        self.match = match
        self._vm   = StateObject(wrappedValue: MatchDetailViewModel(match: match))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .sheet(isPresented: $showBookingForm) {
            BookingFormView(match: vm.match) {
                Task { await vm.load() }
            }
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background
            Rectangle()
                .fill(AppTheme.heroGradient)
                .frame(height: 240)

            HStack(spacing: 0) {
                teamColumn(team: vm.match.homeTeam)
                VStack(spacing: 8) {
                    Text("VS")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.brandSecondary)
                    BookingWindowBadge(status: vm.match.bookingWindowStatus)
                }
                .frame(width: 80)
                teamColumn(team: vm.match.awayTeam)
            }
            .padding(.bottom, 20)
        }
    }

    private func teamColumn(team: Team) -> some View {
        VStack(spacing: 10) {
            Group {
                if let url = team.logoURL {
                    AsyncImage(url: url) { p in
                        if case .success(let img) = p {
                            img.resizable().scaledToFit()
                        } else { fallbackLogo(team.name, 72) }
                    }
                } else { fallbackLogo(team.name, 72) }
            }
            .frame(width: 72, height: 72)

            Text(team.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 110)
        }
        .frame(maxWidth: .infinity)
    }

    private func fallbackLogo(_ name: String, _ size: CGFloat) -> some View {
        ZStack {
            Circle().fill(AppTheme.surfaceElevated)
            Text(name.prefix(2).uppercased())
                .font(.system(size: size * 0.3, weight: .black))
                .foregroundColor(AppTheme.brandPrimary)
        }
    }

    // MARK: Content

    private var contentSection: some View {
        VStack(spacing: 16) {
            // Date / Time / Arena card
            FZCard {
                VStack(spacing: 14) {
                    infoRow(icon: "calendar", label: "Дата", value: vm.match.scheduledAt.ruShortDateString)
                    Divider().background(AppTheme.surfaceElevated)
                    infoRow(icon: "clock", label: "Время", value: vm.match.scheduledAt.ruTimeString)
                    Divider().background(AppTheme.surfaceElevated)
                    infoRow(icon: "building.2", label: "Арена", value: vm.match.arena.name)
                    Divider().background(AppTheme.surfaceElevated)
                    infoRow(icon: "location", label: "Город", value: vm.match.arena.city)
                    if !vm.match.isHome {
                        Divider().background(AppTheme.surfaceElevated)
                        infoRow(icon: "airplane", label: "Тип", value: "Выездной матч", valueColor: AppTheme.brandSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Fan sector card
            if let sector = vm.match.fanSector {
                FZCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Фан-сектор", systemImage: "person.3.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 0) {
                            sectorStat(label: "Всего", value: sector.capacity, color: AppTheme.textSecondary)
                            Divider().frame(height: 40).background(AppTheme.surfaceElevated)
                            sectorStat(label: "Подтверждено", value: vm.match.confirmedBookingsCount ?? 0, color: AppTheme.success)
                            Divider().frame(height: 40).background(AppTheme.surfaceElevated)
                            sectorStat(label: "Свободно", value: vm.match.availableSeats, color: vm.match.availableSeats > 10 ? AppTheme.success : AppTheme.warning)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppTheme.surfaceElevated).frame(height: 6)
                                Capsule()
                                    .fill(AppTheme.brandGradient)
                                    .frame(width: geo.size.width * vm.match.occupancyPercent, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("Бронирование до \(vm.match.bookingCloseAt.ruDateTimeString)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Description
            if let desc = vm.match.description, !desc.isEmpty {
                FZCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Описание", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Action button
            actionButton
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let booking = vm.existingBooking {
            VStack(spacing: 10) {
                BookingStatusBadge(status: booking.status)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))

                if booking.status == .confirmed, booking.ticket != nil {
                    NavigationLink("Показать билет") {
                        TicketView(booking: booking)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.brandPrimary)
                }
            }
        } else {
            FZPrimaryButton(
                vm.match.isBookingOpen ? "ЗАБРОНИРОВАТЬ МЕСТО" : "БРОНИРОВАНИЕ ЗАКРЫТО",
                isLoading: vm.isLoading
            ) {
                showBookingForm = true
            }
            .disabled(!vm.match.isBookingOpen)
            .opacity(vm.match.isBookingOpen ? 1 : 0.5)
        }
    }

    private func infoRow(icon: String, label: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(AppTheme.textSecondary).frame(width: 20)
            Text(label).font(.subheadline).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundColor(valueColor)
        }
    }

    private func sectorStat(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Booking Form ViewModel

@MainActor
class BookingFormViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false

    func submitBooking(matchId: String) async {
        isLoading = true
        do {
            let _: Booking = try await APIClient.shared.request(.createBooking(matchId: matchId))
            withAnimation(.spring()) { isSuccess = true }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Booking Form View

struct BookingFormView: View {
    let match: Match
    var onSuccess: (() -> Void)?

    @StateObject private var vm = BookingFormViewModel()
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if vm.isSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Бронирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Match summary
                FZCard {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Матч")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(match.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        Divider().background(AppTheme.surfaceElevated)
                        HStack {
                            Label(match.scheduledAt.ruShortDateString, systemImage: "calendar")
                            Spacer()
                            Label(match.scheduledAt.ruTimeString, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                        if let sector = match.fanSector {
                            Divider().background(AppTheme.surfaceElevated)
                            HStack {
                                Label(sector.name, systemImage: "person.3.fill")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("\(match.availableSeats) мест")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.success)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Booking on behalf of
                FZCard {
                    HStack(spacing: 14) {
                        UserAvatarView(user: auth.currentUser, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Бронирование для:")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text(auth.currentUser?.displayName ?? "—")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                            Text("@\(auth.currentUser?.username ?? "")")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.success)
                    }
                }
                .padding(.horizontal, 16)

                // Notice
                Label("После отправки заявка поступит ответственному за бронирование. Вы получите уведомление о результате.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 16)

                // Submit button
                FZPrimaryButton("ОТПРАВИТЬ ЗАЯВКУ", isLoading: vm.isLoading) {
                    Task { await vm.submitBooking(matchId: match.id) }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.success)
                .scaleEffect(1.0)
            VStack(spacing: 10) {
                Text("Заявка отправлена!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Заявка на матч \(match.title) отправлена ответственному за бронирование.\nОжидайте подтверждения.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            FZPrimaryButton("Готово") {
                onSuccess?()
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
