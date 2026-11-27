import { Badge, Button, Field, Input, Select, Textarea } from "@mockgps/ui";
import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog, DataTable, Modal, PageHeader, Pagination, Toggle, errorMessage, useToast, type Column } from "../components/ui";
import { api, unwrap, type Announcement, type AnnouncementRequest } from "../lib/api";
import { formatDate, useI18n } from "../lib/i18n";

const toLocalInput = (iso: string | null | undefined) => (iso ? new Date(iso).toISOString().slice(0, 16) : "");
const fromLocalInput = (v: string) => (v ? new Date(v).toISOString() : null);

export function AnnouncementsPage() {
  const { t, lang } = useI18n();
  const toast = useToast();
  const qc = useQueryClient();
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState<{ id?: string; body: AnnouncementRequest } | null>(null);
  const [deleting, setDeleting] = useState<Announcement | null>(null);

  const list = useQuery({
    queryKey: ["announcements", page],
    placeholderData: keepPreviousData,
    queryFn: () => unwrap(api.GET("/api/v1/admin/announcements", { params: { query: { Page: page, PageSize: 20 } } })),
  });
  const invalidate = () => qc.invalidateQueries({ queryKey: ["announcements"] });

  const save = useMutation({
    mutationFn: ({ id, body }: { id?: string; body: AnnouncementRequest }) =>
      id ? unwrap(api.PUT("/api/v1/admin/announcements/{id}", { params: { path: { id } }, body })) : unwrap(api.POST("/api/v1/admin/announcements", { body })),
    onSuccess: () => {
      toast(t.common.saved);
      setEditing(null);
      void invalidate();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const remove = useMutation({
    mutationFn: (id: string) => unwrap(api.DELETE("/api/v1/admin/announcements/{id}", { params: { path: { id } } })),
    onSuccess: () => {
      toast(t.common.deleted);
      setDeleting(null);
      void invalidate();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const tone = (level: string) => (level === "critical" ? "danger" : level === "warning" ? "warning" : "primary") as "danger" | "warning" | "primary";
  const columns: Column<Announcement>[] = [
    { key: "title", header: t.announcements.titleField, cell: (a) => <div><p className="font-medium">{a.title}</p><p className="line-clamp-1 text-xs text-muted">{a.body}</p></div> },
    { key: "level", header: t.announcements.level, cell: (a) => <Badge tone={tone(a.level)}>{t.announcements.levels[a.level] ?? a.level}</Badge> },
    { key: "audience", header: t.announcements.audience, cell: (a) => t.announcements.audiences[a.audience] ?? a.audience },
    { key: "window", header: t.announcements.starts, cell: (a) => <span className="text-muted">{formatDate(a.startsAt, lang)}{a.endsAt ? ` → ${formatDate(a.endsAt, lang)}` : ""}</span> },
    { key: "active", header: t.announcements.active, cell: (a) => <Badge tone={a.isActive ? "success" : "neutral"}>{a.isActive ? t.common.yes : t.common.no}</Badge> },
    {
      key: "actions",
      header: t.common.actions,
      className: "text-right",
      cell: (a) => (
        <div className="flex justify-end gap-1">
          <Button size="sm" variant="ghost" onClick={() => setEditing({ id: a.id, body: { title: a.title, body: a.body, level: a.level, audience: a.audience, startsAt: a.startsAt, endsAt: a.endsAt ?? null, isActive: a.isActive } })}>{t.common.edit}</Button>
          <Button size="sm" variant="ghost" className="text-danger" onClick={() => setDeleting(a)}>{t.common.delete}</Button>
        </div>
      ),
    },
  ];

  const b = editing?.body;
  const set = (patch: Partial<AnnouncementRequest>) => editing && setEditing({ ...editing, body: { ...editing.body, ...patch } });

  return (
    <>
      <PageHeader
        title={t.announcements.title}
        actions={<Button onClick={() => setEditing({ body: { title: "", body: "", level: "info", audience: "all", startsAt: null, endsAt: null, isActive: true } })}><Plus className="size-4" aria-hidden /> {t.announcements.new}</Button>}
      />
      <DataTable columns={columns} rows={list.data?.items} rowKey={(a) => a.id} loading={list.isLoading} error={list.error} onRetry={() => list.refetch()} />
      {list.data && list.data.totalCount > 0 && <Pagination page={page} pageSize={20} total={list.data.totalCount} onPage={setPage} />}

      <Modal
        open={!!editing}
        title={editing?.id ? t.common.edit : t.announcements.new}
        onClose={() => setEditing(null)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setEditing(null)}>{t.common.cancel}</Button>
            <Button loading={save.isPending} disabled={!b?.title.trim() || !b?.body.trim()} onClick={() => editing && save.mutate(editing)}>{t.common.save}</Button>
          </>
        }
      >
        {b && (
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="sm:col-span-2">
              <Field label={t.announcements.titleField} htmlFor="a-title">
                <Input id="a-title" maxLength={120} value={b.title} onChange={(e) => set({ title: e.target.value })} />
              </Field>
            </div>
            <div className="sm:col-span-2">
              <Field label={t.announcements.body} htmlFor="a-body">
                <Textarea id="a-body" maxLength={2000} value={b.body} onChange={(e) => set({ body: e.target.value })} />
              </Field>
            </div>
            <Field label={t.announcements.level} htmlFor="a-level">
              <Select id="a-level" value={b.level} onChange={(e) => set({ level: e.target.value })}>
                {Object.entries(t.announcements.levels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </Select>
            </Field>
            <Field label={t.announcements.audience} htmlFor="a-aud">
              <Select id="a-aud" value={b.audience} onChange={(e) => set({ audience: e.target.value })}>
                {Object.entries(t.announcements.audiences).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </Select>
            </Field>
            <Field label={t.announcements.starts} htmlFor="a-start">
              <Input id="a-start" type="datetime-local" value={toLocalInput(b.startsAt)} onChange={(e) => set({ startsAt: fromLocalInput(e.target.value) })} />
            </Field>
            <Field label={t.announcements.ends} htmlFor="a-end">
              <Input id="a-end" type="datetime-local" value={toLocalInput(b.endsAt)} onChange={(e) => set({ endsAt: fromLocalInput(e.target.value) })} />
            </Field>
            <label className="flex items-center gap-3 text-sm">
              <Toggle label={t.announcements.active} checked={b.isActive} onChange={(v) => set({ isActive: v })} />
              {t.announcements.active}
            </label>
          </div>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} title={t.common.confirm} body={t.announcements.deleteConfirm} confirmLabel={t.common.delete} danger loading={remove.isPending} onClose={() => setDeleting(null)} onConfirm={() => deleting && remove.mutate(deleting.id)} />
    </>
  );
}
