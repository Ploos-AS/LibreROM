#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CROSS=${CROSS:-m68k-linux-gnu-}
BUILD="$ROOT/build"
OBJ="$BUILD/m3_0-reset.o"
ELF="$BUILD/librom-m3.0-macplus.elf"
ROM="$BUILD/librom-m3.0-macplus.bin"
MAP="$BUILD/librom-m3.0-macplus.map"

mkdir -p "$BUILD"

python3 "$ROOT/scripts/check_m3_0.py"
"${CROSS}as" -m68000 -o "$OBJ" "$ROOT/src/platform/macplus/reset_m3_0.S"
"${CROSS}ld" -T "$ROOT/linker/m3_0.ld" -Map="$MAP" -o "$ELF" "$OBJ"
"${CROSS}objcopy" -O binary --gap-fill=0xff "$ELF" "$ROM"
python3 "$ROOT/scripts/pad_rom.py" "$ROM" 131072

bash "$ROOT/scripts/qualify_m3_0_runtime.sh" "$ROM"

echo "LibreROM M3.0 qualification: PASS"
