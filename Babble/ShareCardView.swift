import SwiftUI

/// The shareable family shortlist card. Fixed colors (not theme-dependent) so the exported image is
/// consistent, with a subtle "Babble" wordmark + App Store CTA for organic growth.
struct ShortlistCard: View {
    let title: String
    let names: [String]

    /// Up to 12 names render on the card to keep it readable.
    private var shown: [String] { Array(names.prefix(12)) }

    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("Our shortlist")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(white: 0.5))
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    ForEach(shown, id: \.self) { name in
                        Text(name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.babbleAccent)
                    }
                    if names.count > shown.count {
                        Text("+\(names.count - shown.count) more")
                            .font(.footnote)
                            .foregroundStyle(Color(white: 0.55))
                    }
                }

                Spacer(minLength: 4)

                Text("Babble")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.babbleAccent)
                Text("Find the perfect name - on the App Store")
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.55))
            }
            .padding(34)
        }
        .frame(width: 360, height: 480)
    }

    @MainActor func render() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        return renderer.uiImage
    }
}
