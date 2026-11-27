// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mock GPS';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonOpenSettings => 'Open settings';

  @override
  String get navMap => 'Map';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navRoutes => 'Routes';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to sync your favorites and routes.';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpSubtitle =>
      'Free, no ads. Your location history stays on this device by default.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authDisplayName => 'Name';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authNoAccount => 'No account yet? Create one';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetSubtitle =>
      'We\'ll email you a link to choose a new password.';

  @override
  String get authSendResetLink => 'Send link';

  @override
  String get authResetSent =>
      'If an account exists for this email, a reset link is on its way.';

  @override
  String get authNewPasswordTitle => 'Choose a new password';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authPasswordUpdated => 'Password updated.';

  @override
  String get authCheckEmailTitle => 'Check your inbox';

  @override
  String authCheckEmailBody(String email) {
    return 'We sent a confirmation link to $email. Open it on this phone to finish signing up.';
  }

  @override
  String get authResendEmail => 'Resend email';

  @override
  String get authEmailResent => 'Confirmation email sent again.';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authPasswordRule =>
      'At least 8 characters with letters and numbers.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authEmailNotConfirmed =>
      'Confirm your email first. Check your inbox.';

  @override
  String get authUserExists => 'An account with this email already exists.';

  @override
  String get authRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get mapSearchHint => 'Search address or place';

  @override
  String get mapSelectedLocation => 'Selected location';

  @override
  String get mapTapToSelect => 'Tap the map to choose a location';

  @override
  String get mapStart => 'Start simulation';

  @override
  String get mapStop => 'Stop';

  @override
  String get mapUpdate => 'Move here';

  @override
  String get mapPause => 'Pause';

  @override
  String get mapResume => 'Resume';

  @override
  String get mapSaveFavorite => 'Save';

  @override
  String get mapEnterCoordinates => 'Coordinates';

  @override
  String get mapMyLocation => 'My real location';

  @override
  String get mapLocationServiceOff =>
      'Location services are off. Turn on GPS to see where you are.';

  @override
  String get mapLocationPermissionDenied =>
      'Location permission is needed to show where you are.';

  @override
  String get mapLocationUnavailable =>
      'Couldn\'t get your location. Try again outdoors or with GPS on.';

  @override
  String get mapLayers => 'Map style';

  @override
  String get mapSimulating => 'Simulating';

  @override
  String get mapPaused => 'Paused';

  @override
  String mapRouteProgress(int percent) {
    return 'Route $percent%';
  }

  @override
  String get mapLookingUpAddress => 'Looking up address…';

  @override
  String get mapNoAddress => 'No address found';

  @override
  String get mapNoResults => 'No places found';

  @override
  String get mapRecent => 'Recent';

  @override
  String get mapCopyCoordinates => 'Copy coordinates';

  @override
  String get mapCopied => 'Coordinates copied';

  @override
  String get mapExportGpx => 'Export GPX';

  @override
  String get mapSetupNeeded => 'Finish setup to simulate';

  @override
  String get mapSimulationStarted => 'Simulation started';

  @override
  String get mapAttribution => 'Map data';

  @override
  String get coordsTitle => 'Enter coordinates';

  @override
  String get coordsLatitude => 'Latitude';

  @override
  String get coordsLongitude => 'Longitude';

  @override
  String get coordsPasteHint =>
      'You can paste \"41.0082, 28.9784\" into either field.';

  @override
  String get coordsInvalidLat => 'Latitude must be between -90 and 90.';

  @override
  String get coordsInvalidLng => 'Longitude must be between -180 and 180.';

  @override
  String get coordsGo => 'Show on map';

  @override
  String get mapStyleStandard => 'Standard';

  @override
  String get mapStyleMinimal => 'Minimal';

  @override
  String get mapStyleDark => 'Dark';

  @override
  String get mapStyleSatellite => 'Satellite';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesSearchHint => 'Search favorites';

  @override
  String get favoritesAll => 'All';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Pick a place on the map and tap Save to keep it here.';

  @override
  String get favoritesNoMatch => 'No favorites match your search.';

  @override
  String get favoritesActivate => 'Simulate here';

  @override
  String get favoritesShowOnMap => 'Show on map';

  @override
  String get favoritesDeleted => 'Favorite deleted';

  @override
  String get favoritesSaved => 'Favorite saved';

  @override
  String get favoritesManageCategories => 'Categories';

  @override
  String get favoriteEditTitle => 'Favorite';

  @override
  String get favoriteName => 'Name';

  @override
  String get favoriteDescription => 'Description';

  @override
  String get favoriteCategory => 'Category';

  @override
  String get favoriteNoCategory => 'No category';

  @override
  String get favoriteNameRequired => 'Enter a name.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryName => 'Category name';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete \"$name\"? Favorites in it are kept without a category.';
  }

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favorites',
      one: '1 favorite',
      zero: 'No favorites',
    );
    return '$_temp0';
  }

  @override
  String get routesTitle => 'Routes';

  @override
  String get routesEmptyTitle => 'No saved routes';

  @override
  String get routesEmptyBody =>
      'Create a route by tapping points on the map, then play it at the speed you choose.';

  @override
  String get routesNew => 'New route';

  @override
  String get routeEditorTitle => 'Route';

  @override
  String get routeEditorHint =>
      'Tap the map to add points. Long-press a point to remove the last one.';

  @override
  String get routeName => 'Route name';

  @override
  String get routeSpeed => 'Speed';

  @override
  String routeSpeedValue(int speed) {
    return '$speed km/h';
  }

  @override
  String get routeLoop => 'Loop';

  @override
  String get routeLoopHint => 'Return to the start and repeat';

  @override
  String routePoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String routeDistance(String km) {
    return '$km km';
  }

  @override
  String get routePlay => 'Play route';

  @override
  String get routeUndoPoint => 'Remove last point';

  @override
  String get routeClear => 'Clear';

  @override
  String get routeNeedsPoints => 'Add at least two points.';

  @override
  String get routeSaved => 'Route saved';

  @override
  String get routeDeleted => 'Route deleted';

  @override
  String get routeStarted => 'Route started';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyBody => 'Locations you simulate appear here.';

  @override
  String get historyDisabledTitle => 'History is turned off';

  @override
  String get historyDisabledBody =>
      'Turn it on in Settings to keep a list of simulated locations on this device.';

  @override
  String get historyClearAll => 'Clear all';

  @override
  String historyClearConfirm(String cloud) {
    String _temp0 = intl.Intl.selectLogic(cloud, {
      'true': ' and in the cloud',
      'other': '',
    });
    return 'Delete all history on this device$_temp0?';
  }

  @override
  String get historyCleared => 'History cleared';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get historyLocalOnly => 'Stored on this device only';

  @override
  String get historySynced => 'Synced to your account';

  @override
  String get historyUse => 'Use again';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDefaultMap => 'Default map style';

  @override
  String get settingsSimulation => 'Simulation';

  @override
  String get settingsAccuracy => 'Reported accuracy';

  @override
  String settingsAccuracyValue(int meters) {
    return '$meters m';
  }

  @override
  String get settingsInterval => 'Update interval';

  @override
  String settingsIntervalValue(String seconds) {
    return '$seconds s';
  }

  @override
  String get settingsJitter => 'Natural drift';

  @override
  String get settingsJitterHint =>
      'Adds small random movement inside the accuracy radius';

  @override
  String get settingsSetupGuide => 'Setup guide';

  @override
  String get settingsVerify => 'Check simulation';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsHistory => 'Keep location history';

  @override
  String get settingsHistoryHint => 'Stored on this device';

  @override
  String get settingsCloudSync => 'Sync history to my account';

  @override
  String get settingsCloudSyncHint => 'Turning this off deletes the cloud copy';

  @override
  String get settingsNotifications => 'Announcements';

  @override
  String get settingsNotificationsHint =>
      'Show product announcements in the app';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsDisplayName => 'Name';

  @override
  String get settingsExport => 'Download my data';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteConfirmTitle => 'Delete your account?';

  @override
  String get settingsDeleteConfirmBody =>
      'Your profile, favorites, routes and cloud history are deleted permanently. This cannot be undone.';

  @override
  String get settingsDeleteConfirmType => 'Type DELETE to confirm';

  @override
  String get settingsDeleteConfirmWord => 'DELETE';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get setupTitle => 'Set up simulation';

  @override
  String get setupIntro =>
      'Android lets one app provide test locations. These steps take about a minute and need no root.';

  @override
  String get setupLocationPermission => 'Allow precise location';

  @override
  String get setupLocationPermissionHint =>
      'Needed to run the simulation service.';

  @override
  String get setupNotificationPermission => 'Allow notifications';

  @override
  String get setupNotificationPermissionHint =>
      'Shows a notification with a Stop button while simulating.';

  @override
  String get setupDeveloperOptions => 'Turn on Developer options';

  @override
  String get setupDeveloperOptionsHint =>
      'Settings → About phone → tap Build number 7 times.';

  @override
  String get setupMockApp => 'Select Mock GPS as mock location app';

  @override
  String get setupMockAppHint =>
      'Developer options → Select mock location app → Mock GPS.';

  @override
  String get setupLocationOn => 'Turn on device location';

  @override
  String get setupBattery => 'Allow running in background';

  @override
  String get setupBatteryHint =>
      'Recommended on some phones so the simulation is not stopped.';

  @override
  String get setupGrant => 'Allow';

  @override
  String get setupOpen => 'Open';

  @override
  String get setupAllDone => 'All set. You can start simulating.';

  @override
  String get setupDetectionNote =>
      'Android marks simulated locations. Some apps (for example banking apps and some games) detect this and may refuse to work. Mock GPS does not hide it.';

  @override
  String get setupIosTitle => 'Simulation on iOS';

  @override
  String get setupIosBody =>
      'iOS does not allow apps to change the location other apps see. Use Export GPX and load the file in Xcode (Debug → Simulate Location) on a connected device or the Simulator.';

  @override
  String get verifyTitle => 'Check simulation';

  @override
  String get verifyBody =>
      'Reads the location Android reports to apps and compares it with your simulated point.';

  @override
  String get verifyReported => 'Reported by Android';

  @override
  String get verifyExpected => 'Simulated point';

  @override
  String get verifyDistance => 'Difference';

  @override
  String get verifyMocked => 'Marked as mock location';

  @override
  String get verifyOk => 'Working: apps receive the simulated location.';

  @override
  String get verifyMismatch => 'Apps still receive a different location.';

  @override
  String get verifyNotRunning => 'Start a simulation first.';

  @override
  String get verifyWaiting => 'Waiting for a location…';

  @override
  String get simErrorMockApp =>
      'Mock GPS is not selected as mock location app. Open the setup guide.';

  @override
  String get simErrorForeground =>
      'Android did not allow the simulation to start. Check location permission.';

  @override
  String get simErrorInvalidRoute => 'This route cannot be played.';

  @override
  String get simErrorGeneric => 'The simulation stopped unexpectedly.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorAccountDisabled =>
      'This account has been disabled. Contact support for help.';

  @override
  String get errorRateLimited => 'Too many requests. Please wait a moment.';

  @override
  String get errorGeocodingDisabled =>
      'Address search is temporarily unavailable.';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get maintenanceBody =>
      'We are improving the service. Simulation keeps working; account features return shortly.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Install the latest version to continue.';

  @override
  String get updateAvailable => 'A new version is available.';

  @override
  String get updateDownload => 'Download';

  @override
  String get configMissingTitle => 'App not configured';

  @override
  String configMissingBody(String keys) {
    return 'This build is missing: $keys';
  }
}
