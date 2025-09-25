import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDay: Int = 0
    
    private var tripDays: [Date] {
        guard let trip = store.trip else { return [] }
        var days: [Date] = []
        var currentDate = trip.startDate
        while currentDate <= trip.endDate {
            days.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return days
    }
    
    private var placesForSelectedDay: [Place] {
        // Filter places by selected day
        return store.places.filter { place in
            if let assignedDay = place.assignedDay {
                return assignedDay == selectedDay
            } else {
                // If no day assigned, show on first day
                return selectedDay == 0
            }
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if store.trip == nil {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No trip selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Create a trip first to see your itinerary")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Day selector
                    if tripDays.count > 1 {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Trip Days")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Day \(selectedDay + 1) of \(tripDays.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(tripDays.enumerated()), id: \.offset) { index, date in
                                        Button(action: {
                                            print("Day \(index + 1) tapped")
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedDay = index
                                            }
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(dayName(for: date))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                Text(dayNumber(for: date))
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                            }
                                            .foregroundColor(selectedDay == index ? .white : .primary)
                                            .frame(width: 70, height: 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedDay == index ? Color.blue : Color.gray.opacity(0.1))
                                                    .shadow(color: selectedDay == index ? Color.blue.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
                                            )
                                            .scaleEffect(selectedDay == index ? 1.05 : 1.0)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.05))
                    }
                    
                    // Places for selected day
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Places for \(dayName(for: tripDays[selectedDay])) \(dayNumber(for: tripDays[selectedDay]))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(placesForSelectedDay.count) places")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        List {
                            ForEach(placesForSelectedDay) { place in
                                PlaceRowView(place: place, selectedDay: selectedDay) { newDay in
                                    updatePlaceDay(place: place, newDay: newDay)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Itinerary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export Itinerary") {
                            exportItinerary()
                        }
                        Button("Share Trip") {
                            shareTrip()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func exportItinerary() {
        guard let trip = store.trip else { return }
        let content = ExportService.shared.exportItinerary(trip: trip, places: store.places)
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func shareTrip() {
        guard let trip = store.trip else { return }
        let content = ExportService.shared.exportItinerary(trip: trip, places: store.places)
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func updatePlaceDay(place: Place, newDay: Int) {
        // Update the place's assigned day
        if let index = store.places.firstIndex(where: { $0.id == place.id }) {
            var updatedPlace = place
            updatedPlace.assignedDay = newDay
            store.places[index] = updatedPlace
        }
    }
}

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let dayNumber: Int
    let action: () -> Void
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private var dayNumberString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback for better UX
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(dayNumberString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlaceRowView: View {
    let place: Place
    let selectedDay: Int
    let onDayChange: (Int) -> Void
    @State private var showingDayPicker = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                Text(place.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(categoryColor(for: place.category).opacity(0.1))
                    .cornerRadius(4)
                if !place.notes.isEmpty {
                    Text(place.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack {
                Button(action: { 
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingDayPicker = true 
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Day \(selectedDay + 1)")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let url = place.url {
                    Link(destination: url) {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Move to Day", isPresented: $showingDayPicker) {
            ForEach(1...7, id: \.self) { day in
                Button("Day \(day)") {
                    onDayChange(day - 1)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Which day should this place be on?")
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
}