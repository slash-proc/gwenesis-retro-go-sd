# Changelog

This file is a template for the single project created from this repo.
At project setup time you choose exactly one kind by setting `PROJECT_KIND`
to `core` or `homebrew` (you will only build/release that chosen kind).

Update the content for your project and keep the section heading matching
the pushed release tag (CI requirement).

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Release tags must
match a section heading exactly (for example `v1.0.0`).

When you cut a release:

1. Move items from `[Unreleased]` into a new `## [vX.Y.Z] - YYYY-MM-DD` section.
2. Commit the changelog update.
3. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

CI reads the matching section and uses it as the GitHub Release notes. The tag
is also used in staged asset names (`<binary>-<tag>.bin`, `<binary>-<tag>.zip`).

## [Unreleased]

### Added

First release

### Changed

First release

### Fixed

First release

## [v1.0.0] - 2026-08-12

Initial public release for Megadrive/Genesis core.

### Added

- First external core for Gwenesis

### Install

- Copy `md.bin` to `/cores/` on the SD card.
- Place test ROMs under `/roms/md/`.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
