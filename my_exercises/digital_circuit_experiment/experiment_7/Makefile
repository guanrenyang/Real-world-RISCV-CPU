TOPNAME = keyboard_sim

BUILD_DIR = ./build_$(TOPNAME)
BIN = $(BUILD_DIR)/$(TOPNAME)
OBJ_DIR = $(BUILD_DIR)/obj_dir

$(shell mkdir -p $(BUILD_DIR))

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc -O3 --x-assign fast --x-initial fast --noassert --trace --timing

SRCS = vsrc/ps2_keyboard.v vtestbench/ps2_keyboard_model.v vtestbench/keyboard_sim.v #csrc/keyboard_sim.cpp
CSRCS = /home/parallels/ysyx-workbench/my_exercises/digital_circuit_experiment/experiment_7/csrc/keyboard_sim.cpp

INC_PATH ?=
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lSDL2 -lSDL2_image

keyboard_sim: $(SRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	

include $(NVBOARD_HOME)/scripts/nvboard.mk
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# VSRCS = $(abspath ./vtestbench/test_ps2_pin.v)
$(SRC_AUTO_BIND): ./constr/test_ps2_pin.nxdc
		python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py ./constr/test_ps2_pin.nxdc $(SRC_AUTO_BIND) 

test_ps2_pin: $(abspath ./csrc/test_ps2_pin.cpp) ./vtestbench/test_ps2_pin.v $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)

	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

 clean:
	rm -rf $(BUILD_DIR)

# TOPNAME = barrel_shifter
# NXDC_FILES = constr/$(TOPNAME).nxdc
# INC_PATH ?=
#
# VERILATOR = verilator
# VERILATOR_CFLAGS += -MMD --build -cc  \
# 				-O3 --x-assign fast --x-initial fast --noassert --trace
#
# BUILD_DIR = ./build
# OBJ_DIR = $(BUILD_DIR)/obj_dir
# BIN = $(BUILD_DIR)/$(TOPNAME)
#
# default: $(BIN)
# 	@echo $(BIN)
# $(shell mkdir -p $(BUILD_DIR))
#
# # constraint file
# SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# $(SRC_AUTO_BIND): $(NXDC_FILES)
# 	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
#
# #project source
# VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
# # CSRCS = $(shell find $(abspath ./csrc) -name "sim_*.cpp")
# CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
# CSRCS += $(SRC_AUTO_BIND)
#
# # rules for NVBoard
# include $(NVBOARD_HOME)/scripts/nvboard.mk
#
# # rules for verilator
# INCFLAGS = $(addprefix -I, $(INC_PATH))
# CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
# LDFLAGS += -lSDL2 -lSDL2_image
#
# $(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
# 	@rm -rf $(OBJ_DIR)
# 	$(VERILATOR) $(VERILATOR_CFLAGS) \
# 		--top-module $(TOPNAME) $^ \
# 		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
# 		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
#
# sim: $(BIN)
# 	@$^

