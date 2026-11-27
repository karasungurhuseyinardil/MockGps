import { Button, Card, ErrorState, Input, Skeleton } from "@mockgps/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { PageHeader, Toggle, errorMessage, useToast } from "../components/ui";
import { api, unwrap, type SystemSetting } from "../lib/api";
import { formatDate, useI18n } from "../lib/i18n";

export function SettingsPage() {
  const { t } = useI18n();
  const settings = useQuery({ queryKey: ["system-settings"], queryFn: () => unwrap(api.GET("/api/v1/admin/system-settings")) });

  return (
    <>
      <PageHeader title={t.settings.title} />
      {settings.error ? (
        <Card><ErrorState message={errorMessage(t, settings.error)} retryLabel={t.common.retry} onRetry={() => settings.refetch()} /></Card>
      ) : settings.isLoading ? (
        <Skeleton className="h-72 rounded-lg" />
      ) : (
        <Card className="divide-y divide-line">
          {settings.data!.map((s) => (
            <SettingRow key={s.key} setting={s} />
          ))}
        </Card>
      )}
    </>
  );
}

function SettingRow({ setting }: { setting: SystemSetting }) {
  const { t, lang } = useI18n();
  const toast = useToast();
  const qc = useQueryClient();
  const isBool = typeof setting.value === "boolean";
  const [text, setText] = useState(String(setting.value ?? ""));

  const save = useMutation({
    mutationFn: (value: unknown) => unwrap(api.PUT("/api/v1/admin/system-settings/{key}", { params: { path: { key: setting.key } }, body: { value } as never })),
    onSuccess: () => {
      toast(t.common.saved);
      void qc.invalidateQueries({ queryKey: ["system-settings"] });
      void qc.invalidateQueries({ queryKey: ["dashboard"] });
    },
    onError: (e) => toast(errorMessage(t, e), "error"),
  });

  const label = t.settings.keys[setting.key] ?? setting.key;
  return (
    <div className="flex flex-wrap items-center justify-between gap-4 p-5">
      <div className="min-w-0 flex-1">
        <p className="font-medium">{label}</p>
        {setting.description && <p className="mt-0.5 text-sm text-muted">{setting.description}</p>}
        <p className="mt-1 text-xs text-muted">{t.settings.updated}: {formatDate(setting.updatedAt, lang)}</p>
      </div>
      {isBool ? (
        <div className="flex items-center gap-3">
          <span className="text-sm text-muted">{setting.value ? t.settings.on : t.settings.off}</span>
          <Toggle label={label} checked={Boolean(setting.value)} disabled={save.isPending} onChange={(v) => save.mutate(v)} />
        </div>
      ) : (
        <form
          className="flex w-full gap-2 sm:w-auto"
          onSubmit={(e) => {
            e.preventDefault();
            save.mutate(typeof setting.value === "number" ? Number(text) : text.trim());
          }}
        >
          <Input
            aria-label={label}
            className="sm:w-64"
            type={typeof setting.value === "number" ? "number" : setting.key.includes("email") ? "email" : "text"}
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
          <Button type="submit" variant="secondary" loading={save.isPending} disabled={text === String(setting.value ?? "")}>
            {t.common.save}
          </Button>
        </form>
      )}
    </div>
  );
}
