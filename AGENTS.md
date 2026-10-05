# AGENTS.md — SunRoute Project Memory

This file is the working memory for AI agents and contributors. Update it when implementation or project decisions change. The product plan is `PLAN.md`; this file records the observed implementation, decisions, and remaining gaps as reviewed on 2026-10-05.

## Project at a glance

- **Product:** SunRoute (installed app name: **Travel Where**), a Flutter app that analyzes sunlight along a planned journey and recommends where to sit.
- **Package name:** `travel_app` (`pubspec.yaml`).
- **SDK:** Dart `^3.13.2` (see `pubspec.yaml`).
- **Main flow:** route input → route retrieval → timed route sampling and sun calculation → weather enrichment → seat scoring and recommendation → interactive results/map/seat detail.
- **Current architecture:** feature-oriented folders with domain/data/presentation separation in most features, shared code in `lib/core`, static layouts in `lib/config`, and Riverpod providers wired in `lib/injection.dart`.
- **Review basis:** static inspection on 2026-10-05, updated the same day after the Google Maps switch, package-id changes and picker fixes (see "UI notes" for what was actually run).

## Current implementation status

| Planned feature | Status | Observed implementation and gaps |
|---|---|---|
| Route input and planning | Implemented, with differences | Origin/destination search uses Google Places API (New), with place details and session tokens. Departure date/time picker, bus/train/car vehicle selector, validation, swap, sample trips, and persisted recent trips/places are present. The plan's future/forecast-window validation is not fully enforced at submit time. |
| Route map and sun overlay | Implemented | Android/iOS use `google_maps_flutter` with a JSON dark style (`lib/core/constants/map_styles.dart`) and bitmap markers (`map/map_marker_bitmaps.dart`). Web/desktop, or builds with no Google key, fall back to `flutter_map` with keyless OpenStreetMap tiles darkened via `darkModeTileBuilder`. The switch is `useGoogleMaps` in `results/presentation/widgets/route_map_widget.dart`; shared route colouring and tap lookup live in `map/route_map_shared.dart`. Route segments are colored by sun side/intensity; start/end, weather waypoints, and current vehicle marker are shown. Tapping near a sampled route point seeks the timeline. The vehicle marker follows the sun and optional map-follow controls exist. |
| Time scrubber and playback | Implemented | Timeline seeks across the journey and playback has pause/play and selectable speed controls. The map marker and dependent visualizations use an interpolated journey frame. |
| Sunlight/vehicle visualization | Implemented, visualization differs from plan | Seat layouts are custom-painted and update with the current frame; live exposure and overall score color modes, highlights, labels, and a sun indicator/rays are present. `VehiclePainter` is the main drawing implementation. The implementation is a stylized seat map, not a physical roof/frame shadow simulation. |
| Weather along route | Implemented, with forecast limits | OpenWeather 5-day/3-hour forecasts are requested at sampled route waypoints (about 20 km spacing, capped by app constants); forecast data is attached to route samples and cloud/weather reduces sunlight. Map chips, weather timeline/waypoint UI, cache, stale-cache fallback, unavailable and beyond-forecast states are present. Forecasts outside provider coverage have no usable weather. |
| Seat scoring and top recommendations | Implemented | Every passenger seat is scored using sun exposure, peak intensity, weather adjustment, ventilation, and comfort. Recommendations group suitable adjacent seats/zones, show up to three ranked preferences and possibly an avoid zone, and provide reasons. Seat detail includes weighted breakdown and an exposure chart. |
| Interactive vehicle seat map | Implemented | Bus, train, 4-seat car, and 5+ seat car layouts are defined in `lib/config/`. Seats can be selected and linked from recommendations; detail view and color legend are present. Driver position is configurable in Settings. |

Overall: all seven high-level user-facing features in `PLAN.md` have corresponding implementation. Treat that as **feature coverage**, not exact plan compliance: see the differences and known gaps below.

## Key implementation differences from `PLAN.md`

- Maps: `google_maps_flutter` on Android/iOS; `flutter_map` + OpenStreetMap tiles as the web/desktop fallback. CARTO was dropped on 2026-10-05 because its basemaps now require an API key (tiles showed an "API KEY REQUIRED" watermark).
- Places use Google Places API (New). Routing tries Google Routes API, then falls back to OSRM when unavailable/rejected. The plan describes legacy Directions API and does not mention this fallback.
- Sun calculation is a local NOAA-style implementation (`SunCalculatorDataSource` / `SunUtils`), rather than the planned `solar_calculator` package.
- `pubspec.yaml` currently includes Riverpod, GoRouter, Dio, `google_maps_flutter`, `flutter_map`, `latlong2`, animation/fonts/shimmer, SharedPreferences, dotenv, intl, Equatable, and `share_plus`. Planned Retrofit, Freezed, JSON codegen, Places webservice package, `solar_calculator`, and several others are not current dependencies. `google_fonts` is pinned to 8.x because 9.x builds on the separate `material_ui` package, whose `TextTheme` is incompatible with the SDK `flutter/material.dart` used everywhere else.
- Implemented score includes comfort in addition to sun protection and ventilation. Settings also include driver position and API key overrides.
- Architecture is feature-oriented and layered in many features, but some orchestration/UI state crosses features via providers. Avoid assuming a strict Clean Architecture boundary everywhere.

