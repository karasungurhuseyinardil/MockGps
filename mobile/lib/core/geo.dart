import 'dart:math' as math;

/// Simple coordinate value used across the app (independent of map SDK types).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  bool get isValid => lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  String format([int digits = 6]) => '${lat.toStringAsFixed(digits)}, ${lng.toStringAsFixed(digits)}';

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory GeoPoint.fromJson(Map<String, dynamic> j) => GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint(${format()})';

  /// Parses "41.0082, 28.9784", "41.0082 28.9784" or "41,0082;28,9784".
  static GeoPoint? tryParse(String input) {
    final text = input.trim();
    final m = RegExp(r'^\s*(-?\d{1,3}(?:[.,]\d+)?)\s*[,; ]\s*(-?\d{1,3}(?:[.,]\d+)?)\s*$').firstMatch(text);
    if (m == null) return null;
    double? n(String s) => double.tryParse(s.replaceAll(',', '.'));
    // "41,0082, 28,9784" is ambiguous with commas as separators; only accept dot decimals with comma separators.
    final lat = n(m.group(1)!);
    final lng = n(m.group(2)!);
    if (lat == null || lng == null) return null;
    final p = GeoPoint(lat, lng);
    return p.isValid ? p : null;
  }
}

abstract final class GeoMath {
  static const _r = 6371008.8;

  static double distanceMeters(GeoPoint a, GeoPoint b) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * _r * math.asin(math.min(1, math.sqrt(h)));
  }

  static double pathMeters(List<GeoPoint> points, {bool loop = false}) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distanceMeters(points[i - 1], points[i]);
    }
    if (loop && points.length > 1) total += distanceMeters(points.last, points.first);
    return total;
  }

  static String formatDistance(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 2 : 1)} km';
}
