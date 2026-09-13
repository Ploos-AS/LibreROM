#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.7-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.7-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_7-pce"
SRC="$WORK/PCE"
CFG="$WORK/libre-rom-mac-plus.cfg"
TRANSCRIPT="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

if [ ! -f "$ROM" ] || [ ! -f "$ELF" ]; then
    echo "M2.7 FAIL: missing M2.7 ROM/ELF" >&2
    exit 1
fi
if [ "$(stat -c %s "$ROM")" -ne 131072 ]; then
    echo "M2.7 FAIL: ROM must be exactly 131072 bytes" >&2
    exit 1
fi

BEFORE_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_7_before_overlay_off" {print $1; exit}')
STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_7_stop" {print $1; exit}')
if [ -z "$BEFORE_HEX" ] || [ -z "$STOP_HEX" ]; then
    echo "M2.7 FAIL: qualification symbols not found" >&2
    exit 1
fi
BEFORE_ADDR=$((16#$BEFORE_HEX))
STOP_ADDR=$((16#$STOP_HEX))

git clone --quiet https://github.com/notpeter/PCE.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$PCE_COMMIT"
(
    cd "$SRC"
    ./autogen.sh
    ./configure --with-sdl=no >/dev/null
    make -s src/arch/macplus/pce-macplus
)

cat > "$CFG" <<EOF
path = "$WORK"
system {
    model = "mac-plus"
    memtest = 0
}
cpu {
    model = "68000"
    speed = 0
}
ram {
    address = 0
    size = 1M
    default = 0x00
}
rom {
    file = "$ROM"
    address = 0x400000
    size = 128K
    default = 0xff
}
terminal {
    driver = "null"
}
sound {
    driver = "null"
}
sony {
    enable = 0
}
EOF

{
    printf 'g b %X\n' "$BEFORE_ADDR"
    printf 'd 600000 8\n'
    printf 'd 600400 12\n'

    printf 'g b %X\n' "$STOP_ADDR"
    printf 'd 0 8\n'
    printf 'd 400 16\n'
    printf 'd FA700 10\n'
    printf 'd F2700 10\n'
    printf 's cpu via\n'
    printf 'm emu.exit\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1 || {
    rc=$?
    cat "$TRANSCRIPT" >&2 || true
    echo "M2.7 FAIL: PCE exited with status $rc" >&2
    exit 1
}

cat "$TRANSCRIPT"

if ! grep -Eq '00600400.*50 52 45 37' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: PRE7 missing before overlay-off" >&2
    exit 1
fi
if ! grep -Eq '00600000[[:space:]]+00 10 00 00' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: reset SSP vector missing before overlay-off" >&2
    exit 1
fi
if ! grep -Eq '00000000[[:space:]]+00 10 00 00' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: low RAM vectors missing after overlay-off" >&2
    exit 1
fi
if ! grep -Eq '00000400.*4C 52 4D 37.*45 58 43 37.*50 52 45 37.*56 49 44 37' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: LRM7/EXC7/PRE7/VID7 continuity markers missing" >&2
    exit 1
fi
if ! grep -Eq '000FA700.*AA 55 AA 55' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: main framebuffer diagnostic pattern missing" >&2
    exit 1
fi
if ! grep -Eq '000F2700.*AA 55 AA 55' "$TRANSCRIPT"; then
    echo "M2.7 FAIL: alternate framebuffer diagnostic pattern missing" >&2
    exit 1
fi

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'before_overlay_off=0x%X\n' "$BEFORE_ADDR"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "main_framebuffer=0x000FA700"
    echo "alternate_framebuffer=0x000F2700"
    echo "framebuffer_bytes=21888"
    echo "marker=VID7"
    sha256sum "$ROM"
    echo "LibreROM M2.7 PCE qualification: PASS"
} | tee -a "$TRANSCRIPT"
