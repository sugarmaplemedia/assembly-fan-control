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

; Fucking shit port setting?
; LDI R17, 0x00 ; (all zeroes)
;out DDRA, R17 ; Port A initialized to input / takes in temperature

LDI r18, 0b00110010 ; setting fan register to 50

LDI r19, 0b00011001 ;min fan speed 25%

LDI r20, 0b01100100 ;max fan speed 100%

LDI r21, 0b1000110101 ;30 celsius for temp to be at
;create variable for thermistor value to be

;
; END ARDUINO SETUP CODE
;


;
; START ADC CODE
;

; ADC setup
initial_ADC:
	ldi R22, 0x20
	sts ADMUX, R22
	ldi R22, 0x97
	sts ADCSRA, R22
	clr R22 ; equivalent to ldi R16, 0x00
	sts ADCSRB, R22

; start ADC conversion
StartConversion:
	lds R22, ADCSRA
	ori R22, 0b01000000 ; enable ADSC to trigger conversion

; check conversion status
CheckEOC:
	lds R22, ADCSRA
	SBRS R22, ADIF ; check if bit 7 of register 16 is equivalent to ADIF (bit 5 of ADCSRA), skip if true
	RJMP CheckEOC
	CALL ReadAOC
	rjmp Main

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

Main:
	Call StartConversion ; check ADC for updated thermistor voltage value
	Call TempCheck ;call to check the temp right away may include branches instead of call
	rjmp Main

Display:
	out PORTC, r25
	RET

TempCheck: ;Checks the temperature of the thermistor and then sees if temp is lower or higher than it should be
	Call Display ; send numbers to LED displays
	Call Delay
	CP r25, r21
	BRLO FanSpeedDec
	BRSH FanSpeedInc
	RET

FanSpeedInc: ;increases fan speed to increase cooling to lower temp
	cpse r20, r18 ; skips next line if fan speed is at max value
	add r18, 0x01; add initial speed by 1 bit
	rjmp TempCheck ;loops back to check fan speed 

FanSpeedDec: ;decreases fan speed to increase temp
	cpse r19, r18 ; skips next line if fan speed is at min value
	sub r18, 0x01 ;sub initial speed by 1 bit
	rjmp TempCheck ;loops back to check fan speed 

Delay: ; 2 second delay to avoid constant reading.
	ldi r29, 163
	ldi r30, 86
	ldi r31, 0
L1: dec r31
	brne L1
	dec r30
	brne L1
	dec r29
	brne L1
	ret

;
; END FAN CONTROL CODE
;