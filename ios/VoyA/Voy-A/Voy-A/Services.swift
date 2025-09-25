import Foundation
import MapKit
import CoreLocation
import Combine

final class GeocodingService {
    func geocode(address: String, cityHint: String? = nil, near center: CLLocationCoordinate2D? = nil) async throws -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = cityHint != nil ? "\(address), \(cityHint!)" : address
        if let c = center {
            request.region = MKCoordinateRegion(center: c,
                                                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        }
        let response = try await MKLocalSearch(request: request).start()
        if #available(iOS 26.0, *) {
            return response.mapItems.first?.location.coordinate
        } else {
            return response.mapItems.first?.placemark.coordinate
        }
    }
}

final class DataStore: ObservableObject {
    @Published var trip: Trip? = nil { didSet { saveTrip() } }
    @Published var places: [Place] = [] { didSet { savePlaces() } }
    @Published var outfits: [Outfit] = []


    // Simpler: no UTType needed
    private var tripURL: URL { folderURL.appendingPathComponent("trip.json") }
    private var placesURL: URL { folderURL.appendingPathComponent("places.json") }
    private var tripsRootURL: URL { folderURL.appendingPathComponent("Trips", isDirectory: true) }
    var currentTripFolderURL: URL? {
        guard let trip = trip else { return nil }
        return tripFolderURL(for: trip)
    }
    
    func tripFolderURL(for trip: Trip) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let name = "\(trip.city)-\(formatter.string(from: trip.startDate))"
        return tripsRootURL.appendingPathComponent(name, isDirectory: true)
    }
    
    var folderURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("VoyA", isDirectory: true)
    }

    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    func load() {
        ensureFolder()
        if let data = try? Data(contentsOf: tripURL), let t = try? decoder.decode(Trip.self, from: data) {
            self.trip = t
        }
        if let data = try? Data(contentsOf: placesURL), let p = try? decoder.decode([Place].self, from: data) {
            self.places = p
        }
    }

    private func ensureFolder() {
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: tripsRootURL, withIntermediateDirectories: true)
        if let tripFolder = currentTripFolderURL {
            try? FileManager.default.createDirectory(at: tripFolder, withIntermediateDirectories: true)
        }
    }

    private func saveTrip() {
        ensureFolder()
        guard let trip = trip else {
            try? FileManager.default.removeItem(at: tripURL)
            return
        }
        if let data = try? encoder.encode(trip) {
            try? data.write(to: tripURL, options: [.atomic])
        }
        // ensure per-trip folder exists right after saving trip
        ensureFolder()
    }

    private func savePlaces() {
        ensureFolder()
        if let data = try? encoder.encode(places) {
            try? data.write(to: placesURL, options: [.atomic])
            // Also save to current trip folder if we have a trip
            if let tripFolder = currentTripFolderURL {
                let tripPlacesURL = tripFolder.appendingPathComponent("places.json")
                try? data.write(to: tripPlacesURL, options: [.atomic])
            }
        }
    }
}
