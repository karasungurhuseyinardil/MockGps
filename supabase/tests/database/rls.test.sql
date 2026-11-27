-- RLS and schema security tests. Run with: npx supabase test db
begin;
create extension if not exists pgtap with schema extensions;
set search_path = extensions, public;

select plan(35);

-- ---------------------------------------------------------------------------
-- Fixtures: two users created through auth.users (triggers build their profiles)
-- ---------------------------------------------------------------------------
insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'alice@test.local', '{"language":"tr","display_name":"Alice"}', now(), now()),
  ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'bob@test.local', '{}', now(), now());

-- Trigger results
select is((select count(*)::int from app.profiles where id in ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222')), 2, 'profiles created by trigger');
select is((select display_name from app.profiles where id = '11111111-1111-1111-1111-111111111111'), 'Alice', 'display_name copied from metadata');
select is((select language from app.user_settings where user_id = '11111111-1111-1111-1111-111111111111'), 'tr', 'settings language from metadata');
select is((select history_cloud_sync from app.user_settings where user_id = '22222222-2222-2222-2222-222222222222'), false, 'cloud history sync is off by default');
select is((select count(*)::int from app.location_categories where user_id = '11111111-1111-1111-1111-111111111111'), 5, 'five default categories');
select ok(exists(select 1 from app.location_categories where user_id = '11111111-1111-1111-1111-111111111111' and name = 'Test Lokasyonları'), 'Turkish category names for tr users');
select ok(exists(select 1 from app.location_categories where user_id = '22222222-2222-2222-2222-222222222222' and name = 'Test locations'), 'English category names by default');
select is((select r.name from app.user_roles ur join app.roles r on r.id = ur.role_id where ur.user_id = '22222222-2222-2222-2222-222222222222'), 'user', 'default role is user');

-- Data owned by Bob (inserted as owner/postgres)
insert into app.favorite_locations (id, user_id, name, latitude, longitude)
values ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Bob secret', 52.52, 13.405);
insert into app.location_history (user_id, client_id, latitude, longitude)
values ('22222222-2222-2222-2222-222222222222', gen_random_uuid(), 41.0, 29.0);
insert into app.saved_routes (user_id, name, points)
values ('22222222-2222-2222-2222-222222222222', 'Bob route', '[{"lat":1,"lng":1},{"lat":2,"lng":2}]');

-- ---------------------------------------------------------------------------
-- Act as Alice
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

select is((select count(*)::int from app.profiles), 1, 'alice sees only her profile');
select is((select count(*)::int from app.favorite_locations), 0, 'alice cannot see bob favorites');
select is((select count(*)::int from app.location_history), 0, 'alice cannot see bob history');
select is((select count(*)::int from app.saved_routes), 0, 'alice cannot see bob routes');
select is((select count(*)::int from app.user_settings), 1, 'alice sees only her settings');
select is((select count(*)::int from app.location_categories), 5, 'alice sees only her categories');
select is((select count(*)::int from app.user_roles), 1, 'alice sees only her role links');

-- Alice can manage her own favorites
select lives_ok(
  $$ insert into app.favorite_locations (user_id, name, latitude, longitude)
     values ('11111111-1111-1111-1111-111111111111', 'Berlin', 52.52, 13.405) $$,
  'alice can insert own favorite');

-- ...but cannot insert for Bob
select throws_ok(
  $$ insert into app.favorite_locations (user_id, name, latitude, longitude)
     values ('22222222-2222-2222-2222-222222222222', 'Injected', 1, 1) $$,
  '42501', null, 'alice cannot insert a favorite for bob');

-- ...cannot update or delete Bob's rows (silently affects 0 rows)
update app.favorite_locations set name = 'pwned' where id = 'aaaaaaaa-0000-0000-0000-000000000001';
delete from app.favorite_locations where id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- ...cannot move her own favorite to Bob
select throws_ok(
  $$ update app.favorite_locations set user_id = '22222222-2222-2222-2222-222222222222' where name = 'Berlin' $$,
  '42501', null, 'alice cannot reassign a favorite to bob');

-- Profile column protection
select lives_ok($$ update app.profiles set display_name = 'Alice B' $$, 'alice can update her display name');
select throws_ok($$ update app.profiles set is_active = true $$, '42501', null, 'alice cannot change is_active');
select throws_ok($$ update app.profiles set email = 'x@y.z' $$, '42501', null, 'alice cannot change email');

-- Role escalation attempts
select throws_ok(
  $$ insert into app.user_roles (user_id, role_id) select '11111111-1111-1111-1111-111111111111', id from app.roles where name = 'superadmin' $$,
  '42501', null, 'alice cannot grant herself a role');
select throws_ok($$ select * from app.roles $$, '42501', null, 'roles table is backend only');
select throws_ok($$ select * from app.audit_logs $$, '42501', null, 'audit logs are backend only');
select throws_ok($$ select * from app.system_settings $$, '42501', null, 'system settings are backend only');
select throws_ok($$ select * from app.usage_events $$, '42501', null, 'usage events are backend only');
select throws_ok($$ select * from app.contact_messages $$, '42501', null, 'contact messages are backend only');

-- History rows cannot be edited, only created/deleted
select throws_ok($$ update app.location_history set latitude = 0 $$, '42501', null, 'history rows are immutable');

-- Categories: a favorite cannot reference another user's category
reset role;
create temporary table bob_cat as
  select id from app.location_categories where user_id = '22222222-2222-2222-2222-222222222222' limit 1;
grant select on bob_cat to authenticated;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select throws_ok(
  $$ insert into app.favorite_locations (user_id, category_id, name, latitude, longitude)
     select '11111111-1111-1111-1111-111111111111', id, 'cross', 1, 1 from bob_cat $$,
  '23503', null, 'favorite cannot use another user''s category');

-- Anonymous role sees nothing
reset role;
set local role anon;
select throws_ok($$ select * from app.favorite_locations $$, '42501', null, 'anon has no access to favorites');
select throws_ok($$ select * from app.profiles $$, '42501', null, 'anon has no access to profiles');

-- ---------------------------------------------------------------------------
-- Verify as owner that Bob's data is untouched
-- ---------------------------------------------------------------------------
reset role;
select is((select name from app.favorite_locations where id = 'aaaaaaaa-0000-0000-0000-000000000001'), 'Bob secret', 'bob favorite not modified by alice');
select is((select count(*)::int from app.favorite_locations where user_id = '11111111-1111-1111-1111-111111111111'), 1, 'alice favorite stored');

-- Cascade: deleting the auth user removes personal data
delete from auth.users where id = '22222222-2222-2222-2222-222222222222';
select is((select count(*)::int from app.favorite_locations where user_id = '22222222-2222-2222-2222-222222222222'), 0, 'favorites removed with account');
select is((select count(*)::int from app.location_history where user_id = '22222222-2222-2222-2222-222222222222'), 0, 'history removed with account');

select * from finish();
rollback;
