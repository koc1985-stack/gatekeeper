# Bekle — Impulse Buy Gatekeeper

Gece yarısı Trendyol/Amazon'da sepete attığın şeyleri düşünmeden almanı engelleyen bir iOS uygulaması. Bir şey almak istediğinde kaydedersin, uygulama bir soğuma süresi (varsayılan 24 saat) başlatır ve o süre boyunca ürünün fiyatının saatlik kazancına göre kaç saatlik çalışmana denk geldiğini gösterir. Süre bitince bildirim gelir, "Aldım" ya da "Vazgeçtim" dersin; vazgeçtiklerin biriktirdiğin para/zaman olarak istatistiklerde birikir.

Bu proje **Windows üzerinde, kod düzeyinde tamamen yazıldı** ama iOS uygulamaları yalnızca **macOS + Xcode** üzerinde derlenip çalıştırılabildiği için, aşağıdaki adımları bir Mac'te tamamlaman gerekiyor. Kodun kendisi eksiksiz; eksik olan tek şey gerçek bir derleme/çalıştırma doğrulaması.

## Teknoloji

- SwiftUI, iOS 17+
- SwiftData + CloudKit (`.automatic`) — ayrı bir backend/hesap sistemi yok, veriler kullanıcının iCloud hesabıyla otomatik senkronize olur ve yedeklenir
- StoreKit 2 — Premium abonelik/ömür boyu satın alma, `Configuration.storekit` ile Simulator'da test edilebilir
- UserNotifications — soğuma süresi bitince yerel bildirim, bildirim üzerinden doğrudan "Aldım"/"Vazgeçtim" aksiyonu
- Safari Web Extension (MV3) + WidgetKit — App Group üzerinden ana uygulamayla aynı SwiftData deposunu paylaşan iki ek hedef (bkz. "v2" bölümü)
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

## v2: Safari Uzantısı, Widget, Gece Kuşu Kilidi, Duygusal Check-in

