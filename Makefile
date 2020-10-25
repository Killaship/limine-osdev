CC         = gcc
LD         = ld
KERNEL_HDD = build/disk.hdd

CFLAGS = -O2 -pipe -Wall -Wextra

CHARDFLAGS := $(CFLAGS)               \
	-std=gnu99                     \
	-masm=intel                    \
	-fno-pic                       \
	-mno-sse                       \
	-mno-sse2                      \
	-mno-mmx                       \
	-mno-80387                     \
	-mno-red-zone                  \
	-mcmodel=kernel                \
	-ffreestanding                 \
	-fno-stack-protector           \
	-Isrc/                         \

LDHARDFLAGS := $(LDFLAGS)        \
	-static                   \
	-nostdlib                 \
	-no-pie                   \
	-z max-page-size=0x1000   \
	-T src/linker.ld

.PHONY: clean all
.DEFAULT_GOAL = $(KERNEL_HDD)

disk: $(KERNEL_HDD)
run: $(KERNEL_HDD)
	qemu-system-x86_64 -m 2G -hda $(KERNEL_HDD)

src-stivale2/kernel2.elf:
	$(MAKE) -C src-stivale2
src-stivale/kernel.elf:
	$(MAKE) -C src-stivale

limine/limine-install:
	$(MAKE) -C limine/ limine-install

$(KERNEL_HDD): limine/limine-install src-stivale/kernel.elf src-stivale2/kernel2.elf
	-mkdir build
	rm -f $(KERNEL_HDD)
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(KERNEL_HDD)
	parted -s $(KERNEL_HDD) mklabel msdos
	parted -s $(KERNEL_HDD) mkpart primary 1 100%
	echfs-utils -m -p0 $(KERNEL_HDD) quick-format 32768
	echfs-utils -m -p0 $(KERNEL_HDD) import src-stivale/kernel.elf kernel.elf
	echfs-utils -m -p0 $(KERNEL_HDD) import src-stivale2/kernel2.elf kernel2.elf
	echfs-utils -m -p0 $(KERNEL_HDD) import limine.cfg limine.cfg
	limine/limine-install limine/limine.bin $(KERNEL_HDD)

clean:
	rm -f $(KERNEL_HDD)
	$(MAKE) -C src-stivale clean
	$(MAKE) -C src-stivale2 clean
