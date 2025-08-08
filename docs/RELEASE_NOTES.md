# Dashboard (Mock) overhaul, Drawer refactor, theme fix, and web build updates

Tag: v0.8.0

### Highlights
- Mock-driven Dashboard foundation with basic UI wiring
- Quick actions redesigned as chip-like buttons with a “More” bottom-sheet
- Drawer state management and initialization refactor
- Theme switching race-condition fix
- Web build/deploy reliability improvements and formatting updates

### Added
- Dashboard: model, mock repository, cubit, and basic UI wiring
- Dashboard: provide `DashboardCubit` with mock repository in `HomeScreen`
- Dashboard: quick actions redesigned as chip-like buttons with a “More” bottom-sheet
- Web build: add build web actions

### Changed
- Drawer: refactor state management and initialization
- Icon utilities: replace `string_2_icon` with `icon_utils` and update drawer widget
- Formatting: set Dart formatter `page_width` to 125 in `analysis_options.yaml`; remove trailing newlines and apply consistent formatting
- Dependencies: update Flutter and package versions
- Dashboard: initial design/wireframe; repo scan and baseline tests

### Fixed
- Theme: resolve race-condition during theme switching
- Dashboard: remove direct `part` import from `HomeScreen`
- Web: fix web build and deploy to target

### Breaking Changes
- None

### How to Test
1. `flutter clean && flutter pub get`
2. `flutter analyze && flutter test`
3. `flutter run -d chrome`
4. Navigate to Dashboard and verify:
   - Quick actions appear as chips; “More” opens a bottom-sheet
   - Drawer transitions are consistent
   - Theme toggling is stable (no flicker)

### Notes
- This is a minor release (no breaking changes); suitable for tagging as `v0.8.0`.
- Full changelog is reflected under Unreleased in `CHANGELOG.md`.
