#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.8-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.8-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_8-pce"
SRC="$WORK/PCE"
CFG="$WORK/libre-rom-mac-plus.cfg"
TRANSCRIPT="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_8_stop" {print $1; exit}')
IRQ_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_8_via_irq" {print $1; exit}')
[ -n "$STOP_HEX" ] && [ -n "$IRQ_HEX" ] || { echo "M2.8 FAIL: symbols missing" >&2; exit 1; }
STOP_ADDR=$((16#$STOP_HEX))
IRQ_ADDR=$((16#$IRQ_HEX))

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
    printf 'd 400 18\n'
    printf 'd FA700 10\n'
    printf 'd F2700 10\n'
    printf 's cpu via\n'
    printf 'm emu.exit\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1

cat "$TRANSCRIPT"

grep -Eq '00000400.*4C 52 4D 38.*45 58 43 38.*50 52 45 38.*56 49 44 38.*49 52 51 38.*54 4D 52 38' "$TRANSCRIPT" || { echo "M2.8 FAIL: IRQ markers missing" >&2; exit 1; }
grep -Eq '000FA700.*AA 55 AA 55' "$TRANSCRIPT" || { echo "M2.8 FAIL: main framebuffer regression" >&2; exit 1; }
grep -Eq '000F2700.*AA 55 AA 55' "$TRANSCRIPT" || { echo "M2.8 FAIL: alternate framebuffer regression" >&2; exit 1; }
grep -Eq 'IFR=00[[:space:]]+IER=00[[:space:]]+IRQ=0' "$TRANSCRIPT" || { echo "M2.8 FAIL: VIA IRQ not clean after acknowledgement" >&2; exit 1; }

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'irq_handler=0x%X\n' "$IRQ_ADDR"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "via_timer1_ifr_bit=0x40"
    echo "cpu_interrupt_level=1"
    sha256sum "$ROM"
    echo "LibreROM M2.8 PCE qualification: PASS"
} | tee -a "$TRANSCRIPT"
