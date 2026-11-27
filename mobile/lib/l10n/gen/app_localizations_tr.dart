// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Mock GPS';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonDone => 'Tamam';

  @override
  String get commonSearch => 'Ara';

  @override
  String get commonOptional => 'İsteğe bağlı';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get commonUndo => 'Geri al';

  @override
  String get commonOpenSettings => 'Ayarları aç';

  @override
  String get navMap => 'Harita';

  @override
  String get navFavorites => 'Favoriler';

  @override
  String get navRoutes => 'Rotalar';

  @override
  String get navHistory => 'Geçmiş';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get authSignInTitle => 'Tekrar hoş geldin';

  @override
  String get authSignInSubtitle =>
      'Favorilerini ve rotalarını eşitlemek için giriş yap.';

  @override
  String get authSignUpTitle => 'Hesap oluştur';

  @override
  String get authSignUpSubtitle =>
      'Ücretsiz, reklamsız. Konum geçmişin varsayılan olarak sadece bu cihazda kalır.';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authDisplayName => 'Ad';

  @override
  String get authSignIn => 'Giriş yap';

  @override
  String get authSignUp => 'Hesap oluştur';

  @override
  String get authNoAccount => 'Hesabın yok mu? Oluştur';

  @override
  String get authHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get authForgotPassword => 'Şifreni mi unuttun?';

  @override
  String get authResetTitle => 'Şifre sıfırla';

  @override
  String get authResetSubtitle =>
      'Yeni şifre belirlemen için e-posta ile bağlantı göndereceğiz.';

  @override
  String get authSendResetLink => 'Bağlantı gönder';

  @override
  String get authResetSent =>
      'Bu e-postaya ait bir hesap varsa sıfırlama bağlantısı gönderildi.';

  @override
  String get authNewPasswordTitle => 'Yeni şifre belirle';

  @override
  String get authNewPassword => 'Yeni şifre';

  @override
  String get authPasswordUpdated => 'Şifre güncellendi.';

  @override
  String get authCheckEmailTitle => 'Gelen kutunu kontrol et';

  @override
  String authCheckEmailBody(String email) {
    return '$email adresine doğrulama bağlantısı gönderdik. Kaydı tamamlamak için bağlantıyı bu telefonda aç.';
  }

  @override
  String get authResendEmail => 'E-postayı tekrar gönder';

  @override
  String get authEmailResent => 'Doğrulama e-postası tekrar gönderildi.';

  @override
  String get authInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authPasswordRule => 'En az 8 karakter, harf ve rakam içermeli.';

  @override
  String get authInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authEmailNotConfirmed =>
      'Önce e-postanı doğrula. Gelen kutunu kontrol et.';

  @override
  String get authUserExists => 'Bu e-postayla kayıtlı bir hesap zaten var.';

  @override
  String get authRateLimited => 'Çok fazla deneme. Biraz bekle.';

  @override
  String get mapSearchHint => 'Adres veya yer ara';

  @override
  String get mapSelectedLocation => 'Seçili konum';

  @override
  String get mapTapToSelect => 'Konum seçmek için haritaya dokun';

  @override
  String get mapStart => 'Simülasyonu başlat';

  @override
  String get mapStop => 'Durdur';

  @override
  String get mapUpdate => 'Buraya taşı';

  @override
  String get mapPause => 'Duraklat';

  @override
  String get mapResume => 'Devam et';

  @override
  String get mapSaveFavorite => 'Kaydet';

  @override
  String get mapEnterCoordinates => 'Koordinat';

  @override
  String get mapMyLocation => 'Gerçek konumum';

  @override
  String get mapLocationServiceOff =>
      'Konum servisleri kapalı. Nerede olduğunu görmek için GPS\'i aç.';

  @override
  String get mapLocationPermissionDenied =>
      'Nerede olduğunu göstermek için konum izni gerekli.';

  @override
  String get mapLocationUnavailable =>
      'Konumun alınamadı. Açık alanda veya GPS açıkken tekrar dene.';

  @override
  String get mapLayers => 'Harita stili';

  @override
  String get mapSimulating => 'Simüle ediliyor';

  @override
  String get mapPaused => 'Duraklatıldı';

  @override
  String mapRouteProgress(int percent) {
    return 'Rota %$percent';
  }

  @override
  String get mapLookingUpAddress => 'Adres aranıyor…';

  @override
  String get mapNoAddress => 'Adres bulunamadı';

  @override
  String get mapNoResults => 'Yer bulunamadı';

  @override
  String get mapRecent => 'Son kullanılan';

  @override
  String get mapCopyCoordinates => 'Koordinatı kopyala';

  @override
  String get mapCopied => 'Koordinat kopyalandı';

  @override
  String get mapExportGpx => 'GPX dışa aktar';

  @override
  String get mapSetupNeeded => 'Simülasyon için kurulumu tamamla';

  @override
  String get mapSimulationStarted => 'Simülasyon başladı';

  @override
  String get mapAttribution => 'Harita verisi';

  @override
  String get coordsTitle => 'Koordinat gir';

  @override
  String get coordsLatitude => 'Enlem';

  @override
  String get coordsLongitude => 'Boylam';

  @override
  String get coordsPasteHint =>
      '\"41.0082, 28.9784\" biçimini iki alandan birine yapıştırabilirsin.';

  @override
  String get coordsInvalidLat => 'Enlem -90 ile 90 arasında olmalı.';

  @override
  String get coordsInvalidLng => 'Boylam -180 ile 180 arasında olmalı.';

  @override
  String get coordsGo => 'Haritada göster';

  @override
  String get mapStyleStandard => 'Standart';

  @override
  String get mapStyleMinimal => 'Sade';

  @override
  String get mapStyleDark => 'Koyu';

  @override
  String get mapStyleSatellite => 'Uydu';

  @override
  String get favoritesTitle => 'Favoriler';

  @override
  String get favoritesSearchHint => 'Favorilerde ara';

  @override
  String get favoritesAll => 'Tümü';

  @override
  String get favoritesEmptyTitle => 'Henüz favori yok';

  @override
  String get favoritesEmptyBody => 'Haritada bir yer seç ve Kaydet\'e dokun.';

  @override
  String get favoritesNoMatch => 'Aramana uyan favori yok.';

  @override
  String get favoritesActivate => 'Burayı simüle et';

  @override
  String get favoritesShowOnMap => 'Haritada göster';

  @override
  String get favoritesDeleted => 'Favori silindi';

  @override
  String get favoritesSaved => 'Favori kaydedildi';

  @override
  String get favoritesManageCategories => 'Kategoriler';

  @override
  String get favoriteEditTitle => 'Favori';

  @override
  String get favoriteName => 'Ad';

  @override
  String get favoriteDescription => 'Açıklama';

  @override
  String get favoriteCategory => 'Kategori';

  @override
  String get favoriteNoCategory => 'Kategorisiz';

  @override
  String get favoriteNameRequired => 'Bir ad gir.';

  @override
  String get categoriesTitle => 'Kategoriler';

  @override
  String get categoryNew => 'Yeni kategori';

  @override
  String get categoryName => 'Kategori adı';

  @override
  String categoryDeleteConfirm(String name) {
    return '\"$name\" silinsin mi? İçindeki favoriler kategorisiz olarak kalır.';
  }

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favori',
      one: '1 favori',
      zero: 'Favori yok',
    );
    return '$_temp0';
  }

  @override
  String get routesTitle => 'Rotalar';

  @override
  String get routesEmptyTitle => 'Kayıtlı rota yok';

  @override
  String get routesEmptyBody =>
      'Haritada noktalara dokunarak rota oluştur, sonra seçtiğin hızda oynat.';

  @override
  String get routesNew => 'Yeni rota';

  @override
  String get routeEditorTitle => 'Rota';

  @override
  String get routeEditorHint =>
      'Nokta eklemek için haritaya dokun. Son noktayı silmek için basılı tut.';

  @override
  String get routeName => 'Rota adı';

  @override
  String get routeSpeed => 'Hız';

  @override
  String routeSpeedValue(int speed) {
    return '$speed km/sa';
  }

  @override
  String get routeLoop => 'Döngü';

  @override
  String get routeLoopHint => 'Başlangıca dön ve tekrarla';

  @override
  String routePoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nokta',
      one: '1 nokta',
    );
    return '$_temp0';
  }

  @override
  String routeDistance(String km) {
    return '$km km';
  }

  @override
  String get routePlay => 'Rotayı oynat';

  @override
  String get routeUndoPoint => 'Son noktayı sil';

  @override
  String get routeClear => 'Temizle';

  @override
  String get routeNeedsPoints => 'En az iki nokta ekle.';

  @override
  String get routeSaved => 'Rota kaydedildi';

  @override
  String get routeDeleted => 'Rota silindi';

  @override
  String get routeStarted => 'Rota başladı';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historyEmptyTitle => 'Henüz geçmiş yok';

  @override
  String get historyEmptyBody => 'Simüle ettiğin konumlar burada görünür.';

  @override
  String get historyDisabledTitle => 'Geçmiş kapalı';

  @override
  String get historyDisabledBody =>
      'Simüle edilen konumları bu cihazda tutmak için Ayarlar\'dan aç.';

  @override
  String get historyClearAll => 'Tümünü temizle';

  @override
  String historyClearConfirm(String cloud) {
    String _temp0 = intl.Intl.selectLogic(cloud, {
      'true': ' ve buluttaki',
      'other': '',
    });
    return 'Bu cihazdaki$_temp0 tüm geçmiş silinsin mi?';
  }

  @override
  String get historyCleared => 'Geçmiş temizlendi';

  @override
  String get historyToday => 'Bugün';

  @override
  String get historyYesterday => 'Dün';

  @override
  String get historyLocalOnly => 'Sadece bu cihazda saklanır';

  @override
  String get historySynced => 'Hesabınla eşitleniyor';

  @override
  String get historyUse => 'Tekrar kullan';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsDefaultMap => 'Varsayılan harita stili';

  @override
  String get settingsSimulation => 'Simülasyon';

  @override
  String get settingsAccuracy => 'Bildirilen doğruluk';

  @override
  String settingsAccuracyValue(int meters) {
    return '$meters m';
  }

  @override
  String get settingsInterval => 'Güncelleme aralığı';

  @override
  String settingsIntervalValue(String seconds) {
    return '$seconds sn';
  }

  @override
  String get settingsJitter => 'Doğal sapma';

  @override
  String get settingsJitterHint =>
      'Doğruluk yarıçapı içinde küçük rastgele hareket ekler';

  @override
  String get settingsSetupGuide => 'Kurulum rehberi';

  @override
  String get settingsVerify => 'Simülasyonu kontrol et';

  @override
  String get settingsPrivacy => 'Gizlilik';

  @override
  String get settingsHistory => 'Konum geçmişini tut';

  @override
  String get settingsHistoryHint => 'Bu cihazda saklanır';

  @override
  String get settingsCloudSync => 'Geçmişi hesabımla eşitle';

  @override
  String get settingsCloudSyncHint => 'Kapatınca buluttaki kopya silinir';

  @override
  String get settingsNotifications => 'Duyurular';

  @override
  String get settingsNotificationsHint => 'Ürün duyurularını uygulamada göster';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsDisplayName => 'Ad';

  @override
  String get settingsExport => 'Verilerimi indir';

  @override
  String get settingsSignOut => 'Çıkış yap';

  @override
  String get settingsDeleteAccount => 'Hesabı sil';

  @override
  String get settingsDeleteConfirmTitle => 'Hesabın silinsin mi?';

  @override
  String get settingsDeleteConfirmBody =>
      'Profilin, favorilerin, rotaların ve buluttaki geçmişin kalıcı olarak silinir. Bu işlem geri alınamaz.';

  @override
  String get settingsDeleteConfirmType => 'Onaylamak için SİL yaz';

  @override
  String get settingsDeleteConfirmWord => 'SİL';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String settingsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get settingsPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get settingsTerms => 'Kullanım koşulları';

  @override
  String get settingsSaved => 'Ayarlar kaydedildi';

  @override
  String get setupTitle => 'Simülasyonu kur';

  @override
  String get setupIntro =>
      'Android test konumu sağlaması için tek bir uygulamaya izin verir. Bu adımlar yaklaşık bir dakika sürer, root gerekmez.';

  @override
  String get setupLocationPermission => 'Hassas konum iznini ver';

  @override
  String get setupLocationPermissionHint =>
      'Simülasyon servisini çalıştırmak için gerekli.';

  @override
  String get setupNotificationPermission => 'Bildirim izni ver';

  @override
  String get setupNotificationPermissionHint =>
      'Simülasyon sırasında Durdur butonlu bir bildirim gösterir.';

  @override
  String get setupDeveloperOptions => 'Geliştirici seçeneklerini aç';

  @override
  String get setupDeveloperOptionsHint =>
      'Ayarlar → Telefon hakkında → Yapım numarasına 7 kez dokun.';

  @override
  String get setupMockApp => 'Mock GPS\'i sahte konum uygulaması seç';

  @override
  String get setupMockAppHint =>
      'Geliştirici seçenekleri → Sahte konum uygulamasını seç → Mock GPS.';

  @override
  String get setupLocationOn => 'Cihaz konumunu aç';

  @override
  String get setupBattery => 'Arka planda çalışmaya izin ver';

  @override
  String get setupBatteryHint =>
      'Bazı telefonlarda simülasyonun durdurulmaması için önerilir.';

  @override
  String get setupGrant => 'İzin ver';

  @override
  String get setupOpen => 'Aç';

  @override
  String get setupAllDone => 'Her şey hazır. Simülasyonu başlatabilirsin.';

  @override
  String get setupDetectionNote =>
      'Android simüle konumları işaretler. Bazı uygulamalar (örneğin bankacılık uygulamaları ve bazı oyunlar) bunu algılayıp çalışmayabilir. Mock GPS bunu gizlemez.';

  @override
  String get setupIosTitle => 'iOS\'ta simülasyon';

  @override
  String get setupIosBody =>
      'iOS, uygulamaların diğer uygulamaların gördüğü konumu değiştirmesine izin vermez. GPX dışa aktar ile dosyayı al ve bağlı bir cihazda veya Simülatör\'de Xcode\'dan (Debug → Simulate Location) yükle.';

  @override
  String get verifyTitle => 'Simülasyonu kontrol et';

  @override
  String get verifyBody =>
      'Android\'in uygulamalara bildirdiği konumu okur ve simüle ettiğin noktayla karşılaştırır.';

  @override
  String get verifyReported => 'Android\'in bildirdiği';

  @override
  String get verifyExpected => 'Simüle edilen nokta';

  @override
  String get verifyDistance => 'Fark';

  @override
  String get verifyMocked => 'Sahte konum olarak işaretli';

  @override
  String get verifyOk => 'Çalışıyor: uygulamalar simüle konumu alıyor.';

  @override
  String get verifyMismatch => 'Uygulamalar hâlâ farklı bir konum alıyor.';

  @override
  String get verifyNotRunning => 'Önce bir simülasyon başlat.';

  @override
  String get verifyWaiting => 'Konum bekleniyor…';

  @override
  String get simErrorMockApp =>
      'Mock GPS sahte konum uygulaması olarak seçili değil. Kurulum rehberini aç.';

  @override
  String get simErrorForeground =>
      'Android simülasyonun başlamasına izin vermedi. Konum iznini kontrol et.';

  @override
  String get simErrorInvalidRoute => 'Bu rota oynatılamıyor.';

  @override
  String get simErrorGeneric => 'Simülasyon beklenmedik şekilde durdu.';

  @override
  String get errorNetwork =>
      'Bağlantı yok. İnternetini kontrol edip tekrar dene.';

  @override
  String get errorServer =>
      'Bizim tarafımızda bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get errorSessionExpired =>
      'Oturumun sona erdi. Lütfen tekrar giriş yap.';

  @override
  String get errorAccountDisabled =>
      'Bu hesap devre dışı bırakıldı. Yardım için destekle iletişime geç.';

  @override
  String get errorRateLimited => 'Çok fazla istek. Biraz bekle.';

  @override
  String get errorGeocodingDisabled =>
      'Adres arama geçici olarak kullanılamıyor.';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti.';

  @override
  String get maintenanceTitle => 'Bakımdayız';

  @override
  String get maintenanceBody =>
      'Hizmeti iyileştiriyoruz. Simülasyon çalışmaya devam eder; hesap özellikleri kısa süre içinde geri gelir.';

  @override
  String get updateRequiredTitle => 'Güncelleme gerekli';

  @override
  String get updateRequiredBody =>
      'Bu sürüm artık desteklenmiyor. Devam etmek için son sürümü yükle.';

  @override
  String get updateAvailable => 'Yeni bir sürüm var.';

  @override
  String get updateDownload => 'İndir';

  @override
  String get configMissingTitle => 'Uygulama yapılandırılmamış';

  @override
  String configMissingBody(String keys) {
    return 'Bu derlemede eksik: $keys';
  }
}
