import type { Route } from "./+types/terms";
import { LegalPage } from "../components/legal";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("terms", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function Terms() {
  const { lang } = useI18n();
  return lang === "tr" ? (
    <LegalPage title="Kullanım koşulları" updated="Son güncelleme: 26 Kasım 2026">
      <section>
        <h2>1. Amaç</h2>
        <p>Mock GPS, yazılım geliştirme ve test amaçlı bir konum simülasyon aracıdır. Uygulamayı kullanarak bu koşulları kabul etmiş olursun.</p>
      </section>
      <section>
        <h2>2. Kabul edilebilir kullanım</h2>
        <ul>
          <li>Uygulamayı yürürlükteki yasalara ve test ettiğin uygulama ve hizmetlerin koşullarına uygun kullan.</li>
          <li>Dolandırıcılık, başkalarını yanıltma, konum doğrulaması gerektiren hizmetleri kötüye kullanma veya yasal yükümlülüklerden kaçınma amacıyla kullanma.</li>
          <li>Hizmete aşırı yük bindirme, yetkisiz erişim deneme veya başka kullanıcıların verilerine erişmeye çalışma.</li>
        </ul>
      </section>
      <section>
        <h2>3. Platform sınırları</h2>
        <p>Simülasyon Android'in resmi sahte konum özelliğini kullanır. Android bu konumları işaretler ve bazı uygulamalar bunları reddedebilir. iOS sistem genelinde simülasyonu desteklemez. Bu sınırlamalar bir hizmet hatası değildir.</p>
      </section>
      <section>
        <h2>4. Hesap</h2>
        <p>Hesabının güvenliğinden sen sorumlusun. Bu koşulları ihlal eden hesapları askıya alabiliriz. Hesabını istediğin zaman uygulamadan silebilirsin.</p>
      </section>
      <section>
        <h2>5. Sorumluluk</h2>
        <p>Uygulama "olduğu gibi" sunulur. Yasaların izin verdiği ölçüde, uygulamanın kullanımından doğan dolaylı zararlardan sorumlu değiliz.</p>
      </section>
      <section>
        <h2>6. Değişiklikler</h2>
        <p>Bu koşulları güncelleyebiliriz; önemli değişiklikleri uygulama içi duyuru ile bildiririz.</p>
      </section>
    </LegalPage>
  ) : (
    <LegalPage title="Terms of service" updated="Last updated: 26 November 2026">
      <section>
        <h2>1. Purpose</h2>
        <p>Mock GPS is a location simulation tool for software development and testing. By using it you agree to these terms.</p>
      </section>
      <section>
        <h2>2. Acceptable use</h2>
        <ul>
          <li>Use the app in line with applicable law and the terms of the apps and services you test.</li>
          <li>Do not use it for fraud, to mislead others, to abuse services that rely on location verification, or to avoid legal obligations.</li>
          <li>Do not overload the service, attempt unauthorised access or try to access other users' data.</li>
        </ul>
      </section>
      <section>
        <h2>3. Platform limits</h2>
        <p>Simulation uses Android's official mock location feature. Android marks these locations, and some apps may refuse them. iOS does not support system-wide simulation. These limits are not service defects.</p>
      </section>
      <section>
        <h2>4. Account</h2>
        <p>You are responsible for keeping your account secure. We may suspend accounts that break these terms. You can delete your account at any time in the app.</p>
      </section>
      <section>
        <h2>5. Liability</h2>
        <p>The app is provided "as is". To the extent permitted by law, we are not liable for indirect damages arising from its use.</p>
      </section>
      <section>
        <h2>6. Changes</h2>
        <p>We may update these terms and will announce material changes in the app.</p>
      </section>
    </LegalPage>
  );
}
