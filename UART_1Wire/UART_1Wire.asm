include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

UART_DATA DB ?

COUNT DB ?
END_L DB ?
END_H DB ?
ROMBANK 0 cs
cs	.section	at  000h	'code'
INIT:
	MOV A,10101111B
	MOV WDTC,A
	SET UART_PINC			;輸入
	SET UART_PINPU	
	
MAIN:
	SZ UART_PIN
	JMP $-1
	CALL UART_READ
	
	MOV A,UART_DATA
	XOR A,'1'
	SNZ Z
	JMP $+3
	CALL WRITE_ID
	JMP MAIN
	
	MOV A,UART_DATA
	XOR A,'2'
	SNZ Z
	JMP $+3
	CALL WRITE_NAME
	JMP MAIN
	
	MOV A,UART_DATA
	XOR A,'3'
	SNZ Z
	jmp $+2
	CALL WRITE_HELLO

	JMP MAIN
;----------------------------------------
;	UART Transmitter
;----------------------------------------
UART_WRITE:
	CLR UART_PINC			;開始傳輸將接腳設為output
	
	MOV A,8
	MOV COUNT,A
	CLR UART_PIN			;Start bit
	CALL DELAY		
	
	UART_WRITE1:			;data bits	資料透過不斷右移來傳輸
	
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
	
	SET UART_PINC			;傳輸結束將接腳設為input
	
	RET	
;----------------------------------------
;	UART Receiver 
;----------------------------------------
UART_READ:
	MOV A,8
	MOV COUNT,A
	CALL DELAY			;START
	
	MOV A,34
	SDZ ACC
	JMP $-1
	
	UART_READ1:			;DATA
		RR UART_DATA	
		SZ UART_PIN
		SET UART_DATA.7
		SNZ UART_PIN
		CLR UART_DATA.7
		CALL DELAY
		SDZ COUNT 
		JMP UART_READ1
	
	MOV  A,34			;STOP
	SDZ ACC
	JMP $-1		
	RET
;----------------------------------------
;	write loop 傳送字串
;----------------------------------------
WRITE:
	TABRD UART_DATA
	CALL UART_WRITE
	INC TBLP
	
	SNZ TBLP			;判斷資料位置是否跨頁
	INC TBHP
	
	MOV A,TBLP			;判斷低8BIT位置是否相同
	XOR A,END_L	
	SNZ Z				
	JMP WRITE
	MOV A,TBHP			;相同則判斷高位元
	XOR A,END_H			;判斷高8BIT位置是否相同
	SNZ Z
	JMP WRITE
	RET
;----------------------------------------
;	設定字串位置
;----------------------------------------
WRITE_ID:
	MOV A,HIGH ID
	MOV TBHP,A
	MOV A,LOW ID
	MOV TBLP,A
	MOV A,LOW ID_END
	MOV END_L,A
	MOV A,HIGH ID_END
	MOV END_H,A
	CALL WRITE
	RET
WRITE_NAME:
	MOV A,HIGH NAME
	MOV TBHP,A
	MOV A,LOW NAME
	MOV TBLP,A
	MOV A,LOW NAME_END
	MOV END_L,A
	MOV A,HIGH NAME_END
	MOV END_H,A
	CALL WRITE
	RET
WRITE_HELLO:
	MOV A,HIGH HELLO
	MOV TBHP,A
	MOV A,LOW HELLO
	MOV TBLP,A
	MOV A,LOW HELLO_END
	MOV END_L,A
	MOV A,HIGH HELLO_END
	MOV END_H,A
	CALL WRITE
	RET	
	
;----------------------------------------
;	Delay  2+1+(1+2)*66+2+2 = 205
;----------------------------------------
DELAY: ; 9600 BAUD = 104.2uS
	MOV A,67
	SDZ	ACC
	JMP $-1
	RET
TEST_END:
ID:
	DC '40926116'
ID_END:

NAME:
	DC 'Howard'
NAME_END:

HELLO:
	DC 'HELLO'
HELLO_END:
