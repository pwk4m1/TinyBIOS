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

; In the end, I do use ivt anyway. soz :P :P
;
; following function can be used to set interrupt handlers.
; Arguments:
;	ax 	= handler segment
;	bx 	= handler offset
; 	di 	= ivt offset
;
set_ivt_entry:
	push 	di
	stosw
	mov 	word [di], bx
	pop 	di
	ret

; helper function to handle setting up interrupts.
; Call this first, ivt can be updated on the go by device inits
;
init_interrupts:
	call 	clear_ivt
	call 	remap_pic
	ret

; Clear memory reserved for interrupt vector table, so that
; in case of random interrupts we don't die. 
; All handlers are set to be generic dummy one.
; 
;
clear_ivt:
	pusha
	pushf
	xor 	di, di
	xor 	ax, ax
	mov 	es, ax
	mov 	ds, ax
	mov 	eax, irq_handler
	and 	eax, 0x0000ffff
	mov 	bx, cs
	mov 	cx, 100 	; IVT is 400 bytes large, 1 entry is 4 bytes
	.loop:
		stosw
		mov 	word [di], bx
		add 	di, 2
		loop 	.loop
	popf
	popa
	ret

; this is a generic irq handler, so that each irq handler does not need
; to contain this same code :P
;
irq_handler:
	cli
	pusha

	call 	pic_get_isr

	; check if this was spurious or software defined irq
	; if so, no need to send EOI
	cmp 	ax, 0
	je 	.end 

	; check if primary or secondary irq
	cmp 	al, 8
	jl 	.pri

	; send secondary pic EOI
	mov 	dx, PIC_CMD_SEC
	mov 	al, 0
	out 	dx, al

	; send primary pic EOI
.pri:
	mov 	dx, PIC_CMD_PRI
	out 	dx, al

.end:
	popa
	iret

.msg_bug_unhandled_irq:
	db "BUG: UNHANDLED INTERRUPT, IRQ#: ", 0



