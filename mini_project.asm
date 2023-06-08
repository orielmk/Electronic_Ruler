;********************************************************************
;
; Author        : Eliyahou Garti 302169354 & Oriel Kowler 312496045            
; Revised by	: 
;
; Date          : 23  December 2021
; Rev. Date:	: 23  December 2021
;
; File          : mini_project.asm
;
; Hardware      : Any 8052 based MicroConverter (ADuC8xx)
;
; Purpose       : Implementing an Electronic Ruler 
;
; Description   : 
;				  				  
;*******************************************************************

#include <ADUC841.H>

CSEG AT 0000H 			 ; Upon power up, the processor jumps here.
JMP  MAIN				 ; Jump to main

CSEG AT 000BH 			 ; Timer 0 ISR

JB FLAG, INCREMENT       ; Check the FLAG
JMP END_CASE2
INCREMENT:
INC DAC0L				 ; Increment DACOL

END_CASE2:
RETI

CSEG AT 0023H 			 ; UART ISR
						 ; Push and pop for case that in the main program, we are using different value of A, 
						 ; So in the interrupt we are changing the value

PUSH ACC				 ; Push acc to the stack

CLR  RI					 ; clear for know when we got another input.

MOV A, SBUF				 ; insert the value to A
CJNE A, #'O' , F_CASE	 ; check if pressed 'O'
SETB FLAG  				 ; Turn On Flag
JMP  END_CASE
F_CASE:
CJNE A, #'F' , ERROR_CASE	 ; check if pressed 'F'
CLR  FLAG				 ; Clear FLAG
JMP  END_CASE

ERROR_CASE:

END_CASE:
POP ACC					 ; Pop acc from the stack

RETI

CSEG AT 0033H			 ; Interrupt of ADC
MOV DAC1H, ADCDATAH		 ; Move data from ADC to DAC - bits 8-11(without use bits 12-15)
MOV DAC1L, ADCDATAL		 ; Move data from ADC to DAC - bits 0-7			 
RETI

CSEG AT 0100H
MAIN:

CLR DMA                  ; Without use of DMA
CLR CS3					 ; Input channel 4
SETB CS2
CLR CS1
CLR CS0
ORL ADCCON3, #10000000B   ; Enable ADC without change ADCCON3 other bits

SETB EADC				 ; Enable interrupt of ADC
SETB EA					 ; Enable interrupts global

JB P3.2, FIVE_CASE

ZERO_CASE:
SETB TR2				 ; Turn on TIMER 2
CLR CNT2				 ; Use TIMER 2 as timer
CLR CAP2           		 ; Automatically reload
MOV RCAP2L, #00H		 ; TIMER 2 to be overflow every 5 ms
MOV RCAP2H, #28H

MOV ADCCON1, #10111010B  ; P3.2 0V - Definition of ADCCON1
SETB SCONV  			 ; Set single conversion - sampling rate: 200 Samp/s
CLR CCONV				 ; Clear continuous conversion

JMP FINISH

FIVE_CASE:
MOV ADCCON1, #10111000B  ; P3.2 5V - Definition of ADCCON1
SETB CCONV      		 ; Set continuous conversion - sampling rate: 300kSamp/s
CLR SCONV				 ; Clear single conversion

FINISH:
ANL DACCON, #00101001B   ; Definition DAC1 without change DAC0
ORL DACCON, #01010110B

JMP $
	
END
; conclusion:
;
; In the debugger we set in channel 4 value, and get in channel 1 duplicate value, 
; for example we set 19mV and we get at DAC1 37.8 mV.
; The difference between the Input to the Output is because the difference between 2.5 V at the Input 
; to 5 V at the Output.
;
; In the PicoScope when we set 1KHz sine wave with the AWG without pressed INT0 we get a sine wave.
; When we pressed INT0 we get a long wave that not connection to the sine wave, this is happen because the rate sampled is 
; every 5 mS (200 Samp/s), but when we not pressed int0 we accept a sine wave - because the rate sampled is close to 300 kSamp/s
;
; Now we set 10 KHz sine wave with the AWG without pressed INT0 and we get a sine wave with little stepps so it's convenient 
; to measure the width of one step - we measured and accept 3.428us so it's frequency of 291.715 kSamp/s as we expected to be close
; to 300KSamp/s.
