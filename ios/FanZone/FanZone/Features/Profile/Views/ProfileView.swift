import SwiftUI
import PhotosUI

// MARK: - Profile ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var stats: UserStats?
    @Published var isLoading = false
    @Published var isUploadingAvatar = false
    @Published var errorMessage: String?
    @Published var showError = false

    func loadStats() async {
        isLoading = true
        do {
            stats = try await APIClient.shared.request(.getMyStats)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func uploadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingAvatar = true
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let _: UserProfile = try await APIClient.shared.request(.uploadAvatar(imageData: data))
            await AuthManager.shared.refreshCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isUploadingAvatar = false
    }

    func deleteAvatar() async {
        do {
            try await APIClient.shared.requestEmpty(.deleteAvatar)
            await AuthManager.shared.refreshCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Profile View

@MainActor
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var vm = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showEditProfile = false
    @State private var showSocialLinks = false
    @State private var showLogoutConfirm = false
    @State private var showAvatarOptions = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                    statsSection
                    socialSection
                    attendanceSection
                    settingsSection
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Изменить") { showEditProfile = true }
                    .foregroundColor(AppTheme.brandPrimary)
            }
        }
        .task { await vm.loadStats() }
        .photosPicker(isPresented: .constant(false), selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { item in
            Task { await vm.uploadAvatar(item) }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showSocialLinks) {
            SocialLinksView()
                .environmentObject(auth)
        }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage ?? "") }
        .confirmationDialog("Выйти из аккаунта?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Выйти", role: .destructive) {
                Task { await auth.logout() }
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    UserAvatarView(user: auth.currentUser, size: 100, showBorder: true)
                    if vm.isUploadingAvatar {
                        ProgressView().tint(.white)
                            .frame(width: 100, height: 100)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Circle()
                        .fill(AppTheme.brandPrimary)
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "camera.fill").font(.caption2).foregroundColor(.white))
                }
            }

            // Name / Username
            VStack(spacing: 4) {
                Text(auth.currentUser?.displayName ?? "Болельщик")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("@\(auth.currentUser?.username ?? "")")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                if let city = auth.currentUser?.profile?.city {
                    Label(city, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Role badge
            RoleBadge(role: auth.currentUser?.role ?? .user)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Статистика болельщика")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(emoji: "🏒", value: "\(vm.stats?.attendedMatches ?? 0)", label: "Посещено матчей", color: AppTheme.success)
                StatCard(emoji: "🎟", value: "\(vm.stats?.confirmedBookings ?? 0)", label: "Подтверждено", color: AppTheme.brandPrimary)
                StatCard(emoji: "📅", value: "\(vm.stats?.totalBookings ?? 0)", label: "Забронировано", color: AppTheme.brandSecondary)
                StatCard(emoji: "❌", value: "\(vm.stats?.cancelledBookings ?? 0)", label: "Отменено", color: AppTheme.neutral)
            }

            // Home/Away breakdown
            if let s = vm.stats, s.attendedMatches > 0 {
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("\(s.homeMatchesAttended)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(AppTheme.success)
                        Text("Домашних")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))

                    VStack(spacing: 4) {
                        Text("\(s.awayMatchesAttended)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(AppTheme.info)
                        Text("Выездных")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Social Links

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Социальные сети")
                Spacer()
                Button("Изменить") { showSocialLinks = true }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.brandPrimary)
            }

            if let links = auth.currentUser?.socialLinks, !links.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(links) { link in
                        Button {
                            if let url = URL(string: link.url) { UIApplication.shared.open(url) }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: link.socialPlatform.systemImage)
                                    .font(.title3)
                                    .foregroundColor(Color(hex: link.socialPlatform.hexColor))
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: link.socialPlatform.hexColor).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(link.socialPlatform.displayName)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            } else {
                Button {
                    showSocialLinks = true
                } label: {
                    Label("Добавить социальные сети", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.brandPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Attendance History

    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("История посещений")

            if let history = vm.stats?.recentAttendances, !history.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(history.prefix(5).enumerated()), id: \.offset) { idx, item in
                        attendanceRow(item: item)
                        if idx < min(4, history.count - 1) {
                            Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
                        }
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))

                if history.count > 5 {
                    NavigationLink("Показать всё") {
                        AttendanceHistoryView(history: history)
                    }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "Нет истории",
                    subtitle: "История посещений матчей появится здесь"
                )
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    private func attendanceRow(item: AttendanceHistoryItem) -> some View {
        HStack(spacing: 12) {
            Text(item.attendanceStatus.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.matchTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(item.scheduledAt.ruDayMonthYearString)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            if !item.isHome {
                Image(systemName: "airplane")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Настройки")

            VStack(spacing: 0) {
                NavigationLink {
                    EditProfileView().environmentObject(auth)
                } label: {
                    settingsRow(icon: "person.fill", title: "Редактировать профиль")
                }
                Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
                NavigationLink {
                    SocialLinksView().environmentObject(auth)
                } label: {
                    settingsRow(icon: "link", title: "Социальные сети")
                }
                Divider().background(AppTheme.surfaceElevated).padding(.horizontal, 16)
                settingsRow(icon: "arrow.right.square.fill", title: "Выйти из аккаунта", color: AppTheme.error) {
                    showLogoutConfirm = true
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundColor(.white)
    }

    private func settingsRow(icon: String, title: String, color: Color = AppTheme.textPrimary, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    settingsRowContent(icon: icon, title: title, color: color)
                }
            } else {
                settingsRowContent(icon: icon, title: title, color: color)
            }
        }
    }

    private func settingsRowContent(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
            Text(title)
                .font(.body)
                .foregroundColor(color == AppTheme.textPrimary ? .white : color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var city      = ""
    @State private var bio       = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FZTextField(placeholder: "Имя", text: $firstName, icon: "person")
                        FZTextField(placeholder: "Фамилия", text: $lastName, icon: "person")
                        FZTextField(placeholder: "Город", text: $city, icon: "location")
                        FZTextField(placeholder: "О себе", text: $bio, icon: "text.alignleft")
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .foregroundColor(AppTheme.brandPrimary)
                        .disabled(isLoading)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { prefill() }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
    }

    private func prefill() {
        firstName = auth.currentUser?.profile?.firstName ?? ""
        lastName  = auth.currentUser?.profile?.lastName  ?? ""
        city      = auth.currentUser?.profile?.city      ?? ""
        bio       = auth.currentUser?.profile?.bio       ?? ""
    }

    private func save() {
        isLoading = true
        Task {
            do {
                let _: UserProfile = try await APIClient.shared.request(
                    .updateProfile(firstName: firstName, lastName: lastName,
                                   city: city.isEmpty ? nil : city,
                                   bio:  bio.isEmpty  ? nil : bio)
                )
                await auth.refreshCurrentUser()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Social Links View

struct SocialLinksView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var links:     [SocialLink] = []
    @State private var isLoading  = false
    @State private var showAddForm = false
    @State private var newPlatform = SocialPlatform.telegram
    @State private var newURL      = ""
    @State private var newLabel    = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                List {
                    ForEach(links) { link in
                        HStack(spacing: 12) {
                            Image(systemName: link.socialPlatform.systemImage)
                                .foregroundColor(Color(hex: link.socialPlatform.hexColor))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(link.displayLabel)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                                Text(link.url)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                    .onDelete { offsets in
                        offsets.forEach { idx in
                            Task { await deleteLink(links[idx]) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Социальные сети")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Готово") { dismiss() }.foregroundColor(AppTheme.brandPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddForm = true } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppTheme.brandPrimary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await loadLinks() }
        .sheet(isPresented: $showAddForm) {
            addLinkSheet
        }
    }

    private var addLinkSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Picker("Платформа", selection: $newPlatform) {
                        ForEach(SocialPlatform.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.brandPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))

                    FZTextField(placeholder: "URL профиля", text: $newURL,
                                icon: "link", autocapitalization: .never)
                    FZTextField(placeholder: "Подпись (необязательно)", text: $newLabel,
                                icon: "text.quote")

                    FZPrimaryButton("Добавить") {
                        Task { await addLink() }
                    }
                    .disabled(newURL.isEmpty)
                    .opacity(newURL.isEmpty ? 0.5 : 1)
                }
                .padding(16)
            }
            .navigationTitle("Добавить ссылку")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { showAddForm = false }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func loadLinks() async {
        isLoading = true
        do {
            links = try await APIClient.shared.request(.getSocialLinks)
        } catch {}
        isLoading = false
    }

    private func addLink() async {
        do {
            let _: SocialLink = try await APIClient.shared.request(
                .addSocialLink(platform: newPlatform.rawValue, url: newURL,
                               label: newLabel.isEmpty ? nil : newLabel)
            )
            await loadLinks()
            await auth.refreshCurrentUser()
            showAddForm = false
            newURL = ""
            newLabel = ""
        } catch {}
    }

    private func deleteLink(_ link: SocialLink) async {
        do {
            try await APIClient.shared.requestEmpty(.deleteSocialLink(id: link.id))
            await loadLinks()
        } catch {}
    }
}

// MARK: - Attendance History View

struct AttendanceHistoryView: View {
    let history: [AttendanceHistoryItem]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            List(history) { item in
                HStack(spacing: 12) {
                    Text(item.attendanceStatus.emoji).font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.matchTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text(item.scheduledAt.ruDayMonthYearString)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            if !item.isHome {
                                Label("Выезд", systemImage: "airplane")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.brandSecondary)
                            }
                        }
                    }
                    Spacer()
                    BookingStatusBadge(status: item.bookingStatus)
                }
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.surfaceElevated)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("История посещений")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
