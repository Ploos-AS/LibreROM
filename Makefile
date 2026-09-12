CROSS ?= m68k-elf-
AS := $(CROSS)as
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
OBJ := $(BUILD)/reset.o
ELF := $(BUILD)/librom-m1.elf
ROM := $(BUILD)/librom-m1.bin
MAP := $(BUILD)/librom-m1.map

.PHONY: all check check-m2 check-m2_1 qualify-m1 qualify-m1-runtime qualify-m2_1 clean

all: $(ROM)

$(BUILD):
	mkdir -p $(BUILD)

$(OBJ): src/arch/m68k/reset.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(ELF): $(OBJ) linker/m1.ld
	$(LD) -T linker/m1.ld -Map=$(MAP) -o $@ $(OBJ)

$(ROM): $(ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 65536

check:
	$(PYTHON) scripts/check_m0.py
	$(PYTHON) scripts/check_m1.py
	$(PYTHON) scripts/check_m2.py
	$(PYTHON) scripts/check_m2_1.py

check-m2:
	$(PYTHON) scripts/check_m2.py

check-m2_1:
	$(PYTHON) scripts/check_m2_1.py

qualify-m1: $(ROM)
	$(PYTHON) scripts/qualify_m1.py $(ROM)
	bash scripts/qualify_m1_runtime.sh $(ROM)

qualify-m1-runtime: $(ROM)
	bash scripts/qualify_m1_runtime.sh $(ROM)

qualify-m2_1:
	$(PYTHON) scripts/check_m2_1.py
	$(PYTHON) tests/m2_1_overlay_model.py

clean:
	rm -rf $(BUILD)
