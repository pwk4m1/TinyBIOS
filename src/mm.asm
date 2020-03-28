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
; This code provides simple malloc() and free() to use, so that
; you don't have to remember which areas of ram can be freely used & which
; already contain something we need..
;
; We start our memory allocation from 0x2000, and go on 'till 0xC000
;
%define MM_START_ADDR 		0x2000
%define MM_END_ADDR     	0xC000
%define MM_MAX_OFFSET   	(0xC000 - 0x2000)
%define MM_BLOCK_HDR_SIZE 	6
%define MM_SIGN_FREE 		"free"
%define MM_SIGN_USED 		"used"

; We divide our heap to 'block's with following header:
;	signature: is block free or used
;	size: how large the block is (size in bytes)
;

; The following function "initializes" our heap by marking all of it free.
mm_init_ram:
	mov 	dword [MM_START_ADDR], MM_SIGN_FREE
	mov 	word [MM_START_ADDR+4], MM_MAX_OFFSET
	ret

; To allocate memory, following steps are taken:
;	1.) Find memory block that has been marked 'free'
; 	2.) allocate needed amount of bytes by marking the block 'used'
; 	3.) substract allocated size from size of block
;	4.) At end of this newly created block, mark remaining as 'free'
;	5.) Calculate size of remaining block
;
; malloc() takes following arguments:
;	cx: amount of bytes to allocate
; and returns:
; 	di: 0 on error or pointer to allocated block on success.
; 	carry flag set if memory out of sync
;
malloc:
	push 	bp
	mov 	bp, sp

	clc
	push 	bx
	add 	cx, MM_BLOCK_HDR_SIZE
	cmp 	cx, MM_MAX_OFFSET
	jl 	.ret_error

	mov 	bx, MM_START_ADDR
	.find_free_block:
		cmp 	dword [bx], MM_SIGN_USED
		je 	.get_next_block

		cmp 	dword [bx], MM_SIGN_FREE
		jne 	.error_out_of_sync

		; we found free block, let's see if it's big enough for us
		cmp 	word [bx+4], cx
		jle 	.do_malloc

		; it's not,, let's move to next block
	.get_next_block:
		add 	bx, word [bx+4]
		cmp 	bx, MM_END_ADDR
		jg 	.find_free_block
	.ret_error:
		pop 	bx
		mov 	sp, bp
		pop 	bp
		xor 	di, di
		ret

	.error_out_of_sync:
		; if this happens, that's a result of awful bug..
		mov 	si, .msg_heap_out_of_sync
		call 	serial_print
		stc
		jmp 	.ret_error

	.msg_heap_out_of_sync:
		db "HEAP OUT OF SYNC (BUG)!", 0x0A, 0x0D, 0

	.do_malloc:
		mov 	dword [bx], MM_SIGN_USED ; mark block as used
		mov 	di, bx
		add 	di, MM_BLOCK_HDR_SIZE    ; prepare ptr to return
		cmp 	word [bx+4], cx 	 ; check if block is exactly
		je 	.fullfill 		 ; same size with needed
						 ; if not, split it.

		push 	ax  			 ; backup ax
		mov 	ax, word [bx+4] 	 ; backup original block size
		mov 	word [bx+4], cx 	 ; write new block size
		add 	bx, cx 			 ; move to next block
		mov 	dword [bx], MM_SIGN_FREE ; mark next block as free
		sub 	ax, cx
		mov 	word [bx+4], ax 	; size of remaining region
		pop 	ax 			; restore ax
		jmp 	.ret_ptr
	.fullfill:
		mov 	word [bx+4], cx
	.ret_ptr:
		pop 	bx
		sub 	cx, MM_BLOCK_HDR_SIZE
		mov 	sp, bp
		pop 	bp
		ret

; free() requires pointer to mark as free at di.
; we return nothing
;
free:
	push 	bp
	mov 	bp, sp

	sub 	di, MM_BLOCK_HDR_SIZE
	cmp 	dword [di], MM_SIGN_USED
	jne 	.double_free

	; mark block as free & try to prevent memory fragmentation
	mov 	dword [di], MM_SIGN_FREE
	call 	__mm_prevent_fragments
	jmp 	.ret

	.double_free:
		mov 	si, .msg_double_free_or_err
		call 	serial_print
	.ret:
		mov 	bp, sp
		pop 	bp
		ret
	.msg_double_free_or_err:
		db "DOUBLE FREE OR FREE OF INVALID POINTER! (BUG)"
		db 0x0A, 0x0D, 0

; __mm_prevent_fragments is used to, as name suggests, prevent memory
; fragmentation. This is done by going through all our free blocks &
; combining contiguous regions
;
__mm_prevent_fragments:
	push 	bp
	mov 	bp, sp

	push 	si
	push 	bx
	push 	cx

	mov 	si, MM_START_ADDR
	.start_cm:
		cmp 	dword [si], MM_SIGN_USED
		je 	.get_next_block

		cmp 	dword [si], MM_SIGN_FREE
		je 	.found_free

		; out of sync...
		mov 	si, malloc.msg_heap_out_of_sync
		call 	serial_print
		jmp 	.ret

	.get_next_block:
		add 	si, word [si+4]
		cmp 	si, MM_END_ADDR
		jl 	.start_cm
	.ret:
		pop 	cx
		pop 	bx
		pop 	si
		mov 	sp, bp
		pop 	bp
		ret

	.found_free:
		; now, we've found 1 free block, let's check if next
		; block is free too
		mov 	bx, word [si+4]
		add 	si, bx

		cmp 	dword [si], MM_SIGN_USED
		je 	.get_next_block

		cmp 	dword [si], MM_SIGN_FREE
		jne 	.ret

		; next block is free too, merge these & repeat
		mov 	cx, word [si+4]
		sub 	si, bx
		add 	word [si+4], cx
		jmp 	.found_free


