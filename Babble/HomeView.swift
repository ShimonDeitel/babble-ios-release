import SwiftUI

struct HomeView: View {
    var forceScreen: String?

    @State private var selectedTab = 0
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeView()
                .tabItem { Label("Discover", systemImage: "rectangle.stack") }
                .tag(0)

            CollectionsView()
                .tabItem { Label("Collections", systemImage: "heart.text.square") }
                .tag(1)
        }
        .tint(Color.babbleAccent)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { applyForceScreen() }
    }

    private func applyForceScreen() {
        guard let s = forceScreen else { return }
        switch s {
        case "collections": selectedTab = 1
        case "settings": showSettings = true
        default: selectedTab = 0
        }
    }
}
