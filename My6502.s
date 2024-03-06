; Herdware for the My6502
;
; This file is ment to be included in source files and has the common variables
; and costants that define the herdware of my My6502 design.
; This enables to maintain the herdware relared constants separated from 
; the main assembly code.

; Memory Map:
;  RAM	32k	0x0000	0x7FFF
;  I/O	8k	0x8000	0x9FFF
;  ROM	24k	0xA000	0xFFFF

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

; 6522 VIA IFR REGISTER
; Bit Desc
; 7   Any IRQ
; 6   Timer 1 Overflow Interrupt
; 5   Timer 2 Overflow Interrupt
; 4   CB1 Active Edge
; 3   CB2 Active Edge
; 2   Shift Register Complete 8 Shifts
; 1   CA1 Active Edge
; 0   CA2 Active Edge

; SPI on VIA Port A
; SCL  PA0
; MOSI PA1
; MISO PA6
; CS1  PA2
; CS2  PA3
; CS3  PA4
; PA2, PA3, and PA4 are connected to the A, B, and C inputs on a 74xx138 3 to 8 decoder 
; to provide chip selects for up to 7 devices 1-7, 0 is reserved for no device selected. 
; See spi_select_device: routine for implementation.

; Will use code from https://github.com/bradleystach/65C02-SPI
; Note: 
; Depending on the SPI modes you need, you can sometimes share clock and data lines 
; with I²C.  You'll have to observe the following:
;   - Never transition the data line when the clock is high except to produce start 
;     and stop conditions on I²C.
;   - Keep the EN (of Microwire) or CS (of SPI) lines high (false) when addressing 
;    I²C devices.

; ACIA MC60B50
; Chip Select Connections
; CS0	 = A4
; CS1	 = A4
; ~CS2   = ~IO_SEL
; RS     = A3
ACIA_BASE     = $8010
ACIA_STATUS   = ACIA_BASE       ; Read Only RS 0 + R 
ACIA_CONTROL  = ACIA_BASE       ; Write Only RS 0 + W
ACIA_DATA     = ACIA_BASE + 8   ; RS 1 + R/W > RX/TX

; ACIA Constants
; 
ACIA_TDRE       = %00000010    ; bitmask for TRDE
ACIA_RDRF       = %00000001    ; bitmask for RDRF
ACIA_RESET      = %00000011    ; 6850 reset
; ACIA Config
; Bit# / Desc
; 7/ RX IRQ 
; 6,5/ TX IRQ & RTS 
; 4,3,2/ Bit length, parity & stop
; 1,0/ ÷1,÷16,÷64 Clock Divider & Reset 
; CLK @ 1.8432Mhz 
ACIA_CFG_115    = %00010101    ; 8-N-1, 115200bps, no IRQ - /16 CLK 
ACIA_CFG_28     = %00010110    ; 8-N-1, 28800bps, no IRQ - /64 CLK 
ACIA_CFG_28I    = %10010110    ; 8-N-1, 28800bps, IRQ - /64 CLK 

; Misc Constants
TIMER_INTVL     = $270E        ; The number the timer is going to count down from every 10 ms
; CR    = $0D
; LF    = $0A
BS    = $08
DEL   = $7F 
SPACE = $20
ESC   = $1B
NULL  = $00

; zero page variables from $0000 to $00FF
ZP_START        = $00
JIFFY           = $E0  ; $E0 & $E1 A two-byte memory location to store a jiffy counter each jiffy is 10 ms
LED_STATUS      = $E2
LAST_TOGGLE     = $E3
LED_DIR         = $E4
PTR_RD_RX_BUF   = $E5 ; RX Read Buffer Pointer
PTR_WR_RX_BUF   = $E6 ; RX Write Buffer Pointer
PTR_TX          = $E7 ; Transmit String Pointer
PTR_TX_L        = $E7 ; LO Byte
PTR_TX_H        = $E8 ; HI Byte

; WozMon ZeroPage Variables
; uses $24 to $2B for its variables
XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM

; reserved memory variables
PAGE1_START     = $0100  ; page 1 from $0100-$01FF
RX_BUFFER       = $0200  ; Serial RX Buffer to $02FF > 256 byte serial receive buffer
                         ; Shared with WozMon IN Buffer

