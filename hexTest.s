.equ JP2_HEX, 0xFF200070

.equ HEX_0, 0x0EE
.equ HEX_1, 0x0DE
.equ HEX_2, 0x0BE
.equ HEX_3, 0x07E
.equ HEX_4, 0x0ED
.equ HEX_5, 0x0DD
.equ HEX_6, 0x0BD
.equ HEX_7, 0x07D
.equ HEX_8, 0x0EB
.equ HEX_9, 0x0DB


.global hexTest

hexTest: 

	#prologue 
	subi sp, sp, 24
	stw ra, 0(sp)
	stw r10, 4(sp)
	stw r13, 8(sp)
	stw r14, 12(sp)
	stw r15, 16(sp)
	stw r20, 20(sp)
	
	movia r10,JP2_HEX		#r10 = hex keypad

KEY_PRESSED:	
	movi r15, 700
DELAY_DEBOUNCE:
	subi r15,r15,1
	bne r15,r0,DELAY_DEBOUNCE
	
	ldwio r14, 0(r10)
	movi r15, 0x0000000F
	and r14,r14,r15
	mov r13, r14			#r13 has row data

COLS:
	movia r15,0x0F
	stwio r15,4(r10)  		# Set directions - rows to output, columns to input

	#stwio r0,(r10)   		# Drive all output pins low 

	movi r15, 700
DELAY_PREREAD2:
	subi r15,r15,1
	bne r15,r0,DELAY_PREREAD2

COL_LOOP:
	ldwio r14, 0(r10)		#read port data	
	movi r15, 0x000000F0
	and r14,r14,r15			#mask all but col bits
	
	or r13, r13, r14		#update data register to store col data	

	mov r20, r13

	br DECODE_HEX			#determine which button was pressed

DEBOUNCE:			
	movia r15, 10000000		#debounce loop			
DELAY:
	subi r15,r15,1
	bne r15,r0,DELAY

	br RETURN

DECODE_HEX:
	movi r15, HEX_0
	beq r20, r15, INPUT_0 	#if r20 holds value respresented by HEX_0
	movi r15, HEX_1
	beq r20, r15, INPUT_1 	#if r20 holds value respresented by HEX_1
	movi r15, HEX_2
	beq r20, r15, INPUT_2	#if r20 holds value respresented by HEX_2
	movi r15, HEX_3
	beq r20, r15, INPUT_3	#if r20 holds value respresented by HEX_3
	movi r15, HEX_4
	beq r20, r15, INPUT_4	#if r20 holds value respresented by HEX_4
	movi r15, HEX_5
	beq r20, r15, INPUT_5	#if r20 holds value respresented by HEX_5
	movi r15, HEX_6
	beq r20, r15, INPUT_6	#if r20 holds value respresented by HEX_6
	movi r15, HEX_7
	beq r20, r15, INPUT_7	#if r20 holds value respresented by HEX_7
	movi r15, HEX_8
	beq r20, r15, INPUT_8	#if r20 holds value respresented by HEX_8
	movi r15, HEX_9
	beq r20, r15, INPUT_9	#if r20 holds value respresented by HEX_9


INPUT_A:
	movi r20, 0x0A
	br DEBOUNCE
INPUT_0:
	movi r20, 0x00
	br DEBOUNCE
INPUT_1:
	movi r20, 0x01
	br DEBOUNCE
INPUT_2:
	movi r20, 0x02
	br DEBOUNCE
INPUT_3:
	movi r20, 0x03
	br DEBOUNCE
INPUT_4:
	movi r20, 0x04
	br DEBOUNCE
INPUT_5:
	movi r20, 0x05
	br DEBOUNCE
INPUT_6:
	movi r20, 0x06
	br DEBOUNCE
INPUT_7:
	movi r20, 0x07
	br DEBOUNCE
INPUT_8:
	movi r20, 0x08
	br DEBOUNCE
INPUT_9:
	movi r20, 0x09
	br DEBOUNCE

RETURN:
	mov r2, r20		

	#epilogue	
	ldw r20, 20(sp)
	ldw r15, 16(sp)
	ldw r14, 12(sp)
	ldw r13, 8(sp)
	ldw r10, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 24
	ret
	
