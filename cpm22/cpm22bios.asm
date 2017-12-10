;
; Converted to z88dk z80asm for YAZ180 by
; Phillip Stevens @feilipu https://feilipu.me
; December 2017
;

INCLUDE "config_yaz180_private.inc"

EXTERN  _asci0_pollc, _asci0_getc, _asci0_putc
EXTERN  _asci1_pollc, _asci1_getc, _asci1_putc

EXTERN  delay                       ;FIXME just now for debug, remove later
EXTERN  rhexwd, rhex
EXTERN  phexwd, phex
EXTERN  pstring, pnewline

PUBLIC  _cpm_disks

DEFC    _cpm_disks   =   04h        ;XXX DO NOT CHANGE number of disks

PUBLIC  _cpm_ccp_tfcb
PUBLIC  _cpm_ccp_tbuff
PUBLIC  _cpm_ccp_tbase

DEFC    _cpm_ccp_tfcb   =   $005C   ;default file control block
DEFC    _cpm_ccp_tbuff  =   $0080   ;i/o buffer and command line storage
DEFC    _cpm_ccp_tbase  =   $0100   ;transient program storage area

;==============================================================================
;
;       CP/M PAGE 0
;

SECTION cpm_page0

EXTERN  __cpm_bdos_head     ;base of bdos

PUBLIC  _cpm_iobyte
PUBLIC  _cpm_cdisk

; address = 0x0000

    jp wboot

_cpm_iobyte:                ;intel I/O byte
    defb    $01             ;Console = CRT
_cpm_cdisk:                 ;address of current disk number 0=a,... 15=p
    defb    $00

    jp      __cpm_bdos_head

;==============================================================================
;
;       CP/M BIOS
;

;
;    cbios for CP/M 2.2 alteration
;

SECTION cpm_bios                ;origin of the cpm bios

EXTERN  __cpm_ccp_head          ;base of ccp
EXTERN  __cpm_bdos_head         ;base of bdos
EXTERN  __cpm_bdos_data_tail    ;end of bdos

DEFC    nsects  =   (__cpm_bdos_data_tail - __cpm_ccp_head)/128 ;warm start sector count

;
;    jump vector for individual subroutines
;

PUBLIC    boot      ;cold start
PUBLIC    wboot     ;warm start
PUBLIC    const     ;console status
PUBLIC    conin     ;console character in
PUBLIC    conout    ;console character out
PUBLIC    list      ;list character out
PUBLIC    punch     ;punch character out
PUBLIC    reader    ;reader character out
PUBLIC    home      ;move head to home position
PUBLIC    seldsk    ;select disk
PUBLIC    settrk    ;set track number
PUBLIC    setsec    ;set sector number
PUBLIC    setdma    ;set dma address
PUBLIC    read      ;read disk
PUBLIC    write     ;write disk
PUBLIC    listst    ;return list status
PUBLIC    sectran   ;sector translate

    JP    boot      ;cold start
wboote:
    JP    wboot     ;warm start
    JP    const     ;console status
    JP    conin     ;console character in
    JP    conout    ;console character out
    JP    list      ;list character out
    JP    punch     ;punch character out
    JP    reader    ;reader character out
    JP    home      ;move head to home position
    JP    seldsk    ;select disk
    JP    settrk    ;set track number
    JP    setsec    ;set sector number
    JP    setdma    ;set dma address
    JP    read      ;read disk
    JP    write     ;write disk
    JP    listst    ;return list status
    JP    sectran   ;sector translate

;
;    fixed data tables for four-drive standard
;    ibm-compatible 8" disks
;    no translations
;
;    disk Parameter header for disk 00
dpbase:
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    chk00, all00
;    disk parameter header for disk 01
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    chk01, all01
;    disk parameter header for disk 02
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    chk02, all02
;    disk parameter header for disk 03
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    chk03, all03

;
;   sector translate vector
trans:
    defm     1,  7, 13, 19  ;sectors  1,  2,  3,  4
    defm    25,  5, 11, 17  ;sectors  5,  6,  7,  6
    defm    23,  3,  9, 15  ;sectors  9, 10, 11, 12
    defm    21,  2,  8, 14  ;sectors 13, 14, 15, 16
    defm    20, 26,  6, 12  ;sectors 17, 18, 19, 20
    defm    18, 24,  4, 10  ;sectors 21, 22, 23, 24
    defm    16, 22          ;sectors 25, 26

