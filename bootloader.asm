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

xor 	ax, ax
mov 	es, ax
mov 	bx, 0x8c00
mov 	cl, 1
mov 	ch, 0
mov 	dh, 0
mov 	ah, 2
mov 	al, 1
int 	0x13
int 	0x13
int 	0x13
int 	0x13
int 	0x13
int 	0x13
int 	0x13
int 	0x13

cli
hlt
jmp 	$ - 2

msg_bootloader:
	db "HELLO FROM BOOTLOADER :)", 0x0A, 0x0D, 0

msg_bootloader_size:
	db 26

times	510-($-$$) db 0xFF
dw	0xAA55

