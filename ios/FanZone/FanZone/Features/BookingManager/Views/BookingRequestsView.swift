import SwiftUI
import VisionKit
import AVFoundation

// MARK: - Booking Requests ViewModel

@MainActor
class BookingRequestsViewModel: ObservableObject {
    @Published var pendingBookings:   [Booking] = []
    @Published var confirmedBookings: [Booking] = []
    @Published var rejectedBookings:  [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    func load() async {
        isLoading = true
        async let pending:   [Booking] = (try? APIClient.shared.request(.getAllBookings(status: "PENDING")))   ?? []
        async let confirmed: [Booking] = (try? APIClient.shared.request(.getAllBookings(status: "CONFIRMED"))) ?? []
        async let rejected:  [Booking] = (try? APIClient.shared.request(.getAllBookings(status: "REJECTED")))  ?? []
        let (p, c, r) = await (pending, confirmed, rejected)
        pendingBookings   = p
        confirmedBookings = c
        rejectedBookings  = r
        isLoading = false
    }

    func confirm(bookingId: String) async {
        do {
            let _: Booking = try await APIClient.shared.request(.confirmBooking(id: bookingId))
            await load()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func reject(bookingId: String) async {
        do {
            let _: Booking = try await APIClient.shared.request(.rejectBooking(id: bookingId))
            await load()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Booking Requests View (Manager)

struct BookingRequestsView: View {
    @StateObject private var vm = BookingRequestsViewModel()
    @State private var segment = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Новые (\(vm.pendingBookings.count))").tag(0)
                    Text("Подтверждённые").tag(1)
                    Text("Отклонённые").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if vm.isLoading && vm.pendingBookings.isEmpty {
                    ProgressView().tint(AppTheme.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let list: [Booking] = segment == 0 ? vm.pendingBookings
                                       : segment == 1 ? vm.confirmedBookings
                                       : vm.rejectedBookings
                    if list.isEmpty {
                        ScrollView {
                            EmptyStateView(
                                icon: "list.clipboard",
                                title: "Нет заявок",
                                subtitle: "Заявки появятся здесь"
                            )
                            .padding(.top, 60)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(list) { booking in
                                    BookingRequestCard(
                                        booking: booking,
                                        onConfirm: segment == 0 ? {
                                            _ = Task { await vm.confirm(bookingId: booking.id) }
                                        } : nil,
                                        onReject: segment == 0 ? {
                                            _ = Task { await vm.reject(bookingId: booking.id) }
                                        } : nil
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .refreshable { await vm.load() }
                    }
                }
            }
        }
        .navigationTitle("Заявки")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
    }
}

// MARK: - Booking Request Card

struct BookingRequestCard: View {
    let booking: Booking
    var onConfirm: (() -> Void)?
    var onReject:  (() -> Void)?

    @State private var userStats: UserStats?
    @State private var showUserProfile = false

    var body: some View {
        VStack(spacing: 0) {
            // User row
            HStack(spacing: 12) {
                Button { showUserProfile = true } label: {
                    UserAvatarView(user: booking.user, size: 52, showBorder: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(booking.user?.displayName ?? "—")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                        if let role = booking.user?.role {
                            RoleBadge(role: role)
                        }
                    }
                    Text("@\(booking.user?.username ?? "—")")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(booking.match.title)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Button { showUserProfile = true } label: {
                    Image(systemName: "chevron.right.circle")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(16)

            // Quick stats row
            if let stats = userStats {
                Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
                HStack(spacing: 0) {
                    quickStat("Посещено", "\(stats.attendedMatches)", AppTheme.success)
                    Divider().frame(height: 30).background(AppTheme.surfaceElevated)
                    quickStat("Подтверждено", "\(stats.confirmedBookings)", AppTheme.brandPrimary)
                    Divider().frame(height: 30).background(AppTheme.surfaceElevated)
                    quickStat("Не пришёл", "\(stats.absentMatches)", AppTheme.error)
                }
                .padding(.vertical, 10)
            }

            // Date info
            Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
            HStack {
                Label(booking.match.scheduledAt.ruDateTimeString, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                BookingStatusBadge(status: booking.status)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Action buttons (only for pending)
            if let onConfirm, let onReject {
                Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("ОТКЛОНИТЬ", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(AppTheme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.error.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                    }
                    Button(action: onConfirm) {
                        Label("ПОДТВЕРДИТЬ", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.success)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                    }
                }
                .padding(16)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .task { await loadUserStats() }
        .navigationDestination(isPresented: $showUserProfile) {
            if let user = booking.user {
                UserProfileManagerView(user: user)
            }
        }
    }

    private func quickStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadUserStats() async {
        guard let userId = booking.user?.id else { return }
        userStats = try? await APIClient.shared.request(.getUserStats(userId: userId))
    }
}

// MARK: - Match Participants ViewModel

@MainActor
class MatchParticipantsViewModel: ObservableObject {
    @Published var matches:      [Match] = []
    @Published var participants: [MatchParticipant] = []
    @Published var selectedMatch: Match?
    @Published var isLoading = false
    @Published var searchText = ""

    var filtered: [MatchParticipant] {
        if searchText.isEmpty { return participants }
        let q = searchText.lowercased()
        return participants.filter {
            $0.user.displayName.lowercased().contains(q) ||
            $0.user.username.lowercased().contains(q)
        }
    }

    func loadMatches() async {
        isLoading = true
        matches = (try? await APIClient.shared.request(.getMatches(filter: "upcoming"))) ?? []
        if selectedMatch == nil { selectedMatch = matches.first }
        if let m = selectedMatch { await loadParticipants(matchId: m.id) }
        isLoading = false
    }

    func loadParticipants(matchId: String) async {
        isLoading = true
        participants = (try? await APIClient.shared.request(.getMatchParticipants(matchId: matchId))) ?? []
        isLoading = false
    }

    func markAttendance(bookingId: String, status: AttendanceStatus) async {
        do {
            try await APIClient.shared.requestEmpty(
                .markAttendance(bookingId: bookingId, status: status.rawValue)
            )
            if let matchId = selectedMatch?.id { await loadParticipants(matchId: matchId) }
        } catch {}
    }
}

// MARK: - Match Participants View (Manager)

struct MatchParticipantsView: View {
    @StateObject private var vm = MatchParticipantsViewModel()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Match picker
                if !vm.matches.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vm.matches) { match in
                                Button(match.title) {
                                    vm.selectedMatch = match
                                    Task { await vm.loadParticipants(matchId: match.id) }
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(vm.selectedMatch?.id == match.id ? .white : AppTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    vm.selectedMatch?.id == match.id
                                    ? AppTheme.brandGradient
                                    : LinearGradient(colors: [AppTheme.surface], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textSecondary)
                    TextField("Поиск по имени", text: $vm.searchText)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Stats summary
                if let match = vm.selectedMatch {
                    HStack(spacing: 16) {
                        summaryPill("Всего", "\(vm.participants.count)", AppTheme.textSecondary)
                        summaryPill("Подтверждено", "\(vm.participants.filter { $0.status == .confirmed }.count)", AppTheme.success)
                        summaryPill("Посетило", "\(vm.participants.filter { $0.attendance?.status == .attended }.count)", AppTheme.brandPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                // List
                if vm.isLoading {
                    ProgressView().tint(AppTheme.brandPrimary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.filtered.isEmpty {
                    EmptyStateView(icon: "person.3", title: "Нет участников",
                                   subtitle: "Подтверждённых участников пока нет")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.filtered) { participant in
                                ParticipantRow(participant: participant) { status in
                                    Task { await vm.markAttendance(bookingId: participant.id, status: status) }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        if let m = vm.selectedMatch { await vm.loadParticipants(matchId: m.id) }
                    }
                }
            }
        }
        .navigationTitle("Участники")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.loadMatches() }
    }

    private func summaryPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .black)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: MatchParticipant
    let onMarkAttendance: (AttendanceStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(user: participant.user, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(participant.user.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text("@\(participant.user.username)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Attendance buttons
            HStack(spacing: 8) {
                let attStatus = participant.attendance?.status ?? .unknown
                Button {
                    onMarkAttendance(.attended)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(attStatus == .attended ? AppTheme.success : AppTheme.textTertiary)
                }
                Button {
                    onMarkAttendance(.absent)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(attStatus == .absent ? AppTheme.error : AppTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }
}

// MARK: - QR Scanner ViewModel

@MainActor
class QRScannerViewModel: ObservableObject {
    @Published var isScanning = true
    @Published var verificationResult: QRVerificationResult?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func verify(qrToken: String) async {
        isScanning = false
        isLoading  = true
        do {
            verificationResult = try await APIClient.shared.request(.verifyQR(token: qrToken))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markAttended(qrToken: String) async {
        isLoading = true
        do {
            try await APIClient.shared.requestEmpty(.markAttendedByQR(qrToken: qrToken))
            if var result = verificationResult {
                verificationResult = QRVerificationResult(
                    isValid: result.isValid, isUsed: true,
                    booking: result.booking, message: "Посещение отмечено"
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reset() {
        isScanning = true
        verificationResult = nil
        errorMessage = nil
    }
}

// MARK: - QR Scanner Screen

struct QRScannerScreenView: View {
    @StateObject private var vm = QRScannerViewModel()
    @State private var showResult = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if vm.isScanning {
                scannerView
            } else if let result = vm.verificationResult {
                ticketVerificationView(result: result)
            } else if vm.isLoading {
                LoadingOverlay("Проверка билета...")
            }
        }
        .navigationTitle("Сканер")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var scannerView: some View {
        VStack(spacing: 0) {
            DataScannerRepresentable { token in
                Task { await vm.verify(qrToken: token) }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(scannerOverlay)

            VStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.brandPrimary)
                Text("Наведите камеру на QR-код билета")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
        }
    }

    private var scannerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.brandPrimary, lineWidth: 3)
                .frame(width: 220, height: 220)
                .background(Color.clear)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func ticketVerificationView(result: QRVerificationResult) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status icon
                if result.isUsed {
                    resultHeader(icon: "exclamationmark.triangle.fill", color: AppTheme.warning,
                                 title: "Билет уже использован")
                } else if result.isValid, let booking = result.booking {
                    resultHeader(icon: "checkmark.seal.fill", color: AppTheme.success,
                                 title: "Билет действителен")

                    // User info card
                    FZCard {
                        HStack(spacing: 14) {
                            UserAvatarView(user: booking.user, size: 56, showBorder: true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(booking.user?.displayName ?? "—")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white)
                                Text("@\(booking.user?.username ?? "")")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Match info card
                    FZCard {
                        VStack(spacing: 10) {
                            Text(booking.match.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Label(booking.match.scheduledAt.ruDateTimeString, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            if let sectorName = booking.sectorName {
                                Label(sectorName, systemImage: "person.3")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            BookingStatusBadge(status: booking.status)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)

                    // Mark attended button
                    if !result.isUsed {
                        FZPrimaryButton("ОТМЕТИТЬ ПОСЕЩЕНИЕ", isLoading: vm.isLoading) {
                            if let token = booking.ticket?.qrToken {
                                Task { await vm.markAttended(qrToken: token) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                } else {
                    resultHeader(icon: "xmark.circle.fill", color: AppTheme.error,
                                 title: "Билет не найден")
                }

                // Scan again
                FZSecondaryButton(title: "СКАНИРОВАТЬ СНОВА") { vm.reset() }
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
    }

    private func resultHeader(icon: String, color: Color, title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(color)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(.top, 16)
    }
}

// MARK: - DataScanner Representable

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            if case .barcode(let bc) = addedItems.first, let value = bc.payloadStringValue {
                dataScanner.stopScanning()
                onScan(value)
            }
        }
    }
}

// MARK: - User Profile Manager View

struct UserProfileManagerView: View {
    let user: User
    @State private var stats: UserStats?
    @State private var bookings: [Booking] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Profile header
                    FZCard {
                        HStack(spacing: 16) {
                            UserAvatarView(user: user, size: 80, showBorder: true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.displayName)
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                if let city = user.profile?.city {
                                    Label(city, systemImage: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                RoleBadge(role: user.role)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)

                    // Social links
                    if let links = user.socialLinks, !links.isEmpty {
                        FZCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Социальные сети", systemImage: "link")
                                    .font(.headline).foregroundColor(.white)
                                ForEach(links) { link in
                                    Button {
                                        if let url = URL(string: link.url) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: link.socialPlatform.systemImage)
                                                .foregroundColor(Color(hex: link.socialPlatform.hexColor))
                                                .frame(width: 24)
                                            Text(link.displayLabel)
                                                .font(.subheadline)
                                                .foregroundColor(AppTheme.textSecondary)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Stats
                    if let s = stats {
                        FZCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Статистика", systemImage: "chart.bar.fill")
                                    .font(.headline).foregroundColor(.white)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    StatCard(emoji: "🏒", value: "\(s.attendedMatches)",    label: "Посещено", color: AppTheme.success)
                                    StatCard(emoji: "🎟", value: "\(s.confirmedBookings)",  label: "Подтверждено", color: AppTheme.brandPrimary)
                                    StatCard(emoji: "📅", value: "\(s.totalBookings)",      label: "Всего броней", color: AppTheme.brandSecondary)
                                    StatCard(emoji: "❌", value: "\(s.absentMatches)",      label: "Не пришёл", color: AppTheme.error)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Recent bookings
                    if !bookings.isEmpty {
                        FZCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("История бронирований", systemImage: "clock.arrow.circlepath")
                                    .font(.headline).foregroundColor(.white)
                                ForEach(bookings.prefix(5)) { booking in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(booking.match.title).font(.caption.weight(.semibold)).foregroundColor(.white)
                                            Text(booking.match.scheduledAt.ruShortDateString).font(.caption2).foregroundColor(AppTheme.textSecondary)
                                        }
                                        Spacer()
                                        BookingStatusBadge(status: booking.status)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        async let s: UserStats?  = try? APIClient.shared.request(.getUserStats(userId: user.id))
        async let b: [Booking]?  = try? APIClient.shared.request(.getAllBookings(status: nil))
        let (statsResult, _) = await (s, b)
        stats = statsResult
        isLoading = false
    }
}
