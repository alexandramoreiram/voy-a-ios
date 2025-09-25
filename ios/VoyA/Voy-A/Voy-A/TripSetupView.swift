import SwiftUI

struct TripSetupView: View {
    @State private var city: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = .now.addingTimeInterval(86400)
    @State private var hotelAddress: String = ""
    @State private var isSaving = false
    @State private var showingSuccess = false
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let geocoder = GeocodingService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Plan Your Adventure")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create a new trip to organize your travel inspiration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Destination")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter city name", text: $city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Travel Dates")
                                .font(.headline)
                                .foregroundColor(.primary)
                            VStack(spacing: 12) {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accommodation Address")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter where you're staying", text: $hotelAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: { 
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            Task { await saveTrip() }
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text(isSaving ? "Creating Trip..." : "Create Trip")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(city.isEmpty || hotelAddress.isEmpty || isSaving)
                        .padding(.top, 8)
                        .scaleEffect(isSaving ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isSaving)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Trip Created!", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your trip to \(city) has been created successfully!")
            }
        }
    }

    private func saveTrip() async {
        await MainActor.run {
            isSaving = true
        }
        
        do {
            let coord = try await geocoder.geocode(address: hotelAddress, cityHint: city)
            let newTrip = Trip(id: UUID(), city: city, startDate: startDate, endDate: endDate, hotelAddress: hotelAddress, hotelCoordinate: coord)
            await MainActor.run {
                store.trip = newTrip
                // Also save to trips folder
                saveTripToFolder(newTrip)
                isSaving = false
                showingSuccess = true
            }
        } catch {
            let newTrip = Trip(id: UUID(), city: city, startDate: startDate, endDate: endDate, hotelAddress: hotelAddress, hotelCoordinate: nil)
            await MainActor.run {
                store.trip = newTrip
                // Also save to trips folder
                saveTripToFolder(newTrip)
                isSaving = false
                showingSuccess = true
            }
        }
    }
    
    private func saveTripToFolder(_ trip: Trip) {
        guard let tripFolder = store.tripFolderURL(for: trip) else { return }
        
        // Create trip folder
        try? FileManager.default.createDirectory(at: tripFolder, withIntermediateDirectories: true)
        
        // Save trip.json
        let tripFile = tripFolder.appendingPathComponent("trip.json")
        if let data = try? JSONEncoder().encode(trip) {
            try? data.write(to: tripFile, options: [.atomic])
        }
        
        // Save places.json (empty for new trip)
        let placesFile = tripFolder.appendingPathComponent("places.json")
        if let data = try? JSONEncoder().encode([Place]()) {
            try? data.write(to: placesFile, options: [.atomic])
        }
    }
}
