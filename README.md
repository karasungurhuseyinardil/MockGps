# Mock GPS — Location Simulation Platform

Ad-free location simulation for developers and QA: pick a point on the map (or type coordinates /
search an address) and Android apps on the device see that location through Android's official mock
location mechanism. No root.

| Part | Path | Stack | Tests |
|---|---|---|---|
| Database & auth | [supabase/](supabase/) | Supabase Postgres, Auth, Storage, RLS | 35 pgTAP RLS checks |
| API | [backend/](backend/) | .NET 10, EF Core, FluentValidation, Serilog, Swagger | 30 unit · 10 integration |
| Mobile app | [mobile/](mobile/) | Flutter + Kotlin mock location service | 30 Flutter · 6 Kotlin · 5 on-device |
| Website | [web/apps/site](web/apps/site) | React Router 7 (pre-rendered), Tailwind 4, TR/EN | 9 |
| Admin panel | [web/apps/admin](web/apps/admin) | React, TanStack Query, Recharts | 9 |

Docs: [architecture](docs/architecture.md) · [database](docs/er-diagram.md) · [API](docs/api.md) ·
[Android mock location](docs/android-mock-location.md) · [iOS limitations](docs/ios-limitations.md) ·
[design system](docs/design-system.md) · [testing](docs/testing.md) · [deployment](docs/deployment.md)

## Platform limits (read first)

* **Android**: works without root. Developer options must be on and this app selected as
  *mock location app*. Android marks mocked locations; apps that check for this (banking, some games)
  can detect and refuse them — the app does not try to hide it.
* **iOS**: no public API exists for system-wide location simulation. The iOS app manages favorites,
  routes and history and exports GPX files for Xcode's *Simulate Location*.

## Local development

Requirements: Docker Desktop, Node 20+, .NET SDK 10, Flutter 3.44+, Android SDK.

### 1. Supabase (local)

```bash
npx supabase start        # first run downloads Docker images
npx supabase db reset     # re-applies migrations + seed
npx supabase test db      # RLS tests (pgTAP)
```

Studio: http://127.0.0.1:54323 · Mail (confirmation emails): http://127.0.0.1:54324

### 2. API

```bash
cd backend/src/MockGps.API
dotnet user-secrets set "ConnectionStrings:Database" "Host=127.0.0.1;Port=54322;Database=postgres;Username=postgres;Password=postgres"
dotnet user-secrets set "Supabase:Url" "http://127.0.0.1:54321"
dotnet user-secrets set "Supabase:SecretKey" "<Secret key printed by `npx supabase status`>"
dotnet user-secrets set "Supabase:JwtSecret" "<JWT secret printed by `npx supabase status -o env`>"
cd ../..
dotnet run --project src/MockGps.API      # http://localhost:5080/swagger
dotnet test                                # unit + integration (needs local Supabase running)
```

### 3. Website and admin

```bash
cd web
npm install
npm run api:types            # regenerate the typed API client (API must be running)
npm run dev:site             # http://localhost:5173  (TR: /tr)
npm run dev:admin            # http://localhost:5174
```

Create `web/apps/site/.env.local` and `web/apps/admin/.env.local` from the `.env.example` files.

### 4. Android app

```bash
cd mobile
cp env/dev.example.json env/dev.json        # fill in values
./tool/dev-device.ps1 -GrantSetup           # USB or wireless debugging; tunnels API + Supabase, runs the app
```

See [docs/android-mock-location.md](docs/android-mock-location.md) for the device setup the app guides
users through.

### 5. Make yourself an admin

Sign up in an app (or Supabase Studio → Authentication), then:

```bash
docker exec -i supabase_db_mockgps psql -U postgres -v email="'you@example.com'" < supabase/scripts/grant_superadmin.sql
```

## Configuration

All configuration comes from environment variables; see `backend/.env.example` (and later
`mobile/env/*.example.json`, `web/apps/*/.env.example`). Real `.env` files are git-ignored.
The Supabase **secret key** lives only in the backend.

## Security model (short)

* Clients use Supabase Auth only for sign-in/sign-up; all data goes through the API.
* Application tables live in the `app` schema, which the Supabase Data API does not expose.
* The API validates Supabase JWTs and loads roles/permissions from the database.
* User-scoped queries run as the Postgres `authenticated` role with the caller's claims, so RLS is
  enforced even if an API query forgets a filter.
* Admin actions are written to `audit_logs`. Deactivated users are banned in Supabase Auth.
