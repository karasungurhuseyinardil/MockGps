import { createContext, useContext, useState, type ReactNode } from "react";

const en = {
  appName: "Mock GPS Admin",
  common: { save: "Save", cancel: "Cancel", delete: "Delete", edit: "Edit", create: "Create", retry: "Try again", loading: "Loading…", search: "Search", all: "All", yes: "Yes", no: "No", close: "Close", saved: "Saved", deleted: "Deleted", confirm: "Are you sure?", previous: "Previous", next: "Next", pageOf: "Page {page} of {pages}", total: "{count} total", actions: "Actions", empty: "Nothing here yet.", noMatch: "No results match your filters." },
  nav: { dashboard: "Dashboard", users: "Users", admins: "Administrators", roles: "Roles & permissions", settings: "System settings", versions: "App versions", announcements: "Announcements", audit: "Audit log", messages: "Messages", signOut: "Sign out", language: "Türkçe" },
  theme: { system: "Theme: system", light: "Theme: light", dark: "Theme: dark" },
  login: { title: "Sign in to admin", subtitle: "Only accounts with an administrator role can continue.", email: "Email", password: "Password", submit: "Sign in", invalid: "Email or password is incorrect.", noAccess: "This account has no administrator permissions.", disabled: "This account has been disabled.", configMissing: "Admin is not configured. Missing: {keys}" },
  errors: { network: "Cannot reach the API. Check that it is running.", forbidden: "You don't have permission for this action.", generic: "Something went wrong. Please try again.", notFound: "Not found." },
  dashboard: { title: "Dashboard", totalUsers: "Total users", newToday: "New today", active24h: "Active (24 h)", active30d: "Active (30 days)", inactive: "Disabled accounts", simulations: "Simulations", simulationsToday: "Simulations today", favorites: "Saved favorites", routes: "Saved routes", newMessages: "New messages", chart: "Activity", metrics: { new_users: "New users", active_users: "Active users", simulations: "Simulations" }, daily: "Daily (30 days)", monthly: "Monthly (12 months)", features: "Feature usage (30 days)", health: "System health", healthy: "Healthy", degraded: "Degraded", unhealthy: "Unavailable", uptime: "Uptime", maintenance: "Maintenance mode is ON", events: { simulation_started: "Simulation started", simulation_stopped: "Simulation stopped", route_started: "Route started", favorite_activated: "Favorite activated", search_used: "Search used", gpx_exported: "GPX exported", app_opened: "App opened" } as Record<string, string> },
  users: { title: "Users", searchHint: "Search email or name", status: "Status", active: "Active", disabled: "Disabled", role: "Role", email: "Email", name: "Name", roles: "Roles", created: "Registered", lastSeen: "Last seen", never: "Never", detail: "User details", stats: "Usage", favorites: "Favorites", categories: "Categories", routes: "Routes", cloudHistory: "Cloud history items", simulationsTotal: "Simulations (total)", simulations30d: "Simulations (30 days)", lastActivity: "Last activity", language: "Language", cloudSync: "Cloud history sync", deactivate: "Disable account", activate: "Enable account", reason: "Reason (optional, saved in audit log)", deactivateConfirm: "The user is signed out and cannot sign in until re-enabled.", editRoles: "Edit roles", rolesSaved: "Roles updated", statusSaved: "Status updated", events: "Events by type" },
  roles: { title: "Roles & permissions", name: "Name", description: "Description", permissions: "Permissions", members: "Members", system: "System role", new: "New role", deleteConfirm: "Delete role \"{name}\"? Members lose its permissions.", perms: { "dashboard.read": "View dashboard", "users.read": "View users", "users.manage": "Enable / disable users", "roles.manage": "Manage roles & permissions", "settings.manage": "Change system settings", "versions.manage": "Manage app versions", "announcements.manage": "Manage announcements", "audit.read": "View audit log", "messages.manage": "Manage contact messages" } as Record<string, string> },
  settings: { title: "System settings", keys: { maintenance_mode: "Maintenance mode", geocoding_enabled: "Address search", history_max_cloud_items: "Max cloud history items per user", support_email: "Support email" } as Record<string, string>, updated: "Last changed", on: "On", off: "Off" },
  versions: { title: "App versions", platform: "Platform", version: "Version", build: "Build", minBuild: "Minimum supported build", minBuildHint: "Older builds are forced to update.", url: "Download URL", notes: "Release notes", published: "Published", draft: "Draft", publish: "Publish", upload: "Upload APK", uploading: "Uploading…", size: "Size", new: "New version", deleteConfirm: "Delete version {version} ({build})?" },
  announcements: { title: "Announcements", new: "New announcement", titleField: "Title", body: "Message", level: "Level", audience: "Audience", starts: "Starts", ends: "Ends (optional)", active: "Active", levels: { info: "Info", warning: "Warning", critical: "Critical" } as Record<string, string>, audiences: { all: "Everyone", android: "Android", ios: "iOS", web: "Web" } as Record<string, string>, deleteConfirm: "Delete this announcement?" },
  audit: { title: "Audit log", time: "Time", actor: "Actor", action: "Action", entity: "Entity", description: "Description", from: "From", to: "To", deletedUser: "Deleted user", system: "System" },
  messages: { title: "Contact messages", from: "From", subject: "Subject", received: "Received", status: "Status", statuses: { new: "New", read: "Read", archived: "Archived" } as Record<string, string>, markRead: "Mark as read", archive: "Archive", reply: "Reply by email" },
  notFound: "Page not found",
};

