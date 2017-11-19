range jump    $4040 $405F
range table   $4060 $407F
range code    $4080 $5FFF
range data    $6000 $6FFF
range temp    $7000 $73FF
range stack   $7400 $77FF

section jump

  ld sp $7800
  ld hl $0000
  push hl

  ld hl .table.
  add a; add l; ld t a
  xor a; adc h; ld s a
  ld l [st+0]
  ld h [st+1]
  jp hl

section table

  words memory_test

  words memory_read
  words ram_write

  words rom_fast_write
  words rom_slow_write
  words rom_fast_write_protect
  words rom_slow_write_protect

  words rom_protect
  words rom_unprotect

section code

  rom_protect
    call protect_eeprom
    call delay
  ret

  rom_unprotect
    ld a $AA; ld [$D555] a
    ld a $55; ld [$AAAA] a
    ld a $80; ld [$D555] a
    ld a $AA; ld [$D555] a
    ld a $55; ld [$AAAA] a
    ld a $20; ld [$D555] a
    call delay
  ret

  rom_slow_write
    ld de $8000
    ld hl $0000
    .loop
      ld c [hl]
      ld a [de]; cp c; jp z .skip
        ld a c; ld [de] a
        .wait
        ld a [de]; cp c; jp nz .wait
        ld a [de]; cp c; jp nz .wait
      .skip
      ld [hl] a
      inc de
    xor a; or d; jp nz .loop
  ret

  rom_slow_write_protect
    ld de $8000
    ld hl $0000
    .loop
      ld c [hl]
      ld a [de]; cp c; jp z .skip
        call protect_eeprom
        ld a c; ld [de] a
        .wait
        ld a [de]; cp c; jp nz .wait
        ld a [de]; cp c; jp nz .wait
      .skip
      ld [hl] a
      inc de
    xor a; or d; jp nz .loop
  ret

  rom_fast_write
    ld de $8000
    ld [address] de
    .loop
      call retrieve_page
      call write_rom_page
      call return_page
      ld a [address+1]
    or a; jp nz .loop
  ret

  rom_fast_write_protect
    ld de $8000
    ld [address] de
    .loop
      call retrieve_page
      call protect_eeprom
      call write_rom_page
      call return_page
      ld a [address+1]
    or a; jp nz .loop
  ret

  retrieve_page
    ld hl $0000
    ld de .temp.
    ld bc 64
    ldir
  ret

  return_page
    ld hl .temp.
    ld de $0000
    ld bc 64
    ldir
  ret

  write_rom_page
    ld hl .temp.
    ld de [address]
    ld bc 63
    ldir
    ld a [hl]
    ld [de] a
    .wait
    ld a [de]; cp [hl]; jp nz .wait
    ld a [de]; cp [hl]; jp nz .wait
    inc de
    ld [address] de
  ret

  ram_write
    ld de $8000
    ld hl $0000
    ld bc $4000
    ldir
    ld hl $0000
    ld bc $4000
    ldir
  ret

  memory_read
    ld hl $8000
    ld de $0000
    ld bc $4000
    ldir
    ld de $0000
    ld bc $4000
    ldir
  ret

  memory_test

    # Get a random address from the PC, for wear-leveling purposes.

    ld a d; or $80; ld d a; ld [address] de; ex hl de

    # Save the original value of that byte...

    ld st values
    ld a [hl]; ld [st+0] a

    # First, try simply changing the value...

    add $69; and $FE
    ld [hl] a; ld [st+1] a

    # Then read it immediately, twice...

    ld a [hl]; ld [st+2] a
    ld a [hl]; ld [st+3] a

    # If it was the original value twice in a row, it's ROM.

    ld a [st+2]; cp [st+0]; jr nz .1
    ld a [st+3]; cp [st+0]; jr nz .1
      jp it_is_rom
    .1

    # If it was the new value twice in a row, it's RAM.

    ld a [st+2]; cp [st+1]; jr nz .2
    ld a [st+3]; cp [st+1]; jr nz .2
      jp it_is_ram
    .2

    # If it was anything else, wait 100 us then read it again, twice...

    call delay
    ld a [hl]; ld [st+4] a
    ld a [hl]; ld [st+5] a

    # If it was the old value, it's locked EEPROM.

    ld a [st+4]; cp [st+0]; jr nz .3
    ld a [st+5]; cp [st+0]; jr nz .3
      jp it_is_locked
    .3

    # If it was the new value, it's unlocked EEPROM.

    ld a [st+4]; cp [st+1]; jr nz .4
    ld a [st+5]; cp [st+1]; jr nz .4
      jp it_is_unlocked
    .4

    # Otherwise, we have no clue...

    call restore_test_byte
    ld hl $0000
    ld [hl] $00  # error code
    ld a [st+0]; ld [hl] a
    ld a [st+1]; ld [hl] a
    ld a [st+2]; ld [hl] a
    ld a [st+3]; ld [hl] a
    ld a [st+4]; ld [hl] a
    ld a [st+5]; ld [hl] a
  ret

  restore_test_byte
  ret
    # try to restore the original value of the test byte
    call delay
    ld hl [address]
    ld a [values]
    ld [hl] a
    call delay
  ret

  it_is_rom
    call restore_test_byte
    ld hl $0000
    ld [hl] $01
  ret

  it_is_ram
    call restore_test_byte
    ld hl $0000
    ld [hl] $02
  ret

  delay
    push bc
    ld bc $0000
    .1
      dec c; jp nz .1
      dec b; jp nz .1
    pop bc
  ret

  it_is_unlocked
    call restore_test_byte

    # Now determine if it supports high-speed programming...

    call prepare_page_test
    call perform_page_test

    push af
      call restore_page_data
      call perform_page_test
    pop af

    or a; jp z .slow

  # Tell the PC

    ld hl $0000
    ld [hl] $03  # error code
  ret

  .slow
    ld hl $0000
    ld [hl] $04  # error code
  ret

  it_is_locked
    call restore_test_byte

    # Now determine if it supports high-speed programming...

    call prepare_page_test
    call protect_eeprom
    call perform_page_test

    push af
      call restore_page_data
      call protect_eeprom
      call perform_page_test
    pop af

    or a; jp z .slow

  # Tell the PC

    ld hl $0000
    ld [hl] $05  # error code
  ret

  .slow
    ld hl $0000
    ld [hl] $06  # error code
  ret

  protect_eeprom
    ld a $AA; ld [$D555] a
    ld a $55; ld [$AAAA] a
    ld a $A0; ld [$D555] a
  ret

  prepare_page_test

    # floor() random address to a page address.

    ld a [address]; and $C0; ld [address] a

    # Copy that page to RAM

    ld hl [address]; ld de .temp. + 64; ld bc 64; ldir

    # Create a mangled version of its data.

    ld hl .temp. + 64
    ld de .temp.
    ld b 64
    .1
      ld a [hl]
      add $69
      and $FE
      ld [de] a
      inc hl
      inc de
    djnz .1

  ret

  perform_page_test

    # Quickly write that mangled data back to the chip.

    ld hl .temp.
    ld de [address]
    ld bc 63
    ldir
    ld a [hl]
    ld [de] a

    # Repeatedly poll the last byte written until it is correct twice.

    ld bc $0000
    .2
    dec bc; ld a b; or c; jp z .incorrect
    ld a [de]; cp [hl]; jp nz .2
    ld a [de]; cp [hl]; jp nz .2

    # Now compare memory!

    ld hl .temp.
    ld de [address]
    ld bc 64
    .3
      ld a [de]
      cp [hl]
      jp nz .incorrect
      inc de
      inc hl
      dec bc
    jp nz .3

    ld a $01
  ret
  .incorrect
    ld a $00
  ret

  restore_page_data
    ld hl .temp. + 64
    ld de .temp.
    ld bc 64
    ldir
  ret

section data

  address; data $0000
  values; data $00 $00 $00 $00 $00 $00

section code

output 'main_code.rom' .jump. $
