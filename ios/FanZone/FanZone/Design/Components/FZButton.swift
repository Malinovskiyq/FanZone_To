import SwiftUI

// MARK: - FZ Primary Button

struct FZPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title     = title
        self.isLoading = isLoading
        self.action    = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(isLoading ? AppTheme.brandPrimary.opacity(0.7) : AppTheme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - FZ Secondary Button

struct FZSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
        .background(AppTheme.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                .stroke(AppTheme.brandPrimary.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - FZ Destructive Button

struct FZDestructiveButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title     = title
        self.isLoading = isLoading
        self.action    = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.9)
                } else {
                    Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .background(isLoading ? AppTheme.error.opacity(0.6) : AppTheme.error)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
        .disabled(isLoading)
    }
}
