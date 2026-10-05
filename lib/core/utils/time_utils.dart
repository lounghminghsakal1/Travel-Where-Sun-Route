import 'package:intl/intl.dart';

class TimeUtils {
  const TimeUtils._();

  static String time(DateTime t) => DateFormat.jm().format(t.toLocal());
  static String shortTime(DateTime t) => DateFormat('h:mm').format(t.toLocal());
  static String date(DateTime t) => DateFormat('EEE, d MMM').format(t.toLocal());
  static String dateTime(DateTime t) =>
      DateFormat('EEE d MMM, h:mm a').format(t.toLocal());

  /// "2h 14m", "45m", "30s".
  static String duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String distanceKm(double km) =>
      km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}
