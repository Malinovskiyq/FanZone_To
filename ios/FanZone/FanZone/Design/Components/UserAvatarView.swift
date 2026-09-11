import SwiftUI

struct UserAvatarView: View {
    let user: User?
    let size: CGFloat
    var showBorder: Bool = false

    init(user: User?, size: CGFloat = 40, showBorder: Bool = false) {
        self.user       = user
        self.size       = size
        self.showBorder = showBorder
    }

    var body: some View {
        Group {
            if let url = user?.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure, .empty:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            showBorder
            ? Circle().stroke(AppTheme.brandPrimary, lineWidth: 2)
            : nil
        )
    }

    private var initialsView: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.brandPrimary, AppTheme.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        user?.profile?.initials ?? user?.username.prefix(2).uppercased().description ?? "?"
    }
}

// MARK: - Avatar URL View (for ticket)

struct AvatarURLView: View {
    let url: URL?
    let size: CGFloat
    let initials: String

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.brandPrimary, lineWidth: 2))
    }

    private var initialsView: some View {
        ZStack {
            AppTheme.surface
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