## Source map

- App entry and shell: `lib/main.dart`, `lib/app.dart`
- Dependency/provider wiring: `lib/injection.dart`
- Routes: `lib/core/router/app_router.dart`
- Shared constants, API URLs, errors, networking, storage, theme, and geo/time helpers: `lib/core/`
- Route input, Google Places, route retrieval, and history: `lib/features/route_input/`
- Route point sampling, sun positions, and journey stats: `lib/features/sun_analysis/`
- Weather API/models/cache/waypoints/widgets: `lib/features/weather/`
- Vehicle layouts, seat scoring/recommendations, seat map and seat detail: `lib/features/seat_scoring/` and `lib/config/`
- Cross-feature analysis orchestration, playback, results map and scrubber: `lib/features/results/`
- API key overrides, driver position, cache/history controls: `lib/features/settings/`
- Existing tests: `test/widget_test.dart` (despite the filename, contains utility/domain tests for sun, geometry, sampling, scoring, layouts, and weather parsing).

## Data flow and important behavior

1. `RouteInputScreen` validates selections, persists a recent trip, invokes `tripAnalysisProvider`, then opens `/results`.
2. `TripAnalysisNotifier` calls route retrieval, `ComputeSunPositions`, `GetWeatherAlongRoute`, seat layout/scoring, and `GetSeatRecommendations` in order. It tracks loading stages, stale runs, retry, success, and failure.
3. Route samples are approximately one minute apart; short routes use 30 seconds, long journeys use 2–3 minutes, and sampling is capped around 900 points. Route geometry and duration are interpolated to calculate position, heading, speed, and timestamp.
4. Sun positions are computed locally for each point. Weather enriches points when available. Seat scores use exposure over the journey and weather/cloud reduction.
5. `JourneyFrame` interpolates state for the scrubber and drives the map marker, current weather/sun display, and live seat exposure.
6. Weather responses are cached in memory and SharedPreferences; the repository tries stale cached data after a fetch failure. Settings can clear the cache.

## Configuration and credentials

- `.env.example` contains placeholder names for `GOOGLE_MAPS_API_KEY` and `OPENWEATHER_API_KEY`.
- `lib/core/config/env.dart` reads those names. Settings supports local key overrides and connectivity tests. Never copy key values into this file, commits, logs, or examples.
- `.env` exists locally and is listed in `pubspec.yaml` assets; do not read or disclose its contents. Check `.gitignore` before changing credential handling.
- **Credential cleanup:** `PLAN.md` currently embeds a literal OpenWeather API key in multiple examples. Treat that key as exposed: rotate/revoke it with the provider and remove literals from the plan, replacing them with placeholders. Do not repeat the value in docs or chat.
- Google Maps SDK key injection (no key literals in tracked files):
  - Android: `android/app/build.gradle.kts` reads `GOOGLE_MAPS_API_KEY` from the project `.env` (fallback `MAPS_API_KEY` in `android/local.properties`) into the `${MAPS_API_KEY}` manifest placeholder.
  - iOS: `ios/Flutter/Secrets.xcconfig` (gitignored; template `Secrets.xcconfig.example`) → `GMSApiKey` in `Info.plist` → `GMSServices.provideAPIKey` in `AppDelegate.swift`.
  - The Settings key override affects Dart REST calls only, not the native map SDK.
- App-restricted keys: `MainActivity.kt` and `AppDelegate.swift` expose a `sunroute/app_identity` channel (package + signing SHA-1, or bundle id). `AppIdentity` / `GoogleIdentityInterceptor` (`lib/core/network/app_identity.dart`) add `X-Android-Package`/`X-Android-Cert` or `X-Ios-Bundle-Identifier` to `*.googleapis.com` requests. Web and desktop send no identity, so an Android/iOS-restricted key will fail there.
- App identifiers (updated 2026-10-05):
  - Android: `applicationId`/`namespace` `com.travel_app`; `MainActivity` lives in `android/app/src/main/kotlin/com/travel_app/` (must match, or launch crashes with ClassNotFound).
  - iOS/macOS: bundle id `com.travelApp` (`project.pbxproj`, `macos/Runner/Configs/AppInfo.xcconfig`); tests use `com.travelApp.RunnerTests`. Apple bundle ids cannot contain underscores, so `com.travel_app` is not valid there. Use `com.travelApp` when restricting the Google key to the iOS app.
  - Linux `APPLICATION_ID` is `com.travel_app`; Windows `Runner.rc` company/copyright say SunRoute.
  - Dart package name stays `travel_app` (imports use `package:travel_app/...`).
  - `AppConstants.packageName` (`com.travel_app`) is the user agent for OSM tile requests.

