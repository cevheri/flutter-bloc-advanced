# Mimari Geçiş Dokümantasyonu

**Layered Architecture → Feature-First Clean Boundaries**

Bu doküman, projenin katmanlı (layered) mimariden feature-first clean boundaries mimarisine geçiş sürecini detaylı olarak anlatır.

---

## 1. Neden Geçiş Yapıldı?

### Eski Mimarinin Problemleri

- **Yatay bağımlılıklar:** Tüm BLoC'lar `presentation/common_blocs/` altında, tüm modeller `data/models/` altında toplandığı için ilgisiz dosyalar yan yana duruyordu. Bir feature'ı anlamak için proje genelinde dosya aramak gerekiyordu.
- **Belirsiz sınırlar:** `data/repository/login_repository.dart` ile `presentation/screen/login/bloc/login_bloc.dart` arasındaki ilişki sadece import'lardan anlaşılıyordu. Mimari düzeyde zorunlu bir sınır yoktu.
- **Ölçeklenemezlik:** Yeni bir feature eklemek 5+ farklı dizinde dosya oluşturmayı gerektiriyordu.
- **Test izolasyonu zorluğu:** Bir feature'ı bağımsız test etmek neredeyse imkansızdı çünkü bağımlılıklar katmanlar arasında dağınıktı.
- **Ölü kod birikimi:** Kullanılmayan City, District ve Customer modülleri fark edilmeden birikmişti.

### Yeni Mimarinin Faydaları

- **Feature izolasyonu:** Her feature kendi data, domain, application, presentation ve navigation katmanlarını barındırır.
- **Açık bağımlılık yönü:** `core` ← `infrastructure` ← `shared` ← `features` ← `app` şeklinde tek yönlü bağımlılık.
- **Kolay onboarding:** Yeni geliştirici sadece ilgili feature dizinine bakarak tüm bağlamı anlayabilir.
- **Bağımsız test:** Her feature kendi use case'leri ve repository arayüzleriyle izole test edilebilir.

---

## 2. Eski Mimari (Layered Architecture)

```
lib/
├── configuration/              # Environment, logging, storage, constants
│   ├── environment.dart
│   ├── app_logger.dart
│   ├── local_storage.dart
│   ├── app_key_constants.dart
│   ├── constants.dart
│   └── allowed_paths.dart
│
├── data/
│   ├── models/                 # Tüm data modelleri bir arada
│   │   ├── user.dart
│   │   ├── jwt_token.dart
│   │   ├── menu.dart
│   │   ├── authority.dart
│   │   ├── dashboard_model.dart
│   │   ├── change_password.dart
│   │   ├── city.dart           # (ölü kod)
│   │   ├── district.dart       # (ölü kod)
│   │   ├── customer.dart       # (ölü kod)
│   │   └── ...
│   ├── repository/             # Tüm repository'ler bir arada
│   │   ├── login_repository.dart
│   │   ├── account_repository.dart
│   │   ├── user_repository.dart
│   │   ├── authority_repository.dart
│   │   ├── dashboard_repository.dart
│   │   ├── menu_repository.dart
│   │   ├── city_repository.dart    # (ölü kod)
│   │   ├── district_repository.dart # (ölü kod)
│   │   └── customer_repository.dart # (ölü kod)
│   ├── http_utils.dart
│   └── app_api_exception.dart
│
├── presentation/
│   ├── common_blocs/           # Global BLoC'lar
│   │   ├── account/
│   │   ├── authority/
│   │   ├── theme/
│   │   ├── sidebar/
│   │   ├── city/               # (ölü kod)
│   │   └── district/           # (ölü kod)
│   ├── common_widgets/         # Paylaşılan widget'lar
│   │   ├── drawer/
│   │   ├── language_notifier.dart
│   │   ├── top_actions_widget.dart
│   │   └── web_back_button_disabler.dart
│   ├── design_system/          # Tema, token, component'ler
│   │   ├── theme/
│   │   ├── tokens/
│   │   └── components/
│   ├── screen/                 # Feature ekranları
│   │   ├── login/bloc/ + login_screen.dart
│   │   ├── register/bloc/ + register_screen.dart
│   │   ├── forgot_password/bloc/ + forgot_password_screen.dart
│   │   ├── change_password/bloc/ + change_password_screen.dart
│   │   ├── account/account_screen.dart
│   │   ├── dashboard/bloc/ + dashboard_page.dart
│   │   ├── user/bloc/ + editor/ + list/
│   │   ├── settings/bloc/ + settings_screen.dart
│   │   ├── catalog/catalog_screen.dart
│   │   ├── home/               # (ölü kod)
│   │   ├── customer/           # (ölü kod)
│   │   └── components/         # Paylaşılan form widget'ları
│   └── shell/                  # App shell (sidebar, top bar, bottom nav)
│
├── routes/
│   ├── app_routes_constants.dart
│   ├── app_router.dart
│   └── go_router_routes/
│       ├── app_go_router_config.dart
│       └── routes/
│
└── utils/
    ├── security_utils.dart
    ├── icon_utils.dart
    ├── app_constants.dart
    ├── menu_list_cache.dart
    ├── message.dart            # (ölü kod)
    └── storage.dart            # (ölü kod)
```

