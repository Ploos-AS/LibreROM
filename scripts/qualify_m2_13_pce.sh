#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.13-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.13-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_13-pce"
SRC="$WORK/PCE"
DISK="$WORK/test-disk.psi"
PAYLOAD="$WORK/sector0.bin"
CFG="$WORK/libre-rom-sector-loader.cfg"
TRANSCRIPT="$WORK/runtime-transcript.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

[ -f "$ROM" ] || exit 1
[ -f "$ELF" ] || exit 1
[ "$(stat -c %s "$ROM")" -eq 131072 ] || exit 1

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_13_stop" {print $1; exit}')
[ -n "$STOP_HEX" ] || exit 1
STOP_ADDR=$((16#$STOP_HEX))

git clone --quiet https://github.com/notpeter/PCE.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$PCE_COMMIT"
(cd "$SRC" && ./autogen.sh && ./configure --with-sdl=no >/dev/null && make -s src/arch/macplus/pce-macplus src/utils/psi/psi)

# Project-owned sector 0 payload: LR13 + entry + tiny 68000 proof code.
# ROM writes XFR3 at 0x448 immediately before JMP; payload writes BT13 at
# 0x44c so both proof markers remain independently observable afterwards.
python3 - "$PAYLOAD" <<'PYFIX'
from pathlib import Path
import struct, sys
p = Path(sys.argv[1])
buf = bytearray(512)
buf[0:4] = b"LR13"
buf[4:8] = struct.pack(">I", 0x00002010)
buf[8:16] = b"BOOT13\0\0"
code = bytes.fromhex("20 7c 00 00 04 4c 20 bc 42 54 31 33 4e 72 27 00")
buf[16:16+len(code)] = code
for i in range(16 + len(code), 512):
    buf[i] = (i * 37 + 0x13) & 0xff
p.write_bytes(buf)
PYFIX
[ "$(stat -c %s "$PAYLOAD")" -eq 512 ] || exit 1

# Create a clean 400 KiB Macintosh sector image, select only c0/h0/s0, and
# load our 512-byte payload into that sector. No Apple media is involved.
"$SRC/src/utils/psi/psi" -N mac 400 -r 0 0 0 -p load "$PAYLOAD" -O psi -o "$DISK"
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
    printf 'g b 201C\n'
    printf 'd 420 30\n'
    printf 'd 800 30\n'
    printf 'd A00 10\n'
    printf 'd 1000 30\n'
    printf 'd 1200 10\n'
    printf 'd 2000 40\n'
    printf 's cpu via\n'
    printf 'q\n'
} | timeout 40 "$SRC/src/arch/macplus/pce-macplus" -q -c "$CFG" -t null >"$TRANSCRIPT" 2>&1

cat "$TRANSCRIPT"

! grep -q 'loading drive 1 failed' "$TRANSCRIPT"
grep -Eq '00000420.*49 4E 31 32' "$TRANSCRIPT"
grep -Eq '00000420.*49 57 4D 50.*49 57 4D 32' "$TRANSCRIPT"
grep -Eq '00000440.*53 45 43 32.*43 48 4B 32' "$TRANSCRIPT"
! grep -Eq '00000440.*46 41 49 32' "$TRANSCRIPT"
grep -Eq '00002000.*4C 52 31 33 00 00 20 10' "$TRANSCRIPT"
grep -Eq '00000440.*58 46 52 33.*42 54 31 33' "$TRANSCRIPT"
grep -Eq 'PC=0000201C' "$TRANSCRIPT"

{
    echo "pce_commit=$PCE_COMMIT"
    echo "payload_entry=0x00002010"
    echo "payload_stop=0x0000201C"
    echo "fixture_type=psi"
    echo "fixture_geometry=mac-400-single-sided"
    echo "fixture_sector=c0/h0/s0"
    echo "payload_address=0x00002000"
    echo "payload_bytes=512"
    echo "payload_marker=LR13"
    echo "transfer_marker=XFR3@0x00000448"
    echo "payload_proof=BT13@0x0000044c"
    echo "success_markers=SEC2/CHK2"
    sha256sum "$ROM" "$DISK" "$PAYLOAD"
    echo "LibreROM M2.13 PCE boot-transfer qualification: PASS"
} | tee "$WORK/runtime.txt"
