import XCTest
import SwiftData
@testable import Babble

/// Integration tests for the live data layer: collection creation/gating, saving names, dedupe,
/// and account-deletion wipe — all on an in-memory SwiftData store.
@MainActor
final class BabbleLogicTests: XCTestCase {

    private func memoryModel() -> ModelContainer {
        try! ModelContainer(for: NameCollection.self, SavedName.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func sampleName(_ name: String = "Liam", gender: Gender = .boy) -> Name {
        Name(name: name, gender: gender, origin: "Irish",
             meaning: "Strong-willed protector", popularityByYear: [10, 40, 90])
    }

    func testFreshModelHasOneDefaultCollection() {
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        XCTAssertEqual(model.collections.count, 1)
        XCTAssertEqual(model.primaryCollection?.title, "Favorites")
    }

    func testFreeUserCannotCreateSecondCollection() {
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        // No store attached, so not Pro.
        XCTAssertFalse(model.canCreateCollection, "one default already exists; free cap is 1")
        let created = model.createCollection(title: "Boys")
        XCTAssertNil(created, "free users cannot add a second collection")
        XCTAssertEqual(model.collections.count, 1)
    }

    func testProUserCanCreateUnlimitedCollections() {
        let store = Store()
        store.setProForTesting(true)
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        model.store = store

        XCTAssertTrue(model.canCreateCollection)
        XCTAssertNotNil(model.createCollection(title: "Boys"))
        XCTAssertNotNil(model.createCollection(title: "Girls"))
        XCTAssertEqual(model.collections.count, 3)
    }

    func testSaveAndDedupe() {
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        let liam = sampleName()
        let collection = model.primaryCollection

        XCTAssertFalse(model.isSaved(liam))
        XCTAssertTrue(model.save(liam, to: collection), "first save succeeds")
        XCTAssertTrue(model.isSaved(liam))
        XCTAssertEqual(model.primaryCollection?.count, 1)

        XCTAssertFalse(model.save(liam, to: collection), "duplicate save is rejected")
        XCTAssertEqual(model.primaryCollection?.count, 1)
    }

    func testUnsaveEverywhere() {
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        let liam = sampleName()
        model.save(liam, to: model.primaryCollection)
        XCTAssertTrue(model.isSaved(liam))

        model.unsaveEverywhere(liam)
        XCTAssertFalse(model.isSaved(liam))
        XCTAssertEqual(model.primaryCollection?.count, 0)
    }

    func testDeleteAllDataResetsToOneEmptyCollection() {
        let store = Store()
        store.setProForTesting(true)
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        model.store = store
        model.createCollection(title: "Boys")
        model.save(sampleName(), to: model.primaryCollection)
        XCTAssertGreaterThan(model.collections.count, 1)

        model.deleteAllData()
        XCTAssertEqual(model.collections.count, 1)
        XCTAssertEqual(model.primaryCollection?.count, 0)
        XCTAssertTrue(model.savedNamesSet.isEmpty)
    }

    func testProDefaultCollectionMatchesGender() {
        let store = Store()
        store.setProForTesting(true)
        let model = AppModel(container: memoryModel(), library: NameLibrary(names: []))
        model.store = store
        // Rename the default to "Boys" so a boy name routes there for a Pro user.
        if let primary = model.primaryCollection {
            model.renameCollection(primary, to: "Boys")
        }
        let target = model.defaultCollection(for: sampleName("Noah", gender: .boy))
        XCTAssertEqual(target?.title, "Boys")
    }
}
