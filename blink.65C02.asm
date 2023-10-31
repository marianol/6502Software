  .include "My6502.asm"

  .encoding "ascii"     
  .org $8000 ; skip the first 8k since rom stats at $A000
  .text "ROM starts at $A000 (2000)"
  .text "blink.asm VIA at $9000"
  nop 
  
  .org $A000 ; ROM Start

reset:
  sei ;disable interrupts 
  cld ;turn decimal mode off
  ; set the stack start just in case
  ldx #$FF
  txs

  ; Set VIA portB 
  lda #$ff ; Set all pins on port B to output
  sta VIA1_DDRB

  ; init routines
  jsr init_timer    ; VIA1 IRQ Timer
  ;jsr init_serial   ; 65B50 ACIA

  lda #$50 ; 01010000
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
  sbc LAST_TOGGLE
  cmp #25 ; have 250ms passed?
  bcc exit_blink
  lda LED_STATUS
  lsr
  ror LED_STATUS
  sta VIA1_PORTB
  lda JIFFY
  sta LAST_TOGGLE
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
  sta VIA1_T1CH          ; This starts the timer running
  cli ; enable interrupts
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
  ; check if it was VIA 1
  bit VIA1_IFR    ; Bit 6 copied to overflow flag, bit 7 to negative flag
  bvs irq_via1    ; Overflow clear, so not this VIA...
  ; other IRQ stuff perhaps?
exit_isr:
  ply
  plx
  pla
  rti

; process VIA 1 IRQ
irq_via1:
  ; process Timer 1 Jiffy counter > each jiffy is 10 ms
  bit VIA1_T1CL     ; Clears the interrupt
  inc JIFFY         ; Increment low byte
  bne irq_via1_end  ; Low byte didn't roll over, so we're all done
  inc JIFFY + 1     ; previous byte rolled over, so increment high byte
  irq_via1_end:
    jmp exit_isr

nmi_handler:
  jmp reset

; ROM Data
startupMessage:
  .byte	$0C,"## simple6502 ##",$0D,$0A,"-- v0.0.1",$0D,$0A,$00

endMessage:
  .byte	$0D,$0A,"# Bye !!",$0D,$0A,$00

; Vectors
  .org $fffa
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK	
