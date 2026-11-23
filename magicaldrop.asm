################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Hetvi Soni, 1009808237
# Student 2: Ved Thakar, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8 
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)

# 256/8 = 32, we chose the player to be 2 units tall. Each bubble is 2x2 units, 
# and we also add a 1 unit wide wall on all sides of the playing field 
# (so 28 + 1 + 1 + 2)
# where 28 is the height of the field, 1 for each wall, and 2 for the player.
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
COLOURS:
    .word 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
#Colours in the order black, red, green, blue, and yellow for the bubbles
WALL_GREY_COLOUR:
  .word 0x808080
PLAYER_COLOUR:
  .word 0x00ffff
DELETE_COLOUR:
    .word 0x000000
##############################################################################
# Mutable Data
##############################################################################
GRID:
  .space 392
# 392 comes from 98 cells * 4 bytes, where 98 = 7 * 14 grid
# we are storing data by each row, so the word at row r and column c is r*7 + c
PLAYER_COLUMN:
  .word 3
#The player's position will be in the third column (between columns 0 and 6)
keyboard_address:
 .word 0xffff0000
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    jal initialize_grid
    # Initialize the game
    
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	lw $t0, keyboard_address
    lw $t8, 0($t0) 
    beq $t8, 1, keyboard_input
    jal draw_wall
    jal draw_bubbles
    jal draw_player

	# 4. Sleep
    addi $v0, $zero, 32  # sleep
    addi $a0, $zero, 16  # about 16 ms or 60 frames/second
    syscall

    # 5. Go back to Step 1
    j game_loop
    
##############################################################################
# Milestone 1:
# this is a brief description of all the Labels for Milestone 1
# draw_rectangle: finds necessary address to fill the field with a rectangle
# rectangle_row_loop: the outer loop for drawing the rectangle
# rectangle_column_loop: the inner loop for drawing the rectangle; one row at a time
# next_row: goes to the next row
# rectangle_finish: returns the address once the rectangle is finished
# draw_wall: calls the draw_rectangle label 4 times to draw the four walls 
# initialize_grid: fills the first 6 rows with randomly picked bubbles
# initialize_loop: the loop to pick random bubble colours 
# done_initialization: marks if the grid has been initialized
# draw_bubbles: sets up the registers
# fill_bubble_row_loop: fills the bubbles
# fill_bubble_column_loop: fills the bubbles
# skip_bubble: skips any empty spaces
# bubble_next_row: goes to the next row
# bubble_fill_finish: indicates if the first 6 rows have been filled in or not
# draw_player: draws the stick-like player as a 2 by 2 block below the playing field 

# inputs: $a0 = x, $a1 = y, $a2 = width, $a3 = height, $s0 = colour
# temporary registers used: $t0-$t5
##############################################################################
draw_rectangle: 
# this label loads the base display address, calculates the x and y offsets, combines them, 
# finds the top left memory address and also intitalizes the row counter 
  la $t0, ADDR_DSPL # load the address display into register $t0
  lw $t0, 0($t0)    # the base address is set to $t0
  add $t3, $a3, $zero # inputs the height of the rectangle onto #t3
  sll $t1, $a1, 7   # shift $a1 (y) logically to the left by 7 (or by 128 = 32 bits * 4 bytes)
  sll $t2, $a0, 2  # shift $a0 (x) logically to the left by 2 (or by 4 bytes)
  add $t1, $t1, $t2   # obtains the sum of the offsets and puts it into $t1       
  add $t0, $t0, $t1   # obtains the address of the top left unit of the rectangle we are drawing       

rectangle_row_loop:
  beq $t3, $zero, rectangle_finish  #if this is true, then the rectangle is completed 
  add $t4, $t0, $zero  #inputs the address of the start of this row onto $t4, we need this copy because $t4 will be changing on each iteration, and we want $t0 to stay as is
  add $t5, $a2, $zero  #inputs the number of columns left onto $t5, we need this copy because $t5 will be changing on each iteration, and we want $a2 to stay as is

rectangle_column_loop:
  beq $t5, $zero, next_row  #if the columns remaining == 0, then the row is done
  sw $s0, 0($t4)  #paints the unit with the colour stored in $s0
  addi $t4, $t4, 4  #onto the next unit (shift by 4 bytes)
  addi $t5, $t5, -1  #removes one from the columns left that need to be painted
  j rectangle_column_loop  #repeat this until the row is done

next_row: 
  addi $t0, $t0, 128  #go to the next row
  addi $t3, $t3, -1  #subtracts one from the height that still needs to be painted
  j rectangle_row_loop 

rectangle_finish:
  jr $ra 

