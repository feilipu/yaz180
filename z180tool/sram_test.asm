;range code   $4000 $403F
;range test   $4040 $4FFF

;replace base .test.
;replace size $8000 - .test.

    SECTION code

    ; We'll first read bytes from the PC and fill the SRAM with them.

    ld hl, $0000
    ld de, $2000
    ld bc, $1000
    ldir

    ; Then we'll send them back to the PC for verification.

    ld hl, $2000
    ld de, $0000
    ld bc, $1000
    ldir

    ; Then we'll return control to the PC...

    jp $0000
