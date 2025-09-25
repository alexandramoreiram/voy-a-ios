import SwiftUI

struct EditPlaceView: View {
    let place: Place
    let onSave: (Place) -> Void
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var link: String
    @State private var category: String
    @State private var notes: String
    
    let geocoder = GeocodingService()
    
    init(place: Place, onSave: @escaping (Place) -> Void) {
        self.place = place
        self.onSave = onSave
        self._name = State(initialValue: place.name)
        self._link = State(initialValue: place.url?.absoluteString ?? "")
        self._category = State(initialValue: place.category)
        self._notes = State(initialValue: place.notes)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Edit Place")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Update place information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Place Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter place name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(categoryOptions, id: \.name) { option in
                                    CategoryButton(
                                        category: option,
                                        isSelected: category == option.name
                                    ) {
                                        category = option.name
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website (optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("https://...", text: $link)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Add notes about this place...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        Button("Save Changes") { 
                            Task { await saveChanges() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(name.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private let categoryOptions = [
        CategoryOption(name: "Food", icon: "fork.knife", color: .orange),
        CategoryOption(name: "Shop", icon: "bag", color: .purple),
        CategoryOption(name: "Museum", icon: "building.columns", color: .blue),
        CategoryOption(name: "Neighborhood", icon: "house", color: .green),
        CategoryOption(name: "Fitness", icon: "figure.strengthtraining.traditional", color: .red)
    ]
    
    private func saveChanges() async {
        let url = URL(string: link)
        let coord = try? await geocoder.geocode(address: name, cityHint: store.trip?.city, near: store.trip?.hotelCoordinate)
        
        let updatedPlace = Place(
            id: place.id,
            name: name,
            url: url,
            category: category,
            notes: notes,
            coordinate: coord
        )
        
        onSave(updatedPlace)
        dismiss()
    }
}
