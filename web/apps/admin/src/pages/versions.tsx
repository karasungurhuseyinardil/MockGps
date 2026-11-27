import { Badge, Button, Field, Input, Select, Textarea } from "@mockgps/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Upload } from "lucide-react";
import { useRef, useState } from "react";
import { ConfirmDialog, DataTable, Modal, PageHeader, Toggle, errorMessage, useToast, type Column } from "../components/ui";
import { ApiError, api, unwrap, type AppVersion, type AppVersionRequest } from "../lib/api";
import { supabase } from "../lib/supabase";
import { format, formatDate, useI18n } from "../lib/i18n";

const empty: AppVersionRequest = { platform: "android", version: "", buildNumber: 1, minSupportedBuild: 1, downloadUrl: null, releaseNotes: null, isPublished: false };

export function VersionsPage() {
  const { t, lang } = useI18n();
  const toast = useToast();
  const qc = useQueryClient();
  const [editing, setEditing] = useState<{ id?: string; body: AppVersionRequest } | null>(null);
  const [deleting, setDeleting] = useState<AppVersion | null>(null);
  const [uploadingId, setUploadingId] = useState<string | null>(null);
  const fileInput = useRef<HTMLInputElement>(null);
  const uploadTarget = useRef<string | null>(null);

  const versions = useQuery({ queryKey: ["versions"], queryFn: () => unwrap(api.GET("/api/v1/admin/app-versions")) });
  const invalidate = () => qc.invalidateQueries({ queryKey: ["versions"] });

  const save = useMutation({
    mutationFn: ({ id, body }: { id?: string; body: AppVersionRequest }) =>
      id ? unwrap(api.PUT("/api/v1/admin/app-versions/{id}", { params: { path: { id } }, body })) : unwrap(api.POST("/api/v1/admin/app-versions", { body })),
    onSuccess: () => {
      toast(t.common.saved);
      setEditing(null);
      void invalidate();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const remove = useMutation({
    mutationFn: (id: string) => unwrap(api.DELETE("/api/v1/admin/app-versions/{id}", { params: { path: { id } } })),
    onSuccess: () => {
      toast(t.common.deleted);
      setDeleting(null);
      void invalidate();
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  /** Multipart upload (not covered by the typed JSON client). */
  async function upload(id: string, file: File) {
    setUploadingId(id);
    try {
      const form = new FormData();
      form.append("file", file);
      const token = (await supabase.auth.getSession()).data.session?.access_token;
      const base = ((import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://localhost:5080").replace(/\/$/, "");
      const res = await fetch(`${base}/api/v1/admin/app-versions/${id}/artifact`, { method: "POST", body: form, headers: token ? { Authorization: `Bearer ${token}` } : {} });
      if (!res.ok) throw new ApiError({ status: res.status, ...(await res.json().catch(() => ({}))) });
      toast(t.common.saved);
      void invalidate();
    } catch (e) {
      toast(errorMessage(t, e instanceof ApiError ? e : ApiError.network()), "error");
    } finally {
      setUploadingId(null);
    }
  }

  const columns: Column<AppVersion>[] = [
    { key: "platform", header: t.versions.platform, cell: (v) => <span className="capitalize">{v.platform}</span> },
    { key: "version", header: t.versions.version, cell: (v) => <span className="font-mono">{v.version}</span> },
    { key: "build", header: t.versions.build, cell: (v) => <span className="font-mono">{v.buildNumber} <span className="text-muted">(≥{v.minSupportedBuild})</span></span> },
    { key: "status", header: "", cell: (v) => <Badge tone={v.isPublished ? "success" : "neutral"}>{v.isPublished ? t.versions.published : t.versions.draft}</Badge> },
    { key: "file", header: t.versions.size, cell: (v) => (v.downloadUrl ? <a className="text-primary hover:underline" href={v.downloadUrl}>{v.fileSizeBytes ? `${(v.fileSizeBytes / 1048576).toFixed(1)} MB` : "↗"}</a> : "—") },
    { key: "date", header: "", cell: (v) => <span className="text-muted">{formatDate(v.publishedAt ?? v.createdAt, lang, false)}</span> },
    {
      key: "actions",
      header: t.common.actions,
      className: "text-right",
      cell: (v) => (
        <div className="flex justify-end gap-1">
          {v.platform === "android" && (
            <Button
              size="sm"
              variant="ghost"
              loading={uploadingId === v.id}
              onClick={() => {
                uploadTarget.current = v.id;
                fileInput.current?.click();
              }}
            >
              <Upload className="size-4" aria-hidden /> <span className="sr-only sm:not-sr-only">{t.versions.upload}</span>
            </Button>
          )}
          <Button size="sm" variant="ghost" onClick={() => setEditing({ id: v.id, body: { platform: v.platform, version: v.version, buildNumber: v.buildNumber, minSupportedBuild: v.minSupportedBuild, downloadUrl: v.downloadUrl ?? null, releaseNotes: v.releaseNotes ?? null, isPublished: v.isPublished } })}>
            {t.common.edit}
          </Button>
          <Button size="sm" variant="ghost" className="text-danger" onClick={() => setDeleting(v)}>
            {t.common.delete}
          </Button>
        </div>
      ),
    },
  ];

  const b = editing?.body;
  const set = (patch: Partial<AppVersionRequest>) => editing && setEditing({ ...editing, body: { ...editing.body, ...patch } });

  return (
    <>
      <PageHeader title={t.versions.title} actions={<Button onClick={() => setEditing({ body: { ...empty } })}><Plus className="size-4" aria-hidden /> {t.versions.new}</Button>} />
      <input
        ref={fileInput}
        type="file"
        accept=".apk,application/vnd.android.package-archive"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file && uploadTarget.current) void upload(uploadTarget.current, file);
          e.target.value = "";
        }}
      />
      <DataTable columns={columns} rows={versions.data} rowKey={(v) => v.id} loading={versions.isLoading} error={versions.error} onRetry={() => versions.refetch()} />

      <Modal
        open={!!editing}
        title={editing?.id ? `${t.common.edit} ${b?.version}` : t.versions.new}
        onClose={() => setEditing(null)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setEditing(null)}>{t.common.cancel}</Button>
            <Button loading={save.isPending} onClick={() => editing && save.mutate(editing)}>{t.common.save}</Button>
          </>
        }
      >
        {b && (
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={t.versions.platform} htmlFor="v-platform">
              <Select id="v-platform" value={b.platform} onChange={(e) => set({ platform: e.target.value })}>
                <option value="android">Android</option>
                <option value="ios">iOS</option>
              </Select>
            </Field>
            <Field label={t.versions.version} htmlFor="v-version" hint="1.2.3">
              <Input id="v-version" value={b.version} onChange={(e) => set({ version: e.target.value })} placeholder="1.0.0" />
            </Field>
            <Field label={t.versions.build} htmlFor="v-build">
              <Input id="v-build" type="number" min={1} value={b.buildNumber} onChange={(e) => set({ buildNumber: Number(e.target.value) })} />
            </Field>
            <Field label={t.versions.minBuild} htmlFor="v-min" hint={t.versions.minBuildHint}>
              <Input id="v-min" type="number" min={1} value={b.minSupportedBuild} onChange={(e) => set({ minSupportedBuild: Number(e.target.value) })} />
            </Field>
            <div className="sm:col-span-2">
              <Field label={t.versions.url} htmlFor="v-url">
                <Input id="v-url" type="url" value={b.downloadUrl ?? ""} onChange={(e) => set({ downloadUrl: e.target.value || null })} placeholder="https://…" />
              </Field>
            </div>
            <div className="sm:col-span-2">
              <Field label={t.versions.notes} htmlFor="v-notes">
                <Textarea id="v-notes" maxLength={4000} value={b.releaseNotes ?? ""} onChange={(e) => set({ releaseNotes: e.target.value || null })} />
              </Field>
            </div>
            <label className="flex items-center gap-3 text-sm sm:col-span-2">
              <Toggle label={t.versions.publish} checked={b.isPublished} onChange={(v) => set({ isPublished: v })} />
              {t.versions.publish}
            </label>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title={t.common.confirm}
        body={deleting ? format(t.versions.deleteConfirm, { version: deleting.version, build: deleting.buildNumber }) : undefined}
        confirmLabel={t.common.delete}
        danger
        loading={remove.isPending}
        onClose={() => setDeleting(null)}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </>
  );
}
