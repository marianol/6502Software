; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause
;
; Define the version number
.define VERSION "0.0.2"


.setcpu "65C02"

.include "My6502.s" ; Constants and Labels

; ROMFILL Segment START
; the first 8k of the ROM are not available
; the IO overlays this seccion
.segment "ROMFILL"     
;.org $8000 
  .byte "ROM starts at $A000 (2000)      "
  .byte "bios.asm                        "
  .byte "Version: "
  .byte VERSION
  .byte "                  "
  .byte " VIA at $9000 / ACIA $8010"
  nop 

; JUMP Table
.segment "HEADER"
COMMAND:      jmp command_prompt
MONITOR:      jmp WOZMON
;SERIAL_INIT:  jsr init_serial << how do I do this?

; BIOS Segment START
.segment "BIOS"  
;.org $A000 ; ROM Start

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
  ; configure terminal 
  ; 28.8 8-N-1
  ; - Send only CR (not CR+LF)
  ; - Handle BS ($08) and DEL ($7F)
  ; - Clear Screen on FF ($0C)

  lda #<startupMessage
  sta PTR_TX
  lda #>startupMessage
  sta PTR_TX_H
  jsr serial_out_str
  nop
  ;jmp command_prompt 
  ; no need to JMP now we can just fall though

; BIOS Command Prompt
; Main PRG Loop
command_prompt:
  nop
  accept_command:
    jsr out_prompt    ; Show Prompt
    ldy #$00          ; Init TXT Buffer index
    next_char:
      jsr serial_in     ; Check for Char
      bcc next_char     ; nothing received keep waiting
      sta RX_BUFFER,y   ; add to buffer
      jsr serial_out    ; echo 
      cmp #$08          ; is Backspace?
      beq delete_last   ; Yes
      cmp #$0D          ; is CR?
      beq process_line  ; Yes
      iny               ; inc buffee cursor
      bpl next_char     ; ask for next if buffer is not full (>127)
    ; line buffer overflow
    jsr out_crlf      ; send CRLF
    lda #<err_overflow
    sta PTR_TX_L
    lda #>err_overflow
    sta PTR_TX_H
    jsr serial_out_str  ; Print Error
    jmp accept_command

  delete_last:          ; backspace pressed
    dey                 ; move buffer cursor back
    bmi accept_command  ; buffer is empty, start over 
    jmp next_char       ; ask for next

  process_line:       ; process the command line
    jsr out_crlf      ; send CRLF
    ; jump to WOZ
    ldx #$00
    lda RX_BUFFER,x
    cmp #$21          ; is !(bang)?
    beq go_woz        ; Yes
    ; just echo it now
    lda #$00          ; null terminate the buffer replacing the CR
    sta RX_BUFFER,y 
    lda #<RX_BUFFER     ; print buffer contents
    sta PTR_TX_L
    lda #>RX_BUFFER
    sta PTR_TX_H
    jsr serial_out_str  ; echo buffer back   
    jmp accept_command  ; start over

; Run WozMon
go_woz:
  lda #<msg_wozmon
  sta PTR_TX_L
  lda #>msg_wozmon
  sta PTR_TX_H
  jsr serial_out_str  ; Print Message
  jsr out_crlf      ; send CRLF
  jmp WOZMON

; Command prompt messages
err_overflow:
  .asciiz "! Buffer Overflow"
err_notfound:
  .asciiz "! Command not found"
msg_wozmon:
  .asciiz "> WozMon <"

; Send Prompt 
out_prompt:
  pha
  jsr out_crlf      ; send CRLF
  ; Send Prompt "$ "
  lda #'$'
  jsr serial_out
  lda #' '
  jsr serial_out
  pla
  rts

; Send CRLF > $0D,$0A 
; does not preserve A
out_crlf:
  lda #$0D        ; CR
  jsr serial_out
  lda #$0A        ; LF
  jsr serial_out
  rts

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
    jsr kitt_led        ; just cycle the LEDs in VIA Port B if needed
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
  jmp WOZMON

; ROM Data
; Startup Messages
startupMessage:
  .byte	$0C,$0D,$0A,"## My6502 ##",$0D,$0A,"-- v"
  .byte VERSION
  .byte $0D,$0A,$00

endMessage:
  .byte	$0D,$0A,"# Bye !!",$0D,$0A,$00

; WozMon
.include "wozmon_sbc.s" 

; Vectors
.segment "RESETVECTORS"
  ;.org $fffa
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK	