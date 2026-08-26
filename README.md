# Gwenesis — Sega Genesis / Mega Drive for Retro-Go SD

Standalone dynamic core for
[Game & Watch Retro-Go SD](https://github.com/sylverb/game-and-watch-retro-go-sd).

Emulator: [sylverb/gwenesis](https://github.com/sylverb/gwenesis) (submodule
under `src/gwenesis`). Porting layer: `src/main_gwenesis.c` (from the
firmware `cores/md` / `Core/Src/porting/gwenesis`).

Talks to the launcher **only** through `gw_firmware_abi_t` (vendored under
`sdk/`). You do **not** need a firmware checkout to compile.

## SD layout

| | Path |
|--|------|
| Core | `/cores/gwenesis.bin` |
| ROMs | `/roms/md/` (`.md` `.gen` `.bin`) |

## Requirements

**Local build**

- `arm-none-eabi-gcc` (v10+, hard-float `fpv5-d16` mandatory)
- GNU Make
- Python 3 + Pillow (`pip install -r requirements.txt`) for packaging logos
- Git submodule: `git submodule update --init --recursive`

**Docker build** (no host toolchain)

- Docker
- Image [`sylverb/retro-go-sd-builder`](https://hub.docker.com/r/sylverb/retro-go-sd-builder)
  (default tag `v1.5`)

## Quick start

```bash
git submodule update --init --recursive
make
# or: make docker
```

Produces `gwenesis.bin` → copy to `/cores/gwenesis.bin` on the SD card.

## Layout

```
Makefile              Build + pack + docker (+ host SDL stub)
src/
  main_gwenesis.c     Entry + frame loop / options / ROM load
  md_i18n.c           Pause-menu strings
  assets/             Pad + header 1bpp logos
src/gwenesis/         Emulator submodule
sdk/                  Vendored ABI bridge, headers, linker scripts, packers
scripts/              sync_from_firmware.sh, stage_release.py, resolve_addr.py
host/                 SDL preview shim (from template; not fully wired for Gwenesis)
```

Tag releases attach an install zip (`cores/gwenesis.bin` → `gwenesis-<tag>.zip`)
and a debug zip (ELF + map) for `arm-none-eabi-addr2line` crash decoding — see
`scripts/DEBUG_README.md`.

## ABI compatibility

The packed binary embeds `required_abi_version` / `required_abi_min_size`.
See `SDK_VERSION` for the firmware snapshot this SDK was cut from.

```bash
./scripts/sync_from_firmware.sh /path/to/game-and-watch-retro-go-sd
```

## License

Build glue is MIT (see `LICENSE`). Gwenesis is GPLv3 (see
`src/gwenesis/LICENSE`). Vendored SDK headers keep their upstream
licenses.
