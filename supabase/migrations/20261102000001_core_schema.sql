-- Mock GPS core schema.
-- Application tables live in the `app` schema, which is NOT exposed through the Supabase Data API
-- (PostgREST). Clients must go through the .NET API. RLS still applies when the API runs user-scoped
-- work as the `authenticated` role.

create extension if not exists pg_trgm with schema extensions;

create schema if not exists app;
revoke all on schema app from public;
grant usage on schema app to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function app.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Profiles & authorization
-- ---------------------------------------------------------------------------
create table app.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text not null,
  display_name  text check (char_length(display_name) <= 80),
  avatar_path   text,
  is_active     boolean not null default true,
  last_seen_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index profiles_created_at_idx on app.profiles (created_at desc);
create index profiles_last_seen_idx on app.profiles (last_seen_at desc);
create index profiles_email_trgm_idx on app.profiles using gin (email extensions.gin_trgm_ops);
create index profiles_display_name_trgm_idx on app.profiles using gin (display_name extensions.gin_trgm_ops);

create table app.roles (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique check (name ~ '^[a-z][a-z0-9_]{1,31}$'),
  description text check (char_length(description) <= 200),
  is_system   boolean not null default false,
  created_at  timestamptz not null default now()
);

create table app.role_permissions (
  id          uuid primary key default gen_random_uuid(),
  role_id     uuid not null references app.roles (id) on delete cascade,
  permission  text not null check (permission ~ '^[a-z]+\.[a-z]+$'),
  unique (role_id, permission)
);

create table app.user_roles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references app.profiles (id) on delete cascade,
  role_id     uuid not null references app.roles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, role_id)
);
create index user_roles_role_idx on app.user_roles (role_id);

-- ---------------------------------------------------------------------------
-- User data
-- ---------------------------------------------------------------------------
create table app.user_settings (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null unique references app.profiles (id) on delete cascade,
  theme                  text not null default 'system' check (theme in ('system', 'light', 'dark')),
  language               text not null default 'en' check (language in ('tr', 'en')),
  default_map_type       text not null default 'standard' check (default_map_type in ('standard', 'light', 'dark', 'satellite')),
  history_enabled        boolean not null default true,
  history_cloud_sync     boolean not null default false,
  notifications_enabled  boolean not null default true,
  default_accuracy_m     integer not null default 5 check (default_accuracy_m between 1 and 500),
  update_interval_ms     integer not null default 1000 check (update_interval_ms between 200 and 60000),
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create table app.location_categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references app.profiles (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 40),
  icon        text not null default 'pin' check (char_length(icon) <= 32),
  color       text not null default '#3457F5' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, name),
  unique (id, user_id)
);

create table app.favorite_locations (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references app.profiles (id) on delete cascade,
  category_id  uuid,
  name         text not null check (char_length(name) between 1 and 80),
  description  text check (char_length(description) <= 500),
  latitude     double precision not null check (latitude between -90 and 90),
  longitude    double precision not null check (longitude between -180 and 180),
  address      text check (char_length(address) <= 300),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  -- A favorite can only point to a category of the same user.
  foreign key (category_id, user_id)
    references app.location_categories (id, user_id) on delete set null (category_id)
);
create index favorite_locations_user_created_idx on app.favorite_locations (user_id, created_at desc);
create index favorite_locations_category_idx on app.favorite_locations (category_id);
create index favorite_locations_name_trgm_idx on app.favorite_locations using gin (name extensions.gin_trgm_ops);

create table app.location_history (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references app.profiles (id) on delete cascade,
  client_id   uuid not null,
  latitude    double precision not null check (latitude between -90 and 90),
  longitude   double precision not null check (longitude between -180 and 180),
  address     text check (char_length(address) <= 300),
  source      text not null default 'map' check (source in ('map', 'manual', 'search', 'favorite', 'route', 'history')),
  created_at  timestamptz not null default now(),
  unique (user_id, client_id)
);
create index location_history_user_created_idx on app.location_history (user_id, created_at desc);

create table app.saved_routes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references app.profiles (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 80),
  points      jsonb not null check (jsonb_typeof(points) = 'array' and jsonb_array_length(points) between 2 and 500),
  speed_kmh   double precision not null default 30 check (speed_kmh > 0 and speed_kmh <= 1000),
  loop        boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index saved_routes_user_created_idx on app.saved_routes (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Platform / admin data (backend only)
-- ---------------------------------------------------------------------------
create table app.usage_events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references app.profiles (id) on delete set null,
  event_type   text not null check (event_type ~ '^[a-z][a-z_]{2,47}$'),
  platform     text not null check (platform in ('android', 'ios', 'web')),
  app_version  text check (char_length(app_version) <= 32),
  created_at   timestamptz not null default now()
);
create index usage_events_created_idx on app.usage_events (created_at desc);
create index usage_events_type_created_idx on app.usage_events (event_type, created_at desc);
create index usage_events_user_created_idx on app.usage_events (user_id, created_at desc);

create table app.system_settings (
  id           uuid primary key default gen_random_uuid(),
  key          text not null unique check (key ~ '^[a-z][a-z0-9_.]{1,63}$'),
  value        jsonb not null,
  description  text,
  updated_at   timestamptz not null default now(),
  updated_by   uuid references app.profiles (id) on delete set null
);

create table app.app_versions (
  id                   uuid primary key default gen_random_uuid(),
  platform             text not null check (platform in ('android', 'ios')),
  version              text not null check (version ~ '^\d+\.\d+\.\d+$'),
  build_number         integer not null check (build_number > 0),
  min_supported_build  integer not null default 1 check (min_supported_build > 0),
  download_url         text check (char_length(download_url) <= 500),
  file_size_bytes      bigint,
  release_notes        text check (char_length(release_notes) <= 4000),
  is_published         boolean not null default false,
  published_at         timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (platform, build_number),
  check (min_supported_build <= build_number)
);

create table app.announcements (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 1 and 120),
  body        text not null check (char_length(body) between 1 and 2000),
  level       text not null default 'info' check (level in ('info', 'warning', 'critical')),
  audience    text not null default 'all' check (audience in ('all', 'android', 'ios', 'web')),
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz,
  is_active   boolean not null default true,
  created_by  uuid references app.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);
create index announcements_active_idx on app.announcements (is_active, starts_at, ends_at);

create table app.contact_messages (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 100),
  email       text not null check (char_length(email) between 3 and 254),
  subject     text not null check (char_length(subject) between 1 and 150),
  message     text not null check (char_length(message) between 1 and 5000),
  status      text not null default 'new' check (status in ('new', 'read', 'archived')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index contact_messages_status_created_idx on app.contact_messages (status, created_at desc);

create table app.audit_logs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references app.profiles (id) on delete set null,
  action       text not null check (char_length(action) <= 64),
  entity       text not null check (char_length(entity) <= 64),
  entity_id    text check (char_length(entity_id) <= 64),
  description  text check (char_length(description) <= 1000),
  metadata     jsonb,
  ip_address   text check (char_length(ip_address) <= 64),
  created_at   timestamptz not null default now()
);
create index audit_logs_created_idx on app.audit_logs (created_at desc);
create index audit_logs_entity_action_idx on app.audit_logs (entity, action, created_at desc);
create index audit_logs_user_idx on app.audit_logs (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
create trigger set_updated_at before update on app.profiles            for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.user_settings       for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.location_categories for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.favorite_locations  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.saved_routes        for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.system_settings     for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.app_versions        for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.announcements       for each row execute function app.set_updated_at();
create trigger set_updated_at before update on app.contact_messages    for each row execute function app.set_updated_at();
