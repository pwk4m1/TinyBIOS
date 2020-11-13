bits	16
org	0x7c00

mov	dx, 0x3f8
mov	si, msg_bootloader
mov	cl, byte [msg_bootloader_size]

rep	outsb

xor 	dx, dx
mov 	al, 0x41
mov 	ah, 0x01
int 	0x14

cli
hlt


msg_bootloader:
	db "HELLO FROM BOOTLOADER :)", 0x0A, 0x0D, 0

msg_bootloader_size:
	db 26

times	510-($-$$) db 0xFF
dw	0xAA55

