/// Build-time configuration. Pass with `--dart-define-from-file=env/dev.json`.
/// Only public values belong here: the Supabase publishable key is safe to ship,
/// the secret key never is.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const authRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL', defaultValue: 'mockgps://auth-callback');
  static const websiteUrl = String.fromEnvironment('WEBSITE_URL', defaultValue: 'https://mockgps.app');

  static List<String> get missing => [
        if (apiBaseUrl.isEmpty) 'API_BASE_URL',
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      ];
}
