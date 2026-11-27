import { dictionaries, localePath, type Lang } from "./i18n";
import { PAGES, type PageKey } from "./pages";

const SITE_URL = (import.meta.env.VITE_SITE_URL as string | undefined)?.replace(/\/$/, "") ?? "";

/** Title, description, Open Graph and hreflang alternates for a page. */
export function pageMeta(key: PageKey, lang: Lang) {
  const page = PAGES.find((p) => p.key === key)!;
  const m = dictionaries[lang].meta.pages[key];
  const url = (l: Lang) => `${SITE_URL}${localePath(page.path, l)}`;
  return [
    { title: m.title },
    { name: "description", content: m.description },
    { property: "og:type", content: "website" },
    { property: "og:site_name", content: "Mock GPS" },
    { property: "og:title", content: m.title },
    { property: "og:description", content: m.description },
    { property: "og:url", content: url(lang) },
    { property: "og:image", content: `${SITE_URL}/og-image.png` },
    { property: "og:locale", content: lang === "tr" ? "tr_TR" : "en_US" },
    { name: "twitter:card", content: "summary_large_image" },
    { tagName: "link", rel: "canonical", href: url(lang) },
    { tagName: "link", rel: "alternate", hrefLang: "en", href: url("en") },
    { tagName: "link", rel: "alternate", hrefLang: "tr", href: url("tr") },
    { tagName: "link", rel: "alternate", hrefLang: "x-default", href: url("en") },
  ];
}

export function langFromRouteId(id: string): Lang {
  return id.startsWith("tr-") ? "tr" : "en";
}
