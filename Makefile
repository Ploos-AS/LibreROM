PYTHON ?= python3

.PHONY: all check clean

all: check
	@mkdir -p build
	@printf 'LibreROM M0: no executable ROM image yet\n' > build/README.txt
	@printf 'M0 foundation complete. M1 will introduce the m68k ROM build.\n'

check:
	$(PYTHON) scripts/check_m0.py

clean:
	rm -rf build