### Eski Mimaride Dosya Dağılımı

| Dizin | Sorumluluk |
|-------|------------|
| `configuration/` | Environment, logging, storage |
| `data/models/` | Tüm data modelleri (feature farkı yok) |
| `data/repository/` | Tüm repository implementasyonları |
| `presentation/common_blocs/` | Uygulama geneli BLoC'lar |
| `presentation/screen/<feature>/` | Feature-spesifik BLoC + UI |
| `presentation/design_system/` | Tema ve UI token'ları |
| `routes/` | Router yapılandırması |
| `utils/` | Yardımcı fonksiyonlar |

---

## 3. Yeni Mimari (Feature-First Clean Boundaries)

```
lib/
├── app/                        # Composition root (35 dosya)
│   ├── bootstrap/              # Uygulama başlatma
│   │   ├── app_bootstrap.dart
│   │   ├── app_bootstrap_config.dart
│   │   └── app_session_listeners.dart
│   ├── di/                     # Dependency injection
│   │   ├── app_dependencies.dart
│   │   └── app_scope.dart
│   ├── localization/
│   │   └── language_notifier.dart
│   ├── router/                 # Router kompozisyonu
│   │   ├── app_router.dart             # AppRouterFactory
│   │   ├── app_router_strategy.dart    # AppRouter strategy pattern
│   │   ├── app_router_refresh_notifier.dart
│   │   ├── app_go_router_config.dart
│   │   └── app_routes_constants.dart
│   ├── session/
│   │   └── session_cubit.dart
│   ├── shell/                  # App shell bileşenleri
│   │   ├── app_shell.dart
│   │   ├── responsive_scaffold.dart
│   │   ├── content_area.dart
│   │   ├── sidebar/            # Sidebar widget + BLoC
│   │   ├── top_bar/            # Top bar + breadcrumb
│   │   ├── bottom_nav/         # Bottom navigation
│   │   ├── command_palette/    # Ctrl+K command palette
│   │   ├── drawer/             # Drawer BLoC
│   │   ├── models/menu.dart
│   │   ├── repositories/menu_repository.dart
│   │   └── menu_list_cache.dart
│   ├── theme/                  # Theme BLoC
│   └── app.dart
│
├── core/                       # Cross-cutting primitives (5 dosya)
│   ├── errors/
│   │   └── app_api_exception.dart
│   ├── logging/
│   │   └── app_logger.dart
│   ├── security/
│   │   ├── allowed_paths.dart
│   │   └── security_utils.dart
│   └── testing/
│       └── app_key_constants.dart
│
├── features/                   # Business capabilities (93 dosya)
│   ├── account/    (14 dosya)
│   │   ├── application/        # AccountBloc + use cases
│   │   ├── data/models/        # ChangePassword
│   │   ├── data/repositories/  # AccountRepository impl
│   │   ├── domain/repositories/ # IAccountRepository
│   │   ├── navigation/         # AccountFeatureRoutes
│   │   └── presentation/pages/ # AccountPage
│   │
│   ├── auth/       (30 dosya)
│   │   ├── application/        # LoginBloc, RegisterBloc, ForgotPasswordBloc, ChangePasswordBloc + use cases
│   │   ├── data/models/        # JWTToken, UserJwt, SendOtpRequest, VerifyOtpRequest
│   │   ├── data/mappers/       # AuthMapper
│   │   ├── data/repositories/  # LoginRepository (AuthRepositoryImpl)
│   │   ├── domain/entities/    # AuthEntity
│   │   ├── domain/repositories/ # IAuthRepository
│   │   ├── navigation/         # AuthFeatureRoutes
│   │   └── presentation/pages/ # LoginPage, RegisterPage, ForgotPasswordPage, ChangePasswordPage
│   │
│   ├── catalog/    (3 dosya)
│   │   ├── navigation/         # CatalogFeatureRoutes
│   │   └── presentation/pages/ # CatalogScreen
│   │
│   ├── dashboard/  (12 dosya)
│   │   ├── application/        # DashboardCubit + use cases
│   │   ├── data/models/        # DashboardModel
│   │   ├── data/mappers/       # DashboardMapper
│   │   ├── data/repositories/  # DashboardMockRepository
│   │   ├── domain/entities/    # DashboardEntity
│   │   ├── domain/repositories/ # IDashboardRepository
│   │   ├── navigation/         # DashboardFeatureRoutes
│   │   └── presentation/pages/ # DashboardPage, DashboardHomePage
│   │
│   ├── settings/   (10 dosya)
│   │   ├── application/        # SettingsBloc + use cases
│   │   ├── navigation/         # SettingsFeatureRoutes
│   │   └── presentation/pages/ # SettingsPage, SettingsScreen
│   │
│   └── users/      (24 dosya)
│       ├── application/        # UserBloc, AuthorityBloc + use cases
│       ├── data/models/        # User, Authority, UserModel
│       ├── data/mappers/       # UserMapper
│       ├── data/repositories/  # UserRepository, AuthorityRepository
│       ├── domain/repositories/ # IUserRepository
│       ├── navigation/         # UsersFeatureRoutes
│       └── presentation/       # UserListPage, UserEditorPage + widgets
│
├── infrastructure/             # External adapters (4 dosya)
│   ├── config/
│   │   ├── environment.dart
│   │   └── constants.dart
│   ├── http/
│   │   └── http_utils.dart
│   └── storage/
│       └── local_storage.dart
│
├── shared/                     # Business-free reusable UI (40 dosya)
│   ├── design_system/
│   │   ├── components/         # 14 composable component (AppButton, AppCard, ...)
│   │   ├── theme/              # AppTheme, SemanticColors, ThemeColors
│   │   └── tokens/             # Spacing, breakpoints, durations, sizes, ...
│   ├── models/
│   │   └── user_entity.dart
│   ├── utils/
│   │   ├── app_constants.dart
│   │   └── icon_utils.dart
│   └── widgets/                # Paylaşılan widget'lar
│       ├── confirmation_dialog_widget.dart
│       ├── responsive_form_widget.dart
│       ├── submit_button_widget.dart
│       ├── theme_selection_dialog.dart
│       ├── language_selection_dialog.dart
│       ├── editor_form_mode.dart
│       ├── user_form_fields.dart
│       ├── web_back_button_disabler.dart
│       └── widgets.dart
│
├── generated/                  # Otomatik oluşturulan lokalizasyon (dokunulmadı)
├── l10n/                       # ARB dosyaları (dokunulmadı)
└── main/                       # Entry point'ler (dokunulmadı)
    ├── app.dart
    ├── main_local.dart
    └── main_prod.dart
```

