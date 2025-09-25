import SwiftUI
import MapKit

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var presentingAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapSection(places: store.places)
                    .frame(height: 280)
                ListSection(places: store.places)
            }
            .navigationTitle("Dashboard")
            .toolbar { Button(action: { presentingAdd = true }) { Image(systemName: "plus") } }
            .sheet(isPresented: $presentingAdd) { AddPlaceView().environmentObject(store) }
        }
    }
}

struct MapSection: View {
    var places: [Place]
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))

    var body: some View {
        Map(
            coordinateRegion: $region,
            annotationItems: places.filter { $0.coordinate != nil }
        ) { place in
            MapMarker(coordinate: place.coordinate!)
        }
    }
}

struct ListSection: View {
    var places: [Place]
    var body: some View {
        List(places) { p in
            VStack(alignment: .leading, spacing: 4) {
                Text(p.name).font(.headline)
                if let url = p.url { Link(url.absoluteString, destination: url).font(.subheadline) }
                Text(p.category).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
