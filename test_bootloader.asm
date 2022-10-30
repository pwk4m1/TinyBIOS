bits 	16
org 	0x7c00

.start:
	times 	128 db 0x90
jmp 	.start
hlt

times 510-($-$$) db 0xFF
dw 0xaa55

