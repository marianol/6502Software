; Herdware
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
JIFFY = $0A  ; $0A & $0B A two-byte memory location to store a jiffy counter each jiffy is 10 ms
ACIA_TDRE     = %00000010
ACIA_RDRF     = %00000001
ACIA_CONFIG   = %00010101       ; 0/ Set No IRQ; 00/ no RTS; 101/ 8 bit,NONE,1 stop; 01/ x16 clock -> CLK 1.8432Mhz >> 115200bps 
ACIA_RESET    = %00000011
SERIAL_RX_BUFFER = $0200        ; 256 byte serial receive buffer
PTR_RD_RX_BUFFER = #12
PTR_WR_RX_BUFFER = #13
TIMER_INTVL = $270E             ; The number the timer is going to count down from every 10 ms
LED_STATUS  = $10
last_toggle = $11

CR    = $0D
LF    = $0A
BS    = $08
DEL   = $7F 
SPACE = $20
ESC   = $1B

; zero page start
ZP_START1 = $00

  .encoding "ascii"     
  .org $8000 ; fill first 8k since rom stats at $A000
  .text "ROM starts at $A000 (2000)"
  .text "blink.asm VIA at $9000"
  nop 
  
  .org $A000 ; ROM Start

reset:
  ; init routines
  jsr init_timer    ; VIA1 IRQ Timer
  jsr init_serial   ; 65B50 ACIA

  ; Set VIA portB
  lda #$ff ; Set all pins on port B to output
  sta VIA1_DDRB

  lda #$50 ; 0101
  sta VIA1_PORTB
  sta LED_STATUS

main_loop:
  nop
  jsr blink

  jmp main_loop

blink:
  pha
  sec
  lda JIFFY
  sbc last_toggle
  cmp #25 ; have 250ms passed?
  bcc exit_blink
  ror LED_STATUS
  lda LED_STATUS
  sta VIA1_PORTB
  lda JIFFY
  sta last_toggle
exit_blink:
  pla
  rts

serial_out:  ; sent char in A to the serial port
  pha
  pool_acia:
    lda ACIA_STATUS 
    and ACIA_TDRE     ; looking at Bit 1 which shows TX data register empty
    beq pool_acia
  pla
  sta ACIA_DATA
  rts


init_timer:  ; INIT VIA Timer 1 
  lda #0
  sta JIFFY    ; Or use STZ if using a 65C02, without the LDA line above.
  sta JIFFY + 1
  ; enable IRQ in VIA
  lda #%11000000  ; setting bit 7 sets interrupts and bit 6 enables Timer 1
  sta VIA1_IER
  
  lda #%01000000  ; Set Continuous interrupts with PB7 disabled 
  sta VIA1_ACR
  ; We set up TIMER_INTVL as count down value
  lda #<TIMER_INTVL      ; Load low byte of our 16-bit value
  sta VIA1_T1CL
  lda #>TIMER_INTVL      ; Load high byte of our 16-bit value
  sta VIA1_T1CH           ; This starts the timer running
  cli
  rts

init_serial:
  lda #ACIA_RESET
  sta ACIA_CONTROL
  lda #ACIA_CONFIG    ; 115200bps 8,N,1
  sta ACIA_CONTROL
  lda #0
  sta PTR_RD_RX_BUFFER
  sta PTR_WR_RX_BUFFER
  rts

irq_handler:
  pha
  phx
  phy
  ; other IRQ stuff perhaps
  bit VIA1_IFR         ; Bit 6 copied to overflow flag
  bvc irq_timer_end    ; Overflow clear, so not this...
  irq_timer
    bit VIA1_T1CL        ; Clears the interrupt
    inc JIFFY      ; Increment low byte
    bne irq_timer_end    ; Low byte didn't roll over, so we're all done
    inc JIFFY + 1  ; previous byte rolled over, so increment high byte
irq_timer_end
  jmp exit_isr
  ; other isr stuff
exit_isr
  ply
  plx
  pla
  rti

; Vectors
  .org $fffa
  .word reset ; NMI
  .word reset ; RESET
  .word irq_handler ; IRQ/BRK	
