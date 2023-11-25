; BSD 3-Clause License
; 
; Copyright (c) 2022, k4m1 <k4m1@protonmail.com>
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

%ifndef VGA_DAC
%define VGA_DAC

%define VGA_DAC_STATUS_READ 			0x00
%define VGA_DAC_STATUS_WRITE 			0x03


%define VGA_DAC_ADDRESS_WRITE_MODE_REGISTER 	0x03C8
%define VGA_DAC_ADDRESS_READ_MODE_REGISTER 	0x03C7
%define VGA_DAC_DATA_REGISTER 			0x03C9
%define VGA_DAC_DATA_STATE_REGISTER 		0x03C7

; Set DAC Write Address. This prepares the DAC hardware to accept writes
; of data to the VGA_DAC_DATA_REGISTER. The value written is the index of
; the first DAC entry to be written (Multiple CDAC entries may be written
; without having to reset the write address - it autoincrements)
;
; Reading this register might return current index, or not....
; Very DAC implementation specific unfortunately.
;
; Requires / Returns:
;	al = address byte(index)
;
vga_core_dac_address_write_mode_register_r:
	push 	dx
	mov 	dx, VGA_DAC_ADDRESS_WRITE_MODE_REGISTER
	in 	al, dx
	pop 	dx
	ret

vga_core_dac_address_write_mode_register_w:
	push 	dx
	mov 	dx, VGA_DAC_ADDRESS_WRITE_MODE_REGISTER
	out 	dx, al
	pop 	dx
	ret

; Set DAC read address. This prepares DAC hardware to accept reads of data to
; the VGA_DAC_DATA_REGISTER. The value written is the index of the 1st DAC
; entry to be read (autoincrements here too, no need to reset)
;
; Requires:
;	al = DAC Read address
;
vga_core_dac_read_address_w:
	push 	dx
	mov 	dx, VGA_DAC_ADDRESS_WRITE_MODE_REGISTER
	out 	dx, al
	pop 	dx
	ret

; Read/Write DAC data. These happen in bursts of 3 6-bit operations, the
; values are R/G/B intensities between 0-63.
;
; Read:
; 	Requires:
;		di = where from to write 3 bytes of R/G/B
; Write:
;	Requires:
;		si = where to read 3 bytes of R/G/B 
; 
; SI/DI are adjusted automatically, and bitmasks are applied here aswell
;
vga_core_dac_data_register_r:
	push 	dx
	push 	ax
	push 	cx
	
	mov 	cl, 3
	mov 	dx, VGA_DAC_DATA_REGISTER
	.loop:
		in 	al, dx
		and 	al, 0x3F
		stosb
		loop 	.loop

	pop 	cx
	pop 	ax
	pop 	dx
	ret

vga_core_dac_data_register_w:
	push 	dx
	push 	ax
	push 	cx
	
	mov 	cl, 3
	mov 	dx, VGA_DAC_DATA_REGISTER
	.loop:
		lodsb
		and 	al, 0x3F ; Mask of bits 6 and 7
		out 	dx, al
		loop 	.loop
		
	pop 	cx
	pop 	ax
	pop 	dx
	ret

; Read DAC status
;
; Returns:
;	al bits 0 and 1 imply status. High bits cleared off
;
vga_core_dac_status_register_r:
	push 	dx
	mov 	dx, VGA_DAC_DATA_STATE_REGISTER
	in 	al, dx
	and 	al, 0x03
	pop 	dx
	ret


%endif ; VGA_DAC
