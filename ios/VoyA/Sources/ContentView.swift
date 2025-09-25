import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TripSetupView()
                .tabItem { Label("Trip", systemImage: "airplane") }
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "map") }
            OutfitsView()
                .tabItem { Label("Outfits", systemImage: "photo.on.rectangle") }
        }
    }
}
