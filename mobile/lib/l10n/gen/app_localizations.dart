import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mock GPS'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonOpenSettings;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get navRoutes;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your favorites and routes.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free, no ads. Your location history stays on this device by default.'**
  String get authSignUpSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authDisplayName;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to choose a new password.'**
  String get authResetSubtitle;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authSendResetLink;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link is on its way.'**
  String get authResetSent;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get authPasswordUpdated;

  /// No description provided for @authCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authCheckEmailTitle;

  /// No description provided for @authCheckEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it on this phone to finish signing up.'**
  String authCheckEmailBody(String email);

  /// No description provided for @authResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get authResendEmail;

  /// No description provided for @authEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent again.'**
  String get authEmailResent;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with letters and numbers.'**
  String get authPasswordRule;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first. Check your inbox.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authUserExists;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get authRateLimited;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address or place'**
  String get mapSearchHint;

  /// No description provided for @mapSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get mapSelectedLocation;

  /// No description provided for @mapTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to choose a location'**
  String get mapTapToSelect;

  /// No description provided for @mapStart.
  ///
  /// In en, this message translates to:
  /// **'Start simulation'**
  String get mapStart;

  /// No description provided for @mapStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get mapStop;

  /// No description provided for @mapUpdate.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get mapUpdate;

  /// No description provided for @mapPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mapPause;

  /// No description provided for @mapResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mapResume;

  /// No description provided for @mapSaveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mapSaveFavorite;

  /// No description provided for @mapEnterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get mapEnterCoordinates;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My real location'**
  String get mapMyLocation;

  /// No description provided for @mapLayers.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapLayers;

  /// No description provided for @mapSimulating.
  ///
  /// In en, this message translates to:
  /// **'Simulating'**
  String get mapSimulating;

  /// No description provided for @mapPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mapPaused;

  /// No description provided for @mapRouteProgress.
  ///
  /// In en, this message translates to:
  /// **'Route {percent}%'**
  String mapRouteProgress(int percent);

  /// No description provided for @mapLookingUpAddress.
  ///
  /// In en, this message translates to:
  /// **'Looking up address…'**
  String get mapLookingUpAddress;

  /// No description provided for @mapNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address found'**
  String get mapNoAddress;

  /// No description provided for @mapNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get mapNoResults;

  /// No description provided for @mapRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get mapRecent;

  /// No description provided for @mapCopyCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get mapCopyCoordinates;

  /// No description provided for @mapCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get mapCopied;

  /// No description provided for @mapExportGpx.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get mapExportGpx;

  /// No description provided for @mapSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Finish setup to simulate'**
  String get mapSetupNeeded;

  /// No description provided for @mapSimulationStarted.
  ///
  /// In en, this message translates to:
  /// **'Simulation started'**
  String get mapSimulationStarted;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'Map data'**
  String get mapAttribution;

  /// No description provided for @coordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates'**
  String get coordsTitle;

  /// No description provided for @coordsLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get coordsLatitude;

  /// No description provided for @coordsLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get coordsLongitude;

  /// No description provided for @coordsPasteHint.
  ///
  /// In en, this message translates to:
  /// **'You can paste \"41.0082, 28.9784\" into either field.'**
  String get coordsPasteHint;

  /// No description provided for @coordsInvalidLat.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between -90 and 90.'**
  String get coordsInvalidLat;

  /// No description provided for @coordsInvalidLng.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between -180 and 180.'**
  String get coordsInvalidLng;

  /// No description provided for @coordsGo.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get coordsGo;

  /// No description provided for @mapStyleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get mapStyleStandard;

  /// No description provided for @mapStyleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get mapStyleMinimal;

  /// No description provided for @mapStyleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mapStyleDark;

  /// No description provided for @mapStyleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapStyleSatellite;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search favorites'**
  String get favoritesSearchHint;

  /// No description provided for @favoritesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get favoritesAll;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a place on the map and tap Save to keep it here.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoritesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No favorites match your search.'**
  String get favoritesNoMatch;

  /// No description provided for @favoritesActivate.
  ///
  /// In en, this message translates to:
  /// **'Simulate here'**
  String get favoritesActivate;

  /// No description provided for @favoritesShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get favoritesShowOnMap;

  /// No description provided for @favoritesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Favorite deleted'**
  String get favoritesDeleted;

  /// No description provided for @favoritesSaved.
  ///
  /// In en, this message translates to:
  /// **'Favorite saved'**
  String get favoritesSaved;

  /// No description provided for @favoritesManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get favoritesManageCategories;

  /// No description provided for @favoriteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteEditTitle;

  /// No description provided for @favoriteName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get favoriteName;

  /// No description provided for @favoriteDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get favoriteDescription;

  /// No description provided for @favoriteCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get favoriteCategory;

  /// No description provided for @favoriteNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get favoriteNoCategory;

  /// No description provided for @favoriteNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get favoriteNameRequired;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNew;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Favorites in it are kept without a category.'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No favorites} =1{1 favorite} other{{count} favorites}}'**
  String categoryCount(int count);

  /// No description provided for @routesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesTitle;

  /// No description provided for @routesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved routes'**
  String get routesEmptyTitle;

  /// No description provided for @routesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a route by tapping points on the map, then play it at the speed you choose.'**
  String get routesEmptyBody;

  /// No description provided for @routesNew.
  ///
  /// In en, this message translates to:
  /// **'New route'**
  String get routesNew;

  /// No description provided for @routeEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeEditorTitle;

  /// No description provided for @routeEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add points. Long-press a point to remove the last one.'**
  String get routeEditorHint;

  /// No description provided for @routeName.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get routeName;

  /// No description provided for @routeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get routeSpeed;

  /// No description provided for @routeSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h'**
  String routeSpeedValue(int speed);

  /// No description provided for @routeLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get routeLoop;

  /// No description provided for @routeLoopHint.
  ///
  /// In en, this message translates to:
  /// **'Return to the start and repeat'**
  String get routeLoopHint;

  /// No description provided for @routePoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String routePoints(int count);

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String routeDistance(String km);

  /// No description provided for @routePlay.
  ///
  /// In en, this message translates to:
  /// **'Play route'**
  String get routePlay;

  /// No description provided for @routeUndoPoint.
  ///
  /// In en, this message translates to:
  /// **'Remove last point'**
  String get routeUndoPoint;

  /// No description provided for @routeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get routeClear;

  /// No description provided for @routeNeedsPoints.
  ///
  /// In en, this message translates to:
  /// **'Add at least two points.'**
  String get routeNeedsPoints;

  /// No description provided for @routeSaved.
  ///
  /// In en, this message translates to:
  /// **'Route saved'**
  String get routeSaved;

  /// No description provided for @routeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Route deleted'**
  String get routeDeleted;

  /// No description provided for @routeStarted.
  ///
  /// In en, this message translates to:
  /// **'Route started'**
  String get routeStarted;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Locations you simulate appear here.'**
  String get historyEmptyBody;

  /// No description provided for @historyDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'History is turned off'**
  String get historyDisabledTitle;

  /// No description provided for @historyDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings to keep a list of simulated locations on this device.'**
  String get historyDisabledBody;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all history on this device{cloud, select, true{ and in the cloud} other{}}?'**
  String historyClearConfirm(String cloud);

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @historyLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device only'**
  String get historyLocalOnly;

  /// No description provided for @historySynced.
  ///
  /// In en, this message translates to:
  /// **'Synced to your account'**
  String get historySynced;

  /// No description provided for @historyUse.
  ///
  /// In en, this message translates to:
  /// **'Use again'**
  String get historyUse;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDefaultMap.
  ///
  /// In en, this message translates to:
  /// **'Default map style'**
  String get settingsDefaultMap;

  /// No description provided for @settingsSimulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get settingsSimulation;

  /// No description provided for @settingsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Reported accuracy'**
  String get settingsAccuracy;

  /// No description provided for @settingsAccuracyValue.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String settingsAccuracyValue(int meters);

  /// No description provided for @settingsInterval.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get settingsInterval;

  /// No description provided for @settingsIntervalValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String settingsIntervalValue(String seconds);

  /// No description provided for @settingsJitter.
  ///
  /// In en, this message translates to:
  /// **'Natural drift'**
  String get settingsJitter;

  /// No description provided for @settingsJitterHint.
  ///
  /// In en, this message translates to:
  /// **'Adds small random movement inside the accuracy radius'**
  String get settingsJitterHint;

  /// No description provided for @settingsSetupGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get settingsSetupGuide;

  /// No description provided for @settingsVerify.
  ///
  /// In en, this message translates to:
  /// **'Check simulation'**
  String get settingsVerify;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep location history'**
  String get settingsHistory;

  /// No description provided for @settingsHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get settingsHistoryHint;

  /// No description provided for @settingsCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Sync history to my account'**
  String get settingsCloudSync;

  /// No description provided for @settingsCloudSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Turning this off deletes the cloud copy'**
  String get settingsCloudSyncHint;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Show product announcements in the app'**
  String get settingsNotificationsHint;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsDisplayName;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get settingsExport;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, favorites, routes and cloud history are deleted permanently. This cannot be undone.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @settingsDeleteConfirmType.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get settingsDeleteConfirmType;

  /// No description provided for @settingsDeleteConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get settingsDeleteConfirmWord;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTerms;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up simulation'**
  String get setupTitle;

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'Android lets one app provide test locations. These steps take about a minute and need no root.'**
  String get setupIntro;

  /// No description provided for @setupLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow precise location'**
  String get setupLocationPermission;

  /// No description provided for @setupLocationPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Needed to run the simulation service.'**
  String get setupLocationPermissionHint;

  /// No description provided for @setupNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get setupNotificationPermission;

  /// No description provided for @setupNotificationPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Shows a notification with a Stop button while simulating.'**
  String get setupNotificationPermissionHint;

  /// No description provided for @setupDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Turn on Developer options'**
  String get setupDeveloperOptions;

  /// No description provided for @setupDeveloperOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Settings → About phone → tap Build number 7 times.'**
  String get setupDeveloperOptionsHint;

  /// No description provided for @setupMockApp.
  ///
  /// In en, this message translates to:
  /// **'Select Mock GPS as mock location app'**
  String get setupMockApp;

  /// No description provided for @setupMockAppHint.
  ///
  /// In en, this message translates to:
  /// **'Developer options → Select mock location app → Mock GPS.'**
  String get setupMockAppHint;

  /// No description provided for @setupLocationOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on device location'**
  String get setupLocationOn;

  /// No description provided for @setupBattery.
  ///
  /// In en, this message translates to:
  /// **'Allow running in background'**
  String get setupBattery;

  /// No description provided for @setupBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended on some phones so the simulation is not stopped.'**
  String get setupBatteryHint;

  /// No description provided for @setupGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get setupGrant;

  /// No description provided for @setupOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get setupOpen;

  /// No description provided for @setupAllDone.
  ///
  /// In en, this message translates to:
  /// **'All set. You can start simulating.'**
  String get setupAllDone;

  /// No description provided for @setupDetectionNote.
  ///
  /// In en, this message translates to:
  /// **'Android marks simulated locations. Some apps (for example banking apps and some games) detect this and may refuse to work. Mock GPS does not hide it.'**
  String get setupDetectionNote;

  /// No description provided for @setupIosTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulation on iOS'**
  String get setupIosTitle;

  /// No description provided for @setupIosBody.
  ///
  /// In en, this message translates to:
  /// **'iOS does not allow apps to change the location other apps see. Use Export GPX and load the file in Xcode (Debug → Simulate Location) on a connected device or the Simulator.'**
  String get setupIosBody;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check simulation'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Reads the location Android reports to apps and compares it with your simulated point.'**
  String get verifyBody;

  /// No description provided for @verifyReported.
  ///
  /// In en, this message translates to:
  /// **'Reported by Android'**
  String get verifyReported;

  /// No description provided for @verifyExpected.
  ///
  /// In en, this message translates to:
  /// **'Simulated point'**
  String get verifyExpected;

  /// No description provided for @verifyDistance.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get verifyDistance;

  /// No description provided for @verifyMocked.
  ///
  /// In en, this message translates to:
  /// **'Marked as mock location'**
  String get verifyMocked;

  /// No description provided for @verifyOk.
  ///
  /// In en, this message translates to:
  /// **'Working: apps receive the simulated location.'**
  String get verifyOk;

  /// No description provided for @verifyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Apps still receive a different location.'**
  String get verifyMismatch;

  /// No description provided for @verifyNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Start a simulation first.'**
  String get verifyNotRunning;

  /// No description provided for @verifyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a location…'**
  String get verifyWaiting;

  /// No description provided for @simErrorMockApp.
  ///
  /// In en, this message translates to:
  /// **'Mock GPS is not selected as mock location app. Open the setup guide.'**
  String get simErrorMockApp;

  /// No description provided for @simErrorForeground.
  ///
  /// In en, this message translates to:
  /// **'Android did not allow the simulation to start. Check location permission.'**
  String get simErrorForeground;

  /// No description provided for @simErrorInvalidRoute.
  ///
  /// In en, this message translates to:
  /// **'This route cannot be played.'**
  String get simErrorInvalidRoute;

  /// No description provided for @simErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The simulation stopped unexpectedly.'**
  String get simErrorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get errorServer;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support for help.'**
  String get errorAccountDisabled;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get errorRateLimited;

  /// No description provided for @errorGeocodingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Address search is temporarily unavailable.'**
  String get errorGeocodingDisabled;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'We are improving the service. Simulation keeps working; account features return shortly.'**
  String get maintenanceBody;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Install the latest version to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available.'**
  String get updateAvailable;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @configMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'App not configured'**
  String get configMissingTitle;

  /// No description provided for @configMissingBody.
  ///
  /// In en, this message translates to:
  /// **'This build is missing: {keys}'**
  String configMissingBody(String keys);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
