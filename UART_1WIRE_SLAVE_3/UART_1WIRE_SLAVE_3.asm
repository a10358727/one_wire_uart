include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

UART_DATA DB ?

BUFFER1 DB ?
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
	
	SZ UART_PIN			;�������
	JMP $-1
	CALL UART_READ
	
	MOV A,UART_DATA		;�a�}��f1
	XOR A,0F1H			
	SNZ Z				
	JMP MAIN	
	
	SZ UART_PIN			;�������
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
	
	MOV A,34				;�ϧP�_��m��������
	SDZ ACC
	JMP $-1
		
	UART_READ1:				;DATA
		CALL DELAY
		RR UART_DATA		
		SZ UART_PIN
		SET UART_DATA.7
		SNZ UART_PIN
		CLR UART_DATA.7
		
		SDZ COUNT 
		JMP UART_READ1
				
	SNZ UART_PIN			;STOP
	JMP $-1		
	
	RET
;----------------------------------------
;	write loop
;----------------------------------------
WRITE:
	TABRD UART_DATA
	CALL UART_WRITE
	INC TBLP
	
	SNZ TBLP			;�P�_��Ʀ�m�O�_��
	INC TBHP
	
	MOV A,TBLP			;�P�_�C8BIT��m�O�_�ۦP
	XOR A,END_L	
	SNZ Z				
	JMP WRITE
	MOV A,TBHP			;�ۦP�h�P�_���줸
	XOR A,END_H			;�P�_��8BIT��m�O�_�ۦP
	SNZ Z
	JMP WRITE
	
	RET

;----------------------------------------
;	WAIT FOR OTHER SLAVE 
;----------------------------------------
UART_RECEVIER:
	SZ UART_PIN			;�������
	JMP $-1
	CALL UART_READ
	
	MOV A,UART_DATA		;�P�_�O�_��OD
	XOR A,0DH			
	SZ Z				
	JMP $+4				;�O���ܱN��Ʀs���BUFFER1���ۧP�_�U�@����ƬO�_��OA
	
	MOV A,UART_DATA		;�_�h�N��Ʀs���BUFFER1
	MOV BUFFER1,A
	JMP UART_RECEVIER
	
	MOV A,UART_DATA
	MOV BUFFER2,A
	
	SZ UART_PIN			;�������
	JMP $-1
	CALL UART_READ
	
	MOV A,UART_DATA		;�P�_�O�_��OA
	XOR A,0AH
	SZ Z
	JMP $+6			
	MOV A,BUFFER2
	MOV BUFFER1,A
	MOV A,UART_DATA
	MOV BUFFER2,A
	JMP UART_RECEVIER 
	RET
;----------------------------------------
;	�]�w�r���m
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
	DC '2002'
NAME_END:

HELLO:
	DC 'HELLO'
HELLO_END:
