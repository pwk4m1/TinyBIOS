target remote :1234
set architecture i386
add-symbol-file tinybios.elf
tui enable
tui new-layout main regs 1 asm 1 status 0 cmd 1
tui layout main
set disassembly-flavor intel

