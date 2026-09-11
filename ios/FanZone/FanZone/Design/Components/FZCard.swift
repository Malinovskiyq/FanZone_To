import SwiftUI

// MARK: - Stat Card

struct StatCard: View {
    let emoji: String
    let value: String
    let label: String
    var color: Color = AppTheme.brandPrimary

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.title2)
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }
}

// MARK: - FZ Text Field

struct FZTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var isSecureVisible = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 20)
            }

            if isSecure && !isSecureVisible {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }

            if isSecure {
                Button(action: { isSecureVisible.toggle() }) {
                    Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                .stroke(AppTheme.surfaceElevated, lineWidth: 1)
        )
    }
}

// MARK: - FZ Card

struct FZCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var color: Color = AppTheme.surface

    init(padding: CGFloat = 16, color: Color = AppTheme.surface, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.color   = color
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    init(_ message: String = "Загрузка...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.brandPrimary)
                    .scaleEffect(1.4)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(28)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(AppTheme.textTertiary)
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.brandPrimary)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
