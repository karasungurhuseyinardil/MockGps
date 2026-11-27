import { Badge, Card, ErrorState, Skeleton, cn } from "@mockgps/ui";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { Area, AreaChart, Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { PageHeader, StatCard, errorMessage } from "../components/ui";
import { api, unwrap } from "../lib/api";
import { formatNumber, useI18n } from "../lib/i18n";

type Metric = "new_users" | "active_users" | "simulations";
type Granularity = "day" | "month";

export function DashboardPage() {
  const { t, lang } = useI18n();
  const [metric, setMetric] = useState<Metric>("simulations");
  const [granularity, setGranularity] = useState<Granularity>("day");

  const summary = useQuery({ queryKey: ["dashboard", "summary"], queryFn: () => unwrap(api.GET("/api/v1/admin/dashboard/summary")), refetchInterval: 60_000 });
  const series = useQuery({
    queryKey: ["dashboard", "series", metric, granularity],
    queryFn: () => unwrap(api.GET("/api/v1/admin/dashboard/timeseries", { params: { query: { Metric: metric, Granularity: granularity } } })),
  });
  const features = useQuery({ queryKey: ["dashboard", "features"], queryFn: () => unwrap(api.GET("/api/v1/admin/dashboard/feature-usage")) });
  const health = useQuery({ queryKey: ["dashboard", "health"], queryFn: () => unwrap(api.GET("/api/v1/admin/dashboard/system-health")), refetchInterval: 30_000 });

  const n = (v: number | undefined) => (v === undefined ? "—" : formatNumber(v, lang));
  const s = summary.data;
  const dateFmt = new Intl.DateTimeFormat(lang === "tr" ? "tr-TR" : "en-GB", granularity === "day" ? { day: "numeric", month: "short" } : { month: "short", year: "2-digit" });
  const chartData = (series.data ?? []).map((p) => ({ label: dateFmt.format(new Date(p.bucket)), value: p.value }));

  return (
    <>
      <PageHeader title={t.dashboard.title} />
      {health.data?.maintenanceMode && (
        <div className="mb-6 rounded-md border border-warning/30 bg-warning/10 px-4 py-3 text-sm font-medium text-warning" role="status">
          {t.dashboard.maintenance}
        </div>
      )}

      {summary.error ? (
        <Card><ErrorState message={errorMessage(t, summary.error)} retryLabel={t.common.retry} onRetry={() => summary.refetch()} /></Card>
      ) : (
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-5">
          {summary.isLoading
            ? Array.from({ length: 10 }, (_, i) => <Skeleton key={i} className="h-[104px] rounded-lg" />)
            : [
                [t.dashboard.totalUsers, n(s?.totalUsers)],
                [t.dashboard.newToday, n(s?.newUsersToday)],
                [t.dashboard.active24h, n(s?.activeUsers24h)],
                [t.dashboard.active30d, n(s?.activeUsers30d)],
                [t.dashboard.inactive, n(s?.inactiveUsers)],
                [t.dashboard.simulations, n(s?.totalSimulations), "simulated"],
                [t.dashboard.simulationsToday, n(s?.simulationsToday), "simulated"],
                [t.dashboard.favorites, n(s?.totalFavorites)],
                [t.dashboard.routes, n(s?.totalRoutes)],
                [t.dashboard.newMessages, n(s?.newContactMessages), (s?.newContactMessages ?? 0) > 0 ? "warning" : undefined],
              ].map(([label, value, tone]) => <StatCard key={label} label={label!} value={value} tone={tone as "simulated" | "warning" | undefined} />)}
        </div>
      )}

      <div className="mt-6 grid gap-6 xl:grid-cols-[2fr_1fr]">
        <Card className="p-5">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h2 className="font-semibold">{t.dashboard.chart}</h2>
            <div className="flex flex-wrap gap-2">
              <Segmented value={metric} onChange={setMetric} options={(["simulations", "active_users", "new_users"] as const).map((m) => [m, t.dashboard.metrics[m]])} />
              <Segmented value={granularity} onChange={setGranularity} options={[["day", t.dashboard.daily], ["month", t.dashboard.monthly]]} />
            </div>
          </div>
          <div className="h-72" role="img" aria-label={`${t.dashboard.metrics[metric]} — ${granularity === "day" ? t.dashboard.daily : t.dashboard.monthly}`}>
            {series.isLoading ? (
              <Skeleton className="size-full" />
            ) : series.error ? (
              <ErrorState message={errorMessage(t, series.error)} retryLabel={t.common.retry} onRetry={() => series.refetch()} />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ left: -16, right: 8, top: 8 }}>
                  <defs>
                    <linearGradient id="fill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="var(--mg-primary)" stopOpacity={0.35} />
                      <stop offset="100%" stopColor="var(--mg-primary)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke="var(--mg-border)" vertical={false} />
                  <XAxis dataKey="label" tick={{ fill: "var(--mg-text-muted)", fontSize: 12 }} tickLine={false} axisLine={false} minTickGap={16} />
                  <YAxis allowDecimals={false} tick={{ fill: "var(--mg-text-muted)", fontSize: 12 }} tickLine={false} axisLine={false} />
                  <Tooltip contentStyle={{ background: "var(--mg-bg-elevated)", border: "1px solid var(--mg-border)", borderRadius: 10 }} labelStyle={{ color: "var(--mg-text)" }} />
                  <Area type="monotone" dataKey="value" name={t.dashboard.metrics[metric]} stroke="var(--mg-primary)" strokeWidth={2} fill="url(#fill)" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>

        <Card className="p-5">
          <h2 className="mb-4 font-semibold">{t.dashboard.health}</h2>
          {health.isLoading ? (
            <Skeleton className="h-40" />
          ) : health.error ? (
            <ErrorState message={errorMessage(t, health.error)} retryLabel={t.common.retry} onRetry={() => health.refetch()} />
          ) : (
            <div className="space-y-3 text-sm">
              <div className="flex items-center justify-between">
                <span>API {health.data!.apiVersion}</span>
                <Badge tone={health.data!.status === "healthy" ? "success" : "warning"}>{health.data!.status === "healthy" ? t.dashboard.healthy : t.dashboard.degraded}</Badge>
              </div>
              {health.data!.checks.map((c) => (
                <div key={c.name} className="flex items-center justify-between border-t border-line pt-3">
                  <span className="capitalize">{c.name}</span>
                  <span className="flex items-center gap-2 text-muted">
                    {c.latencyMs != null && <span className="font-mono text-xs">{c.latencyMs} ms</span>}
                    {c.detail && <span className="font-mono text-xs">{c.detail}</span>}
                    <span className={cn("size-2 rounded-full", c.status === "unhealthy" ? "bg-danger" : "bg-success")} aria-label={c.status} />
                  </span>
                </div>
              ))}
              <p className="border-t border-line pt-3 text-muted">
                {t.dashboard.uptime}: <span className="font-mono">{health.data!.uptime.split(".")[0]}</span>
              </p>
            </div>
          )}
        </Card>
      </div>

      <Card className="mt-6 p-5">
        <h2 className="mb-4 font-semibold">{t.dashboard.features}</h2>
        <div className="h-64">
          {features.isLoading ? (
            <Skeleton className="size-full" />
          ) : features.error ? (
            <ErrorState message={errorMessage(t, features.error)} retryLabel={t.common.retry} onRetry={() => features.refetch()} />
          ) : (features.data ?? []).length === 0 ? (
            <p className="py-16 text-center text-sm text-muted">{t.common.empty}</p>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={(features.data ?? []).map((f) => ({ name: t.dashboard.events[f.eventType] ?? f.eventType, count: f.count }))} layout="vertical" margin={{ left: 24, right: 16 }}>
                <CartesianGrid stroke="var(--mg-border)" horizontal={false} />
                <XAxis type="number" allowDecimals={false} tick={{ fill: "var(--mg-text-muted)", fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="name" width={150} tick={{ fill: "var(--mg-text)", fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip cursor={{ fill: "var(--mg-border)" }} contentStyle={{ background: "var(--mg-bg-elevated)", border: "1px solid var(--mg-border)", borderRadius: 10 }} />
                <Bar dataKey="count" fill="var(--mg-primary)" radius={[0, 6, 6, 0]} barSize={18} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </Card>
    </>
  );
}

function Segmented<T extends string>({ value, onChange, options }: { value: T; onChange: (v: T) => void; options: [T, string][] }) {
  return (
    <div className="inline-flex rounded-md border border-line p-0.5" role="group">
      {options.map(([v, label]) => (
        <button
          key={v}
          type="button"
          aria-pressed={value === v}
          onClick={() => onChange(v)}
          className={cn("rounded-[8px] px-3 py-1.5 text-xs font-medium transition-colors", value === v ? "bg-primary text-primary-fg" : "text-muted hover:text-fg")}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
