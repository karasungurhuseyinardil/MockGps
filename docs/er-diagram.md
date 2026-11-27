# Database (Supabase PostgreSQL)

Schema is versioned in `supabase/migrations`. All primary keys are `uuid`, timestamps are `timestamptz`.

```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "id (cascade)"
  PROFILES ||--|| USER_SETTINGS : user_id
  PROFILES ||--o{ USER_ROLES : user_id
  ROLES ||--o{ USER_ROLES : role_id
  ROLES ||--o{ ROLE_PERMISSIONS : role_id
  PROFILES ||--o{ LOCATION_CATEGORIES : user_id
  LOCATION_CATEGORIES ||--o{ FAVORITE_LOCATIONS : "category_id (set null)"
  PROFILES ||--o{ FAVORITE_LOCATIONS : user_id
  PROFILES ||--o{ LOCATION_HISTORY : user_id
  PROFILES ||--o{ SAVED_ROUTES : user_id
  PROFILES ||--o{ USAGE_EVENTS : "user_id (set null)"
  PROFILES ||--o{ AUDIT_LOGS : "user_id (set null)"

  PROFILES {
    uuid id PK
    text email
    text display_name
    text avatar_url
    bool is_active
    timestamptz last_seen_at
  }
  ROLES { uuid id PK
    text name UK
    text description
    bool is_system }
  ROLE_PERMISSIONS { uuid id PK
    uuid role_id FK
    text permission }
  USER_ROLES { uuid id PK
    uuid user_id FK
    uuid role_id FK }
  LOCATION_CATEGORIES { uuid id PK
    uuid user_id FK
    text name
    text icon
    text color
    int sort_order }
  FAVORITE_LOCATIONS { uuid id PK
    uuid user_id FK
    uuid category_id FK
    text name
    text description
    float8 latitude
    float8 longitude
    text address }
  LOCATION_HISTORY { uuid id PK
    uuid user_id FK
    float8 latitude
    float8 longitude
    text address
    text source
    uuid client_id }
  SAVED_ROUTES { uuid id PK
    uuid user_id FK
    text name
    jsonb points
    float8 speed_kmh
    bool loop }
  USER_SETTINGS { uuid id PK
    uuid user_id FK
    text theme
    text language
    text default_map_type
    bool history_enabled
    bool history_cloud_sync
    bool notifications_enabled
    int default_accuracy_m
    int update_interval_ms }
  USAGE_EVENTS { uuid id PK
    uuid user_id FK
    text event_type
    text platform
    text app_version }
  AUDIT_LOGS { uuid id PK
    uuid user_id FK
    text action
    text entity
    text entity_id
    text description
    jsonb metadata
    text ip_address }
```

Standalone tables: `system_settings`, `app_versions`, `announcements`, `contact_messages`.

## Rules

* `handle_new_user()` trigger on `auth.users` creates profile, settings, `user` role and the 5 default
  categories (Work, Home, Test locations, Cities, Custom — localised names stored per user language).
* RLS on user tables: owner only (`auth.uid() = user_id`).
* Backend-only tables (`roles`, `role_permissions`, `user_roles`, `audit_logs`, `system_settings`,
  `contact_messages`, `usage_events`, `app_versions`, `announcements`): no access for `anon` /
  `authenticated`.
* `profiles`: owner can read; `is_active` and `email` are not updatable by the user (column grants).
* Storage buckets: `avatars` (private, `<user_id>/...` path policy), `releases` (public read, backend write).
