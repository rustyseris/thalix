.PHONY: build rebuild clean build-iso

# name
KERNEL_NAME=thalix
TARGET_TRIPLE=x86_64-unknown-$(KERNEL_NAME)

# binaries
NASM = nasm
FIND = find
LINKER = ld
CARGO = xargo
RM = rm
GRUB_MKRESCUE = grub-mkrescue

# config
ifneq ($(PROFILE),release)
    PROFILE=debug
endif

# path
BUILD_DIR = build
SRC_DIRECTORY = src
LINKER_SCRIPT = $(BUILD_DIR)/linker.ld
THALIXLIB = target/$(TARGET_TRIPLE)/$(PROFILE)/lib$(KERNEL_NAME).a
KERNEL = target/$(TARGET_TRIPLE)/$(PROFILE)/$(KERNEL_NAME).knl

# flags generation
CARGO_FLAGS = --target=$(TARGET_TRIPLE)
NASM_FLAGS = -f elf64
LINKER_FLAGS = -n -T $(LINKER_SCRIPT) --gc-sections -nostdlib
ifneq ($(PROFILE),release)
    NASM_FLAGS += -g
else
    CARGO_FLAGS += --release
endif

# file discovery
ASM_FILES = $(shell $(FIND) $(SRC_DIRECTORY) -name "*.S" -type f)
OBJ_FILES = $(patsubst %.S, %.$(PROFILE).asm.o, $(ASM_FILES))


########## RULES ##########

build-iso: $(KERNEL)
	mkdir -p $(BUILD_DIR)/isodir/boot/grub
	cp $(KERNEL) $(BUILD_DIR)/isodir/boot
	cp $(BUILD_DIR)/grub.cfg $(BUILD_DIR)/isodir/boot/grub
	$(GRUB_MKRESCUE) -o $(BUILD_DIR)/$(KERNEL_NAME).iso $(BUILD_DIR)/isodir 

# Build the kernel
build: $(KERNEL) 

# Clean lib$(KERNEL_NAME) and assembler object files
clean:
	$(RM) -rf $(OBJ_FILES)
	$(CARGO) clean

# Rebuild the kernel from scratch
rebuild: clean build

# Linking the kernel
$(KERNEL): $(THALIXLIB) $(OBJ_FILES)
	@ printf "\t(LINKING)\n"
	$(LINKER) $^ -o $@ $(LINKER_FLAGS)

# Building lib$(KERNEL_NAME)
$(THALIXLIB):
	$(CARGO) build $(CARGO_FLAGS)

# Building assembler object files
%.$(PROFILE).asm.o: %.S
	@ printf "\t(NASM) $<\n"
	@ $(NASM) $< -o $@ $(NASM_FLAGS)

