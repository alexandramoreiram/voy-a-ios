import SwiftUI

struct ItineraryView: View {
    var places: [Place]
    var body: some View {
        List(places) { p in
            Text(p.name)
        }
        .navigationTitle("Itinerary")
    }
}
