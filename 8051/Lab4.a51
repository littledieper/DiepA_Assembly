;Alex Diep, 012954719

num1 equ 0x30 		;equate num1 to 0x30
num2 equ 0x31		;equate num2 to 0x31
num3 equ 0x32		;equate num3 to 0x32
choice equ 0x40		;equate choice to 0x40

mov num1, #0x10		;num1 = #0x10
mov num2, #0x20		;num2 = #0x20
mov choice, #7		;choice = #7

mov r0, choice	;r0 = choice
cjne r0, #1, not1	;if r0 is not equal to #1, jump to not1
mov a, num1		;a = num1
add a, num2		;a = a + num2
mov num3, a		;num3 = a;
jmp done		;jump to done

not1: cjne r0, #2, not2	; if r0 is not equal to #2, jump to not2
		mov a, num1		;a = num1
		subb a, num2	;a = a - num2
		mov num3, a		;num3 = a
		jmp done		;jump to done
not2: cjne r0, #3, not3	; if r0 is not equal to #3, jump to not3
		mov a, num2		;a = num2
		subb a, num1	;a = a - num1
		mov num3, a		;num3 = a;
		jmp done		; jump to done
not3: mov num3, #0xAA	;"default" case if choice is not equal to 1,2, or 3
done:
end