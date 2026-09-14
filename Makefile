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

M2_6_OBJ := $(BUILD)/m2_6-reset.o
M2_6_ELF := $(BUILD)/librom-m2.6-macplus.elf
M2_6_ROM := $(BUILD)/librom-m2.6-macplus.bin
M2_6_MAP := $(BUILD)/librom-m2.6-macplus.map

M2_7_OBJ := $(BUILD)/m2_7-reset.o
M2_7_ELF := $(BUILD)/librom-m2.7-macplus.elf
M2_7_ROM := $(BUILD)/librom-m2.7-macplus.bin
M2_7_MAP := $(BUILD)/librom-m2.7-macplus.map

M2_8_OBJ := $(BUILD)/m2_8-reset.o
M2_8_ELF := $(BUILD)/librom-m2.8-macplus.elf
M2_8_ROM := $(BUILD)/librom-m2.8-macplus.bin
M2_8_MAP := $(BUILD)/librom-m2.8-macplus.map

M2_9_OBJ := $(BUILD)/m2_9-reset.o
M2_9_ELF := $(BUILD)/librom-m2.9-macplus.elf
M2_9_ROM := $(BUILD)/librom-m2.9-macplus.bin
M2_9_MAP := $(BUILD)/librom-m2.9-macplus.map

M2_10_OBJ := $(BUILD)/m2_10-reset.o
M2_10_ELF := $(BUILD)/librom-m2.10-macplus.elf
M2_10_ROM := $(BUILD)/librom-m2.10-macplus.bin
M2_10_MAP := $(BUILD)/librom-m2.10-macplus.map

M2_11_OBJ := $(BUILD)/m2_11-reset.o
M2_11_ELF := $(BUILD)/librom-m2.11-macplus.elf
M2_11_ROM := $(BUILD)/librom-m2.11-macplus.bin
M2_11_MAP := $(BUILD)/librom-m2.11-macplus.map
M2_12_OBJ := $(BUILD)/m2_12-reset.o
M2_12_ELF := $(BUILD)/librom-m2.12-macplus.elf
M2_12_ROM := $(BUILD)/librom-m2.12-macplus.bin
M2_12_MAP := $(BUILD)/librom-m2.12-macplus.map
M2_13_OBJ := $(BUILD)/m2_13-reset.o
M2_13_ELF := $(BUILD)/librom-m2.13-macplus.elf
M2_13_ROM := $(BUILD)/librom-m2.13-macplus.bin
M2_13_MAP := $(BUILD)/librom-m2.13-macplus.map

.PHONY: all check check-m2 check-m2_1 check-m2_2 check-m2_3 check-m2_4 check-m2_5 check-m2_6 check-m2_7 check-m2_8 check-m2_9 check-m2_10 check-m2_11 check-m2_12 check-m2_13 qualify-m1 qualify-m1-runtime qualify-m2_1 qualify-m2_2 qualify-m2_3 qualify-m2_4 qualify-m2_5 qualify-m2_6 qualify-m2_7 qualify-m2_8 qualify-m2_9 qualify-m2_10 qualify-m2_11 qualify-m2_12 qualify-m2_13 clean

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

$(M2_6_OBJ): src/platform/macplus/reset_m2_6.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_6_ELF): $(M2_6_OBJ) linker/m2_6.ld
	$(LD) -T linker/m2_6.ld -Map=$(M2_6_MAP) -o $@ $(M2_6_OBJ)

$(M2_6_ROM): $(M2_6_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_7_OBJ): src/platform/macplus/reset_m2_7.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_7_ELF): $(M2_7_OBJ) linker/m2_7.ld
	$(LD) -T linker/m2_7.ld -Map=$(M2_7_MAP) -o $@ $(M2_7_OBJ)

$(M2_7_ROM): $(M2_7_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_8_OBJ): src/platform/macplus/reset_m2_8.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_8_ELF): $(M2_8_OBJ) linker/m2_8.ld
	$(LD) -T linker/m2_8.ld -Map=$(M2_8_MAP) -o $@ $(M2_8_OBJ)

$(M2_8_ROM): $(M2_8_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_9_OBJ): src/platform/macplus/reset_m2_9.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_9_ELF): $(M2_9_OBJ) linker/m2_9.ld
	$(LD) -T linker/m2_9.ld -Map=$(M2_9_MAP) -o $@ $(M2_9_OBJ)

$(M2_9_ROM): $(M2_9_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_10_OBJ): src/platform/macplus/reset_m2_10.S | $(BUILD)
	$(AS) -m68000 -o $@ $<

$(M2_10_ELF): $(M2_10_OBJ) linker/m2_10.ld
	$(LD) -T linker/m2_10.ld -Map=$(M2_10_MAP) -o $@ $(M2_10_OBJ)

