# ðŸšŒ SunRoute â€” Smart Seat Advisor (Flutter Mobile App)

> A Flutter mobile app that helps travelers choose the best seat by visualizing sunlight exposure, weather conditions, and ventilation along their entire route â€” with an interactive time scrubber.

---

## ðŸ“‹ Table of Contents

1. [App Overview](#app-overview)
2. [Core Features](#core-features)
3. [Tech Stack & Packages](#tech-stack--packages)
4. [API Keys Required](#api-keys-required)
5. [Architecture Overview (Clean Architecture)](#architecture-overview-clean-architecture)
6. [Data Models](#data-models)
7. [Detailed Feature Breakdown](#detailed-feature-breakdown)
8. [UI/UX Design Specification](#uiux-design-specification)
9. [Algorithm: Sun Position & Seat Scoring](#algorithm-sun-position--seat-scoring)
10. [Implementation Phases](#implementation-phases)
11. [File Structure (Flutter Clean Architecture)](#file-structure-flutter-clean-architecture)
12. [API Integration Details](#api-integration-details)
13. [Edge Cases & Error Handling](#edge-cases--error-handling)

---

## App Overview

**SunRoute** lets a user enter a source and destination, pick a vehicle type (bus, train, 4-seater car, 5+ seater car), choose a departure time, and then:

- See the **exact route** on Google Maps
- See a **sun position overlay** showing where sunlight hits the vehicle at every point along the route
- **Scrub through time** to see how sunlight shifts as the vehicle moves
- View **real-time weather forecasts** (cloudy, rainy, sunny) along the route
- Get **ranked seat recommendations** (1st, 2nd, 3rd preference) based on maximum sun protection + ventilation
- **Visualize the vehicle interior** with a seat map showing sun exposure per seat

---

## Core Features

### Feature 1: Route Input & Planning
- Autocomplete source/destination fields (Google Places API)
- Departure date & time picker
- Vehicle type selector: `Bus (default)` | `Train` | `4-Seater Car` | `5+ Seater Car`
- "Find Best Seat" button

### Feature 2: Route Map with Sun Overlay
- Google Maps showing the full route polyline
- Sun position indicator (azimuth arrow overlay on the map)
- Route segments color-coded by sun exposure side (left/right/top)
- Animated vehicle marker showing current position on time scrub

### Feature 3: Time Scrubber / Timeline Control
- Horizontal slider from departure â†’ arrival time
- Play/pause button for auto-animation
- Speed controls (1x, 2x, 5x, 10x)
- Current time display + vehicle location display
- Tapping any point on the route also updates the scrubber

### Feature 4: Sunlight Projection Visualization
- 2D top-down view of the vehicle using CustomPainter
- Sunlight rays drawn from the correct angle
- Seats highlighted with exposure levels: ðŸ”´ High | ðŸŸ¡ Medium | ðŸŸ¢ Low/None
- Shadow zones from the roof/frame rendered
- Updates in real-time as scrubber moves

### Feature 5: Weather Integration Along Route
- Weather forecast sampled at intervals along the route (OpenWeatherMap 5-day/3-hour forecast)
- Weather icons on the map at key waypoints
- Timeline bar below scrubber showing weather transitions
- Cloud cover percentage affects sun exposure calculation (critical!)

### Feature 6: Seat Recommendation Engine
- Scores every seat based on:
  - Total sun exposure duration (lower = better)
  - Peak sun intensity exposure (lower = better)
  - Ventilation access (window seats with openable windows score higher)
  - Weather-adjusted exposure (cloudy segments reduce penalty)
- Outputs **ranked recommendations**:
  - ðŸ¥‡ **1st Preference**: Best overall seat (area/specific seat)
  - ðŸ¥ˆ **2nd Preference**: Next best alternative
  - ðŸ¥‰ **3rd Preference**: Third option
- Each recommendation includes a reason (e.g., "Left side is shaded for 78% of the journey")

### Feature 7: Vehicle Seat Map (Interactive)
- Tappable seat layout matching the selected vehicle
- Each seat shows a score badge
- Tapping a seat shows its detailed sun exposure breakdown
- Legend for color coding

---

## Tech Stack & Packages

### Flutter Packages (pubspec.yaml dependencies)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Navigation
  go_router: ^14.0.0               # Declarative routing

  # State Management
  flutter_riverpod: ^2.5.0          # State management (or use flutter_bloc if preferred)
  riverpod_annotation: ^2.3.0       # Code generation for Riverpod

  # Networking
  dio: ^5.4.0                       # HTTP client for API calls
  retrofit: ^4.1.0                  # Type-safe HTTP client generator (optional, pairs with Dio)

  # Google Maps
  google_maps_flutter: ^2.6.0       # Google Maps widget
  google_maps_webservice: ^0.0.20   # Directions API, Places API, Geocoding
  flutter_polyline_points: ^2.0.0   # Decode Google polyline to lat/lng

  # Location & Places
  google_places_flutter: ^2.0.9     # Google Places Autocomplete widget
  geolocator: ^12.0.0               # Current device location
  geocoding: ^3.0.0                 # Geocoding (address <-> lat/lng)

  # Sun Calculations
  solar_calculator: ^2.0.0          # Sun position (azimuth, altitude) â€” pure Dart, no API

  # UI & Design
  flutter_animate: ^4.5.0           # Micro-animations
  google_fonts: ^6.2.0              # Google Fonts (Inter, Outfit, etc.)
  shimmer: ^3.0.0                   # Skeleton loading effects
  lottie: ^3.1.0                    # Lottie animations for weather icons

  # Storage
  shared_preferences: ^2.2.0        # Local key-value storage
  flutter_dotenv: ^5.1.0            # .env file for API keys

  # Date/Time
  intl: ^0.19.0                     # Date/time formatting

  # Utils
  equatable: ^2.0.5                 # Value equality for data classes
  dartz: ^0.10.1                    # Functional programming (Either for error handling)
  freezed_annotation: ^2.4.0        # Immutable data classes

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0              # Code generation runner
  freezed: ^2.5.0                   # Code gen for immutable classes
  json_serializable: ^6.7.0         # JSON serialization code gen
  riverpod_generator: ^2.4.0        # Riverpod code gen
  retrofit_generator: ^8.1.0        # Retrofit code gen
```

### Key Technology Choices

| Concern | Choice | Why |
|---|---|---|
| **HTTP Client** | Dio | Interceptors, request cancellation, FormData, better error handling than http |
| **Routing** | GoRouter | Declarative, deep linking, redirects, type-safe routes |
| **State Mgmt** | Riverpod | Compile-safe, testable, no BuildContext dependency for providers |
| **Sun Calc** | solar_calculator | Pure Dart â€” computes azimuth & altitude from lat/lng/timestamp, zero API calls |
| **Maps** | google_maps_flutter | Official Google Maps plugin for Flutter |
| **Data Classes** | Freezed + json_serializable | Immutable, copyWith, JSON serialization, union types |

---

## API Keys Required

### âœ… Already Have

| API | Key | Purpose |
|---|---|---|
| **OpenWeatherMap** | `appid=YOUR_OPENWEATHER_API_KEY` | 5-day/3-hour weather forecast along route |

### âš ï¸ NEED TO GET â€” Google Maps API Key

You need **ONE Google Maps API key** with the following APIs enabled:

| Google API | Purpose |
|---|---|
| **Maps SDK for Android** | Render Google Map in the Flutter app (Android) |
| **Maps SDK for iOS** | Render Google Map in the Flutter app (iOS) |
| **Directions API** | Get route polyline, duration, distance between source & destination |
| **Places API** | Autocomplete for source/destination text fields |
| **Geocoding API** | Convert place names to lat/lng coordinates |

### ðŸ”‘ How to Get a Google Maps API Key

#### Step 1: Create a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Select a project"** â†’ **"New Project"**
3. Name it (e.g., "SunRoute") â†’ Click **"Create"**

#### Step 2: Enable Billing
1. Go to **Billing** in the left sidebar
2. Link a billing account (Google gives **$200/month free credit** â€” more than enough for dev/testing)
3. âš ï¸ Billing MUST be enabled or the API keys won't work

#### Step 3: Enable Required APIs
1. Go to **"APIs & Services" â†’ "Library"**
2. Search for and **Enable** each of these:
   - âœ… Maps SDK for Android
   - âœ… Maps SDK for iOS
   - âœ… Directions API
   - âœ… Places API
   - âœ… Geocoding API

#### Step 4: Create an API Key
1. Go to **"APIs & Services" â†’ "Credentials"**
2. Click **"+ CREATE CREDENTIALS" â†’ "API key"**
3. Copy the generated key
4. (Recommended) Click **"Restrict key"**:
   - For Android: Add your app's SHA-1 fingerprint + package name
   - For iOS: Add your app's bundle ID
   - For APIs: Restrict to only the 5 APIs above

#### Step 5: Add the Key to Your Flutter App

**For Android** â€” Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest ...>
  <application ...>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    ...
  </application>
</manifest>
```

**For iOS** â€” Edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**For Directions/Places/Geocoding API calls (via Dio)** â€” Store in `.env`:
```env
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
```

> **Cost Estimate**: With $200/month free credit, you can make ~40,000 Directions requests, ~100,000 Geocoding requests, and unlimited map loads per month. This is more than enough for development and moderate personal use.

---

## Architecture Overview (Clean Architecture)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  PRESENTATION LAYER                      â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚  Screens  â”‚  â”‚  Widgets     â”‚  â”‚  Providers/       â”‚ â”‚
â”‚  â”‚  (Pages)  â”‚  â”‚  (Components)â”‚  â”‚  Controllers      â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜            â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                  DOMAIN LAYER                            â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚  Entities â”‚  â”‚  Use Cases   â”‚  â”‚  Repository       â”‚ â”‚
â”‚  â”‚           â”‚  â”‚              â”‚  â”‚  Interfaces       â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                  DATA LAYER                              â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚  Models   â”‚  â”‚  Data Sourcesâ”‚  â”‚  Repository       â”‚ â”‚
â”‚  â”‚  (DTOs)   â”‚  â”‚  (Remote)    â”‚  â”‚  Implementations  â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚                                                          â”‚
â”‚  Remote Data Sources:                                    â”‚
â”‚  â”œâ”€â”€ Google Directions API (via Dio)                     â”‚
â”‚  â”œâ”€â”€ Google Places API (via Dio)                         â”‚
â”‚  â”œâ”€â”€ OpenWeatherMap 5-day Forecast API (via Dio)         â”‚
â”‚  â””â”€â”€ Solar Calculator (local, pure Dart)                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### Layer Rules
- **Presentation** â†’ depends on **Domain** only
- **Domain** â†’ depends on **nothing** (pure Dart, no Flutter imports)
- **Data** â†’ depends on **Domain** (implements repository interfaces)
- Dependencies flow inward only

---

## Data Models

### Route Point Entity (sampled every ~1 minute of travel)
```dart
@freezed
class RoutePoint with _$RoutePoint {
  const factory RoutePoint({
    required int index,
    required double lat,
    required double lng,
    required DateTime timestamp,
    required double bearing,         // vehicle heading 0-360Â°
    required double speedKmh,
    required double distanceFromStartKm,
    // Sun data (computed via solar_calculator)
    required double sunAzimuth,      // degrees from North (0-360)
    required double sunAltitude,     // degrees above horizon
    required double sunRelativeAngle,// relative to vehicle heading
    required SunSide sunSide,        // left | right | front | rear | top
    // Weather data
    required WeatherData weather,
  }) = _RoutePoint;
}

enum SunSide { left, right, front, rear, top, frontLeft, frontRight, rearLeft, rearRight }
```

### Weather Data Entity
```dart
@freezed
class WeatherData with _$WeatherData {
  const factory WeatherData({
    required String condition,     // sunny | partly_cloudy | cloudy | overcast | rain | storm
    required int cloudCover,       // 0-100%
    required double temperature,   // Celsius
    required int humidity,         // %
    required double windSpeed,     // m/s
    required String icon,          // OpenWeather icon code
    required String description,
  }) = _WeatherData;
}
```

### Vehicle Layout Entity
```dart
@freezed
class VehicleLayout with _$VehicleLayout {
  const factory VehicleLayout({
    required VehicleType type,
    required String name,
    required int rows,
    required int seatsPerRow,
    required int totalSeats,
    required List<Seat> seatMap,
  }) = _VehicleLayout;
}

enum VehicleType { bus, train, car4, car5plus }

@freezed
class Seat with _$Seat {
  const factory Seat({
    required String id,
    required int row,
    required String column,
    required SeatSide side,      // left | right | middle
    required bool isWindow,
    required bool isAisle,
    required bool hasVentilation,
    required double x,           // position for CustomPainter
    required double y,
    @Default(false) bool isDriver,
  }) = _Seat;
}

enum SeatSide { left, right, middle }
```

### Seat Score Entity
```dart
@freezed
class SeatScore with _$SeatScore {
  const factory SeatScore({
    required String seatId,
    required double totalSunExposureMinutes,
    required double peakExposureIntensity,
    required double avgExposureIntensity,
    required double weatherAdjustedExposure,
    required double ventilationScore,
    required double overallScore,       // 0-100
    required int rank,
    required String recommendation,     // "1st Preference", etc.
    required String reason,
  }) = _SeatScore;
}
```

---

## Detailed Feature Breakdown

### 7.1 Route Input Screen

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  ðŸŒ… SunRoute                         â”‚
â”‚                                      â”‚
â”‚  ðŸ“ From                             â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚ Search source location...      â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â”‚                                      â”‚
â”‚  ðŸ“ To                               â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚ Search destination...          â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â”‚                                      â”‚
â”‚  ðŸ“… Date          ðŸ• Time            â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”        â”‚
â”‚  â”‚ Oct 5    â”‚    â”‚ 10:30 AM â”‚        â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜        â”‚
â”‚                                      â”‚
â”‚  ðŸš— Vehicle Type                     â”‚
â”‚  â”Œâ”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”     â”‚
â”‚  â”‚ ðŸšŒ â”‚ â”‚ ðŸš‚ â”‚ â”‚ ðŸš— â”‚ â”‚ ðŸš™   â”‚     â”‚
â”‚  â”‚Bus âœ“â”‚ â”‚Railâ”‚ â”‚Car4â”‚ â”‚Car5+ â”‚     â”‚
â”‚  â””â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”˜     â”‚
â”‚                                      â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚    ðŸ” Find Best Seat           â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

**Implementation:**
- Use Google Places Autocomplete widget for source/destination
- `showDatePicker()` and `showTimePicker()` for date/time
- `ToggleButtons` or custom chips for vehicle type
- Default: Bus, today, current time + 30 min

### 7.2 Results Screen (Main Screen after search)

**Sections (scrollable or tab-based):**
1. **Map View** â€” Google Map with route polyline + sun overlay + vehicle marker
2. **Time Scrubber** â€” Slider + play controls + weather bar
3. **Vehicle Visualization** â€” CustomPainter 2D top-down vehicle with sun projection
4. **Seat Recommendations** â€” Ranked cards with scores and reasons

### 7.3 Time Scrubber Widget

```
  â˜€ï¸ Sunny    â›… Cloudy   â˜€ï¸ Sunny     ðŸŒ§ï¸ Rain
  |___________|___________|____________|________|
  10:30       11:15       12:00        12:45    13:30
        â–² 11:42 AM â€” Near Tumkur â€” 62 km

  [â—„â—„] [â–¶ Play] [â–ºâ–º]   Speed: [1x] [2x] [5x]
```

**Implementation:**
- `Slider` widget with custom `SliderTheme`
- Weather bar: `CustomPainter` drawing colored segments behind slider
- Play mode: `Timer.periodic` or `AnimationController`
- Shows: current time, nearest location name, km from start

### 7.4 Sunlight Projection (CustomPainter)

Top-down view of the vehicle with sun rays from the correct angle:

```
        â˜€ï¸ Sun (120Â° relative)
         \
          \  â† Sun rays
           \
    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
    â”‚  [A1]  [B1][C1]  [D1] â”‚  â† Row 1
    â”‚  [A2]  [B2][C2]  [D2] â”‚
    â”‚   ðŸŸ¢    ðŸŸ¢  ðŸŸ¡    ðŸ”´  â”‚  â† Color = exposure
    â”‚  ...                   â”‚
    â”‚  [A12] [B12][C12][D12] â”‚  â† Row 12
    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

**Implementation:**
- `CustomPainter` for the vehicle body, seats, and sun rays
- Sun rays: semi-transparent gradient paint from the sun angle
- Each seat painted with fill color based on exposure (greenâ†’yellowâ†’red)
- `GestureDetector` on each seat region for tap-to-inspect
- Repaint when scrubber position changes

### 7.5 Vehicle Layouts (All Types)

#### ðŸšŒ Bus (Default) â€” 49 seats
```
  DRIVER
  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
  â”‚  [1A] [1B]    [1C] [1D]    â”‚  â† Rows 1-12
  â”‚  [2A] [2B]    [2C] [2D]    â”‚  Window seats: A, D
  â”‚  [3A] [3B]    [3C] [3D]    â”‚  Aisle seats: B, C
  â”‚  ...  ...     ...  ...     â”‚
  â”‚  [12A][12B][12C][12D][12E] â”‚  â† Last row: 5 seats
  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
  Ventilation: Window seats have openable windows (higher score)
```

#### ðŸš‚ Train (Single Normal Coach) â€” 72 seats
```
  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
  â”‚  [1A][1B]   AISLE   [1C][1D]       â”‚
  â”‚  [2A][2B]           [2C][2D]       â”‚
  â”‚  â”€â”€â”€ table â”€â”€â”€  â”€â”€â”€ table â”€â”€â”€     â”‚
  â”‚  [3A][3B]           [3C][3D]       â”‚
  â”‚  [4A][4B]           [4C][4D]       â”‚
  â”‚  ... repeats for 18 rows ...       â”‚
  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
  Window seats: A, D | Aisle seats: B, C
  Ventilation: AC only (uniform ventilation score)
  Note: Just one standard coach layout
```

#### ðŸš— 4-Seater Car â€” 3 choosable seats
```
  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
  â”‚ DRIVER  [Pass]â”‚  â† Front row
  â”‚  [RL]   [RR]  â”‚  â† Rear row
  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
  Ventilation: All have windows
```

#### ðŸš™ 5+ Seater Car (SUV/MPV) â€” 4-6 choosable seats
```
  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
  â”‚ DRIVER  [Pass]â”‚  â† Row 1
  â”‚ [RL] [RM] [RR]â”‚  â† Row 2 (middle has no window)
  â”‚   [3L]  [3R]  â”‚  â† Row 3 (if 7-seater)
  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
  Ventilation: Row 3 has worst ventilation
```

### 7.6 Weather Timeline

Weather data fetched at **waypoints along the route** (every ~15-20 km or ~15 min of travel).

**Color bar under the scrubber:**
- â˜€ï¸ Yellow/Orange = Sunny (cloud cover < 20%)
- â›… Light gray = Partly Cloudy (20-60%)
- â˜ï¸ Dark gray = Overcast (60-90%)
- ðŸŒ§ï¸ Blue = Rain
- â›ˆï¸ Dark blue = Storm/Thunderstorm
- ðŸŒ«ï¸ Light white = Fog/Mist

**Weather Impact on Seat Scoring:**
- Overcast/rainy â†’ sun exposure â‰ˆ 0 â†’ no penalty to any seat
- Partly cloudy â†’ reduce exposure by cloud cover %
- A "bad" seat on a clear day may be "fine" if forecast shows clouds

### 7.7 Seat Recommendation Cards

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  ðŸ† SEAT RECOMMENDATIONS                 â”‚
â”‚                                           â”‚
â”‚  ðŸ¥‡ 1st Preference: Seats 3A-7A          â”‚
â”‚     (Left Window) â€” Score: 92/100         â”‚
â”‚     "Left side shaded for 82% of journey. â”‚
â”‚      Sun is mostly from the right."       â”‚
â”‚                                           â”‚
â”‚  ðŸ¥ˆ 2nd Preference: Seats 3B-7B          â”‚
â”‚     (Left Aisle) â€” Score: 85/100          â”‚
â”‚     "Left-aisle gets partial shade.       â”‚
â”‚      Less ventilation but protected."     â”‚
â”‚                                           â”‚
â”‚  ðŸ¥‰ 3rd Preference: Seats 8D-10D         â”‚
â”‚     (Right Window, Rear) â€” Score: 74/100  â”‚
â”‚     "Rear section benefits from afternoon â”‚
â”‚      cloud cover. Good window airflow."   â”‚
â”‚                                           â”‚
â”‚  âš ï¸ Avoid: Seats 1D-5D (Right, Front)    â”‚
â”‚     Score: 31/100                         â”‚
â”‚     "Direct sun for 71% of journey."      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## UI/UX Design Specification

### App Theme (Dark Mode Primary)

```dart
// lib/core/theme/app_theme.dart

class AppColors {
  static const bgPrimary = Color(0xFF0F1117);
  static const bgSecondary = Color(0xFF1A1D27);
  static const bgCard = Color(0xFF232734);
  static const textPrimary = Color(0xFFE8EAED);
  static const textSecondary = Color(0xFF9AA0B0);
  static const accentSun = Color(0xFFFFB830);
  static const accentShade = Color(0xFF4A9EFF);
  static const accentHot = Color(0xFFFF6B6B);
  static const accentCool = Color(0xFF51CF66);
  static const accentRain = Color(0xFF748FFC);

  static const gradientSun = LinearGradient(
    colors: [Color(0xFFFFB830), Color(0xFFFF6B6B)],
  );
  static const gradientShade = LinearGradient(
    colors: [Color(0xFF4A9EFF), Color(0xFF51CF66)],
  );
}
```

### Typography
- Use **Google Fonts**: `Inter` (primary), `Outfit` (headings)
- Loaded via `google_fonts` package

### Micro-Animations (via flutter_animate)
- Sun rays pulse gently on the vehicle CustomPainter
- Seat colors transition smoothly on scrubber change
- Weather icons have subtle float animation
- Vehicle marker on map has heading trail
- Score badges count-up animation on load
- Cards use glassmorphism with `BackdropFilter`

### Screen Flow (GoRouter)

```dart
GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const RouteInputScreen()),
    GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
    GoRoute(path: '/seat/:seatId', builder: (_, state) => SeatDetailScreen(
      seatId: state.pathParameters['seatId']!,
    )),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
```

---

## Algorithm: Sun Position & Seat Scoring

### Step-by-Step Pipeline

```
INPUT: source, destination, departureTime, vehicleType

STEP 1: FETCH ROUTE
  â†’ Google Directions API (via Dio)
  â†’ Get: polyline, total duration, total distance, step-by-step legs
  â†’ Decode polyline into List<LatLng> using flutter_polyline_points
  
STEP 2: SAMPLE ROUTE POINTS
  â†’ Sample every 1 minute of estimated travel time
  â†’ For each sample point:
    - Interpolate lat/lng from polyline
    - Compute timestamp = departureTime + elapsed minutes
    - Compute bearing (heading) from current to next point using geolocator
    
STEP 3: COMPUTE SUN POSITIONS
  â†’ For each route point, using solar_calculator package:
    - sunPosition = SolarCalculator(dateTime, lat, lng)
    - sunAzimuth = position.azimuth (degrees from North, 0-360)
    - sunAltitude = position.altitude (degrees above horizon)
    - If sunAltitude < 0 â†’ nighttime, no exposure
    
STEP 4: COMPUTE RELATIVE SUN ANGLE
  â†’ For each route point:
    - relativeSunAngle = (sunAzimuth - vehicleBearing + 360) % 360
    - Map to side:
      - 350Â°-10Â°   â†’ FRONT
      - 10Â°-80Â°    â†’ FRONT-RIGHT
      - 80Â°-100Â°   â†’ RIGHT (direct)
      - 100Â°-170Â°  â†’ REAR-RIGHT
      - 170Â°-190Â°  â†’ REAR
      - 190Â°-260Â°  â†’ REAR-LEFT
      - 260Â°-280Â°  â†’ LEFT (direct)
      - 280Â°-350Â°  â†’ FRONT-LEFT

STEP 5: FETCH WEATHER
  â†’ Sample weather at waypoints (every ~15km)
  â†’ OpenWeatherMap 5-day/3-hour forecast API for each waypoint
  â†’ Endpoint: api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&units=metric&appid=YOUR_OPENWEATHER_API_KEY
  â†’ Extract: cloudCover, condition, temperature
  â†’ Interpolate between 3-hour forecast slots for finer granularity

STEP 6: COMPUTE SEAT EXPOSURE
  â†’ For each seat in the vehicle layout:
    â†’ For each route point:
      - Check if seat is on the sun-exposed side
      - Raw exposure intensity:
        * Window seat on sun-side: intensity = cos(sunAltitude) Ã— 1.0
        * Aisle seat on sun-side: intensity = cos(sunAltitude) Ã— 0.4
        * Opposite side: intensity = 0.05 (ambient reflected light)
        * Front/rear angles: graduated intensity
      - Apply weather modifier:
        * adjustedIntensity = rawIntensity Ã— (1 - cloudCover/100 Ã— 0.85)
      - If sunAltitude > 65Â°: reduce by 70% (roof blocks most light)
      - Accumulate: seat.totalExposure += adjustedIntensity
    â†’ Compute averages and peaks

STEP 7: COMPUTE VENTILATION SCORE
  â†’ Based on vehicle type and seat position:
    - Bus window seat: 0.9
    - Bus aisle seat: 0.5
    - Train (all AC): 0.6 uniform
    - Car window seat: 0.85
    - Car middle seat: 0.3
    - Back row / 3rd row: reduce by 0.2

STEP 8: COMPUTE OVERALL SCORE
  â†’ overallScore = (sunProtectionScore Ã— 0.65) + (ventilationScore Ã— 0.20) + (comfortBonus Ã— 0.15)
  â†’ sunProtectionScore = 100 - (normalizedExposure Ã— 100)
  â†’ comfortBonus:
    - Window seat: +5 (view)
    - Front of vehicle: +3 (less bumpy)
    - Near exit: +2 (convenience)

STEP 9: RANK & RECOMMEND
  â†’ Sort seats by overallScore descending
  â†’ Group adjacent high-scoring seats into "zones"
  â†’ Output top 3 zones as 1st, 2nd, 3rd preference
  â†’ Output worst zone as "Avoid"
```

---

## Implementation Phases

### Phase 1: Foundation & Project Setup
- [ ] Add all packages to `pubspec.yaml` & run `flutter pub get`
- [ ] Set up `.env` file with API keys
- [ ] Create clean architecture folder structure
- [ ] Set up GoRouter navigation
- [ ] Set up Riverpod providers
- [ ] Create app theme (dark mode, colors, typography)
- [ ] Create Route Input Screen UI (source, destination, date, time, vehicle selector)

### Phase 2: Route Processing & Map
- [ ] Integrate Google Places Autocomplete for source/destination
- [ ] Fetch route via Google Directions API using Dio
- [ ] Decode polyline to lat/lng points
- [ ] Display route on Google Maps widget
- [ ] Sample route points at 1-minute intervals
- [ ] Compute bearing at each point

### Phase 3: Sun Engine
- [ ] Integrate `solar_calculator` package
- [ ] Compute sun azimuth & altitude at each route point
- [ ] Compute relative sun angle vs vehicle heading
- [ ] Determine sun-side for each segment
- [ ] Color-code route polyline on map by sun-side

### Phase 4: Weather Integration
- [ ] Fetch 5-day/3-hour forecast from OpenWeatherMap via Dio
- [ ] Sample weather for waypoints along route
- [ ] Build weather timeline data
- [ ] Render weather bar widget (CustomPainter) below time scrubber
- [ ] Integrate cloud cover into exposure calculations

### Phase 5: Time Scrubber & Animation
- [ ] Build time scrubber Slider widget with custom theme
- [ ] Animate vehicle marker on map with scrubber
- [ ] Update sun overlay in real-time
- [ ] Play/pause & speed controls
- [ ] Current time + location info

### Phase 6: Vehicle Visualization (CustomPainter)
- [ ] Create seat layout configs for all 4 vehicle types
- [ ] Build `VehiclePainter` CustomPainter (bus, train, car4, car5+)
- [ ] Render sunlight projection overlay
- [ ] Color-code seats by exposure level
- [ ] Tap-to-select seats with GestureDetector
- [ ] Animate sun angle changes on scrubber movement

### Phase 7: Seat Scoring & Recommendations
- [ ] Implement scoring algorithm in domain layer
- [ ] Compute scores for all seats
- [ ] Rank & group into preference zones
- [ ] Build recommendation cards UI
- [ ] Per-seat detail bottom sheet with exposure breakdown

### Phase 8: Polish & Edge Cases
- [ ] Night travel handling
- [ ] Loading states with Shimmer
- [ ] Error handling & retry logic
- [ ] Responsive layout (tablet support)
- [ ] Share/export results
- [ ] Settings screen (API key management)

---

## File Structure (Flutter Clean Architecture)

```
lib/
â”œâ”€â”€ main.dart                           # App entry point
â”œâ”€â”€ app.dart                            # MaterialApp + GoRouter setup
â”‚
â”œâ”€â”€ core/                               # Shared across all features
â”‚   â”œâ”€â”€ constants/
â”‚   â”‚   â”œâ”€â”€ api_constants.dart          # API base URLs, endpoints
â”‚   â”‚   â””â”€â”€ app_constants.dart          # App-wide constants
â”‚   â”œâ”€â”€ error/
â”‚   â”‚   â”œâ”€â”€ exceptions.dart             # Custom exceptions
â”‚   â”‚   â””â”€â”€ failures.dart               # Failure classes (for Either)
â”‚   â”œâ”€â”€ network/
â”‚   â”‚   â”œâ”€â”€ dio_client.dart             # Dio setup, interceptors, base config
â”‚   â”‚   â””â”€â”€ network_info.dart           # Connectivity checker
â”‚   â”œâ”€â”€ theme/
â”‚   â”‚   â”œâ”€â”€ app_theme.dart              # ThemeData, dark/light mode
â”‚   â”‚   â”œâ”€â”€ app_colors.dart             # Color constants
â”‚   â”‚   â””â”€â”€ app_text_styles.dart        # TextStyle presets
â”‚   â”œâ”€â”€ router/
â”‚   â”‚   â””â”€â”€ app_router.dart             # GoRouter configuration
â”‚   â”œâ”€â”€ utils/
â”‚   â”‚   â”œâ”€â”€ geo_utils.dart              # Bearing, distance, interpolation
â”‚   â”‚   â”œâ”€â”€ sun_utils.dart              # Sun position helpers (wraps solar_calculator)
â”‚   â”‚   â”œâ”€â”€ color_utils.dart            # Exposure â†’ Color mapping
â”‚   â”‚   â”œâ”€â”€ time_utils.dart             # Date/time formatting
â”‚   â”‚   â””â”€â”€ polyline_decoder.dart       # Google polyline decoding
â”‚   â””â”€â”€ widgets/                        # Shared/reusable widgets
â”‚       â”œâ”€â”€ loading_widget.dart         # Shimmer loading
â”‚       â”œâ”€â”€ error_widget.dart           # Error display
â”‚       â””â”€â”€ glass_card.dart             # Glassmorphism card
â”‚
â”œâ”€â”€ features/
â”‚   â”œâ”€â”€ route_input/                    # Feature: Route planning input
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ datasources/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ places_remote_data_source.dart   # Google Places API
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ directions_remote_data_source.dart # Google Directions API
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ place_model.dart
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ directions_model.dart
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ route_model.dart
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ route_repository_impl.dart
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ place.dart
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ route_info.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ route_repository.dart           # Abstract
â”‚   â”‚   â”‚   â””â”€â”€ usecases/
â”‚   â”‚   â”‚       â”œâ”€â”€ search_places.dart
â”‚   â”‚   â”‚       â””â”€â”€ get_route.dart
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚       â”‚   â””â”€â”€ route_input_provider.dart
â”‚   â”‚       â”œâ”€â”€ screens/
â”‚   â”‚       â”‚   â””â”€â”€ route_input_screen.dart
â”‚   â”‚       â””â”€â”€ widgets/
â”‚   â”‚           â”œâ”€â”€ place_search_field.dart
â”‚   â”‚           â”œâ”€â”€ date_time_picker.dart
â”‚   â”‚           â””â”€â”€ vehicle_type_selector.dart
â”‚   â”‚
â”‚   â”œâ”€â”€ weather/                        # Feature: Weather along route
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ datasources/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ weather_remote_data_source.dart  # OpenWeatherMap API
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ weather_forecast_model.dart
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ weather_repository_impl.dart
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ weather_data.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ weather_repository.dart          # Abstract
â”‚   â”‚   â”‚   â””â”€â”€ usecases/
â”‚   â”‚   â”‚       â””â”€â”€ get_weather_along_route.dart
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚       â”‚   â””â”€â”€ weather_provider.dart
â”‚   â”‚       â””â”€â”€ widgets/
â”‚   â”‚           â”œâ”€â”€ weather_bar.dart                 # Timeline weather strip
â”‚   â”‚           â””â”€â”€ weather_icon_widget.dart
â”‚   â”‚
â”‚   â”œâ”€â”€ sun_analysis/                   # Feature: Sun position calculations
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ datasources/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ sun_calculator_data_source.dart  # Wraps solar_calculator
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ sun_repository_impl.dart
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ route_point.dart
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ sun_position.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ sun_repository.dart              # Abstract
â”‚   â”‚   â”‚   â””â”€â”€ usecases/
â”‚   â”‚   â”‚       â””â”€â”€ compute_sun_positions.dart
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚       â”‚   â””â”€â”€ sun_analysis_provider.dart
â”‚   â”‚       â””â”€â”€ widgets/
â”‚   â”‚           â””â”€â”€ sun_direction_overlay.dart        # Map overlay widget
â”‚   â”‚
â”‚   â”œâ”€â”€ seat_scoring/                   # Feature: Seat analysis & recommendations
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ datasources/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ vehicle_layout_data_source.dart  # Static vehicle configs
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ seat_repository_impl.dart
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ seat.dart
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ seat_score.dart
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ vehicle_layout.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ seat_repository.dart             # Abstract
â”‚   â”‚   â”‚   â””â”€â”€ usecases/
â”‚   â”‚   â”‚       â”œâ”€â”€ compute_seat_scores.dart
â”‚   â”‚   â”‚       â””â”€â”€ get_seat_recommendations.dart
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚       â”‚   â””â”€â”€ seat_scoring_provider.dart
â”‚   â”‚       â”œâ”€â”€ screens/
â”‚   â”‚       â”‚   â””â”€â”€ seat_detail_screen.dart
â”‚   â”‚       â””â”€â”€ widgets/
â”‚   â”‚           â”œâ”€â”€ vehicle_painter.dart              # CustomPainter for vehicle
â”‚   â”‚           â”œâ”€â”€ seat_map_widget.dart              # Interactive seat map
â”‚   â”‚           â””â”€â”€ recommendation_card.dart          # Ranked seat card
â”‚   â”‚
â”‚   â””â”€â”€ results/                        # Feature: Combined results view
â”‚       â””â”€â”€ presentation/
â”‚           â”œâ”€â”€ providers/
â”‚           â”‚   â””â”€â”€ results_provider.dart             # Orchestrates all features
â”‚           â”œâ”€â”€ screens/
â”‚           â”‚   â””â”€â”€ results_screen.dart
â”‚           â””â”€â”€ widgets/
â”‚               â”œâ”€â”€ route_map_widget.dart             # Google Map with overlays
â”‚               â”œâ”€â”€ time_scrubber_widget.dart          # Timeline slider
â”‚               â””â”€â”€ play_controls_widget.dart          # Play/pause/speed
â”‚
â”œâ”€â”€ config/                             # Vehicle layout configurations
â”‚   â”œâ”€â”€ bus_layout.dart                 # Bus seat positions & properties
â”‚   â”œâ”€â”€ train_layout.dart              # Train coach seat positions
â”‚   â”œâ”€â”€ car4_layout.dart               # 4-seater car positions
â”‚   â””â”€â”€ car5_layout.dart               # 5+ seater car positions
â”‚
â””â”€â”€ injection.dart                      # Dependency injection setup (Riverpod)
```

### Other Project Files
```
travel_app/
â”œâ”€â”€ .env                                # API keys (gitignored)
â”œâ”€â”€ .env.example                        # Template with placeholder keys
â”œâ”€â”€ pubspec.yaml                        # Dependencies
â”œâ”€â”€ analysis_options.yaml
â”œâ”€â”€ PLAN.md                             # This file
â”œâ”€â”€ android/
â”‚   â””â”€â”€ app/src/main/AndroidManifest.xml  # Google Maps API key here
â”œâ”€â”€ ios/
â”‚   â””â”€â”€ Runner/AppDelegate.swift          # Google Maps API key here
â””â”€â”€ lib/                                  # (see above)
```

---

## API Integration Details

### OpenWeatherMap 5-Day/3-Hour Forecast API

**Endpoint:**
```
GET https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&units=metric&appid=YOUR_OPENWEATHER_API_KEY
```

**Parameters:**
| Parameter | Required | Description |
|---|---|---|
| `lat` | Yes | Latitude of the waypoint |
| `lon` | Yes | Longitude of the waypoint |
| `appid` | Yes | Your API key: `YOUR_OPENWEATHER_API_KEY` |
| `units` | Optional | `metric` for Celsius, `imperial` for Fahrenheit (default: Kelvin) |
| `lang` | Optional | Language code for description (e.g., `en`, `hi`) |
| `cnt` | Optional | Limit number of timestamps returned |

**Response Fields Used:**
```json
{
  "list": [
    {
      "dt": 1696406400,                    // Forecast timestamp (Unix UTC)
      "main": {
        "temp": 32.5,                      // Temperature (Â°C with metric)
        "humidity": 60                     // Humidity %
      },
      "weather": [
        {
          "id": 801,                        // Weather condition code
          "main": "Clouds",                 // Group (Rain, Snow, Clouds, etc.)
          "description": "few clouds",      // Description
          "icon": "02d"                     // Icon code
        }
      ],
      "clouds": { "all": 15 },             // Cloud cover % (CRITICAL for sun calc)
      "wind": {
        "speed": 3.5,                      // Wind speed m/s
        "deg": 180                         // Wind direction
      },
      "visibility": 10000,                 // Visibility in metres
      "pop": 0.1,                          // Probability of precipitation (0-1)
      "dt_txt": "2026-10-05 10:00:00"      // Human-readable timestamp
    }
  ],
  "city": {
    "sunrise": 1696381200,                 // Sunrise (Unix UTC)
    "sunset": 1696424400                   // Sunset (Unix UTC)
  }
}
```

**Dart Implementation (Dio):**
```dart
// lib/features/weather/data/datasources/weather_remote_data_source.dart

class WeatherRemoteDataSource {
  final Dio _dio;
  
  WeatherRemoteDataSource(this._dio);
  
  Future<WeatherForecastModel> getForecast({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get(
      'https://api.openweathermap.org/data/2.5/forecast',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'units': 'metric',
        'appid': 'YOUR_OPENWEATHER_API_KEY',
      },
    );
    return WeatherForecastModel.fromJson(response.data);
  }
}
```

**Weather Icon URL:**
```
https://openweathermap.org/img/wn/{icon}@2x.png
```
Example: `https://openweathermap.org/img/wn/02d@2x.png`

### Google Directions API

**Endpoint:**
```
GET https://maps.googleapis.com/maps/api/directions/json?origin={origin}&destination={destination}&key={API_KEY}
```

**Dart Implementation (Dio):**
```dart
// lib/features/route_input/data/datasources/directions_remote_data_source.dart

class DirectionsRemoteDataSource {
  final Dio _dio;
  
  DirectionsRemoteDataSource(this._dio);
  
  Future<DirectionsModel> getDirections({
    required String origin,
    required String destination,
    required DateTime departureTime,
  }) async {
    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/directions/json',
      queryParameters: {
        'origin': origin,
        'destination': destination,
        'departure_time': departureTime.millisecondsSinceEpoch ~/ 1000,
        'key': dotenv.env['GOOGLE_MAPS_API_KEY'],
      },
    );
    return DirectionsModel.fromJson(response.data);
  }
}
```

### Sun Calculator (Local â€” No API)

```dart
// lib/core/utils/sun_utils.dart
import 'package:solar_calculator/solar_calculator.dart';

class SunUtils {
  static SunPosition getSunPosition(DateTime dateTime, double lat, double lng) {
    final instant = Instant(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hour: dateTime.hour,
      timeZoneOffset: dateTime.timeZoneOffset.inHours.toDouble(),
    );
    final calc = SolarCalculator(instant, lat, lng);
    
    return SunPosition(
      azimuth: calc.sunAzimuth,      // degrees from North (0-360)
      altitude: calc.sunElevation,   // degrees above horizon
    );
  }
}
```

---

## Edge Cases & Error Handling

| Scenario | Handling |
|---|---|
| **Night travel** (sun below horizon) | Show "No sun exposure" for all seats. Rank by ventilation & comfort only. |
| **Sunrise/sunset during journey** | Handled by per-minute sampling. Highlight transition in timeline. |
| **Very short route** (< 10 min) | Reduce sampling interval to 30 seconds. Simplified recommendation. |
| **Very long route** (> 12 hours) | Sample every 2-3 min. Paginate weather calls. Warn about forecast accuracy. |
| **No route found** | Show SnackBar with error + retry button. |
| **Weather API rate limit** | Cache responses with shared_preferences. Show "weather unavailable" state. |
| **Weather forecast > 5 days out** | OpenWeather free tier only covers 5 days. Show warning if departure > 5 days away. |
| **Curved/winding road** | Captured by per-minute sampling. Average exposure over segments. |
| **Tunnels/overpasses** | Ignore for MVP. Could use elevation data in future. |
| **No internet** | Show cached results if available, else error screen with retry. |
| **Google Maps API key missing** | Show setup instructions screen (deep link to settings). |
| **Invalid date/time** | Validate departure is in the future and within 5-day forecast window. |
| **Opposite hemisphere** | `solar_calculator` handles automatically. Sun from north in southern hemisphere. |

---

## Key Dependencies Summary

| Package | Purpose | API Key? |
|---|---|---|
| `dio` | HTTP client for all API calls | â€” |
| `go_router` | Declarative navigation | â€” |
| `flutter_riverpod` | State management | â€” |
| `google_maps_flutter` | Map widget | Google Maps API Key |
| `google_maps_webservice` | Directions/Places/Geocoding API | Google Maps API Key |
| `flutter_polyline_points` | Decode polyline | â€” |
| `solar_calculator` | Sun azimuth/altitude (pure Dart) | â€” |
| `freezed` + `json_serializable` | Immutable data classes + JSON | â€” |
| `flutter_dotenv` | Load .env API keys | â€” |
| `flutter_animate` | Micro-animations | â€” |
| `google_fonts` | Custom typography | â€” |
| `shimmer` | Skeleton loading | â€” |
| `intl` | Date/time formatting | â€” |

---

## Summary

This plan covers a full-featured **SunRoute** Flutter mobile app that:

1. âœ… Takes source/destination with Google Places autocomplete
2. âœ… Shows exact route on Google Maps with sun direction overlay
3. âœ… Computes sun position at every point using `solar_calculator` (no API)
4. âœ… Provides an interactive time scrubber to visualize sun at any moment
5. âœ… Supports 4 vehicle types (bus, train coach, 4-seater car, 5+ seater car)
6. âœ… Integrates OpenWeatherMap 5-day/3-hour weather forecasts
7. âœ… Scores every seat on sun protection + ventilation
8. âœ… Recommends top 3 seat preferences with reasons
9. âœ… Follows Flutter clean architecture (data/domain/presentation layers)
10. âœ… Uses Dio, GoRouter, Riverpod, Freezed â€” all best-practice Flutter packages

### API Keys Status
- âœ… **OpenWeatherMap**: `YOUR_OPENWEATHER_API_KEY` (have it)
- âš ï¸ **Google Maps API Key**: NEEDED â€” follow the [setup guide above](#-how-to-get-a-google-maps-api-key)

**Estimated implementation time**: 5-7 days for a skilled Flutter developer, or ~3-4 days with AI assistance.

