import '../../../../core/utils/sun_utils.dart';

/// Local solar-position calculator (no API).
class SunCalculatorDataSource {
  const SunCalculatorDataSource();

  SunAngles compute(DateTime time, double lat, double lng) =>
      SunUtils.position(time, lat, lng);
}
