-- Reference data (roles, permissions, system settings) and Supabase Auth integration.

-- ---------------------------------------------------------------------------
-- Roles & permissions
-- ---------------------------------------------------------------------------
insert into app.roles (name, description, is_system) values
  ('user',       'Standard application user', true),
  ('admin',      'Administrator: manages users, content and settings', true),
  ('superadmin', 'Full access including role management', true)
on conflict (name) do nothing;

insert into app.role_permissions (role_id, permission)
select r.id, p.permission
from app.roles r
cross join lateral (
  select unnest(case r.name
    when 'admin' then array[
      'dashboard.read', 'users.read', 'users.manage', 'settings.manage', 'versions.manage',
      'announcements.manage', 'audit.read', 'messages.manage']
    when 'superadmin' then array[
      'dashboard.read', 'users.read', 'users.manage', 'roles.manage', 'settings.manage',
      'versions.manage', 'announcements.manage', 'audit.read', 'messages.manage']
    else array[]::text[]
  end) as permission
) p
on conflict (role_id, permission) do nothing;

-- ---------------------------------------------------------------------------
-- System settings (each one is read and enforced by the API)
-- ---------------------------------------------------------------------------
insert into app.system_settings (key, value, description) values
  ('maintenance_mode',        'false'::jsonb, 'When true, non-admin API calls return 503 and apps show a maintenance notice.'),
  ('geocoding_enabled',       'true'::jsonb,  'Enables address search and reverse geocoding.'),
  ('history_max_cloud_items', '1000'::jsonb,  'Maximum cloud history rows kept per user (oldest are removed).'),
  ('support_email',           '"support@example.com"'::jsonb, 'Support address shown on the website and in the app.')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- New Supabase Auth user -> profile, settings, default role, default categories
-- ---------------------------------------------------------------------------
create or replace function app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lang text := case when new.raw_user_meta_data ->> 'language' = 'tr' then 'tr' else 'en' end;
  v_name text := nullif(left(trim(new.raw_user_meta_data ->> 'display_name'), 80), '');
begin
  insert into app.profiles (id, email, display_name)
  values (new.id, coalesce(new.email, ''), v_name);

  insert into app.user_settings (user_id, language)
  values (new.id, v_lang);

  insert into app.user_roles (user_id, role_id)
  select new.id, r.id from app.roles r where r.name = 'user';

  insert into app.location_categories (user_id, name, icon, color, sort_order)
  select new.id, c.name, c.icon, c.color, c.sort_order
  from (values
    (case when v_lang = 'tr' then 'İş'                 else 'Work'           end, 'briefcase', '#3457F5', 0),
    (case when v_lang = 'tr' then 'Ev'                 else 'Home'           end, 'home',      '#16A34A', 1),
    (case when v_lang = 'tr' then 'Test Lokasyonları'  else 'Test locations' end, 'flask',     '#D97706', 2),
    (case when v_lang = 'tr' then 'Şehirler'           else 'Cities'         end, 'building',  '#7C3AED', 3),
    (case when v_lang = 'tr' then 'Özel Konumlar'      else 'Custom'         end, 'star',      '#F2542D', 4)
  ) as c (name, icon, color, sort_order);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- Keep profile email in sync when the user confirms an email change.
create or replace function app.handle_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update app.profiles set email = coalesce(new.email, '') where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function app.handle_user_email_change();

revoke all on function app.handle_new_user() from public, anon, authenticated;
revoke all on function app.handle_user_email_change() from public, anon, authenticated;
revoke all on function app.set_updated_at() from public, anon;
