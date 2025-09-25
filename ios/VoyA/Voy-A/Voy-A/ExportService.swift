import Foundation

class ExportService {
    static let shared = ExportService()
    
    func exportItinerary(trip: Trip, places: [Place]) -> String {
        var content = "# \(trip.city) Itinerary\n\n"
        
        // Trip details
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        content += "**Dates:** \(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))\n"
        content += "**Hotel:** \(trip.hotelAddress)\n\n"
        
        // Places
        content += "## Places to Visit\n\n"
        for place in places {
            content += "### \(place.name)\n"
            content += "**Category:** \(place.category)\n"
            if let url = place.url {
                content += "**Link:** \(url.absoluteString)\n"
            }
            if !place.notes.isEmpty {
                content += "**Notes:** \(place.notes)\n"
            }
            content += "\n"
        }
        
        return content
    }
    
    func exportToPDF(trip: Trip, places: [Place]) -> Data? {
        let _ = exportItinerary(trip: trip, places: places)
        
        // Simple HTML to PDF conversion
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                h1 { color: #007AFF; }
                h2 { color: #333; border-bottom: 2px solid #007AFF; }
                h3 { color: #666; }
                .trip-details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
                .place { margin-bottom: 20px; padding: 15px; border-left: 4px solid #007AFF; }
                .category { background: #007AFF; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
            </style>
        </head>
        <body>
            <h1>\(trip.city) Itinerary</h1>
            <div class="trip-details">
                <p><strong>Dates:</strong> \(DateFormatter.localizedString(from: trip.startDate, dateStyle: .full, timeStyle: .none)) - \(DateFormatter.localizedString(from: trip.endDate, dateStyle: .full, timeStyle: .none))</p>
                <p><strong>Hotel:</strong> \(trip.hotelAddress)</p>
            </div>
            <h2>Places to Visit</h2>
            \(places.map { place in
                var html = "<div class=\"place\">"
                html += "<h3>\(place.name)</h3>"
                html += "<span class=\"category\">\(place.category)</span>"
                if let url = place.url {
                    html += "<p><strong>Link:</strong> <a href=\"\(url.absoluteString)\">\(url.absoluteString)</a></p>"
                }
                if !place.notes.isEmpty {
                    html += "<p><strong>Notes:</strong> \(place.notes)</p>"
                }
                html += "</div>"
                return html
            }.joined(separator: ""))
        </body>
        </html>
        """
        
        return html.data(using: .utf8)
    }
}
