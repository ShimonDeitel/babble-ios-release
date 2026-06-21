import SwiftUI

/// The core experience: a deck of name cards. Swipe right (or tap the heart) to save into a
/// collection, swipe left to skip. Pro unlocks filters by gender, origin and length.
struct SwipeView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var detail: Name?
    @State private var savedToast: String?

    // Filter state (gender chips are free; origin + length are Pro).
    @State private var genders: Set<Gender> = []
    @State private var origin: String? = nil
    @State private var length: NameLength = .any

    private var deck: [Name] {
        let filtered = NameLibrary.filter(appModel.library.all,
                                          genders: genders,
                                          origin: store.isPro ? origin : nil,
                                          length: store.isPro ? length : .any)
        return NameLibrary.deck(filtered, seed: appModel.deckSeed)
    }

    private var current: Name? { index < deck.count ? deck[index] : nil }
    private var next: Name? { index + 1 < deck.count ? deck[index + 1] : nil }

    var body: some View {
        NavigationStack {
            ZStack {
                BabbleBackground()
                VStack(spacing: 0) {
                    genderBar
                    Spacer(minLength: 8)
                    cardStack
                    Spacer(minLength: 8)
                    actionRow
                        .padding(.bottom, 6)
                }
                .padding(.horizontal, 20)

                if let savedToast {
                    toast(savedToast)
                }
            }
            .navigationTitle("Babble")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { Haptics.tap(); openFilters() } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityIdentifier("open-filters")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("open-settings")
                }
            }
            .tint(Color.babbleAccent)
            .sheet(isPresented: $showFilters) {
                FiltersView(genders: $genders, origin: $origin, length: $length,
                            origins: appModel.library.origins())
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $detail) { name in
                NavigationStack { NameDetailView(name: name) }
            }
            .onChange(of: genders) { _, _ in resetDeck() }
            .onChange(of: origin) { _, _ in resetDeck() }
            .onChange(of: length) { _, _ in resetDeck() }
            .onAppear { appModel.refresh() }
        }
    }

    // MARK: Pieces

    private var genderBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", selected: genders.isEmpty) {
                    Haptics.tap(); genders = []
                }
                ForEach(Gender.allCases) { g in
                    FilterChip(label: g.label, selected: genders.contains(g)) {
                        Haptics.tap()
                        if genders.contains(g) { genders.remove(g) } else { genders.insert(g) }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var cardStack: some View {
        ZStack {
            if let next {
                NameCard(name: next, saved: appModel.isSaved(next))
                    .scaleEffect(0.94)
                    .opacity(0.6)
                    .offset(y: 14)
            }
            if let current {
                NameCard(name: current, saved: appModel.isSaved(current))
                    .offset(x: drag.width, y: drag.height * 0.25)
                    .rotationEffect(.degrees(Double(drag.width / 18)))
                    .overlay(swipeBadge)
                    .gesture(dragGesture)
                    .onTapGesture { Haptics.tap(); detail = current }
                    .accessibilityIdentifier("name-card")
                    .transition(.scale.combined(with: .opacity))
            } else {
                emptyState
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
    }

    private var swipeBadge: some View {
        ZStack {
            if drag.width > 40 {
                badge(text: "SAVE", color: .babbleAccent, system: "heart.fill")
                    .opacity(Double(min(1, (drag.width - 40) / 80)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
            } else if drag.width < -40 {
                badge(text: "SKIP", color: .secondary, system: "arrow.left")
                    .opacity(Double(min(1, (-drag.width - 40) / 80)))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 24)
        .allowsHitTesting(false)
    }

    private func badge(text: String, color: Color, system: String) -> some View {
        Label(text, systemImage: system)
            .font(.headline.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.babbleCard, in: Capsule())
            .overlay(Capsule().strokeBorder(color, lineWidth: 2))
    }

    private var actionRow: some View {
        HStack(spacing: 28) {
            roundButton(system: "arrow.left", tint: .secondary,
                        id: "skip-button") { advance(saving: false) }
            roundButton(system: "info.circle", tint: Color.babbleAccent,
                        id: "info-button", small: true) {
                if let current { detail = current }
            }
            roundButton(system: "heart.fill", tint: Color.babbleAccent,
                        id: "save-button") { advance(saving: true) }
        }
        .disabled(current == nil)
        .opacity(current == nil ? 0.4 : 1)
    }

    private func roundButton(system: String, tint: Color, id: String,
                             small: Bool = false, action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Image(systemName: system)
                .font(.system(size: small ? 22 : 28, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: small ? 52 : 66, height: small ? 52 : 66)
                .background(Color.babbleCard, in: Circle())
                .overlay(Circle().strokeBorder(Color.babbleHair.opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.babbleAccent)
            Text("That's every name")
                .font(.title3.weight(.bold))
            Text("You've been through the whole list. Start over to see them again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Start over") { Haptics.tap(); resetDeck() }
                .softButton()
        }
        .padding(28)
        .babbleCard(cornerRadius: 28)
    }

    private func toast(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.babbleAccent, in: Capsule())
                .padding(.bottom, 96)
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: Gestures / actions

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width > 110 {
                    advance(saving: true)
                } else if value.translation.width < -110 {
                    advance(saving: false)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func advance(saving: Bool) {
        guard let name = current else { return }
        if saving {
            let collection = appModel.defaultCollection(for: name)
            let didSave = appModel.save(name, to: collection)
            Haptics.swipe(saved: true)
            if didSave { flashToast("Saved to \(collection?.title ?? "collection")") }
        } else {
            Haptics.swipe(saved: false)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            drag = .zero
            index += 1
        }
    }

    private func flashToast(_ text: String) {
        withAnimation { savedToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation { if savedToast == text { savedToast = nil } }
        }
    }

    private func openFilters() {
        // Gender chips are free; the full filter sheet's origin/length are Pro.
        showFilters = true
    }

    private func resetDeck() {
        withAnimation { index = 0; drag = .zero }
    }
}

/// The filter sheet. Gender is free; origin + length are Pro and gated behind the paywall.
struct FiltersView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @Binding var genders: Set<Gender>
    @Binding var origin: String?
    @Binding var length: NameLength
    let origins: [String]

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Gender") {
                    ForEach(Gender.allCases) { g in
                        Toggle(g.label, isOn: Binding(
                            get: { genders.contains(g) },
                            set: { on in
                                if on { genders.insert(g) } else { genders.remove(g) }
                            }))
                    }
                }

                Section {
                    if store.isPro {
                        Picker("Origin", selection: Binding(
                            get: { origin ?? "Any" },
                            set: { origin = $0 == "Any" ? nil : $0 })) {
                            Text("Any").tag("Any")
                            ForEach(origins, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Length", selection: $length) {
                            ForEach(NameLength.allCases) { Text($0.label).tag($0) }
                        }
                    } else {
                        Button {
                            Haptics.tap(); showPaywall = true
                        } label: {
                            HStack {
                                Label("Filter by origin & length", systemImage: "lock.fill")
                                Spacer()
                                Text("Pro").foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Refine")
                } footer: {
                    if !store.isPro {
                        Text("Unlock Babble Pro to filter by origin and name length.")
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .tint(Color.babbleAccent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}
