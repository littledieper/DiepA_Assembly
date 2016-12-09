; ---------- constant definitions ---------;
null	equ 0x00
cr		equ 0x0d
lf		equ 0x0a
tab		equ 0x09

keyBytesRAMaddress	equ 0x22	; symbolic constant for base address
;								  of encryption key in RAM
txtRAMaddress		equ 0x30	; symbolic constant for base address
;								  of encryption key in RAM
;----------- variable definitions ----------;
keyvalIndex			equ 0x30	; variable to index keyval context array
keyLength			equ 0x20	; variable to track length of key
txtLength			equ 0x21	; variable to track length of key
charIndex			equ 0xe0	; alias for accumulator
choice				equ 0x7F	; variable to store selected operaiton
cryptChoice			equ 0x85	; variable to store selected operation

jmp main;

org 0x30
main:
;---------------- Init / config -------------------;
	mov tmod, #0x20		; config timer 1, mode 2
	mov scon, #0x50		; config serial 8-data, 1 start, 1 stop, no parity
	mov th1, #0xFD		; 9600 baud
	setb tr1			; start timer
;--------------- END of Init / config --------------;

;---------------------------------------------------
;---------------- Main Loop ------------------------
;---------------------------------------------------
; This handles a lot of the various calling and
; will control determine which path to follow
; for encryption / decryption
mainloop:
	call CryptSelect
	call EncryptSelect
	
	mov a, cryptChoice		; move selection back to accum for testing
	cjne a, #0x31, notXOR	; jump if a != 1
		mov a, choice 		; move selection back to accum for testing
		cjne a, #0x65, notXOREncrypt ; jump if not E
		jmp XORencrypt
		
		notXOREncrypt:
			cjne a, #0x64, notValid ; jump if not E / D
			jmp XORdecrypt
			
	notXOR: ; this is rotation encryption
		cjne a, #0x32, notROT	; jump if a != 2
			mov a, choice 		; move selection back to accum for testing
			cjne a, #0x65, notRotEncrypt ; jump if a!= E
			jmp ROTencrypt
			
			notRotEncrypt:
				cjne a, #0x64, notValid ; jump if not E / D
				jmp ROTdecrypt
				
	notROT: ; this will be the both encryption
		cjne a, #0x33, notValid
			mov a, choice	; move selectiono back to accum for testing
			cjne a, #0x65, notBOTHEncrypt ; jump if a != E
			jmp BOTHencrypt
			
			notBOTHEncrypt:
				cjne a, #0x64, notValid ; jump if not E / D
				jmp BOTHdecrypt	
				
	notValid: ; if it reached this, then input is not a valid option
		mov dptr, #Display0F		; select prompt
		call writeString		; display prompt
		call CrLf
		call CrLf				; space out next try...
		jmp mainloop			; reselect

;-----------------------------------------------------
; -----------    Encryption Subroutines     ----------
;-----------------------------------------------------
; all of these just call the various helper methods that break up
; the process into other subroutine helpers

; XOR encryption method
XORencrypt:
	call getEncryptKey		; prompt and get encryption key
	call RequestPlainText	; receive plain text to crypt
	call XORcrypt			; XOR encryption
	jmp finishUp	

; XOR decryption method
XORdecrypt:
	call getDecryptKey		; prompt and get decryption key
	call RequestCipherText	; receive ciphered text to decrypt
	call XORcrypt			; XOR decryption (the same)
	jmp finishUp
	
; bit rotation encryption
ROTencrypt:
	call getEncryptKey		; prompt and get encryption key
	call RequestPlainText	; receive plain text to encrypt
	call RotationEncrypt	; bit rotation encryption
	jmp finishUp
	
; bit rotation decryption
ROTdecrypt:
	call getDecryptKey		; prompt for input of key
	call RequestCipherText	; receive ciphered text to decrypt
	call RotationDecrypt	; bit rotation decryption
	jmp finishUp
	
; both combined encryption
; this will XOR first then rotate bits
BOTHencrypt:
	call getEncryptKey		; prompt and get encryption key
	call RequestPlainText	; prompt and get plain text to encrypt
	call XORcrypt			; xor encryption
	call RotationEncrypt	; rotation encryption
	jmp finishUp
	
; both combined decryption
; this will rotate bits then XOR
BOTHdecrypt:
	call getDecryptKey		; prompt and get decryption key
	call RequestCipherText	; prompt and get ciphered text to decrypt
	call RotationDecrypt	; rotation decryption
	call XORcrypt			; xor decryption
	jmp finishUp
	

