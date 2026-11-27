import type { Config } from "@react-router/dev/config";
import { PAGES } from "./app/pages";

/** Static site: every page is pre-rendered in English (/) and Turkish (/tr) for SEO. */
export default {
  ssr: false,
  prerender: [...PAGES.map((p) => p.path), ...PAGES.map((p) => (p.path === "/" ? "/tr" : `/tr${p.path}`))],
} satisfies Config;
