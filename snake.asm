


.data 0x10010000 			# Start of data memory

snake: .space 60
old: .space 60
fruit: .space 4
 


.text 0x00400000			# Start of instruction memory
main:
	lui	$sp, 0x1001		# Initialize stack pointer to the 64th location above start of data
	ori 	$sp, $sp, 0x0100	# top of the stack is the word at address [0x100100fc - 0x100100ff]
	
		
	ori	$a1, $0, 20			# initialize to middle screen col (X=20)
	ori	$a2, $0, 15			# initialize to middle screen row (Y=15)
	
	
	ori $t7, $0, 8 # snake length
	
	
initialize:
	addi $s0, $0, 50
	addi $a0, $0, 304
	jal put_fruit 	
	
	addi $a0, $0, 619
	sw $a0, snake($t7)
	jal coord
	addi $a1, $v0, 0
	addi $a2, $v1, 0

	jal     getChar_atXY
	sw $v0, old($t7)
	ori	$a0, $0, 2			# draw character 3 here
	jal putChar_atXY
	
	addi $t6, $0, 4 
	addi $a0, $0, 620
	sw $a0, snake($t6)
	jal coord
	addi $a1, $v0, 0
	addi $a2, $v1, 0

	jal     getChar_atXY
	sw $v0, old($t6)
	ori	$a0, $0, 2			# draw character 2 here
	jal putChar_atXY

	
	addi $a0, $0, 621

	sw $a0, snake($0)
	
	jal coord
	addi $a1, $v0, 0
	addi $a2, $v1, 0

	jal     getChar_atXY
	sw $v0, old($0)
	ori $a0, $0, 2			# draw character 2 here
	jal putChar_atXY
		
animate_loop:		

	#jal	move_2 		# $a0 is char, $a1 is X, $a2 is Y
	add	$a0, $0, $s0
		# pause for 1/2 second
	jal	pause
	
key_loop:	

	jal 	get_key			# get a key (if available)
	bne $v0, $0, sk
	add $v0, $0, $s4
	beq	$v0, $0, key_loop	# 0 means no valid key
sk:
	add $s4, $v0,$0

key1:

	bne	$v0, 1, key2
	addi	$a1, $a1, -1 		# move left
	slt	$1, $a1, $0		# make sure X >= 0
	beq	$1, $0, move_2
	j	blackout             # else, you hit a wall, game over      

key2:
	bne	$v0, 2, key3
	addi	$a1, $a1, 1 		# move right
	slti	$1, $a1, 40		# make sure X < 40
	bne	$1, $0, move_2
	j	blackout            # else, you hit a wall, game over

key3:
	bne	$v0, 3, key4
	addi	$a2, $a2, -1 		# move up
	ble     $a2, 0, blackout
	slt	$1, $a2, $0		# make sure Y >= 0
	beq	$1, $0, move_2
	j	blackout                # else, you hit a wall, game over

key4:
	bne	$v0, 4, key_loop	# read key again
	addi	$a2, $a2, 1 		# move down
	slti	$1, $a2, 30		# make sure Y < 30
	bne	$1, $0, move_2
	j	blackout              # else, you hit a wall, game over      



move_2 :
	add $t8, $0, $a1 
	add $t9, $0, $a2
	
	jal getChar_atXY # get the character at current values of X and Y ($a1 and $a2) 	
	beq $v0, 2, blackout  # if the character is the color of the snake, game over 
	
	addi $t1, $v0, 0
	

	lw $t4, old($0) # save the color of the background behind the head in a temporary value 
	sw $v0, old($0) # save the new color behind where we're trying to move the head w/here ^ used to be 
	
	addi $a0, $0, 2  
	jal putChar_atXY   # physically draw the head, which is blue 
	
	lw $t5, snake($0) # save what used to be the head location in a temp 
	jal uncoord          #  convert the current x and y values of the new head to a raw number 
	sw $v0, snake($0)           # write over the head location with a new head location
	
	addi $t3, $0, 4 # set a temporary = 4 

	
