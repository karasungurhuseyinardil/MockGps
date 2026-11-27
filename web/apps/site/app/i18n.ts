import { useLocation } from "react-router";
import type { PageKey } from "./pages";

export type Lang = "en" | "tr";

export function langFromPath(pathname: string): Lang {
  return pathname === "/tr" || pathname.startsWith("/tr/") ? "tr" : "en";
}

/** Path of a page in a language. */
export function localePath(path: string, lang: Lang): string {
  if (lang === "en") return path;
  return path === "/" ? "/tr" : `/tr${path}`;
}

/** Path of the current page in the other language. */
export function switchLanguagePath(pathname: string, to: Lang): string {
  const base = langFromPath(pathname) === "tr" ? pathname.replace(/^\/tr/, "") || "/" : pathname;
  return localePath(base, to);
}

const en = {
  meta: {
    siteName: "Mock GPS",
    tagline: "Location simulation for developers and QA",
    pages: {
      home: { title: "Mock GPS — Location simulation for Android testing", description: "Test location-based apps anywhere in the world. Pick a point or a route on the map and Android apps receive it through the official mock location API. Free, no ads, no root." },
      features: { title: "Features — Mock GPS", description: "Point and route simulation, favorites, history, GPX export, accuracy and interval control — built for developers and QA teams." },
      how: { title: "How it works — Mock GPS", description: "Set up Android's mock location in about a minute, without root, and start simulating." },
      about: { title: "About — Mock GPS", description: "Why we build an ad-free, honest location simulation tool." },
      faq: { title: "FAQ — Mock GPS", description: "Answers about Android setup, mock detection, iOS support and privacy." },
      contact: { title: "Contact — Mock GPS", description: "Questions, bug reports or feedback — we read every message." },
      privacy: { title: "Privacy policy — Mock GPS", description: "What data Mock GPS processes and how you control it." },
      terms: { title: "Terms of service — Mock GPS", description: "The rules for using Mock GPS." },
    } satisfies Record<PageKey, { title: string; description: string }>,
  },
  nav: { home: "Home", features: "Features", how: "How it works", about: "About", faq: "FAQ", contact: "Contact", privacy: "Privacy", terms: "Terms", download: "Download", menu: "Menu", close: "Close menu", skip: "Skip to content" },
  theme: { system: "Theme: system", light: "Theme: light", dark: "Theme: dark" },
  hero: {
    eyebrow: "No root · No ads · Android",
    title: "Test your app from anywhere on the map.",
    body: "Pick a point, type coordinates or draw a route. Mock GPS feeds it to Android through the official mock location API, so every app on the device sees the same simulated location.",
    primary: "Download for Android",
    secondary: "See how it works",
    simulating: "Simulating",
  },
  highlights: [
    { title: "Official Android API", body: "Uses Developer options → mock location app. No root, no hacks." },
    { title: "Built for QA", body: "Routes with speed, accuracy and update interval you control." },
    { title: "Private by default", body: "Location history stays on your phone unless you turn on sync." },
  ],
  features: {
    title: "Everything you need to test location features",
    intro: "Designed with QA engineers and mobile developers. Every feature works on a real device today.",
    items: [
      { title: "Map, search and coordinates", body: "Tap the map, search an address or paste \"41.0082, 28.9784\". Reverse geocoding shows the address of every point." },
      { title: "One-tap simulation", body: "Start, stop or move the simulated point. A persistent notification shows the status and a Stop button." },
      { title: "Routes with speed", body: "Draw a path, set 5–200 km/h, loop it, pause and resume. Bearing and speed are reported like a real GPS fix." },
      { title: "Favorites and categories", body: "Save test locations with notes, group them into categories like Work, Cities or Test locations, and activate them with one tap." },
      { title: "History", body: "Re-use recent locations. Stored on the device; optional sync to your account." },
      { title: "Accuracy and interval", body: "Choose the accuracy radius apps receive and how often the location updates, with optional natural drift." },
      { title: "Verification screen", body: "Check that apps really receive the simulated location — distance and mock flag included." },
      { title: "GPX export", body: "Export points and routes as GPX for Xcode's Simulate Location on iOS." },
      { title: "Dark mode, Turkish and English", body: "A calm, map-first interface with light and dark themes." },
    ],
  },
  how: {
    title: "Ready in about a minute",
    intro: "Android lets exactly one app provide test locations. Mock GPS guides you through each step and checks it automatically.",
    steps: [
      { title: "Turn on Developer options", body: "Settings → About phone → tap Build number seven times." },
      { title: "Select Mock GPS as mock location app", body: "Developer options → Select mock location app → Mock GPS. The app opens this screen for you." },
      { title: "Pick a place and start", body: "Choose a point, a favorite or a route and tap Start. Other apps now see the simulated location." },
    ],
    noteTitle: "Good to know",
    note: "Android marks simulated locations as mock. Some apps — for example banking apps and some games — detect this and may refuse to work. Mock GPS does not hide it.",
  },
  limits: {
    title: "Honest about platform limits",
    android: { title: "Android", body: "Full system-wide simulation with the official mock location API. Developer options must stay on." },
    ios: { title: "iOS", body: "iOS does not allow apps to change the location other apps see. The iOS app manages favorites and routes and exports GPX files for Xcode." },
  },
  faq: {
    title: "Frequently asked questions",
    items: [
      { q: "Do I need root?", a: "No. Mock GPS uses Android's official mock location setting in Developer options." },
      { q: "Will every app see the simulated location?", a: "Apps that use Android's location services receive it, including apps that use Google Play services. Android flags these locations as mock, and some apps (banking, some games, anti-fraud checks) refuse them. We do not try to bypass this." },
      { q: "Does it work on iPhone?", a: "Not system-wide. Apple provides no public API for this, so no App Store app can do it. You can export GPX files and load them in Xcode on a connected device or in the Simulator." },
      { q: "Does the simulation keep running in the background?", a: "Yes. It runs in a foreground service with a visible notification. Some manufacturers stop background apps aggressively; the setup guide links to the battery settings." },
      { q: "Is my location history uploaded?", a: "No, not by default. History is stored on your phone. You can turn on sync in settings; turning it off deletes the cloud copy." },
      { q: "Is it free? Are there ads?", a: "Mock GPS is free and has no ads or tracking SDKs." },
      { q: "How do I delete my account?", a: "Settings → Delete account. Your profile, favorites, routes and cloud history are deleted permanently. You can download your data first." },
    ],
  },
  download: {
    title: "Get Mock GPS for Android",
    body: "Android 8.0 or newer. Free, no ads.",
    button: "Download APK",
    version: "Version {version} · build {build}",
    size: "{size} MB",
    loading: "Checking the latest version…",
    unavailable: "No public release is available yet. Leave your email on the contact page and we'll let you know.",
    error: "Couldn't load release information. Please try again later.",
    notes: "What's new",
  },
  about: {
    title: "About Mock GPS",
    paragraphs: [
      "Mock GPS started as a tool for testing location-based features: delivery zones, region-locked content, geofences and maps. Most simulation apps we tried were full of ads, asked for unnecessary permissions or claimed things the platform does not allow.",
      "We built the opposite: a focused tool that uses only official platform APIs, explains exactly what works and what does not, and keeps your location data on your device by default.",
      "Mock GPS is for testing and development. Please respect the terms of the apps and services you test.",
    ],
    values: [
      { title: "No ads, no trackers", body: "The app contains no advertising or third-party analytics SDKs." },
      { title: "Official APIs only", body: "No root, no private frameworks, no detection bypass." },
      { title: "Your data, your control", body: "Local-first history, data export and full account deletion." },
    ],
  },
  contact: {
    title: "Contact",
    intro: "Bug reports, feature ideas or questions — we read every message.",
    name: "Name",
    email: "Email",
    subject: "Subject",
    message: "Message",
    send: "Send message",
    sent: "Thanks! Your message has been sent. We usually reply within two working days.",
    errors: { name: "Enter your name.", email: "Enter a valid email address.", subject: "Enter a subject.", message: "Write at least 10 characters.", rateLimited: "Too many messages. Please try again in a few minutes.", network: "Could not reach the server. Check your connection and try again.", generic: "Something went wrong. Please try again." },
    direct: "Or email us at",
  },
  footer: { rights: "All rights reserved.", madeFor: "Made for developers and QA teams.", attribution: "Map data © OpenStreetMap contributors" },
  notFound: { title: "Page not found", body: "The page you are looking for does not exist.", back: "Back to home" },
};

