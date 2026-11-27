import { ThemeToggle, cn } from "@mockgps/ui";
import {
  BarChart3,
  FileClock,
  KeyRound,
  Languages,
  LogOut,
  Mail,
  Megaphone,
  Menu,
  PackageCheck,
  Settings2,
  ShieldCheck,
  Users,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";
import { NavLink, Outlet, useLocation } from "react-router";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";

export const NAV = [
  { to: "/", key: "dashboard", icon: BarChart3, permission: "dashboard.read" },
  { to: "/users", key: "users", icon: Users, permission: "users.read" },
  { to: "/admins", key: "admins", icon: ShieldCheck, permission: "users.read" },
  { to: "/roles", key: "roles", icon: KeyRound, permission: "roles.manage" },
  { to: "/settings", key: "settings", icon: Settings2, permission: "settings.manage" },
  { to: "/versions", key: "versions", icon: PackageCheck, permission: "versions.manage" },
  { to: "/announcements", key: "announcements", icon: Megaphone, permission: "announcements.manage" },
  { to: "/audit", key: "audit", icon: FileClock, permission: "audit.read" },
  { to: "/messages", key: "messages", icon: Mail, permission: "messages.manage" },
] as const;

function Logo() {
  return (
    <svg viewBox="0 0 108 108" className="size-8" aria-hidden="true">
      <rect width="108" height="108" rx="26" fill="#3457F5" />
      <path d="M54,77 L39.98,56.6 A17,17 0 1,1 68.02,56.6 Z" fill="#fff" />
      <circle cx="54" cy="47" r="7" fill="#F2542D" />
    </svg>
  );
}

export function AdminLayout() {
  const { t, lang, setLang } = useI18n();
  const { me, can, signOut } = useAuth();
  const [open, setOpen] = useState(false);
  const { pathname } = useLocation();
  useEffect(() => setOpen(false), [pathname]);

  const nav = (
    <nav className="flex flex-1 flex-col gap-1 px-3" aria-label="Admin">
      {NAV.filter((n) => can(n.permission)).map((n) => (
        <NavLink
          key={n.to}
          to={n.to}
          end={n.to === "/"}
          className={({ isActive }) =>
            cn("flex items-center gap-3 rounded-md px-3 py-2.5 text-sm transition-colors", isActive ? "bg-primary/12 font-medium text-primary" : "text-muted hover:bg-line hover:text-fg")
          }
        >
          <n.icon className="size-[18px]" aria-hidden />
          {t.nav[n.key]}
        </NavLink>
      ))}
    </nav>
  );

  const footer = (
    <div className="space-y-1 border-t border-line p-3">
      <p className="truncate px-3 pb-2 text-xs text-muted" title={me?.email}>
        {me?.email}
      </p>
      <div className="flex items-center gap-1 px-1">
        <ThemeToggle labels={t.theme} />
        <button type="button" onClick={() => setLang(lang === "en" ? "tr" : "en")} className="inline-flex h-10 items-center gap-1.5 rounded-full px-3 text-sm text-muted hover:bg-line hover:text-fg">
          <Languages className="size-4" aria-hidden />
          {t.nav.language}
        </button>
      </div>
      <button type="button" onClick={signOut} className="flex w-full items-center gap-3 rounded-md px-3 py-2.5 text-sm text-muted hover:bg-line hover:text-fg">
        <LogOut className="size-[18px]" aria-hidden />
        {t.nav.signOut}
      </button>
    </div>
  );

  return (
    <div className="min-h-dvh lg:grid lg:grid-cols-[260px_1fr]">
      <aside className="sticky top-0 hidden h-dvh flex-col border-r border-line bg-elevated lg:flex">
        <div className="flex items-center gap-2.5 px-6 py-5 font-semibold">
          <Logo />
          {t.appName}
        </div>
        {nav}
        {footer}
      </aside>

      <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-line bg-elevated/90 px-4 backdrop-blur lg:hidden">
        <div className="flex items-center gap-2 font-semibold">
          <Logo />
          {t.appName}
        </div>
        <button type="button" onClick={() => setOpen((v) => !v)} aria-expanded={open} aria-controls="admin-mobile-nav" className="rounded-full p-2 hover:bg-line" aria-label={t.common.close}>
          {open ? <X className="size-5" /> : <Menu className="size-5" />}
        </button>
      </header>
      {open && (
        <div id="admin-mobile-nav" className="flex flex-col border-b border-line bg-elevated py-3 lg:hidden">
          {nav}
          {footer}
        </div>
      )}

      <main id="main" className="min-w-0 px-4 py-6 sm:px-8 sm:py-8">
        <Outlet />
      </main>
    </div>
  );
}
