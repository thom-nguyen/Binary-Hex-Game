.equ Timer, 0xFF202000
.equ LED, 0xFF200000
.equ PERIOD, 100000000
.equ HEX0, 0xFF200020 
.equ JP2_HEX, 0xFF200070

.data
#variables
GLOBAL_COUNTER:
	.word 0x0
HEX_VALUE:
	.word 9
GAME_OVER:						# 0 = not over, 1 = game over
	.word 0x0
RANDOM_NUM:
	.word 0x0
USER_ANSWER:
	.word 0x00
CORRECT:						# 0 = incorrect, 1 = correct
	.word 0x1		
USER_SCORE:
	.word 0x0
MULTIPLIER:
	.word 0b01
	
.section .text

.global main
main:
	#initialize
	movia sp, 0x04000000
	movia r8, HEX0					# r8 = HEX ADDRESS
	movia r20, 0x0000003F			# r20 = temp variable
	stwio r20,0(r8)
	
	movia r20, HEX_VALUE
	ldw r21, 0(r20)					# r21 = Initializing Counter to 9 (HEX counter)
	movia r20, GLOBAL_COUNTER
	ldw r22, 0(r20)					# r22 = Global Counter initialzied to 0
	
	movia r9, Timer					#r9 = Timer1
	movi r20, %lo(PERIOD)			
	stwio r20, 8(r9)
	movi r20, %hi(PERIOD)
	stwio r20, 12(r9)
	stwio r0, 0(r9) #clear
	movi r20, 0b0111
	stwio r20, 4(r9) 				#initialize interrupt, continue and start

	movi r20, 0x01
	wrctl ctl0, r20		#enable IRQ
	wrctl ctl3, r20		#PIE enabled
	
	#call seedInit
	#call getRandNums			#calling subroutine in main.s
	movi r2, 67			#	***
	movi r20, RANDOM_NUM	#initialize first random number
	stw r2, 0(r20)
	movia r20, LED		#initialize LEDs to first random number
	stwio r2, 0(r20)
	
loop:								#this loop will go on until game is over

	movi r20, GAME_OVER
	ldw r20, 0(r20)					#r20 contains game state
	bne r20, r0, endgame			#if game is over, go to end game sequence
	
ROWS:
	movia r20,JP2_HEX		#if game is not over, poll until hex keypad press is detected
	movia r15,0x0F0			#r15 = temp register
	stwio r15,4(r20)  		# Set directions - rows to input, columns to output 

	stwio r0,(r20)   		# Drive all output pins low 

	movi r15, 700
DELAY_PREREAD:				#delay for debounce
	subi r15,r15,1
	bne r15,r0,DELAY_PREREAD

ROW_LOOP:
	ldwio r20, 0(r20)		#read port data
	movi r15, 0x0000000F
	and r20,r20,r15			#mask all but last 4 bits to determine which bits are 0 (active low)
	beq r15, r20, loop		#if nothing pressed, keep polling

	movia r21, USER_ANSWER
	call hexTest			# hex keypad subroutine to update USER_ANSWER, r2 has button pressed
	
	#ignore invalid inputs
	movi r15, 0x0A
	beq r2, r15, loop

	ldw r15, 0(r21)			# r15 has answer so far
	movia r20, MULTIPLIER
	ldw r20, 0(r20)			#get current multiplier value, place into r20
	mul r15, r15, r20
	add r15, r2, r15		#add what was pressed to current answer * tens multiplier
	stw r15, 0(r21)
	movia r20, MULTIPLIER
	ldw r15, 0(r20)			#get current multiplier value, place into r15
	muli r15, r15, 10		#multiply current multiplier value by 10, place into r15
	stw r15, 0(r20)			#store updated multiplier value into memory

	br loop					#keep polling

endgame:
	movia r9, Timer					#stop timer running interrupts
	movi r20, 0b00
	stwio r20, 4(r9) 				#disable interrupt, dont continue and do not start
	wrctl ctl3, r0					#PIE disabled
	
	movi r21, USER_SCORE			#get user score
	ldw r4, 0(r21)

	movi r20, 10					#check if user got 10/10 points
	blt r4, r20, LOST_SOUND
	
