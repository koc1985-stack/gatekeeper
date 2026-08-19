# Bekle — Impulse Buy Gatekeeper

Gece yarısı Trendyol/Amazon'da sepete attığın şeyleri düşünmeden almanı engelleyen bir iOS uygulaması. Bir şey almak istediğinde kaydedersin, uygulama bir soğuma süresi (varsayılan 24 saat) başlatır ve o süre boyunca ürünün fiyatının saatlik kazancına göre kaç saatlik çalışmana denk geldiğini gösterir. Süre bitince bildirim gelir, "Aldım" ya da "Vazgeçtim" dersin; vazgeçtiklerin biriktirdiğin para/zaman olarak istatistiklerde birikir.

Bu proje **Windows üzerinde, kod düzeyinde tamamen yazıldı** ama iOS uygulamaları yalnızca **macOS + Xcode** üzerinde derlenip çalıştırılabildiği için, aşağıdaki adımları bir Mac'te tamamlaman gerekiyor. Kodun kendisi eksiksiz; eksik olan tek şey gerçek bir derleme/çalıştırma doğrulaması.

## Teknoloji

- SwiftUI, iOS 17+
- SwiftData + CloudKit (`.automatic`) — ayrı bir backend/hesap sistemi yok, veriler kullanıcının iCloud hesabıyla otomatik senkronize olur ve yedeklenir
- StoreKit 2 — Premium abonelik/ömür boyu satın alma, `Configuration.storekit` ile Simulator'da test edilebilir
- UserNotifications — soğuma süresi bitince yerel bildirim, bildirim üzerinden doğrudan "Aldım"/"Vazgeçtim" aksiyonu
- Localizable.xcstrings — Türkçe (ana dil) + İngilizce

## Kurulum (Mac üzerinde, tek seferlik)

