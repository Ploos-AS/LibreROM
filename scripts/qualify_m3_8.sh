#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CROSS=${CROSS:-m68k-elf-}
BUILD="$ROOT/build"
OBJ="$BUILD/m3_8-reset.o"
ELF="$BUILD/librom-m3.8-macplus.elf"
ROM="$BUILD/librom-m3.8-macplus.bin"
MAP="$BUILD/librom-m3.8-macplus.map"
MUSASHI_COMMIT=313ebf1bd9f4d0d93341eb5ce21fd8a119e9dbdd
WORK="$BUILD/m3_8-runtime"
SRC="$WORK/Musashi"
BIN="$WORK/librerom-m3_8-runtime"
EVIDENCE="$WORK/runtime.txt"

mkdir -p "$BUILD"
python3 "$ROOT/scripts/check_m3_8.py"
"${CROSS}as" -m68000 -o "$OBJ" "$ROOT/src/platform/macplus/reset_m3_8.S"
"${CROSS}ld" -T "$ROOT/linker/m3_8.ld" -Map="$MAP" -o "$ELF" "$OBJ"
"${CROSS}objcopy" -O binary --gap-fill=0xff "$ELF" "$ROM"
python3 "$ROOT/scripts/pad_rom.py" "$ROM" 131072

rm -rf "$WORK"
mkdir -p "$WORK"
git clone --quiet https://github.com/kstenerud/Musashi.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$MUSASHI_COMMIT"
make -C "$SRC" -s all
gcc -std=c11 -Wall -Wextra -Werror -O2 -I"$SRC" \
  "$ROOT/tests/m3_8_runtime.c" \
  "$SRC/m68kcpu.o" "$SRC/m68kops.o" "$SRC/softfloat/softfloat.o" \
  -lm -o "$BIN"
"$BIN" "$ROM" | tee "$EVIDENCE"
{
  echo "musashi_commit=$MUSASHI_COMMIT"
  sha256sum "$ROM"
} >> "$EVIDENCE"
