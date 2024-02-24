; snippets from https://mansfield-devine.com/speculatrix/2021/11/zolatron-64-6502-homebrew-converting-between-text-and-numbers-in-assembly/


TMP_TEXT_BUF = $07A0 ; general-purpose buffer/scratchpad
 
.hex_chr_tbl         ; hex character table
  .text "0123456789ABCDEF"
; convert 1-byte value to 2-char hex string
.byte_to_hex_str ; assumes that number to be converted is in A
  tax                ; keep a copy of A in X for later
  lsr A              ; logical shift right 4 bits
  lsr A
  lsr A
  lsr A              ; A now contains upper nibble of value
  tay                ; put in Y to act as offset
  lda hex_chr_tbl,Y  ; load A with appropriate char from lookup table
  sta TMP_TEXT_BUF   ; and stash that in the text buffer
  txa                ; recover original value of A
  and #%00001111     ; mask to get lower nibble value
  tay                ; again, put in Y to act as offset
  lda hex_chr_tbl,Y  ; load A with appropriate char from lookup table
  sta TMP_TEXT_BUF+1 ; and stash that in the next byte of the buffer
  lda #0             ; and end with a null byte
  sta TMP_TEXT_BUF+2
  rts

; now the other way Hex to ASCII
FUNC_RESULT = $60 ; to hold the result of a subroutine
BYTE_CONV_L = $63 ; scratch space for converting bytes between num & string
BYTE_CONV_H = BYTE_CONV_L+1
.hex_str_to_byte      ; assumes text is in BYTE_CONV_H and BYTE_CONV_L
  lda BYTE_CONV_H       ; load the high nibble character
  jsr asc_hex_to_bin    ; convert to number - result is in A
  asl A                 ; shift to high nibble
  asl A
  asl A
  asl A
  sta FUNC_RESULT       ; and store
  lda BYTE_CONV_L       ; get the low nibble character
  jsr asc_hex_to_bin    ; convert to number - result is in A
  ora FUNC_RESULT       ; OR with previous result
  sta FUNC_RESULT       ; and store final result
  rts
 
.asc_hex_to_bin          ; assumes ASCII char val is in A
  sec
  sbc #$30               ; subtract $30 - this is good for 0-9
  cmp #10                ; is value more than 10?
  bcc asc_hex_to_bin_end ; if not, we're okay
  sbc #$07               ; otherwise subtract another $07 for A-F
.asc_hex_to_bin_end
  rts                    ; value is returned in A