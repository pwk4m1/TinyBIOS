; BSD 3-Clause License
; 
; Copyright (c) 2020, k4m1 <k4m1@protonmail.com>
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
; 
; * Redistributions of source code must retain the above copyright notice, 
;   this list of conditions and the following disclaimer.
; 
; * Redistributions in binary form must reproduce the above copyright notice,
;   this list of conditions and the following disclaimer in the documentation
;   and/or other materials provided with the distribution.
; 
; * Neither the name of the copyright holder nor the names of its
;   contributors may be used to endorse or promote products derived from
;   this software without specific prior written permission.
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 

%define PIC_CMD_PRI 	0x20
%define PIC_CMD_SEC 	0xA0
%define PIC_DATA_PRI 	0x21
%define PIC_DATA_SEC 	0xA1

%define ICW1_ICW4 	0x01
%define ICW1_SINGLE 	0x02
%define ICW1_INTERVAL4 	0x04 	; call address interval 4
%define ICW1_LEVEL 	0x08 	; level trigger (edge) mode
%define ICW1_INIT 	0x10

%define ICW4_8086 	0x01 	; 8086/88 mode
%define ICW4_AUTO 	0x02 	; Auto EOI
%define ICW4_BUF_SEC 	0x08 	; buffered mode / secondary
%define ICW4_BUF_PRI 	0x0C 	; buffered mode / primary
%define ICW4_SFNM 	0x10 	; Special fully nested 	

; helper function for writing values for 8259 PIC
; no delay needed w/ qemu & modern stuff, but real old hw might be slow
pic_write:
	out 	dx, ax
	nop
	ret

; mask or unmask interrupts, both functions only require
; al = irqline to mask
; bl = set to 1 to set mask, or 0 to clear mask
irq_mask:
	push 	dx
	push 	ax

	cmp 	al, 8
	jl 	.pri
	mov 	dx, PIC_CMD_SEC
	sub 	al, 8
	jmp 	.do_mask_op
.pri:
	mov 	dx, PIC_CMD_PRI
.do_mask_op:
	mov 	ah, al
	in 	al, dx
	shr 	ah, 1
	test 	bl, bl
	jz 	.do_op
	not 	ah	
.do_op:
	or 	al, ah
	out 	dx, al

	pop 	ax
	pop 	dx
	ret

; Even if I do use ivt + stick to 16 bit realmode, there are overlapping
; interrupts, I need to remap those.
;
remap_pic:
	push 	dx
	push 	ax
	
	; init sequence in cascade mode
	mov 	dx, PIC_CMD_PRI
	mov 	ax, (ICW1_INIT | ICW1_ICW4)
	call 	pic_write

	mov 	dx, PIC_CMD_SEC
	call 	pic_write

	; primary pic vector offset
	mov 	dx, PIC_DATA_PRI
	mov 	ax, 0x20
	call 	pic_write

	; secondary pic vector offset
	mov 	dx, PIC_DATA_SEC
	mov 	ax, 0x28
	call 	pic_write

	; tell primary pic that there is secondary pic at IRQ2
	mov 	dx, PIC_DATA_PRI
	mov 	ax, 4
	call 	pic_write

	; tell secondary pic it's cascade identity
	mov 	dx, PIC_DATA_SEC
	mov 	ax, 2
	call 	pic_write

	pop 	ax
	pop 	dx
	ret

; get isr values from primary and secondary pic
__pic_get_irq_reg:
	push 	dx
	push 	bx
	mov 	bl, al
	mov 	dx, PIC_CMD_PRI
	out 	dx, al
	in 	al, dx
	shl 	ax, 8
	mov 	al, bl
	mov 	dx, PIC_CMD_SEC
	out 	dx, al
	in 	al, dx
	pop 	bx
	pop 	dx
	ret

pic_get_isr:
	mov 	al, 0x0b
	call 	__pic_get_irq_reg
	ret

pic_get_irr:
	mov 	ax, 0x0a
	call 	__pic_get_irq_reg
	ret
