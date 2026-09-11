import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthManager.shared

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if !auth.isAuthenticated {
                AuthRootView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                roleBasedView
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .environmentObject(auth)
    }

    @ViewBuilder
    private var roleBasedView: some View {
        switch auth.userRole {
        case .user:           UserTabView()
        case .bookingManager: ManagerTabView()
        case .admin:          AdminTabView()
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "hockey.puck.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.heroGradient)
                VStack(spacing: 6) {
                    Text("ХК СИБИРЬ")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(5)
                    Text("FanZone")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(2)
                }
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.brandPrimary)
                    .scaleEffect(1.2)
                    .padding(.top, 24)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    scale   = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - User Tab View

struct UserTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Главная", systemImage: "house.fill") }
            NavigationStack { MatchesView() }
                .tabItem { Label("Матчи", systemImage: "hockey.puck.fill") }
            NavigationStack { MyBookingsView() }
                .tabItem { Label("Брони", systemImage: "ticket.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(AppTheme.brandPrimary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Manager Tab View

struct ManagerTabView: View {
    var body: some View {
        TabView {
            NavigationStack { BookingRequestsView() }
                .tabItem { Label("Заявки", systemImage: "list.clipboard.fill") }
            NavigationStack { MatchesView() }
                .tabItem { Label("Матчи", systemImage: "hockey.puck.fill") }
            NavigationStack { MatchParticipantsView() }
                .tabItem { Label("Участники", systemImage: "person.3.fill") }
            NavigationStack { QRScannerScreenView() }
                .tabItem { Label("Сканер", systemImage: "qrcode.viewfinder") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(AppTheme.brandPrimary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Admin Tab View

struct AdminTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Главная", systemImage: "chart.bar.fill") }
            NavigationStack { AdminMatchesView() }
                .tabItem { Label("Матчи", systemImage: "hockey.puck.fill") }
            NavigationStack { BookingRequestsView() }
                .tabItem { Label("Заявки", systemImage: "list.clipboard.fill") }
            NavigationStack { AdminUsersView() }
                .tabItem { Label("Пользователи", systemImage: "person.2.fill") }
            NavigationStack { AdminStatsView() }
                .tabItem { Label("Статистика", systemImage: "chart.pie.fill") }
        }
        .tint(AppTheme.brandPrimary)
        .preferredColorScheme(.dark)
    }
}
