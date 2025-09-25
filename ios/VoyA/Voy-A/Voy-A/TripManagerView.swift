import SwiftUI

struct TripManagerView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedTab: Int
    @State private var showingNewTrip = false
    @State private var trips: [Trip] = []
    @State private var editingTrip: Trip?
    @State private var showingEditSheet = false
    @State private var selectedTrip: Trip?
    @State private var showingTripSummary = false
    @State private var currentTripId: UUID? = nil
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            List {
                if trips.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No trips yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Create your first trip to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(trips) { trip in
                        TripRowView(trip: trip, isSelected: trip.id == currentTripId) {
                            // Load the trip immediately to update the checkmark
                            loadTrip(trip)
                            selectedTrip = trip
                            // Small delay to ensure state is properly set
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showingTripSummary = true
                            }
                        } onEdit: {
                            editingTrip = trip
                            showingEditSheet = true
                        }
                    }
                    .onDelete(perform: deleteTrips)
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewTrip = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadTrips()
                // Initialize currentTripId with the current trip
                currentTripId = store.trip?.id
                let onAppearTripIdString = currentTripId?.uuidString ?? "nil"
                print("OnAppear - currentTripId set to: \(onAppearTripIdString)")
            }
            .onChange(of: store.trip?.id) { _, newTripId in
                currentTripId = newTripId
                let updatedTripIdString = currentTripId?.uuidString ?? "nil"
                print("Store trip changed - currentTripId updated to: \(updatedTripIdString)")
                // Force UI refresh
                refreshID = UUID()
            }
            .sheet(isPresented: $showingNewTrip) {
                TripSetupView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let trip = editingTrip {
                    EditTripSheet(trip: trip) { updatedTrip in
                        updateTrip(updatedTrip)
                    }
                    .environmentObject(store)
                } else {
                    Text("No trip selected for editing")
                        .padding()
                }
            }
            .sheet(isPresented: $showingTripSummary) {
                if let trip = selectedTrip {
                    TripSummarySheet(trip: trip, selectedTab: $selectedTab) {
                        loadTrip(trip)
                        showingTripSummary = false
                    }
                    .environmentObject(store)
                }
            }
        }
        .id(refreshID)
    }
    
    private func loadTrips() {
        // Load all saved trips from the trips folder
        let tripsFolder = store.folderURL.appendingPathComponent("Trips", isDirectory: true)
        guard FileManager.default.fileExists(atPath: tripsFolder.path) else { return }
        guard let tripFolders = try? FileManager.default.contentsOfDirectory(at: tripsFolder, includingPropertiesForKeys: nil) else { return }
        
        var loadedTrips: [Trip] = []
        for folder in tripFolders {
            let tripFile = folder.appendingPathComponent("trip.json")
            if let data = try? Data(contentsOf: tripFile),
               let trip = try? JSONDecoder().decode(Trip.self, from: data) {
                loadedTrips.append(trip)
            }
        }
        trips = loadedTrips.sorted { $0.startDate > $1.startDate }
    }
    
    private func loadTrip(_ trip: Trip) {
        print("Loading trip: \(trip.city)")
        let currentStoreTrip = store.trip?.city ?? "nil"
        let currentTripIdString = currentTripId?.uuidString ?? "nil"
        print("Current store.trip: \(currentStoreTrip)")
        print("Current currentTripId: \(currentTripIdString)")
        
        // Update the store with the new trip
        store.trip = trip
        currentTripId = trip.id
        let newStoreTrip = store.trip?.city ?? "nil"
        print("Set store.trip to: \(newStoreTrip)")
        // Force UI refresh
        refreshID = UUID()
        let newTripIdString = currentTripId?.uuidString ?? "nil"
        print("Set currentTripId to: \(newTripIdString)")
        print("Checkmark should now show for trip: \(trip.city)")
        
        // Load places for this trip
        if let tripFolder = store.tripFolderURL(for: trip) {
            let placesFile = tripFolder.appendingPathComponent("places.json")
            print("Looking for places at: \(placesFile.path)")
            if let data = try? Data(contentsOf: placesFile),
               let places = try? JSONDecoder().decode([Place].self, from: data) {
                print("Loaded \(places.count) places for trip")
                store.places = places
            } else {
                print("No places found for trip, starting with empty array")
                store.places = []
            }
        } else {
            print("No trip folder found")
            store.places = []
        }
        
        // Force UI update
        DispatchQueue.main.async {
            print("Forcing UI update after trip load")
            refreshID = UUID() // Force UI refresh
        }
    }
    
    private func updateTrip(_ updatedTrip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == updatedTrip.id }) {
            trips[index] = updatedTrip
            // Update the current trip if it's the one being edited
            if store.trip?.id == updatedTrip.id {
                store.trip = updatedTrip
            }
            // Save the updated trip to its folder
            saveTripToFolder(updatedTrip)
        }
        editingTrip = nil
    }
    
    private func saveTripToFolder(_ trip: Trip) {
        guard let tripFolder = store.tripFolderURL(for: trip) else { return }
        
        try? FileManager.default.createDirectory(at: tripFolder, withIntermediateDirectories: true)
        
        let tripFile = tripFolder.appendingPathComponent("trip.json")
        if let data = try? JSONEncoder().encode(trip) {
            try? data.write(to: tripFile, options: [.atomic])
        }
    }
    
    private func deleteTrips(offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            if let tripFolder = store.tripFolderURL(for: trip) {
                try? FileManager.default.removeItem(at: tripFolder)
            }
        }
        trips.remove(atOffsets: offsets)
    }
}