;
;   disk parameter block for all disks.
dpblk:
    defw    26              ;sectors per track
    defm    3               ;block shift factor
    defm    7               ;block mask
    defm    0               ;null mask
    defw    242             ;disk size-1
    defw    63              ;directory max
    defm    192             ;alloc 0
    defm    0               ;alloc 1
    defw    0               ;check size
    defw    2               ;track offset

;
;    end of fixed tables
;
;    individual subroutines to perform each function
boot:       ;simplest case is to just perform parameter initialization
    XOR     a               ;zero in the accum
    LD      hl, _cpm_iobyte ;set iobyte to 00000001b
    LD      (hl), 00000001b
    LD      (_cpm_cdisk), a ;select disk zero

    LD      (_cpm_ccp_tfcb), a
    LD      hl, _cpm_ccp_tfcb
    LD      d, h
    LD      e, l
    inc     de
    LD      bc, 0x20-1
    LDIR                    ;clear default FCB

    JP      gocpm           ;initialize and go to cp/m

wboot:      ;simplest case is to read the disk until all sectors loaded
    LD      sp, 80h         ;use space below buffer for stack
    LD      c, 0            ;select disk 0
    CALL    seldsk
    CALL    home            ;go to track 00
    LD      b, nsects       ;b counts * of sectors to load
    LD      c, 0            ;c has the current track number
    LD      d, 2            ;d has the next sector to read
            ;note that we begin by reading track 0, sector 2 since sector 1
            ;contains the cold start loader, which is skipped in a warm start
    LD      hl, __cpm_ccp_head  ;base of cp/m (initial load point)

load1:                      ;load one more sector
    PUSH    bc              ;save sector count, current track
    PUSH    de              ;save next sector to read
    PUSH    hl              ;save dma address
    LD      c, d            ;get sector address to register C
    CALL    setsec          ;set sector address from register C
    POP     bc              ;recall dma address to B, C
    PUSH    bc              ;replace on stack for later recall
    call    setdma          ;set dma address from B, C

            ;drive set to 0, track set, sector set, dma address set
    call    read
    CP      00h             ;any errors?
    JP      NZ,wboot         ;retry the entire boot if an error occurs

            ;no error, move to next sector
    pop     hl              ;recall dma address
    LD      de, 128         ;dma=dma+128
    ADD     hl,de           ;new dma address is in h, l
    pop     de              ;recall sector address
    pop     bc              ;recall number of sectors remaining, and current trk
    DEC     b               ;sectors=sectors-1
    JP      Z,gocpm         ;transfer to cp/m if all have been loaded

            ;more sectors remain to load, check for track change
    INC     d
    LD      a,d             ;sector=27?, if so, change tracks
    CP      27
    JP      C,load1         ;carry generated if sector<27

            ;end of current track, go to next track
    LD      d, 1            ;begin with first sector of next track
    INC     c               ;track=track+1

            ;save register state, and change tracks
    PUSH    bc
    PUSH    de
    PUSH    hl
    call    settrk          ;track address set from register c
    pop     hl
    pop     de
    pop     bc
    JP      load1           ;for another sector

;
;    end of    load operation, set parameters and go to cp/m
gocpm:
    LD      a, 0c3h         ;c3 is a jmp instruction
    LD      (0),a           ;for jmp to wboot
    LD      hl, wboote      ;wboot entry point
    LD      (1),hl          ;set address field for jmp at 0

    LD      (5),a           ;for jmp to bdos
    LD      hl, __cpm_bdos_head  ;bdos entry point
    LD      (6),hl          ;address field of Jump at 5 to bdos

    LD      bc, 80h         ;default dma address is 80h
    call    setdma

    LD      a,(_cpm_cdisk)  ;get current disk number
    cp      _cpm_disks      ;see if valid disk number
    jp      C,diskok        ;disk valid, go to ccp
    ld      a,0             ;invalid disk, change to disk 0

diskok:
    LD      c, a            ;send to the ccp
    JP      __cpm_ccp_head  ;go to cp/m for further processing

;
;    simple i/o handlers in each case
;
const:      ;console status, return 0ffh if character ready, 00h if not   
    LD      A,(_cpm_iobyte)
    AND     00001011b       ;Mask off console and high bit of reader
    CP      00001010b       ;redirected to asci1 TTY
    JR      Z,const1
    CP      00000010b       ;redirected to asci1 TTY
    JR      Z,const1

    AND     00000011b       ; remove the reader from the mask - only console bits then remain
    CP      00000001b
    JR      NZ,const1
const0:
    CALL    _asci0_pollc    ; check whether any characters are in CRT Rx0 buffer
    JR      NC, dataEmpty
dataReady:
    LD      A,0FFH
    RET

