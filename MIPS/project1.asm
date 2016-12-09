.data
	listA: .word 10, 20, 30	# init listA with values 10, 20, 30
	listB: .word 1, 2, 3 	# init listB with 1, 2, 3
	
.text 	
	#instantiate lists
	la $s6, listA
	la $s7, listB
	
	#project 1 main code
	sll	$t0, $s0, 2 		#$t0 = f * 4
	add 	$t0, $s6, $t0 		#$t0 = &A[f]
	sll	$t1, $s1, 2 		#t1 = g * 4
	add 	$t1, $s7, $t1 		#t1 = &B[g]
	lw	$s0, 0($t0) 		#f = A[f]
	addi 	$t2, $t0, 4 		#$t2 = f + 4
	lw	$t0, 0($t2) 		#$t0 = &A[f+1]
	add 	$t0, $t0, $s0 		#$t0 = A[f+1] + A[f]
	sw	$t0, 0($t1)		#B[g] = A[f+1] + A[f]

	#display result
	li $v0, 1
	lw $a0, 0($s7)
	syscall

