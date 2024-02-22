  .include "My6502.asm"

  .encoding "ascii"     
  .org $8000 ; skip the first 8k since rom stats at $A000
  .text "ROM starts at $A000 (2000)      "
  .text "bios.asm                        "
  .text "VIA at $9000"
  nop 
  
  .org $A000 ; ROM Start

; Reset Vector 
reset:
  sei ;disable interrupts 
  cld ;turn decimal mode off
  ldx #$FF
  txs ; set the stack
  ; init Jiffy 
  lda #$0
  sta JIFFY
  sta JIFFY + 1
  sta LAST_TOGGLE 

  ; Set VIA portB 
  lda #$ff ; Set all pins on port B to output
  sta VIA1_DDRB
  sta LED_DIR ; LED direction for KITT $FF right $00 left
  ; init port B
  lda #%00000001
  sta VIA1_PORTB
  sta LED_STATUS

  ; init routines
  jsr init_timer    ; VIA1 IRQ Timer
  jsr init_serial   ; 65B50 ACIA

  lda #<startupMessage
  sta PTR_TX
  lda #>startupMessage
  sta PTR_TX_H
  jsr serial_out_str
  lda #'>'
  jsr serial_out

  

; Main BIOS Loop
main_loop:
  nop
  jsr kitt_led ; just cycle the LEDs in Port B
  jsr serial_in
  bcc no_char ; nothing received
  jsr serial_out ; echo char
  no_char:
    jmp main_loop

; Move LED bar in Port B like K.I.T.T
kitt_led:
  pha
  phx
  sec 
  lda JIFFY
  sbc LAST_TOGGLE
  cmp #25 ; have 250ms passed?
  bcc exit_kitt ; if not return 
  ; time has passed rotate the LEDs
  ldx LED_DIR ; check which way we are going
  beq go_left
  ; move led right 
  lda #'>'
  ;jsr serial_out 
  lda LED_STATUS
  lsr ; shift right, move bit 0 in A to carry
  bcc rot_done ; bit 0 was clear we are done
  ora #$02 ; bit 0 was set so switch dir 00000010
  ldx #$00 
  jmp rot_done
  go_left: 
    ; move led left
    lda #'<'
    ;jsr serial_out 
    lda LED_STATUS
    asl ; shift left, move bit 7 in A to carry
    bcc rot_done ; bit 7 was clear we are done
    ora #$40 ; bit 7 was set so switch dir 01000000
    ldx #$ff
  rot_done: ;
    sta LED_STATUS ; rotate done store new status 
    sta VIA1_PORTB
    lda JIFFY  
    sta LAST_TOGGLE ; record the Jiffy of rotation
    stx LED_DIR ; store direction 

  exit_kitt:
    plx
    pla
    rts

; Serial Transmit Routine
; Sends the char in A out the ACIA RS232
serial_out:  
  pha
  pool_acia: ; pulling mode until ready to TX
    lda ACIA_STATUS 
    and #ACIA_TDRE     ; looking at Bit 1 TX Data Register Empty > High = Empty
    beq pool_acia     ; pooling loop if empty
  pla
  sta ACIA_DATA       ; output char in A to TDRE
  rts

; Serial Receive Routine
; Checks if the ACIA has RX a characted and put it in A 
; if a byte was received sets the carry flag, if not it clears it
serial_in:
  lda ACIA_STATUS
  and #ACIA_RDRF     ; look at Bit 0 RX Data Register Full > High = Full
  beq @no_data      ; nothing in the RX Buffer
  lda ACIA_DATA     ; load the byte to A
  sec
  rts 
@no_data:
  clc
  rts

; Serial TX a string from memory
; Sends the a null terminated string via RS232
; PTR_TX is a pointer to the string memory location
serial_out_str:
  ldy #0
  @loop:
    lda (PTR_TX),y
    beq @null_found
    jsr serial_out
    iny
    bra @loop
  @null_found:
  rts

; INIT VIA Timer 1 for the Jiffy counter
; The timer will generate an IRQ every TIMER_INTVL (default $270E ~10ms)  
init_timer:  
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
 
; INIT ACIA
; Reset and set ACIA config. Init the RX buffer pointer
init_serial:
  lda #ACIA_RESET
  sta ACIA_CONTROL
  lda #ACIA_CFG_28    ; 28800 8,N,1
  sta ACIA_CONTROL
  ; Init the RX buffer pointers
  lda #0
  sta PTR_RD_RX_BUF
  sta PTR_WR_RX_BUF
  rts

; Main IRQ Service Routine
irq_handler:
  pha
  phx
  phy
  ; check who called me 
  bit VIA1_IFR          ; Check VIA 1 Bit 6 copied to oVerflow flag, bit 7 to negative flag (Z)
  bvs irq_via1_timer1   ; Overflow set?, process this VIA for Timer 1 IRQ...
  ; other IRQ stuff perhaps?
  exit_isr:
    ply
    plx
    pla
    rti

; process VIA 1 Timer 1 IRQ a.k. Jiffy timer
irq_via1_timer1:
  ; process Timer 1 Jiffy counter > each jiffy is 10 ms
  bit VIA1_T1CL     ; Clears the interrupt
  inc JIFFY         ; Increment low byte
  bne irq_via1_end  ; Low byte didn't roll over (Z=0), so we're all done
  inc JIFFY + 1     ; previous byte rolled over, so increment high byte
  irq_via1_end:
    jmp exit_isr

; NMI Service Routine
nmi_handler:
  jmp reset

; ROM Data
startupMessage:
  .byte	$0C,"## My6502 ##",$0D,$0A,"-- v0.0.1",$0D,$0A,$00

endMessage:
  .byte	$0D,$0A,"# Bye !!",$0D,$0A,$00

; Vectors
  .org $fffa
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK	