$(M2_10_ROM): $(M2_10_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072

$(M2_11_OBJ): src/platform/macplus/reset_m2_11.S | $(BUILD)
	$(AS) -m68000 -o $@ $<
$(M2_11_ELF): $(M2_11_OBJ) linker/m2_11.ld
	$(LD) -T linker/m2_11.ld -Map=$(M2_11_MAP) -o $@ $(M2_11_OBJ)
$(M2_11_ROM): $(M2_11_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072
$(M2_12_OBJ): src/platform/macplus/reset_m2_12.S | $(BUILD)
	$(AS) -m68000 -o $@ $<
$(M2_12_ELF): $(M2_12_OBJ) linker/m2_12.ld
	$(LD) -T linker/m2_12.ld -Map=$(M2_12_MAP) -o $@ $(M2_12_OBJ)
$(M2_12_ROM): $(M2_12_ELF)
	$(OBJCOPY) -O binary --gap-fill=0xff $< $@
	$(PYTHON) scripts/pad_rom.py $@ 131072
$(M2_13_OBJ): src/platform/macplus/reset_m2_13.S | $(BUILD)
	$(AS) -m68000 -o $@ $<
$(M2_13_ELF): $(M2_13_OBJ) linker/m2_13.ld
	$(LD) -T linker/m2_13.ld -Map=$(M2_13_MAP) -o $@ $(M2_13_OBJ)
$(M2_13_ROM): $(M2_13_ELF)
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
	$(PYTHON) scripts/check_m2_5.py
	$(PYTHON) scripts/check_m2_6.py
	$(PYTHON) scripts/check_m2_7.py
	$(PYTHON) scripts/check_m2_8.py
	$(PYTHON) scripts/check_m2_9.py
	$(PYTHON) scripts/check_m2_10.py
	$(PYTHON) scripts/check_m2_11.py
	$(PYTHON) scripts/check_m2_12.py
	$(PYTHON) scripts/check_m2_13.py

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

check-m2_5:
	$(PYTHON) scripts/check_m2_5.py

check-m2_6:
	$(PYTHON) scripts/check_m2_6.py

check-m2_7:
	$(PYTHON) scripts/check_m2_7.py

check-m2_8:
	$(PYTHON) scripts/check_m2_8.py

check-m2_9:
	$(PYTHON) scripts/check_m2_9.py

check-m2_10:
	$(PYTHON) scripts/check_m2_10.py

check-m2_11:
	$(PYTHON) scripts/check_m2_11.py

check-m2_12:
	$(PYTHON) scripts/check_m2_12.py

check-m2_13:
	$(PYTHON) scripts/check_m2_13.py

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

qualify-m2_5: $(M2_4_ROM) $(M2_4_ELF)
	$(PYTHON) scripts/check_m2_5.py
	CROSS=$(CROSS) bash scripts/qualify_m2_5_pce.sh $(M2_4_ROM) $(M2_4_ELF)

qualify-m2_6: $(M2_6_ROM) $(M2_6_ELF)
	$(PYTHON) scripts/check_m2_6.py
	bash scripts/qualify_m2_6_runtime.sh $(M2_6_ROM)
	CROSS=$(CROSS) bash scripts/qualify_m2_6_pce.sh $(M2_6_ROM) $(M2_6_ELF)

qualify-m2_7: $(M2_7_ROM) $(M2_7_ELF)
	$(PYTHON) scripts/check_m2_7.py
	bash scripts/qualify_m2_7_runtime.sh $(M2_7_ROM)
	CROSS=$(CROSS) bash scripts/qualify_m2_7_pce.sh $(M2_7_ROM) $(M2_7_ELF)

qualify-m2_8: $(M2_8_ROM) $(M2_8_ELF)
	$(PYTHON) scripts/check_m2_8.py
	bash scripts/qualify_m2_8_runtime.sh $(M2_8_ROM)
	CROSS=$(CROSS) bash scripts/qualify_m2_8_pce.sh $(M2_8_ROM) $(M2_8_ELF)

qualify-m2_9: $(M2_9_ROM) $(M2_9_ELF)
	$(PYTHON) scripts/check_m2_9.py
	bash scripts/qualify_m2_9_runtime.sh $(M2_9_ROM)
	CROSS=$(CROSS) bash scripts/qualify_m2_9_pce.sh $(M2_9_ROM) $(M2_9_ELF)

qualify-m2_10: $(M2_10_ROM) $(M2_10_ELF)
	$(PYTHON) scripts/check_m2_10.py
	CROSS=$(CROSS) bash scripts/qualify_m2_10_pce.sh $(M2_10_ROM) $(M2_10_ELF)

qualify-m2_11: $(M2_11_ROM) $(M2_11_ELF)
	$(PYTHON) scripts/check_m2_11.py
	CROSS=$(CROSS) bash scripts/qualify_m2_11_pce.sh $(M2_11_ROM) $(M2_11_ELF)
qualify-m2_12: $(M2_12_ROM) $(M2_12_ELF)
	$(PYTHON) scripts/check_m2_12.py
	CROSS=$(CROSS) bash scripts/qualify_m2_12_pce.sh $(M2_12_ROM) $(M2_12_ELF)
qualify-m2_13: $(M2_13_ROM) $(M2_13_ELF)
	$(PYTHON) scripts/check_m2_13.py
	CROSS=$(CROSS) bash scripts/qualify_m2_13_pce.sh $(M2_13_ROM) $(M2_13_ELF)

clean:
	rm -rf $(BUILD)
