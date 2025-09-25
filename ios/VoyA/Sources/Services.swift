import Foundation
import CoreLocation
import Combine

final class GeocodingService {
    private let geocoder = CLGeocoder()
    func geocode(address: String) async throws -> CLLocationCoordinate2D? {
        try await withCheckedThrowingContinuation { cont in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error { cont.resume(throwing: error); return }
                let coord = placemarks?.first?.location?.coordinate
                cont.resume(returning: coord)
            }
        }
    }
}

final class DataStore: ObservableObject {
    @Published var trip: Trip? = nil {
        didSet { saveTrip() }
    }
    @Published var places: [Place] = [] {
        didSet { savePlaces() }
    }
    @Published var outfits: [Outfit] = []

    private var cancellables: Set<AnyCancellable> = []

    private let folderURL: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("VoyA", isDirectory: true)
    }()

    private var tripURL: URL { folderURL.appendingPathComponent("trip.json", conformingTo: .json) }
    private var placesURL: URL { folderURL.appendingPathComponent("places.json", conformingTo: .json) }

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
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            // Ignore directory creation errors for MVP
        }
    }

    private func saveTrip() {
        ensureFolder()
        guard let trip = trip else {
            // If trip is cleared, also clear file
            try? FileManager.default.removeItem(at: tripURL)
            return
        }
        if let data = try? encoder.encode(trip) {
            try? data.write(to: tripURL, options: [.atomic])
        }
    }

    private func savePlaces() {
        ensureFolder()
        if let data = try? encoder.encode(places) {
            try? data.write(to: placesURL, options: [.atomic])
        }
    }
}
