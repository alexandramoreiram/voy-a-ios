//
//  ContentView.swift
//  Voy-A
//
//  Created by Alexandra Moreira on 25/9/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TripManagerView(selectedTab: $selectedTab)
                .tabItem { Label("Trips", systemImage: "airplane") }
                .tag(0)
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "map") }
                .tag(1)
            OutfitsView()
                .tabItem { Label("Outfits", systemImage: "photo.on.rectangle") }
                .tag(2)
            ItineraryView()
                .tabItem { Label("Itinerary", systemImage: "calendar") }
                .tag(3)
            CollaborationView()
                .tabItem { Label("Collaborate", systemImage: "person.2") }
                .tag(4)
        }
        .accentColor(.blue)
    }
}
