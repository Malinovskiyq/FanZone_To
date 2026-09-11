import SwiftUI

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var color: Color = AppTheme.surface
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, color: Color = AppTheme.surface) -> some View {
        modifier(CardModifier(padding: padding, color: color))
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppTheme.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.brandPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .stroke(AppTheme.brandPrimary.opacity(0.5), lineWidth: 1)
            )
    }

    func destructiveButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.error)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
