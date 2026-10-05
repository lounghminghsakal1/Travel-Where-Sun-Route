/// Google Maps JSON style matching the app's dark palette.
const kDarkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#15171f"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#7d8496"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0f1117"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#2b3040"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9aa0b0"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#b7bdcb"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"visibility": "on"}, {"color": "#16201b"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#262a36"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1a1d27"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#6b7183"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#2b3040"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#353b4e"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#9aa0b0"}]},
  {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0b1424"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d4a66"}]}
]
''';
