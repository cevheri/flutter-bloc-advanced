# Flutter BLoC Advance Template — Yeni Özellik Önerileri

## Bağlam

Bu proje ciddi bir modernizasyondan geçti: feature-first clean architecture, 14+ design system bileşeni, 472 test, CI/CD pipeline'ları, mock data sistemi, responsive shell ve kapsamlı altyapı (Dio HTTP client, interceptor chain, JWT auth, session management, theme system, localization). Şimdi sıra, template'i kullanan geliştiricilerin "tak çalıştır" deneyimiyle production-ready uygulamalar üretebilmesini sağlayacak bir sonraki nesil özelliklerde.

Öneriler iki katmanda sunulmaktadır:

- **Katman 1 (Öneri 1-5):** Her production uygulamanın ihtiyaç duyduğu temel altyapı özellikleri
- **Katman 2 (Öneri 6-10):** Geliştiricilerin "WOW" diyeceği, hiçbir Flutter template'inde olmayan yaratıcı özellikler

---

# KATMAN 1: Production Altyapı Temelleri

---

## Öneri 1: Feature Scaffolding CLI (Kod Üreteci)

### Problem
Yeni bir feature eklemek şu anda 10-15 dosyayı 5 dizin altında manuel oluşturmayı, isimlendirme kurallarını takip etmeyi, route/DI/mock kaydı yapmayı ve test boilerplate'i yazmayı gerektiriyor. Bu hem yavaş hem hata yapmaya açık, hem de mimariyi bilmeyenlerin yanlış yapı oluşturmasına neden oluyor.

### Çözüm
`tool/generate_feature.dart` — tek komutla komple feature iskeleti üreten Dart script:

```bash
dart run tool/generate_feature.dart orders
```

**Üretilen yapı:**
```
lib/features/orders/
  application/
    orders_bloc.dart / orders_event.dart / orders_state.dart
    usecases/ (list, get, create, update, delete)
  data/
    models/order_model.dart
    repositories/orders_repository_impl.dart
  domain/
    entities/order_entity.dart
    repositories/orders_repository.dart (abstract interface)
  navigation/orders_routes.dart
  presentation/
    pages/orders_list_page.dart, order_editor_page.dart
    widgets/order_form_fields.dart

test/features/orders/
  application/orders_bloc_test.dart
  data/{models,repositories}/
  presentation/pages/

assets/mock/
  GET_orders.json, GET_orders_pathParams.json, POST_orders.json, PUT_orders.json
```

**Konsol çıktısı:** Route, DI ve localization kayıtları için adım adım rehber.

### Neden 1 Numara?
Bu, template'in "referans mimari"den "geliştirme hızlandırıcı"ya dönüşmesini sağlayan çarpan etkisi. Her sonraki feature dakikalar içinde üretilir. Mimari kuralları zorla doğru uygular. Yanlış yapı oluşturma riski sıfıra iner.

### Efor: ~3-4 gün | Karmaşıklık: Orta

---

## Öneri 2: Token Refresh ve Güvenli Oturum Yönetimi

### Problem
JWT token `SharedPreferences`'da (plaintext) saklanıyor. `SecurityUtils.isTokenExpired()` kapatılmış durumda (`//TODO`). Refresh token mekanizması yok. Eş zamanlı 401'lerde race condition riski var.

### Çözüm
- **Güvenli depolama:** `ISecureStorage` + `FlutterSecureStorageAdapter`
- **Token refresh interceptor:** `QueuedInterceptor` pattern — 401'de tek refresh, diğer istekler kuyrukta
- **Auth genişletme:** `AuthTokenEntity`'ye `refreshToken` + `expiresAt`, `SecurityUtils.isTokenExpired()` aktivasyonu
- **Hata durumu:** Refresh başarısız → `SessionCubit.markLoggedOut()` → login redirect

### Efor: ~4-5 gün | Karmaşıklık: Orta-Yüksek

---

## Öneri 3: Connectivity Monitoring ve Offline Farkındalığı