struct TripRowView: View {
    let trip: Trip
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    var body: some View {
        let _ = print("TripRowView for \(trip.city): isSelected = \(isSelected)")
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(trip.city)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
                
                Text(trip.hotelAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(dateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            onEdit()
                        }) {
                            Text("Edit")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: false)
                        
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            onTap()
                        }) {
                            Text("Tap to open")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
}

struct EditTripSheet: View {
    let trip: Trip
    let onSave: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var city: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hotelAddress: String
    @State private var isSaving = false
    @State private var showingSuccess = false
    
    let geocoder = GeocodingService()
    
    init(trip: Trip, onSave: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onSave = onSave
        self._city = State(initialValue: trip.city)
        self._startDate = State(initialValue: trip.startDate)
        self._endDate = State(initialValue: trip.endDate)
        self._hotelAddress = State(initialValue: trip.hotelAddress)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Edit Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                Form {
                    Section("Destination") {
                        TextField("City", text: $city)
                    }
                    
                    Section("Dates") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    
                    Section("Accommodation") {
                        TextField("Accommodation address", text: $hotelAddress)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: { Task { await saveTrip() } }) {
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
                .disabled(isSaving || city.isEmpty || hotelAddress.isEmpty)
                .opacity((isSaving || city.isEmpty || hotelAddress.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Trip Updated!", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your trip has been successfully updated.")
        }
    }
    
    private func saveTrip() async {
        await MainActor.run {
            isSaving = true
        }
        
        do {
            let coord = try await geocoder.geocode(address: hotelAddress, cityHint: city)
            let updatedTrip = Trip(
                id: trip.id,
                city: city,
                startDate: startDate,
                endDate: endDate,
                hotelAddress: hotelAddress,
                hotelCoordinate: coord
            )
            await MainActor.run {
                onSave(updatedTrip)
                isSaving = false
                showingSuccess = true
            }
        } catch {
            let updatedTrip = Trip(
                id: trip.id,
                city: city,
                startDate: startDate,
                endDate: endDate,
                hotelAddress: hotelAddress,
                hotelCoordinate: nil
            )
            await MainActor.run {
                onSave(updatedTrip)
                isSaving = false
                showingSuccess = true
            }
        }
    }
}

struct TripSummarySheet: View {
    let trip: Trip
    @Binding var selectedTab: Int
    let onOpenTrip: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @State private var tripPlaces: [Place] = []
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private var tripDuration: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return "\(days + 1) days"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(trip.city)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(trip.hotelAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Trip Details
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Dates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(dateRange)
                                    .font(.headline)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(tripDuration)
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Places Summary
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Places (\(tripPlaces.count))")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            if tripPlaces.isEmpty {
                                Text("No places added yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                                    ForEach(tripPlaces.prefix(6)) { place in
                                        PlaceCard(place: place)
                                    }
                                }
                                
                                if tripPlaces.count > 6 {
                                    Text("+ \(tripPlaces.count - 6) more places")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            print("Open Trip button tapped - switching to Dashboard")
                            selectedTab = 1 // Switch to Dashboard tab
                            onOpenTrip()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Open Trip")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Trip Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            loadTripPlaces()
        }
    }
    
    private func loadTripPlaces() {
        if let tripFolder = store.tripFolderURL(for: trip) {
            let placesFile = tripFolder.appendingPathComponent("places.json")
            if let data = try? Data(contentsOf: placesFile),
               let places = try? JSONDecoder().decode([Place].self, from: data) {
                tripPlaces = places
            }
        }
    }
}

struct PlaceCard: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(place.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(place.category)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(categoryColor(for: place.category).opacity(0.2))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
