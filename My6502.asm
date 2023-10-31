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
; ACIA MC60B50
ACIA_BASE     = $8010
ACIA_STATUS   = ACIA_BASE
ACIA_CONTROL  = ACIA_BASE
ACIA_DATA     = ACIA_BASE + 8   ; ???? check this in hardware 

; Constants
ACIA_TDRE       = %00000010
ACIA_RDRF       = %00000001
ACIA_CONFIG     = %00010101    ; 0/ Set No IRQ; 00/ no RTS; 101/ 8 bit,NONE,1 stop; 01/ x16 clock -> CLK 1.8432Mhz >> 115200bps 
ACIA_RESET      = %00000011
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
PTR_RD_RX_BUF   = #12
PTR_WR_RX_BUF   = #13

; page 1 from $0100-$01FF
PAGE1_START     = $0100
; reserved memory variables
ACIA_RX_BUFFER  = $0200  ; to $02FF > 256 byte serial receive buffer