### Yeni Mimaride Dosya Dağılımı

| Dizin | Dosya Sayısı | Sorumluluk |
|-------|-------------|------------|
| `app/` | 35 | Composition root, DI, router, shell, theme, session |
| `core/` | 5 | Hatalar, logging, security, test sabitleri |
| `features/` | 93 | 6 feature modülü (account, auth, catalog, dashboard, settings, users) |
| `infrastructure/` | 4 | HTTP, environment, storage |
| `shared/` | 40 | Design system, paylaşılan widget ve utility'ler |
| `main/` | 5 | Entry point'ler |
| **Toplam** | **182** | |

---

## 4. Bağımlılık Kuralları

```
app  ────→  features, shared, infrastructure, core
features ──→  shared, infrastructure, core
shared  ───→  core
infrastructure → core

Yasaklanan yönler:
  shared  ──✗──→  features
  core    ──✗──→  shared, features
  feature_a ─✗──→  feature_b/presentation veya feature_b/data
```

Bu kurallar geçiş sonrasında doğrulanmıştır:
- `lib/shared/` dizininde `features/` import'u **yok**
- `lib/core/` dizininde `shared/` veya `features/` import'u **yok**

---

## 5. Feature Yapısı

Her feature aşağıdaki standart yapıyı izler:

```
features/<feature>/
├── application/          # BLoC/Cubit + use case orchestration
│   ├── <feature>_bloc.dart
│   ├── <feature>_event.dart
│   ├── <feature>_state.dart
│   └── usecases/
│       └── <action>_usecase.dart
├── data/
│   ├── models/           # Data modelleri (fromJson/toJson)
│   ├── mappers/          # Entity ↔ Model dönüşümleri
│   └── repositories/     # Repository implementasyonları
├── domain/
│   ├── entities/         # Domain entity'leri (Flutter-free)
│   └── repositories/     # Repository arayüzleri (abstract class)
├── navigation/           # Feature route tanımları
│   └── <feature>_routes.dart
└── presentation/
    ├── pages/            # Ekranlar
    └── widgets/          # Feature-local widget'lar
```

