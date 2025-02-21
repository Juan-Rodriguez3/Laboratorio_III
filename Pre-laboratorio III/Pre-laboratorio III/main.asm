; Universidad del Valle de Guatemala
; IE2025: Programacion de Microcontroladores
;
; Author: Juan Rodriguez
; Proyecto: Prelab III
; Hardware: ATmega328P
; Creado: 20/02/2025
; Modificado: 20/02/2025
; Descripcion: Implementaci?n de interrupciones
;*********************

.include "M328PDEF.inc"
.cseg
.org 0x0000
    RJMP SETUP  ; Ir a la configuraci?n al inicio

.org PCI1addr  ; Vector de interrupci?n para PCINT1 (PORTC)
    RJMP ISR_PCINT1

	// Configuracion de la pila
	LDI		 R16, LOW(RAMEND)
	OUT		 SPL, R16
	LDI		 R16, HIGH(RAMEND)
	OUT		 SPH, R16

// Configuracion MCU
SETUP:
	// Configurar PB como salida para usarlo como del contador 
	LDI		R16, 0xFF
	OUT		DDRB, R16						// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16						//El puerto B conduce cero logico.

	 //Puerto C como entrada
	LDI		R16, 0x00
	OUT		DDRC, R16
	LDI		R16, 0xFF
	OUT		PORTC, R16						//Pull-up

	//Habilitar interrupciones en el pin C

	LDI		R16, (PCIE1<<1)					//Encender PCIE1 en PCICR
	STS		PCICR, R16						//Configurar interrupciones puerto C
	LDI		R16, 0x03						//Configurar PC0 y PC1 en 
	STS		PCMSK1, R16	

	NOP
	NOP
	LDI		R18, 0x00						//Salida de los leds

	SEI										//Habilitar interrupciones globales

MAIN:
	RJMP	MAIN

//Subrutinas

SUMA:
	INC		R18								//Incrementa contador
	CPI		R18, 0x10						//Comparar con 16
	BREQ	OVERF
	
	RJMP	FIN
RESTA:
	CPI		R18, 0x00						//Compara el contador			
	BREQ	UNDERF							
	DEC		R18								//Decrementa el contador
	RJMP	FIN

OVERF:
	LDI		R18, 0x00						//Reiniciar el contador a 0
	RJMP	FIN
UNDERF:
	LDI		R18, 0x0F						//Reiniciar el contador a 15
	RJMP	FIN


//Subrutinas de interrupciön
ISR_PCINT1:	
	IN		R17, PINC						//Leer el estado de los botones
	SBRS	R17, 0							//Salta si el bit 0 esta en set
	RJMP	SUMA
	SBRS	R17, 1							//Salta si el bit 1 esta en set
	RJMP	RESTA
FIN:
	OUT		PORTB,	R18						//Actualiza la salida,
	RETI


