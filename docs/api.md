# API (`/api/v1`)

Full, always-current reference: Swagger UI at `http://localhost:5080/swagger` when the API runs.

## Conventions

* Auth: `Authorization: Bearer <Supabase access token>`.
* Errors: RFC 9457 `application/problem+json` (`type`, `title`, `status`, `detail`, `errors`, `traceId`).
* Paging: `page` (1-based), `pageSize` (default 20, max 100) → `{ items, page, pageSize, totalCount }`.
* Sorting: `sort=field:asc|desc`, whitelisted per endpoint.
* Every admin mutation writes an `audit_logs` row.

## Public (anonymous, rate limited)

| Method | Path | |
|---|---|---|
| GET | `/public/app-config?platform=&version=` | min version, force update, active announcements, feature flags |
| GET | `/public/releases/latest?platform=` | latest published release (site download area) |
| POST | `/public/contact` | contact form |
| GET | `/health`, `/health/ready` | liveness / readiness (DB + Auth) |

## User (JWT)

| Method | Path | |
|---|---|---|
| GET | `/me` | profile + roles + permissions + settings |
| PATCH | `/me/profile` | display name |
| POST | `/me/avatar` | multipart image upload |
| DELETE | `/me` | delete account and all personal data |
| GET | `/me/export` | personal data export (JSON) |
| GET / PUT | `/me/settings` | |
| GET / POST | `/categories` | |
| PUT / DELETE | `/categories/{id}` | |
| GET | `/favorites?search=&categoryId=&page=&pageSize=&sort=` | |
| POST | `/favorites` | |
| GET / PUT / DELETE | `/favorites/{id}` | |
| GET | `/history?from=&to=&page=&pageSize=&sort=` | cloud history (only if sync enabled) |
| POST | `/history/batch` | idempotent sync by `clientId` |
| DELETE | `/history/{id}`, `/history` | |
| DELETE | `/history/client/{clientId}` | delete the cloud copy of a device entry (idempotent) |
| GET / POST | `/routes` | |
| GET / PUT / DELETE | `/routes/{id}` | |
| GET | `/geocoding/search?q=&lang=&limit=` | |
| GET | `/geocoding/reverse?lat=&lng=&lang=` | |
| POST | `/usage-events` | batch, no coordinates |

## Admin (permission based)

| Method | Path | Permission |
|---|---|---|
| GET | `/admin/dashboard/summary` | `dashboard.read` |
| GET | `/admin/dashboard/timeseries?metric=&granularity=day\|month&from=&to=` | `dashboard.read` |
| GET | `/admin/dashboard/feature-usage?from=&to=` | `dashboard.read` |
| GET | `/admin/dashboard/system-health` | `dashboard.read` |
| GET | `/admin/users?search=&role=&status=&page=&sort=` | `users.read` |
| GET | `/admin/users/{id}`, `/admin/users/{id}/stats` | `users.read` |
| PATCH | `/admin/users/{id}/status` | `users.manage` |
| PUT | `/admin/users/{id}/roles` | `roles.manage` |
| GET | `/admin/admins` | `users.read` |
| GET / POST | `/admin/roles` | `roles.manage` |
| PUT / DELETE | `/admin/roles/{id}` | `roles.manage` |
| GET | `/admin/permissions` | `roles.manage` |
| GET | `/admin/system-settings` | `settings.manage` |
| PUT | `/admin/system-settings/{key}` | `settings.manage` |
| GET / POST | `/admin/app-versions` | `versions.manage` |
| PUT / DELETE | `/admin/app-versions/{id}` | `versions.manage` |
| POST | `/admin/app-versions/{id}/artifact` | `versions.manage` |
| GET / POST | `/admin/announcements` | `announcements.manage` |
| PUT / DELETE | `/admin/announcements/{id}` | `announcements.manage` |
| GET | `/admin/audit-logs?userId=&action=&entity=&from=&to=&page=` | `audit.read` |
| GET | `/admin/contact-messages?status=&page=` | `messages.manage` |
| PATCH | `/admin/contact-messages/{id}` | `messages.manage` |

Guards: an admin cannot deactivate themselves; the last `superadmin` cannot lose the role; system
roles cannot be deleted.