loops: 
	bgt $t3, $t7, endloop # if temp > length of the snake, break loop 
	
	add $t6, $t5, $0  # move the temps into the other temps 
	add $t2, $t4, $0
	lw $t5, snake ($t3) # t5 = next value of snake 
	lw $t4, old ($t3) # t4 = next value of color behind snake 
	sw $t6, snake($t3) # make the head location the new tail location 
	sw $t2, old($t3) # make what used to be the color behind the head the new color behind the  tail 
	addi $t3, $t3, 4
	j loops
endloop:	

	
	addi $a0, $t5, 0 
	jal coord 
	addi $a1, $v0, 0  
	addi $a2, $v1, 0 # put these coordinates in a1 and a2	
	beq $t1, 3, enderasetail
	
	addi $a0, $t4, 0 
	

		
	jal putChar_atXY # put the color back 
	
enderasetail:		
# fruitstuff 

	bne $t1, 3, endfruitstuff   # only do this next part if fruit

	lw $t2, fruit($0)
	sw $t2, old($0)
	
	addi $t7, $t7, 4 
	
	sw $t5, snake($t7) 
	sw $t4, old($t7)

	  
	addi $a0, $t0, 0
	jal put_fruit 
	ble $s0, 10, slabel
	addi $s0, $s0, -5
slabel:
endfruitstuff:
	
	add $a0, $t0, $0

	addi $a1, $0, 1200
	addi $a2, $0, 1193
	jal random
	add $t0, $0, $v0	
	
	add $a1, $0, $t8
	add $a2, $0, $t9
	
		
	j animate_loop
	

put_fruit: 
	#addi $a0, $t0, 0 
	
	addi $sp, $sp, -8   # make room on stack
  	 sw $ra, 4($sp)      # save $ra
 	 sw $fp, 0($sp)      # save $fp
 	 addi $fp, $sp, 4    # set $fp 
	
       	jal coord 
	
   	 lw  $ra, 0($fp)     # restore $ra 
    	addi $sp, $fp, 4    # restore $sp
  	 lw  $fp, -4($fp)    # restore $fp  	 
  	 
  	 addi $a1, $v0, 0
  	 addi $a2, $v1,0
   
  	 
  	 addi $sp, $sp, -8   # make room on stack
  	 sw $ra, 4($sp)      # save $ra
 	 sw $fp, 0($sp)      # save $fp
 	 addi $fp, $sp, 4    # set $fp 
	
	jal getChar_atXY 
	
	 lw  $ra, 0($fp)     # restore $ra 
    	addi $sp, $fp, 4    # restore $sp
  	 lw  $fp, -4($fp)    # restore $fp
  	 
  	 sw $v0, fruit($0)
  	 
  	 addi $a0, $0, 3
  	 
  	 
	addi $sp, $sp, -8   # make room on stack
  	 sw $ra, 4($sp)      # save $ra
 	 sw $fp, 0($sp)      # save $fp
 	 addi $fp, $sp, 4    # set $fp 
	
	jal putChar_atXY 
	
	 lw  $ra, 0($fp)     # restore $ra 
    	addi $sp, $fp, 4    # restore $sp
  	 lw  $fp, -4($fp)    # restore $fp
  	 
  	 
	jr $ra
				
blackout:	
	ori $a0, $0, 2
	or $t1, $0, $0
	dump:   
	or $t0, $0, $0
		dump1:
		or $a1, $0, $t0 
		jal putChar_atXY
		addi $t0, $t0, 1	
		bne $t0, 40, dump1 
	or $a2, $0, $t1
	addi $t1,$t1,1 
	bne $t1, 31, dump	
	ori $a0, $0, 227273
	jal put_sound
	addi	$a0, $0, 25
	jal pause
	add	$a0, $0, $0
	jal put_sound
	j end
					

	
	
									
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit





.include "procs_board.asm"