### Use Case Pattern

BLoC'lar artık doğrudan repository'ye bağımlı değil, use case'ler üzerinden çalışır:

```dart
// Eski: BLoC → Repository
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;
  LoginBloc({required this.repository});
}

// Yeni: BLoC → UseCase → Repository Interface
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetAccountUseCase getAccountUseCase,
  });
}
```

---

## 6. Geçiş Adımları

### Adım 1: Ölü Kod Temizliği

Kullanılmayan modüller tamamen silindi:

| Silinen Modül | Dosya Sayısı | Neden |
|---------------|-------------|-------|
| City BLoC + Model + Repository | 6 | Hiçbir yerde kullanılmıyor |
| District BLoC + Model + Repository | 6 | Hiçbir yerde kullanılmıyor |
| Customer Screen + BLoC + Model + Repository | 11 | Boş BLoC, ekranlar kullanılmıyor |
| Home Screen | 1 | 0 import |
| `utils/message.dart` | 1 | 0 import |
| `utils/storage.dart` | 1 | Tamamen comment'lenmiş kod |
| `top_actions_widget.dart` | 1 | 0 import, dead code |
| `drawer_widget.dart` | 1 | 0 import, dead code |
| Mock JSON dosyaları | 5 | Silinen modüllere ait |
| İlgili test dosyaları | 11 | Silinen modüllere ait |
| **Toplam** | **~44** | |

### Adım 2: Design System Konsolidasyonu

27 dosya `presentation/design_system/` → `shared/design_system/` altına taşındı:

- **Components:** 14 composable component + barrel export
- **Theme:** AppTheme, AppThemePalette, SemanticColors, ThemeColors
- **Tokens:** AppSpacing, AppBreakpoints, AppDurations, AppSizes, AppRadius, AppElevation, AppTypography

Tüm import'lar (~30 dosya) doğrudan güncellendi, eski dizin tamamen silindi.

### Adım 3: LoginBloc ve Auth Repository Taşıma

