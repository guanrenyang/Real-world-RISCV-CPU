AM_SRCS := riscv/ysyxsoc/start.S \
		   riscv/ysyxsoc/trm.c 

CFLAGS	+= -fdata-sections -ffunction-sections
LDFLAGS	+= -T $(AM_HOME)/am/src/riscv/ysyxsoc/linker.ld \
			--defsym=_sram_start=0x0f000000 --defsym=_sram_size=0x2000 --defsym=_mrom_start=0x20000000

LDFLAGS   += --gc-sections -e _start

YSYXSOCFLAGS ?= 
YSYXSOCFLAGS += -l $(shell dirname $(IMAGE).elf)/ysyxsoc-log.txt
YSYXSOCFLAGS += -f $(IMAGE).elf
YSYXSOCFLAGS += -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so

CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
# .PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -B -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(YSYXSOCFLAGS)" IMG=$(IMAGE).bin

gdb: image
	$(MAKE) -B -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(YSYXSOCFLAGS)" IMG=$(IMAGE).bin
