;*********************
; Universidad del Valle de Guatemala
; IE2025: Programacion de Microcontroladores
;
; Author: Juan Rodriguez
; Proyecto: Prelab III
; Hardware: ATmega328P
; Creado: 20/02/2025
; Modificado: 20/02/2025
; Descripcion: Implementación de interrupciones
;*********************

.include "M328PDEF.inc"
.cseg
.org 0x0000
    RJMP SETUP  ; Ir a la configuración al inicio

.org PCI1addr  ; Vector de interrupción para PCINT1 (PORTC)
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
	LDI		R16, (PCINT8<<1) | (PCINT9<<1)	//Configurar PC0 y PC1 en 
	STS		PCMSK1, R16						//Cargar la configuración de los pines

	NOP
	NOP

	IN		R17, PINC						//Lectura de los botones
	LDI		R18, 0x00						//Salida de los leds

	SEI										//Habilitar interrupciones globales

MAIN:
	RJMP	MAIN

//Subrutinas de interrupción

ISR_PCINT1:
	PUSH	R16
	IN		R16, SREG						//Guardar en el stack el sreg
	PUSH	R16

	IN		R17, PINC						//Leer 
	
	POP		R16
	OUT		SREG, R16
	POP		R16



