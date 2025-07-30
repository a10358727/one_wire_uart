include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

SW0 EQU PA1
SW0C EQU PAC1
SW0PU EQU PAPU1

SW1 EQU PB1
SW1C EQU PBC1
SW1PU EQU PBPU1

UART_DATA DB ?
CMD DB ?
COUNT DB ?
ack DB ?
mode db ?

DEL1 DB ?
DEL2 DB ?
DEL3 DB ?



ROMBANK 0 cs
cs	.section	at  000h	'code'
	ORG 000H
	JMP INIT
	
INIT:
	MOV A,10101111B
	MOV WDTC,A
	SET UART_PINC			;輸入
	SET UART_PINPU	
	clr mode				;設定模式0代表MASTER發送指令 1代表MASTER停止發送指令

	SET SW0C
	SET SW0PU
	SET SW1C
	SET SW1PU
	
MAIN:
	sz mode
	jmp CHANGE_MASTER
	
	MOV A,0C1H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0D1H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0E1H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0F1H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000

	MOV A,0C2H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0D2H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0E2H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	MOV A,0F2H
	MOV CMD,A
	CALL SEND_CMD
	CALL DELAY_1000
	
	JMP MAIN
;
SEND_CMD:
	MOV A,CMD
	MOV UART_DATA,A
	CALL UART_WRITE
	CLR ACK
	clr DEL1
WAIT_ACK:	
	SnZ UART_PIN					;接收資料並判斷與發送的數值是否成補數
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
	SET ACK
	
SEND_CMD_END:
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
	CALL DELAY			
	RET

;----------------------------------------
;	Delay  2+1+(1+2)*66+2+2 = 205
;----------------------------------------
DELAY: ; 9600 BAUD = 104.2uS
	MOV A,65
	SDZ	ACC
	JMP $-1
	RET
;----------------------------------------
;	Delay  1000mS
;----------------------------------------	
DELAY_1000:
	MOV A,50
	MOV DEL1,A
DEL_1:
	MOV A,60
	MOV DEL2,A
DEL_2:
	MOV A,110
	MOV DEL3,A
DEL_3:
	SNZ SW0
	SET mode
	SDZ DEL3
	JMP DEL_3
	SDZ DEL2
	JMP DEL_2
	SDZ DEL1
	JMP DEL_1
	RET 	


CHANGE_MASTER:
	MOV A,0C3H
	MOV CMD,A
	CALL SEND_CMD
	SZ ACK 
	JMP WAIT_SW1
	MOV A,0D3H
	MOV CMD,A
	CALL SEND_CMD
	SZ ACK 
	JMP WAIT_SW1
	MOV A,0E3H
	MOV CMD,A
	CALL SEND_CMD
	SZ ACK 
	JMP WAIT_SW1
	MOV A,0F3H
	MOV CMD,A
	CALL SEND_CMD
	SZ ACK 
	JMP WAIT_SW1
WAIT_SW1: 
	SZ SW1
	JMP $-1
	INC CMD
	CALL SEND_CMD
	SNZ ack
	JMP $-2
	
	SZ UART_PIN				;等待SLAVE完成指令
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA
	XOR A,055H
	SNZ Z
	JMP $-6
	clr mode
	jmp MAIN
	
	end