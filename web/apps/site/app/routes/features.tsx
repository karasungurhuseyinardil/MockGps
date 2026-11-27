import type { Route } from "./+types/features";
import { DownloadSection } from "../components/download";
import { FeatureGrid, PhoneFrame, PlatformLimits, Section } from "../components/sections";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("features", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function Features() {
  const { t } = useI18n();
  return (
    <>
      <Section title={t.features.title} intro={t.features.intro}>
        <FeatureGrid />
      </Section>
      <div className="mx-auto flex max-w-6xl flex-wrap justify-center gap-8 px-4 sm:px-6">
        <PhoneFrame src="/screens/favorites.png" alt={t.features.items[3]!.title} />
        <PhoneFrame src="/screens/route.png" alt={t.features.items[2]!.title} className="hidden md:block" />
        <PhoneFrame src="/screens/setup.png" alt={t.how.title} className="hidden lg:block" />
      </div>
      <Section title={t.limits.title}>
        <PlatformLimits />
      </Section>
      <DownloadSection />
    </>
  );
}
