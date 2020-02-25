
as=nasm
aflags=-fbin -Wall -O0

all: clean install

clean:
	rm -rf bin/bios

install:
	$(as) $(asflags) -o bin/bios src/reset.asm

test:
	qemu-system-x86_64 -serial stdio -bios bin/bios \
	    -hda test_disk 

test-tty:
	qemu-system-x86_64 -nographic -serial mon:stdio \
	    -bios bin/bios -hda test_disk &

logtest:
	qemu-system-x86_64 -d in_asm -bios bin/bios  \
	-hda /dev/null | \
	tee qemu_run_log.txt

