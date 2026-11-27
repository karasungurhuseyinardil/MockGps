import { Badge, Button, Card, ErrorState, Input, Select, Skeleton, Textarea } from "@mockgps/ui";
import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Search } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router";
import { ConfirmDialog, DataTable, Modal, PageHeader, Pagination, errorMessage, useToast, type Column } from "../components/ui";
import { api, unwrap, type UserListItem } from "../lib/api";
import { useAuth } from "../lib/auth";
import { formatDate, formatNumber, useI18n } from "../lib/i18n";

function useDebounced<T>(value: T, ms = 300) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setV(value), ms);
    return () => clearTimeout(id);
  }, [value, ms]);
  return v;
}

export function UsersPage({ adminsOnly = false }: { adminsOnly?: boolean }) {
  const { t, lang } = useI18n();
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [role, setRole] = useState("");
  const [page, setPage] = useState(1);
  const debounced = useDebounced(search);
  useEffect(() => setPage(1), [debounced, status, role]);

  const roles = useQuery({ queryKey: ["roles"], queryFn: () => unwrap(api.GET("/api/v1/admin/roles")), enabled: !adminsOnly, retry: false });
  const users = useQuery({
    queryKey: ["users", adminsOnly, debounced, status, role, page],
    placeholderData: keepPreviousData,
    queryFn: () =>
      adminsOnly
        ? unwrap(api.GET("/api/v1/admin/admins", { params: { query: { Page: page, PageSize: 20 } } }))
        : unwrap(
            api.GET("/api/v1/admin/users", {
              params: { query: { Page: page, PageSize: 20, Search: debounced || undefined, Status: status || undefined, Role: role || undefined, Sort: "created_at:desc" } },
            }),
          ),
  });

  const columns: Column<UserListItem>[] = [
    {
      key: "email",
      header: t.users.email,
      cell: (u) => (
        <Link to={`/users/${u.id}`} className="font-medium break-all hover:text-primary" onClick={(e) => e.stopPropagation()}>
          {u.email}
          {u.displayName && <span className="block text-xs font-normal text-muted">{u.displayName}</span>}
        </Link>
      ),
    },
    { key: "roles", header: t.users.roles, cell: (u) => <div className="flex flex-wrap gap-1">{u.roles.map((r) => <Badge key={r} tone={r === "user" ? "neutral" : "primary"}>{r}</Badge>)}</div> },
    { key: "status", header: t.users.status, cell: (u) => <Badge tone={u.isActive ? "success" : "danger"}>{u.isActive ? t.users.active : t.users.disabled}</Badge> },
    { key: "created", header: t.users.created, className: "whitespace-nowrap", cell: (u) => <span className="text-muted">{formatDate(u.createdAt, lang, false)}</span> },
    { key: "seen", header: t.users.lastSeen, className: "whitespace-nowrap", cell: (u) => <span className="text-muted">{u.lastSeenAt ? formatDate(u.lastSeenAt, lang) : t.users.never}</span> },
  ];

  return (
    <>
      <PageHeader title={adminsOnly ? t.nav.admins : t.users.title} />
      {!adminsOnly && (
        <div className="mb-4 grid gap-3 sm:grid-cols-[1fr_180px_180px]">
          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" aria-hidden />
            <Input aria-label={t.users.searchHint} placeholder={t.users.searchHint} value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
          </div>
          <Select aria-label={t.users.status} value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">{t.users.status}: {t.common.all}</option>
            <option value="active">{t.users.active}</option>
            <option value="inactive">{t.users.disabled}</option>
          </Select>
          <Select aria-label={t.users.role} value={role} onChange={(e) => setRole(e.target.value)}>
            <option value="">{t.users.role}: {t.common.all}</option>
            {roles.data?.map((r) => (
              <option key={r.id} value={r.name}>{r.name}</option>
            ))}
          </Select>
        </div>
      )}
      <DataTable
        columns={columns}
        rows={users.data?.items}
        rowKey={(u) => u.id}
        loading={users.isLoading}
        error={users.error}
        onRetry={() => users.refetch()}
        onRowClick={(u) => navigate(`/users/${u.id}`)}
        emptyText={debounced || status || role ? t.common.noMatch : undefined}
      />
      {users.data && users.data.totalCount > 0 && <Pagination page={page} pageSize={20} total={users.data.totalCount} onPage={setPage} />}
      <p className="sr-only" aria-live="polite">{users.data ? formatNumber(users.data.totalCount, lang) : ""}</p>
    </>
  );
}

