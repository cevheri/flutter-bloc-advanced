## Repo scan - Dashboard baseline

- App entry points: `lib/main/main_local.dart` (dev), `lib/main/main_prod.dart` (prod)
- Theming: `AdaptiveTheme` in `lib/main/app.dart` with light/dark; `MaterialApp.router` built via `AppGoRouterConfig.routeBuilder`
- Routing: `go_router`, initial route `ApplicationRoutesConstants.home` provided by `HomeRoutes` → `HomeScreen`
- BLoC: Provided at root in `App` for `LoginBloc`, `AuthorityBloc`, `AccountBloc`, `DrawerBloc`
- Home: `HomeScreen` loads `AccountBloc` and shows `Scaffold` with `AppBar` and application drawer
- Mocking: `Environment` dev/test use `HttpUtils.mockRequest`; mock JSON files under `assets/mock/`
- L10n: `flutter_intl` with `S` delegates
- Tests: 500+ widget/bloc tests green locally

### Baseline commands

```
flutter pub get
flutter analyze
flutter test
```

All tests passed locally; analyze shows only a few deprecation infos in `app_router.dart`.

### Dashboard plan impact

- Add dashboard data model and mock repository under `lib/data/`
- Add `DashboardCubit` under `lib/presentation/screen/dashboard/`
- Add `DashboardPage` UI composed of: header, summary cards, recent activities, quick actions
- Wire into `HomeScreen` body only for `Environment.dev` to avoid breaking existing flows/tests


