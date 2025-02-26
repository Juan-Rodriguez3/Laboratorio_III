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
	

	//Valor inicial de variables generales
	LDI		DISPLAY, 0x00
	LDI		CONTADOR, 0x00
	LDI		R16, 0x00


	//Usar el puntero Z como salida de display de unidades
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirreción Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla


	//Usar el puntero X como salida de display de unidades
	//Usar el puntero Z como salida de display de unidades
	LDI		XH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		XL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL


DELAY_TIMER2:
    LDI     R16, 194						//Delay de 2 ms 
    STS     TCNT2, R16						//Cargar el valor inicial
    LDI     R16, (1 << CS21) | (1 << CS20)	//Prescaler de 32
    STS     TCCR2B, R16

	SEI										//Habilitar las interrupciones globales.

MAIN:
	//Cargar las unidades
	CALL	INCREMENTAR_DISPLAY
	LPM		DISPLAY, Z						//Cargar en el display el puntero Z
	OUT		PORTD, DISPLAY					//Cargar en los display
	SBI		PORTC, 3						//Encender el display de unidades
	CBI		PORTC, 2						//Apagar el display de decenas
	CALL	DELAY
	//Cargar las decenas
	MOV		R24, ZL
	MOV		R25, ZH
	MOV		ZL, XL
	MOV		ZH, XH
	LPM		DISPLAY, Z						//Cargar en el display el puntero X
	OUT		PORTD, DISPLAY					//Cargar en los displays 
	CBI		PORTC, 3						//Apagar el display de unidades
	SBI		PORTC, 2						//Encender el display de decenas
	MOV		ZL, R24
	MOV		ZH, R25
	CALL	DELAY 
	RJMP	MAIN							//Bucle






//*******Rutina de interrupción TIMER********
ISR_TIMER0:
	PUSH	R16
	IN		R16, SREG  ; Carga el valor de SREG en R16
	PUSH	R16
	SBI     TIFR0, TOV0						; Limpiar bandera de interrupción del Timer0 Overflow
	INC		CONTADOR
	CPI		CONTADOR, 100					//Cada interrupción ocurre 10 ms*100=1000ms
	BREQ	INCREMENTAR
FIN0:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//
INCREMENTAR:
	LDI		CONTADOR, 0x00
	INC		UNI_DISP
	RJMP	FIN0		
//*******Rutina de interrupción TIMER********



//*******SubrutinaS - no interupcciones********
//Delay con el timer
DELAY:
	IN		R16, TIFR2
	SBRS	R16, TOV2						//Hasta que la bandera de overflow se active
    RJMP    DELAY							//Se va a repetir el ciclo
	LDI     R16, 194
    STS     TCNT2, R16						//Cargar el valor inicial
    LDI		R16, (1 << TOV2)				//Limpiar la bandera 
	STS		TIFR2, R16						//Limpiar la bandera de overflow
    RET

//Rutina para incrementar las unidades y decenas en el display
INCREMENTAR_DISPLAY:
	CPI		UNI_DISP, 0x0A
	BREQ	OVERF_UNI
	ADIW	Z, 1
RETURN:
	RET


OVERF_UNI:
	LDI		UNI_DISP, 0x00
	//Resetear el puntero Z a su posicion inicial
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	//Sumarle al puntero X para aumentar las decenas
	INC		DEC_DISP
	CPI		DEC_DISP, 0x06
	BREQ	OVERF_DEC
	ADIW	X, 1
	RJMP	RETURN


OVERF_DEC:
	LDI		DEC_DISP, 0x00
	LDI		XH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		XL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	RJMP	RETURN
//*******SubrutinaS - no interupcciones********

// Tabla de conversión hexadecimal a 7 segmentos
TABLA:
    .DB 0x77, 0x50, 0x3B, 0x7A, 0x5C, 0x6E, 0x6F, 0x70, 0x7F, 0x7E, 0x7D, 0x4F, 0x27, 0x5B, 0x2F, 0x2D	