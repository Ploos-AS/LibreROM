#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ROM=${1:-"$ROOT/build/librom-m2.10-macplus.bin"}
ELF=${2:-"$ROOT/build/librom-m2.10-macplus.elf"}
PCE_COMMIT=371414f8f41ae02e9ce36004ba7b076fdd3abe63
WORK="$ROOT/build/m2_10-pce"
SRC="$WORK/PCE"
DISK="$WORK/test-disk.img"
CFG_EMPTY="$WORK/libre-rom-iwm-empty.cfg"
CFG_MEDIA="$WORK/libre-rom-iwm-media.cfg"
EMPTY_TRANSCRIPT="$WORK/empty-runtime.txt"
MEDIA_TRANSCRIPT="$WORK/media-runtime.txt"

rm -rf "$WORK"
mkdir -p "$WORK"

[ -f "$ROM" ] || exit 1
[ -f "$ELF" ] || exit 1
[ "$(stat -c %s "$ROM")" -eq 131072 ] || exit 1

STOP_HEX=$(${CROSS:-m68k-linux-gnu-}nm -n "$ELF" | awk '$3 == "_m2_10_stop" {print $1; exit}')
[ -n "$STOP_HEX" ] || exit 1
STOP_ADDR=$((16#$STOP_HEX))

truncate -s 409600 "$DISK"
printf 'LIBREROM-IWM-M10' | dd of="$DISK" conv=notrunc status=none

git clone --quiet https://github.com/notpeter/PCE.git "$SRC"
git -C "$SRC" checkout --quiet --detach "$PCE_COMMIT"
(cd "$SRC" && ./autogen.sh && ./configure --with-sdl=no >/dev/null && make -s src/arch/macplus/pce-macplus)

write_cfg() {
    local cfg=$1
    local inserted=$2
    cat > "$cfg" <<EOF
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
    inserted     = $inserted
    single_sided = 1
    auto_rotate  = 1
  }
}
disk {
  drive    = 1
  type     = "auto"
  file     = "$DISK"
  optional = 0
}
EOF
}

run_case() {
    local cfg=$1
    local transcript=$2
    {
        printf 'g b %X\n' "$STOP_ADDR"
        printf 'd 400 30\n'
        printf 'd 420 10\n'
        printf 's cpu via\n'
        printf 'm emu.exit\n'
    } | timeout 30 "$SRC/src/arch/macplus/pce-macplus" -q -c "$cfg" -t null >"$transcript" 2>&1
}

write_cfg "$CFG_EMPTY" 0
write_cfg "$CFG_MEDIA" 1
run_case "$CFG_EMPTY" "$EMPTY_TRANSCRIPT"
run_case "$CFG_MEDIA" "$MEDIA_TRANSCRIPT"

cat "$EMPTY_TRANSCRIPT"
cat "$MEDIA_TRANSCRIPT"

grep -Eq '00000420.*49 4E 31 30' "$EMPTY_TRANSCRIPT"
grep -Eq '00000420.*49 57 4D 4E.*49 57 4D 30' "$EMPTY_TRANSCRIPT"
grep -Eq '00000420.*49 4E 31 30' "$MEDIA_TRANSCRIPT"
grep -Eq '00000420.*49 57 4D 50.*49 57 4D 30' "$MEDIA_TRANSCRIPT"

{
    echo "pce_commit=$PCE_COMMIT"
    printf 'stop_address=0x%X\n' "$STOP_ADDR"
    echo "iwm_status_address=0x00C01A01"
    echo "iwm_q7_low_address=0x00C01C01"
    echo "sense_bank=8"
    sha256sum "$ROM" "$DISK"
    echo "LibreROM M2.10 PCE qualification: PASS"
} | tee "$WORK/runtime.txt"
