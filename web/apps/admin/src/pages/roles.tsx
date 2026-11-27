import { Badge, Button, Card, ErrorState, Field, Input, Skeleton } from "@mockgps/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Lock, Plus } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog, Modal, PageHeader, errorMessage, useToast } from "../components/ui";
import { api, unwrap, type Role } from "../lib/api";
import { format, useI18n } from "../lib/i18n";

type Draft = { id?: string; name: string; description: string; permissions: string[]; isSystem: boolean };

export function RolesPage() {
  const { t } = useI18n();
  const toast = useToast();
  const qc = useQueryClient();
  const [draft, setDraft] = useState<Draft | null>(null);
  const [deleting, setDeleting] = useState<Role | null>(null);

  const roles = useQuery({ queryKey: ["roles"], queryFn: () => unwrap(api.GET("/api/v1/admin/roles")) });
  const permissions = useQuery({ queryKey: ["permissions"], queryFn: () => unwrap(api.GET("/api/v1/admin/permissions")) });

  const save = useMutation({
    mutationFn: (d: Draft) => {
      const body = { name: d.name.trim(), description: d.description.trim() || null, permissions: d.permissions };
      return d.id ? unwrap(api.PUT("/api/v1/admin/roles/{id}", { params: { path: { id: d.id } }, body })) : unwrap(api.POST("/api/v1/admin/roles", { body }));
    },
    onSuccess: () => {
      toast(t.common.saved);
      setDraft(null);
      void qc.invalidateQueries({ queryKey: ["roles"] });
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const remove = useMutation({
    mutationFn: (id: string) => unwrap(api.DELETE("/api/v1/admin/roles/{id}", { params: { path: { id } } })),
    onSuccess: () => {
      toast(t.common.deleted);
      setDeleting(null);
      void qc.invalidateQueries({ queryKey: ["roles"] });
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  return (
    <>
      <PageHeader
        title={t.roles.title}
        actions={
          <Button onClick={() => setDraft({ name: "", description: "", permissions: [], isSystem: false })}>
            <Plus className="size-4" aria-hidden /> {t.roles.new}
          </Button>
        }
      />
      {roles.error ? (
        <Card><ErrorState message={errorMessage(t, roles.error)} retryLabel={t.common.retry} onRetry={() => roles.refetch()} /></Card>
      ) : roles.isLoading ? (
        <Skeleton className="h-64 rounded-lg" />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {roles.data!.map((r) => (
            <Card key={r.id} className="p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="flex items-center gap-2 font-semibold">
                    {r.name}
                    {r.isSystem && <Badge tone="neutral"><Lock className="size-3" aria-hidden /> {t.roles.system}</Badge>}
                  </h2>
                  {r.description && <p className="mt-1 text-sm text-muted">{r.description}</p>}
                </div>
                <Badge tone="primary">{r.userCount} {t.roles.members}</Badge>
              </div>
              <div className="mt-4 flex flex-wrap gap-1.5">
                {r.permissions.length === 0 ? <span className="text-sm text-muted">—</span> : r.permissions.map((p) => <Badge key={p}>{t.roles.perms[p] ?? p}</Badge>)}
              </div>
              <div className="mt-4 flex gap-2">
                {r.name !== "superadmin" && r.name !== "user" && (
                  <Button variant="secondary" size="sm" onClick={() => setDraft({ id: r.id, name: r.name, description: r.description ?? "", permissions: r.permissions, isSystem: r.isSystem })}>
                    {t.common.edit}
                  </Button>
                )}
                {!r.isSystem && (
                  <Button variant="ghost" size="sm" className="text-danger" onClick={() => setDeleting(r)}>
                    {t.common.delete}
                  </Button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      <Modal
        open={!!draft}
        title={draft?.id ? `${t.common.edit}: ${draft.name}` : t.roles.new}
        onClose={() => setDraft(null)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setDraft(null)}>{t.common.cancel}</Button>
            <Button loading={save.isPending} disabled={!draft?.name.trim()} onClick={() => draft && save.mutate(draft)}>{t.common.save}</Button>
          </>
        }
      >
        {draft && (
          <div className="space-y-4">
            <Field label={t.roles.name} htmlFor="role-name" hint="a-z, 0-9, _">
              <Input id="role-name" value={draft.name} disabled={draft.isSystem} maxLength={32} pattern="[a-z][a-z0-9_]{1,31}" onChange={(e) => setDraft({ ...draft, name: e.target.value.toLowerCase() })} />
            </Field>
            <Field label={t.roles.description} htmlFor="role-desc">
              <Input id="role-desc" value={draft.description} maxLength={200} onChange={(e) => setDraft({ ...draft, description: e.target.value })} />
            </Field>
            <fieldset>
              <legend className="mb-2 text-sm font-medium">{t.roles.permissions}</legend>
              <div className="grid gap-2 sm:grid-cols-2">
                {(permissions.data ?? []).map((p) => (
                  <label key={p} className="flex items-center gap-2 rounded-md border border-line px-3 py-2 text-sm">
                    <input
                      type="checkbox"
                      className="size-4 accent-[var(--mg-primary)]"
                      checked={draft.permissions.includes(p)}
                      onChange={(e) => setDraft({ ...draft, permissions: e.target.checked ? [...draft.permissions, p] : draft.permissions.filter((x) => x !== p) })}
                    />
                    {t.roles.perms[p] ?? p}
                  </label>
                ))}
              </div>
            </fieldset>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title={t.common.confirm}
        body={deleting ? format(t.roles.deleteConfirm, { name: deleting.name }) : undefined}
        confirmLabel={t.common.delete}
        danger
        loading={remove.isPending}
        onClose={() => setDeleting(null)}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </>
  );
}
