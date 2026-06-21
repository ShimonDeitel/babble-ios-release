import SwiftUI
import UIKit

// MARK: - Minimalist, Apple-native color system
// Flat surfaces, system semantic colors (so Light AND Dark both look right),
// a single Apple-blue accent. No gradients.

extension Color {
    static let babbleAccent = Color(hex: "#007AFF")          // the single accent
    static let babbleCard = Color(uiColor: .secondarySystemBackground)
    static let babbleCard2 = Color(uiColor: .tertiarySystemBackground)
    static let babbleField = Color(uiColor: .tertiarySystemFill)
    static let babbleHair = Color(uiColor: .separator)
}

// MARK: - Flat surfaces (cards / pills / buttons)

extension View {
    func babbleCard(cornerRadius: CGFloat = 20) -> some View {
        self.padding(16)
            .background(Color.babbleCard, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func babblePill() -> some View {
        self.padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.babbleCard, in: Capsule())
    }

    /// Primary action — a clean, flat Apple-blue filled capsule.
    func prominentButton() -> some View { self.buttonStyle(FilledAccentButtonStyle()) }
    /// Secondary action — flat tinted capsule.
    func softButton() -> some View { self.buttonStyle(SoftButtonStyle()) }
}

struct FilledAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 22)
            .background(Color.babbleAccent, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.medium))
            .foregroundStyle(Color.babbleAccent)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(Color.babbleCard, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Background (flat, adapts to light/dark)

struct BabbleBackground: View {
    var body: some View { Color(uiColor: .systemBackground).ignoresSafeArea() }
}

// MARK: - Haptics

enum Haptics {
    /// Respects the user's "Haptics" toggle (defaults to on when unset).
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "babble.haptics") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// A directional cue when a name card is swiped.
    static func swipe(saved: Bool) {
        guard enabled else { return }
        if saved {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        }
    }
}

// MARK: - Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
