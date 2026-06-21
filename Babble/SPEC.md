# Babble — Baby Names

**App Store Title:** Babble: Baby Names
**Subtitle:** Find and save the perfect name
**Bundle id:** `com.shimondeitel.babble`
**iCloud container:** `iCloud.com.shimondeitel.babble`
**Pro product (one-time, $0.99 non-consumable):** `babble_pro_unlock`

## What it is

Babble helps expecting parents discover and shortlist baby names. You swipe through a deck of
name cards — each showing origin, meaning, syllable count, and a small popularity trend — and swipe
right (or tap the heart) to save names into collections. Share a family shortlist card with a
partner.

100% native Swift / SwiftUI. Works fully offline. The only backend is Apple CloudKit (private
database mirror of your saved names) plus Sign in with Apple for identity. No servers, no
third-party SDKs, no AI, no ads, no tracking. **Zero device permissions** (no camera, photos, mic,
location, contacts, health, motion, files, or notifications).

## Screens

1. **Discover (Swipe)** — a deck of `NameCard`s. Drag right to save, left to skip, or use the
   three round buttons (skip / info / save). Gender chips filter the deck for free; the filter
   sheet adds origin + length (Pro). Tapping a card opens the detail sheet.
2. **Collections** — your saved-name lists. Free users keep one collection; Pro unlocks unlimited.
   Each collection can be opened, edited (swipe to delete a name) and, for Pro, shared as a
   rendered shortlist card.
3. **Name detail** — full meaning, origin, syllable count, and a larger popularity trend with a
   year axis, plus a save/unsave toggle.
4. **Settings** — Pro unlock / restore, theme (System / Light / Dark), haptics toggle, account
   (Sign in with Apple status, sign out, delete account), and the privacy link.

## Free vs Pro

| | Free | Pro ($0.99 one-time) |
|---|---|---|
| Browse all names | Yes | Yes |
| Collections | One | Unlimited (Boys / Girls / Unisex / custom) |
| Gender filter | Yes | Yes |
| Origin + length filters | — | Yes |
| Partner share (shortlist card) | — | Yes |

Pro is **never** persisted as truth — it is derived live from StoreKit 2
`Transaction.currentEntitlements`. A best-effort `PaidStatus` record is written to the public
CloudKit database for owner visibility only; gating always comes from StoreKit.

## Data

- **Catalog (read-only):** `Babble/Resources/names.json` — 390+ original baby-name entries, each
  with `name`, `gender` (boy/girl/unisex), `origin`, `meaning`, and a 9-point `popularityByYear`
  trend (relative 0–100 index, sampled 1980–2020). Meanings/origins are widely-established factual
  etymologies; the trend shapes are authored illustrative data for the mini-viz (not a copyrighted
  dataset). Loaded at launch by `NameLibrary`.
- **Saved data (SwiftData + CloudKit mirror):** `NameCollection` and `SavedName`. Every property has
  a default and the relationship is optional, so the schema mirrors to CloudKit cleanly.

## Key types

- `Name`, `Gender`, `NameLength` — pure value types + filtering/syllable logic (`Name.swift`).
- `NameLibrary` — catalog loading, `filter(...)`, and a deterministic seeded `deck(...)` shuffle.
- `AppModel` — owns the SwiftData container + catalog; collection CRUD with free/Pro gating; the
  save / dedupe / delete-all flows.
- `Store` — StoreKit 2 non-consumable unlock.
- `AccountManager` — Sign in with Apple.
- `CloudSync` — best-effort public `PaidStatus` record.

## Tests

`BabbleTests` (pure logic): syllable counting, length matching, gender/origin/length filtering,
deterministic deck shuffle, rising-trend helper, and bundled-catalog integrity (>= 300 names,
unique, all fields present, all genders represented).

`BabbleLogicTests` (SwiftData, in-memory): default collection on first run, free-tier one-collection
cap, Pro unlimited collections, save + dedupe, unsave-everywhere, delete-all reset, and Pro
gender-routed default collection.

## Build

XcodeGen project. Single app target + a unit-test target (no widget / UI-test targets; no App
Group). Entitlements: Sign in with Apple + iCloud/CloudKit only.

```
xcodegen generate
xcodebuild -project Babble.xcodeproj -scheme Babble -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/babble_dd CODE_SIGNING_ALLOWED=NO build
```
