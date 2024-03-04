TOPNAME = ysyxSoCFull
SIM_PATH = ./csrc

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(abspath ../ysyxSoC/perip) -name "*.v")
VSRCS += $(abspath ../ysyxSoC/generated/ysyxSoCFull.v)
CSRCS = $(shell find $(abspath $(SIM_PATH)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)
# CSRCS := $(filter-out %/main.cpp,$(filter main.cpp,$(CSRCS)) $(filter-out main.cpp,$(CSRCS))) // filter main.cpp which is the old version of main.cpp, this line is only for testing

VINCPATH = $(abspath ./vsrc) 
VINCPATH += $(abspath ../ysyxSoC/perip/uart16550/rtl) $(abspath ../ysyxSoC/perip/spi/rtl)
INC_PATH = $(abspath ./include)

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lSDL2 -lSDL2_image -lreadline


# for disassembly
CFLAGS += $(shell llvm-config --cflags) -fPIE 
LDFLAGS += $(shell llvm-config --libs)

# for debugging
ifeq ($(MAKECMDGOALS),gdb)
	CFLAGS += -ggdb3 -DVL_DEBUG=1 -D_GLIBCXX_DEBUG -O0
	LDFLAGS += -ggdb 
endif


all: $(BIN)
	@echo "Write this Makefile by your self."

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(shell mkdir $(abspath $(BUILD_DIR)))
	$(VERILATOR) $(VERILATOR_CFLAGS) $(addprefix -I, $(VINCPATH)) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN)) \
		--timescale "1ns/1ns" --no-timing

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

run: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_EXEC)

gdb: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "gdb $(NPC_EXEC)"
	gdb -s $(BIN) --args $(NPC_EXEC)

wave: run
	@gtkwave ./build/dump.vcd

.PHONY: clean
clean:
	rm -rf $(abspath $(BUILD_DIR))

include ../Makefile
