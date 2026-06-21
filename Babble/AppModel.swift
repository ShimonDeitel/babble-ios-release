import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store + the bundled name catalog, manages collections and the
/// save action, and enforces the free/Pro split (free users get exactly one collection).
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    let library: NameLibrary
    weak var store: Store?

    @Published private(set) var collections: [NameCollection] = []
    @Published private(set) var savedNamesSet: Set<String> = []

    /// Free users may keep this many collections; Pro unlocks unlimited.
    static let freeCollectionLimit = 1

    /// Per-launch deck seed so the swipe order is reproducible within a session.
    let deckSeed: UInt64

    init(container: ModelContainer, library: NameLibrary = NameLibrary()) {
        self.container = container
        self.library = library
        self.deckSeed = UInt64(Date().timeIntervalSince1970)
        ensureDefaultCollection()
        refresh()
    }

    // MARK: Container (local-only on-device persistence)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([NameCollection.self, SavedName.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Collections

    /// First-run: make sure there is always at least one collection ("Favorites").
    private func ensureDefaultCollection() {
        let ctx = container.mainContext
        let existing = (try? ctx.fetch(FetchDescriptor<NameCollection>())) ?? []
        if existing.isEmpty {
            ctx.insert(NameCollection(title: "Favorites", symbol: "heart.fill"))
            try? ctx.save()
        }
    }

    func refresh() {
        let ctx = container.mainContext
        let all = (try? ctx.fetch(FetchDescriptor<NameCollection>())) ?? []
        collections = all.sorted { $0.createdAt < $1.createdAt }
        let saved = (try? ctx.fetch(FetchDescriptor<SavedName>())) ?? []
        savedNamesSet = Set(saved.map(\.name))
    }

    /// Free users are capped at one collection; only Pro may create more.
    var canCreateCollection: Bool {
        (store?.isPro ?? false) || collections.count < Self.freeCollectionLimit
    }

    var primaryCollection: NameCollection? {
        collections.first
    }

    @discardableResult
    func createCollection(title: String, symbol: String = "heart.fill") -> NameCollection? {
        guard canCreateCollection else { return nil }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let ctx = container.mainContext
        let c = NameCollection(title: trimmed.isEmpty ? "Untitled" : trimmed, symbol: symbol)
        ctx.insert(c)
        try? ctx.save()
        refresh()
        return c
    }

    func renameCollection(_ collection: NameCollection, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        collection.title = trimmed
        try? container.mainContext.save()
        refresh()
    }

    func deleteCollection(_ collection: NameCollection) {
        let ctx = container.mainContext
        ctx.delete(collection)
        try? ctx.save()
        ensureDefaultCollection()
        refresh()
    }

    /// Pick the collection that best matches a name's gender (Boys/Girls/Unisex), falling back to
    /// the first/primary collection. Free users always save into their single collection.
    func defaultCollection(for name: Name) -> NameCollection? {
        if store?.isPro == true {
            if let match = collections.first(where: { $0.title.caseInsensitiveCompare(name.gender.label) == .orderedSame }) {
                return match
            }
        }
        return primaryCollection
    }

    // MARK: Saving names

    func isSaved(_ name: Name) -> Bool { savedNamesSet.contains(name.name) }

    /// Saves a name into a collection (deduped by name within that collection). Returns false if the
    /// name was already present.
    @discardableResult
    func save(_ name: Name, to collection: NameCollection?) -> Bool {
        guard let collection else { return false }
        let already = (collection.names ?? []).contains { $0.name == name.name }
        guard !already else { return false }
        let ctx = container.mainContext
        let saved = SavedName(from: name, collection: collection)
        ctx.insert(saved)
        if collection.names == nil { collection.names = [] }
        collection.names?.append(saved)
        try? ctx.save()
        refresh()
        return true
    }

    func remove(_ saved: SavedName) {
        let ctx = container.mainContext
        ctx.delete(saved)
        try? ctx.save()
        refresh()
    }

    /// Removes a catalog name from every collection it appears in (used by the detail toggle).
    func unsaveEverywhere(_ name: Name) {
        let ctx = container.mainContext
        let matches = (try? ctx.fetch(FetchDescriptor<SavedName>(
            predicate: #Predicate { $0.name == name.name }))) ?? []
        matches.forEach { ctx.delete($0) }
        try? ctx.save()
        refresh()
    }

    // MARK: Account deletion

    /// Erase all on-device data (used by Delete Account).
    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: SavedName.self)
        try? ctx.delete(model: NameCollection.self)
        try? ctx.save()
        ensureDefaultCollection()
        refresh()
    }
}
