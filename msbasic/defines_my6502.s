; configuration
CONFIG_2A := 1

; CBM2 := 1 ; Added Make belive is CBM2 Since that was our base
; CONFIG_CBM_ALL := 1 ; Needed this for the patches
; CONFIG_DATAFLG := 1
; CONFIG_EASTER_EGG := 1
; CONFIG_FILE := 1; support PRINT#, INPUT#, GET#, CMD
; CONFIG_NO_CR := 1; terminal doesn't need explicit CRs on line ends
; CONFIG_NO_LINE_EDITING := 1; support for "@", "_", BEL etc.
; CONFIG_NO_READ_Y_IS_ZERO_HACK := 1
; CONFIG_PEEK_SAVE_LINNUM := 1
CONFIG_SCRTCH_ORDER := 2

; zero page
ZP_START1 = $00 ; 10 bytes
ZP_START2 = $0A ; 6 bytes + INPUT Buffer - CBM Orig $0D
ZP_START3 = $60 ; 11 bytes - Orig 03
ZP_START4 = $6B ; Orig 13

; extra/override ZP variables
USR				:= GORESTART ; XXX

; inputbuffer
;INPUTBUFFER     := $0200

; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA
WIDTH			:= 40
WIDTH2			:= 30

RAMSTART2		:= $0400

; monitor functions
MONCOUT	:= serial_out   ; CHROUT
MONRDKEY := serial_in    ; GETIN
CHRIN	:= serial_in ; $FFCF
CHROUT	:= serial_out ; $FFD2
LOAD	:= load_bas
SAVE	:= save_bas


