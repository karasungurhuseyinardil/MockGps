import type { Route } from "./+types/how-it-works";
import { DownloadSection } from "../components/download";
import { PhoneFrame, PlatformLimits, Section, Steps } from "../components/sections";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("how", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function HowItWorks() {
  const { t } = useI18n();
  return (
    <>
      <Section title={t.how.title} intro={t.how.intro}>
        <Steps />
      </Section>
      <div className="flex justify-center px-4">
        <PhoneFrame src="/screens/setup.png" alt={t.how.steps[1]!.title} />
      </div>
      <Section title={t.limits.title}>
        <PlatformLimits />
      </Section>
      <DownloadSection />
    </>
  );
}
