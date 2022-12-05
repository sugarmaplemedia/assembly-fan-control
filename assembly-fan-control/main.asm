;
; main.asm
;
; Created: 11/30/2022 12:13:05 PM
; Authors : River Smith, Harrison Bouche
;

;
; START ARDUINO SETUP CODE
;

.cseg
.org 0x00
rjmp reset
.org INT0addr
rjmp INT0_vect
.org 0x34

	ldi R16, HIGH(RAMEND)
	out SPH, R16
	ldi R16, LOW(RAMEND)
	out SPL, R16

;ports
LDI R16, 0xFF ;(all ones)
out DDRC, R16 ; Port C initialized to output / send info to LEDs

LDI R17, 0x00 ; (all zeroes)
out DDRA, R17 ; Port A initialized to input / takes in temperature

LDI r18, 0x00110010 ; setting fan register to 50

LDI r19, 0x00011001 ;min fan speed 25%

LDI r20, 0x01100100 ;max fan speed 100%

LDI r21, 0x1000110101 ;30 celsius for temp to be at
;create variable for thermistor value to be

;
; END ARDUINO SETUP CODE
;


;
; START ADC CODE
;

; ADC setup
initial_ADC:
	ldi R16, 0x20
	sts ADMUX, R16
	ldi R16, 0x97
	sts ADCSRA, R16
	clr R16 ; equivalent to ldi R16, 0x00
	sts ADCSRB, R16

; start ADC conversion
SC:
	lds R16, ADCSRA
	ori R16, 0b01000000 ; enable ADSC to trigger conversion

; check conversion status
CheckEOC:
	lds R16, ADCSRA
	SBRS R16, ADIF ; check if bit 7 of register 16 is equivalent to ADIF (bit 5 of ADCSRA), skip if true
	RJMP CheckEOC
	CALL ReadAOC

; to read retrieved data
ReadADC:
	clr R24
	clr R25
	lds R24, ADCL ; retrieve two most significant bits (transfer signals) of data in bits 8 and 7 of register
	lds R25, ADCH ; retrieve first 8 bits of data, actual data
	; 10 bits of data retrieved in backwards (from binary) order
	RET

;
; END ADC CODE
;


;
; START FAN CONTROL CODE
;

main:
	Call TempCheck ;call to check the temp right away may include branches instead of call

TempCheck: ;Checks the temperature of the thermistor and then sees if temp is lower or higher than it should be
	CPI r17, r21
	BR ;if temp read (r17) is lower than r21 then slow fan else if r17 is higher increase fan if neither keep speed.

FanSpeedInc: ;increases fan speed to increase cooling to lower temp
	add r18, 0x01; add initial speed by 1 bit
	call delay
	rjmp TempCheck ;loops back to check fan speed 

FanSpeedDec: ;decreases fan speed to increase temp
	sub r18, 0x01 ;sub initial speed by 1 bit
	call delay
	rjmp TempCheck ;loops back to check fan speed 

TempStable: ;resistor has reached its targeted temp.
	rjmp main

Delay: ; 2 second delay to avoid constant reading.
	ldi r20, 163
	ldi r21, 86
	ldi r22, 0
L1: dec r22
	brne L1
	dec r21
	brne L1
	dec r20
	brne L1
	ret

;
; END FAN CONTROL CODE
;