### Problem
Offline durumda 30 sn timeout sonrası generic hata. Proaktif bilgi yok.

### Çözüm
- **`ConnectivityService`:** `connectivity_plus` + HTTP ping doğrulama
- **`ConnectivityInterceptor`:** Chain'in başına, anında `ConnectivityError`
- **`ConnectivityCubit`:** Global cubit + animasyonlu offline/online banner in `AppShell`

### Efor: ~3-4 gün | Karmaşıklık: Orta

---

## Öneri 4: Analytics ve Crash Reporting Altyapısı

### Problem
`AppLogger` sadece konsola yazıyor. Production observability sıfır. BLoC/route enstrümantasyonu yok.

### Çözüm
- **`IAnalyticsService`:** Abstract interface (core layer)
- **`LogAnalyticsService`:** Varsayılan — `AppLogger`'a yazar, SDK gerektirmez
- **`AnalyticsBlocObserver`:** Otomatik BLoC transition logging
- **`AnalyticsRouteObserver`:** Otomatik ekran geçişi tracking
- **Crash reporting:** `FlutterError.onError` + `PlatformDispatcher.instance.onError`
- Firebase'e geçiş = 1 interface + 1 DI kaydı

### Efor: ~2-3 gün | Karmaşıklık: Düşük-Orta

---

## Öneri 5: Repository Cache Katmanı ve Offline Data

### Problem
Offline'da tüm liste ekranları hata gösteriyor. Daha önce yüklenen veri bile korunmuyor.

### Çözüm
- **`ICacheStorage`** + **`HiveCacheStorage`** implementasyonu
- **`CachePolicy`** enum: `networkFirst`, `cacheFirst`, `networkOnly`, `cacheOnly`
- **`CacheInterceptor`:** Başarılı yanıtları saklar, offline'da cached data döndürür
- Opt-in: `apiClient.get('/dashboard', cachePolicy: CachePolicy.networkFirst)`

### Efor: ~3-4 gün | Karmaşıklık: Orta

---

# KATMAN 2: "WOW" Efekti Yaratan Yaratıcı Özellikler

> Hiçbir Flutter template'inde olmayan, bir geliştiricinin repo'yu klonlayıp çalıştırdığı anda "bunu daha önce hiç görmemiştim" diyeceği 5 özellik.

---

## Öneri 6: In-App Developer Console (DevPanel)

### "WOW" Faktörü
Browser DevTools'u Flutter uygulamasının içine gömmek. Hiçbir Flutter template'inde yok. Telefonu sallayarak veya `Ctrl+Shift+D` ile açılan, uygulamanın iç dünyasını gösteren bir diagnostic panel.

### Ne Yapıyor?