export function UserDetailPage() {
  const { id = "" } = useParams();
  const { t, lang } = useI18n();
  const { can, me } = useAuth();
  const toast = useToast();
  const qc = useQueryClient();
  const [statusOpen, setStatusOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [rolesOpen, setRolesOpen] = useState(false);
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);

  const user = useQuery({ queryKey: ["user", id], queryFn: () => unwrap(api.GET("/api/v1/admin/users/{id}", { params: { path: { id } } })) });
  const stats = useQuery({ queryKey: ["user", id, "stats"], queryFn: () => unwrap(api.GET("/api/v1/admin/users/{id}/stats", { params: { path: { id } } })) });
  const roles = useQuery({ queryKey: ["roles"], queryFn: () => unwrap(api.GET("/api/v1/admin/roles")), enabled: can("roles.manage") });

  const refresh = () => {
    void qc.invalidateQueries({ queryKey: ["user", id] });
    void qc.invalidateQueries({ queryKey: ["users"] });
  };

  const setStatus = useMutation({
    mutationFn: (isActive: boolean) => unwrap(api.PATCH("/api/v1/admin/users/{id}/status", { params: { path: { id } }, body: { isActive, reason: reason || null } })),
    onSuccess: () => {
      toast(t.users.statusSaved);
      setStatusOpen(false);
      setReason("");
      refresh();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const saveRoles = useMutation({
    mutationFn: () => unwrap(api.PUT("/api/v1/admin/users/{id}/roles", { params: { path: { id } }, body: { roles: selectedRoles } })),
    onSuccess: () => {
      toast(t.users.rolesSaved);
      setRolesOpen(false);
      refresh();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  if (user.error) return <Card><ErrorState message={errorMessage(t, user.error)} retryLabel={t.common.retry} onRetry={() => user.refetch()} /></Card>;
  const u = user.data;
  const isSelf = me?.id === id;
  const st = stats.data;

  return (
    <>
      <Link to="/users" className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-fg">
        <ArrowLeft className="size-4" aria-hidden /> {t.users.title}
      </Link>
      <PageHeader
        title={u?.email ?? t.users.detail}
        actions={
          u && (
            <>
              {can("roles.manage") && (
                <Button variant="secondary" onClick={() => { setSelectedRoles(u.roles); setRolesOpen(true); }}>
                  {t.users.editRoles}
                </Button>
              )}
              {can("users.manage") && !isSelf && (
                <Button variant={u.isActive ? "danger" : "primary"} onClick={() => setStatusOpen(true)}>
                  {u.isActive ? t.users.deactivate : t.users.activate}
                </Button>
              )}
            </>
          )
        }
      />
      <div className="grid gap-6 lg:grid-cols-[1fr_1.4fr]">
        <Card className="p-5">
          {!u ? (
            <Skeleton className="h-48" />
          ) : (
            <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-3 text-sm">
              <dt className="text-muted">{t.users.name}</dt><dd>{u.displayName ?? "—"}</dd>
              <dt className="text-muted">{t.users.status}</dt><dd><Badge tone={u.isActive ? "success" : "danger"}>{u.isActive ? t.users.active : t.users.disabled}</Badge></dd>
              <dt className="text-muted">{t.users.roles}</dt><dd className="flex flex-wrap gap-1">{u.roles.map((r) => <Badge key={r} tone="primary">{r}</Badge>)}</dd>
              <dt className="text-muted">{t.users.created}</dt><dd>{formatDate(u.createdAt, lang)}</dd>
              <dt className="text-muted">{t.users.lastSeen}</dt><dd>{u.lastSeenAt ? formatDate(u.lastSeenAt, lang) : t.users.never}</dd>
              <dt className="text-muted">{t.users.language}</dt><dd className="uppercase">{u.language}</dd>
              <dt className="text-muted">{t.users.cloudSync}</dt><dd>{u.historyCloudSync ? t.common.yes : t.common.no}</dd>
              <dt className="text-muted">ID</dt><dd className="break-all font-mono text-xs">{u.id}</dd>
            </dl>
          )}
        </Card>
        <Card className="p-5">
          <h2 className="mb-4 font-semibold">{t.users.stats}</h2>
          {!st ? (
            <Skeleton className="h-48" />
          ) : (
            <>
              <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                {[
                  [t.users.simulationsTotal, st.simulationsTotal],
                  [t.users.simulations30d, st.simulations30d],
                  [t.users.favorites, st.favorites],
                  [t.users.categories, st.categories],
                  [t.users.routes, st.routes],
                  [t.users.cloudHistory, st.cloudHistoryItems],
                ].map(([label, value]) => (
                  <div key={label as string}>
                    <p className="text-xs text-muted">{label}</p>
                    <p className="text-xl font-semibold tabular-nums">{formatNumber(value as number, lang)}</p>
                  </div>
                ))}
              </div>
              <p className="mt-4 text-sm text-muted">{t.users.lastActivity}: {formatDate(st.lastActivityAt, lang)}</p>
              {st.eventsByType.length > 0 && (
                <div className="mt-4 border-t border-line pt-4">
                  <p className="mb-2 text-sm font-medium">{t.users.events}</p>
                  <ul className="space-y-1 text-sm">
                    {st.eventsByType.map((e) => (
                      <li key={e.eventType} className="flex justify-between">
                        <span className="text-muted">{t.dashboard.events[e.eventType] ?? e.eventType}</span>
                        <span className="tabular-nums">{formatNumber(e.count, lang)}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </>
          )}
        </Card>
      </div>

      <ConfirmDialog
        open={statusOpen}
        title={u?.isActive ? t.users.deactivate : t.users.activate}
        body={u?.isActive ? t.users.deactivateConfirm : undefined}
        confirmLabel={u?.isActive ? t.users.deactivate : t.users.activate}
        danger={u?.isActive}
        loading={setStatus.isPending}
        onClose={() => setStatusOpen(false)}
        onConfirm={() => setStatus.mutate(!u!.isActive)}
      >
        <label htmlFor="reason" className="mt-4 block text-sm font-medium">{t.users.reason}</label>
        <Textarea id="reason" className="mt-1.5 min-h-20" maxLength={500} value={reason} onChange={(e) => setReason(e.target.value)} />
      </ConfirmDialog>

      <Modal
        open={rolesOpen}
        title={t.users.editRoles}
        onClose={() => setRolesOpen(false)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setRolesOpen(false)}>{t.common.cancel}</Button>
            <Button loading={saveRoles.isPending} onClick={() => saveRoles.mutate()}>{t.common.save}</Button>
          </>
        }
      >
        <fieldset className="space-y-2">
          <legend className="sr-only">{t.users.roles}</legend>
          {roles.data?.map((r) => (
            <label key={r.id} className="flex items-start gap-3 rounded-md border border-line p-3">
              <input
                type="checkbox"
                className="mt-1 size-4 accent-[var(--mg-primary)]"
                checked={selectedRoles.includes(r.name) || r.name === "user"}
                disabled={r.name === "user"}
                onChange={(e) => setSelectedRoles((all) => (e.target.checked ? [...all, r.name] : all.filter((x) => x !== r.name)))}
              />
              <span>
                <span className="font-medium">{r.name}</span>
                {r.description && <span className="block text-sm text-muted">{r.description}</span>}
              </span>
            </label>
          ))}
        </fieldset>
      </Modal>
    </>
  );
}
