# Flutter Template Changelog

@formatter:off
* All notable changes to this project will be documented in this file.
* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project  adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
* This template is based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

### Guiding Principles

- Changelogs are for humans, not machines.
- There should be an entry for every single version.
- The same types of changes should be grouped.
- Versions and sections should be linkable.
- The latest version comes first.
- The release date of each version is displayed.
- Mention whether you follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Types of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.
- `Performance` for improvements in performance.
- `Style` for changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `Docs` for documentation only changes
- `Build` for changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)

### [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

A specification for adding human and machine readable meaning to commit messages.

- `feat` a new feature
- `fix` a bug fix
- `docs` documentation only changes
- `style` changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor` a code change that neither fixes a bug nor adds a feature
- `perf` a code change that improves performance
- `test` adding missing tests or correcting existing tests
- `build` changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- `chore` other changes
- **BREAKING CHANGE**: a commit that has a footer BREAKING CHANGE:, or appends a ! after the type/scope, introduces a breaking API change (correlating with MAJOR in Semantic Versioning). A BREAKING  CHANGE can be part of commits of any type.

---

### Well-known flutter-analyzer issues


---

### Appendix Issues


---

@formatter:off

# Releases

## [Unreleased]()
### Added
- Dashboard: model, mock repository, cubit, and basic UI wiring.
- Dashboard: provide `DashboardCubit` with mock repository in `HomeScreen`.
- Dashboard: quick actions redesigned as chip-like buttons with a “More” bottom-sheet.
- Web build: add build web actions.

### Changed
- Drawer: refactor state management and initialization.
- Icon utilities: replace `string_2_icon` with `icon_utils` and update drawer widget.
- Formatting: set Dart formatter `page_width` to 125 in `analysis_options.yaml`; clean up trailing newlines and apply consistent formatting.
- Dependencies: update Flutter and package versions.
- Dashboard: initial design/wireframe, repo scan, and baseline tests.

### Fixed
- Theme: resolve race-condition during theme switching.
- Dashboard: remove direct `part` import from `HomeScreen`.
- Web: fix web build and deploy to target.

### Removed
- None

### BREAKING CHANGES
- None


---
