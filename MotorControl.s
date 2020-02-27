	# Takes in user score 
	# If max score (10), then period set to 5 seconds 
	# If score if not equal to 10, period will be set to 1 second
	# While NOT Timeout, the motor will be on
	# Once timeout reached, motor turns off

	.equ ADDR_JP1, 0xFF200060   # Address GPIO JP1
	.equ PERIOD_1, 5000000 	#Period -> 0.5 seconds		
	.equ PERIOD_3, 7500000	#Period -> 0.75 second		
	.equ Timer2, 0xFF202020		# Address of Timer 1

.global MotorControl
.global FLAG
.global MOTOR_INT

MOTOR_INT:
	.word 0b00

FLAG:
	.word 0x0		#timeout = 1, end game

MotorControl:
	#prologue
	subi sp, sp, 36 
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	stw r10, 12(sp)
	stw r16, 16(sp)
	stw r17, 20(sp)
	stw r20, 24(sp)
	stw r21, 28(sp)
	stw r22, 32(sp)

	
	#set motor interrupt flag to high so interrupt handler knows to perform this interrupt
	movia r8, MOTOR_INT
	movi r9, 0b01
	stw r9, 0(r8)
	
	
	#score will be passed in
	
	movia r8, ADDR_JP1			# r8 = address of lego controller

	movia  r9, 0x07f557ff		# initialize direction register of lego
	stwio  r9, 4(r8)

	movia r10, Timer2			# r10 = Timer2
	
	movi r20, 0x01		
	wrctl ctl0, r20			#PIE enabled
	movi r20, 0b0100
	wrctl ctl3, r20			#IRQ 2
	
	movi r20, 9				#check to determine 'speed' of motor
	bgt r4, r20, fullSpeed

slowSpeed:
	movi r20, %lo(PERIOD_1)	#Period of 1 second 		
	stwio r20, 8(r10)
	movi r20, %hi(PERIOD_1)
	stwio r20, 12(r10)
	stwio r0, 0(r10) 		#clear
	movi r20, 0x07
	stwio r20, 4(r10) 		#initialize interrupt, continue and start	

	movia r21, 0xFFFFFFFC
	stwio r21, 0(r8)		#set motor 0 forwards
	br loop
	
fullSpeed:
	movi r20, %lo(PERIOD_3)	#Period of 3 seconds		
	stwio r20, 8(r10)
	movi r20, %hi(PERIOD_3)
	stwio r20, 12(r10)
	stwio r0, 0(r10) #clear
	movi r20, 0x07
	stwio r20, 4(r10) #initialize interrupt, continue and start
	
	movia r21, 0xFFFFFFFC
	stwio r21, 0(r8)		#set motor 0 forwards

#Keep looping until Timeout
loop:
	movi r17, FLAG	#If flag equals to 1, then return
	ldw r16, 0(r17)
	movi r22, 0x1
	bne r16, r22, loop

	#epilogue
	ldw r22, 32(sp)
	ldw r21, 28(sp)
	ldw r20, 24(sp)
	ldw r17, 20(sp)
	ldw r16, 16(sp)
	ldw r10, 12(sp)
	ldw r9, 8(sp)
	ldw r8, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 36
	wrctl ctl3, r0		#No IRQs enabled
	ret
