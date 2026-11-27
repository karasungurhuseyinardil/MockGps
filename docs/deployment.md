# Deployment

Four deployable parts: **Supabase** (database, auth, storage), **API** (Docker container),
**website** and **admin** (static files), **Android app** (signed APK/AAB).

## 1. Supabase (cloud)

1. Create a project at supabase.com. Note the project ref, database password, URL, publishable key and
   secret key (Project Settings → API keys).
2. Link and push the schema (runs every file in `supabase/migrations`, including roles, permissions,
   system settings and RLS):
   ```bash
   npx supabase link --project-ref <ref>
   npx supabase db push
   ```
3. Storage buckets: create `avatars` (private, 2 MB, image/png|jpeg|webp) and `releases` (public,
   200 MB, APK). Locally they come from `supabase/config.toml`.
4. Auth (Authentication → URL configuration):
   * Site URL: `https://<your-site>`
   * Redirect URLs: `https://<your-site>/**`, `https://<your-admin>/**`, `mockgps://auth-callback`
   * Email: enable confirmations, minimum password length 8 with letters and digits, set up a real SMTP
     provider (the built-in sender is rate limited).
5. Make the first superadmin after they signed up once:
   run `supabase/scripts/grant_superadmin.sql` in the SQL editor, replacing `:email` with the quoted
   address.

## 2. API (Docker)

```bash
docker build -t mockgps-api ./backend
docker run -p 8080:8080 --env-file backend/.env mockgps-api
```

Environment variables: see `backend/.env.example`. Required:

| Variable | Notes |
|---|---|
| `ConnectionStrings__Database` | Direct connection or **session** pooler (port 5432). Not the transaction pooler: RLS scoping uses transaction-local settings. `SSL Mode=Require`. |
| `Supabase__Url` | `https://<ref>.supabase.co` |
| `Supabase__SecretKey` | Secret / service role key. Backend only. |
| `Cors__AllowedOrigins__0..n` | Site and admin origins. |
| `ForwardedHeaders__KnownProxies__0..n` | IPs of your reverse proxy, so client IPs in audit logs and rate limits are correct. |

Health checks for the platform: liveness `GET /health`, readiness `GET /health/ready` (database).
Swagger is off in production unless `Swagger__Enabled=true`. Logs are JSON on stdout plus a 14-day
rolling file in `logs/`.

Any container host works (Azure Container Apps, Fly.io, Render, a VM with Docker). Put it behind
HTTPS; HSTS is enabled outside Development.

## 3. Website and admin (static)

```bash
cd web
npm ci
VITE_API_BASE_URL=https://api.example.com VITE_SITE_URL=https://mockgps.example.com \
VITE_SUPABASE_URL=https://<ref>.supabase.co VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
npm run build
```

* Site: upload `web/apps/site/build/client`. Every page is a pre-rendered `index.html` (EN at `/`, TR
  at `/tr/...`), plus `sitemap.xml` and `robots.txt`. Serve `__spa-fallback.html` for unknown paths
  (or a 404 page).
* Admin: upload `web/apps/admin/dist` and rewrite all paths to `index.html` (single-page app). The admin
  sends `X-Robots-Tag`-equivalent `noindex` via meta; keep it off public search.
* Any static host works (Cloudflare Pages, Netlify, Vercel, S3 + CloudFront, nginx).
* Add product screenshots to `web/apps/site/public/screens/` (`map.png`, `favorites.png`, `route.png`,
  `setup.png`) — real device captures, 1080×2280 or similar.

## 4. Android app

1. Create an upload keystore once and keep it out of git:
   ```bash
   keytool -genkey -v -keystore ~/mockgps-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. `mobile/android/key.properties` (git-ignored):
   ```properties
   storeFile=C:/path/mockgps-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. Production config in `mobile/env/prod.json` (git-ignored, public values only):
   `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `WEBSITE_URL`.
4. Build:
   ```bash
   cd mobile
   flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json   # direct download
   flutter build appbundle --release --dart-define-from-file=env/prod.json             # Google Play
   ```
5. Publish: Admin → App versions → New version (same version/build as `pubspec.yaml`), upload the
   arm64 APK, set the minimum supported build, publish. The website download area and the in-app
   update banner read this automatically.

Google Play note: apps that use `ACCESS_MOCK_LOCATION` and a foreground service of type `location`
must describe the use in the Play Console declarations (foreground service and data safety forms).

## 5. iOS

Building requires macOS + Xcode (`flutter build ipa`). The iOS app does not offer system-wide
simulation (see `docs/ios-limitations.md`).

## Checklist before going live

- [ ] Real SMTP configured in Supabase Auth; email templates point to your domain.
- [ ] `support_email` system setting set in Admin → System settings.
- [ ] CORS origins and forwarded-header proxies set on the API.
- [ ] For production geocoding traffic: `Geocoding__Provider=maptiler` with a key, or a self-hosted
      Photon/Nominatim (public instances are fair-use only).
- [ ] First superadmin granted; a second admin account exists (the last superadmin cannot be removed).
- [ ] Backups enabled for the Supabase project.
