#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CROSS=${CROSS:-m68k-linux-gnu-}
BUILD="$ROOT/build"
OBJ="$BUILD/m2_13-reset.o"
ELF="$BUILD/librom-m2.13-macplus.elf"
ROM="$BUILD/librom-m2.13-macplus.bin"
MAP="$BUILD/librom-m2.13-macplus.map"

mkdir -p "$BUILD"
"${CROSS}as" -m68000 -o "$OBJ" "$ROOT/src/platform/macplus/reset_m2_13.S"
"${CROSS}ld" -T "$ROOT/linker/m2_13.ld" -Map="$MAP" -o "$ELF" "$OBJ"
"${CROSS}objcopy" -O binary --gap-fill=0xff "$ELF" "$ROM"
python3 "$ROOT/scripts/pad_rom.py" "$ROM" 131072
python3 "$ROOT/scripts/check_m2_13.py"
CROSS="$CROSS" bash "$ROOT/scripts/qualify_m2_13_pce.sh" "$ROM" "$ELF"
