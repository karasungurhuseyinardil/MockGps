import { Badge, Button, Card, Input, Select } from "@mockgps/ui";
import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { DataTable, PageHeader, Pagination, errorMessage, useToast, type Column } from "../components/ui";
import { api, unwrap, type AuditLog, type ContactMessage } from "../lib/api";
import { formatDate, useI18n } from "../lib/i18n";

export function AuditPage() {
  const { t, lang } = useI18n();
  const [page, setPage] = useState(1);
  const [action, setAction] = useState("");
  const [entity, setEntity] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  useEffect(() => setPage(1), [action, entity, from, to]);

  const logs = useQuery({
    queryKey: ["audit", page, action, entity, from, to],
    placeholderData: keepPreviousData,
    queryFn: () =>
      unwrap(
        api.GET("/api/v1/admin/audit-logs", {
          params: {
            query: {
              Page: page,
              PageSize: 25,
              Action: action || undefined,
              Entity: entity || undefined,
              From: from ? new Date(from).toISOString() : undefined,
              To: to ? new Date(`${to}T23:59:59`).toISOString() : undefined,
            },
          },
        }),
      ),
  });

  const columns: Column<AuditLog>[] = [
    { key: "time", header: t.audit.time, cell: (l) => <span className="whitespace-nowrap text-muted">{formatDate(l.createdAt, lang)}</span> },
    { key: "actor", header: t.audit.actor, cell: (l) => l.userEmail ?? (l.userId ? t.audit.deletedUser : t.audit.system) },
    { key: "action", header: t.audit.action, cell: (l) => <Badge tone="primary" className="font-mono">{l.action}</Badge> },
    { key: "entity", header: t.audit.entity, cell: (l) => <span className="font-mono text-xs">{l.entity}{l.entityId ? ` · ${l.entityId.slice(0, 8)}` : ""}</span> },
    {
      key: "desc",
      header: t.audit.description,
      cell: (l) => (
        <div className="max-w-md">
          <p>{l.description}</p>
          {l.metadata != null && (
            <details className="mt-1">
              <summary className="cursor-pointer text-xs text-muted">JSON</summary>
              <pre className="mt-1 overflow-x-auto rounded bg-bg p-2 text-xs">{JSON.stringify(l.metadata, null, 2)}</pre>
            </details>
          )}
          {l.ipAddress && <p className="text-xs text-muted">IP {l.ipAddress}</p>}
        </div>
      ),
    },
  ];

  return (
    <>
      <PageHeader title={t.audit.title} />
      <div className="mb-4 grid gap-3 sm:grid-cols-4">
        <Input aria-label={t.audit.action} placeholder={`${t.audit.action} (user.deactivated…)`} value={action} onChange={(e) => setAction(e.target.value)} />
        <Select aria-label={t.audit.entity} value={entity} onChange={(e) => setEntity(e.target.value)}>
          <option value="">{t.audit.entity}: {t.common.all}</option>
          {["user", "role", "system_setting", "app_version", "announcement", "contact_message"].map((e) => <option key={e} value={e}>{e}</option>)}
        </Select>
        <Input aria-label={t.audit.from} type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        <Input aria-label={t.audit.to} type="date" value={to} onChange={(e) => setTo(e.target.value)} />
      </div>
      <DataTable columns={columns} rows={logs.data?.items} rowKey={(l) => l.id} loading={logs.isLoading} error={logs.error} onRetry={() => logs.refetch()} emptyText={action || entity || from || to ? t.common.noMatch : undefined} />
      {logs.data && logs.data.totalCount > 0 && <Pagination page={page} pageSize={25} total={logs.data.totalCount} onPage={setPage} />}
    </>
  );
}

export function MessagesPage() {
  const { t, lang } = useI18n();
  const toast = useToast();
  const qc = useQueryClient();
  const [status, setStatus] = useState("new");
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState<ContactMessage | null>(null);
  useEffect(() => setPage(1), [status]);

  const list = useQuery({
    queryKey: ["messages", status, page],
    placeholderData: keepPreviousData,
    queryFn: () => unwrap(api.GET("/api/v1/admin/contact-messages", { params: { query: { Page: page, PageSize: 20, Status: status || undefined } } })),
  });

  const update = useMutation({
    mutationFn: ({ id, status: s }: { id: string; status: string }) => unwrap(api.PATCH("/api/v1/admin/contact-messages/{id}", { params: { path: { id } }, body: { status: s } })),
    onSuccess: (m) => {
      setOpen(m);
      void qc.invalidateQueries({ queryKey: ["messages"] });
      void qc.invalidateQueries({ queryKey: ["dashboard", "summary"] });
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const columns: Column<ContactMessage>[] = [
    { key: "from", header: t.messages.from, cell: (m) => <div><p className="font-medium">{m.name}</p><p className="text-xs text-muted">{m.email}</p></div> },
    { key: "subject", header: t.messages.subject, cell: (m) => <span className={m.status === "new" ? "font-semibold" : undefined}>{m.subject}</span> },
    { key: "date", header: t.messages.received, cell: (m) => <span className="text-muted">{formatDate(m.createdAt, lang)}</span> },
    { key: "status", header: t.messages.status, cell: (m) => <Badge tone={m.status === "new" ? "warning" : "neutral"}>{t.messages.statuses[m.status] ?? m.status}</Badge> },
  ];

  return (
    <>
      <PageHeader title={t.messages.title} />
      <div className="mb-4 max-w-xs">
        <Select aria-label={t.messages.status} value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">{t.common.all}</option>
          {Object.entries(t.messages.statuses).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </Select>
      </div>
      <div className="grid gap-6 xl:grid-cols-[1.2fr_1fr]">
        <div>
          <DataTable
            columns={columns}
            rows={list.data?.items}
            rowKey={(m) => m.id}
            loading={list.isLoading}
            error={list.error}
            onRetry={() => list.refetch()}
            onRowClick={(m) => {
              setOpen(m);
              if (m.status === "new") update.mutate({ id: m.id, status: "read" });
            }}
          />
          {list.data && list.data.totalCount > 0 && <Pagination page={page} pageSize={20} total={list.data.totalCount} onPage={setPage} />}
        </div>
        {open && (
          <Card className="h-fit p-5">
            <p className="text-sm text-muted">{open.name} · {open.email}</p>
            <h2 className="mt-1 text-lg font-semibold">{open.subject}</h2>
            <p className="mt-1 text-xs text-muted">{formatDate(open.createdAt, lang)}</p>
            <p className="mt-4 whitespace-pre-wrap text-sm leading-relaxed">{open.message}</p>
            <div className="mt-5 flex flex-wrap gap-2">
              <a className="inline-flex h-9 items-center rounded-md bg-primary px-3 text-sm font-medium text-primary-fg" href={`mailto:${open.email}?subject=${encodeURIComponent(`Re: ${open.subject}`)}`}>
                {t.messages.reply}
              </a>
              {open.status !== "archived" && (
                <Button size="sm" variant="secondary" loading={update.isPending} onClick={() => update.mutate({ id: open.id, status: "archived" })}>
                  {t.messages.archive}
                </Button>
              )}
            </div>
          </Card>
        )}
      </div>
    </>
  );
}