**Erişim:**
- Mobile: Shake gesture (`sensors_plus`)
- Desktop/Web: `Ctrl+Shift+D` (mevcut `CommandPaletteShortcut` pattern'i takip eder)
- Sadece debug build'de görünür (`kDebugMode` guard)

**4 Tab:**

| Tab | İçerik | Teknik |
|-----|--------|--------|
| **Network Inspector** | Her HTTP request/response: method, URL, status, timing, headers, body | Yeni `DevConsoleInterceptor` — interceptor chain'e 4. sırada eklenir, in-memory ring buffer |
| **BLoC State Inspector** | Canlı timeline: `UserBloc: initial → loading → searchSuccess` | Custom `BlocObserver`, her transition'ı kaydeder. Tıkla → full state detayı |
| **Storage Inspector** | Tüm `SharedPreferences` key/value'ları (JWT masked) | Mevcut `AppLocalStorage` + `StorageKeys` enum'u okur. Debug'da key silme |
| **Environment & Routes** | Aktif environment, tüm GoRouter route'ları, navigasyon geçmişi | Mevcut `ProfileConstants` + `GoRouter` introspection |

### Mimari Uyum
- `lib/core/dev_console/` — core katmanında, feature bağımsız
- Interceptor: mevcut `AuthInterceptor`, `MockInterceptor`, `LoggingInterceptor` pattern'ini birebir takip eder
- BlocObserver: `AppBootstrap.run()` seviyesinde entegre
- Overlay: `CommandPaletteShortcut` ile aynı pattern (shortcut widget + dialog)
- `kDebugMode` guard → production'da sıfır overhead

### Demo Anı
Geliştirici repo'yu klonlar, `fvm flutter run` çalıştırır, login olur, Users sayfasına gider. **Ctrl+Shift+D** basar. Alttan sleek bir panel açılır: MockInterceptor'ün serve ettiği her network request, app start'tan beri her BLoC state değişikliği, tüm storage değerleri, route ağacı. **Bir daha asla `print` debug yapmak zorunda kalmayacağını anlar.**

### Efor: ~4-5 gün | Karmaşıklık: Orta

---

## Öneri 7: State Time-Travel Debugging

### "WOW" Faktörü
Redux DevTools'un Flutter BLoC dünyasına taşınması. State geçmişinde ileri-geri gidebilmek, her transition'ın diff'ini görmek, ve bir state sequence'ı "replay" edebilmek. **Hiçbir Flutter BLoC template'inde olmayan** devrimsel bir özellik.

### Ne Yapıyor?

**State Recording:**
- `TimeTravelBlocObserver` — her BLoC için ring buffer (max 100 entry)
- Her `StateSnapshot`: timestamp, BLoC tipi, trigger event, önceki state, yeni state
- `Equatable.props` üzerinden serialization (tüm state'ler zaten `Equatable` extend ediyor)

**Time-Travel Controls (DevConsole'un bir tab'ı):**
- **Timeline:** Tüm BLoC'lar arası state değişikliklerinin dikey zaman çizelgesi, BLoC tipine göre filtrelenebilir
- **State Diff:** Herhangi bir snapshot'a tıkla → before/after diff (git diff gibi ama state için)
- **Rewind:** Önceki bir state'e geri sar → BLoC o state'i emit eder, UI anında güncellenir
- **Replay:** State geçişlerini otomatik oynat (ayarlanabilir hız), animasyon gibi izle
- **Export:** Timeline'ı JSON olarak dışa aktar → bug report'lara ekle

### Mimari Uyum
- `lib/core/dev_console/time_travel/` — DevConsole'un alt modülü
- Mevcut BLoC kodunda **HİÇBİR DEĞİŞİKLİK GEREKMİYOR** — observer framework seviyesinde hook'lanır
- `Equatable` + `copyWith()` pattern'i zaten var → mutation sorunu yok
- `kDebugMode` guard → production'da sıfır overhead

### Demo Anı
Users sayfasında arama yapılır, DevConsole açılır. Güzel bir timeline'da `UserBloc: initial → loading → searchSuccess` görünür. `loading` state'e tıklanır — diff viewer tam olarak neyin değiştiğini gösterir. "Rewind to initial" basılır — Users sayfası başlangıç state'ine döner. "Replay" basılır — arama, loading ve sonuçlar otomatik olarak animate eder. **State debugging bir sanat formuna dönüşür.**

### Efor: ~3-4 gün | Karmaşıklık: Orta (DevConsole'dan sonra)

---

## Öneri 8: Smart Retry + Circuit Breaker Pattern

### "WOW" Faktörü
Microservice dünyasından (Netflix Hystrix) alınan self-healing network pattern'i. **Hiçbir Flutter HTTP client'ında** implement edilmemiş. Uygulama otomatik olarak iyileşir, cascade failure'ları önler, ve geliştiriciye tek satır kod yazdırmaz.

### Ne Yapıyor?

**Automatic Retry + Exponential Backoff:**
- Geçici hatalar (timeout, 502, 503, connection error) → otomatik retry (max 3)
- Backoff: 200ms → 400ms → 800ms + jitter
- `Retry-After` header'ı respect edilir
- Non-retryable (400, 401, 403, 404, 422) → anında pass-through

**Circuit Breaker (endpoint başına):**
```
  [CLOSED] ──5 ardışık hata──→ [OPEN] ──30sn cooldown──→ [HALF-OPEN]
     ↑                           │                            │
     │                     anında fail                   1 probe request
     │                    (network'e gitmez)                   │
     └────────────başarılı──────────────────────────başarılı───┘
                                                         │
                                                    başarısız → [OPEN]
```

- Her endpoint (`/admin/users`, `/dashboard`) kendi circuit breaker'ına sahip
- **Open** durumda istekler anında fail olur (30sn timeout yerine ~0ms)
- **Half-Open** durumda tek probe request ile test edilir

**Health Dashboard (DevConsole entegrasyonu):**
- Hangi endpoint'ler sağlıklı (yeşil), yarı-açık (sarı), veya fail (kırmızı) → görsel monitoring

### Mimari Uyum
- `lib/infrastructure/http/interceptors/resilience_interceptor.dart` — mevcut interceptor pattern
- `lib/infrastructure/http/circuit_breaker.dart` — pure Dart state machine, fully testable
- Chain: `[AuthInterceptor → ResilienceInterceptor → MockInterceptor → LoggingInterceptor]`
- Mevcut `AppError` hierarchy (`NetworkError`, `TimeoutError`, `ServerError`) doğal mapping

### Demo Anı
Production modda test sunucusuna bağlı çalışırken sunucu kapatılır. İlk istek 3 kez retry eder — animasyonlu "Retrying..." toast görünür (`AppToast` kullanılır). 5 ardışık hatadan sonra Users endpoint'in circuit'i açılır. Sonraki "Users" tıklamalarında **anında** "Servis geçici olarak kullanılamıyor, 30sn sonra otomatik deneme" mesajı çıkar (30sn timeout yerine). Sunucu geri geldiğinde circuit otomatik kapanır. **Uygulama kendi kendini iyileştirir.**

### Efor: ~3-4 gün | Karmaşıklık: Orta

---

## Öneri 9: App Lifecycle Manager (Force Update, Maintenance Mode, Feature Flags)

### "WOW" Faktörü
Server-driven uygulama yaşam döngüsü. Template'i klonlayan geliştirici, bir JSON dosyasını değiştirerek force update ekranı, maintenance modu ve feature flag'ler görebilir. Production'dan düşünülmüş bir template olduğunu ilk 5 dakikada anlar.

### Ne Yapıyor?

**3 Sütun:**

| Özellik | Nasıl Çalışır | Tetikleyici |
|---------|--------------|-------------|
| **Force Update** | `AppConstants.appVersion` vs remote `minimumVersion` karşılaştırması | Bootstrap'ta + periyodik check |
| **Maintenance Mode** | Remote config'de `maintenanceMode: true` → full-screen maintenance ekranı | Bootstrap'ta + periyodik check |
| **Feature Flags** | `FeatureFlagService` — runtime toggle, local cache + TTL | DI üzerinden tüm feature'lara erişim |

**Force Update akışı:**
1. `AppBootstrap.run()` → `GET /app/config` (mock: `assets/mock/GET_app_config.json`)
2. `currentVersion < minimumVersion` → non-dismissable `ForceUpdateScreen` (store linki ile)
3. Mevcut design system: `AppButton`, `AppCard`, `SemanticColors`

**Maintenance Mode:**
- `maintenanceMode: true` → `MaintenanceScreen` (tahmini dönüş süresi + refresh butonu)
- Mevcut `AppErrorState` pattern'i üzerine inşa

**Feature Flags:**
- Mevcut `TemplateConfig.socialLoginEnabled` / `multiTenancyEnabled` → compile-time'dan **runtime** toggle'a geçiş
- `AppLocalStorage`'da cache + TTL ile offline çalışma
- Sidebar'da `featureFlags.isEnabled('feature_x')` kontrolü

### Mimari Uyum
- Yeni feature: `lib/features/lifecycle/` (standart feature yapısı)
- Mock data: `assets/mock/GET_app_config.json` (mevcut naming convention)
- `LifecycleBloc` → `AppScope`'ta register, `AppRouterFactory.redirect()`'te check
- `FeatureFlagService` → `core/feature_flags/` (core layer, reusable)

### Demo Anı
Geliştirici mock JSON'da `"maintenanceMode": true` yapar → hot restart → profesyonel maintenance ekranı. `"minimumVersion": "99.0.0"` yapar → force update ekranı. `"featureFlags": {"beta_chat": true}` ekler → sidebar'da yeni item belirir. **Template'in production-first düşünüldüğünü 5 dakikada anlar.**

### Efor: ~3-4 gün | Karmaşıklık: Orta

---

## Öneri 10: Server-Driven Dynamic Forms Engine

### "WOW" Faktörü
Backend'den gelen JSON şemasını çalışan, validasyonlu, temalı bir forma dönüştüren rendering engine. Airbnb (Lona), Shopify (Hydrogen), Netflix ve Uber'in kullandığı pattern. **Hiçbir Flutter template'inde yok.** App store güncellemesi olmadan form değişikliği yapabilmek.

### Ne Yapıyor?

**JSON Schema → Rendered Form:**
```json
{
  "id": "create_lead",
  "title": "New Lead",
  "fields": [
    {"type": "text", "key": "name", "label": "Full Name", "required": true, "validators": ["minLength:2"]},
    {"type": "email", "key": "email", "label": "Email Address", "required": true},
    {"type": "dropdown", "key": "source", "label": "Lead Source", "options": ["Web", "Referral", "Cold Call"]},
    {"type": "date", "key": "followUp", "label": "Follow-up Date"},
    {"type": "toggle", "key": "priority", "label": "High Priority", "default": false}
  ],
  "submitAction": {"method": "POST", "endpoint": "/leads"},
  "layout": "responsive"
}
```

**Desteklenen field tipleri (18):** text, email, password, number, phone, textarea, dropdown, multi-select, date, datetime, toggle, checkbox, radio, file, slider, color picker, section header, divider

**Özellikler:**
- Mevcut design system bileşenleri kullanılır (`AppInput`, `AppButton`, `AppForm`, `AppCard`)
- `form_builder_validators` ile tam validasyon (zaten dependency'de var)
- `AppResponsiveBuilder` / `AppAdaptiveGrid` ile responsive layout
- `DynamicFormBloc` — standart Event → BLoC → State pattern
- Submit → `ApiClient.post()` ile schema'daki endpoint'e

### Mimari Uyum
- Yeni feature: `lib/features/dynamic_forms/`
  - `data/models/form_schema.dart`, `domain/entities/form_schema_entity.dart`
  - `application/dynamic_form_bloc.dart`
  - `presentation/widgets/dynamic_form_renderer.dart` (~200 satır — mevcut bileşenleri compose eder)
  - `presentation/widgets/field_renderers/` — tip başına widget
- Mock: `assets/mock/GET_dynamic_forms_create_lead.json`
- `DynamicFormRenderer` aynı zamanda `shared/widgets/`'e export → her feature kullanabilir
- Sidebar'da "Dynamic Forms" demo route'u

### Demo Anı
Developer sidebar'dan "Dynamic Forms" sekmesine girer. JSON'dan render edilmiş profesyonel bir form görür. Mock JSON dosyasını değiştirir — yeni field'lar, farklı validasyon, farklı layout. Hot restart sonrası form tamamen değişir. **App store güncellemesi olmadan form değiştirebileceğini anlar.** Sonra `dynamic_form_renderer.dart`'a bakar — sadece ~200 satır, çünkü her şey mevcut design system bileşenlerini compose ediyor. **Mimarinin gerçek gücünü o an kavrar.**

### Efor: ~5-6 gün | Karmaşıklık: Yüksek

---

# Genel Özet Tablosu

## Katman 1: Production Altyapı

| # | Öneri | Evrensellik | Sonradan Ekleme Maliyeti | Efor |
|---|-------|-------------|--------------------------|------|
| 1 | Feature Scaffolding CLI | Her template kullanıcısı | Düşük | 3-4 gün |
| 2 | Token Refresh + Secure Session | Her auth'lu uygulama | Çok yüksek | 4-5 gün |
| 3 | Connectivity Monitoring | Her mobil uygulama | Yüksek | 3-4 gün |
| 4 | Analytics + Crash Reporting | Her production uygulama | Orta | 2-3 gün |
| 5 | Repository Cache + Offline | Çoğu uygulama | Çok yüksek | 3-4 gün |

## Katman 2: WOW Özellikler

| # | Öneri | "WOW" Seviyesi | Demo Etkisi | Efor |
|---|-------|----------------|-------------|------|
| 6 | In-App Developer Console | Browser DevTools uygulamanın içinde | Ctrl+Shift+D → tüm iç dünya | 4-5 gün |
| 7 | State Time-Travel | Redux DevTools for BLoC | Rewind/Replay state geçişleri | 3-4 gün |
| 8 | Smart Retry + Circuit Breaker | Self-healing network | Sunucu kapatınca otomatik iyileşme | 3-4 gün |
| 9 | App Lifecycle Manager | Force update + maintenance + flags | JSON değiştir → maintenance ekranı | 3-4 gün |
| 10 | Dynamic Forms Engine | JSON → çalışan form | Mock JSON değiştir → form değişir | 5-6 gün |

**Toplam tahmini efor: ~35-43 gün (10 önerinin tamamı)**

---

# Kesinleşen Uygulama Sırası

> Kullanıcı tercihi: 10 önerinin tamamı uygulanacak. In-App DevConsole (#6) ilk sırada.

**Faz 1 — Developer Experience First (Hafta 1-2):**
1. **In-App Developer Console (#6)** — İlk başlanacak. Network Inspector, BLoC State Inspector, Storage Viewer, Route Tree. DevConsole altyapısı sonraki iki özelliğin temeli.
2. **State Time-Travel (#7)** — DevConsole'un tab'ı olarak eklenir. BlocObserver + rewind/replay UI.
3. **Feature Scaffolding CLI (#1)** — Sonraki tüm feature'ları hızlandıracak çarpan etkisi.

**Faz 2 — Network & Security (Hafta 3-4):**
4. **Token Refresh + Secure Session (#2)** — Güvenlik önceliği. QueuedInterceptor + SecureStorage.
5. **Smart Retry + Circuit Breaker (#8)** — DevConsole Health tab'ı ile entegre. Self-healing network.
6. **Connectivity Monitoring (#3)** — Circuit Breaker ile sinerjik. Offline banner + ConnectivityCubit.

**Faz 3 — Production Readiness (Hafta 5-6):**
7. **Analytics + Crash Reporting (#4)** — BlocObserver pattern'i DevConsole observer ile ortaklaşır.
8. **App Lifecycle Manager (#9)** — Force update, maintenance mode, runtime feature flags.
9. **Repository Cache + Offline Data (#5)** — Connectivity monitoring üzerine inşa. Hive cache + CachePolicy.

**Faz 4 — Innovation (Hafta 7):**
10. **Dynamic Forms Engine (#10)** — En yaratıcı, en impactful demo. JSON → çalışan form.

---

# Doğrulama Planı

Her özellik tamamlandığında:
1. `fvm dart analyze` — statik analiz temiz
2. `fvm dart format . --line-length=120` — format uyumlu
3. `fvm flutter test` — tüm mevcut 472+ test geçiyor
4. Yeni özellik için yazılan testler geçiyor
5. `test/architecture/import_guard_test.dart` — mimari sınır ihlali yok
6. `fvm flutter run --target lib/main/main_local.dart` — uygulama çalışıyor, özellik demo edilebilir
