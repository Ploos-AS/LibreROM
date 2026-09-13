#!/usr/bin/env python3
from pathlib import Path
import shutil

COPIES = {
    'src/platform/macplus/reset_m2_12.S': 'src/platform/macplus/reset_m2_13.S',
    'linker/m2_12.ld': 'linker/m2_13.ld',
    'scripts/check_m2_12.py': 'scripts/check_m2_13.py',
    'scripts/qualify_m2_12.sh': 'scripts/qualify_m2_13.sh',
    'scripts/qualify_m2_12_pce.sh': 'scripts/qualify_m2_13_pce.sh',
    'docs/M2_12_GCR_SECTOR_QUALIFICATION.md': 'docs/M2_13_BOOT_TRANSFER_QUALIFICATION.md',
}
for src, dst in COPIES.items():
    shutil.copyfile(src, dst)
    p = Path(dst)
    s = p.read_text().replace('m2_12', 'm2_13').replace('M2_12', 'M2_13')
    s = s.replace('M2.12', 'M2.13').replace('m2.12', 'm2.13')
    p.write_text(s)

# Firmware delta: LR13 + validated entry + cleanup + transfer marker + JMP.
p = Path('src/platform/macplus/reset_m2_13.S')
s = p.read_text()
s = s.replace('cmpi.l  #0x4c523132,(%a0)       /* fixture begins LR12 */',
              'cmpi.l  #0x4c523133,(%a0)       /* fixture begins LR13 */')
s = s.replace('''        move.l  #0x00000444,%a0
        move.l  #0x43484b32,(%a0)       /* CHK2 */
        bra.s   _m2_13_read_done
''', '''        move.l  #0x00000444,%a0
        move.l  #0x43484b32,(%a0)       /* CHK2 */
        bra.w   _m2_13_transfer
''', 1)
transfer = '''/* M2.13: validate project-owned boot header and transfer control to RAM. */
_m2_13_transfer:
        move.l  #0x0000042c,%a0
        move.l  #0x49574d32,(%a0)       /* IWM2 */
        move.b  0x00c01001,%d0
        move.b  0x00c00001,%d0
        move.b  0x00c00601,%d0
        move.b  0x00c00a01,%d0
        move.b  0x00c00e01,%d0
        move.b  0x00c00c01,%d0
        move.l  #0x00efe600,%a0
        move.b  %d6,(%a0)
        move.l  #0x00002000,%a0
        move.l  4(%a0),%d0
        cmpi.l  #0x00002010,%d0
        bne.w   _m2_13_payload_fail
        move.l  %d0,%a1
        move.l  #0x00000448,%a0
        move.l  #0x58465233,(%a0)       /* XFR3 */
        jmp     (%a1)

'''
needle = '_m2_13_checksum_fail:\n'
if needle not in s:
    raise SystemExit('checksum label missing')
s = s.replace(needle, transfer + needle, 1)
p.write_text(s)

# Static checker additions.
p = Path('scripts/check_m2_13.py')
s = p.read_text()
s = s.replace('"fixture-marker": "0x4c523132",',
              '"fixture-marker": "0x4c523133",\n    "boot-entry": "0x00002010",\n    "transfer-marker": "XFR3",')
s = s.replace('"qualification-fixture": "sector0.bin",',
              '"qualification-fixture": "sector0.bin",\n    "qualification-proof": "BT13",')
s = s.replace('PASS: LibreROM M2.13 GCR sector-loader invariants',
              'PASS: LibreROM M2.13 GCR boot-transfer invariants')
p.write_text(s)

# PCE project-owned executable sector fixture.
p = Path('scripts/qualify_m2_13_pce.sh')
s = p.read_text()
start = s.index('# Project-owned sector 0 payload.')
end = s.index('# Create a clean 400 KiB Macintosh sector image', start)
lines = [
    '# Project-owned sector 0 payload: LR13 + entry + tiny 68000 proof code.',
    'python3 - "$PAYLOAD" <<\'PYFIX\'',
    'from pathlib import Path',
    'import struct, sys',
    'p = Path(sys.argv[1])',
    'buf = bytearray(512)',
    'buf[0:4] = b"LR13"',
    'buf[4:8] = struct.pack(">I", 0x00002010)',
    'buf[8:16] = b"BOOT13\\0\\0"',
    'code = bytes.fromhex("20 7c 00 00 04 48 20 bc 42 54 31 33 4e 72 27 00")',
    'buf[16:16+len(code)] = code',
    'for i in range(16 + len(code), 512):',
    '    buf[i] = (i * 37 + 0x13) & 0xff',
    'p.write_bytes(buf)',
    'PYFIX',
    '[ "$(stat -c %s "$PAYLOAD")" -eq 512 ] || exit 1',
    '',
]
s = s[:start] + '\n'.join(lines) + '\n' + s[end:]
s = s.replace("    printf 'g b %X\\n' \"$STOP_ADDR\"", "    printf 'g b 201C\\n'")
s = s.replace("grep -Eq '00002000.*4C 52 31 32 42 4F 4F 54' \"$TRANSCRIPT\"",
              "grep -Eq '00002000.*4C 52 31 33 00 00 20 10' \"$TRANSCRIPT\"\ngrep -Eq '00000440.*58 46 52 33.*42 54 31 33' \"$TRANSCRIPT\"")
