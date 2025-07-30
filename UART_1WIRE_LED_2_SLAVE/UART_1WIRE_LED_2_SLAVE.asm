include HT66F50.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

LED_PORT EQU PA6
LED_PORTC EQU PAC6
UART_DATA DB ?

CMD DB ?
ADDRESS DB ?
MODE DB ?
COUNT DB ?

DEL1 DB ?
DEL2 DB ?
DEL3 DB ?

cs	.section	at  000h	'code'


INIT:
	clr ACERL
	SET UART_PINC	
	SET UART_PINPU		
	CLR LED_PORTC
	CLR LED_PORT
	CLR MODE
	MOV A,0C0H
	MOV ADDRESS,A
MAIN:
	sz MODE
	CALL MAIN1	
	SZ UART_PIN			;接收資料
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA		;
	AND A,11110000B		;接收到的資料高4bit為地址
	XOR A,ADDRESS		;地址為F
	SNZ Z				
	JMP MAIN
	MOV A,UART_DATA		
	AND A,00001111B		;接收到的資料低4bit為指令	
	mov CMD,A			;
	CPL UART_DATA		;將資料取補數並回傳
	CALL UART_WRITE
	
	mov a,CMD	
	XOR A,01h			;指令為01h
	SNZ Z
	JMP $+3
	SET LED_PORT
	JMP MAIN
	mov a,CMD		
	XOR A,02h			;指令為02h
	SNZ Z
	JMP $+3
	CLR LED_PORT
	JMP MAIN
	mov a,CMD		
	XOR A,03h			;指令為03h
	SNZ Z
	JMP $+3
	set mode
	JMP MAIN
	mov a,CMD		
	XOR A,04h			;指令為04h
	SNZ Z
	JMP $+3
	clr MODE
	JMP MAIN
	
	JMP MAIN

MAIN1:
	SZ MODE 
	JMP $+2
	JMP MAIN1_END
	
	SET LED_PORT
	
	MOV A,0D1H
	MOV CMD,A
	CALL SEND_CMD

	MOV A,0E1H
	MOV CMD,A
	CALL SEND_CMD

	MOV A,0F1H
	MOV CMD,A
	CALL SEND_CMD
	call DELAY_1000
	
	clr LED_PORT

	MOV A,0D2H
	MOV CMD,A
	CALL SEND_CMD

	MOV A,0E2H
	MOV CMD,A
	CALL SEND_CMD

	MOV A,0F2H
	MOV CMD,A
	CALL SEND_CMD
	call DELAY_1000
	JMP MAIN1
	
MAIN1_END:
	MOV A,055H
	MOV UART_DATA,A
	CALL UART_WRITE
	
	ret
	
SEND_CMD:
	MOV A,CMD
	MOV UART_DATA,A
	CALL UART_WRITE
	clr DEL1
WAIT_ACK:	
	SnZ UART_PIN					;
	JMP GET_ACK
	sdz DEL1
	jmp WAIT_ACK
	jmp SEND_CMD_END
GET_ACK:
	CALL UART_READ
	MOV A,UART_DATA
	CPLA ACC
	XOR A,CMD
	SNZ Z
	JMP SEND_CMD_END

SEND_CMD_END:
	RET
;----------------------------------------
;	UART Transmitter
;----------------------------------------
UART_WRITE:
	CLR UART_PINC
	
	MOV A,8
	MOV COUNT,A
	CLR UART_PIN			;Start bit
	CALL DELAY		
	
	UART_WRITE1:			;data bits
	
		SZ UART_DATA.0
		SET UART_PIN
		SNZ UART_DATA.0
		CLR UART_PIN
		CALL DELAY
		RR UART_DATA
		SDZ COUNT 
		JMP UART_WRITE1
	
	SET UART_PIN			;stop bit
	CALL DELAY	
	
	SET UART_PINC
	
	RET	
;----------------------------------------
;	UART Receiver 
;----------------------------------------
UART_READ:
	MOV A,8
	MOV COUNT,A
	CALL DELAY
	MOV A,34				;使判斷位置為中間值
	SDZ ACC
	JMP $-1
		
	UART_READ1:				;DATA
		
		RR UART_DATA		
		SZ UART_PIN
		SET UART_DATA.7
		SNZ UART_PIN
		CLR UART_DATA.7
		CALL DELAY
		SDZ COUNT 
		JMP UART_READ1
	
	SNZ UART_PIN			;STOP
	JMP $-1		
	
	RET

	
;----------------------------------------
;	Delay  2+1+(1+2)*67+2+2 = 208
;----------------------------------------
DELAY: ; 9600 BAUD = 104.2uS
	MOV A,67
	SDZ	ACC
	JMP $-1
	RET
;----------------------------------------
;	Delay  1000mS
;----------------------------------------	
DELAY_1000:
	MOV A,100
	MOV DEL1,A
DEL_1:
	MOV A,60
	MOV DEL2,A
DEL_2:
	MOV A,110
	MOV DEL3,A
DEL_3:
	snz UART_PIN
	jmp GET_DATA
	SDZ DEL3
	JMP DEL_3
	SDZ DEL2
	JMP DEL_2
	SDZ DEL1
	JMP DEL_1
	JMP DEL_END	
GET_DATA:
	CALL UART_READ
	MOV A,UART_DATA		;
	AND A,11110000B		;接收到的資料高4bit為地址
	XOR A,ADDRESS		;地址為F
	SNZ Z				
	JMP DEL_END

	MOV A,UART_DATA		
	AND A,00001111B		;接收到的資料低4bit為指令	
	mov CMD,A		;
	
	CPL UART_DATA		;將資料取補數並回傳
	CALL UART_WRITE
	mov a,CMD		
	XOR A,04h			;指令為04h
	SZ Z
	clr MODE
DEL_END:	
	RET 	


	END