const1:
    CALL    _asci1_pollc    ; check whether any characters are in TTY Rx1 buffer
    JR      C, dataReady
dataEmpty:
    XOR     A
    RET

conin:    ;console character into register a
    LD      A,(_cpm_iobyte)
    AND     00000011b
    CP      00000010b
    JR      Z,reader        ; "BAT:" redirect
    CP      00000001b
    JR      NZ,conin1
conin0:
   call     _asci0_getc     ; check whether any characters are in CRT Rx0 buffer
   jr       NC, conin0      ; if Rx buffer is empty
   and	    7fh	            ; strip parity bit
   ret

conin1:
   call     _asci1_getc     ; check whether any characters are in TTY Rx1 buffer
   jr       NC, conin1      ; if Rx buffer is empty
   and	    7fh	            ; strip parity bit
   ret

reader:        
    LD      A,(_cpm_iobyte)
    AND     00001100b
    CP      00000100b
    JR      Z, conin0
    CP      00000000b
    JR      Z, conin1
    LD      A,$1A           ; CTRL-Z if not asci0 or asci1
    RET

conout:    ;console character output from register c
    LD      l, c            ; Store character
    LD      A,(_cpm_iobyte)
    AND     00000011b
    CP      00000010b
    JR      Z,list          ; "BAT:" redirect
    CP      00000001b
    JP      NZ,_asci1_putc
    JP      _asci0_putc

list:
    LD      l, c            ; Store character
    LD      A,(_cpm_iobyte)
    AND     11000000b
    CP      01000000b
    JP      Z,_asci0_putc
    CP      00000000b
    JP      Z,_asci1_putc
    RET

punch:
    LD      l, c            ; Store character
    LD      A,(_cpm_iobyte)
    AND     00110000b
    CP      00010000b
    JP      Z,_asci0_putc
    CP      00000000b
    JP      Z,_asci1_putc
    RET

listst:     ;return list status
    LD      A,$FF           ; Return list status of 0xFF (ready).
    RET

;
;    i/o drivers for the disk follow
;    for now, we will simply store the parameters away for use
;    in the read and write subroutines
;

home:       ;move to the track 00 position of current drive
            ; translate this call into a settrk call with Parameter 00
    LD      c,0             ;select track 0
    call    settrk
    ret                     ;we will move to 00 on first read/write

seldsk:    ;select disk given by register c
    LD      hl,0000h        ;error return code
    LD      a, c
    LD      (diskno),a
    CP      _cpm_disks      ;must be between 0 and 3
    RET     NC              ;no carry if 4, 5,...

            ;disk number is in the proper range
            ;defs    10     ;space for disk select
            ;compute proper disk Parameter header address
    LD      a,(diskno)
    LD      l, a            ;l=disk number 0, 1, 2, 3
    LD      h, 0            ;high order zero
    ADD     hl,hl           ;*2
    ADD     hl,hl           ;*4
    ADD     hl,hl           ;*8
    ADD     hl,hl           ;*16 (size of each header)
    LD      de, dpbase
    ADD     hl,de           ;hl=,dpbase (diskno*16) Note typo here in original source.
    ret

settrk:     ;set track given by register c
    LD      a, c
    LD      (track),a
    ret

setsec:     ;set sector given by register c
    LD      a, c
    LD      (sector),a
    ret

sectran:
            ;translate the sector given by bc using the
            ;translate table given by de
    EX      de,hl           ;hl=.trans
    ADD     hl,bc           ;hl=.trans (sector)
    ret                     ;FIXME debug no translation

    LD      l, (hl)         ;l=trans (sector)
    LD      h, 0            ;hl=trans (sector)
    ret                     ;with value in hl

setdma:     ;set dma address given by registers b and c
    LD      l, c            ;low order address
    LD      h, b            ;high order address
    LD      (dmaad),hl      ;save the address
    ret

read:
;Read one CP/M sector from disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
;
    XOR     a
    RET                     ;FIXME

    ld      hl,hstbuf       ;buffer to place disk sector (256 bytes)
rd_status_loop_1:
    in      a,(0fh)         ;check status
    and     80h             ;check BSY bit
    jp      NZ,rd_status_loop_1 ;loop until not busy