draw_wall:
  addi $sp, $sp, -8 #move the stack pointer by 8 bytes, to reserve $ra 
  sw $ra, 4($sp) #save $ra
  sw $s0, 0($sp) #save $s0
  la $t0, WALL_GREY_COLOUR  #loading grey onto $t0
  lw $s0, 0($t0)  #now $s0 is the grey colour, which is used as an input for draw_rectangle

  add $a0, $zero, $zero  # the top wall has inputs x=0, y=0, w=16, and h=1
  add $a1, $zero, $zero
  addi $a2, $zero, 16
  addi $a3, $zero, 1
  jal draw_rectangle

  add $a0, $zero, $zero  # the bottom wall has inputs x=0, y=29, w=16 and h=1
  addi $a1, $zero, 29
  addi $a2, $zero, 16
  addi $a3, $zero, 1
  jal draw_rectangle

  add $a0, $zero, $zero  # the left wall has inputs x=0, y=0, w=1 and h=30
  add $a1, $zero, $zero
  addi $a2, $zero, 1
  addi $a3, $zero, 30
  jal draw_rectangle

  addi $a0, $zero, 15  # the right wall has inputs x=15, y=0, w=1 and h=30
  add $a1, $zero, $zero
  addi $a2, $zero, 1
  addi $a3, $zero, 30
  jal draw_rectangle

  lw $s0, 0($sp)  # pop $s0 and $ra
  lw $ra, 4($sp)
  addi $sp, $sp, 8
  jr $ra

initialize_grid:
  la $t0, GRID  #inputing the current cell into $t0
  addi $t1, $zero, 42  #7*6 cells (or 6 rows) to be filled in with bubbles

initialize_loop: 
  beq $t1, $zero, done_initialization  #if $t1==0, then the initialization has been finsihed
  addi $v0, $zero, 42  #get a random number from 0 to 3
  add $a0, $zero, $zero
  addi $a1, $zero, 4
  syscall  # $a0 is either 0,1,2, or 3 
  
  addi $a0, $a0, 1  #add 1 to $a0 to have its range be 1,2,3, or 4
  sw $a0, 0($t0)  #then we store this colour code in the grid 
  addi $t0, $t0, 4  #move to the next cell
  addi $t1, $t1, -1  #subtract the number of cells left by one
  j initialize_loop

done_initialization:
  jr $ra #this returns the address if the grid has been intialized 

draw_bubbles:
  addi $sp, $sp, -20 #reserving space for 5 registers so that as the function changes $s0 to $s3, the original addresses are saved still
  sw $ra, 16($sp)
  sw $s0, 12($sp)
  sw $s1, 8($sp)
  sw $s2, 4($sp)
  sw $s3, 0($sp)
  la $s3, GRID 
  addi $s1, $zero, 1 #setting $s1 (y) to 1 

fill_bubble_row_loop:
  addi $t8, $zero, 29  #when y ==29, then all the 14 rows are done
  beq $s1, $t8, bubble_fill_finish
  addi $s2, $zero, 1  #sets $s2 (x) to 1

fill_bubble_column_loop:
  addi $t9, $zero, 15  #when x==15, the row is finished because we have reached the right wall
  beq $s2, $t9, bubble_next_row

  lw $t6, 0($s3)  #set $t6 to be the cell value
  beq $t6, $zero, skip_bubble  #when you have an empty cell, then don't draw anything
  la $t7, COLOURS  #load the colour address
  sll $t6, $t6, 2  #shift $t6 by 2 logically left (so by 4 bytes) as the offset
  add $t7, $t7, $t6  #find the address of the offsetted cell
  lw $s0, 0($t7)  #load that colour value

  add $a0, $s2, $zero  #the current x position  
  add $a1, $s1, $zero  #the current y position
  addi $a2, $zero, 2  #the width
  addi $a3, $zero, 2  #the height 
  jal draw_rectangle

skip_bubble:
  addi $s3, $s3, 4  #move to the next cell 
  addi $s2, $s2, 2  #change the x value by 2 
  j fill_bubble_column_loop  #then try again

bubble_next_row:
  addi $s1, $s1, 2 #changes the y value by 2 (moving to the next row)
  j fill_bubble_row_loop

bubble_fill_finish:
  lw $s3, 0($sp) #restoring the values that were reserved in <draw_bubbles>
  lw $s2, 4($sp)
  lw $s1, 8($sp)
  lw $s0, 12($sp)
  lw $ra, 16($sp)
  addi $sp, $sp, 20
  jr $ra

draw_player:
  addi $sp, $sp, -8  #reserving 8 bytes for 2 4 byte words
  sw $ra, 4($sp)  #return address
  sw $s0, 0($sp)  #the previous value of $s0

  la $t0, PLAYER_COLUMN  #load the address for the player's column
  lw $t0, 0($t0)
  sll $t0, $t0, 1 #shift the value logically to the left by 1 
  add $a0, $t0, $v1
  addi $a1, $zero, 30  #sets the player's height to the bottom of the playing field 
  addi $a2, $zero, 2
  addi $a3, $zero, 2
  la $t1, PLAYER_COLOUR  #load the player's colour to be used as a parameter in draw_rectangle
  lw $s0, 0($t1)
  jal draw_rectangle

  lw $s0, 0($sp)  #restore the registers from before 
  lw $ra, 4($sp)
  addi $sp, $sp, 8
  jr $ra

keyboard_input:
    lw $t2 , 4($t0)
    beq $t2 , 0x61, move_left
    beq $t2 , 0x64, move_right
    beq $t2 , 0x71, quit
    beq $t2 , 0x73, grab
    beq $t2 , 0x77, throw
    la $t1, COLOURS
    j draw_player
    
move_left:
    #jal DELETE_PLAYER
    addi $v1,$v1, -1
    j draw_player

move_right:
    addi $v1,$v1, 1
    j draw_player

quit:
  li $v0 , 10 
  syscall

grab: #the character picks up same-coloured bubbles from the column above

throw: #the character throws collected bubbles upward into the column above, stacking on existing bubbles
