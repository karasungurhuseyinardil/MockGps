import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockgps/core/geo.dart';
import 'package:mockgps/core/theme/app_theme.dart';
import 'package:mockgps/features/auth/auth_controller.dart';
import 'package:mockgps/features/auth/auth_screens.dart';
import 'package:mockgps/features/map/coordinates_dialog.dart';
import 'package:mockgps/features/map/location_panel.dart';
import 'package:mockgps/features/simulation/mock_location_channel.dart';
import 'package:mockgps/l10n/gen/app_localizations.dart';

/// Avoids Supabase in widget tests.
class _SignedOutAuth extends AuthController {
  @override
  AppAuthState build() => const AppAuthState();
}

Widget wrap(Widget child, {Locale locale = const Locale('en')}) => ProviderScope(
      overrides: [authProvider.overrideWith(_SignedOutAuth.new)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(body: child),
      ),
    );

LocationPanel panel({
  GeoPoint? selected,
  SimulationState simulation = const SimulationState(),
  bool canSimulate = true,
  VoidCallback? onStart,
  VoidCallback? onStop,
  VoidCallback? onExport,
  List<QuickPlace> quick = const [],
}) =>
    LocationPanel(
      selected: selected,
      address: 'Pariser Platz, Berlin',
      addressLoading: false,
      simulation: simulation,
      canSimulate: canSimulate,
      quickPlaces: quick,
      onStart: onStart ?? () {},
      onStop: onStop ?? () {},
      onPause: () {},
      onResume: () {},
      onSave: () {},
      onCoordinates: () {},
      onCopy: () {},
      onExportGpx: onExport ?? () {},
      onQuickPlace: (_) {},
    );

void main() {
  setUpAll(() {
    // google_fonts would try to download fonts in tests.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('panel asks to pick a location when nothing is selected', (tester) async {
    await tester.pumpWidget(wrap(panel()));
    expect(find.text('Tap the map to choose a location'), findsOneWidget);
    final start = tester.widget<FilledButton>(find.ancestor(of: find.text('Start simulation'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(start.onPressed, isNull);
  });

  testWidgets('panel starts simulation for a selected point', (tester) async {
    var started = false;
    await tester.pumpWidget(wrap(panel(selected: const GeoPoint(52.5163, 13.3777), onStart: () => started = true)));
    expect(find.text('52.516300, 13.377700'), findsOneWidget);
    expect(find.text('Pariser Platz, Berlin'), findsOneWidget);
    await tester.tap(find.text('Start simulation'));
    expect(started, isTrue);
  });

  testWidgets('panel shows stop while simulating and move-here for a new point', (tester) async {
    var stopped = false;
    await tester.pumpWidget(wrap(panel(
      selected: const GeoPoint(41, 29),
      simulation: const SimulationState(status: SimulationStatus.running, mode: 'point', point: GeoPoint(52.5, 13.4)),
      onStop: () => stopped = true,
    )));
    expect(find.text('Move here'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
  });

  testWidgets('route simulation shows pause instead of move', (tester) async {
    await tester.pumpWidget(wrap(panel(
      selected: const GeoPoint(41, 29),
      simulation: const SimulationState(status: SimulationStatus.running, mode: 'route', point: GeoPoint(41, 29)),
    )));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Move here'), findsNothing);
  });

  testWidgets('iOS shows GPX export instead of simulation', (tester) async {
    var exported = false;
    await tester.pumpWidget(wrap(panel(selected: const GeoPoint(41, 29), canSimulate: false, onExport: () => exported = true)));
    expect(find.text('Start simulation'), findsNothing);
    await tester.tap(find.text('Export GPX'));
    expect(exported, isTrue);
  });

  testWidgets('Turkish labels are used', (tester) async {
    await tester.pumpWidget(wrap(panel(selected: const GeoPoint(41, 29)), locale: const Locale('tr')));
    expect(find.text('Simülasyonu başlat'), findsOneWidget);
  });

  testWidgets('sign in validates the form', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('coordinates sheet validates and returns a point', (tester) async {
    GeoPoint? result;
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => TextButton(onPressed: () async => result = await showCoordinatesDialog(context), child: const Text('open')),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '95');
    await tester.enterText(fields.at(1), '10');
    await tester.tap(find.text('Show on map'));
    await tester.pump();
    expect(find.text('Latitude must be between -90 and 90.'), findsOneWidget);

    // Pasting "lat, lng" into one field fills both.
    await tester.enterText(fields.at(0), '41.0082, 28.9784');
    await tester.pump();
    await tester.tap(find.text('Show on map'));
    await tester.pumpAndSettle();
    expect(result, const GeoPoint(41.0082, 28.9784));
  });

  test('password policy mirrors Supabase', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(validatePassword(l, 'short1'), isNotNull);
    expect(validatePassword(l, 'onlyletters'), isNotNull);
    expect(validatePassword(l, 'letters123'), isNull);
  });
}
