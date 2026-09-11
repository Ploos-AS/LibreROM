#!/usr/bin/env python3
from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: pad_rom.py IMAGE SIZE", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    target = int(sys.argv[2], 0)
    data = path.read_bytes()
    if len(data) > target:
        print(f"error: {path} is {len(data)} bytes, exceeds target {target}", file=sys.stderr)
        return 1
    if len(data) < target:
        path.write_bytes(data + b"\xff" * (target - len(data)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
