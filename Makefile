# Gwenesis — Sega Genesis / Mega Drive core for Retro-Go SD.
#
#   make                  — build + pack → md.bin
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# Drop md.bin on the SD card under /cores/. ROMs under /roms/md/
# (extensions: .md .gen .bin).
#
# Emulator: src/gwenesis (submodule). Porting: src/main_gwenesis.c
# (from firmware Core/Src/porting/gwenesis/). Verbose: make V=

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := md
CORE_ENTRY := app_main_gwenesis

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

# LSB_FIRST/TABLES_FULL: M68K + Z80. TARGET_GNW: G&W branches in gwenesis.
# COVERFLOW/CHEAT_CODES: match firmware retro_emulator_file_t layout.
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

# Relative path so Docker bind-mounts work (do NOT use $(abspath)).
GNW_CORE_SDK ?= sdk
BUILD_DIR ?= build/$(PROJECT_KIND)

ifeq ($(PROJECT_KIND),core)
PACKED_BIN  := md.bin
PAD_LOGO    := src/assets/pad.png
HEADER_LOGO := src/assets/header.png
# Assets are light-on-dark; pack_core --logo-invert restores lit 1bpp glyphs.
else
$(error Gwenesis is a dynamic core only (PROJECT_KIND=core); got '$(PROJECT_KIND)')
endif

include $(GNW_CORE_SDK)/Makefile

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Pack
#######################################
.PHONY: pack

pack: $(TARGET_BIN) $(PAD_LOGO) $(HEADER_LOGO)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system-name "Sega Genesis" --dirname md \
		--extensions "md gen bin" \
		--core-name "Gwenesis" \
		--version 1.0.0 \
		--pad-logo $(PAD_LOGO) \
		--header-logo $(HEADER_LOGO) \
		--logo-invert \
		--out $(PACKED_BIN)

all: pack

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
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

docker_shell:
	$(DOCKER_RUN) bash
