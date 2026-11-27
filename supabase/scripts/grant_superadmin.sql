-- Grants the superadmin role to an existing user.
-- Usage (local):
--   docker exec -i supabase_db_mockgps psql -U postgres -v email="'you@example.com'" < supabase/scripts/grant_superadmin.sql
-- Usage (cloud): run in the SQL editor after replacing :email with the quoted address.

insert into app.user_roles (user_id, role_id)
select p.id, r.id
from app.profiles p
join app.roles r on r.name = 'superadmin'
where lower(p.email) = lower(:email)
on conflict (user_id, role_id) do nothing;

insert into app.audit_logs (user_id, action, entity, entity_id, description)
select p.id, 'role.granted', 'user', p.id::text, 'superadmin granted by grant_superadmin.sql'
from app.profiles p
where lower(p.email) = lower(:email);

select p.email, array_agg(r.name order by r.name) as roles
from app.profiles p
join app.user_roles ur on ur.user_id = p.id
join app.roles r on r.id = ur.role_id
where lower(p.email) = lower(:email)
group by p.email;
