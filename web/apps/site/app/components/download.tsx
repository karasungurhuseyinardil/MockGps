import { Button, Card, Skeleton, buttonClass } from "@mockgps/ui";
import { Download, Smartphone } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { format, useI18n } from "../i18n";
import { type Release, fetchLatestRelease } from "../lib/api";

type State = { kind: "loading" } | { kind: "ready"; release: Release | null } | { kind: "error" };

/** Download area backed by the API (`/public/releases/latest`). Rendered client-side so it is always current. */
export function DownloadSection() {
  const { t } = useI18n();
  const [state, setState] = useState<State>({ kind: "loading" });

  const load = useCallback(() => {
    setState({ kind: "loading" });
    fetchLatestRelease("android")
      .then((release) => setState({ kind: "ready", release }))
      .catch(() => setState({ kind: "error" }));
  }, []);

  useEffect(load, [load]);

  return (
    <section id="download" className="mx-auto max-w-6xl scroll-mt-24 px-4 py-20 sm:px-6">
      <Card className="relative overflow-hidden p-8 sm:p-12">
        <div className="pointer-events-none absolute -right-24 -top-24 size-80 rounded-full bg-primary/15 blur-3xl" aria-hidden />
        <div className="relative grid items-center gap-8 md:grid-cols-[1fr_auto]">
          <div>
            <h2 className="text-3xl font-bold tracking-tight">{t.download.title}</h2>
            <p className="mt-3 text-muted">{t.download.body}</p>
            <div className="mt-6 min-h-12" aria-live="polite">
              {state.kind === "loading" && (
                <div className="space-y-2" role="status" aria-label={t.download.loading}>
                  <Skeleton className="h-4 w-56" />
                  <Skeleton className="h-4 w-40" />
                </div>
              )}
              {state.kind === "error" && (
                <div className="flex flex-wrap items-center gap-3 text-sm text-danger">
                  {t.download.error}
                  <Button size="sm" variant="secondary" onClick={load}>↻</Button>
                </div>
              )}
              {state.kind === "ready" && !state.release && <p className="text-sm text-muted">{t.download.unavailable}</p>}
              {state.kind === "ready" && state.release && (
                <div className="text-sm text-muted">
                  <p className="font-mono">
                    {format(t.download.version, { version: state.release.version, build: state.release.buildNumber })}
                    {state.release.fileSizeBytes ? ` · ${format(t.download.size, { size: (state.release.fileSizeBytes / 1048576).toFixed(1) })}` : ""}
                  </p>
                  {state.release.releaseNotes && (
                    <details className="mt-2">
                      <summary className="cursor-pointer text-fg">{t.download.notes}</summary>
                      <p className="mt-2 whitespace-pre-line">{state.release.releaseNotes}</p>
                    </details>
                  )}
                </div>
              )}
            </div>
          </div>
          {state.kind === "ready" && state.release?.downloadUrl ? (
            <a href={state.release.downloadUrl} className={buttonClass("primary", "lg")} rel="noopener">
              <Download className="size-5" aria-hidden />
              {t.download.button}
            </a>
          ) : (
            <span className={buttonClass("secondary", "lg", "pointer-events-none opacity-50")} aria-disabled="true">
              <Smartphone className="size-5" aria-hidden />
              {t.download.button}
            </span>
          )}
        </div>
      </Card>
    </section>
  );
}
