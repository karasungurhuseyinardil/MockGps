import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

class UserSettings {
  const UserSettings({
    this.theme = 'system',
    this.language = 'en',
    this.defaultMapType = 'standard',
    this.historyEnabled = true,
    this.historyCloudSync = false,
    this.notificationsEnabled = true,
    this.defaultAccuracyM = 5,
    this.updateIntervalMs = 1000,
  });

  final String theme;
  final String language;
  final String defaultMapType;
  final bool historyEnabled;
  final bool historyCloudSync;
  final bool notificationsEnabled;
  final int defaultAccuracyM;
  final int updateIntervalMs;

  factory UserSettings.fromJson(Map<String, dynamic> j) => UserSettings(
        theme: j['theme'] as String,
        language: j['language'] as String,
        defaultMapType: j['defaultMapType'] as String,
        historyEnabled: j['historyEnabled'] as bool,
        historyCloudSync: j['historyCloudSync'] as bool,
        notificationsEnabled: j['notificationsEnabled'] as bool,
        defaultAccuracyM: j['defaultAccuracyM'] as int,
        updateIntervalMs: j['updateIntervalMs'] as int,
      );

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'language': language,
        'defaultMapType': defaultMapType,
        'historyEnabled': historyEnabled,
        'historyCloudSync': historyCloudSync,
        'notificationsEnabled': notificationsEnabled,
        'defaultAccuracyM': defaultAccuracyM,
        'updateIntervalMs': updateIntervalMs,
      };

  UserSettings copyWith({
    String? theme,
    String? language,
    String? defaultMapType,
    bool? historyEnabled,
    bool? historyCloudSync,
    bool? notificationsEnabled,
    int? defaultAccuracyM,
    int? updateIntervalMs,
  }) =>
      UserSettings(
        theme: theme ?? this.theme,
        language: language ?? this.language,
        defaultMapType: defaultMapType ?? this.defaultMapType,
        historyEnabled: historyEnabled ?? this.historyEnabled,
        historyCloudSync: historyCloudSync ?? this.historyCloudSync,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        defaultAccuracyM: defaultAccuracyM ?? this.defaultAccuracyM,
        updateIntervalMs: updateIntervalMs ?? this.updateIntervalMs,
      );

  String encode() => jsonEncode(toJson());
  static UserSettings? decode(String? s) {
    if (s == null) return null;
    try {
      return UserSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class Me {
  const Me({required this.id, required this.email, this.displayName, this.avatarUrl, required this.roles, required this.settings});

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final List<String> roles;
  final UserSettings settings;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        roles: (j['roles'] as List).cast<String>(),
        settings: UserSettings.fromJson(j['settings'] as Map<String, dynamic>),
      );
}

class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<Me> me() async => Me.fromJson(await _api.get<Map<String, dynamic>>('/me'));

  Future<Me> updateDisplayName(String? name) async =>
      Me.fromJson(await _api.patch<Map<String, dynamic>>('/me/profile', body: {'displayName': name}));

  Future<UserSettings> updateSettings(UserSettings settings) async =>
      UserSettings.fromJson(await _api.put<Map<String, dynamic>>('/me/settings', body: settings.toJson()));

  Future<Me> uploadAvatar(File file) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(file.path)});
    return Me.fromJson(await _api.post<Map<String, dynamic>>('/me/avatar', body: form));
  }

  /// Returns the export as pretty JSON text.
  Future<String> export() async {
    final data = await _api.get<dynamic>('/me/export');
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> deleteAccount() => _api.delete<void>('/me');
}

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(apiClientProvider)));
