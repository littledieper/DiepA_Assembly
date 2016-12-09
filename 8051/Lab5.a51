		jmp main ; jump past interrupt vector

		org 0x30
main: 	;--+ configuration section +--
		mov p1, #0x00

	;--+ main program section +--
main_loop:
		call	checkInput
		call 	Delay
		mov p1, #0xFF
		call	checkInput
		call 	Delay
		mov p1, #0x00
		jmp main_loop
	
	;--+  input check subroutine +--
checkInput:
		mov r7, p0 ; read switch position into r7
		cjne r7, #0x00, not0	;1/4 second
		mov r5, #12
		jmp goback
not0: 	cjne r7, #0x01, not1	;1/2 second
		mov r5, #24
		jmp goback
not1: 	cjne r7, #0x02, not2	;1 second
		mov r5, #47
		jmp goback
not2:	mov r5, #94				;2 seconds				
goback: ret

		;--+ delay subroutine +--
Delay:
again:	mov r0, #230
outer: 	mov r1, #255
inner: 	djnz r1, inner
		djnz r0, outer
		djnz r5, again
		ret ; return from subroutine
		
end