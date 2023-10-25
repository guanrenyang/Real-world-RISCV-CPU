TOPNAME = ysyx_23060061_Top

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

INC_PATH += $(abspath ./vsrc)
# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lSDL2 -lSDL2_image

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
	$(VERILATOR) $(VERILATOR_CFLAGS) -I$(abspath ./vsrc) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

run: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_EXEC)

gdb: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	gdb -s $(BIN) --args $(NPC_EXEC)

wave: run
	@gtkwave ./build/dump.vcd

.PHONY: clean
clean:
	rm -rf $(abspath $(BUILD_DIR))

include ../Makefile
