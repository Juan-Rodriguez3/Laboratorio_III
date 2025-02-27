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
.def	LEDS=R17
.def	BOTON=R23
.def	DISPLAY=R18
.def	CONTADOR=R19
.def	UNI_DISP=R20
.def	DEC_DISP=R21
.def	FLAG_INC=R22



.org 0x0000
	RJMP SETUP  ; Ir a la configuraciOn al inicio

.org PCI1addr  ; Vector de interrupci?n para PCINT1 (PORTC) //0x0008
    RJMP ISR_PCINT1

.org OVF0addr	; Vector de interrupci?n para TIMERO		//0x0020
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

	// Configurar PB como salida para usarlo como del contador 
	LDI		R16, 0xFF
	OUT		DDRB, R16						// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16						//El puerto B conduce cero logico.

	//Habilitar interrupciones en el pin C

	LDI		R16, (PCIE1<<1)					//Encender PCIE1 en PCICR
	STS		PCICR, R16						//Configurar interrupciones puerto C
	LDI		R16, 0x03						//Configurar PC0 y PC1 en 
	STS		PCMSK1, R16						

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
	LDI		R16, 0b11110011					//Pullup en PC0, PC1 - 0 l?gico PC2, PC3
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
	LDI		R16, 0x00
	LDI		UNI_DISP, 0x00
	LDI		LEDS, 0x00
	LDI		BOTON, 0x00

	//Usar el puntero Z como salida de display de unidades
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la direcci?n de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la direcci?n de la tabla en el registro ZL
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirreci?n Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	//Usar el puntero X para las decenas
	LDI		XH, HIGH(TABLA<<1)				//Carga la parte alta de la direcci?n de tabla en el registro xH
	LDI		XL, LOW(TABLA<<1)				//Carga la parte baja de la direcci?n de la tabla en el registro xL

	SEI										//Habilitar las interrupciones globales.

MAIN:
	//Incrementar el contador de unidades.
	CPI		FLAG_INC, 0x01					//Revisar si paso un segundo
	BREQ	INCREMENT						//Paso un segundo, incrementar unidades

	//cargar unidades
	LD		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirreci?n Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	//MULTIPLEXEAR
	SBI		PORTC, 3
	CBI		PORTC, 2
	CALL	DELAY

	//Cargar al puerto D las decenas
	LD		DISPLAY, X
	OUT		PORTD, DISPLAY
	
	//apagar los display 
	CBI		PORTC, 2
	CBI		PORTC, 3			

	//MULTIPLEXEAR para decenas
	SBI		PORTC, 2
	CBI		PORTC, 3
	CALL	DELAY
	RJMP	MAIN

//*****Subrutinas globales******
INCREMENT:
	LDI		FLAG_INC, 0x00						//Clear the flag
	INC		UNI_DISP							//Incrementar el contador de unidades
	CPI		UNI_DISP, 10						//Comparar si hubo overflow
	BREQ	OVERF_UNI							//Desbordamiento de unidades
	ADIW	Z, 1								//Desplazarse una posici?n en la tabla
	RJMP	MAIN

OVERF_UNI:	
	LDI		UNI_DISP, 0x00						//Reiniciar el contador de unidades
	//Reiniciar el puntero Z
	LDI		ZH, HIGH(TABLA<<1)				
	LDI		ZL, LOW(TABLA<<1)
	//Aumentar decenas
	INC		DEC_DISP
	CPI		DEC_DISP, 6							//Comparar con 6	
	BREQ	OVERF_DEC							//Desbordamiento de decenas	
	ADIW	X, 1								//Mover el puntero de decenas
	RJMP	MAIN			

OVERF_DEC:
	LDI		DEC_DISP, 0x00						//Reiniciar el contado de decenas
	LDI		XH, HIGH(TABLA<<1)					//Carga la direccion inical parte alta
	LDI		XL, LOW(TABLA<<1)					//Carga la direccion inicial parte baja
	RJMP	MAIN
	 

//*****Subrutinas globales******



//*******Rutina de interrupci?n TIMER********
ISR_TIMER0:
	//Recargar el valor inicial del TCNT0
	LDI		R16, 100						//Se carga este valor para interrumpir cada 10 ms
	OUT		TCNT0, R16						// Cargar valor inicial en TCNT0
	INC		CONTADOR
	CPI		CONTADOR, 100					//Cada interrupci?n ocurre 10 ms*100=1000ms
	BRNE	FIN0
	LDI		CONTADOR, 0x00					//R19
	LDI		FLAG_INC, 0x01				//ALTERNA EL VALOR DE LA BANDERA CADA SEGUNDO
FIN0:
	RETI
//*******Rutina de interrupci?n TIMER********



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
//*******SubrutinaS - no interupcciones********

//********Subrutinas interrupciones pin change*******

//Subrutinas para interrupciones de botones
SUMA:
	INC		LEDS								//Incrementa contador
	CPI		LEDS, 0x10						//Comparar con 16
	BREQ	OVERF1
	
	RJMP	FIN1
RESTA:
	CPI		LEDS, 0x00						//Compara el contador			
	BREQ	UNDERF1							
	DEC		LEDS								//Decrementa el contador
	RJMP	FIN1

OVERF1:
	LDI		LEDS, 0x00						//Reiniciar el contador a 0
	RJMP	FIN1
UNDERF1:
	LDI		LEDS, 0x0F						//Reiniciar el contador a 15
	RJMP	FIN1


//Subrutinas de interrupciön
ISR_PCINT1:
	IN		BOTON, PINC							//Leer el estado de los botones
	SBRS	BOTON, 0							//Salta si el bit 0 esta en set
	RJMP	SUMA
	SBRS	BOTON, 1							//Salta si el bit 1 esta en set
	RJMP	RESTA
FIN1:
	OUT		PORTB, LEDS							//Actualiza la salida,
	RETI

//********Subrutinas interrupciones pin change*******0

// Tabla de conversi?n hexadecimal a 7 segmentos
TABLA:
    .DB 0x77, 0x50, 0x3B, 0x7A, 0x5C, 0x6E, 0x6F, 0x70, 0x7F, 0x7E, 0x7D, 0x4F, 0x27, 0x5B, 0x2F, 0x2D	