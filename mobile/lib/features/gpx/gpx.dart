import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/geo.dart';

/// Builds GPX files that Xcode's "Simulate Location" understands: a list of `<wpt>` elements.
/// For routes, waypoints get timestamps spaced by the travel time at the chosen speed, which Xcode
/// uses to animate movement.
abstract final class Gpx {
  static String point(GeoPoint p, {String name = 'Mock GPS'}) => _doc([
        '  <wpt lat="${_n(p.lat)}" lon="${_n(p.lng)}"><name>${_escape(name)}</name></wpt>',
      ]);

  static String route(List<GeoPoint> points, {required double speedKmh, bool loop = false, String name = 'Mock GPS route', DateTime? start}) {
    final path = loop && points.length > 1 ? [...points, points.first] : points;
    final mps = speedKmh / 3.6;
    var time = (start ?? DateTime.utc(2026, 1, 1)).toUtc();
    final lines = <String>[];
    for (var i = 0; i < path.length; i++) {
      if (i > 0) {
        final seconds = GeoMath.distanceMeters(path[i - 1], path[i]) / mps;
        time = time.add(Duration(milliseconds: (seconds * 1000).round()));
      }
      lines.add('  <wpt lat="${_n(path[i].lat)}" lon="${_n(path[i].lng)}"><name>${_escape(name)} ${i + 1}</name>'
          '<time>${time.toIso8601String().split('.').first}Z</time></wpt>');
    }
    return _doc(lines);
  }

  static Future<void> share(String gpx, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.gpx');
    await file.writeAsString(gpx);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/gpx+xml')]));
  }

  static String _doc(List<String> body) => [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="Mock GPS" xmlns="http://www.topografix.com/GPX/1/1">',
        ...body,
        '</gpx>',
        '',
      ].join('\n');

  static String _n(double v) => v.toStringAsFixed(7);

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}
