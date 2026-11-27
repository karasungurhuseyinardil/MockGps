import type { Route } from "./+types/faq";
import { FaqList, Section } from "../components/sections";
import { dictionaries, useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => {
  const lang = langFromRouteId(matches.at(-1)?.id ?? "");
  // FAQ rich results (schema.org FAQPage).
  const faq = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: dictionaries[lang].faq.items.map((i) => ({ "@type": "Question", name: i.q, acceptedAnswer: { "@type": "Answer", text: i.a } })),
  };
  return [...pageMeta("faq", lang), { "script:ld+json": faq }];
};

export default function Faq() {
  const { t } = useI18n();
  return (
    <Section title={t.faq.title}>
      <FaqList />
    </Section>
  );
}