1. [Xcode](https://apps.apple.com/app/xcode/id497799835) 15 veya üzerini App Store'dan kur.
2. [Homebrew](https://brew.sh) kuruluysa, [XcodeGen](https://github.com/yonaskolb/XcodeGen) kur:
   ```bash
   brew install xcodegen
   ```
3. Bu klasörde `.xcodeproj` dosyasını üret:
   ```bash
   cd Impulse_Buy_Gatekeeper
   xcodegen generate
   ```
4. `ImpulseGatekeeper.xcodeproj` dosyasını Xcode ile aç.
5. Proje ayarlarında **Signing & Capabilities** sekmesinde kendi Apple Developer **Team**'ini seç. `project.yml` içindeki `PRODUCT_BUNDLE_IDENTIFIER` (`com.impulsegatekeeper.app`) ve iCloud container ID'si (`iCloud.com.impulsegatekeeper.app`) placeholder — kendi bundle ID'ni kullanmak istersen `project.yml`'de değiştirip `xcodegen generate`'i tekrar çalıştır.
6. İlk derlemede Xcode, iCloud (CloudKit) container'ını senin Developer hesabında otomatik oluşturacak; "Signing & Capabilities" altında iCloud/CloudKit servisinin işaretli olduğunu doğrula.
7. Bir Simulator seç (örn. iPhone 15) ve **Product ▸ Run** (⌘R).

## StoreKit (Premium) test etme

`Resources/Configuration.storekit` dosyası aylık/yıllık abonelik ve ömür boyu ürünleri tanımlar (`project.yml` bu dosyayı çalıştırma şemasına zaten bağlıyor). Eğer Xcode dosyayı açarken şikayet ederse (JSON'u elle, Xcode olmadan yazdım, format küçük bir detayda farklı olabilir):

- Xcode'da **File ▸ New ▸ File ▸ StoreKit Configuration File** ile yeni bir dosya oluştur, `Resources/Configuration.storekit`'in yerine koy.
- Şu üç product ID'yi aynen ekle (kod bunlara göre çalışıyor — `Sources/Services/StoreService.swift`):
  - `com.impulsegatekeeper.premium.monthly` (Auto-Renewable Subscription)
  - `com.impulsegatekeeper.premium.yearly` (Auto-Renewable Subscription)
  - `com.impulsegatekeeper.premium.lifetime` (Non-Consumable)
- **Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration** altından bu dosyayı seçili olduğundan emin ol.

Gerçek App Store Connect ürünlerini (fiyat, deneme süresi vb.) kendi hesabından oluşturup aynı ID'lerle eşleştirdiğinde canlıya geçebilirsin — App Store Connect'e benim erişimim yok.

## Mac'siz test: GitHub Actions + Sideloadly

Mac'in yoksa `.github/workflows/build-ios.yml`, her `workflow_dispatch` tetiklemesinde (GitHub reposu → **Actions** sekmesi → "Build iOS IPA (unsigned, for Sideloadly)" → **Run workflow**) imzasız bir `.ipa` üretir ve Actions çalışmasının **Artifacts** bölümüne yükler — Kozmika/Yıldız Haritası projesinde kullandığın yöntemin aynısı.

1. Bu repoyu GitHub'a push et (repo yoksa önce github.com'da boş bir repo aç).
2. GitHub'da **Actions** sekmesine gir, "Build iOS IPA" workflow'unu seç, **Run workflow** ile tetikle.
3. Çalışma bitince **ImpulseGatekeeper-ipa** artifact'ini indir, zip'i aç (`ImpulseGatekeeper.ipa` çıkar).
4. Windows'a [Sideloadly](https://sideloadly.io) kur (kuruluysa atla).
5. iPhone'u USB ile bağla, Sideloadly'de cihazı seç, `.ipa` dosyasını sürükle.
6. Apple ID'ni gir → Sideloadly kendi imzalayıp telefona yükler.
7. iPhone'da **Ayarlar → Genel → VPN ve Cihaz Yönetimi** kısmından geliştirici profiline güvenmen gerekebilir (ilk açılışta telefon uyarır).

Not: Uygulama SwiftData+CloudKit ve StoreKit kullanıyor — iCloud senkronu ve Premium satın alma testinin düzgün çalışması için Sideloadly'e girdiğin Apple ID'nin **Apple Developer Program'a kayıtlı** (ücretli) hesabın olması gerekiyor; sadece ücretsiz bir Apple ID ile iCloud container'ları imzalanamayabilir. Kozmika'da kullandığın hesap zaten bu programa kayıtlı görünüyor, aynısını kullanabilirsin.

Ücretsiz Apple ID ile imzalanan uygulamalar **7 günde bir** yeniden imzalanmalı; ücretli Developer Program hesabıyla imzalarsan bu süre 1 yıla çıkar. Süre dolarsa Sideloadly'de aynı `.ipa`'yı tekrar sürükleyip tekrar yükleyerek yenileyebilirsin.

## Bilinen eksikler / sıradaki adımlar

- **App Icon**: `Resources/Assets.xcassets/AppIcon.appiconset` şu an boş bir placeholder. 1024×1024 bir görsel ekleyip Xcode'a sürükle-bırak yapman gerekiyor (Nim/ürettiğin başka bir görsel de olur).
- **İngilizce çeviri**: `Localizable.xcstrings` en görünür ~70 metni (başlıklar, butonlar, ana ekranlar) çevirdi. Saat/dakika gibi dinamik olarak üretilen bazı ifadeler (`WageCalculator.formattedHours`) şu an sadece Türkçe — İngilizce arayüzde de Türkçe görünürler, hata vermezler. Xcode'da dosyayı açıp String Catalog editöründen tamamlayabilirsin.
- **Çoklu para birimi**: İstatistikler tek bir para biriminde toplanıyor (Ayarlar'daki para birimi); farklı para birimleriyle eklenen ürünler varsa toplam yanıltıcı olur. MVP kapsamında basit tutuldu.
- Kapsam dışı bırakılanlar: Safari Extension, ana ekran widget'ı, Apple Watch uygulaması, ayrı bir sunucu/API, gerçek analitik.

## Proje yapısı

```
Sources/
  App/                  — @main giriş noktası, ModelContainer + CloudKit kurulumu
  Root/                 — Sekme çubuğu, onboarding kapısı, bildirimden gelen derin bağlantılar
  Models/               — PurchaseItem, UserSettings (SwiftData)
  Services/             — NotificationService, StoreService, WageCalculator, CurrencyFormatter
  Features/
    Onboarding/          Home/            AddItem/         Decision/
    History/              Stats/           Settings/         Paywall/
    Shared/               — FeatureRow, StatCard gibi ortak bileşenler
Resources/
  Localizable.xcstrings, Assets.xcassets, Configuration.storekit
```

Bir derleme hatası alırsan, hata mesajını buraya yapıştır — birlikte düzeltelim.
