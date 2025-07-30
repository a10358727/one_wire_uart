include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

KEY_PORT EQU PC
KEY_PORTC EQU PCC
KEY_PORTPU EQU PCPU



UART_DATA DB ?
CMD DB ?
COUNT DB ?

END_L DB ?
END_H DB ?

KEY DB ?

DEL1 DB ?
DEL2 DB ?
DEL3 DB ?

BUFFER DB 20 DUP (?)

ROMBANK 0 cs
cs	.section	at  000h	'code'
INIT:
	MOV A,10101111B
	MOV WDTC,A
	SET UART_PINC			;輸入
	SET UART_PINPU	
	
	MOV A,11110000B			;設定按鍵的輸入輸出
	MOV KEY_PORTC,A
	MOV KEY_PORTPU,A
	
	
	
MAIN:
	CALL READ_KEY				;呼叫副程式判斷是否有按下按鈕
	MOV A,16
	XOR A,KEY
	SZ Z
	JMP MAIN
	
	MOV A,KEY					;將按鍵數值轉換成我們要發送的數值
	CALL TRANS_CMD
	MOV CMD,A
	MOV UART_DATA,A
	CALL UART_WRITE
	
	SZ UART_PIN					;接收資料並判斷與發送的數值是否成補數
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA
	CPLA ACC
	XOR A,CMD
	SNZ Z
	JMP MAIN
	call clear_buffer
	MOV A,HIGH OFFSET BUFFER
	MOV MP1H,A
	MOV A,LOW OFFSET BUFFER 
	MOV MP1L,A
REC_LOOP:						;將接收到的資料存放於BUFFER，">" 為停止訊號
	SZ UART_PIN
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA
	MOV IAR1,A
	XOR A,'>'
	SZ Z
	JMP $+3
	INC MP1L
	JMP REC_LOOP
	
	CALL DELAY_1000
	JMP MAIN

;----------------------------------------
;	SCAN KEY
;----------------------------------------
READ_KEY:
	SET KEY_PORT
	CLR KEY
	MOV A,04
	MOV COUNT,A
	CLR C
SCAN_KEY:
	RLC KEY_PORT
	SNZ KEY_PORT.4
	JMP END_KEY
	INC KEY
	SNZ KEY_PORT.5
	JMP END_KEY
	INC KEY
	SNZ KEY_PORT.6
	JMP END_KEY
	INC KEY
	SNZ KEY_PORT.7
	JMP END_KEY
	INC KEY
	SDZ COUNT
	JMP SCAN_KEY
END_KEY:	
	RET	

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
	
	MOV A,20
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
	
		
	SNZ UART_PIN	;STOP
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
;	ADDRESS COMMAND
;----------------------------------------
TRANS_CMD:
	ADDM A,PCL
	RET A,0F0H
	RET A,0F1H
	RET A,0F2H
	RET A,0F3H
	RET A,0E0H
	RET A,0E1H
	RET A,0E2H
	RET A,0E3H
	RET A,0D0H
	RET A,0D1H
	RET A,0D2H
	RET A,0D3H
	RET A,0C0H
	RET A,0C1H
	RET A,0C2H
	RET A,0C3H

;----------------------------------------
;	Delay  2+1+(1+2)*66+2+2 = 205
;----------------------------------------
DELAY: ; 9600 BAUD = 104.2uS
	MOV A,65
	SDZ	ACC
	JMP $-1
	RET
;----------------------------------------
;	Delay  100mS
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
	SDZ DEL3
	JMP DEL_3
	SDZ DEL2
	JMP DEL_2
	SDZ DEL1
	JMP DEL_1
	RET 	
clear_buffer:
	MOV A,HIGH OFFSET BUFFER
	MOV MP1H,A
	MOV A,LOW OFFSET BUFFER 
	MOV MP1L,A
	mov a,20
	mov  COUNT,A
	clr IAR1
	inc MP1L
	sdz COUNT
	jmp $-3
	ret

