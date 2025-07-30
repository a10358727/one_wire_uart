include HT66F2390.inc

ds	.section	'data'

UART_PIN EQU PA4
UART_PINC EQU PAC4
UART_PINPU EQU PAPU4

KEY_PORT EQU PC
KEY_PORTC EQU PCC
KEY_PORTPU EQU PCPU

SDA   EQU PF6
SDAC  EQU PFC6
SDAPU EQU PFPU6
SCL   EQU PF7
SCLC  EQU PFC7
SCLPU EQU PFPU7

i2c_data db ?
i2c_ack DB ?
i2c_count DB ?
I2C_COMMAND DB ?
I2C_DATA_TOTAL DB ?
I2C_BUSY DB ?

UART_DATA DB ?
data_count db ?
CMD DB ?
COUNT DB ?
COUNT1 DB ?
END_L DB ?
END_H DB ?

KEY DB ?

DEL1 DB ?
DEL2 DB ?
DEL3 DB ?

BUFFER DB 20 DUP (?)
BUFFER1 DB 20 DUP (?)

ROMBANK 0 cs
cs	.section	at  000h	'code'
INIT:
	MOV A,10101111B
	MOV WDTC,A
	
	call i2c_init
	
	SET UART_PINC			;輸入
	SET UART_PINPU	
	
	MOV A,11110000B			;設定按鍵的輸入輸出
	MOV KEY_PORTC,A
	MOV KEY_PORTPU,A
	
	CALL CLEAR_BUFFER	;CLEAR BUFFER1 DATA
	call CLEAR_BUFFER1
	CALL eDISPLAY_CLEAR_ALL
	Call eDISPLAY_ASC_2
	CALL eDISPLAY_ASC_DATA
MAIN:
	CALL READ_KEY			;呼叫副程式判斷是否有按下按鈕
	MOV A,16
	XOR A,KEY
	SZ Z
	JMP MAIN
	call CLEAR_BUFFER1
	MOV A,KEY				;將按鍵數值轉換成我們要發送的數值
	CALL TRANS_CMD
	MOV CMD,A
	MOV UART_DATA,A
	CALL UART_WRITE
	
	SZ UART_PIN				;接收資料並判斷與發送的數值是否成補數
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA
	CPLA ACC
	XOR A,CMD
	SNZ Z
	JMP MAIN
	
	MOV A,HIGH OFFSET BUFFER
	MOV MP1H,A
	MOV A,LOW OFFSET BUFFER 
	MOV MP1L,A
REC_LOOP:						;將接收到的資料存放於BUFFER，0D0A 為停止訊號
	SZ UART_PIN
	JMP $-1
	CALL UART_READ
	MOV A,UART_DATA
	MOV IAR1,A
	XOR A,0AH 
	SZ Z
	JMP $+3
	INC MP1L
	JMP REC_LOOP
	MOV A,IAR1
	XOR A,0DH
	SNZ Z
	JMP $+3
	INC MP1L
	JMP REC_LOOP
	
	
	CALL eDISPLAY_ASC_CMD
	CALL eDISPLAY_ASC_UART_DATA
	
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
	SDZ DEL3
	JMP DEL_3
	SDZ DEL2
	JMP DEL_2
	SDZ DEL1
	JMP DEL_1
	RET 	