## App name and icon (2026-10-05)

- OS-visible name is **Travel Where**: Android `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, web `<title>`/`manifest.json`, Windows window title + `Runner.rc` FileDescription/ProductName, Linux GTK titles, macOS `PRODUCT_NAME`, and `AppConstants.appName` (MaterialApp title, shown in Android recents). The in-app brand text ("SunRoute" in `RouteInputScreen._BrandBar`, share text, About) is unchanged.
- Icon sources live in `assets/icon/`: `app_icon.png` (rounded, transparent corners: Android legacy, web, Windows, macOS), `app_icon_ios.png` (full-bleed, no alpha), and `adaptive_foreground.png` (art at 64% so circle/squircle masks keep the bus, pin and sun) with `adaptive_background.png` (blurred art). They are cropped from the user-supplied logo. Regenerate platform icons with `dart run flutter_launcher_icons` (config at the bottom of `pubspec.yaml`).

## Credentials and billing notes (2026-10-05)

- API keys live only in `.env` (and gitignored `ios/Flutter/Secrets.xcconfig`). The OpenWeather key literals in `PLAN.md` were replaced with `YOUR_OPENWEATHER_API_KEY`. The old key should still be rotated, since it was exposed.
- `.env` is bundled as a Flutter asset, so keys are extractable from the APK and publicly downloadable on web. Protect them with Google key restrictions, not secrecy.
- Android release builds currently use the debug signing config (`build.gradle.kts`), so debug and release share the debug keystore SHA-1. Add the new SHA-1 to the key restriction once a release keystore (or Play App Signing) is set up.
- Place Details requests `id,formattedAddress,location` only; `displayName` would move them to the Place Details Pro SKU. The name comes from the autocomplete suggestion.
- Web: an Android/iOS-restricted key fails there (no app identity headers). Web needs a separate HTTP-referrer-restricted key. The web map uses the OSM fallback.

## UI notes

- Results top bar (`_TopBar` in `results_screen.dart`) must be wrapped in `Positioned(top/left/right)` with a `mainAxisSize.min` column; unpositioned in the `Stack`, its frosted pill stretched over the whole map.
- `RouteInputScreen._submit` hides any visible snackbar before pushing `/results` (the app-wide `ScaffoldMessenger` otherwise carries it over). If the user never picked a time, it also refreshes the auto default departure (`RouteFormState.departureEdited`, `refreshDefaultDeparture`).
- Date/time pickers have explicit, state-based colours in `AppTheme` (`timePickerTheme`, `datePickerTheme`). Material 3 defaults rendered dark text on the dark dialog.
- Verified 2026-10-05: `flutter analyze` clean, 13 unit tests pass, `flutter build apk --debug` succeeds. Google Maps rendering on a real device and iOS builds have not been verified by an agent.

## Known gaps / follow-up candidates

- Replace the generic Flutter starter `README.md` with actual SunRoute setup/run/configuration guidance.
- Clean credentials from `PLAN.md`; rotate the exposed OpenWeather key.
- Decide whether submit-time departure validation should enforce the plan's 5-day weather window. Current analysis exposes a beyond-forecast state rather than guaranteeing usable forecast data.
- Confirm all edge-case behaviors from the plan, including no-network/no-route/missing-key handling, with implementation review or tests as needed. Do not assume the plan's entire edge-case table is implemented solely because the main flow exists.
- Consider adding focused repository/provider/widget tests for routing fallbacks, weather failures/cache, and interactive playback. Existing tests cover core algorithms but do not establish API integration correctness.
- `PLAN.md` is a specification and contains implementation suggestions that may be stale. Prefer observed code and this memory file for current architecture; update this file when decisions are made.

## Working conventions for future agents

- Read this file and the relevant feature files before making changes; inspect `PLAN.md` for intended product behavior.
- Keep API credentials private. Use `.env.example` placeholders only in documentation.
- Follow existing Dart style and feature folder organization; add shared primitives to `lib/core` only when appropriate.
- Keep UI updates connected to existing Riverpod state/providers and preserve the analysis pipeline unless changing it intentionally.
- Do not claim an integration or behavior is verified from source inspection alone. Report what was inspected, and run checks only when requested by the user or task instructions.
- Update this file with material architecture, behavior, or known-gap changes so the next agent has accurate project memory.
