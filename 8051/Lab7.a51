		DutyCycleByte EQU r0		; set DutyCycleByte to equate to r0 register
		DutyFlag BIT 0x01			; set DutyFlag to save bit at 0x01
		directionFlag BIT 0x00		; set directionFlag to save bit at 0x00
		jmp main					; jump to main
		
		org 0x0B
		jmp t0_isr					; jump to t0_isr when timer 0 interrupt is reached
		
		org 0x1b
		jmp t1_isr					; jump to t1_isr when timer 1 interrupt is reached	
		
		org 0x30					; org to 0x30 to jump past other ISRs
main:	mov tmod, #0x11				; set timer 0 and 1 to mode 1
		mov p1, #0x00				; set p1 as output
		setb ET0					; enable timer0 interrupt
		setb ET1					; enable timer1 interrupt
		setb EA						; enable global interrupt
		mov TL0, #0x00
		mov TH0, #0x00				; initialize timer0 with 0x0000
		mov TL1, #0x00
		mov TH1, #0x00				; initialize timer1 with 0x0000
		setb TR0					; start timer 0
		setb TR1					; start timer 1
mainloop:	mov DutyCycleByte, P0	; move switch positions into DutyCycleByte(r0)
			jmp mainloop			; recursive jump back to main loop
			
			
	; ----- timer 0 ISR subroutine -----
t0_isr: mov th0, #0xff				; set high byte of timer 0 to 0xFF		
		cpl DutyFlag				; complement DutyFlag to show that LED's are turning on
		jb DutyFlag, t_on			; jump to t_on if DutyFlag is 1
		mov a, #0xff				; a = 0xff
		clr cy						; clear carry to prep for subtraction
		subb a, DutyCycleByte		; a = a - DutyCycleByte (r0 / switch position)
		mov TL0, a					; move value in accumulator to timer 0 low byte
		mov P1, #0x00				; turn off LED's
		reti						; return from instruction

	; ----- timer 0 turning on LED's -----
t_on:	mov TL0, DutyCycleByte		; move value of DutyCycleByte into timer0 lowbyte
		mov P1, #0xFF				; turn on LED's
		reti						; return from instruction
	

	; ----- timer 1 ISR subroutine -----
t1_isr: mov th1, #0xC0				; move 0xC0 into timer 1 high byte
		jnb directionFlag, t1_not0	; jump to t1_not0 if directionFlag is not 0
		cjne DutyCycleByte, #0xFF, t1_incDuty			; jump if dutyCycleByte != ff, jump to incDuty
		cpl directionFlag			; complement directionFlag
		jmp t1_decDuty				; jump to t1_decDuty
		
	; ----- timer 1, not 0 jump from t1_isr -----
t1_not0:	cjne DutyCycleByte, #0x60, t1_decDuty 		; jump if dutycyclebyte != 60, jump to decDuty
			cpl directionFlag		; complement directionFlag	
			jmp t1_incDuty			; jump to t1_incDuty

	; ----- timer 1 decrement subroutine -----
t1_decDuty: 	dec DutyCycleByte	; decrement DutyCycleByte
				reti				; return from instruction
				
	; ----- timer 1 increment subroutine -----
t1_incDuty:		inc DutyCycleByte	; increment from instruction
				reti				; return from instruction

end