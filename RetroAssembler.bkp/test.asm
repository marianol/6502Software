PORTB = $9000
PORTA = $9001
DDRB = $9002
DDRA = $9003

  .org $8000

reset:
  lda #$ff    ; set all pins on Port B to output
  sta DDRB

  lda #$50
  sta PORTB

loop:
  ror
  sta PORTB

  jmp loop

vectors:
  .org $fffa      
    .word reset   ; NMI
    .word reset   ; RESET
    .word $0000   ; IRQ