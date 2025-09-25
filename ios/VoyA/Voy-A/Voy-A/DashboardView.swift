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
                ListSection()
            }
            .navigationTitle("Dashboard")
            .toolbar { Button(action: { presentingAdd = true }) { Image(systemName: "plus") } }
            .sheet(isPresented: $presentingAdd) { AddPlaceView().environmentObject(store) }
        }
    }
}

struct MapSection: View {
    var places: [Place]
    @EnvironmentObject var store: DataStore
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))

    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                Map(position: .constant(.region(region)), interactionModes: .all) {
                    if let hotel = store.trip?.hotelCoordinate { 
                        Marker("Accommodation", coordinate: hotel)
                            .tint(.red)
                    }
                    ForEach(places) { p in
                        if let c = p.coordinate { 
                            Marker(p.name, coordinate: c)
                                .tint(categoryColor(for: p.category))
                        }
                    }
                }
            } else {
                Map(
                    coordinateRegion: $region,
                    annotationItems: places.filter { $0.coordinate != nil }
                ) { place in
                    MapAnnotation(coordinate: place.coordinate!) {
                        Circle()
                            .fill(categoryColor(for: place.category))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .onAppear {
            updateMapRegion()
        }
        .onChange(of: store.trip?.id) {
            updateMapRegion()
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "shop": return .purple
        case "museum": return .blue
        case "neighborhood": return .green
        case "fitness": return .red
        default: return .gray
        }
    }
    
    private func updateMapRegion() {
        if let hotelCoord = store.trip?.hotelCoordinate {
            region = MKCoordinateRegion(center: hotelCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        } else if let firstPlace = places.first(where: { $0.coordinate != nil })?.coordinate {
            region = MKCoordinateRegion(center: firstPlace, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
}

struct ListSection: View {
    @EnvironmentObject var store: DataStore
    @State private var editingPlace: Place?
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
                ForEach(store.places) { place in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.headline)
                            if let url = place.url { 
                                Link(url.absoluteString, destination: url)
                                    .font(.subheadline)
                            }
                            Text(place.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(categoryColor(for: place.category).opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            editingPlace = place
                            showingEditSheet = true
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 2)
                }
            .onDelete { offsets in
                store.places.remove(atOffsets: offsets)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let place = editingPlace {
                EditPlaceSheet(place: place) { updatedPlace in
                    updatePlace(updatedPlace)
                }
                .environmentObject(store)
            }
        }
    }
    
    private func updatePlace(_ updatedPlace: Place) {
        if let index = store.places.firstIndex(where: { $0.id == updatedPlace.id }) {
            store.places[index] = updatedPlace
        }
        editingPlace = nil
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "shop": return .purple
        case "museum": return .blue
        case "neighborhood": return .green
        case "fitness": return .red
        default: return .gray
        }
    }
}

struct EditPlaceSheet: View {
    let place: Place
    let onSave: (Place) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var name: String
    @State private var link: String
    @State private var category: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var showingSuccess = false
    
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
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Edit Place")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                Form {
                    Section("Place Details") {
                        TextField("Place name", text: $name)
                        TextField("Website URL (optional)", text: $link)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section("Category") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                            ForEach(categoryOptions, id: \.name) { option in
                                CategoryButton(
                                    category: option,
                                    isSelected: category == option.name
                                ) {
                                    category = option.name
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: { Task { await saveChanges() } }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isSaving ? "Saving..." : "Save Changes")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                }
                .disabled(isSaving || name.isEmpty)
                .opacity((isSaving || name.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Place Updated!", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your place has been successfully updated.")
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
        await MainActor.run {
            isSaving = true
        }
        
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
        
        await MainActor.run {
            onSave(updatedPlace)
            isSaving = false
            showingSuccess = true
        }
    }
}
