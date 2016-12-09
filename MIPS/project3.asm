.data
	#init list with inital values
	array: .word 1, 2, 5, 7, 10
	store: .space 32 
	newLine: .asciiz "\n"	
.text
	la $s7, array		# instantiate array (first index in memory is in $s7, shouldn't manipulate this)
	add $t7, $t7, $s7	# store address of first memory location of array (manipulate this address)
	
	la $s6, store		# init sescond array (empty)
	add $t6, $t6, $s6 	# store address so we can manip
loop:	
	lw $t2, 0($t7)		# don't immediately store into $a0, because we need to test it later
	move $a0, $t2		# move value into $a0 so we can calculate
	jal factorial		# run factorial 
	
	#store value in array
	sw $v0, 0($t6)		# &t6 = $v0
	addi $t6, $t6, 4	# increment
	
	#print value
	move $t1, $v0		# temp store result into $t1
	li $v0, 1		# prep for integer display
	move $a0, $t1		# load value to display
	syscall

	#print new line
	li $v0, 4		# prep for string display
	la $a0, newLine		# load value to display
	syscall
	
	addi $t7, $t7, 4	# get next line
	bne $t2, 10, loop	# branch to loop if $t6 != 10

finish:	
	#end program
        li $v0, 10
        syscall
        
        
factorial:
	addi $sp, $sp, -8	#adjust stack for 2 items
	sw $ra, 4($sp)		#save return address
	sw $a0, 0($sp)		#save argument
	slti $t0, $a0, 1	#test for n < 1
	beq $t0, $zero, L1
	addi $v0, $zero, 1	# if so, result is 1
	addi $sp, $sp, 8	# pop 2 items from stack
	jr $ra			# return
L1:	addi $a0, $a0, -1	# else decrement n
	jal factorial		# recursive call
	lw $a0, 0($sp)		# restore original n
	lw $ra, 4($sp)		# and return address
	addi $sp, $sp, 8	# pop 2 items from stack
	mul $v0, $a0, $v0	# multiply to get result
	jr $ra			# and return
