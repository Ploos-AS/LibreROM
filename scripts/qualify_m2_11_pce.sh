#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.11-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.11-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_11-pce"
SRC="$WORK/PCE"
DISK="$WORK/test-disk.psi"
CFG="$WORK/libre-rom-iwm-read.cfg"
TRANSCRIPT="$WORK/runtime-transcript.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

[ -f "$ROM" ] || exit 1
[ -f "$ELF" ] || exit 1
[ "$(stat -c %s "$ROM")" -eq 131072 ] || exit 1

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_11_stop" {print $1; exit}')
[ -n "$STOP_HEX" ] || exit 1
STOP_ADDR=$((16#$STOP_HEX))

git clone --quiet https://github.com/notpeter/PCE.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$PCE_COMMIT"
(cd "$SRC" && ./autogen.sh && ./configure --with-sdl=no >/dev/null && make -s src/arch/macplus/pce-macplus src/utils/psi/psi)

# Project-owned 400 KiB single-sided Macintosh PSI fixture. No Apple ROM or
# System software is present; PCE converts the sector image to a GCR track.
"$SRC/src/utils/psi/psi" -N mac 400 -O psi -o "$DISK"
[ -s "$DISK" ] || exit 1

cat > "$CFG" <<EOF
path = "$WORK"
system { model = "mac-plus" memtest = 0 }
cpu { model = "68000" speed = 0 }
ram { address = 0 size = 1M default = 0x00 }
rom { file = "$ROM" address = 0x400000 size = 128K default = 0xff }
terminal { driver = "null" }
sound { driver = "null" }
sony { enable = 0 }
iwm {
  drive {
    drive        = 1
    disk         = 1
    inserted     = 1
    single_sided = 1
    auto_rotate  = 1
  }
}
disk {
  drive    = 1
  type     = "psi"
  file     = "$DISK"
  readonly = 1
  optional = 0
}
EOF

{
    printf 'g b %X\n' "$STOP_ADDR"
    printf 'd 420 30\n'
    printf 'd 430 20\n'
    printf 's cpu via\n'
    printf 'q\n'
} | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1

cat "$TRANSCRIPT"

! grep -q 'loading drive 1 failed' "$TRANSCRIPT"
grep -Eq '00000420.*49 4E 31 31' "$TRANSCRIPT"
grep -Eq '00000420.*49 57 4D 50.*49 57 4D 31' "$TRANSCRIPT"
grep -Eq '00000440.*44 41 54 31' "$TRANSCRIPT"
! grep -Eq '00000440.*52 44 46 31' "$TRANSCRIPT"

# DAT1 is only written after firmware captured sixteen IWM data bytes whose
# high bit is set, so reaching it proves the motor/ENABLE/Q6/Q7 raw read path.
{
    echo "pce_commit=$PCE_COMMIT"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "fixture_type=psi"
    echo "fixture_geometry=mac-400-single-sided"
    echo "capture_address=0x00000430"
    echo "capture_bytes=16"
    echo "success_marker=DAT1"
    sha256sum "$ROM" "$DISK"
    echo "LibreROM M2.11 PCE qualification: PASS"
} | tee "$WORK/runtime.txt"
