# Gwenesis — Sega Genesis / Mega Drive core for Retro-Go SD.
#
#   make                  — build + pack → gwenesis.bin
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# Drop gwenesis.bin on the SD card under /cores/. ROMs under /roms/md/
# (extensions: .md .gen .bin).
#
# Emulator: src/gwenesis (submodule). Porting: src/main_gwenesis.c
# (from firmware Core/Src/porting/gwenesis/). Verbose: make V=
#
# Host SDL preview (experimental; Gwenesis is not fully stubbed for desktop):
#   make host / make host HOST_SDL=3

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := gwenesis
CORE_ENTRY := app_main_gwenesis
# SD ROM folder (pack --dirname); independent of CORE_NAME / binary stem.
ROM_DIRNAME := md

CORE_GWENESIS := src/gwenesis

CORE_C_SOURCES := \
$(CORE_GWENESIS)/src/cpus/M68K/m68kcpu.c \
$(CORE_GWENESIS)/src/cpus/Z80/Z80.c \
$(CORE_GWENESIS)/src/sound/z80inst.c \
$(CORE_GWENESIS)/src/sound/ym2612.c \
$(CORE_GWENESIS)/src/sound/gwenesis_sn76489.c \
$(CORE_GWENESIS)/src/bus/gwenesis_bus.c \
$(CORE_GWENESIS)/src/bus/gwenesis_sram.c \
$(CORE_GWENESIS)/src/bus/gwenesis_eeprom.c \
$(CORE_GWENESIS)/src/io/gwenesis_io.c \
$(CORE_GWENESIS)/src/vdp/gwenesis_vdp_mem.c \
$(CORE_GWENESIS)/src/vdp/gwenesis_vdp_gfx.c \
$(CORE_GWENESIS)/src/savestate/gwenesis_savestate.c \
src/main_gwenesis.c \
src/md_i18n.c

CORE_C_INCLUDES := \
-I$(CORE_GWENESIS)/src/cpus/M68K \
-I$(CORE_GWENESIS)/src/cpus/Z80 \
-I$(CORE_GWENESIS)/src/sound \
-I$(CORE_GWENESIS)/src/bus \
-I$(CORE_GWENESIS)/src/vdp \
-I$(CORE_GWENESIS)/src/io \
-I$(CORE_GWENESIS)/src/savestate \
-Isrc

# Relative path so Docker bind-mounts work (do NOT use $(abspath) — it
# bakes the host path into Make prerequisites / .d files). Do not name
# this SDK_ROOT: that env var is commonly set by Android SDK installs.
GNW_CORE_SDK ?= sdk
# Separate build trees so switching PROJECT_KIND does not reuse stale .o.
BUILD_DIR ?= build/$(PROJECT_KIND)

#######################################
# SDK bridge overrides (optional)
#######################################
# The SDK bridge (gw_core_bridge.c) provides default implementations for
# memcpy/memset/memmove/__aeabi_mem* and malloc/calloc/free/realloc.
# Define these to exclude the SDK versions and supply your own:
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMCPY — exclude memcpy only.
#       Memmove stays routed through the SDK bridge (Doom/fastmem needs it).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMSET — exclude memset only.
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMMOVE — exclude memmove too (requires your
#       core to provide memmove).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMOPS — back-compat: exclude the full memops
#       block (memcpy/memset/memmove + all __aeabi_mem* helpers).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MALLOC — exclude the malloc/calloc/free/
#       realloc wrappers that forward to the firmware ABI heap. Use this when
#       the core links its own allocator or needs a custom malloc/free path.
#
# To enable, add the define(s) to CORE_C_DEFS below, e.g.:
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MEMCPY
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MEMSET
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MALLOC

#######################################
# Kind-specific compile defs + packing
#######################################
ifeq ($(PROJECT_KIND),core)
# LSB_FIRST/TABLES_FULL: M68K + Z80. TARGET_GNW: G&W branches in gwenesis.
# COVERFLOW/CHEAT_CODES: match firmware retro_emulator_file_t layout.
# MAX_CHEAT_CODES mirrors Makefile.common's release default.
CORE_C_DEFS := \
-DLSB_FIRST \
-DTABLES_FULL \
-DTARGET_GNW \
-DPROJECT_KIND_CORE=1 \
-DCOVERFLOW=1 \
-DCHEAT_CODES=1 \
-DMAX_CHEAT_CODES=13

# ym2612.c builds sine/log FM tables with libm sin()/log() at startup.
CORE_LDLIBS := -lm

PACKED_BIN  := $(CORE_NAME).bin
PAD_LOGO    := src/assets/pad.png
HEADER_LOGO := src/assets/header.png
# Assets are light-on-dark; pack_core --logo-invert restores lit 1bpp glyphs.

else
$(error Gwenesis is a dynamic core only (PROJECT_KIND=core); got '$(PROJECT_KIND)')
endif

include $(GNW_CORE_SDK)/Makefile

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Packed header version
#######################################
# gnw_core_meta_t only stores major.minor.patch (0..255).
# CORE_VERSION is the full git describe string passed to the packer; it
# extracts the leading vX.Y.Z (NOTAG / missing tags → 0.0.0).
# Override: make CORE_VERSION=v1.2.3
CORE_VERSION ?= $(shell git describe --tags --dirty 2>/dev/null || echo NOTAG)

#######################################
# Pack
#######################################
.PHONY: pack

pack: $(TARGET_BIN) $(PAD_LOGO) $(HEADER_LOGO)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN) version=$(CORE_VERSION)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system-name "Sega Genesis" --dirname $(ROM_DIRNAME) \
		--extensions "md gen bin" \
		--core-name "Gwenesis" \
		--version "$(CORE_VERSION)" \
		--pad-logo $(PAD_LOGO) \
		--header-logo $(HEADER_LOGO) \
		--logo-invert \
		--out $(PACKED_BIN)

all: pack

# Read-only helpers for CI / scripts (make print-PROJECT_KIND, etc.).
.PHONY: print-PROJECT_KIND print-PACKED_BIN print-RO_BIN print-CORE_NAME print-ROM_DIRNAME print-DOCKER_IMAGE \
	print-TARGET_ELF print-TARGET_MAP print-CORE_VERSION
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
# The shared stage_release.py asks every project for RO_BIN: the extra
# device file installed beside the packed binary. Empty here.
print-RO_BIN:
	@echo $(RO_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-ROM_DIRNAME:
	@echo $(ROM_DIRNAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)
print-TARGET_ELF:
	@echo $(TARGET_ELF)
print-TARGET_MAP:
	@echo $(BUILD_DIR)/$(CORE_NAME)_core.map
print-CORE_VERSION:
	@echo $(CORE_VERSION)

clean::
	$(V)rm -f $(PACKED_BIN)

#######################################
# Docker (same image as firmware repo)
#######################################
.PHONY: docker docker_pull docker_shell

RELEASE_VERSION ?= v1.5
DOCKER_REPOSITORY ?= sylverb/retro-go-sd-builder
DOCKER_IMAGE ?= $(DOCKER_REPOSITORY):$(RELEASE_VERSION)

DOCKER_TTY_FLAG := $(shell if [ -t 0 ]; then echo -it; else echo; fi)
# Host UID so build/ artifacts are not root-owned on the bind mount.
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

# Compile inside the published builder image (uses the local copy).
# Refresh with `make docker_pull` when you want a newer digest for the tag.
docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

# Interactive shell with the same image / mount as `make docker`.
docker_shell:
	$(DOCKER_RUN) bash

#######################################
# Host SDL (Linux / macOS)
#######################################
include host/Makefile.host
