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

CI reads the matching section and uses it as the GitHub Release notes. Assets
attached to the release:

- `<binary>-<tag>.zip` — SD layout only (`cores/` + packed `.bin`)
- `<binary>-<tag>-debug.zip` — ELF + linker map (use `arm-none-eabi-addr2line` for crash PC/LR → function/line)

## [Unreleased]

### Added

- Sync from `retro-go-sd-templates`: debug release zips (ELF + map), host SDL
  tree, bridge override knobs, `CORE_VERSION` from git tags.

### Changed

- Vendored SDK refreshed (ABI sync 2026-08-26): odroid headers under
  `Core/Inc/porting`, `appid.h` (`APPID_CORE`), firmware seeds `ram_start`.
- Pack/CI: version from `git describe`; release ships install + debug archives.
- Packed binary renamed to `gwenesis.bin` (release zips: `gwenesis-<tag>.zip`).

### Fixed

- (none yet)

## [v1.0.0] - 2026-08-12

Initial public release for Megadrive/Genesis core.

### Added

- First external core for Gwenesis

### Install

- Copy `gwenesis.bin` to `/cores/` on the SD card.
- Place test ROMs under `/roms/md/`.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
