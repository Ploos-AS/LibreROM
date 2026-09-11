# Clean-room policy

LibreROM must be independently implementable and freely redistributable.

## Prohibited inputs

Do not contribute or use as implementation source material:

- Apple Macintosh ROM binaries or extracted ROM resources.
- Disassemblies, decompilations, annotated dumps, or copied code from Apple ROMs.
- Leaked or proprietary Apple source code.
- Tables, byte sequences, routines, comments, or data copied from copyrighted ROM material.
- Material whose license is incompatible with LibreROM's MIT-licensed source tree.

## Acceptable inputs

Contributors may use:

- Public hardware documentation and datasheets.
- Public API/ABI documentation.
- Independently written software and documentation with compatible licenses.
- Black-box observations of externally visible behavior, recorded as tests or behavioral specifications without copying implementation expression.
- Emulator and hardware experiments designed to establish observable compatibility requirements.

## Documentation discipline

When behavior is non-obvious, document the public or independently derived basis for the implementation in source comments or design notes.

Compatibility tests should describe inputs and observable outputs rather than reproduce ROM internals.

## Repository hygiene

Never commit ROM images or copyrighted firmware dumps, even for tests. Test fixtures must be project-authored, generated, or clearly redistributable.

If provenance is uncertain, do not commit the material until its suitability is established.
