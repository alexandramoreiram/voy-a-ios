import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    let id: UUID
    var city: String
    var startDate: Date
    var endDate: Date
    var hotelAddress: String
    var hotelCoordinate: CLLocationCoordinate2D?

    private enum CodingKeys: String, CodingKey {
        case id, city, startDate, endDate, hotelAddress, hotelLatitude, hotelLongitude
    }

    init(id: UUID, city: String, startDate: Date, endDate: Date, hotelAddress: String, hotelCoordinate: CLLocationCoordinate2D?) {
        self.id = id
        self.city = city
        self.startDate = startDate
        self.endDate = endDate
        self.hotelAddress = hotelAddress
        self.hotelCoordinate = hotelCoordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        city = try container.decode(String.self, forKey: .city)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        hotelAddress = try container.decode(String.self, forKey: .hotelAddress)
        if let lat = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .hotelLatitude),
           let lon = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .hotelLongitude) {
            hotelCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            hotelCoordinate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(city, forKey: .city)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(hotelAddress, forKey: .hotelAddress)
        if let coord = hotelCoordinate {
            try container.encode(coord.latitude, forKey: .hotelLatitude)
            try container.encode(coord.longitude, forKey: .hotelLongitude)
        }
    }
}

struct Place: Identifiable, Codable {
    let id: UUID
    var name: String
    var url: URL?
    var category: String
    var notes: String
    var coordinate: CLLocationCoordinate2D?
    var assignedDay: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, url, category, notes, latitude, longitude, assignedDay
    }

    init(id: UUID, name: String, url: URL?, category: String, notes: String, coordinate: CLLocationCoordinate2D?, assignedDay: Int? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category
        self.notes = notes
        self.coordinate = coordinate
        self.assignedDay = assignedDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        category = try container.decode(String.self, forKey: .category)
        notes = try container.decode(String.self, forKey: .notes)
        assignedDay = try container.decodeIfPresent(Int.self, forKey: .assignedDay)
        if let lat = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .latitude),
           let lon = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .longitude) {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(category, forKey: .category)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(assignedDay, forKey: .assignedDay)
        if let coord = coordinate {
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        }
    }
}

struct Outfit: Identifiable, Codable { 
    let id: UUID
    var imageFileName: String
    var caption: String
    var pinterestURL: String?
    var imageData: Data?
    
    init(id: UUID = UUID(), imageFileName: String = "", caption: String = "", pinterestURL: String? = nil, imageData: Data? = nil) {
        self.id = id
        self.imageFileName = imageFileName
        self.caption = caption
        self.pinterestURL = pinterestURL
        self.imageData = imageData
    }
}
