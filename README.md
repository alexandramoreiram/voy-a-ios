# Voy-a iOS Travel App

A comprehensive travel planning and organization app built with SwiftUI for iOS 16+.

## ✈️ Features

### Trip Management
- Create and manage multiple trips
- Set accommodation details and dates
- View trip summaries with place counts
- Edit trip information
- Delete trips with swipe gestures

### Interactive Dashboard
- Interactive map with place markers
- Color-coded place categories
- Add new places with geocoding
- Edit existing places
- Filter places by category

### Place Categories
- 🍽️ **Food** - Restaurants and cafes
- 🛍️ **Shop** - Shopping destinations
- 🏛️ **Museum** - Cultural attractions
- 🏘️ **Neighborhood** - Areas to explore
- 💪 **Fitness** - Gyms and fitness centers

### Itinerary Planning
- Day-by-day trip organization
- Assign places to specific days
- Calendar-style day selector
- Export itinerary functionality
- Visual day planning interface

### Outfit Gallery
- Photo management from camera roll
- Pinterest URL integration
- Caption and description support
- Swipe-to-delete functionality
- Edit outfit details

### Collaboration
- Invite family members and partners
- Share trip information
- Collaborative trip planning

## 🛠️ Technical Stack

- **Framework**: SwiftUI
- **Minimum iOS**: 16.0
- **Language**: Swift 5
- **Maps**: MapKit
- **Location**: CoreLocation
- **Storage**: Local JSON file storage
- **Images**: PhotosPicker
- **Architecture**: MVVM with ObservableObject

## 📱 Screenshots

*Screenshots will be added here*

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later
- macOS 12.0 or later (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/voy-a-ios.git
   cd voy-a-ios
   ```

2. **Open in Xcode**
   ```bash
   open ios/VoyA/VoyA.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Project Structure

```
ios/VoyA/
├── Sources/
│   ├── App.swift                 # Main app entry point
│   ├── ContentView.swift         # Tab navigation
│   ├── Models.swift              # Data models (Trip, Place, Outfit)
│   ├── Services.swift            # Data storage and geocoding
│   ├── TripManagerView.swift     # Trip management
│   ├── DashboardView.swift       # Map and places
│   ├── AddPlaceView.swift        # Add new places
│   ├── OutfitsView.swift         # Outfit gallery
│   ├── ItineraryView.swift       # Day-by-day planning
│   ├── TripSetupView.swift       # Create new trips
│   └── CollaborationView.swift   # Sharing features
└── Voy-A/
    └── Voy-A/                    # Xcode project files
```

## 💾 Data Storage

The app uses local JSON file storage for:
- **Trips**: Stored in `Documents/VoyA/trip.json`
- **Places**: Stored in `Documents/VoyA/places.json`
- **Trip-specific data**: Each trip has its own folder with places

## 🎨 Design Philosophy

- **Gen Z/Millennial focused**: Fast, responsive, and intuitive
- **Modern UI**: Clean SwiftUI interface with haptic feedback
- **Flexible**: Easy to add new features and categories
- **Offline-first**: Works without internet connection
- **Privacy-focused**: All data stored locally on device

## 🔧 Development

### Adding New Features
1. Create new SwiftUI views in the `Sources/` directory
2. Update `ContentView.swift` to add new tabs
3. Add new data models to `Models.swift` if needed
4. Update `Services.swift` for data persistence

### Code Style
- Use SwiftUI best practices
- Follow MVVM architecture
- Use `@Published` properties for reactive UI
- Implement proper error handling
- Add haptic feedback for user interactions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the documentation
- Review the code comments

## 🎯 Roadmap

- [ ] Cloud sync functionality
- [ ] Offline map support
- [ ] Social sharing features
- [ ] Advanced filtering options
- [ ] Trip templates
- [ ] Weather integration
- [ ] Budget tracking
- [ ] Photo organization improvements

---

**Voy-a** - Your personal travel companion 🧳✈️
