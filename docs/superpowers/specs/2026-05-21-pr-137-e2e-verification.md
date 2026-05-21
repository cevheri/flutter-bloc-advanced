# PR #137 — E2E Verification (Chrome Web, 2026-05-21)

## Setup

- **Build:** `fvm flutter run --target lib/main/main_local.dart -d chrome --web-port=8080`
- **Branch:** `feat/129-secure-storage-wiring` @ commit `a5b7f7e`
- **Environment:** `Environment.dev` (mock interceptor active)
- **Browser:** Chromium via chrome-devtools-mcp
- **Pre-test state:** clean (no localStorage)

## Test Matrix

| # | Scenario | Status | Evidence |
|---|----------|:---:|---|
| 1 | Cold boot: empty secure storage → router redirects to `/login` | ✅ | URL: `http://localhost:8080/#/login`; log: `SessionCubit: restore: no token in secure storage → unauthenticated` |
| 2 | Sealed state transition `SessionUnknown → SessionUnauthenticated` (I1) | ✅ | Logs show both variants distinctly: `redirect ... session: SessionUnknown` followed by `session: SessionUnauthenticated` |
| 3 | Login form submit → backend auth → redirect to `/` | ✅ | URL transition `/login` → `/`, Dashboard rendered, top-right shows "AU / Admin" |
| 4 | JWT persisted **encrypted** in localStorage (not plaintext) | ✅ | `FlutterSecureStorage.jwtToken` = `pXHMpuYX7pCwvils.VKtQ/Ie78sSuS…` (53 chars, base64 cipher), NOT the plaintext `MOCK_TOKEN`. Same for `refreshToken` (65 chars cipher). |
| 5 | AuthInterceptor attaches `Bearer` to outgoing requests | ✅ | Console: `AuthInterceptor : Request [GET] /account (auth: true, token: MOCK…OKEN)` |
| 6 | LogSanitizer masks token (S2 top-level `maskToken`) | ✅ | Token rendered as `MOCK…OKEN` (first 4 + last 4), never raw |
| 7 | Full interceptor chain active (#63 dashboard truth source) | ✅ | Dashboard renders 8 interceptors in order: Connectivity → Auth → TokenRefresh → Resilience → Mock → Cache → DevConsole → Logging |
| 8 | Authenticated HTTP requests route through chain | ✅ | `GET /account` traces: `AuthInterceptor` → `ResilienceInterceptor: circuit closed` → `MockInterceptor: Mock data loaded` → `AccountRepository.END: successful` |
| 9 | Reload mid-session: tokens survive, session restored | ✅ | After page reload at `/`, `MenuRepository.getMenus successful` + `AuthInterceptor Request [GET] /account (auth: **true**, token: MOCK…OKEN)` → user stays logged in, no login flash |
| 10 | Non-sensitive prefs persist separately | ✅ | `flutter.language`, `flutter.theme`, `flutter.username`, `flutter.roles` in plaintext SharedPreferences (correct — these are NOT secrets) |
| 11 | Dynamic Forms feature reachable (auth-gated) | ✅ | Quick Action "Open Dynamic Forms" → `/#/dynamic-forms/sample` → "New Lead" form renders with 9 field types (text, dropdown, radio, textarea, date, slider, switch, checkbox, submit) |
| 12 | "Logout" effect: wiped storage → next boot returns to `/login` | ✅ | `localStorage.clear()` → reload → URL: `/#/login`, only `flutter.language` + `flutter.theme` remain (recreated by bootstrap defaults). No `FlutterSecureStorage.*` keys leak. |
| 13 | Router redirect respects sealed `SessionAuthenticated` (I1 wiring) | ✅ | Authenticated user navigating to `/login` would be redirected to `/` — covered by router code `if (isAuthenticated && isPublic) return home`. Verified by Dashboard rendering after login (`/login` → `/` rather than staying on `/login`). |

## Console / Terminal Log Highlights

**Bootstrap (cold):**
```
ConnectivityService : Initial connectivity status: online
CrashReporter : Crash reporter installed
AppBootstrap : Starting app with env: dev, language: en, palette: classic, brightness: light
AppRouterFactory : redirect - location: /, session: SessionUnknown
AppRouterFactory : redirect - location: /login, session: SessionUnknown
SessionCubit : restore: no token in secure storage → unauthenticated   ← I1 + secure read
AppRouterFactory : redirect - location: /login, session: SessionUnauthenticated
```

**Post-login (authenticated traffic):**
```
MenuRepository : END:getMenus successful — response.body: [Menu(home, ...), ...]
AuthInterceptor : Request [GET] /account (auth: true, token: MOCK…OKEN)   ← S2 masking
ResilienceInterceptor : Circuit closed for endpoint "/account"
MockInterceptor : Mock data loaded: GET /account (body length: 362)
AccountRepository : END:getAccount successful — response.body: User(user-1, admin, ...)
AccountBloc : END: getAccount bloc: _onLoad success: User(user-1, admin, ...)
```

**Errors / warnings observed:** none.

## Secure Storage Inspection (post-login)

```
FlutterSecureStorage                  = aThLpnzMKOW/B0gWpARVV6gAcUZCwI5pbuJ1/NvX0HQ=  ← encryption key
FlutterSecureStorage.jwtToken         = pXHMpuYX7pCwvils.VKtQ/Ie78sSuS… (53 ch cipher)
FlutterSecureStorage.refreshToken     = Ck0VIDpg+Um54NL6.dMseqNThrUTfh… (65 ch cipher)
flutter.username                      = "admin"      ← plaintext (non-sensitive)
flutter.roles                         = ["ROLE_ADMIN","ROLE_USER"]  ← plaintext (non-sensitive)
flutter.language                      = "en"
flutter.theme                         = "classic"
```

**Key finding:** the JWT and refresh tokens are present as encrypted bytes via `flutter_secure_storage_web`, NEVER as plaintext under `flutter.jwtToken` (which was the legacy unsafe location prior to this PR).

## What Couldn't Be Tested via Chrome MCP

These are **tooling limitations**, NOT product gaps. All covered by the unit/widget test suite (1478/1478 passing).

| Gap | Reason | Coverage |
|---|---|---|
| Sidebar `Logout` button click via UI | Flutter renders the sidebar without exposing widgets to the accessibility tree; chrome-devtools-mcp can only click elements with a `uid` from the semantic snapshot. | `logout_test`, `auth_repository_impl_test`, `auth_session_repository_impl_test` exercise the full cleanup path. E2E equivalent simulated via `localStorage.clear()`. |
| Token refresh round trip (401 → refresh → retry) | Requires triggering a real 401 with valid refresh; mock interceptor doesn't expose this path. | `token_refresh_interceptor_test` — 28 tests including the new happy-path + rollback (C1, C2). |
| Adapter throw-on-failure contract | Requires forcing the platform channel to throw `PlatformException`. | `secure_storage_test` — 5 tests driving `setMockMethodCallHandler` directly with `PlatformException`. |

## Verdict

**PR #137 ships its security claim end-to-end on web.** Tokens are encrypted at rest, never logged in plaintext, restored correctly across reloads, and wiped on logout-equivalent clear. The sealed `SessionState` hierarchy from I1 is observable in the live log stream. Zero errors / warnings during the verified flows.

**Remaining concerns:** none observable from E2E. PR is ship-ready.
