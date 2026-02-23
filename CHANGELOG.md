# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-23

### Fixed

- Removed unused `_baseName` method in generator (dart analyze warning)
- Wired async validation `_triggerAsyncValidation` into widget `onChanged` handlers, removing lint suppressions in generated code

### Changed

- Widened `analyzer` dependency to `>=6.0.0 <8.0.0`
- Loosened `build_runner` constraint to `^2.4.0`

## [Unreleased]

### Added

- Initial workspace scaffold with 3 packages: form_forge, form_forge_generator, form_forge_example
