.equ LEDS, 0xFF200000
.equ AUDIO_CORE, 0xFF203040
.equ TIMER2, 0xFF202020
.equ PERIOD, 100000000

.global TIMERFLAG
.global EXITFLAG

TIMERFLAG:
	.word 0x0
EXITFLAG:
	.word 0x0
	
.global audioDemo

audioDemo:
	
	#prologue
	subi sp, sp, 44
	stw ra, 0(sp)	#return address
	stw r8, 4(sp)	#Timer2
	stw r9, 8(sp)
	stw r10, 12(sp)
	stw r11, 16(sp)
	stw r12, 20(sp)
	stw r13, 24(sp)
	stw r14, 28(sp)
	stw r15, 32(sp)
	stw r16, 36(sp)
	stw r17, 40(sp)
	
	movia r8, TIMER2		#r8 = TIMER2

	#Timer init
							#r9 = temp register
	#timer initialization
	movui r9, %lo(PERIOD)	#set period
	stwio r9, 8(r8)
	movui r9, %hi(PERIOD)
	stwio r9, 12(r8)
	stwio r0, 0(r8)			#clear timer
	movui r9, 0b0001		#do not start, not continuous, int enabled
	stwio r9, 4(r8)
	
	movi r9, 1
	wrctl ctl0, r9	#enable PIE
	movi r9, 0b0100
	wrctl ctl3, r9	#enable IRQ2

	#keypad inputs will trigger audio to be played using TIMER2 with sound
	#value given as parameter
	#24 = game win, 28 = correct, 96 = incorrect
	movi r9, 0b0101	#start, not continuous, int enabled
	stwio r9, 4(r8)	#start timer
	call PLAYSOUND		#will play for 1 sec
	
	
LOOP:
	movia r9, EXITFLAG
	ldw r9, 0(r9)
	beq r9, r0, LOOP 		#loop until exit flag is high

	#epilogue **********************************
	ldw ra, 0(sp)	#return address
	ldw r8, 4(sp)	#Timer2
	ldw r9, 8(sp)
	ldw r10, 12(sp)
	ldw r11, 16(sp)
	ldw r12, 20(sp)
	ldw r13, 24(sp)
	ldw r14, 28(sp)
	ldw r15, 32(sp)
	ldw r16, 36(sp)
	ldw r17, 40(sp)
	addi sp, sp, 44
	ret

# *** SUBROUTINES ***

PLAYSOUND:
	subi sp, sp, 28
	stw r10, 0(sp)
	stw r11, 4(sp)
	stw r12, 8(sp)
	stw r13, 12(sp)
	stw r14, 16(sp)
	stw r15, 20(sp)	#AUDIO
	stw r16, 24(sp)

    movia r15, AUDIO_CORE	# Audio device base address: DE1-SoC
    movia r13, 0x60000000	# Audio sample value
    mov r12, r4

WaitForWriteSpace:
	movia r14, TIMERFLAG
	ldw r16, 0(r14)
	bne r16, r0, EXITSOUND
    ldwio r11, 4(r15)
    andhi r10, r11, 0xff00
    beq r10, r0, WaitForWriteSpace
    andhi r10, r11, 0xff
    beq r10, r0, WaitForWriteSpace
    
WriteTwoSamples:
    stwio r13, 8(r15)
    stwio r13, 12(r15)
    subi r12, r12, 1
    bne r12, r0, WaitForWriteSpace
    
HalfPeriodInvertWaveform:
    mov r12, r4
    sub r13, r0, r13				# 32-bit signed samples: Negate.
    br WaitForWriteSpace

EXITSOUND:
	ldw r10, 0(sp)
	ldw r11, 4(sp)
	ldw r12, 8(sp)
	ldw r13, 12(sp)
	ldw r14, 16(sp)
	ldw r15, 20(sp)
	ldw r16, 24(sp)
	addi sp, sp, 28
	wrctl ctl3, r0					#No IRQs enabled
	ret

