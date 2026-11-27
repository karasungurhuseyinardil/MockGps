import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/env.dart';

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, required this.level});

  final String id;
  final String title;
  final String body;
  final String level;

  factory Announcement.fromJson(Map<String, dynamic> j) =>
      Announcement(id: j['id'] as String, title: j['title'] as String, body: j['body'] as String, level: j['level'] as String);
}

class MapStyles {
  const MapStyles({required this.standard, required this.dark, required this.minimal, this.satellite, required this.attribution});

  final String standard;
  final String dark;
  final String minimal;
  final String? satellite;
  final String attribution;

  static const fallback = MapStyles(
    standard: 'https://tiles.openfreemap.org/styles/liberty',
    dark: 'https://tiles.openfreemap.org/styles/dark',
    minimal: 'https://tiles.openfreemap.org/styles/positron',
    attribution: '© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors',
  );

  factory MapStyles.fromJson(Map<String, dynamic> j) => MapStyles(
        standard: j['styleLightUrl'] as String,
        dark: j['styleDarkUrl'] as String,
        minimal: (j['styleMinimalUrl'] as String?) ?? fallback.minimal,
        satellite: j['styleSatelliteUrl'] as String?,
        attribution: j['attribution'] as String,
      );

  /// Style for a map type; falls back to the dark/standard style for the current theme.
  String forType(String type, {required bool dark}) => switch (type) {
        'dark' => this.dark,
        'light' => minimal,
        'satellite' when satellite != null => satellite!,
        _ => dark ? this.dark : standard,
      };
}

class AppConfig {
  const AppConfig({
    required this.maintenanceMode,
    required this.updateRequired,
    required this.updateAvailable,
    this.downloadUrl,
    required this.announcements,
    required this.map,
    required this.geocodingEnabled,
    required this.supportEmail,
  });

  final bool maintenanceMode;
  final bool updateRequired;
  final bool updateAvailable;
  final String? downloadUrl;
  final List<Announcement> announcements;
  final MapStyles map;
  final bool geocodingEnabled;
  final String supportEmail;

  /// Used when the server cannot be reached: the app keeps working (simulation is local).
  static const offline = AppConfig(
    maintenanceMode: false,
    updateRequired: false,
    updateAvailable: false,
    announcements: [],
    map: MapStyles.fallback,
    geocodingEnabled: true,
    supportEmail: '',
  );

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        maintenanceMode: j['maintenanceMode'] as bool,
        updateRequired: j['updateRequired'] as bool,
        updateAvailable: j['updateAvailable'] as bool,
        downloadUrl: (j['latestRelease'] as Map<String, dynamic>?)?['downloadUrl'] as String?,
        announcements: (j['announcements'] as List).map((a) => Announcement.fromJson(a as Map<String, dynamic>)).toList(),
        map: MapStyles.fromJson(j['map'] as Map<String, dynamic>),
        geocodingEnabled: j['geocodingEnabled'] as bool,
        supportEmail: j['supportEmail'] as String,
      );
}

final packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Public runtime config (no auth). Falls back to [AppConfig.offline] on network errors.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
  final dio = Dio(BaseOptions(baseUrl: '${Env.apiBaseUrl}/api/v1', connectTimeout: const Duration(seconds: 6)));
  try {
    final res = await dio.get<Map<String, dynamic>>('/public/app-config', queryParameters: {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'build': int.tryParse(info.buildNumber) ?? 1,
    });
    return AppConfig.fromJson(res.data!);
  } on DioException {
    return AppConfig.offline;
  }
});