Ana uygulamanın yanına iki yeni Xcode hedefi eklendi: **GatekeeperExtension** (Trendyol/Amazon/Zara/H&M ödeme sayfalarında devreye giren Safari Web Extension) ve **GatekeeperWidgetExtension** (ana ekran + kilit ekranı "Bu Ay Kurtarılan ₺" widget'ı). Üçü de aynı SwiftData deposunu **App Group** (`group.com.impulsegatekeeper.app`) üzerinden paylaşıyor — extension'dan eklenen bir ürün doğrudan ana uygulamanın Bekleme Listesi'nde görünür.

**Sideloadly ile test ederken önemli:** App Group'lu (paylaşımlı container gerektiren) uygulamalar `xcodegen generate` sonrası Xcode'da **Signing & Capabilities**'te App Group'un işaretli/oluşturulmuş olmasını ister; Team'i seçtikten sonra Xcode bunu genelde otomatik halleder, ama ilk derlemede bir uyarı görürsen "Ayarlar → Apple ID → App Groups" ile ilgili bir provisioning sorunu olabilir — bana hatayı yapıştır.

**Safari uzantısını etkinleştirme** (uygulama içinde Ayarlar → "Safari Uzantısını Etkinleştir" ile aynı adımlar): Ayarlar → Safari → Uzantılar → "Bekle" → aç → tüm web siteleri için izin ver. Apple bir uygulamanın kendi uzantısını otomatik açmasına izin vermiyor, bu adım her zaman manuel.

**Dürüst bir uyarı — siteler test edilmedi:** `GatekeeperExtension/Resources/site-selectors.js` içindeki Trendyol/Amazon/Zara/H&M CSS seçicileri, gerçek siteleri açıp inceleyemediğim için (bu ortamda Mac/Safari/gerçek alışveriş oturumu yok) en iyi tahminimle yazıldı — siteler düzenini değiştirdikçe bayatlayabilirler. Seçici bir şey bulamazsa özellik **sessizce başarısız olmuyor**: genel ödeme-sayfası URL deseniyle yine devreye girer ve fiyatı elle girmeni ister. Gerçek cihazda hangi sitede ne olduğunu (veya Mac'e bağlayıp Safari Web Inspector konsol çıktısını) paylaşırsan seçicileri düzeltirim — Xcode build hatalarını düzelttiğimiz yöntemin aynısı.

**"Kilit" ne kadar gerçek?** Uzantı, ödeme butonuna tıklamayı yakalayıp üstüne bir uyarı ekranı bindiriyor ve soğuma süresi boyunca sayfaya her dönüşte tekrar beliriyor — ama One Sec/Opal/Freedom gibi uygulamalarla aynı kategoride: bir *caydırma katmanı*, teknik olarak kırılamaz bir kilit değil. Kullanıcı "Yine de devam et" diyerek geçebilir; amaç anlık dürtüyü kesmek.

- **Bildirimler**: Uzantı headless bir işlem olduğu için bildirim izni isteyemiyor — bunun yerine ana uygulama her ön plana geldiğinde (`RootView.reconcileNotifications`) bekleyen tüm ürünler için hatırlatmayı (yeniden) planlıyor; aynı ID ile tekrar planlamak zararsız, tekilleştiriliyor.
- **Yatırım oranları** (S&P 500 %10, Altın %7 yıllık): kabaca uzun vadeli tarihsel ortalamalar, uygulamada da uzantıda da "garanti değildir" notuyla gösteriliyor.

## Bilinen sorunlar

- **Widget şu an pakete gömülü değil.** İlk Sideloadly kurulumunda `GatekeeperWidgetExtension` süreci `CODESIGNING` / "Invalid Page" hatasıyla (kernel'in imzayı geçersiz sayıp anında öldürmesi) çöktü ve bu muhtemelen ana uygulamanın hiç açılmamasına neden oldu — iOS, ana uygulamayı çalıştırmadan önce içindeki tüm gömülü uzantıların imzasını da doğruluyor. Bu bir Swift hatası değil, Sideloadly'nin App Group'lu bir widget uzantısını yeniden imzalarken yaşadığı bir provisioning sorunu gibi görünüyor. Widget'ı `project.yml`'de geçici olarak `dependencies`'ten çıkardım (kod hâlâ orada, sadece pakete gömülmüyor) — Safari uzantısı gömülü kaldı, aynı sorunu yaşayıp yaşamadığını bu şekilde ayrı test edebiliriz. Widget'ı geri istediğinde: `project.yml`'de `GatekeeperWidgetExtension` satırındaki yorumu kaldır, `xcodegen generate` çalıştır.

## Bilinen eksikler / sıradaki adımlar

- **App Icon** ve **uzantı ikonu**: ikisi de placeholder/boş. 1024×1024 bir görsel + uzantı için küçük ikonlar eklemen gerekiyor.
- **İngilizce çeviri**: yeni v2 metinlerinin çoğu çevrildi ama gece modu saat metinleri gibi dinamik ifadeler yine sadece Türkçe (hata vermez, sadece İngilizce arayüzde de Türkçe görünür).
- **Çoklu para birimi**: İstatistikler tek bir para biriminde toplanıyor; farklı para birimleriyle eklenen ürünler varsa toplam yanıltıcı olur.
- Kapsam dışı: Apple Watch uygulaması, ayrı bir sunucu/API, gerçek analitik/A-B test altyapısı.

## Proje yapısı

```
Sources/                          — ana uygulama (App Group'lu paylaşımlı SwiftData deposu kullanır)
  App/, Root/, Models/, Services/, Features/ (Onboarding, Home, AddItem, Decision, History,
    Stats, Settings, Paywall, Shared — MoodPicker, NightChallengeView dahil)
GatekeeperExtension/               — Safari Web Extension
  SafariWebExtensionHandler.swift  — JS ↔ paylaşımlı SwiftData köprüsü
  Resources/                       — manifest.json, content.js, site-selectors.js, background.js
GatekeeperWidget/                  — WidgetKit hedefi (ana ekran + kilit ekranı)
Resources/
  Localizable.xcstrings, Assets.xcassets, Configuration.storekit
```

Bir derleme hatası alırsan, hata mesajını buraya yapıştır — birlikte düzeltelim.
