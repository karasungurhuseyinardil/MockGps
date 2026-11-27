import { buttonClass } from "@mockgps/ui";
import { ArrowRight } from "lucide-react";
import { Link } from "react-router";
import type { Route } from "./+types/home";
import { DownloadSection } from "../components/download";
import { FaqList, FeatureGrid, Hero, Highlights, PlatformLimits, Section, Steps } from "../components/sections";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("home", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function Home() {
  const { t, path } = useI18n();
  return (
    <>
      <Hero />
      <Highlights />
      <Section id="features" title={t.features.title} intro={t.features.intro}>
        <FeatureGrid limit={6} />
        <div className="mt-8 text-center">
          <Link to={path("/features")} className={buttonClass("ghost", "md")}>
            {t.nav.features} <ArrowRight className="size-4" aria-hidden />
          </Link>
        </div>
      </Section>
      <Section id="how" title={t.how.title} intro={t.how.intro}>
        <Steps />
      </Section>
      <Section title={t.limits.title}>
        <PlatformLimits />
      </Section>
      <Section id="faq" title={t.faq.title}>
        <FaqList limit={4} />
        <div className="mt-8 text-center">
          <Link to={path("/faq")} className={buttonClass("ghost", "md")}>
            {t.nav.faq} <ArrowRight className="size-4" aria-hidden />
          </Link>
        </div>
      </Section>
      <DownloadSection />
    </>
  );
}
