# Define the root directory for the Verilog files
ROOT_DIR = ..

# Define your top-level modules for simulation
TOP_MODULES = line_buffer

# Find all .v files in the ROOT_DIR for dependencies (excluding testbenches)
SRC_FILES = $(shell find $(ROOT_DIR) -name "*.v" ! -name "tb_*.v" -not -path "$(ROOT_DIR)/.history/*")


# Define your testbenches
TESTBENCHES = $(patsubst %, tb_%, $(TOP_MODULES))

# Compiler and simulator commands
IVERILOG = iverilog
VVP = vvp

# Default target: compile, run simulation, and output VCD
all: $(TESTBENCHES)

# Rule to compile each testbench with the corresponding module
tb_%: tb_%.v $(SRC_FILES)
	$(IVERILOG) -o $@.out $^
	$(VVP) $@.out -vcd $@.vcd

# Rule to clean up generated files
clean:
	rm -f *.vcd *.out

# Phony targets
.PHONY: all clean
