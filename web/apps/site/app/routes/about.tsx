import { Card } from "@mockgps/ui";
import type { Route } from "./+types/about";
import { Section } from "../components/sections";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("about", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function About() {
  const { t } = useI18n();
  return (
    <Section title={t.about.title}>
      <div className="mx-auto max-w-2xl space-y-5 text-lg leading-relaxed text-muted">
        {t.about.paragraphs.map((p) => (
          <p key={p.slice(0, 24)}>{p}</p>
        ))}
      </div>
      <div className="mx-auto mt-12 grid max-w-4xl gap-4 sm:grid-cols-3">
        {t.about.values.map((v) => (
          <Card key={v.title} className="p-6">
            <h3 className="font-semibold">{v.title}</h3>
            <p className="mt-2 text-sm text-muted">{v.body}</p>
          </Card>
        ))}
      </div>
    </Section>
  );
}
