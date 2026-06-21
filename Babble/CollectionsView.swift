import SwiftUI

/// The Collections screen. Free users keep one collection; Pro unlocks unlimited collections plus
/// partner sharing of a shortlist card.
struct CollectionsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showNewSheet = false
    @State private var showPaywall = false
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BabbleBackground()
                if appModel.collections.allSatisfy({ $0.count == 0 }) && appModel.collections.count <= 1 {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        if appModel.canCreateCollection { showNewSheet = true }
                        else { showPaywall = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("new-collection")
                }
            }
            .tint(Color.babbleAccent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("New collection", isPresented: $showNewSheet) {
                TextField("Name", text: $newTitle)
                Button("Create") {
                    appModel.createCollection(title: newTitle)
                    newTitle = ""
                }
                Button("Cancel", role: .cancel) { newTitle = "" }
            } message: {
                Text("Give your shortlist a name, like \"Top picks\".")
            }
            .onAppear { appModel.refresh() }
        }
    }

    private var list: some View {
        List {
            ForEach(appModel.collections) { collection in
                NavigationLink {
                    CollectionDetailView(collection: collection)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: collection.symbol)
                            .font(.headline)
                            .foregroundStyle(Color.babbleAccent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collection.title).font(.body.weight(.semibold))
                            Text("\(collection.count) name\(collection.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete(perform: deleteCollections)

            if !store.isPro {
                Section {
                    Button {
                        Haptics.tap(); showPaywall = true
                    } label: {
                        HStack {
                            Label("More collections & partner share", systemImage: "lock.fill")
                            Spacer()
                            Text("Pro").foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Free includes one collection. Babble Pro unlocks unlimited collections, origin and length filters, and partner sharing.")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(Color.babbleAccent)
            Text("No saved names yet")
                .font(.title3.weight(.bold))
            Text("Swipe right on a name in Discover to save it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func deleteCollections(at offsets: IndexSet) {
        // Never delete the user's last remaining collection.
        for i in offsets {
            let c = appModel.collections[i]
            if appModel.collections.count > 1 { appModel.deleteCollection(c) }
        }
    }
}

/// A single collection's saved names, with the share-shortlist action (Pro).
struct CollectionDetailView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Bindable var collection: NameCollection

    @State private var shareImage: UIImage?
    @State private var showShare = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            BabbleBackground()
            if collection.count == 0 {
                empty
            } else {
                List {
                    ForEach(collection.sortedNames) { saved in
                        HStack(spacing: 12) {
                            Text(saved.name).font(.body.weight(.semibold))
                            Spacer()
                            Text(saved.origin).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { idx in
                        let items = collection.sortedNames
                        idx.map { items[$0] }.forEach(appModel.remove)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    if store.isPro { share() } else { showPaywall = true }
                } label: {
                    Image(systemName: store.isPro ? "square.and.arrow.up" : "lock.fill")
                }
                .disabled(collection.count == 0)
                .accessibilityIdentifier("share-shortlist")
            }
        }
        .tint(Color.babbleAccent)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showShare) {
            if let shareImage { ShareSheet(items: [shareImage]) }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No names here yet")
                .font(.headline)
            Text("Swipe right on names in Discover to add them.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    private func share() {
        let card = ShortlistCard(title: collection.title,
                                 names: collection.sortedNames.map(\.name))
        if let img = card.render() {
            shareImage = img
            showShare = true
        }
    }
}
