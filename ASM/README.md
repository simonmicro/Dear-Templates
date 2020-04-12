---
title: ASM
summary: Some overview of ASM code for ATMEGA16
type: blog
slug: .
banner: "/img/dear-templates/default.jpg"
---

### Note ###
This code has been tested and developed with the [Atmel Studio 7.0](http://studio.download.atmel.com/7.0.2397/as-installer-7.0.2397-full.exe) for an ATMEGA16 chip.
You should also consult the instruction manual from [here](http://ww1.microchip.com/downloads/en/devicedoc/atmel-0856-avr-instruction-set-manual.pdf)!

```
; Get the default definitions for this chip (not really needed in this example)
; .INCLUDE "m16def.inc"

; Start the data definition segment
.DSEG

; Define some symbols (like #define from C++)
.EQU CONSTANT=0xEE

; Define as other name for a register
.DEF TEMP=R16

; Define some data (in the RAM)
var1: .byte 1 ; A named var with sizof 1
array1: .byte 42 ; A named var with sizeof 42 => array
; To create a var with sizeof 4 and {1, 2, 3, 4} you have to put them into the .CSEG -> see down @array2

; Lets define a marco
.MACRO DOSHIT
	INC R17
.ENDMACRO

; Lets define a macro with "parameters" @0 and @1
.MACRO DOMORESHIT
	INC @0
    DEC @1
.ENDMACRO

; Start the code segment
.CSEG

; Init stack pointer by using a temporary value named R16
LDI TEMP, LOW(RAMEND)
OUT SPL, TEMP
LDI TEMP, HIGH(RAMEND)
OUT SPH, TEMP

; Start MAIN loop
INIT:
	LDI R16, 0x00 ; Reset our R16 after its use from above...
	LDI R17, 0x00
MAIN:
	PUSH R16 ; Save R16 to stack
	INC R17 ; Increase R17
	DOSHIT ; Same
    DOMORESHIT R16, R16 ; Does "nothing"
	LDI R16, CONSTANT ; Load out constant into the R16
	POP R16 ; ... and restore R16 from stack
	CALL SUB1 ; Got into a subprog (store address of next line in stack)...
	CALL SUB2 ; ...
	JMP MAIN ; Back to start...

SUB1:
	LDI	ZL, LOW(2*array2) ; Why 2*? Because we use word sizes to address in PROGMEM. And one word are two bytes -> see http://www.rjhcoding.com/avr-asm-pm.php
	LDI	ZH, HIGH(2*array2)
	; Now to cite "https://www.motherboardpoint.com/threads/accessing-arrays-in-avr-assembly.88733/": The trick is to use the X (r26,r27), Y (r28,r29) or Z (r30,r31) register as the array pointer.
	LPM R20, Z + 0 ; Now load from PROGMEM by using the Z-pointer
	LPM R21, Z + 1
	LPM R22, Z + 2
	LPM R23, Z + 3
	RET ; -> Pop addr from stack and go back...

SUB2:
    ; Lets create a working copy of the pointer to the array1 and write to it...
	LDI YL, LOW(array1)
	LDI YH, HIGH(array1)
    ; Now Y points to the first element of array1 and is writeable...
	ST Y, R20 ; Now store to RAM by using the Y-pointer (reg to FIRST element)
	ST Y, R21 ; (reg to FIRST element)
	ST Y, R22 ; (reg to FIRST element)
	ST Y, R23 ; (reg to FIRST element)
	ST Y+, R21 ; Now we store R21 to the first element and also increase pointer to point to the second element of our array...
	ST Y, R23 ; (reg to SECOND element)
	RET ; -> Pop addr from stack and go back...

; The following SHOULD be at the end of the CSEG, otherwise the code would be added AFTER this data... Bad. Because we start to execute at 0x0 // $0000
; @array2
.ORG $0100 ; Now set the "cursor" to address 0100
array2: .DB 1, 2, 3, 4 ; Put this values into the PROGMEM
```