type Dict = typeof en;

const tr: Dict = {
  meta: {
    siteName: "Mock GPS",
    tagline: "Geliştiriciler ve QA için konum simülasyonu",
    pages: {
      home: { title: "Mock GPS — Android test için konum simülasyonu", description: "Konum tabanlı uygulamaları dünyanın her yerinden test et. Haritada bir nokta ya da rota seç; Android uygulamaları bunu resmi mock location API'si üzerinden alır. Ücretsiz, reklamsız, root gerekmez." },
      features: { title: "Özellikler — Mock GPS", description: "Nokta ve rota simülasyonu, favoriler, geçmiş, GPX dışa aktarma, doğruluk ve aralık kontrolü — geliştiriciler ve QA ekipleri için." },
      how: { title: "Nasıl çalışır — Mock GPS", description: "Android'in sahte konum özelliğini root olmadan yaklaşık bir dakikada kur ve simülasyona başla." },
      about: { title: "Hakkında — Mock GPS", description: "Neden reklamsız ve dürüst bir konum simülasyon aracı geliştiriyoruz." },
      faq: { title: "SSS — Mock GPS", description: "Android kurulumu, sahte konum algılama, iOS desteği ve gizlilik hakkında yanıtlar." },
      contact: { title: "İletişim — Mock GPS", description: "Sorular, hata bildirimleri veya geri bildirim — her mesajı okuyoruz." },
      privacy: { title: "Gizlilik politikası — Mock GPS", description: "Mock GPS hangi verileri işler ve bunları nasıl kontrol edersin." },
      terms: { title: "Kullanım koşulları — Mock GPS", description: "Mock GPS kullanım kuralları." },
    },
  },
  nav: { home: "Ana sayfa", features: "Özellikler", how: "Nasıl çalışır", about: "Hakkında", faq: "SSS", contact: "İletişim", privacy: "Gizlilik", terms: "Koşullar", download: "İndir", menu: "Menü", close: "Menüyü kapat", skip: "İçeriğe geç" },
  theme: { system: "Tema: sistem", light: "Tema: açık", dark: "Tema: koyu" },
  hero: {
    eyebrow: "Root yok · Reklam yok · Android",
    title: "Uygulamanı haritanın her yerinden test et.",
    body: "Bir nokta seç, koordinat yaz ya da rota çiz. Mock GPS bunu resmi mock location API'si ile Android'e iletir; cihazdaki tüm uygulamalar aynı simüle konumu görür.",
    primary: "Android için indir",
    secondary: "Nasıl çalıştığını gör",
    simulating: "Simüle ediliyor",
  },
  highlights: [
    { title: "Resmi Android API'si", body: "Geliştirici seçenekleri → sahte konum uygulaması. Root yok, hile yok." },
    { title: "QA için tasarlandı", body: "Hız, doğruluk ve güncelleme aralığını kontrol ettiğin rotalar." },
    { title: "Varsayılan olarak gizli", body: "Eşitlemeyi açmadıkça konum geçmişin telefonunda kalır." },
  ],
  features: {
    title: "Konum özelliklerini test etmek için ihtiyacın olan her şey",
    intro: "QA mühendisleri ve mobil geliştiricilerle birlikte tasarlandı. Her özellik bugün gerçek bir cihazda çalışır.",
    items: [
      { title: "Harita, arama ve koordinat", body: "Haritaya dokun, adres ara ya da \"41.0082, 28.9784\" yapıştır. Ters coğrafi kodlama her noktanın adresini gösterir." },
      { title: "Tek dokunuşla simülasyon", body: "Simüle noktayı başlat, durdur veya taşı. Kalıcı bildirim durumu ve Durdur butonunu gösterir." },
      { title: "Hızlı rotalar", body: "Yol çiz, 5–200 km/sa hız seç, döngüye al, duraklat ve devam ettir. Yön ve hız gerçek bir GPS konumu gibi bildirilir." },
      { title: "Favoriler ve kategoriler", body: "Test konumlarını notlarla kaydet, İş, Şehirler veya Test Lokasyonları gibi kategorilere ayır, tek dokunuşla etkinleştir." },
      { title: "Geçmiş", body: "Son konumları tekrar kullan. Cihazda saklanır; istersen hesabınla eşitlenir." },
      { title: "Doğruluk ve aralık", body: "Uygulamaların alacağı doğruluk yarıçapını ve güncelleme sıklığını seç; istersen doğal sapma ekle." },
      { title: "Doğrulama ekranı", body: "Uygulamaların simüle konumu gerçekten aldığını mesafe ve sahte konum işaretiyle kontrol et." },
      { title: "GPX dışa aktarma", body: "Noktaları ve rotaları iOS'ta Xcode'un Simulate Location özelliği için GPX olarak aktar." },
      { title: "Koyu mod, Türkçe ve İngilizce", body: "Açık ve koyu temalı, haritayı merkeze alan sakin bir arayüz." },
    ],
  },
  how: {
    title: "Yaklaşık bir dakikada hazır",
    intro: "Android test konumu sağlamak için tek bir uygulamaya izin verir. Mock GPS seni her adımda yönlendirir ve otomatik kontrol eder.",
    steps: [
      { title: "Geliştirici seçeneklerini aç", body: "Ayarlar → Telefon hakkında → Yapım numarasına yedi kez dokun." },
      { title: "Mock GPS'i sahte konum uygulaması seç", body: "Geliştirici seçenekleri → Sahte konum uygulamasını seç → Mock GPS. Uygulama bu ekranı senin için açar." },
      { title: "Bir yer seç ve başlat", body: "Bir nokta, favori veya rota seç ve Başlat'a dokun. Diğer uygulamalar artık simüle konumu görür." },
    ],
    noteTitle: "Bilmekte fayda var",
    note: "Android simüle konumları sahte olarak işaretler. Bazı uygulamalar — örneğin bankacılık uygulamaları ve bazı oyunlar — bunu algılayıp çalışmayabilir. Mock GPS bunu gizlemez.",
  },
  limits: {
    title: "Platform sınırları konusunda dürüstüz",
    android: { title: "Android", body: "Resmi mock location API'si ile sistem genelinde tam simülasyon. Geliştirici seçenekleri açık kalmalı." },
    ios: { title: "iOS", body: "iOS, uygulamaların diğer uygulamaların gördüğü konumu değiştirmesine izin vermez. iOS uygulaması favorileri ve rotaları yönetir, Xcode için GPX dosyası üretir." },
  },
  faq: {
    title: "Sıkça sorulan sorular",
    items: [
      { q: "Root gerekiyor mu?", a: "Hayır. Mock GPS, Android'in Geliştirici seçeneklerindeki resmi sahte konum ayarını kullanır." },
      { q: "Her uygulama simüle konumu görür mü?", a: "Android konum servislerini kullanan uygulamalar — Google Play hizmetlerini kullananlar dahil — simüle konumu alır. Android bu konumları sahte olarak işaretler; bazı uygulamalar (bankacılık, bazı oyunlar, dolandırıcılık kontrolleri) bunları reddeder. Bunu atlatmaya çalışmıyoruz." },
      { q: "iPhone'da çalışıyor mu?", a: "Sistem genelinde hayır. Apple bunun için herkese açık bir API sunmaz; App Store'daki hiçbir uygulama bunu yapamaz. GPX dosyası dışa aktarıp bağlı bir cihazda veya Simülatör'de Xcode ile kullanabilirsin." },
      { q: "Simülasyon arka planda çalışmaya devam eder mi?", a: "Evet. Görünür bir bildirimle ön plan servisinde çalışır. Bazı üreticiler arka plan uygulamalarını agresif şekilde durdurur; kurulum rehberi pil ayarlarına bağlantı verir." },
      { q: "Konum geçmişim sunucuya yükleniyor mu?", a: "Varsayılan olarak hayır. Geçmiş telefonunda saklanır. Ayarlardan eşitlemeyi açabilirsin; kapattığında buluttaki kopya silinir." },
      { q: "Ücretsiz mi? Reklam var mı?", a: "Mock GPS ücretsizdir; reklam veya izleme SDK'sı içermez." },
      { q: "Hesabımı nasıl silerim?", a: "Ayarlar → Hesabı sil. Profilin, favorilerin, rotaların ve buluttaki geçmişin kalıcı olarak silinir. Öncesinde verilerini indirebilirsin." },
    ],
  },
  download: {
    title: "Mock GPS'i Android için indir",
    body: "Android 8.0 veya üzeri. Ücretsiz, reklamsız.",
    button: "APK indir",
    version: "Sürüm {version} · derleme {build}",
    size: "{size} MB",
    loading: "Son sürüm kontrol ediliyor…",
    unavailable: "Henüz yayımlanmış bir sürüm yok. İletişim sayfasından e-postanı bırak, haber verelim.",
    error: "Sürüm bilgisi yüklenemedi. Lütfen daha sonra tekrar dene.",
    notes: "Yenilikler",
  },
  about: {
    title: "Mock GPS hakkında",
    paragraphs: [
      "Mock GPS, konum tabanlı özellikleri test etmek için bir araç olarak başladı: teslimat bölgeleri, bölgeye özel içerik, geofence'ler ve haritalar. Denediğimiz simülasyon uygulamalarının çoğu reklam doluydu, gereksiz izinler istiyordu ya da platformun izin vermediği şeyleri vaat ediyordu.",
      "Biz tam tersini yaptık: yalnızca resmi platform API'lerini kullanan, neyin çalışıp neyin çalışmadığını açıkça anlatan ve konum verini varsayılan olarak cihazında tutan odaklı bir araç.",
      "Mock GPS test ve geliştirme içindir. Lütfen test ettiğin uygulama ve hizmetlerin koşullarına uy.",
    ],
    values: [
      { title: "Reklam yok, izleyici yok", body: "Uygulama reklam veya üçüncü taraf analiz SDK'sı içermez." },
      { title: "Yalnızca resmi API'ler", body: "Root yok, gizli framework yok, algılama atlatma yok." },
      { title: "Verin, kontrolün", body: "Önce cihazda tutulan geçmiş, veri dışa aktarma ve tam hesap silme." },
    ],
  },
  contact: {
    title: "İletişim",
    intro: "Hata bildirimleri, özellik fikirleri veya sorular — her mesajı okuyoruz.",
    name: "Ad",
    email: "E-posta",
    subject: "Konu",
    message: "Mesaj",
    send: "Mesajı gönder",
    sent: "Teşekkürler! Mesajın gönderildi. Genellikle iki iş günü içinde yanıtlıyoruz.",
    errors: { name: "Adını gir.", email: "Geçerli bir e-posta adresi gir.", subject: "Bir konu gir.", message: "En az 10 karakter yaz.", rateLimited: "Çok fazla mesaj gönderildi. Birkaç dakika sonra tekrar dene.", network: "Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.", generic: "Bir şeyler ters gitti. Lütfen tekrar dene." },
    direct: "Ya da e-posta gönder:",
  },
  footer: { rights: "Tüm hakları saklıdır.", madeFor: "Geliştiriciler ve QA ekipleri için yapıldı.", attribution: "Harita verisi © OpenStreetMap katkıcıları" },
  notFound: { title: "Sayfa bulunamadı", body: "Aradığın sayfa mevcut değil.", back: "Ana sayfaya dön" },
};

export const dictionaries: Record<Lang, Dict> = { en, tr };

export function useI18n() {
  const { pathname } = useLocation();
  const lang = langFromPath(pathname);
  return { lang, t: dictionaries[lang], path: (p: string) => localePath(p, lang) };
}

export function format(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, k: string) => String(values[k] ?? ""));
}
