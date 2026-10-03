import 'dart:math' as math;

/// Cálculos de distancia entre dos puntos (latitud/longitud).
abstract final class Distancia {
  static const _radioTierraMetros = 6371000.0;

  /// Distancia en metros en línea recta (fórmula de Haversine).
  static double metrosEntre(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    double rad(double grados) => grados * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _radioTierraMetros * math.asin(math.sqrt(a));
  }

  /// 350 → "a 350 m"   1234 → "a 1,2 km"   25300 → "a 25 km"
  static String texto(double metros) {
    if (metros < 1000) return 'a ${(metros / 10).round() * 10} m';
    final km = metros / 1000;
    if (km < 10) return 'a ${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    return 'a ${km.round()} km';
  }
}
