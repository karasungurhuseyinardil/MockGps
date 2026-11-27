# Architecture

## Overview

```
Flutter (Android/iOS) ──┐
React Site ─────────────┼── HTTPS + Supabase JWT ──▶ .NET API ── Npgsql ──▶ Supabase Postgres (RLS)
React Admin ────────────┘                               │
       │                                                ├─▶ Supabase Auth Admin API (ban, delete user) — secret key, backend only
       └─ supabase SDK (auth only: sign-up, sign-in,    ├─▶ Supabase Storage (avatars, releases)
          password reset, email verification)           └─▶ Geocoding provider (Photon / Nominatim / MapTiler)
```

* **Business logic lives in the .NET API.** Clients use the Supabase SDK only for authentication
  (sign-up, sign-in, password reset, email verification, session refresh). Every data read and write
  goes through `/api/v1`.
* **Supabase Auth** issues JWTs. The API validates them (JWKS for asymmetric signing keys, optional
  HS256 legacy secret), checks issuer `{SUPABASE_URL}/auth/v1` and audience `authenticated`.
* **Authorization** is permission-based. Roles and permissions are read from the database
  (`user_roles`, `role_permissions`) and cached for 60 seconds. JWT `user_metadata` is never trusted,
  because users can edit it.

## Security layers

1. **API authorization** — every personal-data endpoint requires a valid JWT; admin endpoints require
   a specific permission (`users.manage`, `audit.read`, ...).
2. **RLS is enforced for user requests, not just configured.** User-scoped work runs inside a
   transaction that executes `SET LOCAL ROLE authenticated` and
   `set_config('request.jwt.claims', <claims>, true)`. `auth.uid()` then resolves to the caller, so even
   a missing `WHERE user_id = ...` in the API cannot leak another user's rows.
   Admin work runs with the privileged backend connection after the API permission check.
3. **Inactive users** — `profiles.is_active = false` makes the API return 403 and the user is banned in
   Supabase Auth so refresh tokens stop working.
4. **Secrets** — the Supabase secret (service role) key and the database connection string exist only
   in the backend environment. Mobile and web ship only the publishable (anon) key.
5. **Connection mode** — the backend uses a direct connection or the Supavisor *session* pooler, since
   transaction-local settings require a stable session within a transaction.
6. **Audit** — every admin mutation and every account deletion is written to `audit_logs`.

## Privacy

* Location history is stored **on the device** by default (SQLite via drift). Cloud sync is opt-in
  (`user_settings.history_cloud_sync`, default `false`).
* Usage statistics (`usage_events`) contain event type, platform and app version — **never coordinates**.
* Coordinates are never written to logs.
* Account deletion removes the Auth user, profile, settings, categories, favorites, routes, history and
  avatar. Audit rows keep the action but lose the user link (`ON DELETE SET NULL`).
* Data export: `GET /api/v1/me/export`.

## Technology decisions

| Area | Decision | Reason |
|---|---|---|
| Backend | .NET 10 (LTS), ASP.NET Core controllers | .NET 8 support ends Nov 2026 |
| ORM | EF Core 10 + Npgsql | |
| Validation | FluentValidation | |
| Mapping / mediator | Hand-written mapping, plain services | AutoMapper and MediatR moved to commercial licences |
| Tests | xUnit + Shouldly | FluentAssertions v8 is commercial |
| Logging | Serilog (JSON console + rolling file) | |
| Errors | `IExceptionHandler` + RFC 9457 ProblemDetails | |
| Versioning | Asp.Versioning, URL segment `/api/v1` | |
| Mobile | Flutter, Riverpod, go_router, dio, drift, supabase_flutter, maplibre_gl | |
| Android simulation | Kotlin: `LocationManager` test providers + Fused mock mode, foreground service | official, no root |
| Web | npm workspaces: `apps/site`, `apps/admin`, `packages/ui`, `packages/api-client` | one design system |
| Site | React Router v7 framework mode with static prerender, Tailwind v4 | SEO |
| Admin | Vite SPA, React Router, TanStack Query, Recharts | |
| Map tiles | OpenFreeMap vector tiles (no key, free, OSM attribution required) | zero cost |
| Geocoding | Backend proxy with pluggable provider: Photon (default), Nominatim, MapTiler; cached and rate limited | provider can change without app release |

### Map service evaluation

| Option | Cost | Notes |
|---|---|---|
| Google Maps | Mobile map loads free; Geocoding/Places billed per request after free tier; billing account required | strongest POI search, but requires API key in app and billing |
| Mapbox | Free tier (25k mobile MAU / 50k web loads), then paid; token required | good styling |
| **MapLibre + OpenFreeMap** (chosen) | Free, no key, no usage limit published; OSM attribution required | vector tiles, light/dark styles; no satellite imagery |
| Geocoding: Photon / Nominatim public | Free, fair-use (Nominatim: max 1 req/s, valid User-Agent) | proxied + cached by backend; for production traffic use MapTiler key or self-host |

Satellite view is offered only when a MapTiler key is configured. Without it, the option is hidden.

## Repository layout

```
backend/    .NET solution (API, Application, Domain, Infrastructure, tests)
supabase/   config, migrations, seed, scripts, pgTAP tests
mobile/     Flutter app (+ Kotlin mock location plugin)
web/        npm workspaces: site, admin, ui, api-client
docs/       this documentation
```
