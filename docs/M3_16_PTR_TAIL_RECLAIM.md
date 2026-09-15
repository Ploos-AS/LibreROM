# M3.16 — Immediate Ptr tail reclamation

M3.16 extends the cumulative Memory Manager baseline with immediate reclamation when `_DisposePtr` releases the allocation at the physical heap tail.

## Scope

A Ptr remains non-relocatable while active. On disposal, LibreROM now computes the allocation end before deactivating its record. If that end equals `LR_HEAP_NEXT`, the heap cursor is rewound to the disposed Ptr start. Non-tail Ptr disposal remains a hole and is handled by the existing mixed Ptr/Handle compaction path when later Handle pressure requires it.

The behavior is intentionally conservative: it never moves a live Ptr and does not scan backward through arbitrary already-disposed records. Consecutive tail Ptrs are reclaimed naturally when callers dispose them from highest to lowest address.

## Runtime qualification

The deterministic 68000/Musashi fixture:

1. allocates a stable lower Handle leaving a 0x100-byte tail arena;
2. allocates a 0x20-byte Ptr followed by a 0xe0-byte Ptr, filling the heap exactly;
3. disposes the upper Ptr and verifies `LR_HEAP_NEXT` immediately rewinds from `0x80000` to `0x7ff20`;
4. disposes the newly exposed lower Ptr and verifies another immediate rewind to `0x7ff00`;
5. allocates a 0x100-byte Handle directly into the recovered space without requiring a compaction pass;
6. verifies the heap is full again, the new Handle data starts at `0x7ff00`, its payload is writable, and the stable lower Handle remains unchanged.

## Deliberate limits

M3.16 does not implement arbitrary backward coalescing of inactive Ptr records, multiple heap zones, grow-zone callbacks, full purge policy, or complete classic Macintosh zone semantics. Those remain later milestones.

The implementation remains clean-room and uses public observable behavior only; no Apple ROM code, disassembly, or derived implementation material is used.
