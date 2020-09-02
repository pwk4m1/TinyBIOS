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

; Implementing interrupt handling in this file. Stuff to note:
; 	- I greatly dislike the way IVT stuff works. I wont make
; 	  use of such.
; 	
; 	- Only minimal amount of stuff is supported here, This is 
; 	  machine firmware, not operating system (Looking at you
; 	  engineers at intel)
;
; 	- Only those devices that we're actually using are granted
; 	  "proper" handlers. Rest willl get generic EOI.

; ========================================================================== ;
; Reserved space for our IDT
;
IDT:
	times 	(256 * 8) db 0

; ========================================================================== ;
; Simple output function for sending data for PIC.
;
; Requires:
;	dx = port
; 	al = data
;
__pic_out:
	out 	dx, al
	times 	5 db 0x90 	; 5 nops of delay
	ret

%define PIC1_CMD 	0x20
%define PIC1_DATA 	0x21
%define PIC2_CMD 	0xA0
%define PIC2_DATA 	0xA1

; ========================================================================== ;
; Functions to set and clear IRQ masks. 
; If a request line is masked, interrupt request from line is  ignored.
; If IRQ2 is masked, secondary PIC stops raising IRQs.
;
; Both functions require al to be IRQLine to mask.
;

; helper function to check if line is for primary or secondary PIC
; sets dx = PIC1 if primary, or PIC2 if secondary.
; if secondary PIC is used, line -= 8.
__pic_set_regs_by_line:
	mov 	dx, PIC1_DATA
	cmp 	al, 8
	jl 	.done
	sub 	al, 8
	mov 	dx, PIC2_DATA
.done:
	ret

; Mask IRQ Line from al
set_irq_mask:
	push 	bp
	mov 	bp, sp

	push 	dx
	push 	ax

	call 	__pic_set_regs_by_line

	; we first read Interrupt Mask register, then we set
	; our IRQ line to 1 from result, and finally write new mask back.
	mov 	ah, al
	in 	al, dx
	shl 	ah, 1
	or 	al, ah
	out 	dx, al
	
	pop 	ax
	pop 	dx

	mov 	sp, bp
	pop 	bp
	ret

; remove/unmask IRQ Line from al
clear_irq_mask:
	push 	bp
	mov 	bp, sp

	push 	dx
	push 	ax

	call 	__pic_set_regs_by_line

	; as above, read IMR, then clear IRQ line, and write mask back
	mov 	ah, al
	in 	al, dx
	shl 	ah, 1
	not 	ah
	and 	al, ah
	out 	dx, al
	
	pop 	ax
	pop 	dx

	mov 	sp, bp
	pop 	bp
	ret

; ========================================================================== ;
; Functions to get ISR/IRR data
;
; Return ISR value in ax
pic_get_isr:
	push 	dx

	mov 	dx, PIC1_CMD
	mov 	al, 0x0b 	; read ISR command
	out 	dx, al
	mov 	dx, PIC2_CMD
	out 	dx, al
	in 	al, PIC2_CMD
	shl 	ax, 8
	in 	al, PIC1_CMD

	pop 	dx
	ret

; ========================================================================== ;
; Functionality related to generic interrupt handling / management.
; Here is both helper functions (EOI_xx, not to be used elsewhere), as well
; as handler code.

; After we're done with interrupt, we can use following functions to 
; let PIC to know we're done
EOI_primary:
	push 	ax
	mov 	al, 0x20
	out 	0x20, al
	pop 	ax
	ret

EOI_secondary:
	push 	ax
	mov 	al, 0x20
	out 	0xA0, al
	out 	0x20, al
	pop 	ax
	ret

; Fill IDT with EOI function pointers, even though *all* unused ints should be
; masked away, I want to be sure to not get random crashes due INT# jumping to
; addr 0.
__fill_idt_with_eoi:
	pusha
	; there are 8 interrupt lines on both primary and secondary 
	; PICs. As long as I set EOI 'handlers' for all those, we should
	; be all good.
	mov 	cl, 8 ; set primary handlers
	mov 	di, IDT
	mov 	bx, EOI_primary
	.loop_setup:
		mov 	ax, cs 			; get code segment
		mov 	word [di], bx 		; handler address low bits
		add 	di, 2
		stosw 	 			; code segment
		xor 	ax, ax
		stosb 				; zero
		mov 	byte [di], 0x8e 	; interrupt gate
		inc 	di
		stosw 				; addr high bits
		loop 	.loop_pri
	
	cmp 	bx, EOI_secondary
	je 	.done
	mov 	bx, EOI_secondary
	mov 	cl, 8
	jmp 	.loop_setup
.done:
	popa
	ret

	
