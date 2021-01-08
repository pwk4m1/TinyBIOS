;
; Copyright (c) 2020, k4m1 <k4m1@protonmail.com>
; All rights reserved. See /LICENSE for full license agreement.
;
; let's implement malloc+free in hopefully sane way.
;
; Memory block header:
;	4 bytes: used/free
;	2 bytes: size
;
%ifndef __MM_ASM__
%define __MM_ASM__

%define __MM_MEM_USED 	"used"
%define __MM_MEM_FREE 	"free"
%define __MM_MEM_SIZE 	(__MM_MEM_END - __MM_MEM_START)

mm_heap_init:
	mov 	dword [__MM_MEM_START],  __MM_MEM_FREE
	mov 	word [__MM_MEM_START+4], __MM_MEM_SIZE
	ret

; ====================================================================== ;
; malloc requires:
;	cx: size of memory block to allocate
; returns:
;	di = pointer to allocated memory on success or
;	di = 0 on error
;
; ====================================================================== ;
malloc:
	push 	bp
	mov 	bp, sp

	push 	si
	push 	cx
	push 	eax ; used for temp. storing signaturE

	xor 	di, di 	; set default ret value to 0
	mov 	si, __MM_MEM_START  ; start looking for free memory to allocate

	.check_next_block:
		lodsd
		cmp 	eax, __MM_MEM_FREE
		je 	.free_block_found
		cmp 	eax, __MM_MEM_USED
		jne 	.mem_out_of_sync
		
		lodsw
		add 	si, ax
		cmp 	si, __MM_MEM_END
		jl 	.check_next_block

		; we fell out of memory region/out of heap..
		; / no more space left to allocate
	.ret:
		pop 	eax
		pop 	cx
		pop 	si
		mov 	sp, bp
		pop 	bp
		ret

	.free_block_found:
		lodsw
		cmp 	ax, cx
		jg 	.do_malloc
		; memory block was not large enough, move to next
		add 	si, ax
		cmp 	si, __MM_MEM_END
		jl 	.check_next_block
		jmp 	.ret

	.mem_out_of_sync:
		; we're out of sync now.. panic
		push 	si
		mov 	si, msg_heap_out_of_sync
		call 	serial_print
		pop 	si
		cli
		hlt
		jmp 	$ - 2

	.do_malloc:
		; we've found suitable block, si now points to start of 
		; free memory block (Our return value), store it to di
		mov 	di, si
		sub 	si, 6
		mov 	dword [si], __MM_MEM_USED
		add 	si, 4

		; check how large is the free block, do we fill it totally?
		add 	cx, 8 ; add (header size + 1 byte of memory (lol))
		cmp 	cx, ax
		je 	.fullfill

		; we don't fill it all, so let's split it
		sub 	cx, 8
		mov 	word [si], cx

		add 	si, cx
		add 	si, 2
		mov 	dword [si], __MM_MEM_FREE
		add 	si, 4
		sub 	ax, cx
		sub 	ax, 6
		mov 	word [si], ax
		jmp 	.ret

	.fullfill:
		mov 	dword [si], __MM_MEM_USED
		jmp 	.ret

; ====================================================================== ;
; phew, malloc() is done, next.. free()
;
; requires:
;	di = pointer to free
; returns:
;	nothing, really
;
; ====================================================================== ;
free:
	push 	bp
	mov 	bp, sp

	sub 	di, 6 ; sizeof header
	cmp 	dword [di], __MM_MEM_USED
	jne 	.ret
	mov 	dword [di], __MM_MEM_FREE
	call 	__mm_prevent_fragmentation
.ret:
	mov 	sp, bp
	pop 	bp
	ret

; ====================================================================== ;
; prevent_fragmentation is used to, as name suggests, to prevent memory
; fragmentation.
;
; ====================================================================== ;
__mm_prevent_fragmentation:
	pusha
	add 	di, 4
	mov 	ax, word [di]
	add 	di, ax
	.check_next_block:
		cmp 	dword [di], __MM_MEM_FREE 	; is next block free
		jne 	.done 				; if not, return

		mov 	bx, word [di+4] 	; it's marked free, merge
		sub 	di, ax
		sub 	di, 2			; point back block size
		add 	ax, bx
		stosw
	.done:
		popa
		ret

msg_heap_out_of_sync:
	db "heap out of sync (BUG)", 0

%endif ; __MM_ASM__
