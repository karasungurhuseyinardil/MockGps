import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/network/api_client.dart';
import '../account/account_repository.dart';
import '../history/history_repository.dart';
import '../settings/settings_controller.dart';
import '../usage/usage_tracker.dart';

/// Supabase Auth session + the API profile. Clients use Supabase only for authentication;
/// everything else goes through the API.
class AppAuthState {
  const AppAuthState({this.session, this.me, this.passwordRecovery = false, this.blockedCode});

  final Session? session;
  final Me? me;

  /// True after opening a password reset link: the app must ask for a new password.
  final bool passwordRecovery;

  /// Set when the API refused the account (e.g. `account_disabled`).
  final String? blockedCode;

  bool get signedIn => session != null;
}

class AuthController extends Notifier<AppAuthState> {
  StreamSubscription<AuthState>? _sub;
  Timer? _retry;
  int _attempt = 0;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  AppAuthState build() {
    _sub = _auth.onAuthStateChange.listen(_onChange);
    ref.onDispose(() {
      _sub?.cancel();
      _retry?.cancel();
    });
    final session = _auth.currentSession;
    if (session != null) Future.microtask(_loadProfile);
    return AppAuthState(session: session);
  }

  void _onChange(AuthState data) {
    final event = data.event;
    final session = data.session;
    switch (event) {
      case AuthChangeEvent.passwordRecovery:
        state = AppAuthState(session: session, me: state.me, passwordRecovery: true);
      case AuthChangeEvent.signedOut:
        _retry?.cancel();
        _attempt = 0;
        ref.read(usageTrackerProvider).enabled = false;
        state = const AppAuthState();
      case AuthChangeEvent.signedIn || AuthChangeEvent.tokenRefreshed || AuthChangeEvent.userUpdated:
        final wasSignedIn = state.signedIn;
        state = AppAuthState(session: session, me: state.me, passwordRecovery: state.passwordRecovery);
        if (!wasSignedIn || state.me == null) _loadProfile();
      default:
        break;
    }
  }

  Future<void> _loadProfile() async {
    _retry?.cancel();
    if (!state.signedIn) return;
    try {
      final me = await ref.read(accountRepositoryProvider).me();
      ref.read(settingsProvider.notifier).applyServer(me.settings);
      ref.read(usageTrackerProvider)
        ..enabled = true
        ..track(UsageEvents.appOpened);
      _attempt = 0;
      state = AppAuthState(session: state.session, me: me, passwordRecovery: state.passwordRecovery);
      if (me.settings.historyCloudSync) {
        unawaited(ref.read(historyRepositoryProvider).sync().catchError((_) => 0));
      }
    } on ApiException catch (e) {
      if (e.code == 'account_disabled' || e.code == 'account_not_found' || e.status == 401) {
        state = AppAuthState(session: state.session, blockedCode: e.code);
        await signOut();
      } else {
        // Network or server error: retry with backoff (5s, 10s, 20s … max 60s).
        debugPrint('Profile load failed: $e');
        final delay = Duration(seconds: (5 << _attempt).clamp(5, 60));
        _attempt = (_attempt + 1).clamp(0, 4);
        _retry = Timer(delay, _loadProfile);
      }
    }
  }

  Future<void> refreshProfile() => _loadProfile();

  void setMe(Me me) => state = AppAuthState(session: state.session, me: me, passwordRecovery: state.passwordRecovery);

  Future<void> signIn(String email, String password) => _auth.signInWithPassword(email: email.trim(), password: password);

  /// Returns true when the user must confirm the email before signing in.
  Future<bool> signUp(String email, String password, {String? displayName, required String language}) async {
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: Env.emailConfirmUrl,
      data: {'language': language, if (displayName != null && displayName.isNotEmpty) 'display_name': displayName},
    );
    return res.session == null;
  }

  Future<void> resendConfirmation(String email) =>
      _auth.resend(type: OtpType.signup, email: email.trim(), emailRedirectTo: Env.emailConfirmUrl);

  Future<void> sendPasswordReset(String email) => _auth.resetPasswordForEmail(email.trim(), redirectTo: Env.authRedirectUrl);

  Future<void> setNewPassword(String password) async {
    await _auth.updateUser(UserAttributes(password: password));
    state = AppAuthState(session: state.session, me: state.me);
  }

  Future<void> signOut() async {
    await ref.read(usageTrackerProvider).flush();
    await _auth.signOut();
  }
}

final authProvider = NotifierProvider<AuthController, AppAuthState>(AuthController.new);
final isSignedInProvider = Provider<bool>((ref) => ref.watch(authProvider.select((s) => s.signedIn)));
