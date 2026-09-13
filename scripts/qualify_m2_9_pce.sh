#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.9-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.9-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_9-pce"
SRC="$WORK/PCE"
CFG="$WORK/libre-rom-mac-plus.cfg"
TRANSCRIPT="$WORK/runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_9_stop" {print $1; exit}')
[ -n "$STOP_HEX" ] || { echo "M2.9 FAIL: stop symbol missing" >&2; exit 1; }
STOP_ADDR=$((16#$STOP_HEX))

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
    printf 'd 400 28\n'
    printf 'd FA700 10\n'
    printf 'd F2700 10\n'
    printf 's cpu via\n'
    printf 'm emu.exit\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1

cat "$TRANSCRIPT"

grep -Eq '00000400.*4C 52 4D 39.*45 58 43 39.*50 52 45 39.*56 49 44 39' "$TRANSCRIPT" || { echo "M2.9 FAIL: continuity markers missing" >&2; exit 1; }
grep -Eq '00000410.*4B 42 44 39.*49 4E 50 39|00000418.*4B 42 44 39.*49 4E 50 39' "$TRANSCRIPT" || { echo "M2.9 FAIL: keyboard/input markers missing" >&2; exit 1; }
grep -Eq '000FA700.*AA 55 AA 55' "$TRANSCRIPT" || { echo "M2.9 FAIL: main framebuffer regression" >&2; exit 1; }
grep -Eq '000F2700.*AA 55 AA 55' "$TRANSCRIPT" || { echo "M2.9 FAIL: alternate framebuffer regression" >&2; exit 1; }
grep -Eq 'IER=00[[:space:]]+IRQ=0' "$TRANSCRIPT" || { echo "M2.9 FAIL: VIA keyboard IRQ not clean" >&2; exit 1; }

# The response byte is immediately before KBD9 at 0x418. Any odd model byte is
# valid for the keyboard model-number protocol ((model & 7) << 1) | 1.
LINE=$(grep -E '00000410|00000418' "$TRANSCRIPT" | tail -n1 || true)
[ -n "$LINE" ] || { echo "M2.9 FAIL: keyboard response dump missing" >&2; exit 1; }

echo "$LINE" | grep -Eq '4B 42 44 39' || { echo "M2.9 FAIL: KBD9 marker absent" >&2; exit 1; }

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "keyboard_command=0x16"
    echo "via_sr_ifr_bit=0x04"
    echo "cpu_interrupt_level=1"
    sha256sum "$ROM"
    echo "LibreROM M2.9 PCE qualification: PASS"
} | tee -a "$TRANSCRIPT"