export type Dict = typeof en;

const tr: Dict = {
  appName: "Mock GPS Yönetim",
  common: { save: "Kaydet", cancel: "Vazgeç", delete: "Sil", edit: "Düzenle", create: "Oluştur", retry: "Tekrar dene", loading: "Yükleniyor…", search: "Ara", all: "Tümü", yes: "Evet", no: "Hayır", close: "Kapat", saved: "Kaydedildi", deleted: "Silindi", confirm: "Emin misin?", previous: "Önceki", next: "Sonraki", pageOf: "Sayfa {page} / {pages}", total: "Toplam {count}", actions: "İşlemler", empty: "Henüz kayıt yok.", noMatch: "Filtrelere uyan sonuç yok." },
  nav: { dashboard: "Panel", users: "Kullanıcılar", admins: "Yöneticiler", roles: "Roller ve yetkiler", settings: "Sistem ayarları", versions: "Uygulama sürümleri", announcements: "Duyurular", audit: "Denetim kaydı", messages: "Mesajlar", signOut: "Çıkış yap", language: "English" },
  theme: { system: "Tema: sistem", light: "Tema: açık", dark: "Tema: koyu" },
  login: { title: "Yönetim paneline giriş", subtitle: "Yalnızca yönetici rolüne sahip hesaplar devam edebilir.", email: "E-posta", password: "Şifre", submit: "Giriş yap", invalid: "E-posta veya şifre hatalı.", noAccess: "Bu hesabın yönetici yetkisi yok.", disabled: "Bu hesap devre dışı bırakıldı.", configMissing: "Yönetim paneli yapılandırılmamış. Eksik: {keys}" },
  errors: { network: "API'ye ulaşılamıyor. Çalıştığını kontrol et.", forbidden: "Bu işlem için yetkin yok.", generic: "Bir şeyler ters gitti. Lütfen tekrar dene.", notFound: "Bulunamadı." },
  dashboard: { title: "Panel", totalUsers: "Toplam kullanıcı", newToday: "Bugün yeni", active24h: "Aktif (24 sa)", active30d: "Aktif (30 gün)", inactive: "Devre dışı hesaplar", simulations: "Simülasyon", simulationsToday: "Bugünkü simülasyon", favorites: "Kayıtlı favori", routes: "Kayıtlı rota", newMessages: "Yeni mesaj", chart: "Etkinlik", metrics: { new_users: "Yeni kullanıcı", active_users: "Aktif kullanıcı", simulations: "Simülasyon" }, daily: "Günlük (30 gün)", monthly: "Aylık (12 ay)", features: "Özellik kullanımı (30 gün)", health: "Sistem durumu", healthy: "Sağlıklı", degraded: "Sorunlu", unhealthy: "Erişilemiyor", uptime: "Çalışma süresi", maintenance: "Bakım modu AÇIK", events: { simulation_started: "Simülasyon başlatıldı", simulation_stopped: "Simülasyon durduruldu", route_started: "Rota başlatıldı", favorite_activated: "Favori etkinleştirildi", search_used: "Arama kullanıldı", gpx_exported: "GPX dışa aktarıldı", app_opened: "Uygulama açıldı" } },
  users: { title: "Kullanıcılar", searchHint: "E-posta veya ad ara", status: "Durum", active: "Aktif", disabled: "Devre dışı", role: "Rol", email: "E-posta", name: "Ad", roles: "Roller", created: "Kayıt", lastSeen: "Son görülme", never: "Hiç", detail: "Kullanıcı detayı", stats: "Kullanım", favorites: "Favoriler", categories: "Kategoriler", routes: "Rotalar", cloudHistory: "Bulut geçmiş kaydı", simulationsTotal: "Simülasyon (toplam)", simulations30d: "Simülasyon (30 gün)", lastActivity: "Son etkinlik", language: "Dil", cloudSync: "Bulut geçmiş eşitleme", deactivate: "Hesabı devre dışı bırak", activate: "Hesabı etkinleştir", reason: "Gerekçe (isteğe bağlı, denetim kaydına yazılır)", deactivateConfirm: "Kullanıcının oturumu kapanır ve yeniden etkinleştirilene kadar giriş yapamaz.", editRoles: "Rolleri düzenle", rolesSaved: "Roller güncellendi", statusSaved: "Durum güncellendi", events: "Türe göre olaylar" },
  roles: { title: "Roller ve yetkiler", name: "Ad", description: "Açıklama", permissions: "Yetkiler", members: "Üye", system: "Sistem rolü", new: "Yeni rol", deleteConfirm: "\"{name}\" rolü silinsin mi? Üyeleri bu yetkileri kaybeder.", perms: { "dashboard.read": "Paneli görüntüleme", "users.read": "Kullanıcıları görüntüleme", "users.manage": "Kullanıcıyı etkinleştirme / devre dışı bırakma", "roles.manage": "Rol ve yetki yönetimi", "settings.manage": "Sistem ayarlarını değiştirme", "versions.manage": "Uygulama sürümlerini yönetme", "announcements.manage": "Duyuruları yönetme", "audit.read": "Denetim kaydını görüntüleme", "messages.manage": "İletişim mesajlarını yönetme" } },
  settings: { title: "Sistem ayarları", keys: { maintenance_mode: "Bakım modu", geocoding_enabled: "Adres arama", history_max_cloud_items: "Kullanıcı başına en fazla bulut geçmiş kaydı", support_email: "Destek e-postası" }, updated: "Son değişiklik", on: "Açık", off: "Kapalı" },
  versions: { title: "Uygulama sürümleri", platform: "Platform", version: "Sürüm", build: "Derleme", minBuild: "Desteklenen en eski derleme", minBuildHint: "Daha eski derlemeler güncellemeye zorlanır.", url: "İndirme bağlantısı", notes: "Sürüm notları", published: "Yayında", draft: "Taslak", publish: "Yayımla", upload: "APK yükle", uploading: "Yükleniyor…", size: "Boyut", new: "Yeni sürüm", deleteConfirm: "{version} ({build}) sürümü silinsin mi?" },
  announcements: { title: "Duyurular", new: "Yeni duyuru", titleField: "Başlık", body: "Mesaj", level: "Seviye", audience: "Hedef", starts: "Başlangıç", ends: "Bitiş (isteğe bağlı)", active: "Aktif", levels: { info: "Bilgi", warning: "Uyarı", critical: "Kritik" }, audiences: { all: "Herkes", android: "Android", ios: "iOS", web: "Web" }, deleteConfirm: "Bu duyuru silinsin mi?" },
  audit: { title: "Denetim kaydı", time: "Zaman", actor: "Yapan", action: "İşlem", entity: "Kayıt türü", description: "Açıklama", from: "Başlangıç", to: "Bitiş", deletedUser: "Silinmiş kullanıcı", system: "Sistem" },
  messages: { title: "İletişim mesajları", from: "Gönderen", subject: "Konu", received: "Alındı", status: "Durum", statuses: { new: "Yeni", read: "Okundu", archived: "Arşivlendi" }, markRead: "Okundu işaretle", archive: "Arşivle", reply: "E-postayla yanıtla" },
  notFound: "Sayfa bulunamadı",
};