;*******************************************************************************
;   ASCII eDISPLAY 
;
;	COLOR: 	WHITE=0FFFFH,BLACK=0000H,RED=0F800H,GREEN=07E0H,
;			BLUE=001FH,YELLOW=0FFE0H,MAGENTA=0F81FH,CYANH=7FFFH  
;*******************************************************************************
eDISPLAY_ASC_UART_DATA:
	;CALL eDISPLAY_CLEAR_1
	MOV A,20				;X	0-128
	MOV BUFFER1[0],A
	MOV A,60				;Y  0-128
	MOV BUFFER1[1],A
	MOV A,00H				;COLOR1H ?r??
	MOV BUFFER1[2],A
	MOV A,00H				;COLOR1L 
	MOV BUFFER1[3],A
	MOV A,0ffH				;COLOR2H ?I??
	MOV BUFFER1[4],A
	MOV A,0fFH				;COLOR2L 
	MOV BUFFER1[5],A
	CALL DATA_LEN		
	MOV A,I2C_DATA_TOTAL
	MOV COUNT,A
	MOV A,HIGH OFFSET BUFFER
	MOV MP1H,A
	MOV A,LOW OFFSET BUFFER 
	MOV MP1L,A
	MOV A,HIGH OFFSET BUFFER1
	MOV MP2H,A
	MOV A,LOW OFFSET BUFFER1
	MOV MP2L,A
	
	MOV A,6
	ADDM A,MP2L
	X:
	MOV A,IAR1
	MOV IAR2,A
	INC MP1L
	INC MP2L
	SDZ COUNT
	JMP X
	MOV A,20
	MOV  I2C_DATA_TOTAL,A
	CALL I2C_ASC
	RET
eDISPLAY_ASC_DATA:
	CALL CLEAR_BUFFER
	MOV A,HIGH  ASC_WORD_1
	MOV TBHP,A
	MOV A,LOW  ASC_WORD_1
	MOV TBLP,A
	MOV A,HIGH END_ASC_WORD_1
	MOV END_H,A	
	MOV A,LOW END_ASC_WORD_1
	MOV END_L,A
	CALL ASC_LOOP	
	CALL I2C_ASC
	
	RET
	

eDISPLAY_ASC_CMD:
	CALL eDISPLAY_ASC_3
	CALL CLEAR_BUFFER
	mov a,7
	mov I2C_DATA_TOTAL,A
	MOV A,60				;X	0-128
	MOV BUFFER1[0],A
	MOV A,22				;Y  0-128
	MOV BUFFER1[1],A
	MOV A,00H				;COLOR1H ?r??
	MOV BUFFER1[2],A
	MOV A,00H				;COLOR1L 
	MOV BUFFER1[3],A
	MOV A,0ffH				;COLOR2H ?I??
	MOV BUFFER1[4],A
	MOV A,0fFH				;COLOR2L 
	MOV BUFFER1[5],A
	MOV A,CMD
	AND A,11110000B
	SWAP ACC
	CPL ACC
	AND A,00001111B
	CALL TRANS_slave
	MOV BUFFER1[6],A
	CALL I2C_ASC
	RET
eDISPLAY_ASC_2:
	CALL CLEAR_BUFFER
	MOV A,HIGH  ASC_WORD_2
	MOV TBHP,A
	MOV A,LOW  ASC_WORD_2
	MOV TBLP,A
	MOV A,HIGH END_ASC_WORD_2
	MOV END_H,A	
	MOV A,LOW END_ASC_WORD_2
	MOV END_L,A
	
	CALL ASC_LOOP
			
	CALL I2C_ASC
	ret
eDISPLAY_ASC_3:
	CALL CLEAR_BUFFER
	MOV A,HIGH  ASC_WORD_3
	MOV TBHP,A
	MOV A,LOW  ASC_WORD_3
	MOV TBLP,A
	MOV A,HIGH END_ASC_WORD_3
	MOV END_H,A	
	MOV A,LOW END_ASC_WORD_3
	MOV END_L,A
	
	CALL ASC_LOOP
			
	CALL I2C_ASC
	ret
ASC_WORD_1:
	DC 04,40,00H,00H,0FFH,0FFH		; X,Y,COLOR1H,COLOR1L,COLOR2H,COLOR2L
	DC 'DATA:'
END_ASC_WORD_1:	
ASC_WORD_2: 
	Dc 04,04,00H,00H,0FFH,0FFH		; X,Y,COLOR1H,COLOR1L,COLOR2H,COLOR2L
	DC 'Device:'
END_ASC_WORD_2:	
ASC_WORD_3: 
	Dc 20,22,00H,00H,0FFH,0FFH		; X,Y,COLOR1H,COLOR1L,COLOR2H,COLOR2L
	DC 'Slave'
