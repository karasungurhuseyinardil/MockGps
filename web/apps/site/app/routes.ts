import { type RouteConfig, index, layout, prefix, route } from "@react-router/dev/routes";
import { PAGES } from "./pages";

/** The same page modules serve English (no prefix) and Turkish (/tr). */
function pages(lang: "en" | "tr") {
  return PAGES.map((p) =>
    p.path === "/" ? index(p.file, { id: `${lang}-${p.key}` }) : route(p.path.slice(1), p.file, { id: `${lang}-${p.key}` }),
  );
}

export default [
  layout("routes/layout.tsx", { id: "en-layout" }, pages("en")),
  ...prefix("tr", [layout("routes/layout.tsx", { id: "tr-layout" }, pages("tr"))]),
  route("*", "routes/not-found.tsx"),
] satisfies RouteConfig;