; ---------------------------------------------------;
; ---------- Selection Subroutine Helpers ---------;
;----------------------------------------------------;

; selection for type of en/decryption
CryptSelect:
	mov dptr, #Select0		; prompt type of en/decryption
	call writeString		; send message
	jnb ri, $				; wait for input
	call getChar			; grab input
	mov cryptChoice, a		; move the input into a variable just in case
	ret

;selection for en/decryption
EncryptSelect:
	mov dptr, #Prompt0		; prompt en/cryption
	call writeString		; send message
	jnb ri, $				; wait for input
	call getChar			; grab input
	mov choice, a			; move the input into a variable	
	ret

; ---------------------------------------------------;
; ---------- Key Getting Subroutine Helpers ---------;
;----------------------------------------------------;

; prompts for encryption key
getEncryptKey:
	mov dptr, #Prompt1e		; prompt for input of key
	call writeString 		; send message
	jmp continue
; prompts for decryption
getDecryptKey:
	mov dptr, #Prompt1d		; prompt for input of key
	call writeString		; send mesage
continue: 
	call getKey				; recieve key
	mov dptr, #Display1a	; say key was received
	call writeString		; send message
	ret

;----------------------------------------------------;
;---   Request and Buffer Plain / Cipher Text  	-----;
;----------------------------------------------------;
	RequestPlainText:
	mov dptr, #Prompt2			; ask for plain text
	call WriteString			; send the prompt
	call BufferText				; get the plain text
	ret
	RequestCipherText:
	mov dptr, #Prompt3			; ask for ciphered text
	call WriteString			; send prompt
	call BufferText				; get plain text
	ret
	
;----------------------------------------------------;
;---------		Finishing Main Loop	 ----------------;
;----------------------------------------------------;
finishUp:
	call WriteBufferedText		; write encrypted/decrypted message
	call WaitForEnterKey		; halt until enter key is pressed
	call CrLf					; new lines for clarity
	mov a, choice;				; a = choice
	cjne a, #0x65, finishNotEncrypt	; jump if decrypt was selected
	mov dptr, #Display2			; load prompt of encrypt success
	call writeString			; display message
	jmp finish					; jump past subroutine
	finishNotEncrypt:	; this just displays a different prompt
		mov dptr, #Display3		; load decryption success message
		call writeString		; display message
finish:
	jmp mainloop		
	
;----------------------------------------------------;	
;----------------------------------------------------;
;-------------		Subroutines	     ----------------;
;----------------------------------------------------;
;----------------------------------------------------;


; --------------- XORcrypt -------------;
; handles both XOR encryption and decryption.
XORcrypt:
	mov r0, #keyBytesRAMaddress		;re-initialize key pointer
	mov r1, #txtRAMAddress			;re-initialize key pointer
XORcryptNextChar:
	mov a, @r0						;initialize rotate loop count
	mov r6, a						;must be passed to a before r6
	mov a, @r1						;get char from plain text
	
	xrl a, @r0 						;encrypt the character contained in the accumulator
	
	mov @r1, a						;write encrypted character back to RAM
	inc r0							;point to next key byte
	cjne @r0, #null, dontresetXORcryptKeyPtr
		mov r0, #keyBytesRAMaddress ;reinitialize key pointer
	dontresetXORcryptKeyPtr:
	inc r1							;point to next plain text char
		cjne @r1, #null, XORcryptNextChar
		ret										;end of string reached

;--------- LoadkeyFromROM ----------------;
;Receives ROM location of key array in dptrbefore it is called
;load bytes from a constant array of key values into RAM
;returns nothing

LoadKeyFromROM:
	mov r0, #keyBytesRAMaddress-1	;initialize RAM pointer
	mov keyvalIndex, #0x00	;initialize accumlator
	GetNextKeyByteFromROM:
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
	
	
;----------- getKey -----------;
;receives no params
;reads a series of key bytes from serial Rx
;writes the bytes to RAM at location indicated by keyBytesRAMaddress
;returns length of key in the keyLength variable

getKey:
	mov keyLength, #-1		; init keyLength to 0
	mov r0, #keyBytesRAMaddress ;init RAM pointer