END_ASC_WORD_3:	
TRANS_slave:
	ADDM A,PCL
	RET A,'0'
	RET A,'1'
	RET A,'2'
	RET A,'3'
	RET A,'4'
	RET A,'5'
	RET A,'6'
	RET A,'7'
	RET A,'8'
	RET A,'9'
	RET A,'A'
	RET A,'B'
	RET A,'C'
	RET A,'D'
	RET A,'E'
	RET A,'F'

ASC_LOOP:
	clr I2C_DATA_TOTAL
	CALL CLEAR_BUFFER
	MOV A,OFFSET BUFFER1
	MOV MP0,A
	ASC_L1:
		TABRD IAR0
		INC MP0
		inc I2C_DATA_TOTAL
		
		INC TBLP
		SNZ TBLP			
		INC TBHP
		
		MOV A,TBLP				
		XOR A,END_L	
		SNZ Z				
		JMP ASC_L1
		MOV A,TBHP				
		XOR A,END_H				
		SNZ Z
		JMP ASC_L1
	RET
I2C_ASC:
	CALL I2C_CHECK_BUSY
	MOV A,0AAH
	XOR A,I2C_BUSY
	SNZ Z
	JMP I2C_ASC
	
	MOV A,01H
	MOV I2C_COMMAND,A
	
	CALL i2c_write_data
	RET

DATA_LEN:
	MOV A,HIGH OFFSET BUFFER
	MOV MP1H,A
	MOV A,LOW OFFSET BUFFER 
	MOV MP1L,A
	CLR I2C_DATA_TOTAL
DATA_LEN_L:


	MOV A,IAR1
	XOR A,0AH 
	SZ Z
	JMP $+4
	INC I2C_DATA_TOTAL
	INC MP1L
	JMP DATA_LEN_L
	MOV A,IAR1
	XOR A,0DH
	SNZ Z
	JMP $+3
	INC MP1L
	JMP DATA_LEN_L
	DEC I2C_DATA_TOTAL
	RET
;*******************************************************************************
;   CLEAR eDISPLAY 
;*******************************************************************************
eDISPLAY_CLEAR_ALL:
	MOV A,00
	MOV BUFFER1[0],A
	MOV A,128
	MOV BUFFER1[1],A
	MOV A,00
	MOV BUFFER1[2],A
	MOV A,128
	MOV BUFFER1[3],A
	CALL I2C_CLEAR
	RET
eDISPLAY_CLEAR_1:
	MOV A,20
	MOV BUFFER1[0],A
	MOV A,100
	MOV BUFFER1[1],A
	MOV A,60
	MOV BUFFER1[2],A
	MOV A,20
	MOV BUFFER1[3],A
	CALL I2C_CLEAR
	RET
I2C_CLEAR:
	CALL I2C_CHECK_BUSY
	MOV A,0AAH
	XOR A,I2C_BUSY
	SNZ Z
	JMP I2C_CLEAR
	MOV A,04H
	MOV I2C_COMMAND,A
	MOV A,04H
	MOV I2C_DATA_TOTAL,A
	
	
	CALL i2c_write_data
	
	
	RET
;*******************************************************************************
;   check BUSY
;*******************************************************************************
I2C_CHECK_BUSY:
	call i2c_start
	MOV A,05BH				;ADDRESSS
	MOV i2c_data,A
	call i2c_write
	call i2c_read_ack
	CALL I2C_READ
	CALL i2c_stop
	mov a,i2c_data
	mov I2C_BUSY,A
	
	RET
;*******************************************************************************
;   i2c_write_data
;*******************************************************************************
i2c_write_data:
	MOV A,05AH				;ADDRESSS
	MOV i2c_data,A
	call	i2c_start
	call	i2c_write
	call	i2c_read_ack
	
	MOV A,I2C_COMMAND		;COMMAND
	MOV i2c_data,A
	CALL i2c_write
	call i2c_read_ack
	
	MOV A,00H
	MOV i2c_data,A
	CALL i2c_write
	call i2c_read_ack
	
	MOV A,I2C_DATA_TOTAL
	MOV i2c_data,A
	CALL i2c_write
	call i2c_read_ack
	
	MOV A,5				
	MOV COUNT,A
