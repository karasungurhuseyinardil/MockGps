import { Badge, Card, buttonClass, cn } from "@mockgps/ui";
import {
  Activity,
  Apple,
  BadgeCheck,
  Bookmark,
  ChevronDown,
  Crosshair,
  FileDown,
  Gauge,
  History,
  Info,
  Languages,
  MapPinned,
  Route as RouteIcon,
  ShieldCheck,
  Smartphone,
  Zap,
} from "lucide-react";
import type { ReactNode } from "react";
import { Link } from "react-router";
import { useI18n } from "../i18n";

export function Section({ id, eyebrow, title, intro, children, className }: { id?: string; eyebrow?: string; title: string; intro?: string; children: ReactNode; className?: string }) {
  return (
    <section id={id} className={cn("mx-auto max-w-6xl scroll-mt-24 px-4 py-20 sm:px-6", className)}>
      <div className="mx-auto mb-12 max-w-2xl text-center">
        {eyebrow && <p className="mb-3 text-sm font-semibold uppercase tracking-wider text-primary">{eyebrow}</p>}
        <h2 className="text-3xl font-bold tracking-tight text-balance sm:text-4xl">{title}</h2>
        {intro && <p className="mt-4 text-lg text-muted text-pretty">{intro}</p>}
      </div>
      {children}
    </section>
  );
}

/** Real device screenshot inside a phone frame. */
export function PhoneFrame({ src, alt, className }: { src: string; alt: string; className?: string }) {
  return (
    <div className={cn("relative w-[260px] rounded-[44px] border-[10px] border-[#0b1220] bg-[#0b1220] shadow-[0_40px_80px_-24px_rgba(11,18,32,0.45)] sm:w-[300px]", className)}>
      <img
        src={src}
        alt={alt}
        width={1080}
        height={2280}
        className="aspect-[9/19] w-full rounded-[34px] bg-elevated object-cover object-top"
        loading="eager"
        decoding="async"
        // Screenshots are real device captures; hide the frame content rather than show a broken image.
        onError={(e) => (e.currentTarget.style.visibility = "hidden")}
      />
    </div>
  );
}

export function Hero() {
  const { t, path } = useI18n();
  return (
    <section className="relative overflow-hidden">
      <div className="map-grid pointer-events-none absolute inset-0" aria-hidden />
      <div className="pointer-events-none absolute -top-40 left-1/2 h-[520px] w-[820px] -translate-x-1/2 rounded-full bg-primary/20 blur-3xl" aria-hidden />
      <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 pb-16 pt-16 sm:px-6 lg:grid-cols-[1.1fr_1fr] lg:pt-24">
        <div>
          <Badge tone="primary" className="mb-6">{t.hero.eyebrow}</Badge>
          <h1 className="text-4xl font-extrabold tracking-tight text-balance sm:text-5xl lg:text-6xl">{t.hero.title}</h1>
          <p className="mt-6 max-w-xl text-lg text-muted text-pretty">{t.hero.body}</p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <a href="#download" className={buttonClass("primary", "lg")}>
              <Smartphone className="size-5" aria-hidden />
              {t.hero.primary}
            </a>
            <Link to={path("/how-it-works")} className={buttonClass("secondary", "lg")}>
              {t.hero.secondary}
            </Link>
          </div>
          <div className="mt-8 inline-flex items-center gap-3 rounded-full border border-line bg-elevated/70 px-4 py-2 font-mono text-sm backdrop-blur">
            <span className="relative flex size-3">
              <span className="absolute inline-flex size-full animate-pulse-ring rounded-full bg-simulated" />
              <span className="relative inline-flex size-3 rounded-full bg-simulated" />
            </span>
            <span className="font-sans font-medium">{t.hero.simulating}</span>
            <span className="text-muted">41.02564, 28.97421</span>
          </div>
        </div>
        <div className="flex justify-center lg:justify-end">
          <PhoneFrame src="/screens/map.png" alt={t.hero.title} className="rotate-[2deg]" />
        </div>
      </div>
    </section>
  );
}

