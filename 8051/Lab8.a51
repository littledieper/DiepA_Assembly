charindex equ 0xe0
dutybyte equ 0x30
dutyflag bit 0x00

jmp main
org 0x0b
jmp t0_isr

org 0x30
main: 	
		mov p1, #0x00		; configure p1 as output
		mov tmod, #0x21		; set timer 1 mode 2, timer 0 mode 1
		mov TH1, #0xFD		; set timer 1 to 9600 baud
		mov scon, #0x50		; config serial comms for 8bit data, 1 start/stop bit, no flow
		setb TR1			; start timer 1
		mov DPTR, #Welcome	; load welcome message into data pointer
		call writestring	; write string in data pointer
		mov DPTR, #DutyValues	; move DutyValues lookup table to dptr
		mov TH0, #0xFF		; load 0xFF into timer 0 high byte
		mov TL0, #0x60		; load 0x60 into timer 0 low byte
		setb ET0 			; enable timer 0 interrupt
		setb EA				; enable global interrupts
		setb TR0			; start timer 0

; ------ main loop of program ----
; retrieves values and preps them for processing		
mainloop:
		jnb RI, $ 		; loop here until value from serial comms until recieve	
		call getchar		; call getchar
		ANL a, #0x0F		; mask accumulator high 4 bits
		mov b, a			; b = a
		mov a, #9			; a = 9
		subb a,  b			; a = a - b
		jc mainloop			; jump back to mainloop if carry flag is set
		mov a , b			; a = back
		movc a, @a+dptr		; move to next value in lookup table
		mov DutyByte, a		; DutyByte = a
		jmp mainloop		; jump back to main loop
		
; ----- timer 0 ISR subroutine -----
; controls when LED's turn on
t0_isr: 	mov th0, #0xff 		;set high byte of timer 0 to 0xFF
		cpl DutyFlag 		; complement DutyFlag to show that LED's are turning on
		jb DutyFlag, t_on 	; jump to t_on if DutyFlag is 1
		mov a, #0xff 		; a = 0xff
		clr cy 			; clear carry to prep for subtraction
		subb a, DutyByte 	; a = a - DutyCycleByte (r0 / switch position)
		mov TL0, a 		; move value in accumulator to timer 0 low byte
		mov P1, #0x00 		; turn off LED's
		reti 			; return from instruction

; ----- timer 0 turning on LED's -----
t_on:   mov TL0, DutyByte 		; move value of DutyCycleByte into timer0 lowbyte
		mov P1, #0xFF 		; turn on LED's
		reti 			; return from instruction
		
; ----- getchar subroutine -----
; retrieves character input from serial buffer
getchar:
		mov a, sbuf		; a = value from serial buffer
		clr RI			; clear serial retrieve flag
		ret				
; ----- writechar subroutine -----
; writes the values from the data pointer over the serial comms	
writestring: 	mov charindex, #0	; charindex = 0
loop:
		push charindex		; push charindex onto the stack
		movc a, @a+dptr		; move to next value in lookup table
		jz popchar			; jump to popchar if accumulator = 0
		call writechar		; call writechar subroutine
		pop charindex		; pop charindex back from the stack
		inc charindex		; increment charindex
		jmp loop			; jump back to loop

; ----- popchar subroutine -----
; helper to writechar, returns to subroutine
popchar:					
		pop charindex 		; pop charindex back from stack
		reti				; return from instruction

; ----- writechar subroutine -----
; writes a char over the serial comms
writechar:
		mov sbuf, a			; move value in accumulator into serial buffer
		jnb TI, $			; loop here until value is sent over serial comms
		clr TI				; clear serial comms send
		ret					

org 0x200
Welcome: DB "Enter a value 0 through 9 for LED brightness control: ",0
DutyValues: DB 0x60,0x70, 0x80, 0x90, 0xA0, 0xB0, 0xC0, 0xD0, 0xE0, 0xF0
end
		