as=nasm
aflags=-fbin -O0

all: build

clean:
	rm -rf bin/bios

debug:
	$(as) $(asflags) -o bin/bios -D__DO_DEBUG_LOG__ src/reset.asm

build:
	$(as) $(asflags) -o bin/bios src/reset.asm

test:
	qemu-system-x86_64 -bios bin/bios -serial stdio \
		-hda test_disk


logtest:
	qemu-system-x86_64 -d in_asm -bios bin/bios  \
	-hda test_disk 2>&1 | \
	tee qemu_run_log.txt

gdb:
	qemu-system-i386 -S -gdb tcp::1234 -bios bin/bios \
	-hda test_disk -d in_asm 2>&1 | tee gdb_runlog.txt



