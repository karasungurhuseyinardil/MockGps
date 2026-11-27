# Testing

| Layer | Command | What it covers |
|---|---|---|
| Database (pgTAP) | `npx supabase test db` | 35 checks: signup trigger, RLS isolation between users, role escalation blocked, column protections, backend-only tables, cascade on account deletion |
| Backend unit | `dotnet test backend/tests/MockGps.UnitTests` | validators, sorting/paging, geo math, image sniffing, setting types, geocoding parsing |
| Backend integration | `dotnet test backend/tests/MockGps.IntegrationTests` | real API in-process against local Supabase: auth required, forged tokens, cross-user isolation, admin permissions, deactivation + audit, account deletion cascade, cloud history opt-in |
| Flutter unit/widget | `cd mobile && flutter test` | coordinate parsing, GPX, filters, router rules, API errors, SQLite history + sync, location panel states, forms, TR/EN |
| Kotlin unit | `cd mobile/android && ./gradlew :app:testDebugUnitTest` | route player: speed, bearing, end of route, loop |
| On-device | `flutter test integration_test/mock_location_test.dart -d <device>` | real mock location pipeline: point and route seen by Android location APIs, `isMocked`, stop |
| Website | `cd web/apps/site && npx vitest run` | language routing, dictionary parity, contact form (validation, sending, rate limit), download area |
| Admin | `cd web/apps/admin && npx vitest run` | login / no-access, permission-based navigation and redirects, error mapping, table states |

The integration and on-device tests need running services:

```bash
npx supabase start
```

On-device test preparation (or use `mobile/tool/dev-device.ps1 -GrantSetup`):

```bash
adb shell pm grant com.mockgps.mockgps android.permission.ACCESS_FINE_LOCATION
adb shell appops set com.mockgps.mockgps android:mock_location allow
```

Keep the phone **unlocked with the screen on** while the on-device test runs: Android 12+ does not let
an app start a location foreground service from the background. `flutter test` reinstalls the app,
which resets these grants; re-run the commands above if a test reports missing permission.

## Windows notes

* Run Vitest from a path with an upper-case drive letter (`C:\...`). Mixed `c:`/`C:` paths make Vite load
  two copies of Vitest ("failed to find the current suite").
* The running API locks its DLLs; stop it before `dotnet test`.

## Manual checks per release

See `docs/android-mock-location.md` → *Manual device test checklist* (Google Maps shows the simulated
point, background continuity, stop restores the real location).
