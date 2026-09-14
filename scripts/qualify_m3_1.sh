#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CROSS=${CROSS:-m68k-elf-}
AS=${CROSS}as
LD=${CROSS}ld
OBJCOPY=${CROSS}objcopy
BUILD="$ROOT/build"
OBJ="$BUILD/m3_1-reset.o"
ELF="$BUILD/librom-m3.1-macplus.elf"
ROM="$BUILD/librom-m3.1-macplus.bin"
MAP="$BUILD/librom-m3.1-macplus.map"

mkdir -p "$BUILD"
python3 "$ROOT/scripts/check_m3_1.py"
"$AS" -m68000 -o "$OBJ" "$ROOT/src/platform/macplus/reset_m3_1.S"
"$LD" -T "$ROOT/linker/m3_1.ld" -Map="$MAP" -o "$ELF" "$OBJ"
"$OBJCOPY" -O binary --gap-fill=0xff "$ELF" "$ROM"
python3 "$ROOT/scripts/pad_rom.py" "$ROM" 131072
bash "$ROOT/scripts/qualify_m3_1_runtime.sh" "$ROM"
