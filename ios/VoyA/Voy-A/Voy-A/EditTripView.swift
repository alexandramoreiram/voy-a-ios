import SwiftUI

struct EditTripView: View {
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
            VStack(spacing: 0) {
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
                .padding(.bottom, 30)
                
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
                VStack(spacing: 16) {
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
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .alert("Trip Updated!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
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