getNextKeyByte:	
	jnb ri, $				; wait to receive a char
		call getchar		; char received, get it!
		mov @r0, a			; store key value in RAM
		inc r0				; increment RAM ptr
		inc keyLength		; increment keyLength var
	cjne a, #null, getNextKeyByte	; check for null char in encryption key
		ret	; found encryption key null
;----------------------------------------------------;
	
;----------- getchar ----------;
;subroutine receives nothing before it is called
;writes the character to the serial console
;returns a byte in the accumulator
getchar:
	mov a, sbuf ;get serial data (char)
	clr ri ;acknowledge data received
	ret ;return from subroutine call
;----------------------------------------------------;

;----------- writechar ----------;
;receives byte or character
;reads a character that has been received serially
;returns the char
writechar:
mov sbuf, a ;send data (char) serially
jnb ti, $ ;wait until data is sent
clr ti ;acknowledge data has been sent
ret 


; ----- writestring subroutine -----
;receives address of string in DPTR
; sends String serially using writechar
; returns nothing
WriteString:
		mov charIndex, #0x00	; re-init charIndex
	NextChar:
		push charIndex			; preserve charIndex value
		movc a, @a+dptr			; load byte of next char into accumulator
		cjne a, #null, notNullChar	; jump if char is not null
			pop charIndex		; restore charIndex value
			ret
	notNullChar:
			call writeChar		; calls writechar
			pop charIndex		; restore charIndex
			inc charIndex		; increment charIndex
			jmp NextChar		; restart to grab next char

;---------- WriteBufferedText ------------;
;receives nothing
;sends BufferedText serially using writeChar
;returns nothing
WriteBufferedText:
	mov r1, #txtRAMaddress			; re-init txt pointer
	NextBufChar:
		mov a, @r1					; moves character into accumulator
		call writeChar				; displays char
		inc r1						; increments index value in R1
		cjne @r1, #null, NextBufChar	; jump if char @r1 is null
			mov a, @r1				; move char at R1 to accumulator
			call writechar			; display char
			ret			
;----------------------------------------------------;

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
			ret
;----------------------------------------------------;

;----------- Wait for Enter Key ------------;
;Receives nno parameters
;Loops until keyboard enter key press is detected
;return nothing
WaitForenterKey:
	jnb ri, $					; wait for input
		call getchar			; char received, get it
		cjne a, #0x0d,WaitForEnterKey	; jump if enter key is not pressed
		ret
;----------------------------------------------------;

;-------------- CrLf --------------;
;receives no params
;outputs carriabe return and line feed
;returns nothing
CrLf:
	mov dptr, #newline			; move defined newline prompt into pointer
	call WriteString			; display new line
	ret
;----------------------------------------------------;

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
		mov r0, #keyBytesRAMaddress ;reinitialize key pointer
	dontResetRotationEncryptionKeyPtr:
	inc r1							;point to next plain text char
		cjne @r1, #0x00, RotationEncryptNextChar
		ret		

		
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



;----------------------------------------------------;
;---------		Buffer Plain Text	 ----------------;
;----------------------------------------------------;
newline: db cr, lf, null
Prompt0: db cr, lf, "Enter a letter to choose an operation:", cr, lf
		 db tab, "E to Encrypt", cr, lf
		 db tab, "D to Decrypt", cr, lf, null;
Display0: db "You chose: ", null
Prompt1e: db "Send the Encryption Key", cr, lf, null
Prompt1d: db "Send the Decryption Key", cr, lf, null
Display1a: db "Key has been received!", cr, lf, null
Display1c: db "Key format is incorrect", cr, lf, null
Display1d: db "Key is NULL", cr, lf, null

;prompt and display for encryption
Prompt2: db "Begin the capture and send the plain.txt file", cr, lf
		 db "Stop the capture once the cipher text is displayed.", cr, lf, null
Display2: db "Message has been encrypted.", cr, lf, null

;if (decrypt was chosen at Prompt0)
Prompt3: db "Begin the capture and send the cipher.txt file", cr, lf
		 db "Stop the capture once the cipher text is displayed.", cr, lf, null
Display3: db "Message has been decrypted.", cr, lf, null
Display0F: db "Invalid option was entered", cr, lf, null

;created prompts
Select0: db cr, lf, "Enter which type of encryption / decryption you want to use:", cr, lf
		 db tab, "1 for XOR encryption", cr, lf
		 db tab, "2 for bit rotation encryption", cr, lf
		 db tab, "3 for both", cr, lf, null;
		 
end