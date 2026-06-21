import Foundation
import SwiftData

/// A user-made collection of saved names (e.g. "Boys", "Girls", "Unisex", or a custom shortlist).
/// All properties default and the relationship is optional, so the schema mirrors to CloudKit cleanly.
@Model
final class NameCollection {
    var id: UUID = UUID()
    var title: String = "Favorites"
    var createdAt: Date = Date.now
    /// SF Symbol shown next to the collection.
    var symbol: String = "heart.fill"

    @Relationship(deleteRule: .cascade, inverse: \SavedName.collection)
    var names: [SavedName]? = []

    init(id: UUID = UUID(), title: String = "Favorites",
         createdAt: Date = .now, symbol: String = "heart.fill") {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.symbol = symbol
    }

    /// Live count, resilient to a nil relationship array (CloudKit-mirrored optional).
    var count: Int { names?.count ?? 0 }

    /// Saved names newest-first.
    var sortedNames: [SavedName] {
        (names ?? []).sorted { $0.savedAt > $1.savedAt }
    }
}

/// A single name a user saved into a collection. Stores a snapshot of the catalog fields so the
/// shortlist still renders even if the bundled catalog changes in a future version.
@Model
final class SavedName {
    var id: UUID = UUID()
    var name: String = ""
    var gender: String = "unisex"
    var origin: String = ""
    var meaning: String = ""
    var savedAt: Date = Date.now
    var collection: NameCollection?

    init(id: UUID = UUID(), name: String = "", gender: String = "unisex",
         origin: String = "", meaning: String = "", savedAt: Date = .now,
         collection: NameCollection? = nil) {
        self.id = id
        self.name = name
        self.gender = gender
        self.origin = origin
        self.meaning = meaning
        self.savedAt = savedAt
        self.collection = collection
    }

    convenience init(from catalog: Name, collection: NameCollection?) {
        self.init(name: catalog.name, gender: catalog.gender.rawValue,
                  origin: catalog.origin, meaning: catalog.meaning,
                  savedAt: .now, collection: collection)
    }

    var genderValue: Gender { Gender(rawValue: gender) ?? .unisex }
}