WON_SOUND:
	movi r4, 24
	br CALL_AUDIO
LOST_SOUND:
	movi r4, 96

CALL_AUDIO:
	#calling audio demo  to play sound for 1 sec
	call audioDemo 
	
	ldw r4, 0(r21)
	call MotorControl
	

LOOP_FOREVER:
	br LOOP_FOREVER						#loop forever

	
# *** SUBROUTINES ***
checkAndResetAnswer:
	subi sp, sp, 16
	stw ea, 0(sp)
	stw r16, 4(sp)					# r16 = subroutine temp
	stw r17, 8(sp)			
	stw r18, 12(sp)			
	
	movia r16, RANDOM_NUM
	ldw r17, 0(r16)
	movia r16, USER_ANSWER
	ldw r18, 0(r16)
	beq r17,r18, CORRECT_ANSWER			#load both numbers from memory and check if equal
	
INCORRECT_ANSWER:
	movia r16, CORRECT
	movi r17, 0x0
	stw r17, 0(r16)						
	#***************#will play sound at end of game**********
	br EXIT_CHECK

CORRECT_ANSWER:
	movia r16, USER_ANSWER				# reset user answer to 0
	stw r0, 0(r16)
	movia r16, CORRECT
	movi r17, 0x01
	stw r17, 0(r16)			
	movia r16, USER_SCORE				#increment user score
	ldw r17, 0(r16)
	addi r17, r17, 0b01
	stw r17, 0(r16)
	#call getRandNums					#get next random number, returned in r4
	movi r2, 24				#	***
	movi r20, RANDOM_NUM	
	stw r2, 0(r20)
	movia r20, LED						#set LEDs to display new rand num
	stw r2, 0(r20)

	movia r20, MULTIPLIER
	movi r16, 0b001
	stw r16, 0(r20)						# reset multiplier value to 1

	movi r16, 300
QUICKDELAY:
	subi r16,r16,1
	bne r16,r0,QUICKDELAY
	
EXIT_CHECK:
	ldw ea, 0(sp)
	ldw r16, 4(sp)	
	ldw r17, 8(sp)			
	ldw r18, 12(sp)			
	addi sp, sp, 16
	ret

# *** INTERRUPTS ***

.section .exceptions, "ax"
Interrrupt:
	addi sp,sp, -28
	stw et, 0(sp)
	stw ea, 4(sp)
	stw r16, 8(sp)
	stw r18, 12(sp)
	stw r11, 16(sp)
	stw r21, 20(sp)
	stw r22, 24(sp)

	movia et, HEX_VALUE
	ldw r21, 0(et)	
	movia et, GLOBAL_COUNTER
	ldw r22, 0(et)	

	rdctl et, ctl4							#check which IRQ was called
	movi r18, 0b01
	beq et, r18, TIMER1_INT					#IRQ 0 (TIMER1)				
	movi r18, 0b0100		
	beq et, r18, TIMER2_INT					#IRQ2 (TIMER2) used in audioDemo
	br Exit

TIMER1_INT:

#get start value for HEX display
checkStart:
	bne r0, r21, GetHexVal
	call checkAndResetAnswer
	movia et, CORRECT
	ldw et, 0(et)							#check if answer at end of cycle was correct
	beq et, r0, GAME_OVER_LOSE
	movi r18, 51
	bge r22, r18, setToZero					#determine which number to start at
	movi r18, 48
	bge r22, r18, startAtTwo
	movi r18, 42
	bge r22, r18, startAtThree
	movi r18, 32
	bge r22, r18, startAtFive
	movi r18, 18
	bge r22, r18, startAtSeven
	movi r21, 0b0000000000001001
	br GetHexVal

setToZero:
	movi r21,0b0000000000000000
	br GetHexVal

startAtTwo:
	movi r21,0b0000000000000010
	br GetHexVal

startAtThree:
	movi r21,0b0000000000000011
	br GetHexVal

