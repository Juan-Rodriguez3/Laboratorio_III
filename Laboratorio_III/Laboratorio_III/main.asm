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
.dseg
.def LEDS=R17
.def DISPLAY=R18

.org 0x0000
	RJMP SETUP  ; Ir a la configuraci?n al inicio

.org OVF0addr	; Vector de interrupción para TIMERO
	RJMP ISR_TIMER0
	
	// Configuracion de la pila
	LDI		 R16, LOW(RAMEND)
	OUT		 SPL, R16
	LDI		 R16, HIGH(RAMEND)
	OUT		 SPH, R16

//Configurar MCU
SETUP:

	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz

	// Inicializar timer0
	CALL INIT_TMR0

	// Configurar PB como salida para usarlo como del contador 
	LDI		R16, 0xFF
	OUT		DDRB, R16						// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16						//El puerto B conduce cero logico.

	//Configurar PD como salida para usarlo para el display
	LDI		R16, 0xFF
	OUT		DDRD, R16						// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTD, R16						//El puerto B conduce cero logico.

	// Deshabilitar serial (esto apaga los dem s LEDs del Arduino)?
	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Habilitar interrupciones del Timer
	LDI		R16,	(TOIE1<<1)				//Encender el enable de las interrupciones
	STS		TIMSK0, R16						//Cargarle el nuevo valor a mascara

	SEI										//Habilitar las interrupciones globales.




MAIN:
	RJMP	MAIN


//configurar el timer0 en 64 bits y cargarle el valor inicial al TCNT0
INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16						// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16						// Cargar valor inicial en TCNT0
	RET

//Rutina de interrupción
ISR_TIMER0:
	INC		LEDS
	OUT		PORTB, LEDS
	RETI