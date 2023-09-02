rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

cpp := x86_64-unknown-elf-g++
cc := x86_64-unknown-elf-gcc
ld := x86_64-unknown-elf-ld
kbin := kernel.elf

CPPFLAGS += \
    -Wall \
    -Wextra \
    -Werror \
    -ffreestanding \
    -fno-stack-protector \
    -fno-stack-check \
    -fno-lto \
    -fno-PIE \
    -fno-PIC \
    -m64 \
    -march=x86-64 \
    -mabi=sysv \
    -mno-80387 \
    -mno-mmx \
    -mno-sse \
    -mno-sse2 \
    -mno-red-zone \
    -mcmodel=kernel \
    -Ikernel/include

LDFLAGS += \
    -nostdlib \
    -static \
    -m elf_x86_64 \
    -z max-page-size=0x1000 \
    -T kernel/misc/kernel.ld

ASMFLAGS += \
    -Wall \
    -f elf64

kcsources = $(call rwildcard,kernel/src,*.cpp)
kcsources_c = $(call rwildcard,kernel/src,*.c)
kcsourcesnasm = $(call rwildcard,kernel/src,*.asm)
kobj = $(kcsourcesnasm:.asm=.o) $(kcsources:.cpp=.o) $(kcsources_c:.c=.o)

all: $(kbin) limine

limine:
	@git clone https://github.com/limine-bootloader/limine.git --branch=v5.x-branch-binary --depth=1
	@make -C limine

$(kbin): $(kobj)
	@echo 'LD ' $(kbin)
	@$(ld) $(kobj) $(LDFLAGS) -o $@

kernel/src/%.o: kernel/src/%.cpp
	@echo CXX $<
	@$(cpp) $(CPPFLAGS) -c $< -o $@ -g

kernel/src/%.o: kernel/src/%.c
	@echo 'CC ' $<
	@$(cc) $(CPPFLAGS) -c $< -o $@ -g

kernel/src/%.o: kernel/src/%.asm
	@echo 'AS ' $<
	@nasm $(ASMFLAGS) $< -o $@

iso: $(kbin)
	@rm -rf iso_root
	@mkdir -p iso_root
	@cp kernel.elf kernel/misc/limine.cfg limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/
	@xorriso -as mkisofs -b limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		iso_root -o root.iso
	@limine/limine bios-install root.iso
	@rm -rf iso_root

run: iso
	qemu-system-x86_64 -cdrom root.iso

clean:
	-@rm $(kobj)
	-@rm kernel.elf -f