- `LoginBloc` constructor'ı use case tabanlı DI'ye dönüştürüldü (repository doğrudan inject yerine use case'ler üzerinden)
- `LoginRepository` → `features/auth/data/repositories/auth_repository_impl.dart`
- Auth modelleri (JWTToken, UserJwt, SendOtpRequest, VerifyOtpRequest) → `features/auth/data/models/`

### Adım 4: Kalan Data Katmanı Taşıması

| Kaynak | Hedef |
|--------|-------|
| `data/models/menu.dart` | `app/shell/models/menu.dart` |
| `data/repository/menu_repository.dart` | `app/shell/repositories/menu_repository.dart` |
| `utils/menu_list_cache.dart` | `app/shell/menu_list_cache.dart` |
| `data/models/dashboard_model.dart` | `features/dashboard/data/models/` |
| `data/repository/dashboard_repository.dart` | `features/dashboard/data/repositories/` |
| `data/models/authority.dart` | `features/users/data/models/` |
| `data/repository/authority_repository.dart` | `features/users/data/repositories/` |
| `data/http_utils.dart` | `infrastructure/http/http_utils.dart` |
| `data/app_api_exception.dart` | `core/errors/app_api_exception.dart` |
| `data/models/change_password.dart` | `features/account/data/models/` |
| `data/models/user.dart` | `features/users/data/models/` |

### Adım 5: Cross-Feature Import Düzeltmeleri

`features/users/presentation/widgets/` altındaki `user_form_fields.dart` ve `editor_form_mode.dart` dosyaları birden fazla feature tarafından kullanıldığı için `shared/widgets/` altına taşındı. Bu, feature sınırlarını temiz tutar.

### Adım 6: Configuration ve Utils Taşıması

| Kaynak | Hedef |
|--------|-------|
| `configuration/environment.dart` | `infrastructure/config/environment.dart` |
| `configuration/local_storage.dart` | `infrastructure/storage/local_storage.dart` |
| `configuration/app_logger.dart` | `core/logging/app_logger.dart` |
| `configuration/app_key_constants.dart` | `core/testing/app_key_constants.dart` |
| `configuration/constants.dart` | `infrastructure/config/constants.dart` |
| `configuration/allowed_paths.dart` | `core/security/allowed_paths.dart` |
| `utils/security_utils.dart` | `core/security/security_utils.dart` |
| `utils/icon_utils.dart` | `shared/utils/icon_utils.dart` |
| `utils/app_constants.dart` | `shared/utils/app_constants.dart` |

### Adım 7: Shell, Router ve Shim Temizliği

**Shell bileşenleri:** `presentation/shell/` altındaki tüm widget'lar (sidebar, top bar, breadcrumb, bottom nav, command palette, content area) `app/shell/` altına taşındı.

**Router konsolidasyonu:** `routes/` dizini `app/router/` altına entegre edildi:
- `app_routes_constants.dart` → `app/router/app_routes_constants.dart`
- `app_router.dart` (strategy pattern) → `app/router/app_router_strategy.dart`
- `app_go_router_config.dart` → `app/router/app_go_router_config.dart`
- Feature-specific route dosyaları zaten `features/*/navigation/` altındaydı

**Reverse shim düzeltmeleri:** ForgotPasswordBloc, RegisterBloc, ChangePasswordBloc ve DashboardCubit implementasyonları eski konumlarından `features/` altına taşındı.

**Shim temizliği:** Tüm re-export shim dosyaları (toplam ~70) silindi ve eski dizinler kaldırıldı. Test dosyalarındaki import'lar da kanonik yollara güncellendi.

---

## 7. Silinen Eski Dizinler

Geçiş tamamlandıktan sonra aşağıdaki dizinler tamamen kaldırıldı:

| Dizin | Açıklama |
|-------|----------|
| `lib/presentation/` | Tamamı `features/`, `app/`, `shared/` altına taşındı |
| `lib/data/` | Modeller ve repository'ler ilgili feature'lara taşındı |
| `lib/configuration/` | `infrastructure/` ve `core/` altına dağıtıldı |
| `lib/utils/` | `shared/utils/` ve `core/security/` altına dağıtıldı |
| `lib/routes/` | `app/router/` altına entegre edildi |

---

## 8. Geçiş Stratejisi: Re-Export Shim Pattern

Geçiş süresince **incremental migration** stratejisi uygulandı:

1. Implementasyon yeni konumuna kopyalandı (import'lar kanonik yollara güncellenerek)
2. Eski dosya `export 'yeni_konum.dart';` şeklinde re-export shim'e dönüştürüldü
3. Mevcut tüm import'lar shim sayesinde çalışmaya devam etti
4. Tüm import'lar kanonik yollara güncellendikten sonra shim dosyaları silindi

Bu strateji, büyük bir codebase'de sıfır kesinti ile geçiş yapılmasını sağladı. Her adım sonrası `dart analyze` ve `flutter test` ile doğrulama yapıldı.

---

## 9. Doğrulama Sonuçları

| Kontrol | Sonuç |
|---------|-------|
| `fvm dart analyze` | 0 issue |
| `fvm flutter test` | +407 -9 (9 hata geçiş öncesinden mevcut, mock tip uyumsuzlukları) |
| `shared/` → `features/` import kontrolü | 0 ihlal |
| `core/` → `shared/` veya `features/` import kontrolü | 0 ihlal |

---

## 10. Öncesi / Sonrası Karşılaştırma

### Dizin Yapısı

| Öncesi | Sonrası |
|--------|---------|
| `lib/configuration/` (6 dosya) | `lib/core/` (5 dosya) + `lib/infrastructure/` (4 dosya) |
| `lib/data/` (models + repos, ~20 dosya) | Her feature kendi `data/` dizinine sahip |
| `lib/presentation/common_blocs/` (8+ bloc) | `lib/app/theme/` + `lib/app/shell/` + `lib/features/*/application/` |
| `lib/presentation/screen/` (tüm feature UI'ları) | `lib/features/*/presentation/pages/` |
| `lib/presentation/design_system/` (27 dosya) | `lib/shared/design_system/` (27 dosya) |
| `lib/presentation/shell/` (8 widget) | `lib/app/shell/` (tam shell ekosistemi) |
| `lib/routes/` (9 dosya) | `lib/app/router/` (5 dosya) + `lib/features/*/navigation/` |
| `lib/utils/` (6 dosya) | `lib/shared/utils/` + `lib/core/security/` |

### BLoC Yapısı

| Öncesi | Sonrası |
|--------|---------|
| `presentation/common_blocs/account/` | `features/account/application/account_bloc.dart` |
| `presentation/common_blocs/authority/` | `features/users/application/authority_bloc.dart` |
| `presentation/common_blocs/theme/` | `app/theme/theme_bloc.dart` |
| `presentation/common_blocs/sidebar/` | `app/shell/sidebar/sidebar_bloc.dart` |
| `presentation/screen/login/bloc/` | `features/auth/application/login_bloc.dart` |
| `presentation/screen/register/bloc/` | `features/auth/application/register_bloc.dart` |
| `presentation/screen/dashboard/bloc/` | `features/dashboard/application/dashboard_cubit.dart` |
| `presentation/screen/user/bloc/` | `features/users/application/user_bloc.dart` |
| `presentation/screen/settings/bloc/` | `features/settings/application/settings_bloc.dart` |

### Repository Yapısı

| Öncesi | Sonrası |
|--------|---------|
| `data/repository/login_repository.dart` | `features/auth/data/repositories/auth_repository_impl.dart` |
| `data/repository/account_repository.dart` | `features/account/data/repositories/account_repository.dart` |
| `data/repository/user_repository.dart` | `features/users/data/repositories/user_repository.dart` |
| `data/repository/authority_repository.dart` | `features/users/data/repositories/authority_repository.dart` |
| `data/repository/dashboard_repository.dart` | `features/dashboard/data/repositories/dashboard_mock_repository.dart` |
| `data/repository/menu_repository.dart` | `app/shell/repositories/menu_repository.dart` |

---

## 11. Yeni Feature Ekleme Rehberi

Yeni bir feature eklemek için:

```bash
# 1. Feature dizin yapısını oluştur
mkdir -p lib/features/<feature>/{application/usecases,data/{models,mappers,repositories},domain/{entities,repositories},navigation,presentation/{pages,widgets}}

# 2. Domain katmanı (entity + repository arayüzü)
# lib/features/<feature>/domain/entities/<feature>_entity.dart
# lib/features/<feature>/domain/repositories/<feature>_repository.dart

# 3. Data katmanı (model + mapper + repository impl)
# lib/features/<feature>/data/models/<feature>_model.dart
# lib/features/<feature>/data/mappers/<feature>_mapper.dart
# lib/features/<feature>/data/repositories/<feature>_repository_impl.dart

# 4. Application katmanı (use case + BLoC)
# lib/features/<feature>/application/usecases/<action>_usecase.dart
# lib/features/<feature>/application/<feature>_bloc.dart

# 5. Presentation katmanı
# lib/features/<feature>/presentation/pages/<feature>_page.dart

# 6. Navigation
# lib/features/<feature>/navigation/<feature>_routes.dart

# 7. DI kaydı: lib/app/di/app_dependencies.dart ve app_scope.dart
# 8. Router entegrasyonu: lib/app/router/app_router.dart
# 9. Route sabiti: lib/app/router/app_routes_constants.dart
# 10. Testler: test/features/<feature>/
```

---

## 12. Referanslar

- [Feature-First Clean Boundaries Tasarım Dokümanı](feature-first-clean-boundaries.md)
- [Flutter BLoC Kütüphanesi](https://bloclibrary.dev/)
- [go_router Paketi](https://pub.dev/packages/go_router)
