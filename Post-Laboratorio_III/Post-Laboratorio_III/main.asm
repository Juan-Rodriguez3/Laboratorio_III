; Universidad del Valle de Guatemala
; IE2025: Programacion de Microcontroladores
;
; Author: Juan Rodriguez
; Proyecto: PostLab III
; Hardware: ATmega328P
; Creado: 24/02/2025
; Modificado: 25/02/2025
; Descripcion: Implementacion de interrupciones
;*********************
.include "M328PDEF.inc"
.cseg
.def	DISPLAY=R18
.def	CONTADOR=R19
.def	UNI_DISP=R20
.def	DEC_DISP=R21
.def	FLAG_INC=R22
.def	VARIADOR=R23



.org 0x0000
	RJMP SETUP  ; Ir a la configuraciOn al inicio


.org OVF0addr	; Vector de interrupción para TIMERO		//0x0020
	RJMP ISR_TIMER0
	
	// Configuracion de la pila
	LDI		 R16, LOW(RAMEND)
	OUT		 SPL, R16
	LDI		 R16, HIGH(RAMEND)
	OUT		 SPH, R16

//Configurar MCU
SETUP:
	 CLI									//Deshabilitar interrupciones globales
	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16						// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16						// Configurar Prescaler a 16 F_cpu = 1MHz


	// Inicializar timer0
	//configurar el timer0 en 64 bits y cargarle el valor inicial al TCNT0
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16						// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100						//Se carga este valor para interrumpir cada 10 ms
	OUT		TCNT0, R16						// Cargar valor inicial en TCNT0
	

	//Configurar PD como salida para usarlo para el display
	LDI		R16, 0xFF
	OUT		DDRD, R16						// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTD, R16						//El puerto B conduce cero logico.


	//Puerto C como entrada y Pull-up activados
	LDI		R16, 0b00001100					//Pin 0 y 1 entradas - Pin 2 y 3 Salidas
	OUT		DDRC, R16						
	LDI		R16, 0b11110011					//Pullup en PC0, PC1 - 0 lógico PC2, PC3
	OUT		PORTC, R16


	// Deshabilitar serial (esto apaga los dem s LEDs del Arduino)?
	LDI		R16, 0x00
	STS		UCSR0B, R16


	//Habilitar interrupciones del Timer
	LDI		R16,	(1<<TOIE0)				//Encender el enable de las interrupciones
	STS		TIMSK0, R16						//Cargarle el nuevo valor a mascara
	
	DELAY_TIMER2:
    LDI     R16, 194						//Delay de 2 ms 
    STS     TCNT2, R16						//Cargar el valor inicial
    LDI     R16, (1 << CS21) | (1 << CS20)	//Prescaler de 32
    STS     TCCR2B, R16

	//Valor inicial de variables generales
	LDI		DISPLAY, 0x00
	LDI		CONTADOR, 0x00
	LDI		FLAG_INC, 0x00
	LDI		VARIADOR, 0x01
	LDI		R16, 0x00


	//Usar el puntero Z como salida de display de unidades
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirreción Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla



	SEI										//Habilitar las interrupciones globales.

MAIN:
	//Incrementar el contador.
	CPI		FLAG_INC, 0x01					//Revisar si paso un segundo
	BREQ	INCREMENT						//Paso un segundo, incrementar unidades

	//cargar unidades
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirreción Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	//MULTIPLEXEAR
	SBI		PORTC, 3
	CBI		PORTC, 2
	CALL	DELAY

	//cargar decenas
	LDI		DISPLAY, 0x77
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	//MULTIPLEXEAR
	SBI		PORTC, 2
	CBI		PORTC, 3
	CALL	DELAY
	RJMP	MAIN

//*****Subrutinas globales******
INCREMENT:
	EOR		FLAG_INC, VARIADOR				//Clear the flag
	INC		UNI_DISP						//Incrementar el contador de unidades
	CPI		UNI_DISP, 0x0A					//Comparar si hubo overflow
	BREQ	OVERF_UNI						//Desbordamiento de unidades
	ADIW	Z, 1							//Desplazarse una posición en la tabla
	RJMP	MAIN

OVERF_UNI:
	LDI		UNI_DISP, 0x00					//Reiniciar el contador de unidades
	//Reiniciar el puntero Z
	LDI		ZH, HIGH(TABLA<<1)				
	LDI		ZL, LOW(TABLA<<1)
	//Aumentar 

	RJMP	MAIN			

//*****Subrutinas globales******

//*******Rutina de interrupción TIMER********
ISR_TIMER0:
	SBI     TIFR0, TOV0						// Limpiar bandera de interrupción del Timer0 Overflow
	INC		CONTADOR
	CPI		CONTADOR, 100					//Cada interrupción ocurre 10 ms*100=1000ms
	BREQ	FLAG_ACTIVE
FIN0:
	RETI
//
FLAG_ACTIVE:
	LDI		CONTADOR, 0x00					//R19
	EOR		FLAG_INC, VARIADOR				//ALTERNA EL VALOR DE LA BANDERA CADA SEGUNDO
	RJMP	FIN0		
//*******Rutina de interrupción TIMER********



//*******SubrutinaS - no interupcciones********
//Delay con el timer2
DELAY:
	IN		R16, TIFR2
	SBRS	R16, TOV2						//Hasta que la bandera de overflow se active
    RJMP    DELAY							//Se va a repetir el ciclo
    SBI		TIFR2, TOV2						//Limpiar la bandera
	LDI     R16, 194
    STS     TCNT2, R16						//Cargar el valor inicial 
    RET

//Rutina para incrementar las unidades y decenas en el display


//*******SubrutinaS - no interupcciones********

// Tabla de conversión hexadecimal a 7 segmentos
TABLA:
    .DB 0x77, 0x50, 0x3B, 0x7A, 0x5C, 0x6E, 0x6F, 0x70, 0x7F, 0x7E, 0x7D, 0x4F, 0x27, 0x5B, 0x2F, 0x2D	
