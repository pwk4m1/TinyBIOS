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

%ifndef VGA_CORE
%define VGA_CORE

; http://www.osdever.net/FreeVGA/vga/vgareg.htm#general
; http://www.osdever.net/FreeVGA/vga/graphreg.htm#06
; http://www.osdever.net/FreeVGA/vga/extreg.htm#3CCR3C2W
; http://www.osdever.net/FreeVGA/vga/graphreg.htm#05
; http://www.osdever.net/FreeVGA/vga/vgamem.htm
; http://www.osdever.net/FreeVGA/vga/vga.htm#general

; ======================================================================== ;
; Following function implements access to sequencer, graphics and crtc
;
; All registers are 8 bits wide, reads return byte to al, writes require
; byte to write in al.
;
; Both reads and writes require index at ah
;
; Accessing works as follows:
;	1.) Input the value of address register and save it
; 	2.) Output the index to the address regsiter
; 	3.) Read original value from data register
;	4.) If writing, modify original data
;	5.) If writing, output the modified data
; 	6.) Output original address register value back to addr register
;
; Requires:
; 	al = data to write
; 	ah = index to use
; Returns:
; 	al = data read
; Trashes:
; 	ah
; ======================================================================== ;
__vgac_sgcr_in:
	push 	dx
	push 	bx
	push 	ax

	; step 1
	mov 	dx, 0x03CE
	in 	al, dx
	mov 	bl, al

	; step 2
	pop 	ax
	out 	dx, ah

	; step 3
	inc 	dx
	in 	al, dx

	; step 6
	dec 	dx
	mov 	ah, bl
	out 	dx, ah
	pop 	bx
	pop 	dx
	ret

__vgac_sgcr_out:
	push 	dx
	push 	bx
	push 	ax
	push 	ax

	; step 1
	mov 	dx, 0x03CE
	in 	al, dx
	mov 	bl, al

	; step 2
	pop 	ax
	out 	dx, ah

	; step 3
	inc 	dx
	mov 	ah, al
	in 	al, dx

	; step 4
	or 	al, ah
	mov 	al, ah

	; step 5
	out 	dx, al

	; step 6
	mov 	al, bl
	dec 	dx
	out 	dx, al
	pop 	ax
	pop 	bx
	pop 	dx
	ret

; ======================================================================== ;
; Following function implements access to vga attribute registers.
; All of the documentation regarding accessing seq, graph & crtc regs
; holds pretty much true here too. 
;
; However, these functions, even if they have exactly same argument & 
; return value usages, are different. Both work in indexed manner yes, but
; well, just see for yourself:
;
; 	- Address register is R/W 0x3C0
; 	- Data register is: Read at 0x3C1, write to 0x3C0 (weird..)
; 	- Every 2nd write is address, every 2nd is data... internal
; 	  flipflop keeps track of this on vga end, we have to do tricks to
; 	  do the same here..
; Steps:
; 	1.) Input a value from the Input Status #1 register (0x3DA), and 
; 	    discard it.
; 	2.) Input the value of Address/Data register 0x3C0, and save it.
; 	3.) Output the index
; 	4.) Input the value of data register
; 	5.) If writing, modify data from step 4
; 	6.) If writing, output data
; 	7.) Write the value of address register saved in step 1
; 	8.) Input value from Input Status #1 to leave vga end to
; 	    index state
;
; Arguments:
; 	ah = index
; 	al = output data
; Return value:
; 	al = data read
; Trashes:
; 	ah
; ======================================================================== ;
__vga_attrib_in:
	push 	dx
	push 	bx
	push 	ax

	; step 1
	mov 	dx, 0x03DA
	in 	al, dx

	; step 2
	mov 	dx, 0x03C0
	in 	al, dx
	mov 	bl, al

	; step 3
	pop 	ax
	out 	dx, ah

	; step 4
	inc 	dx
	in 	al, dx

	; step 7
	mov 	ah, al
	mov 	al, bl
	dec 	dx
	out 	dx, al

	; step 8
	mov 	dx, 0x03DA
	in 	al, dx
	mov 	al, bl
	pop 	bx
	pop 	dx
	ret

__vga_attrib_out:
	push 	dx
	push 	bx
	push 	ax
	push 	ax

	; step 1
	mov 	dx, 0x03DA
	in 	al, dx

	; step 2
	mov 	dx, 0x03C0
	in 	al, dx
	mov 	bl, al

	; step 3
	pop 	ax
	out 	dx, ah

	; step 4
	inc 	dx 	; almost forgot this lol
	mov 	ah, al
	in 	al, dx

	; step 5 & 6
	dec 	dx
	or 	al, ah
	out 	dx, al

	; step 7
	mov 	al, bl
	out 	dx, al

	; step 8
	mov 	dx, 0x03DA
	in 	al, dx

	pop 	ax
	pop 	bx
	pop 	dx
	ret

; ======================================================================== ;
; These functions implement access to vga color registers. 
; Sadly, this is totally different technique, but oh well, that's why I'm
; writing these abstractions... So there would be no need to ever think
; about how this works again :D
;
; Jk jk I'm having fun.
;
; Anyway, steps:
; 	1.) Read DAC State reg and save the value, to be used in step 8
; 	2.) Read PEL Address write mode reg for use in step 8 too
; 	3.) Output the value of 1st color entry to be read to PEL
; 	    address read mode register
; 	4.) Read PEL Data reg for Red
; 	5.) Read PEL Data reg for Green
; 	6.) Read ...          for Blue
; 	7.) If more colors are to be read, repeat from step 4
; 	8.) Based upon the DAC state from step 1:
; 		- Write the value saved in step 2 to either PEL 
; 		  address write mode register or
; 		- Write to PEL Address read mode reg
; Note copied from FreeVGA aswell:
; 	Steps 1, 2, and 8 are hopelessly optimistic,, oh boy....
;
; There apparently is no way to guarantee that state is preserved,
; and some implementations guarantee that the state is never preserved
; 
; Requires:
; 	al = First color entry for PEL addr read mode register
; 	cl = amount of RGB iterations to read
; Returns:
; 	al = value saved in step 2, which has now been written to PEL 
; 		read or write register
; Trashes:
; 	my sanity.
; ======================================================================== ;
__vga_colo_out:
	push 	dx
	push 	bx
	push 	ax
	push 	cx

	; step 1
	mov 	dx, 0x03C7 	; dac state
	in 	al, dx
	mov 	bl, al

	; step 2
	mov 	dx, 0x03C8 	; PEL addr write mode
	in 	al, dx
	mov 	bh, al

	; step 3



%endif
