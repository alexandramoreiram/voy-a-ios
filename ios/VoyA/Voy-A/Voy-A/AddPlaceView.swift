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
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Add New Place")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Save a place you want to visit")
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
                        
                        Button(action: { 
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            Task { await save() }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Save Place")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(name.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
    
    private let categoryOptions = [
        CategoryOption(name: "Food", icon: "fork.knife", color: .orange),
        CategoryOption(name: "Shop", icon: "bag", color: .purple),
        CategoryOption(name: "Museum", icon: "building.columns", color: .blue),
        CategoryOption(name: "Neighborhood", icon: "house", color: .green),
        CategoryOption(name: "Fitness", icon: "figure.strengthtraining.traditional", color: .red)
    ]

    private func save() async {
        let url = URL(string: link)
        let coord = try? await geocoder.geocode(address: name, cityHint: store.trip?.city, near: store.trip?.hotelCoordinate)
        let newPlace = Place(id: UUID(), name: name, url: url, category: category, notes: notes, coordinate: coord)
        if !store.places.contains(where: { $0.name.caseInsensitiveCompare(newPlace.name) == .orderedSame }) {
            store.places.append(newPlace)
        }
        dismiss()
    }
}

struct CategoryOption {
    let name: String
    let icon: String
    let color: Color
}

struct CategoryButton: View {
    let category: CategoryOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
