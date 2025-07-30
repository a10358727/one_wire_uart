include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

UART_DATA DB ?
command DB ?
BUFFER2 DB ?

COUNT DB ?
END_L DB ?
END_H DB ?
ROMBANK 0 cs
cs	.section	at  000h	'code'
INIT:
	MOV A,10101111B
	MOV WDTC,A

	SET UART_PINC	
	SET UART_PINPU		
	
MAIN:
	
	SZ UART_PIN			;接收資料
	JMP $-1
	CALL UART_READ
	
	MOV A,UART_DATA		;
	AND A,11110000B		;接收到的資料高4bit為地址
	XOR A,0F0H			;地址為F
	SNZ Z				
	JMP MAIN
		
	MOV A,UART_DATA		
	AND A,00001111B		;接收到的資料低4bit為指令	
	mov command,A		;
	
	CPL UART_DATA		;將資料取補數並回傳
	CALL UART_WRITE
	
	mov a,command	
	XOR A,00h			;指令為00h
	SNZ Z
	JMP $+3
	CALL WRITE_HELLO
	JMP MAIN
	
	mov a,command	
	XOR A,01h			;指令為01h
	SNZ Z
	JMP $+3
	CALL WRITE_ID
	JMP MAIN
	
	mov a,command		
	XOR A,02h			;指令為02h
	SNZ Z
	JMP $+3
	CALL WRITE_NAME
	JMP MAIN
	
	mov a,command	
	XOR A,03h			;指令為03h
	SNZ Z
	JMP $+3
	CALL WRITE_word1
	JMP MAIN
	
	
	JMP MAIN
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
;	write loop
;----------------------------------------
WRITE_DATA:
	TABRD UART_DATA
	CALL UART_WRITE
	INC TBLP
	
	SNZ TBLP				;判斷資料位置是否跨頁
	INC TBHP
	
	MOV A,TBLP				;判斷低8BIT位置是否相同
	XOR A,END_L	
	SNZ Z				
	JMP WRITE_DATA
	MOV A,TBHP				;相同則判斷高位元
	XOR A,END_H				;判斷高8BIT位置是否相同
	SNZ Z
	JMP WRITE_DATA
	CALL WRITE_DATA_END	
	RET
;----------------------------------------
;	停止訊號
;----------------------------------------
WRITE_DATA_END:
	MOV A,'>'
	MOV UART_DATA,A
	CALL UART_WRITE
	;MOV A,0AH
	;MOV UART_DATA,A
	;CALL UART_WRITE
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
	CALL WRITE_DATA
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
	CALL WRITE_DATA
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
	CALL WRITE_DATA
	RET	
WRITE_word1:
	MOV A,HIGH word1
	MOV TBHP,A
	MOV A,LOW word1
	MOV TBLP,A
	MOV A,LOW word1_END
	MOV END_L,A
	MOV A,HIGH word1_END
	MOV END_H,A
	CALL WRITE_DATA
	RET		
;----------------------------------------
;	Delay  2+1+(1+2)*67+2+2 = 208
;----------------------------------------
DELAY: ; 9600 BAUD = 104.2uS
	MOV A,67
	SDZ	ACC
	JMP $-1
	RET
TEST_END:
ID:
	DC 'slave2'
ID_END:

NAME:
	DC '40926116'
NAME_END:

HELLO:
	DC 'HELLO'
HELLO_END:
word1:
	DC 'Design'
word1_END:
