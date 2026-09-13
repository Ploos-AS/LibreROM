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

M2_3_OBJ := $(BUILD)/m2_3-reset.o
M2_3_ELF := $(BUILD)/librom-m2.3-macplus.elf
M2_3_ROM := $(BUILD)/librom-m2.3-macplus.bin
M2_3_MAP := $(BUILD)/librom-m2.3-macplus.map

M2_4_OBJ := $(BUILD)/m2_4-reset.o
M2_4_ELF := $(BUILD)/librom-m2.4-macplus.elf
M2_4_ROM := $(BUILD)/librom-m2.4-macplus.bin
M2_4_MAP := $(BUILD)/librom-m2.4-macplus.map

.PHONY: all check check-m2 check-m2_1 check-m2_2 check-m2_3 check-m2_4 qualify-m1 qualify-m1-runtime qualify-m2_1 qualify-m2_2 qualify-m2_3 qualify-m2_4 clean

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

$(M2_3_OBJ): src/platform/macplus/reset_m2_3.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_3_ELF): $(M2_3_OBJ) linker/m2_3.ld
	$(LD) -T linker/m2_3.ld -Map=$(M2_3_MAP) -o $@ $(M2_3_OBJ)

$(M2_3_ROM): $(M2_3_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_4_OBJ): src/platform/macplus/reset_m2_4.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_4_ELF): $(M2_4_OBJ) linker/m2_4.ld
	$(LD) -T linker/m2_4.ld -Map=$(M2_4_MAP) -o $@ $(M2_4_OBJ)

$(M2_4_ROM): $(M2_4_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

check:
	$(PYTHON) scripts/check_m0.py
	$(PYTHON) scripts/check_m1.py
	$(PYTHON) scripts/check_m2.py
	$(PYTHON) scripts/check_m2_1.py
	$(PYTHON) scripts/check_m2_2.py
	$(PYTHON) scripts/check_m2_3.py
	$(PYTHON) scripts/check_m2_4.py

check-m2:
	$(PYTHON) scripts/check_m2.py

check-m2_1:
	$(PYTHON) scripts/check_m2_1.py

check-m2_2:
	$(PYTHON) scripts/check_m2_2.py

check-m2_3:
	$(PYTHON) scripts/check_m2_3.py

check-m2_4:
	$(PYTHON) scripts/check_m2_4.py

qualify-m1: $(ROM)
	$(PYTHON) scripts/qualify_m1.py $(ROM)
	bash scripts/qualify_m1_runtime.sh $(ROM)

qualify-m1-runtime: $(ROM)
	bash scripts/qualify_m1_runtime.sh $(ROM)

qualify-m2_1:
	$(PYTHON) scripts/check_m2_1.py
	$(PYTHON) tests/m2_1_overlay_model.py

qualify-m2_2:
	$(PYTHON) scripts/check_m2_2.py

qualify-m2_3: $(M2_3_ROM)
	$(PYTHON) scripts/check_m2_3.py
	bash scripts/qualify_m2_3_runtime.sh $(M2_3_ROM)

qualify-m2_4: $(M2_4_ROM)
	$(PYTHON) scripts/check_m2_4.py
	bash scripts/qualify_m2_4_runtime.sh $(M2_4_ROM)

clean:
	rm -rf $(BUILD)