rd_status_loop_2:
    in      a,(0fh)         ;check    status
    and     40h             ;check DRDY bit
    jp      Z,rd_status_loop_2  ;loop until ready
    ld      a,01h           ;number of sectors = 1
    out     (0ah),a         ;sector count register
    ld      a,(sector)      ;sector
    out     (0bh),a         ;lba bits 0 - 7
    ld      a,(track)       ;track
    out     (0ch),a         ;lba bits 8 - 15
    ld      a,(diskno)      ;disk (only bits 
    out     (0dh),a         ;lba bits 16 - 23
    ld      a,11100000b     ;LBA mode, select host drive 0
    out     (0eh),a         ;drive/head register
    ld      a,20h           ;Read sector command
    out     (0fh),a
rd_wait_for_DRQ_set:
    in      a,(0fh)         ;read status
    and     08h             ;DRQ bit
    jp      Z,rd_wait_for_DRQ_set   ;loop until bit set
rd_wait_for_BSY_clear:
    in      a,(0fh)
    and     80h
    jp      NZ,rd_wait_for_BSY_clear
    in      a,(0fh)         ;clear INTRQ
read_loop:
    in      a,(08h)         ;get data
    ld      (hl),a
    inc     hl
    in      a,(0fh)         ;check status
    and     08h             ;DRQ bit
    jp      NZ,read_loop    ;loop until clear
    ld      hl,(dmaad)      ;memory location to place data read from disk
    ld      de,hstbuf       ;host buffer
    ld      b,128           ;size of CP/M sector
rd_sector_loop:
    ld      a,(de)          ;get byte from host buffer
    ld      (hl),a          ;put in memory
    inc     hl
    inc     de
    djnz    rd_sector_loop  ;put 128 bytes into memory
    in      a,(0fh)         ;get status
    and     01h             ;error bit
    ret

write:
;Write one CP/M sector to disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
    XOR     a
    RET                     ;FIXME

    ld      hl,(dmaad)      ;memory location of data to write
    ld      de,hstbuf       ;host buffer
    ld      b,128           ;size of CP/M sector
wr_sector_loop:
    ld      a,(hl)          ;get byte from memory
    ld      (de),a          ;put in host buffer
    inc     hl
    inc     de
    djnz    wr_sector_loop  ;put 128 bytes in host buffer
    ld      hl,hstbuf       ;location of data to write to disk
wr_status_loop_1:
    in      a,(0fh)         ;check status
    and     80h             ;check BSY bit
    jp      NZ,wr_status_loop_1 ;loop until not busy
wr_status_loop_2:
    in      a,(0fh)         ;check    status
    and     40h             ;check DRDY bit
    jp      Z,wr_status_loop_2  ;loop until ready
    ld      a,01h           ;number of sectors = 1
    out     (0ah),a         ;sector count register
    ld      a,(sector)
    out     (0bh),a         ;lba bits 0 - 7 = "sector"
    ld      a,(track)
    out     (0ch),a         ;lba bits 8 - 15 = "track"
    ld      a,(diskno)
    out     (0dh),a         ;lba bits 16 - 23, use 16 to 20 for "disk"
    ld      a,11100000b     ;LBA mode, select drive 0
    out     (0eh),a         ;drive/head register
    ld      a,30h           ;Write sector command
    out     (0fh),a
wr_wait_for_DRQ_set:
    in      a,(0fh)         ;read status
    and     08h             ;DRQ bit
    jp      Z,wr_wait_for_DRQ_set   ;loop until bit set            
write_loop:
    ld      a,(hl)
    out     (08h),a         ;write data
    inc     hl
    in      a,(0fh)         ;read status
    and     08h             ;check DRQ bit
    jp      NZ,write_loop   ;write until bit cleared
wr_wait_for_BSY_clear:
    in      a,(0fh)
    and     80h
    jp      NZ,wr_wait_for_BSY_clear
    in      a,(0fh)         ;clear INTRQ
    and     01h             ;check for error
    ret

;
;    the remainder of the cbios is reserved uninitialized
;    data area, and does not need to be a part of the
;    system.
;

SECTION cpm_bios_data

track:    defw    0        ;two bytes for expansion
sector:   defw    0        ;two bytes for expansion
dmaad:    defw    _cpm_ccp_tbuff    ;direct memory address
diskno:   defb    0       ;disk number 0-15

;
;    scratch ram area for bdos use

dirbf:    defs    128     ;scratch directory area

all00:    defs    31      ;allocation vector 0
all01:    defs    31      ;allocation vector 1
all02:    defs    31      ;allocation vector 2
all03:    defs    31      ;allocation vector 3
chk00:    defs    16      ;check vector 0
chk01:    defs    16      ;check vector 1
chk02:    defs    16      ;check vector 2
chk03:    defs    16      ;check vector 3

hstbuf:   defs    256     ;buffer for host disk sector

