import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - My Bookings ViewModel

@MainActor
class MyBookingsViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCancelConfirm = false
    @Published var bookingToCancel: Booking?

    var upcoming: [Booking] { bookings.filter { $0.isUpcoming } }
    var history:  [Booking] { bookings.filter { !$0.isUpcoming } }

    func load() async {
        isLoading = true
        do {
            let result: [Booking] = try await APIClient.shared.request(.getMyBookings)
            bookings = result.sorted { $0.match.scheduledAt > $1.match.scheduledAt }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func cancel(_ booking: Booking) async {
        do {
            let _: Booking = try await APIClient.shared.request(.cancelBooking(id: booking.id))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - My Bookings View

struct MyBookingsView: View {
    @StateObject private var vm = MyBookingsViewModel()
    @State private var segment = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Предстоящие").tag(0)
                    Text("История").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if vm.isLoading && vm.bookings.isEmpty {
                    ProgressView()
                        .tint(AppTheme.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let list = segment == 0 ? vm.upcoming : vm.history
                    if list.isEmpty {
                        emptyState(isUpcoming: segment == 0)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(list) { booking in
                                    BookingCard(booking: booking, onCancel: {
                                        vm.bookingToCancel = booking
                                        vm.showCancelConfirm = true
                                    })
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .refreshable { await vm.load() }
                    }
                }
            }
        }
        .navigationTitle("Мои брони")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .alert("Отменить бронь?", isPresented: $vm.showCancelConfirm) {
            Button("Отменить", role: .destructive) {
                if let b = vm.bookingToCancel {
                    Task { await vm.cancel(b) }
                }
            }
            Button("Нет", role: .cancel) {}
        } message: {
            Text("Вы уверены, что хотите отменить бронирование?")
        }
    }

    private func emptyState(isUpcoming: Bool) -> some View {
        ScrollView {
            EmptyStateView(
                icon: isUpcoming ? "ticket" : "clock.arrow.circlepath",
                title: isUpcoming ? "Нет предстоящих броней" : "История пуста",
                subtitle: isUpcoming
                    ? "Забронируйте место на ближайший матч!"
                    : "Ваша история бронирований появится здесь"
            )
            .padding(.top, 60)
        }
    }
}

// MARK: - Booking Card

struct BookingCard: View {
    let booking: Booking
    var onCancel: (() -> Void)?

    var body: some View {
        NavigationLink {
            BookingDetailView(booking: booking)
        } label: {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Left color accent
                    RoundedRectangle(cornerRadius: 3)
                        .fill(booking.status.color)
                        .frame(width: 4)
                        .frame(minHeight: 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(booking.match.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 12) {
                            Label(booking.match.scheduledAt.ruShortDateString, systemImage: "calendar")
                            Label(booking.match.scheduledAt.ruTimeString, systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        if let sectorName = booking.sectorName {
                            Label(sectorName, systemImage: "person.3")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        BookingStatusBadge(status: booking.status)
                        if let att = booking.attendance {
                            AttendanceStatusBadge(status: att.status)
                        }
                    }
                }
                .padding(14)

                // Action buttons
                if booking.isUpcoming {
                    Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 14)
                    HStack(spacing: 12) {
                        if booking.status == .confirmed, booking.ticket != nil {
                            NavigationLink {
                                TicketView(booking: booking)
                            } label: {
                                Label("Билет", systemImage: "qrcode")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.brandPrimary)
                            }
                        }
                        Spacer()
                        if booking.canCancel {
                            Button("Отменить") { onCancel?() }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.error)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking Detail View

struct BookingDetailView: View {
    let booking: Booking

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Status hero
                    FZCard {
                        VStack(spacing: 12) {
                            Image(systemName: booking.status.systemImage)
                                .font(.system(size: 44))
                                .foregroundColor(booking.status.color)
                            Text(booking.status.displayName)
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            Text("Заявка #\(booking.shortId)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 16)

                    // Match info
                    FZCard {
                        VStack(spacing: 12) {
                            Label("Матч", systemImage: "hockey.puck.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Divider().background(AppTheme.surfaceElevated)
                            Text(booking.match.title)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Label(booking.match.scheduledAt.ruDateTimeString, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Label(booking.match.arena.name, systemImage: "building.2")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Attendance
                    if let att = booking.attendance, att.status != .unknown {
                        FZCard {
                            HStack {
                                Text("Посещение:")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                AttendanceStatusBadge(status: att.status)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Ticket button
                    if booking.status == .confirmed, booking.ticket != nil {
                        NavigationLink {
                            TicketView(booking: booking)
                        } label: {
                            Label("Показать билет", systemImage: "qrcode.viewfinder")
                                .primaryButtonStyle()
                        }
                        .padding(.horizontal, 16)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Бронирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Ticket View

struct TicketView: View {
    let booking: Booking
    @StateObject private var vm: TicketViewModel

    init(booking: Booking) {
        self.booking = booking
        self._vm = StateObject(wrappedValue: TicketViewModel(booking: booking))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    if let ticket = vm.ticket {
                        ticketCard(ticket: ticket)
                    } else if vm.isLoading {
                        ProgressView().tint(AppTheme.brandPrimary)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        EmptyStateView(icon: "ticket.slash", title: "Билет недоступен",
                                       subtitle: "Попробуйте обновить страницу")
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Электронный билет")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
    }

    @ViewBuilder
    private func ticketCard(ticket: Ticket) -> some View {
        VStack(spacing: 0) {
            // Top gradient band
            LinearGradient(
                colors: [AppTheme.brandPrimary, AppTheme.brandPrimary.opacity(0.7)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 6)

            VStack(spacing: 20) {
                // Club branding
                HStack {
                    Image(systemName: "hockey.puck.fill")
                        .foregroundColor(AppTheme.brandPrimary)
                    Text("ХК СИБИРЬ · FanZone")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(2)
                    Spacer()
                    Text(ticket.isUsed ? "ИСПОЛЬЗОВАН" : "ДЕЙСТВИТЕЛЕН")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(ticket.isUsed ? AppTheme.error : AppTheme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((ticket.isUsed ? AppTheme.error : AppTheme.success).opacity(0.15))
                        .clipShape(Capsule())
                }

                // User info
                HStack(spacing: 14) {
                    if let urlStr = ticket.avatarUrl, let url = URL(string: urlStr) {
                        AvatarURLView(url: url, size: 64, initials: "?")
                    } else if let profile = booking.user?.profile {
                        AvatarURLView(url: nil, size: 64, initials: profile.initials)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ticket.userFullName ?? booking.user?.displayName ?? "Болельщик")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        Text("@\(booking.user?.username ?? "")")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }

                Divider()
                    .background(AppTheme.surfaceElevated)
                    .padding(.vertical, 4)

                // Match info
                VStack(spacing: 10) {
                    Text(ticket.matchTitle ?? booking.match.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("ДАТА")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(1)
                            Text((ticket.scheduledAt ?? booking.match.scheduledAt).ruShortDateString)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 2) {
                            Text("ВРЕМЯ")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(1)
                            Text((ticket.scheduledAt ?? booking.match.scheduledAt).ruTimeString)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 2) {
                            Text("СЕКТОР")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(1)
                            Text(ticket.sectorName ?? booking.sectorName ?? "ФАН")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text(ticket.arenaName ?? booking.match.arena.name)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Divider().background(AppTheme.surfaceElevated).padding(.vertical, 4)

                // QR Code
                if let qrImage = generateQR(from: ticket.qrToken) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                }

                // Booking ID
                Text("ID: \(booking.shortId)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(20)
            .background(AppTheme.surface)

            // Bottom gradient band
            LinearGradient(
                colors: [AppTheme.brandSecondary.opacity(0.8), AppTheme.brandPrimary.opacity(0.8)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous))
        .shadow(color: AppTheme.brandPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    private func generateQR(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Ticket ViewModel

@MainActor
class TicketViewModel: ObservableObject {
    @Published var ticket: Ticket?
    @Published var isLoading = false
    private let booking: Booking

    init(booking: Booking) { self.booking = booking }

    func load() async {
        isLoading = true
        do {
            ticket = try await APIClient.shared.request(.getTicket(bookingId: booking.id))
        } catch {
            // If ticket not found, use basic info from booking
            ticket = booking.ticket
        }
        isLoading = false
    }
}
