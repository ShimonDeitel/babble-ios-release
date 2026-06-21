import Foundation

/// Loads and serves the bundled, read-only baby-name catalog. The catalog is original reference
/// data shipped in `names.json`; nothing here touches the network.
struct NameLibrary {
    let all: [Name]

    /// Loads from the app bundle. Falls back to a tiny built-in set if the resource is missing so
    /// the UI never shows an empty deck.
    init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "names", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Name].self, from: data),
           !decoded.isEmpty {
            self.all = decoded
        } else {
            self.all = NameLibrary.fallback
        }
    }

    /// Test/explicit initializer.
    init(names: [Name]) { self.all = names }

    var count: Int { all.count }

    func origins() -> [String] {
        Array(Set(all.map(\.origin))).sorted()
    }

    /// Filters the catalog. `genders` empty means all genders. `origin` nil means all origins.
    /// `length` `.any` means all lengths. Pure and deterministic — covered by unit tests.
    static func filter(_ names: [Name], genders: Set<Gender>,
                       origin: String?, length: NameLength) -> [Name] {
        names.filter { n in
            (genders.isEmpty || genders.contains(n.gender)) &&
            (origin == nil || n.origin == origin) &&
            length.matches(n)
        }
    }

    /// A stable, seeded shuffle so the deck order is reproducible per launch session but still feels
    /// random. Uses a simple LCG so it is fully deterministic and unit-testable.
    static func deck(_ names: [Name], seed: UInt64) -> [Name] {
        var arr = names
        var state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
        if arr.count > 1 {
            for i in stride(from: arr.count - 1, to: 0, by: -1) {
                let j = Int(next() % UInt64(i + 1))
                arr.swapAt(i, j)
            }
        }
        return arr
    }

    static let fallback: [Name] = [
        Name(name: "Liam", gender: .boy, origin: "Irish",
             meaning: "Strong-willed warrior and protector",
             popularityByYear: [40, 45, 50, 55, 60, 70, 85, 95, 90]),
        Name(name: "Olivia", gender: .girl, origin: "Latin",
             meaning: "Olive tree, symbol of peace",
             popularityByYear: [20, 30, 45, 60, 75, 88, 95, 99, 96]),
        Name(name: "Rowan", gender: .unisex, origin: "Irish",
             meaning: "Little red-haired one, the rowan tree",
             popularityByYear: [10, 12, 18, 25, 35, 50, 65, 78, 85])
    ]
}
