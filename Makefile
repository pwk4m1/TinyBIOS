
as=nasm
aflags=-fbin -Wall -O0 

all: clean install

clean:
	rm -rf bin/bios

car:
	$(as) $(asflags) -DUSE_CAR -o bin/bios src/reset.asm

debug:
	$(as) $(asflags) -o bin/bios -D__DO_DEBUG_LOG__ src/reset.asm

install:
	$(as) $(asflags) -o bin/bios src/reset.asm

test:
	qemu-system-x86_64 -bios bin/bios \
	    -hda test_disk 

test-s:
	qemu-system-x86_64 -bios bin/bios \
	    -hda test_disk -serial stdio


test-tty:
	qemu-system-x86_64 -nographic -serial mon:stdio \
	    -bios bin/bios -hda test_disk &

logtest:
	qemu-system-x86_64 -d in_asm -bios bin/bios  \
	-hda test_disk 2>&1 | \
	tee qemu_run_log.txt

gdb:
	qemu-system-i386 -S -gdb tcp::1234 -bios bin/bios \
	-hda test_disk 

test-end:
	kill -9 `ps aux | grep qemu | grep -v grep | awk '{print $$2}'`

