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

; ========================================================================== ;
; Following code remaps 8259 Programmable Interrupt Controller.
;
%define PIC1_CMD 	0x20
%define PIC1_DATA 	0x21
%define PIC2_COMMAND 	0xA0
%define PIC2_DATA 	0xA1

remap_pic:
	mov 	dx, PIC1_COMMAND
	mov 	al, 0x11 		; ICW1 Initializion + icw4
	call 	__pic_out

	mov 	dx, PIC2_COMMAND
	call 	__pic_out

	mov 	al, 0x20 		; primary offset
	mov 	dx, PIC1_DATA
	call 	__pic_out
	
	add 	al, 0x08 		; secondary offset
	mov 	dx, PIC2_DATA
	call 	__pic_out

	mov 	al, 0x04 		; secondary pic at irq2 (0000 0100)
	mov 	dx, PIC1_DATA
	call 	__pic_out

	mov  	al, 2 			; secondary pic cascade identity
	mov 	dx, PIC2_DATA
	call 	__pic_out

	mov 	al, 0x01 		; 8086/88 mode
	mov 	dx, PIC1_DATA
	call 	__pic_out

	mov 	dx, PIC2_DATA
	call 	__pic_out

	xor 	al, al 			; set mask to 0
	mov 	dx, PIC1_DATA
	call 	__pic_out

	mov 	dx, PIC2_DATA
	call 	__pic_out

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



