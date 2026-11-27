import { ThemeToggle, buttonClass, cn } from "@mockgps/ui";
import { Languages, Menu, X } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation } from "react-router";
import { Logo } from "../components/logo";
import { switchLanguagePath, useI18n } from "../i18n";

const NAV = [
  ["/features", "features"],
  ["/how-it-works", "how"],
  ["/faq", "faq"],
  ["/about", "about"],
  ["/contact", "contact"],
] as const;

export default function SiteLayout() {
  const { t, lang, path } = useI18n();
  const { pathname, hash } = useLocation();
  const [open, setOpen] = useState(false);
  useEffect(() => setOpen(false), [pathname, hash]);

  const other = lang === "en" ? "tr" : "en";
  return (
    <>
      <a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-primary-fg">
        {t.nav.skip}
      </a>
      <header className="sticky top-0 z-40 border-b border-line bg-bg/80 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
          <Link to={path("/")} className="flex items-center gap-2.5 font-semibold" aria-label="Mock GPS">
            <Logo className="size-8" />
            <span>Mock GPS</span>
          </Link>

          <nav className="hidden items-center gap-1 md:flex" aria-label="Main">
            {NAV.map(([to, key]) => (
              <NavLink
                key={key}
                to={path(to)}
                className={({ isActive }) =>
                  cn("rounded-md px-3 py-2 text-sm transition-colors hover:text-fg", isActive ? "text-fg font-medium" : "text-muted")
                }
              >
                {t.nav[key]}
              </NavLink>
            ))}
          </nav>

          <div className="flex items-center gap-1">
            <Link
              to={switchLanguagePath(pathname, other)}
              className="inline-flex h-10 items-center gap-1.5 rounded-full px-3 text-sm text-muted hover:bg-line hover:text-fg"
              hrefLang={other}
              aria-label={other === "tr" ? "Türkçe" : "English"}
            >
              <Languages className="size-4" aria-hidden />
              {other.toUpperCase()}
            </Link>
            <ThemeToggle labels={t.theme} />
            <Link to={`${path("/")}#download`} className={buttonClass("primary", "sm", "ml-2 hidden sm:inline-flex")}>
              {t.nav.download}
            </Link>
            <button
              type="button"
              className="inline-flex size-10 items-center justify-center rounded-full hover:bg-line md:hidden"
              aria-expanded={open}
              aria-controls="mobile-nav"
              aria-label={open ? t.nav.close : t.nav.menu}
              onClick={() => setOpen((v) => !v)}
            >
              {open ? <X className="size-5" /> : <Menu className="size-5" />}
            </button>
          </div>
        </div>
        {open && (
          <nav id="mobile-nav" className="border-t border-line px-4 pb-4 md:hidden" aria-label="Main">
            {NAV.map(([to, key]) => (
              <NavLink key={key} to={path(to)} className="block rounded-md px-3 py-3 text-base hover:bg-line">
                {t.nav[key]}
              </NavLink>
            ))}
            <Link to={`${path("/")}#download`} className={buttonClass("primary", "md", "mt-2 w-full")}>
              {t.nav.download}
            </Link>
          </nav>
        )}
      </header>

      <main id="main">
        <Outlet />
      </main>

      <footer className="mt-24 border-t border-line">
        <div className="mx-auto grid max-w-6xl gap-8 px-4 py-12 sm:px-6 md:grid-cols-[1.5fr_1fr_1fr]">
          <div className="space-y-3">
            <div className="flex items-center gap-2.5 font-semibold">
              <Logo className="size-7" />
              Mock GPS
            </div>
            <p className="max-w-xs text-sm text-muted">{t.meta.tagline}. {t.footer.madeFor}</p>
          </div>
          <ul className="space-y-2 text-sm">
            {(["features", "how", "faq", "about"] as const).map((k) => (
              <li key={k}>
                <Link className="text-muted hover:text-fg" to={path(NAV.find(([, key]) => key === k)?.[0] ?? "/")}>
                  {t.nav[k]}
                </Link>
              </li>
            ))}
          </ul>
          <ul className="space-y-2 text-sm">
            <li><Link className="text-muted hover:text-fg" to={path("/contact")}>{t.nav.contact}</Link></li>
            <li><Link className="text-muted hover:text-fg" to={path("/privacy")}>{t.nav.privacy}</Link></li>
            <li><Link className="text-muted hover:text-fg" to={path("/terms")}>{t.nav.terms}</Link></li>
          </ul>
        </div>
        <div className="border-t border-line">
          <p className="mx-auto max-w-6xl px-4 py-6 text-xs text-muted sm:px-6">
            © {new Date().getFullYear()} Mock GPS. {t.footer.rights} · {t.footer.attribution}
          </p>
        </div>
      </footer>
    </>
  );
}
