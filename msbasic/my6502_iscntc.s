; is_CTRL_C
ISCNTC:
    jsr MONRDKEY
    bcc not_CTRL_C  ; no key pressed
    cmp #3           ; was it CTRL+C? ascii 3
    bne not_CTRL_C
    jmp is_CTRL_C

not_CTRL_C:
    rts

is_CTRL_C:
    ; Fall thorugh