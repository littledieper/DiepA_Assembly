.data
	array: .space 32	# allocate space for array
	complete: .asciiz "Goodbye!"
	newLine: .asciiz "\n"
.text
	addi $t0, $t0, 2	# i = 2
	
	la $s7, array		# instantiate array (first index in memory is in $s7, shouldn't manipulate this)
	add $t7, $t7, $s7	# store address of first memory location of array (manipulate this address)
	sw $t0, 0($t7)		# store initial value into array

loop:	
	#print value
	li $v0, 1		
	move $a0, $t0		
	syscall
	
	#i = i + 2
	addi $t0, $t0, 2
	
	#add i into array
	addi $t7, $t7, 4
	sw $t0, 0($t7)
	
	#print new line
	li $v0, 4
	la $a0, newLine
	syscall
	
	# if t0 <= 10, branch to loop
	ble $t0, 10, loop
	
	#display complete message
finish:	li $v0, 4
	la $a0, complete
	syscall
	
