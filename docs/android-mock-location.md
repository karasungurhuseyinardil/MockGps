# Android mock location

The app uses Android's official mock location mechanism. No root, no hidden APIs.

## Requirements on the device

1. Developer options enabled (Settings → About phone → tap *Build number* 7 times).
2. Developer options → **Select mock location app** → *Mock GPS*.
3. Location permission (precise) granted to the app.
4. Notification permission (Android 13+) so the foreground service notification is visible.

The app checks each item and guides the user step by step (onboarding screen), opening the right
settings screen with `Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS` and re-checking on return.

## Manifest

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_MOCK_LOCATION"
    tools:ignore="MockLocation,ProtectedPermissions" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<service android:name=".mock.MockLocationService"
    android:exported="false"
    android:foregroundServiceType="location" />
```

## Components (`mobile/android/app/src/main/kotlin/.../mock/`)

| File | Job |
|---|---|
| `MockSetupChecker.kt` | Reports: location permission, notification permission, developer options enabled, app selected as mock app (`AppOpsManager.OPSTR_MOCK_LOCATION`, confirmed by trying `addTestProvider`). |
| `MockProviderController.kt` | Adds/removes test providers for `gps` and `network`, enables Fused mock mode, pushes `Location` objects to both. |
| `RoutePlayer.kt` | Pure Kotlin: moves along a polyline at a given speed (haversine distance, bearing), supports pause/resume/loop. Unit tested. |
| `MockLocationService.kt` | Foreground service (`type=location`). Owns the push loop, persistent notification with *Stop*, persists state. |
| `MockLocationPlugin.kt` | `MethodChannel` (`checkSetup`, `openDeveloperSettings`, `start`, `startRoute`, `pause`, `resume`, `stop`, `getState`) and `EventChannel` (state stream). |

## Flow

1. **Start** — Flutter calls `start(lat, lng, accuracy, intervalMs)`. The service starts in the
   foreground, adds test providers (`addTestProvider` + `setTestProviderEnabled`) and calls
   `FusedLocationProviderClient.setMockMode(true)`.
2. **Push loop** — every `intervalMs` (default 1000 ms) the service builds a complete `Location`
   (time, `elapsedRealtimeNanos`, accuracy, altitude, speed, bearing, and on API 26+ vertical/speed/bearing
   accuracy) and sends it via `setTestProviderLocation` and `setMockLocation`. Re-sending is required:
   apps request fresh fixes and stale locations are dropped.
3. **Route mode** — `RoutePlayer` runs inside the service, so movement continues while the UI is in the
   background. Two-point movement is a route with two points.
4. **Stop** — loop cancelled, `removeTestProvider` for each provider, `setMockMode(false)`, service
   stopped. Leftover test providers are cleaned on next app start.
5. **State** — `idle | running | paused | error` and the last location are streamed over the
   `EventChannel` and persisted in `SharedPreferences`, so the UI reconnects after process recreation.
6. **Verification** — an in-app screen reads the system location through the platform location API
   and compares it with the simulated point.

## Limitations (shown in app, FAQ and here)

* Android marks mocked fixes (`Location.isMock()` on API 31+, `isFromMockProvider()` before).
  Apps may detect and reject them (banking apps, some games, anti-fraud SDKs).
  **This app does not try to hide or bypass mock detection.**
* Some OEM ROMs and Wi-Fi/cell positioning may partially ignore test providers.
* Developer options must stay enabled while simulating.
* Background: the simulation lives in a foreground service with a visible notification. Battery
  optimisation on some OEMs may still stop it; the onboarding screen links to the battery settings.

## Development device (USB or wireless debugging)

1. Phone: Developer options → **Wireless debugging** on → *Pair device with pairing code*.
   PC: `adb pair <ip>:<pairing-port>` (enter code), then `adb devices` shows the phone.
   Once paired, the phone reconnects automatically (mDNS) while both are on the same Wi-Fi.
2. Start the backend: `npx supabase start` and `dotnet run --project backend/src/MockGps.API`.
3. From `mobile/`: `./tool/dev-device.ps1 -GrantSetup`
   * creates `adb reverse` tunnels for ports 5080 (API) and 54321 (Supabase), so the phone uses
     `http://127.0.0.1:<port>` from `env/dev.json` — no Windows Firewall changes needed,
   * grants location permission and selects the app as mock location app (leave out
     `-GrantSetup` to walk through the in-app setup guide instead),
   * runs the app.
4. Tunnels end when adb disconnects; run the script again after reconnecting.

Automated on-device check of the real pipeline (service → Android location APIs):

```bash
flutter test integration_test/mock_location_test.dart -d <device> --dart-define-from-file=env/dev.json
```

## Manual device test checklist

1. `flutter run` on the device, finish onboarding until all checks are green.
2. Pick a far location (e.g. Berlin), start simulation; persistent notification is visible.
3. `adb shell dumpsys location` lists the `gps` test provider with the simulated coordinates.
4. Open Google Maps → "my location" shows Berlin.
5. Open a second location app (e.g. a GPS status app) → shows Berlin.
6. Start a route at 50 km/h → the marker moves in Google Maps; pause/resume works.
7. Put the app in background for 5 minutes → simulation continues.
8. Stop → Google Maps returns to the real location within a few seconds.
