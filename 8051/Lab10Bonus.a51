;---------- constant definitions ----------------;
null equ 0x00
cr equ 0x0d
lf equ 0x0a
tab equ 0x09
keyBytesRAMaddress equ 0x22 ; symbolic constant for basen address of
							; encryption key in ram
txtRAMaddress equ 0x30     ; symbolic constant for basen address of							
							; encryption key in ram

;--------- variable definitions ---------------;
keyvalIndex equ 0xe0    ;variable ot index the keyval constant array
ketlength equ 0x20    ; variable to track length of key
txtlength equ 0x221    ; variable to track length of key
charIndex  equ 0xe0    ; alias for accumlator
choice	equ 0x7f      ;variable to store selected operation



jmp main ;jump past interrupt vector table

org 0x0030 ;put main program at rom location 0x0030
main:
;---------------- Initialization/configuration ----------------;
mov tmod, #0x20 ;config timer 1 mode 2
mov scon, #0x50 ;config serial 8-data, 1 start, 1 stop, no parity
mov th1, #0xFD ;9600 baud
setb tr1 ;start timer 1 to enable serial communication
mov charindex, #0x00;

;--- selection
mainloop:
mov dptr, #Selection	; load selection message into dptr
call writeString		; display selection message
mov charindex, #0x00	; reset charindex for writestring
jnb ri, $			; wait for input
call getchar			; receive input!
mov r5, a			; move the input to register r5 to hold
mov dptr, #keyvals2		; load keyvals into dptr
call loadkeyfromrom		; load keyvals into ram
mov dptr, #PromptPT		; load file prompt into dptr
call writeString		; write prompt
call buffertext		; read text from file

cjne r5, #0x31, decrypt	; test selection input
; if 1 is input, continue
call rotationencrypt	; encrypt message
jmp continue			; jump to continue

decrypt:
call rotationdecrypt	; otherwise decrypt

continue:
call writebufferedtext	; write buffered text to serial console
call waitforenterkey	; wait for enter key to stop capturing text
mov dptr, #success		; load success message
mov charindex, #0x00	; reset char index for writeString
call writestring		; display success message

jmp mainloop
	

;--------- LoadkeyFromROM ----------------;
;Receives ROM location of key array in dptrbefore it is called
;load bytes from a constant array of key values into RAM
;returns nothing

LoadKeyFromROM:
	mov r0, #keyBytesRAMaddress-1	;initialize RAM pointer
	mov keyvalIndex, #0x00	;initialize accumlator
	GEtNextKeyByteFromROM:
	inc	r0					;increment RAM pointer
	push keyvalIndex		;preserve keyvalIndex variable
	movc a, @a+dptr			;load byes of key into accumlator
	notNull:
		mov @r0, a			;put byte of key into ram
		pop keyvalIndex		;restire keyvalIndex
		inc keyvalIndex		;increment keyvalIndex
	cjne @r0, #0x00, GetNextKeyByteFromROM     ;check for null terminating character
LoadDone:
	mov @r0, #0x00			;append null char to string
	ret
	
;---------- Buffer Text --------;
;Receives no parameters
;Read a series of txt bytes from serial Rx
;writes the bytes to RAM location indicated by keyBytesRAMaddress
;Returns length of key in the keylength variable
BufferText:
		mov r1, #txtRAMaddress	;initialize pointer
	WaitForTXTChar:
		jnb ri, $				;wait to receive char
		call getchar			;char received, get it!
		mov @r1, a 				;store chracter in ram
		inc r1					;increment pointer
		cjne a, #0x00, WaitForTXTChar	;check for null char
		;cjne a, #0x0D, WaitForTXTChar	;Debug: check for enter char for debug
			ret
		
;----------- Rotation Encrypt -----------;
;Receives no parameters
;Encryptes the plain text contained in RAM
;return nothing
RotationEncrypt:
	mov r0, #keyBytesRAMaddress		;re-initialize key pointer
	mov r1, #txtRAMAddress			;re-initialize key pointer
