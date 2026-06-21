import SwiftUI

/// A compact bar mini-viz of a name's popularity trend over the sampled years.
/// Original drawn vector — no external chart library, no copyrighted data.
struct PopularityTrend: View {
    let values: [Int]
    var height: CGFloat = 44
    var tint: Color = .babbleAccent

    private var maxValue: Int { max(values.max() ?? 1, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                let frac = CGFloat(v) / CGFloat(maxValue)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(tint.opacity(0.30 + 0.55 * frac))
                    .frame(height: max(3, height * frac))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Popularity trend")
    }
}

/// A small pill describing a stat (origin, meaning length, syllables).
struct InfoPill: View {
    let systemImage: String
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage).font(.caption2.weight(.semibold))
            Text(text).font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.babbleCard2, in: Capsule())
    }
}

/// The big swipeable name card shown on the Swipe screen.
struct NameCard: View {
    let name: Name
    var saved: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label(name.gender.label, systemImage: name.gender.sfSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if saved {
                    Image(systemName: "heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.babbleAccent)
                }
            }

            Spacer(minLength: 4)

            Text(name.name)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(name.meaning)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            HStack(spacing: 8) {
                InfoPill(systemImage: "globe", text: name.origin)
                InfoPill(systemImage: "textformat.abc",
                         text: "\(name.syllableCount) syllable\(name.syllableCount == 1 ? "" : "s")")
            }

            Spacer(minLength: 4)

            VStack(spacing: 6) {
                HStack {
                    Text("Popularity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label(name.isRising ? "Rising" : "Classic",
                          systemImage: name.isRising ? "arrow.up.right" : "minus")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(name.isRising ? Color.babbleAccent : .secondary)
                }
                PopularityTrend(values: name.popularityByYear, height: 40)
                HStack {
                    Text("\(Name.trendYears.first ?? 1980)")
                    Spacer()
                    Text("\(Name.trendYears.last ?? 2020)")
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.babbleCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.babbleHair.opacity(0.5), lineWidth: 0.5)
        )
    }
}

/// A selectable chip used for gender/length/origin filters.
struct FilterChip: View {
    let label: String
    let selected: Bool
    var locked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label).font(.subheadline.weight(.semibold))
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(selected ? Color.babbleAccent : Color.babbleCard, in: Capsule())
            .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// Wraps UIActivityViewController so we can share a rendered shortlist card image.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
