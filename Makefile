# Final exectuable name
TARGET_EXEC := hexdump

# Build directory
BUILD_DIR 	:= ./build

# Source files directory
SRCS_DIR 	:= ./src

# Size of test file in MB
SIZE ?= 512

# File name
FILE := test$(SIZE)M.bin

# Number of times perf should run
ITER ?= 5

# Check if these commands exist in $PATH
NASM := $(shell command -v nasm)
LD	 := $(shell command -v ld)
PERF := $(shell command -v perf)

$(BUILD_DIR)/$(TARGET_EXEC): $(BUILD_DIR)/hexdump_asm.o
ifeq ($(LD),)
	$(error "ld not found, please make sure your $PATH is set correctly.")
endif
	@echo "[LD]	$@"
	@ld -o $@ $<

$(BUILD_DIR)/hexdump_asm.o: $(SRCS_DIR)/hexdump_asm.asm | $(BUILD_DIR)
ifeq ($(NASM),)
	$(error "nasm not found, please install it.")
endif
	@echo "[NASM]	$@"
	@nasm -f elf64 -g -o $@ $<

benchmark: $(BUILD_DIR)/$(TARGET_EXEC) | $(FILE)
ifeq ($(PERF),)
	$(error "perf not found, please install it.")
endif
	@echo "Running benchmark on $(FILE)..."
	@perf stat -r $(ITER) $(BUILD_DIR)/$(TARGET_EXEC) $(FILE) > /dev/null

$(BUILD_DIR):
	@echo "Making build directory..."
	@mkdir $@

$(FILE):
	@echo "Creating $(SIZE)M file from /dev/urandom..."
	@dd if=/dev/urandom of=$(FILE) bs=1M count=16 status=none
