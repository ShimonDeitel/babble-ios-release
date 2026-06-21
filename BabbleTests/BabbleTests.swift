import XCTest
@testable import Babble

/// Pure-logic tests: syllable counting, filtering, deck shuffling, name-length matching,
/// and the bundled catalog's integrity.
final class BabbleTests: XCTestCase {

    // MARK: Syllable counting

    func testSyllableCounting() {
        XCTAssertEqual(Name.syllables(in: "Liam"), 2)
        XCTAssertEqual(Name.syllables(in: "Mia"), 2)
        XCTAssertEqual(Name.syllables(in: "Grace"), 1)   // silent trailing e
        XCTAssertEqual(Name.syllables(in: "Claire"), 1)  // silent trailing e
        XCTAssertEqual(Name.syllables(in: "Olivia"), 4)
        XCTAssertEqual(Name.syllables(in: "Theodore"), 3)
        XCTAssertEqual(Name.syllables(in: "Jack"), 1)
        XCTAssertGreaterThanOrEqual(Name.syllables(in: ""), 1) // never zero
    }

    // MARK: NameLength matching

    func testNameLengthMatching() {
        let jack = Name(name: "Jack", gender: .boy, origin: "English",
                        meaning: "x", popularityByYear: [1])
        let mia = Name(name: "Mia", gender: .girl, origin: "Italian",
                       meaning: "x", popularityByYear: [1])
        let olivia = Name(name: "Olivia", gender: .girl, origin: "Latin",
                          meaning: "x", popularityByYear: [1])

        XCTAssertTrue(NameLength.short.matches(jack))
        XCTAssertFalse(NameLength.short.matches(mia))
        XCTAssertTrue(NameLength.medium.matches(mia))
        XCTAssertTrue(NameLength.long.matches(olivia))
        XCTAssertTrue(NameLength.any.matches(jack))
        XCTAssertTrue(NameLength.any.matches(olivia))
    }

    // MARK: Filtering

    private func sample() -> [Name] {
        [
            Name(name: "Liam", gender: .boy, origin: "Irish", meaning: "x", popularityByYear: [10, 90]),
            Name(name: "Olivia", gender: .girl, origin: "Latin", meaning: "x", popularityByYear: [90, 10]),
            Name(name: "Rowan", gender: .unisex, origin: "Irish", meaning: "x", popularityByYear: [10, 10]),
            Name(name: "Mia", gender: .girl, origin: "Italian", meaning: "x", popularityByYear: [50, 50])
        ]
    }

    func testFilterByGender() {
        let girls = NameLibrary.filter(sample(), genders: [.girl], origin: nil, length: .any)
        XCTAssertEqual(Set(girls.map(\.name)), ["Olivia", "Mia"])
    }

    func testFilterByOriginAndLength() {
        let irish = NameLibrary.filter(sample(), genders: [], origin: "Irish", length: .any)
        XCTAssertEqual(Set(irish.map(\.name)), ["Liam", "Rowan"])

        let twoSyllableIrish = NameLibrary.filter(sample(), genders: [], origin: "Irish", length: .medium)
        XCTAssertEqual(Set(twoSyllableIrish.map(\.name)), ["Liam", "Rowan"])
    }

    func testFilterEmptyGenderSetReturnsAll() {
        let all = NameLibrary.filter(sample(), genders: [], origin: nil, length: .any)
        XCTAssertEqual(all.count, 4)
    }

    // MARK: Deck shuffle

    func testDeckIsDeterministicForASeedAndPreservesContents() {
        let names = sample()
        let a = NameLibrary.deck(names, seed: 12345)
        let b = NameLibrary.deck(names, seed: 12345)
        XCTAssertEqual(a.map(\.name), b.map(\.name), "same seed -> same order")
        XCTAssertEqual(Set(a.map(\.name)), Set(names.map(\.name)), "no names lost")

        let c = NameLibrary.deck(names, seed: 999)
        // Different seeds should (very likely) differ for a 4-name deck; at minimum still complete.
        XCTAssertEqual(Set(c.map(\.name)), Set(names.map(\.name)))
    }

    // MARK: Rising / trend helpers

    func testIsRising() {
        let rising = Name(name: "A", gender: .boy, origin: "x", meaning: "x", popularityByYear: [10, 50, 90])
        let falling = Name(name: "B", gender: .girl, origin: "x", meaning: "x", popularityByYear: [90, 50, 10])
        XCTAssertTrue(rising.isRising)
        XCTAssertFalse(falling.isRising)
        XCTAssertEqual(rising.peakPopularity, 90)
    }

    // MARK: Bundled catalog integrity

    func testBundledCatalogLoadsAndIsValid() {
        let lib = NameLibrary(bundle: .main)
        XCTAssertGreaterThanOrEqual(lib.count, 300, "ship at least 300 names")
        // Every name has the required fields and a non-empty trend.
        for n in lib.all {
            XCTAssertFalse(n.name.isEmpty)
            XCTAssertFalse(n.origin.isEmpty)
            XCTAssertFalse(n.meaning.isEmpty)
            XCTAssertFalse(n.popularityByYear.isEmpty)
        }
        // Genders are represented.
        let genders = Set(lib.all.map(\.gender))
        XCTAssertTrue(genders.contains(.boy))
        XCTAssertTrue(genders.contains(.girl))
        XCTAssertTrue(genders.contains(.unisex))
    }

    func testCatalogHasNoDuplicateNames() {
        let lib = NameLibrary(bundle: .main)
        XCTAssertEqual(Set(lib.all.map(\.name)).count, lib.all.count, "names must be unique")
    }

    // MARK: Store

    @MainActor
    func testProductIDAndPrice() async {
        let store = Store()
        try? await Task.sleep(for: .seconds(0.2))
        XCTAssertEqual(Store.productID, "babble_pro_unlock")
        XCTAssertEqual(store.displayPrice, "$0.99")
        XCTAssertFalse(store.isPro, "Pro must start locked")
    }
}
