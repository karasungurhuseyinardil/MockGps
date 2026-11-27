import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/account_repository.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Settings shown in the app. Server settings are the source of truth once signed in;
/// a local copy makes theme/language work before sign-in and offline. `jitter` is device-only.
class AppSettings {
  const AppSettings({this.user = const UserSettings(), this.jitter = false});

  final UserSettings user;
  final bool jitter;

  ThemeMode get themeMode => switch (user.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale get locale => Locale(user.language);

  AppSettings copyWith({UserSettings? user, bool? jitter}) => AppSettings(user: user ?? this.user, jitter: jitter ?? this.jitter);
}

class SettingsController extends Notifier<AppSettings> {
  static const _kSettings = 'settings.user';
  static const _kJitter = 'settings.jitter';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final stored = UserSettings.decode(_prefs.getString(_kSettings));
    final deviceLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr' ? 'tr' : 'en';
    return AppSettings(
      user: stored ?? UserSettings(language: deviceLanguage),
      jitter: _prefs.getBool(_kJitter) ?? false,
    );
  }

  /// Applies settings received from the server (after sign-in or refresh).
  void applyServer(UserSettings server) {
    state = state.copyWith(user: server);
    _prefs.setString(_kSettings, server.encode());
  }

  /// Optimistically updates, then persists to the server. Reverts and rethrows on failure.
  Future<void> update(UserSettings Function(UserSettings) change, {required bool signedIn}) async {
    final previous = state.user;
    final next = change(previous);
    state = state.copyWith(user: next);
    await _prefs.setString(_kSettings, next.encode());
    if (!signedIn) return;
    try {
      final saved = await ref.read(accountRepositoryProvider).updateSettings(next);
      applyServer(saved);
    } catch (_) {
      state = state.copyWith(user: previous);
      await _prefs.setString(_kSettings, previous.encode());
      rethrow;
    }
  }

  Future<void> setJitter(bool value) async {
    state = state.copyWith(jitter: value);
    await _prefs.setBool(_kJitter, value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
