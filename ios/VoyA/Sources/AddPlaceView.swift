import SwiftUI

struct AddPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore

    @State private var name: String = ""
    @State private var link: String = ""
    @State private var category: String = "Food"
    @State private var notes: String = ""

    let geocoder = GeocodingService()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Place name", text: $name)
                TextField("URL (optional)", text: $link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Picker("Category", selection: $category) {
                    ForEach(["Food","Shop","Museum","Neighborhood"], id: \.self) { Text($0) }
                }
                TextField("Notes", text: $notes, axis: .vertical)
                Button("Save") { Task { await save() } }
            }
            .navigationTitle("Add Place")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private func save() async {
        let url = URL(string: link)
        let coord = try? await geocoder.geocode(address: name)
        let place = Place(id: UUID(), name: name, url: url, category: category, notes: notes, coordinate: coord)
        store.places.append(place)
        dismiss()
    }
}
