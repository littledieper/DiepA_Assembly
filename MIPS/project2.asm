.data
	complete: .asciiz "Goodbye!"
	newLine: .asciiz "\n"
.text
	# i = 2
	addi $t0, $t0, 2
loop:	
	#print value
	li $v0, 1		
	move $a0, $t0		
	syscall
	
	#i = i + 2
	addi $t0, $t0, 2
	
	#print new line
	li $v0, 4
	la $a0, newLine
	syscall
	
	# if t0 < 10, branch to loop
	ble $t0, 10, loop
	
	#display complete message
finish:	li $v0, 4
	la $a0, complete
	syscall
	