s = s.replace("    printf 'stop_address=0x%X\\n' \"$STOP_ADDR\"", "    echo \"payload_entry=0x00002010\"\n    echo \"payload_stop=0x0000201C\"")
s = s.replace('echo "payload_marker=LR12BOOT"', 'echo "payload_marker=LR13"\n    echo "transfer_marker=XFR3"\n    echo "payload_proof=BT13"')
s = s.replace('echo "LibreROM M2.13 PCE qualification: PASS"', 'echo "LibreROM M2.13 PCE boot-transfer qualification: PASS"')
p.write_text(s)

# Docs delta.
p = Path('docs/M2_13_BOOT_TRANSFER_QUALIFICATION.md')
p.write_text(p.read_text() + '''\n\n## M2.13 control-transfer delta\n\nM2.13 extends the qualified M2.12 sector loader with a minimal project-owned boot contract. Sector 0 begins with `LR13`, big-endian entry `0x00002010`, and project-owned 68000 code. After decode/checksum/copy, firmware validates the entry, stops IWM, restores VIA DDRA, writes `XFR3`, and jumps to RAM. The fixture writes `BT13` at `0x448` and executes `STOP #0x2700`; PCE breaks at `0x201c` and requires both markers. No Apple ROM, System software, boot block, or derived binary is used.\n''')

# Makefile first-class targets for M2.11-M2.13.
p = Path('Makefile')
s = p.read_text()
a = 'M2_10_MAP := $(BUILD)/librom-m2.10-macplus.map\n'
s = s.replace(a, a + '''\nM2_11_OBJ := $(BUILD)/m2_11-reset.o\nM2_11_ELF := $(BUILD)/librom-m2.11-macplus.elf\nM2_11_ROM := $(BUILD)/librom-m2.11-macplus.bin\nM2_11_MAP := $(BUILD)/librom-m2.11-macplus.map\nM2_12_OBJ := $(BUILD)/m2_12-reset.o\nM2_12_ELF := $(BUILD)/librom-m2.12-macplus.elf\nM2_12_ROM := $(BUILD)/librom-m2.12-macplus.bin\nM2_12_MAP := $(BUILD)/librom-m2.12-macplus.map\nM2_13_OBJ := $(BUILD)/m2_13-reset.o\nM2_13_ELF := $(BUILD)/librom-m2.13-macplus.elf\nM2_13_ROM := $(BUILD)/librom-m2.13-macplus.bin\nM2_13_MAP := $(BUILD)/librom-m2.13-macplus.map\n''', 1)
s = s.replace('check-m2_10 qualify-m1', 'check-m2_10 check-m2_11 check-m2_12 check-m2_13 qualify-m1')
s = s.replace('qualify-m2_9 qualify-m2_10 clean', 'qualify-m2_9 qualify-m2_10 qualify-m2_11 qualify-m2_12 qualify-m2_13 clean')
rule = '$(M2_10_ROM): $(M2_10_ELF)\n\t$(OBJCOPY) -O binary --gap-fill=0xff $< $@\n\t$(PYTHON) scripts/pad_rom.py $@ 131072\n'
s += '' if '$(M2_13_OBJ):' in s else ''
extra_rules = '''\n$(M2_11_OBJ): src/platform/macplus/reset_m2_11.S | $(BUILD)\n\t$(AS) -m68000 -o $@ $<\n$(M2_11_ELF): $(M2_11_OBJ) linker/m2_11.ld\n\t$(LD) -T linker/m2_11.ld -Map=$(M2_11_MAP) -o $@ $(M2_11_OBJ)\n$(M2_11_ROM): $(M2_11_ELF)\n\t$(OBJCOPY) -O binary --gap-fill=0xff $< $@\n\t$(PYTHON) scripts/pad_rom.py $@ 131072\n$(M2_12_OBJ): src/platform/macplus/reset_m2_12.S | $(BUILD)\n\t$(AS) -m68000 -o $@ $<\n$(M2_12_ELF): $(M2_12_OBJ) linker/m2_12.ld\n\t$(LD) -T linker/m2_12.ld -Map=$(M2_12_MAP) -o $@ $(M2_12_OBJ)\n$(M2_12_ROM): $(M2_12_ELF)\n\t$(OBJCOPY) -O binary --gap-fill=0xff $< $@\n\t$(PYTHON) scripts/pad_rom.py $@ 131072\n$(M2_13_OBJ): src/platform/macplus/reset_m2_13.S | $(BUILD)\n\t$(AS) -m68000 -o $@ $<\n$(M2_13_ELF): $(M2_13_OBJ) linker/m2_13.ld\n\t$(LD) -T linker/m2_13.ld -Map=$(M2_13_MAP) -o $@ $(M2_13_OBJ)\n$(M2_13_ROM): $(M2_13_ELF)\n\t$(OBJCOPY) -O binary --gap-fill=0xff $< $@\n\t$(PYTHON) scripts/pad_rom.py $@ 131072\n'''
if '$(M2_13_OBJ):' not in s:
    s = s.replace(rule, rule + extra_rules, 1)
