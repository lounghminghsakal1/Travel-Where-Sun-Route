class ApiConstants {
  const ApiConstants._();

  // Google Places API (New)
  static const placesAutocomplete =
      'https://places.googleapis.com/v1/places:autocomplete';
  static String placeDetails(String placeId) =>
      'https://places.googleapis.com/v1/places/$placeId';

  // Google Routes API (preferred when enabled on the key)
  static const googleRoutes =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  // OSRM public router (keyless fallback, OpenStreetMap data)
  static const osrmRoute = 'https://router.project-osrm.org/route/v1/driving';

  // OpenWeatherMap 5 day / 3 hour forecast
  static const owmForecast = 'https://api.openweathermap.org/data/2.5/forecast';

  // OpenStreetMap standard tiles: keyless fallback map for web/desktop.
  // Fine for light use; see https://operations.osmfoundation.org/policies/tiles/
  static const osmTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
