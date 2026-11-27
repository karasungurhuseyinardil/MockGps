-- Row Level Security.
-- The API runs user-scoped work as `authenticated` with the caller's JWT claims, so these policies are
-- a real second layer: a bug in an API query still cannot read or modify another user's rows.
-- Backend-only tables get RLS with no policies and no grants for `authenticated` / `anon`.

alter table app.profiles            enable row level security;
alter table app.roles               enable row level security;
alter table app.role_permissions    enable row level security;
alter table app.user_roles          enable row level security;
alter table app.user_settings       enable row level security;
alter table app.location_categories enable row level security;
alter table app.favorite_locations  enable row level security;
alter table app.location_history    enable row level security;
alter table app.saved_routes        enable row level security;
alter table app.usage_events        enable row level security;
alter table app.system_settings     enable row level security;
alter table app.app_versions        enable row level security;
alter table app.announcements       enable row level security;
alter table app.contact_messages    enable row level security;
alter table app.audit_logs          enable row level security;

-- Nothing for anon in the app schema.
revoke all on all tables in schema app from anon, authenticated;

-- ---------------------------------------------------------------------------
-- profiles: read own row; only display_name / avatar_path are user-updatable.
-- is_active, email, last_seen_at are managed by the backend.
-- ---------------------------------------------------------------------------
grant select on app.profiles to authenticated;
grant update (display_name, avatar_path) on app.profiles to authenticated;

create policy profiles_select_own on app.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on app.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- user_settings: read + update own (row is created by trigger).
-- ---------------------------------------------------------------------------
grant select on app.user_settings to authenticated;
grant update (theme, language, default_map_type, history_enabled, history_cloud_sync,
              notifications_enabled, default_accuracy_m, update_interval_ms)
  on app.user_settings to authenticated;

create policy user_settings_select_own on app.user_settings
  for select to authenticated using (user_id = (select auth.uid()));
create policy user_settings_update_own on app.user_settings
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Owner-only CRUD tables
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on app.location_categories to authenticated;
grant select, insert, update, delete on app.favorite_locations  to authenticated;
grant select, insert, delete         on app.location_history    to authenticated;
grant select, insert, update, delete on app.saved_routes        to authenticated;

create policy location_categories_owner on app.location_categories
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy favorite_locations_owner on app.favorite_locations
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy location_history_owner on app.location_history
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy saved_routes_owner on app.saved_routes
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- user_roles: a user may see their own role links (never modify them).
grant select on app.user_roles to authenticated;
create policy user_roles_select_own on app.user_roles
  for select to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- service_role (backend tooling) has full access; it bypasses RLS.
-- ---------------------------------------------------------------------------
grant all on all tables in schema app to service_role;
