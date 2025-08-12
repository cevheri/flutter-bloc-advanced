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



```
/**
 * Color Opacity to Alpha Conversion Guide
 * 
 * Why we're moving from withOpacity to withAlpha:
 * 
 * 1. Precision:
 *    - withOpacity uses double values (0.0 to 1.0) which can lead to floating-point precision loss
 *    - withAlpha uses integer values (0 to 255) providing exact precision
 * 
 * 2. Performance:
 *    - withAlpha is more performant as it avoids floating-point calculations
 *    - Direct integer operations are faster than floating-point operations
 * 
 * Conversion Formula:
 * alpha = opacity * 255
 * 
 * Common Conversions:
 * 0.1 opacity = 26 alpha   (0.1 * 255)
 * 0.2 opacity = 51 alpha   (0.2 * 255)
 * 0.3 opacity = 77 alpha   (0.3 * 255)
 * 0.4 opacity = 102 alpha  (0.4 * 255)
 * 0.5 opacity = 128 alpha  (0.5 * 255)
 * 0.6 opacity = 153 alpha  (0.6 * 255)
 * 0.7 opacity = 179 alpha  (0.7 * 255)
 * 0.8 opacity = 204 alpha  (0.8 * 255)
 * 0.9 opacity = 230 alpha  (0.9 * 255)
 * 1.0 opacity = 255 alpha  (1.0 * 255)
 * 
 * Example Usage:
 * // Old (Deprecated):
 * color With Opacity(0.5)
 * 
 * // New:
 * color.withAlpha(128)  // 0.5 * 255 = 128
 * 
 * This change is part of Flutter 3.27's improvements for better color precision
 * and performance optimization.
 */

```