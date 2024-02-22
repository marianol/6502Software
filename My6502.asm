; Herdware for the My6502

/*
This file is ment to be included in .asm files and has the common variables
and costants that define the hardware of my My6502 design.
This enables to maintain the haerdware relared constants separated from 
the main assembly code.

Memorey Map:
RAM	32k	0x0000	0x7FFF
I/O	8k	0x8000	0x9FFF
ROM	24k	0xA000	0xFFFF

*/
; VIA
VIA1_PORTB  = $9000
VIA1_PORTA  = $9001
VIA1_DDRB   = $9002
VIA1_DDR    = $9003
VIA1_T1CL   = $9004 ; Timer 1 Counter (low byte)
VIA1_T1CH   = $9005 ; Timer 1 Counter (high byte) 
VIA1_ACR    = $900B ;  Auxiliary Control register @
VIA1_IFR    = $900D ; Interrupt Flag Register
VIA1_IER    = $900E ; Interrupt Enable Register
/* 
6522 VIA IFR REGISTER
Bit Desc
7   Any IRQ
6   Timer 1 Overflow Interrupt
5   Timer 2 Overflow Interrupt
4   CB1 Active Edge
3   CB2 Active Edge
2   Shift Register Complete 8 Shifts
1   CA1 Active Edge
0   CA2 Active Edge
*/

; ACIA MC60B50
ACIA_BASE     = $8010
ACIA_STATUS   = ACIA_BASE  ; Read Only RS 0 + R 
ACIA_CONTROL  = ACIA_BASE  ; Write Only RS 0 + W
ACIA_DATA     = ACIA_BASE + 8 ; RS 1 + R/W > RX/TX
/* 
CS0	 > A4
CS1	 > A4
~CS2 > ~IO_SEL
RS   > A3
*/

; Constants
; ACIA
; ACIA Config
; 7/ RX IRQ 
; 6,5/ TX IRQ & RTS 
; 4,3,2/ Bit length, parity & stop
; 1,0/ ÷1,÷16,÷64 Clock Divider & Reset 
; CLK @ 1.8432Mhz 
ACIA_TDRE       = %00000010
ACIA_RDRF       = %00000001
ACIA_RESET      = %00000011    ; 6850 reset
ACIA_CFG_115    = %00010101    ; 8-N-1, 115200bps, no IRQ - /16 CLK 
ACIA_CFG_28     = %00010110    ; 8-N-1, 28800bps, no IRQ - /64 CLK 
ACIA_CFG_28I    = %10010110    ; 8-N-1, 28800bps, IRQ - /64 CLK 
TIMER_INTVL     = $270E        ; The number the timer is going to count down from every 10 ms

CR    = $0D
LF    = $0A
BS    = $08
DEL   = $7F 
SPACE = $20
ESC   = $1B
NULL  = $00

; zero page variables from $0000 to $00FF
ZP_START        = $00
JIFFY           = $0A  ; $0A & $0B A two-byte memory location to store a jiffy counter each jiffy is 10 ms
LED_STATUS      = $10
LAST_TOGGLE     = $11
LED_DIR         = $12
PTR_RD_RX_BUF   = $13 ; RX Read Buffer Pointer
PTR_WR_RX_BUF   = $14 ; RX Write Buffer Pointer
PTR_TX          = $15 ; Transmit String Pointer
PTR_TX_L        = $15 ;
PTR_TX_H        = $16 ;

; page 1 from $0100-$01FF
PAGE1_START     = $0100
; reserved memory variables
ACIA_RX_BUFFER  = $0200  ; Serial RX Buffer to $02FF > 256 byte serial receive buffer

