# Final exectuable name
TARGET_EXEC := hexdump

# Build directory
BUILD_DIR 	:= ./build

# Source files directory
SRCS_DIR 	:= ./src

$(BUILD_DIR)/$(TARGET_EXEC): $(BUILD_DIR)/hexdump_asm.o
	ld -o $@ $<

$(BUILD_DIR)/hexdump_asm.o: $(SRCS_DIR)/hexdump_asm.asm | $(BUILD_DIR)
	nasm -f elf64 -g -o $@ $<

$(BUILD_DIR):
	mkdir $@