startAtFive:
	movi r21,0b0000000000000101
	br GetHexVal

startAtSeven:
	movi r21,0b0000000000000111

	
GetHexVal:								#Get corresponding HEX pattern
	movi r18, 0b0000000000001001
	beq r21, r18, print9

	movi r18, 0b0000000000001000
	beq r21, r18, print8

	movi r18, 0b0000000000000111
	beq r21, r18, print7

	movi r18, 0b0000000000000110
	beq r21, r18, print6

	movi r18, 0b0000000000000101
	beq r21, r18,print5

	movi r18, 0b0000000000000100
	beq r21, r18, print4

	movi r18, 0b0000000000000011
	beq r21, r18, print3

	movi r18, 0b0000000000000010
	beq r21, r18, print2

	movi r18, 0b0000000000000001
	beq r21, r18, print1

	movi r18, 0b0000000000000000
	beq r21, r18, print0

print9:
	movia r16, 0x000000EF
	stwio r16,0(r8)
	br TimerInterrupt

print8:
	movia r16, 0x000000FF
	stwio r16,0(r8)
	br TimerInterrupt

print7:
	movia r16, 0x00000007
	stwio r16,0(r8)
	br TimerInterrupt

print6:
	movia r16, 0x0000007D
	stwio r16,0(r8)
	br TimerInterrupt

print5:
	movia r16, 0x0000006D
	stwio r16,0(r8)
	br TimerInterrupt

print4:
	movia r16, 0x00000066
	stwio r16,0(r8)
	br TimerInterrupt

print3:
	movia r16, 0x0000004F
	stwio r16,0(r8)
	br TimerInterrupt

print2:
	movia r16, 0x0000005B
	stwio r16,0(r8)
	br TimerInterrupt

print1:
	movia r16, 0x00000006
	stwio r16,0(r8)
	br TimerInterrupt

print0:
	movia r16, 0x0000003F
	stwio r16,0(r8)
	wrctl ctl3, r0		#PIE disabled
	movi r16, GAME_OVER
	movi et, 0b01
	stw et, 0(r16)		#set game over flag to high
	br Exit

TimerInterrupt:
	movia et, Timer
	stwio r0, 0(et) 					# acknowledge timer
	movia et, 0x01
	#wrctl ctl0, et
	subi r21,r21,0b01					#decrementing HEX counter
	movia et, HEX_VALUE
	stw r21, 0(et)
	addi r22,r22,0b01					#incrementing global counter
	movia et, GLOBAL_COUNTER
	stw r22, 0(et)
	br Exit

GAME_OVER_LOSE:
	movi et, 0x01						#game lost
	movia r16, GAME_OVER
	stw et, 0(r16)	
	wrctl ctl3, r0		#PIE disabled
 	br Exit




TIMER2_INT:
	movia r16, MOTOR_INT		#check if audio int or motor int
	ldw r16, 0(r16)
	bne r16, r0, RUNMOTOR
	
TOGGLESOUND:
	stwio r0, 0(r8)				#ack timeout TIMER2
	movia r16, TIMERFLAG
	movi r18, 0b01
	stw r18, 0(r16)
	movia r16, EXITFLAG			#set flags to high to indicate timer2 timeout
	stw r18, 0(r16)
	br Exit

RUNMOTOR:
	movia r16, 0xFF200060	#JP1 - motor
	movi r18, 0xFFFFFFFF
	stwio r18,0(r16) 		#set motor Off
	movia et, 0xFF202020	#timer 2
	stwio r0, 0(et) 		# acknowledge timer
	movia r16, FLAG
	movi r18, 0x01			#set timeout flag to high
	stw r18, 0(r16)


	
Exit:
	#wrctl ctl1, et
	ldw et, 0(sp)
	ldw ea, 4(sp)
	ldw r16, 8(sp)
	ldw r18, 12(sp)
	ldw r11, 16(sp)
	ldw r21, 20(sp)
	ldw r22, 24(sp)
	addi sp, sp, 28
	subi ea, ea, 4
	eret

