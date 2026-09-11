import os

files = {
    "FanZone/Features/Home/Views/HomeView.swift": """import SwiftUI
struct HomeView: View {
    var body: some View {
        Text("Home View")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
    }
}""",
    "FanZone/Features/Matches/Views/MatchesView.swift": """import SwiftUI
struct MatchesView: View {
    var body: some View {
        Text("Matches View")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
    }
}""",
    "FanZone/Features/Matches/Views/MatchDetailView.swift": """import SwiftUI
struct MatchDetailView: View {
    var body: some View {
        Text("Match Detail")
            .foregroundColor(.white)
    }
}""",
    "FanZone/Features/Profile/Views/ProfileView.swift": """import SwiftUI
struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile View")
                .foregroundColor(.white)
            Button("Logout") {
                Task { await AuthManager.shared.logout() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}""",
    "FanZone/Features/Bookings/Views/MyBookingsView.swift": """import SwiftUI
struct MyBookingsView: View {
    var body: some View {
        Text("My Bookings View")
            .foregroundColor(.white)
    }
}""",
    "FanZone/Features/Bookings/Views/TicketView.swift": """import SwiftUI
struct TicketView: View {
    var body: some View {
        Text("Ticket View")
            .foregroundColor(.white)
    }
}"""
}

def create_files():
    base_dir = r"E:\prilox\ios\FanZone"
    os.makedirs(base_dir, exist_ok=True)
    for path_str, content in files.items():
        full_path = os.path.join(base_dir, path_str.replace('/', os.sep))
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content)

if __name__ == "__main__":
    create_files()
    print("Additional files created successfully.")
