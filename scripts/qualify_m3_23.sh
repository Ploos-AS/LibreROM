#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CROSS=${CROSS:-m68k-elf-}
BUILD="$ROOT/build"
OBJ="$BUILD/m3_23-reset.o"; ELF="$BUILD/librom-m3.23-macplus.elf"; ROM="$BUILD/librom-m3.23-macplus.bin"; MAP="$BUILD/librom-m3.23-macplus.map"
mkdir -p "$BUILD"
python3 "$ROOT/tools/gen_m3_23.py"
python3 "$ROOT/scripts/check_m3_23.py"
"${CROSS}as" -m68000 -o "$OBJ" "$ROOT/build/generated/reset_m3_23.S"
"${CROSS}ld" -T "$ROOT/linker/m3_23.ld" -Map="$MAP" -o "$ELF" "$OBJ"
"${CROSS}objcopy" -O binary --gap-fill=0xff "$ELF" "$ROM"
python3 "$ROOT/scripts/pad_rom.py" "$ROM" 131072
echo "LibreROM M3.23 initial build qualification: PASS"
