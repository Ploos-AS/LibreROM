#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m3.0-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m3.0-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m3_0-pce"
SRC="$WORK/PCE"
CFG="$WORK/libre-rom-mac-plus.cfg"
TRANSCRIPT="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m3_0_stop" {print $1; exit}')
ALINE_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m3_0_aline" {print $1; exit}')
[ -n "$STOP_HEX" ] && [ -n "$ALINE_HEX" ] || { echo "M3.0 FAIL: symbols missing" >&2; exit 1; }
STOP_ADDR=$((16#$STOP_HEX))
ALINE_ADDR=$((16#$ALINE_HEX))

git clone --quiet https://github.com/notpeter/PCE.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$PCE_COMMIT"
(cd "$SRC" && ./autogen.sh && ./configure --with-sdl=no >/dev/null && make -s src/arch/macplus/pce-macplus)

cat > "$CFG" <<EOF
path = "$WORK"
system { model = "mac-plus" memtest = 0 }
cpu { model = "68000" speed = 0 }
ram { address = 0 size = 1M default = 0x00 }
rom { file = "$ROM" address = 0x400000 size = 128K default = 0xff }
terminal { driver = "null" }
sound { driver = "null" }
sony { enable = 0 }
EOF

{
    printf 'g b %X\n' "$STOP_ADDR"
    printf 'd 28 4\n'
    printf 'd 400 18\n'
    printf 's cpu\n'
    printf 'm emu.exit\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1

cat "$TRANSCRIPT"

grep -Eq '00000400.*4D 33 30 30.*4F 4B 33 30.*50 52 33 30.*44 53 50 30' "$TRANSCRIPT" || { echo "M3.0 FAIL: dispatch markers missing" >&2; exit 1; }
if grep -Eq '00000410.*42 41 44 30' "$TRANSCRIPT"; then
    echo "M3.0 FAIL: private A-line trap rejected" >&2
    exit 1
fi

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'aline_handler=0x%X\n' "$ALINE_ADDR"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "aline_vector=10"
    echo "aline_vector_offset=0x28"
    echo "qualification_trap=0xA0F0"
    sha256sum "$ROM"
    echo "LibreROM M3.0 PCE qualification: PASS"
} | tee -a "$TRANSCRIPT"
