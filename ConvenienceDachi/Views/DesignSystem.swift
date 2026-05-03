import SwiftUI

extension Color {
    static let brandNavy = Color(red: 0.07, green: 0.14, blue: 0.25)
    static let brandGreen = Color(red: 0.20, green: 0.73, blue: 0.55)
    static let softGreen = Color(red: 0.88, green: 0.97, blue: 0.93)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.15)
    static let mutedInk = Color(red: 0.42, green: 0.46, blue: 0.48)
    static let warmSurface = Color(red: 0.97, green: 0.97, blue: 0.95)
    static let softBlue = Color(red: 0.90, green: 0.95, blue: 0.98)
    static let gentleOrange = Color(red: 0.92, green: 0.58, blue: 0.33)
}

struct MetricCard: View {
    let title: String
    let value: String
    var footnote: String?
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.mutedInk)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Color.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}

struct NumberUnitText: View {
    let number: String
    let unit: String
    var numberSize: Font = .system(.largeTitle, design: .rounded).weight(.heavy)

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(number)
                .font(numberSize)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(unit)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.mutedInk)
        }
    }
}

struct StreakBadge: View {
    let days: Int

    var body: some View {
        Label("\(days)日連続", systemImage: "flame.fill")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.brandNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.softBlue)
            .clipShape(Capsule())
    }
}

struct BannerAdPlaceholder: View {
    var body: some View {
        Text("広告バナー")
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.mutedInk)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("広告バナー枠")
    }
}

struct InterstitialAdPlaceholder: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Text("広告")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.mutedInk)
                Text("広告を表示しています")
                    .font(.headline)
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button("閉じる") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .padding(18)
        .background(Color.warmSurface.ignoresSafeArea())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(Color.brandNavy.opacity(configuration.isPressed ? 0.82 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.brandNavy.opacity(0.18), radius: 12, y: 6)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(configuration.isPressed ? 0.72 : 1))
            .foregroundStyle(Color.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