export function Highlights() {
  const { t } = useI18n();
  const icons = [ShieldCheck, Gauge, BadgeCheck];
  return (
    <div className="mx-auto grid max-w-6xl gap-4 px-4 sm:grid-cols-3 sm:px-6">
      {t.highlights.map((h, i) => {
        const Icon = icons[i]!;
        return (
          <Card key={h.title} className="p-6">
            <Icon className="mb-4 size-6 text-primary" aria-hidden />
            <h3 className="font-semibold">{h.title}</h3>
            <p className="mt-2 text-sm text-muted">{h.body}</p>
          </Card>
        );
      })}
    </div>
  );
}

const FEATURE_ICONS = [MapPinned, Zap, RouteIcon, Bookmark, History, Crosshair, Activity, FileDown, Languages];

export function FeatureGrid({ limit }: { limit?: number }) {
  const { t } = useI18n();
  const items = limit ? t.features.items.slice(0, limit) : t.features.items;
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {items.map((f, i) => {
        const Icon = FEATURE_ICONS[i]!;
        return (
          <Card key={f.title} className="group p-6 transition-shadow hover:shadow-[0_12px_40px_-16px_rgba(52,87,245,0.35)]">
            <div className="mb-4 inline-flex size-11 items-center justify-center rounded-md bg-primary/10 text-primary transition-colors group-hover:bg-primary group-hover:text-primary-fg">
              <Icon className="size-5" aria-hidden />
            </div>
            <h3 className="font-semibold">{f.title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted">{f.body}</p>
          </Card>
        );
      })}
    </div>
  );
}

export function Steps() {
  const { t } = useI18n();
  return (
    <>
      <ol className="grid gap-6 md:grid-cols-3">
        {t.how.steps.map((s, i) => (
          <li key={s.title} className="relative">
            <Card className="h-full p-6">
              <span className="mb-4 inline-flex size-9 items-center justify-center rounded-full bg-primary font-semibold text-primary-fg">{i + 1}</span>
              <h3 className="font-semibold">{s.title}</h3>
              <p className="mt-2 text-sm text-muted">{s.body}</p>
            </Card>
          </li>
        ))}
      </ol>
      <div className="mt-8 flex gap-3 rounded-lg border border-warning/30 bg-warning/8 p-5 text-sm" role="note">
        <Info className="mt-0.5 size-5 shrink-0 text-warning" aria-hidden />
        <div>
          <p className="font-semibold">{t.how.noteTitle}</p>
          <p className="mt-1 text-muted">{t.how.note}</p>
        </div>
      </div>
    </>
  );
}

export function PlatformLimits() {
  const { t } = useI18n();
  return (
    <div className="grid gap-4 md:grid-cols-2">
      <Card className="p-6">
        <div className="mb-3 flex items-center gap-2">
          <Smartphone className="size-5 text-success" aria-hidden />
          <h3 className="font-semibold">{t.limits.android.title}</h3>
          <Badge tone="success">✓</Badge>
        </div>
        <p className="text-sm text-muted">{t.limits.android.body}</p>
      </Card>
      <Card className="p-6">
        <div className="mb-3 flex items-center gap-2">
          <Apple className="size-5 text-muted" aria-hidden />
          <h3 className="font-semibold">{t.limits.ios.title}</h3>
          <Badge tone="neutral">GPX</Badge>
        </div>
        <p className="text-sm text-muted">{t.limits.ios.body}</p>
      </Card>
    </div>
  );
}

export function FaqList({ limit }: { limit?: number }) {
  const { t } = useI18n();
  const items = limit ? t.faq.items.slice(0, limit) : t.faq.items;
  return (
    <div className="mx-auto max-w-3xl divide-y divide-line rounded-lg border border-line bg-elevated">
      {items.map((item) => (
        <details key={item.q} className="group px-6 py-5">
          <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium [&::-webkit-details-marker]:hidden">
            {item.q}
            <ChevronDown className="size-5 shrink-0 text-muted transition-transform group-open:rotate-180" aria-hidden />
          </summary>
          <p className="mt-3 text-sm leading-relaxed text-muted">{item.a}</p>
        </details>
      ))}
    </div>
  );
}