I2C_WRITE_DATA2:
	mov	A, 00H
	MOV i2c_data,A
	call	i2c_write
	call	i2c_read_ack
	inc	MP0
	sdz	COUNT
	jmp	i2c_write_data2
	
	
	MOV A,I2C_DATA_TOTAL
	MOV COUNT,A
	MOV A,OFFSET BUFFER1
	MOV MP0,A
I2C_L1:
	MOV A,IAR0
	INC MP0
	MOV i2c_data,A
	CALL i2c_write
	call i2c_read_ack

	
	SDZ COUNT
	JMP I2C_L1
	
	
I2C_WRITE_DATA3:	
	call	i2c_stop
	ret	

;*******************************************************************************
;   delay 20uS
;*******************************************************************************	
delay_20us:
	MOV A,20
	SDZ ACC
	JMP $-1
	RET
;*******************************************************************************
;   CLEAR_BUFFER
;*******************************************************************************
CLEAR_BUFFER:	
	MOV A,OFFSET BUFFER1
	MOV MP0,A
	MOV A,20
	MOV COUNT,A
	MOV A,32
	MOV IAR0,A
	INC MP0
	SDZ COUNT
	JMP $-4
	RET
CLEAR_BUFFER1:	
	MOV A,OFFSET BUFFER
	MOV MP0,A
	MOV A,20
	MOV COUNT,A
	MOV A,0
	MOV IAR0,A
	INC MP0
	SDZ COUNT
	JMP $-4
	RET

;*******************************************************************************
;	i2c initial
;*******************************************************************************
i2c_init:
	set SCLPU
	set SDAPU
	clr	sclc
	clr	sdac
	set	scl
	set	sda
	
	ret

;*******************************************************************************
;	i2c start signal
;*******************************************************************************
i2c_start:
	CLR SCL 
	CLR SDA
	CLR SCLC
	CLR SDAC
	call	delay_20us   
	SET SCL
	SET sda
	call	delay_20us
    clr SDA
    CALL delay_20us
    CLR SCL
    CALL delay_20us
    ret
;*******************************************************************************
;	i2c stop signal
;*******************************************************************************
i2c_stop:
	clr     scl
	CLR SDA
	CLR SDAC 
	call	delay_20us
    set     scl
    call	delay_20us
    clr     sda
    call	delay_20us
    set     sda
    CALL	DELAY
    call delay
    ret
;*******************************************************************************
;	i2c read ack
;*******************************************************************************      
i2c_read_ack:
	clr	SCL
	set SDAC
	call delay_20us
	set SCL	
	call delay_20us
	clr DEL1
	set i2c_ack
wait_ack:
	snz SDA
	jmp GET_ACK
	SDZ DEL1
	JMP WAIT_ACK
	CLR i2c_ack
GET_ACK:
	call delay_20us
	CLR SCL
	CALL delay_20us
	
	CLR SDAC
	ret	
i2c_write_ack:
	clr scl 
	set SDA
	clr SDAC
	call delay_20us
	set SCL
	call delay_20us
	clr SCL
	call delay_20us
	ret 
;*******************************************************************************
;	i2c write 8 bits
;*******************************************************************************
i2c_write:
        clr	scl  
        clr SDAC
        mov     a,8
        mov     i2c_count,a
i2c_write1:
		clr     sda
        sz      i2c_data.7
		set     SDA
        call	delay_20us
        set     scl
        call	delay_20us
        clr     scl
        call 	delay_20us
        rl      i2c_data
        sdz     i2c_count
        jmp     i2c_write1
        ret

;*******************************************************************************
; i2c READ 8bits
;*******************************************************************************
I2C_READ:
	CLR i2c_data
	mov A,8
    mov i2c_count,a
    set SDAC
I2C_READ1:	
	set SCL
	call delay_20us  
	RLC i2c_data
	sz SDA
	set i2c_data.0	
	call delay_20us
	clr	SCL
	call delay_20us

	sdz i2c_count
    jmp	I2C_READ1
    set SDA
	clr	sdac
	call delay_20us
	set SCL
	call delay_20us
	clr SCL
	ret	
