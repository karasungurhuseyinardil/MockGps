import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/gen/app_localizations.dart';
import 'network/api_client.dart';

/// Turns any error into a user-friendly, translated sentence.
String describeError(AppLocalizations l, Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'network':
        return l.errorNetwork;
      case 'account_disabled':
        return l.errorAccountDisabled;
      case 'rate_limited':
        return l.errorRateLimited;
      case 'geocoding_disabled':
        return l.errorGeocodingDisabled;
      case 'unauthorized' || 'account_not_found':
        return l.errorSessionExpired;
      case 'maintenance':
        return l.maintenanceBody;
    }
    if (error.status == 401) return l.errorSessionExpired;
    if (error.status >= 500 || error.status == 0) return l.errorServer;
    // 4xx business errors carry a readable server message.
    return error.message;
  }
  if (error is AuthException) return describeAuthError(l, error);
  return l.errorGeneric;
}

String describeAuthError(AppLocalizations l, AuthException e) {
  final code = e.code ?? '';
  final msg = e.message.toLowerCase();
  if (code == 'invalid_credentials' || msg.contains('invalid login')) return l.authInvalidCredentials;
  if (code == 'email_not_confirmed' || msg.contains('not confirmed')) return l.authEmailNotConfirmed;
  if (code == 'user_already_exists' || msg.contains('already registered')) return l.authUserExists;
  if (code == 'weak_password') return l.authPasswordRule;
  if (code.contains('rate_limit') || e.statusCode == '429') return l.authRateLimited;
  if (e is AuthRetryableFetchException) return l.errorNetwork;
  return e.message;
}
