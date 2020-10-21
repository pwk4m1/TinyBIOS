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

; **************************************************************************** 
; First, here are some helper functions used for allocating stuff, 
; talking w/ chips, etc..
;
alloc_idt_ptr:
	push 	cx
	push 	edi
	push 	ax

	mov 	cx, (256 * 8)
	call 	malloc
	and 	edi, 0x0000ffff
	mov 	dword [IDT_PTR], edi

	pop 	ax
	pop 	edi
	pop 	cx
	ret

; set handler entry to idt. 
; Requires:
; 	cx = current offset in idt
; 	ax = offset to irq handler.
;
; Do note, that ax needs to be _offset_. All handlers are to be located
; within ROM region, (segment being F, so handlers are in F:0000-F:FFFF)
;
set_irq_handler_entry:
	push 	di
	push 	ax

	mov 	ax, word [IDT_PTR]
	mov 	di, ax
	add 	di, cx

	stosw 			; handler low 16 bits (ax)
	mov 	ax, cs
	stosw 			; handler code segment
	xor 	ax, ax
	stosb 			; zero
	add 	al, 0x8e
	stosb 			; selector attrib, set to 0 if non-present
	xor 	al, al
	stosw 			; handler high 16 bits (ax set to 0)
	
	pop 	ax
	pop 	di
	ret


; **************************************************************************** 
; Following function does manages IDT setup & loading.
load_idt:
	pusha

	; allocate space for idt
	call 	alloc_idt_ptr
	mov 	ax, word [IDT_PTR]
	test 	ax, ax
	jz 	.malloc_error
	mov 	si, .msg_idt_at
	call 	serial_print
	call 	serial_printh

	; clear it out
	mov 	cx, 1024
	mov 	di, ax
	xor 	ax, ax
	rep 	stosw

	mov 	ax, word [IDT_PTR]
	sub 	di, ax
	dec 	di
	mov 	word [IDT_INFO], di
	mov 	di, IDT_INFO
	lidt 	[di]
	sti

.done:
	popa
	ret

.malloc_error:
	mov 	si, .msg_malloc_errored
	call 	serial_print
	jmp 	.done

.msg_malloc_errored:
	db "FAILED TO ALLOCATE SPACE FOR IDT!", 0x0A, 0x0D, 0

.msg_idt_at:
	db "IDT SET UP AT: 0x", 0