rotationEncryptNextChar:
	mov a, @r0						;initialize rotate loop count
	mov r6, a						;must be passed to a before r6
	mov a, @r1						;get char from plain text
	
	rotateEncrypt:
		rr a
		djnz r6, rotateEncrypt
	mov @r1, a						;write encrypted character back to RAM
	inc r0							;point to next key byte
	cjne @r0, #0x00, dontresetRotationEncryptionKeyPtr
	;cjne @r0, #0x00, dontresetRotationEncryptionKeyPtr     ;debug;
		mov r0, #keyBytesRAMaddress ;reinitialize key pointer
	dontResetRotationEncryptionKeyPtr:
	inc r1							;point to next plain text char
		cjne @r1, #0x00, RotationEncryptNextChar
	;	cjne @r1, #0x0D, RotationEncryptNextChar ;Debug; check for enter
		ret										;end of string reached
		
;----------- Rotation Decrypt -----------;
;Receives no parameters
;Encryptes the plain text contained in RAM
;return nothing
RotationDecrypt:
	mov r0, #keyBytesRAMaddress		;re-initialize key pointer
	mov r1, #txtRAMAddress			;re-initialize key pointer
rotationDecryptNextChar:
	mov a, @r0						;initialize rotate loop count
	mov r6, a						;must be passed to a before r6
	mov a, @r1						;get char from plain text
	
	rotateDecrypt:
		rl a
		djnz r6, rotateDecrypt
	mov @r1, a						;write encrypted character back to RAM
	inc r0							;point to next key byte
	cjne @r0, #0x00, dontresetRotationDecryptionKeyPtr
	;cjne @r0, #0x00, dontresetRotationDecryptionKeyPtr     ;debug;
		mov r0, #keyBytesRAMaddress ;reinitialize key pointer
	dontresetRotationDecryptionKeyPtr:
	inc r1							;point to next plain text char
		cjne @r1, #0x00, rotationDecryptNextChar
	;	cjne @r1, #0x0D, RotationEncryptNextChar ;Debug; check for enter
		ret										;end of string reached
	
;---------- WriteBufferedText ---------;
;receives address of buffered text in r1
;sends buffered text serially using writechar
;returns nothing
WriteBufferedText:
	mov r1, #txtRAMaddress ;re-initialize txt pointer
	nextbufchar:
		mov a, @r1
		call writeChar
		inc r1
		cjne @r1, #null, nextbufchar
;       cjne @r1, #0x0D, nextbufchar	;DeBUG
			mov a, @r1
			call writeChar
			ret

;-------------------------------------------;

;----------- Wait for Enter Key ------------;
;Receives nno parameters
;Loops until keyboard enter key press is detected
;return nothing
WaitForenterKey:
	jnb ri, $
		call getchar
		cjne a, #0x0d,WaitForEnterKey
		ret
		
;----------- getchar ----------;
;subroutine receives nothing before it is called
;writes the character to the serial console
;returns a byte in the accumulator
getchar:
mov a, sbuf ;get serial data (char)
clr ri ;acknowledge data received
ret ;return from subroutine call

; ----- writestring subroutine -----
; writes the values from the data pointer over the serial comms
writestring: mov charindex, #0x00; charindex = 0
loop:
push charindex ; push keyvalindex onto the stack
movc a, @a+dptr ; move to next value in lookup table
jz popchar ; jump to popchar if accumulator = 0
call writechar ; call writechar subroutine
pop charindex ; pop keyvalindex back from the stack
inc charindex ; increment keyvalindex
jmp loop ; jump back to loop
; ----- popchar subroutine -----
; helper to writechar, returns to subroutine
popchar:
pop charindex ; pop keyvalindex back from stack
reti ; return from instruction

;----------- writechar ----------;
;receives byte or character
;reads a character that has been received serially
;returns the c
writechar:
mov sbuf, a ;send data (char) serially
jnb ti, $ ;wait until data is sent
clr ti ;acknowledge data has been sent
ret 
;--------------------------------------------;

keyvals2: db 0x11, 0x22, 0x33, 0x44, 0x55, 0x00

PromptPT: db "Begin the captire and send the plain.txt file",cr,lf
		  db "Stop the capture once the cipher text is displayed.",cr,lf,null
Success: db cr,lf,"Message has been encrypted.",cr,lf,null
Selection: db "Enter 1 for encryption or 2 for decryption.",cr,lf,null
end	
