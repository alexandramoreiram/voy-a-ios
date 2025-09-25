import SwiftUI

@main
struct VoyAApp: App {
    @StateObject private var store = DataStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { store.load() }
        }
    }
}
