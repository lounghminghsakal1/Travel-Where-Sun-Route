import '../entities/geo_point.dart';

/// Decodes Google's encoded polyline format (precision 5 by default).
class PolylineDecoder {
  const PolylineDecoder._();

  static List<GeoPoint> decode(String encoded, {int precision = 5}) {
    final factor = _pow10(precision);
    final points = <GeoPoint>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      for (var coordinate = 0; coordinate < 2; coordinate++) {
        var shift = 0;
        var result = 0;
        int byte;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20 && index < encoded.length);
        final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
        if (coordinate == 0) {
          lat += delta;
        } else {
          lng += delta;
        }
      }
      points.add(GeoPoint(lat / factor, lng / factor));
    }
    return points;
  }

  static double _pow10(int n) {
    var v = 1.0;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }
}
