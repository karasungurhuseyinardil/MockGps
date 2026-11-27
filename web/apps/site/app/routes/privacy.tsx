import type { Route } from "./+types/privacy";
import { LegalPage } from "../components/legal";
import { useI18n } from "../i18n";
import { langFromRouteId, pageMeta } from "../seo";

export const meta: Route.MetaFunction = ({ matches }) => pageMeta("privacy", langFromRouteId(matches.at(-1)?.id ?? ""));

export default function Privacy() {
  const { lang } = useI18n();
  return lang === "tr" ? <PrivacyTr /> : <PrivacyEn />;
}

function PrivacyEn() {
  return (
    <LegalPage title="Privacy policy" updated="Last updated: 26 November 2026">
      <section>
        <h2>Summary</h2>
        <ul>
          <li>Your location history stays on your phone unless you turn on cloud sync.</li>
          <li>We do not show ads and do not include third-party analytics or advertising SDKs.</li>
          <li>You can download all your data and delete your account at any time in the app.</li>
        </ul>
      </section>
      <section>
        <h2>Data we process</h2>
        <ul>
          <li><strong>Account:</strong> email address, optional display name and avatar, password (stored as a hash by our authentication provider).</li>
          <li><strong>Favorites, categories and routes</strong> you save, so they are available on your devices.</li>
          <li><strong>Location history:</strong> stored only on your device by default. If you enable "Sync history to my account", the simulated points (coordinates, address, time) are stored in your account. Turning sync off deletes the cloud copy.</li>
          <li><strong>Settings</strong> such as theme, language and simulation preferences.</li>
          <li><strong>Usage statistics:</strong> event types (for example "simulation started"), platform and app version, linked to your account. These events never contain coordinates.</li>
          <li><strong>Address search:</strong> search text and the coordinates of reverse-lookups are sent to our API, which forwards them to a geocoding provider based on OpenStreetMap data. Results are cached for up to 24 hours without your identity.</li>
          <li><strong>Map tiles</strong> are loaded from OpenFreeMap; like any web server, it receives your IP address and the requested map area.</li>
          <li><strong>Contact form:</strong> name, email and message, used only to answer you.</li>
          <li><strong>Server logs:</strong> IP address, request path and status for security and troubleshooting, kept for 14 days. Coordinates are not logged.</li>
        </ul>
      </section>
      <section>
        <h2>The simulated location on your device</h2>
        <p>The location you simulate is passed to Android on your phone. Other apps on your device receive it through Android's location services, as with any mock location app. Android marks these locations as mock.</p>
      </section>
      <section>
        <h2>Where data is stored</h2>
        <p>Account data is stored with our database and authentication provider (Supabase). Access is limited to the backend service; every user can only access their own records.</p>
      </section>
      <section>
        <h2>Your rights</h2>
        <p>Under GDPR and the Turkish Personal Data Protection Law (KVKK) you can access, correct, export and delete your data. In the app: Settings → Download my data, and Settings → Delete account. Deleting your account removes your profile, favorites, categories, routes, cloud history and avatar. Administrative audit records keep the action but are no longer linked to you.</p>
      </section>
      <section>
        <h2>Contact</h2>
        <p>Questions about privacy? Use the contact page and choose a subject starting with "Privacy".</p>
      </section>
    </LegalPage>
  );
}

function PrivacyTr() {
  return (
    <LegalPage title="Gizlilik politikası" updated="Son güncelleme: 26 Kasım 2026">
      <section>
        <h2>Özet</h2>
        <ul>
          <li>Bulut eşitlemeyi açmadıkça konum geçmişin telefonunda kalır.</li>
          <li>Reklam göstermiyoruz; üçüncü taraf analiz veya reklam SDK'sı kullanmıyoruz.</li>
          <li>Tüm verilerini uygulamadan istediğin zaman indirebilir ve hesabını silebilirsin.</li>
        </ul>
      </section>
      <section>
        <h2>İşlediğimiz veriler</h2>
        <ul>
          <li><strong>Hesap:</strong> e-posta adresi, isteğe bağlı ad ve profil fotoğrafı, şifre (kimlik doğrulama sağlayıcımızda özetlenmiş olarak saklanır).</li>
          <li><strong>Kaydettiğin favoriler, kategoriler ve rotalar</strong> — cihazlarında kullanılabilmeleri için.</li>
          <li><strong>Konum geçmişi:</strong> varsayılan olarak yalnızca cihazında saklanır. "Geçmişi hesabımla eşitle" seçeneğini açarsan simüle edilen noktalar (koordinat, adres, zaman) hesabında saklanır. Eşitlemeyi kapatınca buluttaki kopya silinir.</li>
          <li><strong>Ayarlar:</strong> tema, dil ve simülasyon tercihleri.</li>
          <li><strong>Kullanım istatistikleri:</strong> olay türleri (ör. "simülasyon başladı"), platform ve uygulama sürümü; hesabınla ilişkilidir. Bu olaylar asla koordinat içermez.</li>
          <li><strong>Adres arama:</strong> arama metni ve ters arama koordinatları API'mize gönderilir ve OpenStreetMap verisine dayalı bir coğrafi kodlama sağlayıcısına iletilir. Sonuçlar kimliğin olmadan en fazla 24 saat önbellekte tutulur.</li>
          <li><strong>Harita karoları</strong> OpenFreeMap'ten yüklenir; her web sunucusu gibi IP adresini ve istenen harita bölgesini görür.</li>
          <li><strong>İletişim formu:</strong> ad, e-posta ve mesaj; yalnızca sana yanıt vermek için kullanılır.</li>
          <li><strong>Sunucu kayıtları:</strong> güvenlik ve sorun giderme için IP adresi, istek yolu ve durum 14 gün saklanır. Koordinatlar kaydedilmez.</li>
        </ul>
      </section>
      <section>
        <h2>Cihazındaki simüle konum</h2>
        <p>Simüle ettiğin konum telefonundaki Android'e iletilir. Cihazındaki diğer uygulamalar bunu, her sahte konum uygulamasında olduğu gibi Android konum servisleri üzerinden alır. Android bu konumları sahte olarak işaretler.</p>
      </section>
      <section>
        <h2>Verilerin saklandığı yer</h2>
        <p>Hesap verileri veritabanı ve kimlik doğrulama sağlayıcımızda (Supabase) saklanır. Erişim yalnızca backend servisine açıktır; her kullanıcı yalnızca kendi kayıtlarına erişebilir.</p>
      </section>
      <section>
        <h2>Hakların</h2>
        <p>KVKK ve GDPR kapsamında verilerine erişebilir, düzeltebilir, dışa aktarabilir ve silebilirsin. Uygulamada: Ayarlar → Verilerimi indir ve Ayarlar → Hesabı sil. Hesap silme; profilini, favorilerini, kategorilerini, rotalarını, buluttaki geçmişini ve profil fotoğrafını kaldırır. Yönetim denetim kayıtları işlemi korur ancak artık seninle ilişkilendirilmez.</p>
      </section>
      <section>
        <h2>İletişim</h2>
        <p>Gizlilikle ilgili soruların için iletişim sayfasını kullan ve konuya "Gizlilik" yaz.</p>
      </section>
    </LegalPage>
  );
}