s = s.replace('\t$(PYTHON) scripts/check_m2_10.py\n\ncheck-m2:', '\t$(PYTHON) scripts/check_m2_10.py\n\t$(PYTHON) scripts/check_m2_11.py\n\t$(PYTHON) scripts/check_m2_12.py\n\t$(PYTHON) scripts/check_m2_13.py\n\ncheck-m2:', 1)
s = s.replace('check-m2_10:\n\t$(PYTHON) scripts/check_m2_10.py\n', 'check-m2_10:\n\t$(PYTHON) scripts/check_m2_10.py\n\ncheck-m2_11:\n\t$(PYTHON) scripts/check_m2_11.py\n\ncheck-m2_12:\n\t$(PYTHON) scripts/check_m2_12.py\n\ncheck-m2_13:\n\t$(PYTHON) scripts/check_m2_13.py\n', 1)
q = 'qualify-m2_10: $(M2_10_ROM) $(M2_10_ELF)\n\t$(PYTHON) scripts/check_m2_10.py\n\tCROSS=$(CROSS) bash scripts/qualify_m2_10_pce.sh $(M2_10_ROM) $(M2_10_ELF)\n'
s = s.replace(q, q + '''\nqualify-m2_11: $(M2_11_ROM) $(M2_11_ELF)\n\t$(PYTHON) scripts/check_m2_11.py\n\tCROSS=$(CROSS) bash scripts/qualify_m2_11_pce.sh $(M2_11_ROM) $(M2_11_ELF)\nqualify-m2_12: $(M2_12_ROM) $(M2_12_ELF)\n\t$(PYTHON) scripts/check_m2_12.py\n\tCROSS=$(CROSS) bash scripts/qualify_m2_12_pce.sh $(M2_12_ROM) $(M2_12_ELF)\nqualify-m2_13: $(M2_13_ROM) $(M2_13_ELF)\n\t$(PYTHON) scripts/check_m2_13.py\n\tCROSS=$(CROSS) bash scripts/qualify_m2_13_pce.sh $(M2_13_ROM) $(M2_13_ELF)\n''', 1)
p.write_text(s)

# CI.
p = Path('.github/workflows/ci.yml')
s = p.read_text().replace('run: CROSS=m68k-linux-gnu- bash scripts/qualify_m2_11.sh', 'run: make CROSS=m68k-linux-gnu- qualify-m2_11')
s = s.replace('run: CROSS=m68k-linux-gnu- bash scripts/qualify_m2_12.sh', 'run: make CROSS=m68k-linux-gnu- qualify-m2_12')
needle = '      - name: Qualify M2.12 GCR sector-0 loader\n        run: make CROSS=m68k-linux-gnu- qualify-m2_12\n'
s = s.replace(needle, needle + '\n      - name: Qualify M2.13 loaded boot control transfer\n        run: make CROSS=m68k-linux-gnu- qualify-m2_13\n', 1)
a = '            build/m2_12-pce/sector0.bin\n'
s = s.replace(a, a + '''            build/librom-m2.13-macplus.bin\n            build/librom-m2.13-macplus.map\n            build/m2_13-pce/libre-rom-sector-loader.cfg\n            build/m2_13-pce/runtime-transcript.txt\n            build/m2_13-pce/runtime.txt\n            build/m2_13-pce/test-disk.psi\n            build/m2_13-pce/sector0.bin\n''', 1)
p.write_text(s)
