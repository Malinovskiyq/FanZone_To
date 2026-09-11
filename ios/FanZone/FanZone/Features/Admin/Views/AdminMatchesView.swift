import SwiftUI

// MARK: - Admin Matches ViewModel

@MainActor
class AdminMatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var teams:   [Team]  = []
    @Published var arenas:  [Arena] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    func load() async {
        isLoading = true
        async let m: [Match] = (try? APIClient.shared.request(.getMatches(filter: nil))) ?? []
        async let t: [Team]  = (try? APIClient.shared.request(.getTeams)) ?? []
        async let a: [Arena] = (try? APIClient.shared.request(.getArenas)) ?? []
        let (matches, teams, arenas) = await (m, t, a)
        self.matches = matches
        self.teams   = teams
        self.arenas  = arenas
        isLoading = false
    }

    func delete(match: Match) async {
        do {
            try await APIClient.shared.requestEmpty(.deleteMatch(id: match.id))
            await load()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Admin Matches View

struct AdminMatchesView: View {
    @StateObject private var vm = AdminMatchesViewModel()
    @State private var showCreateMatch = false
    @State private var matchToEdit: Match?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if vm.isLoading && vm.matches.isEmpty {
                ProgressView().tint(AppTheme.brandPrimary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.matches.isEmpty {
                EmptyStateView(icon: "hockey.puck", title: "Нет матчей",
                               subtitle: "Создайте первый матч")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.matches) { match in
                        Button {
                            matchToEdit = match
                            showCreateMatch = true
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(match.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                HStack(spacing: 10) {
                                    Label(match.scheduledAt.ruDateTimeString, systemImage: "calendar")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    BookingWindowBadge(status: match.bookingWindowStatus)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.surface)
                        .listRowSeparatorTint(AppTheme.surfaceElevated)
                        .swipeActions(edge: .trailing) {
                            Button("Удалить", role: .destructive) {
                                Task { await vm.delete(match: match) }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("Матчи")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { matchToEdit = nil; showCreateMatch = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.brandPrimary)
                        .font(.title3)
                }
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showCreateMatch, onDismiss: { Task { await vm.load() } }) {
            CreateMatchView(matchToEdit: matchToEdit, teams: vm.teams, arenas: vm.arenas)
        }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
    }
}

// MARK: - Create Match View

struct CreateMatchView: View {
    let matchToEdit: Match?
    let teams: [Team]
    let arenas: [Arena]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CreateMatchViewModel()

    @State private var selectedHomeTeamId = ""
    @State private var awayTeamName       = ""
    @State private var selectedArenaId    = ""
    @State private var scheduledAt        = Date().addingTimeInterval(7 * 86400)
    @State private var bookingOpenAt      = Date().addingTimeInterval(1 * 86400)
    @State private var bookingCloseAt     = Date().addingTimeInterval(6 * 86400)
    @State private var sectorName         = "Фан-сектор"
    @State private var capacity           = "100"
    @State private var description        = ""
    @State private var isHome             = true

    var isEditing: Bool { matchToEdit != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                Form {
                    Section("Команды") {
                        if !teams.isEmpty {
                            Picker("Команда хозяев", selection: $selectedHomeTeamId) {
                                ForEach(teams) { t in Text(t.name).tag(t.id) }
                            }
                            .tint(AppTheme.brandPrimary)
                        }
                        TextField("Команда гостей", text: $awayTeamName)
                        Toggle("Домашний матч", isOn: $isHome)
                    }
                    .listRowBackground(AppTheme.surface)

                    Section("Место и время") {
                        if !arenas.isEmpty {
                            Picker("Арена", selection: $selectedArenaId) {
                                ForEach(arenas) { a in Text("\(a.name), \(a.city)").tag(a.id) }
                            }
                            .tint(AppTheme.brandPrimary)
                        }
                        DatePicker("Дата матча", selection: $scheduledAt, displayedComponents: [.date, .hourAndMinute])
                            .tint(AppTheme.brandPrimary)
                        DatePicker("Открытие брони", selection: $bookingOpenAt, displayedComponents: [.date, .hourAndMinute])
                            .tint(AppTheme.brandPrimary)
                        DatePicker("Закрытие брони", selection: $bookingCloseAt, displayedComponents: [.date, .hourAndMinute])
                            .tint(AppTheme.brandPrimary)
                    }
                    .listRowBackground(AppTheme.surface)

                    Section("Фан-сектор") {
                        TextField("Название сектора", text: $sectorName)
                        TextField("Вместимость", text: $capacity)
                            .keyboardType(.numberPad)
                    }
                    .listRowBackground(AppTheme.surface)

                    Section("Описание") {
                        TextField("Описание матча", text: $description, axis: .vertical)
                            .lineLimit(4, reservesSpace: true)
                    }
                    .listRowBackground(AppTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Редактировать матч" : "Новый матч")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .foregroundColor(AppTheme.brandPrimary)
                        .disabled(vm.isLoading)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .onAppear { setupDefaults() }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
        .onChange(of: vm.isSaved) { saved in
            if saved { dismiss() }
        }
    }

    private func setupDefaults() {
        selectedHomeTeamId = teams.first?.id ?? ""
        selectedArenaId    = arenas.first?.id ?? ""
        if let match = matchToEdit {
            awayTeamName  = match.awayTeam.name
            scheduledAt   = match.scheduledAt
            bookingOpenAt = match.bookingOpenAt
            bookingCloseAt = match.bookingCloseAt
            sectorName    = match.fanSector?.name ?? "Фан-сектор"
            capacity      = "\(match.fanSector?.capacity ?? 100)"
            description   = match.description ?? ""
            isHome        = match.isHome
        }
    }

    private func save() {
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "homeTeamId":     selectedHomeTeamId,
            "awayTeamName":   awayTeamName,
            "arenaId":        selectedArenaId,
            "scheduledAt":    iso.string(from: scheduledAt),
            "bookingOpenAt":  iso.string(from: bookingOpenAt),
            "bookingCloseAt": iso.string(from: bookingCloseAt),
            "isHome":         isHome,
            "fanSector": [
                "name":     sectorName,
                "capacity": Int(capacity) ?? 100
            ]
        ]
        if !description.isEmpty { body["description"] = description }
        Task {
            if let match = matchToEdit {
                await vm.updateMatch(id: match.id, body: body)
            } else {
                await vm.createMatch(body: body)
            }
        }
    }
}

// MARK: - Create Match ViewModel

@MainActor
class CreateMatchViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isSaved   = false
    @Published var showError = false
    @Published var errorMessage: String?

    func createMatch(body: [String: Any]) async {
        isLoading = true
        do {
            let _: Match = try await APIClient.shared.request(.createMatch(body: body))
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func updateMatch(id: String, body: [String: Any]) async {
        isLoading = true
        do {
            let _: Match = try await APIClient.shared.request(.updateMatch(id: id, body: body))
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Admin Users ViewModel

@MainActor
class AdminUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var showError = false
    @Published var errorMessage: String?

    @MainActor func load(search: String = "") async {
        isLoading = true
        users = (try? await APIClient.shared.request(.getUsers(search: search.isEmpty ? nil : search))) ?? []
        isLoading = false
    }

    func updateRole(userId: String, role: UserRole) async {
        do {
            let _: User = try await APIClient.shared.request(.updateUserRole(id: userId, role: role.rawValue))
            await load(search: searchText)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Admin Users View

struct AdminUsersView: View {
    @StateObject private var vm = AdminUsersViewModel()
    @State private var searchText = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textSecondary)
                    TextField("Поиск по имени или нику", text: $searchText)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .onChange(of: searchText) { q in
                    Task { await vm.load(search: q) }
                }

                if vm.isLoading {
                    ProgressView().tint(AppTheme.brandPrimary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.users.isEmpty {
                    EmptyStateView(icon: "person.fill.questionmark", title: "Пользователи не найдены",
                                   subtitle: "Попробуйте изменить поисковый запрос")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(vm.users) { user in
                        NavigationLink {
                            UserProfileManagerView(user: user)
                        } label: {
                            HStack(spacing: 12) {
                                UserAvatarView(user: user, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(user.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                    Text("@\(user.username)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                RoleBadge(role: user.role)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.surface)
                        .listRowSeparatorTint(AppTheme.surfaceElevated)
                        .contextMenu {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                if role != user.role {
                                    Button("Назначить: \(role.displayName)") {
                                        Task { await vm.updateRole(userId: user.id, role: role) }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await vm.load(search: searchText) }
                }
            }
        }
        .navigationTitle("Пользователи")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
    }
}

// MARK: - Admin Stats View

struct AdminStatsView: View {
    @State private var overview: AdminOverviewStats?
    @State private var matchStats: [AdminMatchStats] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if let s = overview {
                        // Overview cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(emoji: "👥", value: "\(s.totalUsers)",       label: "Пользователей",  color: AppTheme.info)
                            StatCard(emoji: "📋", value: "\(s.totalBookings)",    label: "Всего заявок",   color: AppTheme.brandSecondary)
                            StatCard(emoji: "✅", value: "\(s.confirmedBookings)", label: "Подтверждено",   color: AppTheme.success)
                            StatCard(emoji: "🏒", value: "\(s.totalAttended)",    label: "Посетило",       color: AppTheme.brandPrimary)
                        }
                        .padding(.horizontal, 16)

                        // Additional stats
                        FZCard {
                            VStack(spacing: 10) {
                                statRow("Отклонено заявок",    "\(s.rejectedBookings)")
                                Divider().background(AppTheme.surfaceElevated)
                                statRow("Отменено заявок",     "\(s.cancelledBookings)")
                                Divider().background(AppTheme.surfaceElevated)
                                statRow("Не пришли",           "\(s.totalAbsent)")
                                Divider().background(AppTheme.surfaceElevated)
                                statRow("Предстоящих матчей",  "\(s.upcomingMatches)")
                                Divider().background(AppTheme.surfaceElevated)
                                statRow("Завершённых матчей",  "\(s.completedMatches)")
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if isLoading {
                        ProgressView().tint(AppTheme.brandPrimary)
                    }

                    // Per-match stats
                    if !matchStats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Статистика по матчам")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            ForEach(matchStats) { stat in
                                FZCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(stat.matchTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                        Text(stat.scheduledAt.ruDateTimeString)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)

                                        HStack(spacing: 0) {
                                            matchStatPill("Мест", "\(stat.totalCapacity)", AppTheme.textSecondary)
                                            matchStatPill("Бронь", "\(stat.confirmedBookings)", AppTheme.brandPrimary)
                                            matchStatPill("Посетило", "\(stat.attended)", AppTheme.success)
                                            matchStatPill("Не пришло", "\(stat.absent)", AppTheme.error)
                                        }

                                        // Occupancy bar
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule().fill(AppTheme.surfaceElevated).frame(height: 5)
                                                Capsule()
                                                    .fill(AppTheme.brandGradient)
                                                    .frame(width: geo.size.width * stat.occupancyPercent, height: 5)
                                            }
                                        }
                                        .frame(height: 5)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .refreshable { await load() }
        }
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        async let o: AdminOverviewStats? = try? APIClient.shared.request(.getAdminOverviewStats)
        async let m: [AdminMatchStats]   = (try? APIClient.shared.request(.getAdminMatchStats)) ?? []
        let (overviewResult, matchResult) = await (o, m)
        overview   = overviewResult
        matchStats = matchResult
        isLoading = false
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.bold)).foregroundColor(.white)
        }
    }

    private func matchStatPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
