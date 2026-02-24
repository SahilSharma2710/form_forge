# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2026-02-24

### Changed

- Upgraded `source_gen` to `^4.0.0`, `build` to `^4.0.0`, `analyzer` to `>=10.0.0 <12.0.0`, `build_test` to `^3.0.0`
- Bumped minimum Dart SDK to `^3.7.0` (required by upgraded deps)
- Replaced deprecated `isSynthetic` with `isOriginDeclaration` for analyzer 10.x compatibility
- Migrated tests to build_test 3.x API (`TestBuilderResult` / `TestReaderWriter`)

## [0.1.1] - 2026-02-23

### Fixed

- Removed unused `_baseName` method that caused `dart analyze` warning
- Eliminated lint suppressions (`// ignore: unused_field`, `// ignore: unused_element`) in generated async validation code by wiring `_triggerAsyncValidation` into widget `onChanged` handlers

### Changed

- Widened `analyzer` dependency to `>=6.0.0 <8.0.0`
- Loosened `build_runner` constraint from `>=2.4.0 <2.5.0` to `^2.4.0`

## [0.1.0] - 2026-02-21

### Added

- `FormForgeGenerator` — processes `@FormForge()` annotations via `build_runner`
- Generates `FormController` with typed fields, sync validation, cross-field validation, async validation
- Generates `FormWidget` with type-to-widget mapping (String, int, bool, DateTime, enum)
- Generates `FormData` class for typed form submission
- `FieldResolver` for annotation parsing
- Three-phase validation pipeline: sync → cross-field → async
