#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.4-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.4-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_5-pce"
SRC="$WORK/PCE"
CFG="$WORK/libre-rom-mac-plus.cfg"
TRANSCRIPT="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

if [ ! -f "$ROM" ] || [ ! -f "$ELF" ]; then
    echo "M2.5 FAIL: missing M2.4 ROM/ELF" >&2
    exit 1
fi

if [ "$(stat -c %s "$ROM")" -ne 131072 ]; then
    echo "M2.5 FAIL: ROM must be exactly 131072 bytes" >&2
    exit 1
fi

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_4_stop" {print $1; exit}')
if [ -z "$STOP_HEX" ]; then
    echo "M2.5 FAIL: _m2_4_stop symbol not found" >&2
    exit 1
fi
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
    # PCE has a dedicated Mac monitor command for running until a CPU
    # exception. TRAP #0 is exception vector 32, so stop there rather than
    # relying on an address breakpoint at the subsequent STOP instruction.
    printf 'g e 20\n'
    # Execute the two handler instructions which write the EXC4 marker, but
    # deliberately do not execute the STOP at _m2_4_stop.
    printf 'p 2\n'
    printf 'd 400 8\n'
    printf 's cpu\n'
    printf 's via\n'
    printf 'q\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1 || {
    rc=$?
    cat "$TRANSCRIPT" >&2 || true
    echo "M2.5 FAIL: PCE exited with status $rc" >&2
    exit 1
}

cat "$TRANSCRIPT"

if ! grep -Eq '00000400[[:space:]]+4C 52 4D 34[[:space:]]+45 58 43 34' "$TRANSCRIPT"; then
    echo "M2.5 FAIL: PCE did not observe LRM4/EXC4 in low RAM" >&2
    exit 1
fi

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    sha256sum "$ROM"
    echo "LibreROM M2.5 PCE qualification: PASS"
} | tee -a "$TRANSCRIPT"
