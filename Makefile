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

.PHONY: all check qualify-m1 clean

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

qualify-m1: $(ROM)
	$(PYTHON) scripts/qualify_m1.py $(ROM)

clean:
	rm -rf $(BUILD)
