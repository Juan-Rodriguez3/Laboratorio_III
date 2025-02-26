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
	CALL	INIT_TMR0



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
    LDI     R16, (1 << WGM21)        ; Configurar Timer2 en modo CTC (WGM21=1, WGM20=0)
    STS     TCCR2A, R16
    LDI     R16, (1 << CS22)         ; Prescaler 16 para 1 MHz
    STS     TCCR2B, R16
	LDI     R16, 195					; 256 = 195 (esto es lo que entra en OCR2A)
	STS     OCR2A, R16	

	SEI										//Habilitar las interrupciones globales.




MAIN:
	//Cargar las unidades
	LPM		DISPLAY, Z						//Cargar en el display el puntero Z
	OUT		PORTD, DISPLAY					//Cargar en los display
	SBI		PORTC, 3						//Encender el display de unidades
	CBI		PORTC, 2						//Apagar el display de decenas
	//CALL	DELAY
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



//configurar el timer0 en 64 bits y cargarle el valor inicial al TCNT0
INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16						// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100						//Se carga este valor para interrumpir cada 10 ms
	OUT		TCNT0, R16						// Cargar valor inicial en TCNT0
	RET

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
	INC		UNI_DISP							//Incrementar
	CPI		UNI_DISP, 0x0A						//Comparar para overflow
	BREQ	OVERF0
	ADIW	Z,	1								//Usar el puntero para avanzar en la tabla
	RJMP	FIN0

OVERF0:
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	LDI		UNI_DISP, 0x00					//Reseteamos unidades
	INC		DEC_DISP						//Aumentamos decenas
	CPI		DEC_DISP, 0x06					//Comparar para overflow de decenas
	BREQ	OVERFD							
	ADIW	X, 1							//usar el puntero X en la tabla
	RJMP	FIN0

OVERFD:
	LDI		XH, HIGH(TABLA<<1)				//Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		XL, LOW(TABLA<<1)				//Carga la parte baja de la dirección de la tabla en el registro ZL
	LDI		DEC_DISP, 0x00					//Reseteamos decenas
	RJMP	FIN0		
//*******Rutina de interrupción TIMER********


DELAY:
    SBIS    TIFR2, OCF2A        ; Esperar hasta que OCF2A se active
    RJMP    DELAY
    SBI     TIFR2, OCF2A        ; Limpiar la bandera escribiendo 1
    RET

// Tabla de conversión hexadecimal a 7 segmentos
TABLA:
    .DB 0x77, 0x50, 0x3B, 0x7A, 0x5C, 0x6E, 0x6F, 0x70, 0x7F, 0x7E, 0x7D, 0x4F, 0x27, 0x5B, 0x2F, 0x2D	