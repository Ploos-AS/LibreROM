#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
profiles = root / 'profiles'
files = sorted(profiles.glob('*.json'))
if not files:
    raise SystemExit('FAIL: no model profiles found')

seen = set()
for path in files:
    p = json.loads(path.read_text(encoding='utf-8'))
    mid = p.get('id')
    if not mid or mid in seen:
        raise SystemExit(f'FAIL: invalid/duplicate model id in {path}')
    seen.add(mid)
    for key in ('display_name','family','cpu','rom_size','rom_base','current_source_milestone','current_source_rom','current_source_map','variant_rom','variant_map','status'):
        if key not in p:
            raise SystemExit(f'FAIL: {path}: missing {key}')
    if not p.get('preserve'):
        raise SystemExit(f'FAIL: {path}: preserve must be true')
    if not str(p['variant_rom']).startswith(f"build/variants/{mid}/"):
        raise SystemExit(f'FAIL: {path}: variant_rom must live under build/variants/{mid}/')

print('PASS: LibreROM persistent model profile invariants')
print('models=' + ','.join(sorted(seen)))
