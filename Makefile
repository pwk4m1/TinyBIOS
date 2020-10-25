
as=nasm
aflags=-fbin -Wall -O0 

all: clean install

clean:
	rm -rf bin/bios

install:
	$(as) $(asflags) -o bin/bios src/reset.asm

test:
	qemu-system-x86_64 -bios bin/bios \
	    -hda test_disk 

test-tty:
	qemu-system-x86_64 -nographic -serial mon:stdio \
	    -bios bin/bios -hda test_disk &

logtest:
	qemu-system-x86_64 -d in_asm -bios bin/bios  \
	-hda /dev/null 2>&1 | \
	tee qemu_run_log.txt

test-end:
	kill -9 `ps aux | grep qemu | grep -v grep | awk '{print $$2}'`

