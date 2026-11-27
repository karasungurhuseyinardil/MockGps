import { buttonClass } from "@mockgps/ui";
import { Link } from "react-router";
import { dictionaries, langFromPath, localePath } from "../i18n";
import { useLocation } from "react-router";

export const meta = () => [{ title: "404 — Mock GPS" }, { name: "robots", content: "noindex" }];

export default function NotFound() {
  const { pathname } = useLocation();
  const lang = langFromPath(pathname);
  const t = dictionaries[lang].notFound;
  return (
    <main className="mx-auto flex min-h-[70dvh] max-w-xl flex-col items-center justify-center px-6 text-center">
      <p className="font-mono text-sm text-simulated">404 · 0.000000, 0.000000</p>
      <h1 className="mt-4 text-4xl font-bold">{t.title}</h1>
      <p className="mt-3 text-muted">{t.body}</p>
      <Link to={localePath("/", lang)} className={buttonClass("primary", "md", "mt-8")}>
        {t.back}
      </Link>
    </main>
  );
}
