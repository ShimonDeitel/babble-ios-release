import SwiftUI

/// Full detail for a single name: origin, meaning, syllables, and a larger popularity trend with
/// year axis. A save toggle adds/removes the name from the default collection.
struct NameDetailView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let name: Name

    private var saved: Bool { appModel.isSaved(name) }

    var body: some View {
        ZStack {
            BabbleBackground()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    factsCard
                    trendCard
                    saveButton
                }
                .padding(20)
            }
        }
        .navigationTitle(name.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .tint(Color.babbleAccent)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(name.name)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Label(name.gender.label, systemImage: name.gender.sfSymbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var factsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            fact(title: "Meaning", value: name.meaning, system: "text.quote")
            Divider()
            fact(title: "Origin", value: name.origin, system: "globe")
            Divider()
            fact(title: "Syllables",
                 value: "\(name.syllableCount)",
                 system: "textformat.abc")
        }
        .babbleCard()
    }

    private func fact(title: String, value: String, system: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: system)
                .font(.headline)
                .foregroundStyle(Color.babbleAccent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(value).font(.body)
            }
            Spacer(minLength: 0)
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Popularity trend").font(.headline)
                Spacer()
                Label(name.isRising ? "Rising" : "Classic",
                      systemImage: name.isRising ? "arrow.up.right" : "minus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(name.isRising ? Color.babbleAccent : .secondary)
            }
            PopularityTrend(values: name.popularityByYear, height: 84)
            HStack {
                ForEach(Name.trendYears.indices, id: \.self) { i in
                    if i == 0 || i == Name.trendYears.count - 1 || i == Name.trendYears.count / 2 {
                        Text("\(Name.trendYears[i])")
                        if i != Name.trendYears.count - 1 { Spacer() }
                    }
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            Text("Relative interest across the years. A rising bar on the right means the name is more popular now.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .babbleCard()
    }

    private var saveButton: some View {
        Button {
            Haptics.tap()
            if saved {
                appModel.unsaveEverywhere(name)
            } else {
                appModel.save(name, to: appModel.defaultCollection(for: name))
                Haptics.swipe(saved: true)
            }
        } label: {
            Label(saved ? "Saved" : "Save name",
                  systemImage: saved ? "heart.fill" : "heart")
                .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .prominentButton()
        .accessibilityIdentifier("detail-save")
    }
}
