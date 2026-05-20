# User Extended-Info Dynamic Form — Design

**Issue:** [#121](https://github.com/cevheri/flutter-bloc-advanced/issues/121)
**Date:** 2026-05-20
**Status:** Implemented in PR #128

> **Note on evolution during implementation.** This spec captured the design **before** execution. Two architectural decisions were made during the PR after this spec was approved:
>
> 1. **`dynamic_forms` relocated from `features/` to `shared/`** — the engine has no domain entity of its own (`FormSchemaEntity` describes how to render OTHER entities), so it's structurally a reusable subsystem, not a vertical feature. Where this doc says `features/dynamic_forms/...`, the canonical location is now `shared/dynamic_forms/...`. The architecture import-guard test enforces this.
>
> 2. **Engine learned native `pathParams`** — the URL convention shifted from `/admin/users/:id/extended` to `/admin/users/extended/{id}` because the engine now separates `basePath` (`/admin/users/extended`) from the per-instance path segment (`pathParams: userId`). The `DynamicFormLoadBundleEvent(basePath, pathParams: ...)` event and `DynamicFormLoaded.submitPathParams` field carry the segment from load through to submit. A single mock fixture `GET_admin_users_extended_pathParams.json` now serves every user. Section 5.3's `loadBundle(endpoint)` is actually `fetchBundle(basePath, {String? pathParams})` in the shipped code.
>
> Read this spec as the original direction; consult the implementation (`shared/dynamic_forms/`) and PR #128 for the as-built reality.

---

## 1. Problem

The `dynamic_forms` feature ships 16 supported `FormFieldType`s but the only consumer is the dashboard's "Open Dynamic Forms" button → `/dynamic-forms/sample` (a CRM-lead mock). There is no single demo route that exercises every field type, and the `users` feature has no extended-info form despite being the natural home for one. The engine reads as an architectural vitrine rather than a productive feature.

## 2. Goal

Add a comprehensive **user extended-info** form, reachable from the user editor, that:

1. Renders all 16 `FormFieldType`s in one realistic schema.
2. Demonstrates the full round-trip: `GET` (schema + prefilled values) → render → edit → `PUT` (submit).
3. Reuses the existing `DynamicFormBloc` / `LoadFormSchemaUseCase` / `SubmitFormUseCase` / `DynamicFormRenderer` machinery unchanged — except for a small, additive repository extension to support a bundled schema+values endpoint.

## 3. Non-goals (YAGNI fence)

- Per-`:id` personalized prefills (one shared demo payload is sufficient).
- Conditional / cross-field validation (engine doesn't support it; out of scope).
- Wizard / multi-step layout (listed as a future direction in `docs/archived/advanced-features.md`).
- Mock persistence across reloads.
- Real backend wiring (mock interceptor only; swap-in is trivially "delete the mock JSON").

## 4. User flow

```
User list  →  User editor (edit or view mode)
                    │
                    │  taps [Extended Info] outlined button
                    ▼
              /user/:id/extended-info
                    │
                    │  on entry: GET /admin/users/extended/:id
                    ▼
              schema + values rendered via DynamicFormRenderer
                    │
                    │  user edits, taps [Save]
                    ▼
              PUT /admin/users/extended/:id
                    │
                    │  on success: success snackbar + pop back to editor
                    │  on failure: snackbar (typed values preserved by form key)
```

The button is shown in `EditorFormMode.edit` and `EditorFormMode.view` only — not in `create` mode (no `:id` yet).

## 5. Architecture

### 5.1 Component layout

```
features/
└─ users/
   ├─ navigation/
   │  └─ users_routes.dart                            ← add /user/:id/extended-info
   └─ presentation/
      └─ pages/
         ├─ user_editor_page.dart                     ← add [Extended Info] button
         └─ user_extended_info_page.dart              ← NEW

features/
└─ dynamic_forms/
   ├─ domain/
   │  └─ repositories/dynamic_form_repository.dart    ← add loadBundle(endpoint)
   ├─ data/
   │  └─ repositories/dynamic_form_repository_impl.dart  ← implement loadBundle
   ├─ application/
   │  └─ usecases/load_form_bundle_usecase.dart       ← NEW
   └─ ...DynamicFormBloc, DynamicFormRenderer reused unchanged

assets/mock/
├─ GET_admin_users_extended_pathParams.json          ← NEW (schema + values, one fixture serves every user)
└─ PUT_admin_users_extended_pathParams.json          ← NEW ({"ok": true})

lib/l10n/
├─ intl_en.arb                                        ← add 4 keys
└─ intl_tr.arb                                        ← add 4 keys
```

### 5.2 The new page

`UserExtendedInfoPage` is a configured host for the existing engine:

```dart
BlocProvider<DynamicFormBloc>(
  create: (_) => DynamicFormBloc(
    loadBundleUseCase: AppScope.of(context).loadFormBundleUseCase,
    submitUseCase: AppScope.of(context).submitFormUseCase,
  )..add(DynamicFormLoadBundleEvent('/admin/users/$id/extended')),
  child: ...,
)
```

It renders `DynamicFormRenderer` with the schema + initial values from `DynamicFormLoaded`, and dispatches `DynamicFormSubmitEvent` from the renderer's `onSubmit` callback.

### 5.3 Repository extension

Today `IDynamicFormRepository` exposes:

```dart
Future<Result<FormSchemaEntity, AppError>> loadSchema(String formId);
Future<Result<Map<String, dynamic>, AppError>> submit({...});
```

Add one method:

```dart
/// Fetches a schema bundled with its initial values from a single endpoint.
/// Used for server-driven forms whose values live next to their schema
/// (e.g. user extended info, profile preferences).
Future<Result<FormBundleEntity, AppError>> loadBundle(String endpoint);
```

`FormBundleEntity` is a small data class: `{schema: FormSchemaEntity, values: Map<String, dynamic>}`. New use case `LoadFormBundleUseCase` wraps the call. A new event variant `DynamicFormLoadBundleEvent(endpoint)` is added to the existing bloc; the `DynamicFormLoaded(schema, initialValues)` state grows an optional `initialValues` field (default `{}` to keep the existing schema-only callers untouched).

This is **additive only** — the existing `loadSchema` + `LoadFormSchemaUseCase` + `DynamicFormLoadEvent` path stays in place, untouched, for the CRM-lead demo and any future schema-only consumers.

### 5.4 State handling

`UserExtendedInfoPage` switches on sealed `DynamicFormState`:

| State | Render |
|---|---|
| `DynamicFormInitial`, `DynamicFormLoading` | `AppLoadingIndicator` |
| `DynamicFormLoaded(schema, initialValues)` | `DynamicFormRenderer(schema, initialValues: initialValues, onSubmit: ...)` |
| `DynamicFormSubmitting(schema)` | Renderer in `readOnly: true` mode + spinner on save button |
| `DynamicFormSubmitted(...)` | Success snackbar + `context.pop()` |
| `DynamicFormFailure(error, schema?)` | If `schema != null`: `SnackBar` via `ScaffoldMessenger` (typed values preserved by the form key). Else: full-page error text with the error message. |

## 6. Schema content

A single JSON schema covering all 16 `FormFieldType`s, grouped semantically:

```
sectionHeader  "Personal"
  text           firstName            (readOnly demo)
  text           lastName             (readOnly demo)
  email          email                (required)
  phone          phone
  textarea       bio                  (maxLines: 4)
  date           birthdate
  number         yearsExperience      (min: 0, max: 60)
divider
sectionHeader  "Preferences"
  dropdown       country              (TR, US, DE, FR, GB)
  dropdown       language             (en, tr, de)
  multiSelect    interests            (flutter, bloc, dart, design)
  radio          themePreference      (light, dark, system)
  radio          accountType          (individual, business)
  slider         notificationVolume   (min: 0, max: 100, step: 10)
  toggle         newsletter
divider
sectionHeader  "Security"
  password       newPassword          (optional)
  datetime       lastLoginOverride
  checkbox       acceptTerms          (required)
```

That's all 16 types in one schema. `sectionHeader` and `divider` are used purely for layout — they have no value in the submit payload.

### 6.1 Mock response shape

```json
{
  "schema": {
    "id": "user_extended_info",
    "title": "Extended Information",
    "description": "Profile, preferences and security",
    "submitAction": { "method": "PUT", "endpoint": "/admin/users/extended" },
    "layout": "responsive",
    "fields": [ ...all 16 fields... ]
  },
  "values": {
    "firstName": "Alice",
    "lastName": "Liddell",
    "email": "alice@example.com",
    "phone": "+90 555 010 20 30",
    "bio": "Backend engineer, dabbling in Flutter.",
    "birthdate": "1990-01-15",
    "yearsExperience": 8,
    "country": "TR",
    "language": "en",
    "interests": ["flutter", "bloc"],
    "themePreference": "system",
    "accountType": "individual",
    "notificationVolume": 60,
    "newsletter": true,
    "newPassword": null,
    "lastLoginOverride": "2026-05-19T12:30:00Z",
    "acceptTerms": true
  }
}
```

The PUT mock response is just `{ "ok": true, "id": "<userId>" }`.

## 7. UI

- **Page header:** `AppPageHeader(title: tr.user_extended_info_title, subtitle: '<userEmail>')`. The user email is passed via `GoRouterState.extra` from the editor page to avoid a second fetch.
- **Body:** `DynamicFormRenderer` wrapped in `AppFormCard` inside `SingleChildScrollView`.
- **Save button:** `AppSubmitButton` at the bottom of the card. Sticky on mobile (via `AppResponsiveBuilder`), inline on desktop.
- **Loading and submitting:** disable the renderer's interactive fields and show an inline spinner on the save button.
- **Error:** `SnackBar` via `ScaffoldMessenger` when a partial state (`schema != null` on failure) exists, so the user keeps their typed values in the form (form key preserves field state).

## 8. Tests

Unit / widget tests (under `test/features/users/presentation/pages/`):

- `user_extended_info_page_test.dart`
  - Renders `AppLoadingIndicator` while bloc is `DynamicFormLoading`.
  - Renders `DynamicFormRenderer` with prefilled values on `DynamicFormLoaded`.
  - Submit button triggers `DynamicFormSubmitEvent` and on `DynamicFormSubmitted` pops the route + shows a snackbar.
  - On `DynamicFormFailure(schema != null)` shows a `SnackBar` with the error and preserves typed values.

Mock interceptor coverage:

- `test/infrastructure/http/mock_interceptor_test.dart` (if it exists) gets a case for the new `*_admin_users_extended_*` files.

No changes needed to existing `DynamicFormBloc` tests since the new event/state additions are additive. Add a focused `dynamic_form_bloc_load_bundle_test.dart` to cover the new bundle path.

## 9. l10n

New ARB keys (en + tr):

- `user_extended_info_title` — "Extended Information" / "Genişletilmiş Bilgi"
- `user_extended_info_button` — "Extended Info" / "Genişletilmiş Bilgi"
- `user_extended_info_saved` — "Saved" / "Kaydedildi"
- `user_extended_info_save_failed` — "Save failed: {error}" / "Kayıt başarısız: {error}"

Field labels live in the schema JSON (server-driven), not in ARB — matching the lead demo.

## 10. Risks and open questions

- **Schema parser strictness:** `FormSchemaModel.fromJson` accepts both snake_case and camelCase for `multiSelect` / `sectionHeader`. The new mock JSON should pick one and stick with it for readability (use camelCase).
- **`AppScope` wiring:** the new `LoadFormBundleUseCase` must be registered in `lib/app/di/app_scope.dart`. Plan must include this; missing it is a likely cause of "throwing fallback DI" regressions like the ones cleaned up in #86.
- **Sealed state additive change:** growing `DynamicFormLoaded` with an optional `initialValues` field is backward-compatible (default `const {}`); all existing call sites continue to compile.

## 11. Acceptance criteria

- [ ] `/user/:id/extended-info` route works from both `edit` and `view` modes of the user editor.
- [ ] All 16 `FormFieldType`s render correctly with their demo prefills.
- [ ] Submit `PUT /admin/users/extended/:id` returns 200 from mock; UI shows snackbar + pops.
- [ ] Submit failure surfaces a `SnackBar` with the error message and preserves typed values (form key holds state).
- [ ] `fvm dart analyze` clean.
- [ ] `fvm dart format --line-length=120 --set-exit-if-changed .` clean.
- [ ] `fvm flutter test` green (existing 472 tests + new ones).
- [ ] No imports from `features/users/*` into `shared/dynamic_forms/*` or vice versa — communication is via the renderer's public widget API and the DI-injected use cases only.