export type Lang = "en" | "tr";
export const dictionaries: Record<Lang, Dict> = { en, tr };

const KEY = "mockgps.admin.lang";
const I18nContext = createContext<{ lang: Lang; t: Dict; setLang: (l: Lang) => void }>({ lang: "en", t: en, setLang: () => {} });

function initialLang(): Lang {
  try {
    const saved = localStorage.getItem(KEY);
    if (saved === "tr" || saved === "en") return saved;
  } catch {
    /* ignore */
  }
  return navigator.language.toLowerCase().startsWith("tr") ? "tr" : "en";
}

export function I18nProvider({ children, lang: forced }: { children: ReactNode; lang?: Lang }) {
  const [lang, setLangState] = useState<Lang>(forced ?? initialLang);
  const setLang = (l: Lang) => {
    setLangState(l);
    document.documentElement.lang = l;
    try {
      localStorage.setItem(KEY, l);
    } catch {
      /* ignore */
    }
  };
  return <I18nContext.Provider value={{ lang, t: dictionaries[lang], setLang }}>{children}</I18nContext.Provider>;
}

export const useI18n = () => useContext(I18nContext);

export function format(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, k: string) => String(values[k] ?? ""));
}

export function formatDate(value: string | null | undefined, lang: Lang, withTime = true): string {
  if (!value) return "—";
  const d = new Date(value);
  return new Intl.DateTimeFormat(lang === "tr" ? "tr-TR" : "en-GB", withTime ? { dateStyle: "medium", timeStyle: "short" } : { dateStyle: "medium" }).format(d);
}

export function formatNumber(n: number, lang: Lang): string {
  return new Intl.NumberFormat(lang === "tr" ? "tr-TR" : "en-GB").format(n);
}
