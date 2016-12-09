;Alex Diep

		jmp main			; jump past interrupt vector
		
		org 0x30			; start rom location for main code @ 0x30
		; ----- configuration -----
main:	mov tmod, #0x10		;	timer 1, mode 1
		mov p1, #0x00		; port 1 is output
		

		; ----- main program -----
mainloop:
		call	checkInput
		call 	delay
		mov p1, #0xFF		; LED’s on
		call	checkInput
		call 	delay
		mov p1, #0x00		; LED’s off
		jmp mainloop


		; ---- check input subroutine ----
checkInput:
		mov r7, p0	 			; read switch position into r7
		cjne r7, #0x00, not0	; jump to not0 if r7 != 0
		mov r5, #5				; R7 = decimal 12
		jmp goback				; jump down to go back
not0: 	cjne r7, #0x01, not1	; jump to not1 if r7 != 1
		mov r5, #10				; 1/2 second
		jmp goback				; jump down to go back
not1: 	cjne r7, #0x02, not2	; jump to not2 if r7 != 2
		mov r5, #20				; 1 second
		jmp goback				; jump down to go back
not2:		mov r5, #40			; 2 seconds				
goback: 	ret


		; ---- delay subroutine ----
delay:	mov th1, #0x3C			; load initial count for high bit
		mov tl1, #0xAF			; load initial count for low bit
		setb tr1				; start timer for timer1
wait: 	jnb tf1, wait			; poll timer flag
		clr tr1					; stop timer 1
		clr tf1					; clear timer 1 flag
		djnz r5, delay			; decrement, jump if r5 = 0 to delay
		ret						; return to original position
		
end