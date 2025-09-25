import SwiftUI

struct TripSetupView: View {
    @State private var city: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = .now.addingTimeInterval(86400)
    @State private var hotelAddress: String = ""
    @EnvironmentObject var store: DataStore
    let geocoder = GeocodingService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    TextField("City", text: $city)
                }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section("Hotel") {
                    TextField("Hotel address", text: $hotelAddress)
                }
                Button("Save Trip") { Task { await saveTrip() } }
            }
            .navigationTitle("Create Trip")
        }
    }

    private func saveTrip() async {
        do {
            let coord = try await geocoder.geocode(address: hotelAddress)
            store.trip = Trip(id: UUID(), city: city, startDate: startDate, endDate: endDate, hotelAddress: hotelAddress, hotelCoordinate: coord)
        } catch {
            store.trip = Trip(id: UUID(), city: city, startDate: startDate, endDate: endDate, hotelAddress: hotelAddress, hotelCoordinate: nil)
        }
    }
}
