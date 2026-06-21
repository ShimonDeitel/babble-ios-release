import Foundation

/// A baby name's gender category. `unisex` works for either.
enum Gender: String, Codable, CaseIterable, Identifiable, Hashable {
    case boy, girl, unisex
    var id: String { rawValue }

    /// The collection a name maps into when saved with the swipe gesture.
    var label: String {
        switch self {
        case .boy: return "Boys"
        case .girl: return "Girls"
        case .unisex: return "Unisex"
        }
    }

    var sfSymbol: String {
        switch self {
        case .boy: return "person.fill"
        case .girl: return "person.fill"
        case .unisex: return "person.2.fill"
        }
    }
}

/// One baby name, decoded from the bundled `names.json`. This is a pure value type — the catalog
/// is read-only reference data. Saved names live in SwiftData (`SavedName`).
struct Name: Codable, Identifiable, Hashable {
    let name: String
    let gender: Gender
    let origin: String
    let meaning: String
    /// A relative popularity index (0...100) sampled at evenly spaced years. Used for the mini trend.
    let popularityByYear: [Int]

    var id: String { name }

    /// The calendar years the `popularityByYear` samples correspond to.
    static let trendYears = [1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020]

    /// Heuristic syllable count from the name's spelling — counts vowel groups, with a small
    /// correction for a silent trailing "e". Pure and deterministic so it is unit-testable.
    var syllableCount: Int {
        Name.syllables(in: name)
    }

    /// True when the most recent trend sample is at least as high as the earliest one.
    var isRising: Bool {
        guard let first = popularityByYear.first, let last = popularityByYear.last else { return false }
        return last >= first
    }

    /// The peak popularity value across the trend (0 when empty).
    var peakPopularity: Int { popularityByYear.max() ?? 0 }

    /// Heuristic syllable count: count vowel groups, then add a syllable for each common "hiatus"
    /// vowel pair (two adjacent vowels pronounced separately, e.g. the i-a in "Liam" or "Olivia"),
    /// and drop a silent trailing "e". Pure and deterministic so it is unit-testable. This is a
    /// spelling heuristic, not a pronunciation dictionary, so a few names will be approximate.
    static func syllables(in raw: String) -> Int {
        let word = raw.lowercased()
        let vowels = Set("aeiouy")
        // Adjacent vowel pairs that usually span two syllables.
        let hiatus: Set<String> = ["ia", "io", "ya", "eo", "ua", "ea", "uo", "iu", "oe"]

        // Build the consecutive vowel groups.
        var groups: [String] = []
        var current = ""
        for ch in word {
            if vowels.contains(ch) {
                current.append(ch)
            } else if !current.isEmpty {
                groups.append(current); current = ""
            }
        }
        if !current.isEmpty { groups.append(current) }

        var count = 0
        for group in groups {
            count += 1
            let chars = Array(group)
            for i in 0..<max(0, chars.count - 1) {
                if hiatus.contains(String(chars[i]) + String(chars[i + 1])) { count += 1 }
            }
        }

        // Silent trailing "e" (e.g. "Grace", "Claire") usually doesn't add a syllable.
        if word.count > 2, word.hasSuffix("e"), !word.hasSuffix("le"), count > 1 {
            count -= 1
        }
        return max(1, count)
    }
}

/// The lengths used by the Pro "filter by length" feature.
enum NameLength: String, CaseIterable, Identifiable {
    case any, short, medium, long
    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: return "Any length"
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }

    /// Inclusive syllable bounds. `any` accepts everything.
    func matches(_ name: Name) -> Bool {
        let s = name.syllableCount
        switch self {
        case .any: return true
        case .short: return s <= 1
        case .medium: return s == 2
        case .long: return s >= 3
        }
    }
}
