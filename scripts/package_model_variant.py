#!/usr/bin/env python3
import argparse
import hashlib
import json
import shutil
from pathlib import Path


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('profile')
    args = ap.parse_args()

    root = Path(__file__).resolve().parent.parent
    profile_path = root / args.profile
    profile = json.loads(profile_path.read_text(encoding='utf-8'))

    src_rom = root / profile['current_source_rom']
    src_map = root / profile['current_source_map']
    dst_rom = root / profile['variant_rom']
    dst_map = root / profile['variant_map']

    if not src_rom.is_file():
        raise SystemExit(f"missing qualified source ROM: {src_rom}")
    if src_rom.stat().st_size != int(profile['rom_size']):
        raise SystemExit(f"unexpected ROM size: {src_rom.stat().st_size}")
    if not src_map.is_file():
        raise SystemExit(f"missing qualified source map: {src_map}")

    dst_rom.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src_rom, dst_rom)
    shutil.copyfile(src_map, dst_map)

    manifest = {
        'schema': 1,
        'model_id': profile['id'],
        'display_name': profile['display_name'],
        'family': profile['family'],
        'cpu': profile['cpu'],
        'rom_size': profile['rom_size'],
        'rom_base': profile['rom_base'],
        'source_milestone': profile['current_source_milestone'],
        'source_rom': profile['current_source_rom'],
        'variant_rom': profile['variant_rom'],
        'sha256': sha256(dst_rom),
        'preserve': bool(profile.get('preserve', False)),
        'status': profile['status'],
    }
    manifest_path = dst_rom.parent / 'manifest.json'
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n', encoding='utf-8')

    print(f"PASS: packaged {profile['id']} -> {dst_rom.relative_to(root)}")
    print(f"sha256={manifest['sha256']}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
