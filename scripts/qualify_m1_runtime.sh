#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m1.bin"}
MUSASHI_COMMIT=313ebf1bd9f4d0d93341eb5ce21fd8a119e9dbdd
WORK="$ROOT/build/m1-runtime"
SRC="$WORK/Musashi"
BIN="$WORK/libretos-m1-runtime"
EVIDENCE="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

git clone --quiet https://github.com/kstenerud/Musashi.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$MUSASHI_COMMIT"
make -C "$SRC" -s all

gcc -std=c11 -Wall -Wextra -Werror -O2 \
    -I"$SRC" \
    "$ROOT/tests/m1_runtime.c" \
    "$SRC/m68kcpu.o" "$SRC/m68kdasm.o" "$SRC/m68kops.o" "$SRC/softfloat/softfloat.o" \
    -lm -o "$BIN"

"$BIN" "$ROM" | tee "$EVIDENCE"
{
    echo "musashi_commit=$MUSASHI_COMMIT"
    sha256sum "$ROM"
} >> "$EVIDENCE"
