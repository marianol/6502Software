; Herdware for the simple6502

/*
This file is ment to be included in .asm files and has the common variables
and costants that define the hardware of my simple6502 design.
This enables to maintain the haerdware relared constants separated from 
the main assembly code.

Memorey Map:
RAM	31.75k	0x0000	0x7EFF
I/O	256b    0x7F00	0x7FFF
ROM	32k	    0x8000	0xFFFF

*/
; VIA
VIA1_BASE   = $7F10 ; ??? will I put it here?
VIA1_PORTB  = VIA1_BASE
VIA1_PORTA  = VIA1_BASE + 1
VIA1_DDRB   = VIA1_BASE + 2
VIA1_DDRA   = VIA1_BASE + 3
VIA1_T1CL   = VIA1_BASE + 4 ; Timer 1 Counter (low byte)
VIA1_T1CH   = VIA1_BASE + 5 ; Timer 1 Counter (high byte) 
VIA1_ACR    = $900B ;  Auxiliary Control register @
VIA1_IFR    = $900D ; Interrupt Flag Register
VIA1_IER    = $900E ; Interrupt Enable Register
; ACIA MC60B50
ACIA_BASE     = $7F00
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

