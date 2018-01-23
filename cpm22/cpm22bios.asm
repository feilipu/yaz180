;
; Converted to z88dk z80asm for YAZ180 by
; Phillip Stevens @feilipu https://feilipu.me
; December 2017
;

INCLUDE "config_yaz180_private.inc"

EXTERN  _asci0_pollc, _asci0_getc, _asci0_putc
EXTERN  _asci1_pollc, _asci1_getc, _asci1_putc
EXTERN  _asci0_flush_Rx_di, _asci1_flush_Rx_di

EXTERN  _dmac0Lock

PUBLIC  _cpm_disks

PUBLIC  _cpm_ccp_tfcb
PUBLIC  _cpm_ccp_tbuff
PUBLIC  _cpm_ccp_tbase

DEFC    _cpm_disks      =   4       ;XXX DO NOT CHANGE number of disks

DEFC    _cpm_dsk0_base  =   $0040   ;base 32 bit LBA of host file for disk 0 (A:) &
                                    ;3 additional LBA for host files (B:, C:, D:)
DEFC    _cpm_src_bank   =   $0050   ;source bank for CP/M CCP/BDOS for warm boot
DEFC    _cpm_ccp_tfcb   =   $005C   ;default file control block
DEFC    _cpm_ccp_tbuff  =   $0080   ;i/o buffer and command line storage
DEFC    _cpm_ccp_tbase  =   $0100   ;transient program storage area

;==============================================================================
;
;       CP/M PAGE 0
;

SECTION cpm_page0

; address = 0x0000

EXTERN  __cpm_bdos_head         ;base of bdos

PUBLIC  _cpm_iobyte
PUBLIC  _cpm_cdisk

   jp boot                      ;ROM boot is first, overwritten by jp wboot later

_cpm_iobyte:                    ;intel I/O byte
    defb    $01                 ;Console = CRT
_cpm_cdisk:                     ;address of current disk number 0=a,... 15=p
    defb    $00

    jp      __cpm_bdos_head

;==============================================================================
;
;       CP/M TRANSITORY PROGRAM AREA
;

SECTION     cpm_tpa

; address = 0x0100

    jp      $0000               ;jump to boot/wboot

;==============================================================================
;
;           cbios for CP/M 2.2 alteration
;

SECTION cpm_bios                ;origin of the cpm bios

EXTERN  __cpm_ccp_head          ;base of ccp
EXTERN  __cpm_bdos_head         ;base of bdos
EXTERN  __cpm_bdos_data_tail    ;end of bdos

;
;*****************************************************
;*                                                   *
;*           CP/M to host disk constants             *
;*                                                   *
;*****************************************************

DEFC    hstalb  =    4096       ;host number of drive allocation blocks
DEFC    hstsiz  =    512        ;host disk sector size
DEFC    hstspt  =    32         ;host disk sectors/trk
DEFC    hstblk  =    hstsiz/128 ;CP/M sects/host buff (4)

DEFC    cpmbls  =    4096       ;CP/M allocation block size BLS
DEFC    cpmdir  =    512        ;CP/M number of directory blocks (each of 32 Bytes)
DEFC    cpmspt  =    hstspt * hstblk    ;CP/M sectors/track (128 = 32 * 512 / 128)

DEFC    secmsk  =    hstblk-1   ;sector mask

;
;*****************************************************
;*                                                   *
;*         BDOS constants on entry to write          *
;*                                                   *
;*****************************************************
DEFC    wrall   =    0          ;write to allocated
DEFC    wrdir   =    1          ;write to directory
DEFC    wrual   =    2          ;write to unallocated


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

    jp    boot      ;cold start
wboote:
    jp    wboot     ;warm start
    jp    const     ;console status
    jp    conin     ;console character in
    jp    conout    ;console character out
    jp    list      ;list character out
    jp    punch     ;punch character out
    jp    reader    ;reader character out
    jp    home      ;move head to home position
    jp    seldsk    ;select disk
    jp    settrk    ;set track number
    jp    setsec    ;set sector number
    jp    setdma    ;set dma address
    jp    read      ;read disk
    jp    write     ;write disk
    jp    listst    ;return list status
    jp    sectran   ;sector translate

;    individual subroutines to perform each function

boot:       ;simplest case is to just perform parameter initialization
    xor     a               ;zero in the accum
    ld      hl, _cpm_iobyte ;set iobyte to 00000001b
    ld      (hl), 00000001b
    ld      (_cpm_cdisk), a ;select disk zero

    ld      (_cpm_ccp_tfcb), a
    ld      hl, _cpm_ccp_tfcb
    ld      d, h
    ld      e, l
    inc     de
    ld      bc, 0x20-1
    ldir                    ;clear default FCB

    jp      gocpm           ;initialize and go to cp/m

wboot:      ;copy the source bank CP/M CCP/BDOS info and then go to normal start.
    ld      a,_cpm_src_bank ;get CP/M CCP/BDOS/BIOS src bank
    or      a               ;check it exists (non zero)
    jp      Z,boot          ;jp to boot, if there's nothing to load

    ld      hl, _dmac0Lock
    sra     (hl)            ;take the DMAC0 lock
    jr      C, wboot

    out0    (SAR0B),a       ;set source bank for CP/M CCP/BDOS loading

    in0     a,(BBR)         ;get the current bank
    rrca                    ;move the current bank to low nibble
    rrca
    rrca
    rrca
    out0    (DAR0B),a       ;set destination (our) bank

    ld      hl,__cpm_bdos_data_tail-__cpm_ccp_head
    out0    (BCR0H),h       ;set up the transfer size
    out0    (BCR0L),l

    ld      hl,__cpm_ccp_head
    out0    (SAR0H),h       ;set up source and destination addresses
    out0    (SAR0L),l
    out0    (DAR0H),h
    out0    (DAR0L),l

    ld      hl,DMODE_MMOD*$100+DSTAT_DE0
    out0    (DMODE),h       ;DMODE_MMOD - memory++ to memory++, burst mode
    out0    (DSTAT),l       ;DSTAT_DE0 - enable DMA channel 0, no interrupt
                            ;in burst mode the Z180 CPU stops until the DMA completes
    ld      a,$FE
    ld      (_dmac0Lock), a ;give DMAC0 free

    jp      gocpm           ;transfer to cp/m if all have been loaded

;=============================================================================
; Common code for cold and warm boot
;=============================================================================
gocpm:
    ld      a,$C3           ;c3 is a jmp instruction
    ld      ($0000),a       ;for jmp to wboot
    ld      hl, wboote      ;wboot entry point
    ld      ($0001),hl      ;set address field for jmp at 0 to wboote

    ld      ($0005),a       ;for jmp to bdos
    ld      hl, __cpm_bdos_head  ;bdos entry point
    ld      ($0006),hl      ;set address field of Jump at 5 to bdos

    ld      bc,$80          ;default dma address is 0x80
    call    setdma

    call    _asci0_flush_Rx_di
    call    _asci1_flush_Rx_di

    ld      a,(_cpm_cdisk)  ;get current disk number
    cp      _cpm_disks      ;see if valid disk number
    jr      C,diskok        ;disk valid, go to ccp
    ld      a,0             ;invalid disk, change to disk 0

diskok:
    ld      c, a            ;send disk number to the ccp
    jp      __cpm_ccp_head  ;go to cp/m for further processing

;=============================================================================
; Console I/O routines
;=============================================================================
const:      ;console status, return 0ffh if character ready, 00h if not
    ld      A,(_cpm_iobyte)
    and     00001011b       ;mask off console and high bit of reader
    cp      00001010b       ;redirected to asci1 TTY
    jr      Z,const1
    cp      00000010b       ;redirected to asci1 TTY
    jr      Z,const1

    and     00000011b       ;remove the reader from the mask - only console bits then remain
    cp      00000001b
    jr      NZ,const1
const0:
    call    _asci0_pollc    ;check whether any characters are in CRT Rx0 buffer
    jr      NC, dataEmpty
dataReady:
    ld      A,$FF
    ret

const1:
    call    _asci1_pollc    ;check whether any characters are in TTY Rx1 buffer
    jr      C, dataReady
dataEmpty:
    xor     A
    ret

conin:    ;console character into register a
    ld      A,(_cpm_iobyte)
    and     00000011b
    cp      00000010b
    jr      Z,reader        ;"BAT:" redirect
    cp      00000001b
    jr      NZ,conin1
conin0:
   call     _asci0_getc     ;check whether any characters are in CRT Rx0 buffer
   jr       NC, conin0      ;if Rx buffer is empty
   and      $7F             ;strip parity bit
   ret

conin1:
   call     _asci1_getc     ;check whether any characters are in TTY Rx1 buffer
   jr       NC, conin1      ;if Rx buffer is empty
   and      $7F             ;strip parity bit
   ret

reader:
    ld      A,(_cpm_iobyte)
    and     00001100b
    cp      00000100b
    jr      Z, conin0
    cp      00000000b
    jr      Z, conin1
    ld      A,$1A           ;CTRL-Z if not asci0 or asci1
    ret

conout:    ;console character output from register c
    ld      l, c            ;Store character
    ld      A,(_cpm_iobyte)
    and     00000011b
    cp      00000010b
    jr      Z,list          ;"BAT:" redirect
    cp      00000001b
    jp      NZ,_asci1_putc
    jp      _asci0_putc

list:
    ld      l, c            ;Store character
    ld      A,(_cpm_iobyte)
    and     11000000b
    cp      01000000b
    jp      Z,_asci0_putc
    cp      00000000b
    jp      Z,_asci1_putc
    ret

punch:
    ld      l, c            ;Store character
    ld      A,(_cpm_iobyte)
    and     00110000b
    cp      00010000b
    jp      Z,_asci0_putc
    cp      00000000b
    jp      Z,_asci1_putc
    ret

listst:     ;return list status
    ld      A,$FF           ;Return list status of 0xFF (ready).
    ret

;=============================================================================
; Disk processing entry points
;=============================================================================

home:       ;move to the track 00 position of current drive
    ld      a,(hstwrt)      ;check for pending write
    or      a
    jr      nz,homed
    ld      (hstact),a      ;clear host active flag
homed:
    ld      bc,$0000

settrk:     ;set track passed from BDOS in register BC.
    ld      (sektrk),bc
    ret

setsec:     ;set sector passed from BDOS given by register BC
    ld      (seksec),bc
    ret

sectran:    ;translate passed from BDOS sector number BC
    ld      h,b
    ld      l,c
    ret

setdma:     ;set dma address given by registers BC
    ld      (dmaadr),bc     ;save the address
    ret

seldsk:    ;select disk given by register c
    ld      hl,$0000        ;error return code
    ld      a, c
    ld      (sekdsk),a
    cp      _cpm_disks      ;must be between 0 and 3
    jr      C,chgdsk        ;if invalid drive will result in BDOS error
    ld      a,(_cpm_cdisk)  ;so set the drive back to default
    cp      c               ;if the default disk is not the same as the
    ret     NZ              ;selected drive then return, or
    xor     a               ;else reset default back to a:
    ld      (_cpm_cdisk),a  ;otherwise stuck in a loop
    ld      (sekdsk),a
    ret

chgdsk:
    ld      (sekdsk),a
    rlca                    ;*2
    rlca                    ;*4
    rlca                    ;*8
    rlca                    ;*16
    ld      hl,dpbase
    ld      b,0
    ld      c,a
    add     hl,bc
    ret

;
;*****************************************************
;*                                                   *
;*      The READ entry point takes the place of      *
;*      the previous BIOS defintion for READ.        *
;*                                                   *
;*****************************************************

;Read one CP/M sector from disk.
;Return a 00h in register a if the operation completes properly, and 01h if an error occurs during the read.
;Disk number in 'sekdsk'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaadr' (0-65535)

;read the selected CP/M sector
read:
    xor     a
    ld      (unacnt),a
    ld      a,1
    ld      (readop),a      ;read operation
    ld      (rsflag),a      ;must read data
    ld      a,wrual
    ld      (wrtype),a      ;treat as unalloc
    jp      rwoper          ;to perform the read

;
;*****************************************************
;*                                                   *
;*    The WRITE entry point takes the place of       *
;*      the previous BIOS defintion for WRITE.       *
;*                                                   *
;*****************************************************

;Write one CP/M sector to disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
;Disk number in 'sekdsk'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaadr' (0-65535)

;write the selected CP/M sector
write:
    xor     a               ;0 to accumulator
    ld      (readop),a      ;not a read operation
    ld      a,c             ;write type in c
    ld      (wrtype),a
    cp      wrual           ;write unallocated?
    jr      NZ,chkuna       ;check for unalloc

;           write to unallocated, set parameters
    ld      a,cpmbls/128    ;next unalloc recs
    ld      (unacnt),a
    ld      a,(sekdsk)      ;disk to seek
    ld      (unadsk),a      ;unadsk = sekdsk
    ld      hl,(sektrk)
    ld      (unatrk),hl     ;unatrk = sectrk
    ld      a,(seksec)
    ld      (unasec),a      ;unasec = seksec

chkuna:
;           check for write to unallocated sector
    ld      a,(unacnt)      ;any unalloc remain?
    or      a
    jr      Z,alloc         ;skip if not

;           more unallocated records remain
    dec     a               ;unacnt = unacnt-1
    ld      (unacnt),a
    ld      a,(sekdsk)      ;same disk?
    ld      hl,unadsk
    cp      (hl)            ;sekdsk = unadsk?
    jr      NZ,alloc        ;skip if not

;           disks are the same
    ld      hl,unatrk
    call    sektrkcmp       ;sektrk = unatrk?
    jr      NZ,alloc        ;skip if not

;           tracks are the same
    ld      a,(seksec)      ;same sector?
    ld      hl,unasec
    cp      (hl)            ;seksec = unasec?
    jr      NZ,alloc        ;skip if not

;           match, move to next sector for future ref
    inc     (hl)            ;unasec = unasec+1
    ld      a,(hl)          ;end of track?
    cp      cpmspt          ;count CP/M sectors
    jr      C,noovf         ;skip if no overflow

;           overflow to next track
    ld      (hl),0          ;unasec = 0
    ld      hl,(unatrk)
    inc     hl
    ld      (unatrk),hl     ;unatrk = unatrk+1

noovf:
;           match found, mark as unnecessary read
    xor     a               ;0 to accumulator
    ld      (rsflag),a      ;rsflag = 0
    jr      rwoper          ;to perform the write

alloc:
;           not an unallocated record, requires pre-read
    xor     a               ;0 to accum
    ld      (unacnt),a      ;unacnt = 0
    inc     a               ;1 to accum
    ld      (rsflag),a      ;rsflag = 1

;
;*****************************************************
;*                                                   *
;*    Common code for READ and WRITE follows         *
;*                                                   *
;*****************************************************
rwoper:
;           enter here to perform the read/write
    xor     a               ;zero to accum
    ld      (erflag),a      ;no errors (yet)
    ld      a,(seksec)      ;compute host sector
    or      a               ;carry = 0
    rra                     ;shift right
    or      a               ;carry = 0
    rra                     ;shift right
    ld      (sekhst),a      ;host sector to seek

;           active host sector?
    ld      hl,hstact       ;host active flag
    ld      a,(hl)
    ld      (hl),1          ;always becomes 1
    or      a               ;was it already?
    jr      Z,filhst        ;fill host if not

;           host buffer active, same as seek buffer?
    ld      a,(sekdsk)
    ld      hl,hstdsk       ;same disk?
    cp      (hl)            ;sekdsk = hstdsk?
    jr      NZ,nomatch

;           same disk, same track?
    ld      hl,hsttrk
    call    sektrkcmp       ;sektrk = hsttrk?
    jr      nz,nomatch

;           same disk, same track, same buffer?
    ld      a,(sekhst)
    ld      hl,hstsec       ;sekhst = hstsec?
    cp      (hl)
    jr      Z,match         ;skip if match

nomatch:
;           proper disk, but not correct sector
    ld      a,(hstwrt)      ;host written?
    or      a
    call    NZ,writehst     ;clear host buff

filhst:
;           may have to fill the host buffer
    ld      a,(sekdsk)
    ld      (hstdsk),a
    ld      hl,(sektrk)
    ld      (hsttrk),hl
    ld      a,(sekhst)
    ld      (hstsec),a
    ld      a,(rsflag)      ;need to read?
    or      a
    call    NZ,readhst      ;yes, if 1
    xor     a               ;0 to accum
    ld      (hstwrt),a      ;no pending write

match:
;           copy data to or from buffer
    ld      a,(seksec)      ;mask buffer number
    and     secmsk          ;least significant bits
    ld      l,a             ;ready to shift
    ld      h,0             ;double count

;    add     hl,hl          ;shift left 7
;    add     hl,hl
;    add     hl,hl
;    add     hl,hl
;    add     hl,hl
;    add     hl,hl
;    add     hl,hl

    xor     a               ;faster shift left 7
    srl     h
    rr      l
    rra
    ld      h,l
    ld      l,a

;           hl has relative host buffer address
    ld      de,hstbuf
    add     hl,de           ;hl = host address
    ex      de,hl           ;now in DE
    ld      hl,(dmaadr)     ;get/put CP/M data
    ld      c,128           ;length of move
    ld      a,(readop)      ;which way?
    or      a
    jr      nz,rwmove       ;skip if read

;           write operation, mark and switch direction
    ld      a,1
    ld      (hstwrt),a      ;hstwrt = 1
    ex      de,hl           ;source/dest swap

rwmove:                     ;FIXME use LDIR or DMAC
;           C initially 128, DE is source, HL is dest
    ld      a,(de)          ;source character
    inc     de
    ld      (hl),a          ;to dest
    inc     hl
    dec     c               ;loop 128 times
    jr      nz,rwmove

;           data has been moved to/from host buffer
    ld      a,(wrtype)      ;write type
    cp      wrdir           ;to directory?
    ld      a,(erflag)      ;in case of errors
    ret     NZ              ;no further processing

;        clear host buffer for directory write
    or      a               ;errors?
    ret     NZ              ;skip if so
    xor     a               ;0 to accum
    ld      (hstwrt),a      ;buffer written
    call    writehst
    ld      a,(erflag)
    ret

;
;*****************************************************
;*                                                   *
;*    Utility subroutine for 16-bit compare          *
;*                                                   *
;*****************************************************
sektrkcmp:
;           HL = unatrk or hsttrk, compare with sektrk
    ex      de,hl
    ld      hl,sektrk
    ld      a,(de)          ;low byte compare
    cp      (HL)            ;same?
    ret     nz              ;return if not
;           low bytes equal, test high 1s
    inc     de
    inc     hl
    ld      a,(de)
    cp      (hl)            ;sets flags
    ret

;
;*****************************************************
;*                                                   *
;*    WRITEHST performs the physical write to        *
;*    the host disk, READHST reads the physical      *
;*    disk.                                          *
;*                                                   *
;*****************************************************

EXTERN ide_write_sector
EXTERN ide_read_sector

writehst:
    ;hstdsk = host disk #,
    ;hsttrk = host track #, maximum 2048 tracks = 11 bits
    ;hstsec = host sect #. 32 sectors = 5 bits
    ;write "hstsiz" bytes
    ;from hstbuf and return error flag in erflag.
    ;return erflag non-zero if error

    call setLBAaddr
    ld hl,hstlba0           ;get the LBA into BCDE
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld c,(hl)
    inc hl
    ld b,(hl)

    ld hl,hstbuf            ;get hstbuf into HL

    ;write a sector
    ;specified by the 4 bytes in BCDE
    ;the address of the origin buffer is in HL
    ;HL is left incremented by 512 bytes
    ;return carry on success, no carry for an error
    call ide_write_sector
    ret C
    ld a,$01
    ld (erflag),a
    ret

readhst:
    ;hstdsk = host disk #,
    ;hsttrk = host track #, maximum 2048 tracks = 11 bits
    ;hstsec = host sect #. 32 sectors = 5 bits
    ;read "hstsiz" bytes
    ;into hstbuf and return error flag in erflag.

    call setLBAaddr
    ld hl,hstlba0           ;get the LBA into BCDE
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld c,(hl)
    inc hl
    ld b,(hl)

    ld hl,hstbuf            ;get hstbuf into HL

    ;read a sector
    ;LBA specified by the 4 bytes in BCDE
    ;the address of the buffer to fill is in HL
    ;HL is left incremented by 512 bytes
    ;return carry on success, no carry for an error
    call ide_read_sector
    ret C
    ld a,$01
    ld (erflag),a
    ret

;=============================================================================
; Convert track/head/sector into LBA for physical access to the disk
;=============================================================================
;
; The yabios provides us with the LBA base location for each of 4 files,
; together with extent of each file, starting from 0x0040 _cpm_dsk0_base in Page 0.
;
; Each LBA is 4 bytes, total 16 bytes, followed by 16 bit extents (measured in LBA)
; sectors, total of 8 bytes.
;
; The translation activity is to set the hstlbaX correctly, using the hstdsk, hstsec,
; and hsttrk information.
;
; Since hstsec is 32 sectors per track, we can use 5 bits for hstsec.
; Also hsttrk can be any number of bits, but since we never have more than 32MB
; of data then 11 bits is a sensible maximum.
;
; This also matches nicely with the calculation, where a 16 bit addition of the
; translation can be added to the base LBA to get the sector.
;

setLBAaddr:
    ld a,(hstdsk)       ;get disk number (0,1,2,3)
    ld d,a
    ld e,$04            ;uint32_t off-set for each disk (file) LBA base address    
    mlt de              ;multiply offset by disk number

    ld hl,_cpm_dsk0_base    ;get the address for disk LBA base address
    add hl,de           ;add the offset to the base address
    ex de,hl            ;DE contains address of active disk (file) LBA LSB

    ld a,(hstsec)       ;prepare the hstsec (5 bits)
    dec a               ;subtract 1 as LBA starts at 0 (CP/M starts with 1).
    add a,a             ;shift hstsec left three bits to remove irrelevant MSBs
    add a,a
    add a,a

    ld hl,(hsttrk)      ;get both bytes of the hsttrk (maximum 11 bits)

    srl h               ;shift HL&A registers (24bits) down three bits
    rr l                ;to get the required 16 bits of CPM LBA
    rra                 ;to add to the file base LBA 28 bits
    srl h
    rr l
    rra
    srl h
    rr l
    rra

    ld h,l              ;move LBA offset back to the 16 (11 + 5) bit pair
    ld l,a

    ex de,hl            ;HL contains address of active disk (file) base LBA LSB
                        ;DE contains the hsttrk+hstsec result

    ld a,(hl)           ;get disk LBA LSB
    add a,e             ;add hsttrk+hstsec LSB
    ld (hstlba0),a      ;write LBA LSB, put it in hstlba0

    inc hl
    ld a,(hl)           ;get disk LBA 1SB
    adc a,d             ;add hsttrk+hstsec 1SB, with carry
    ld (hstlba1),a      ;write LBA 1SB, put it in hstlba1

    inc hl
    ld a,(hl)           ;get disk LBA 2SB
    adc a,$00           ;get disk LBA 2SB, with carry
    ld (hstlba2),a      ;write LBA 2SB, put it in hstlba2

    inc hl
    ld a,(hl)           ;get disk LBA MSB
    adc a,$00           ;get disk LBA MSB, with carry
    ld (hstlba3),a      ;write LBA MSB, put it in hstlba3

    ret

;
;    the remainder of the cbios is reserved uninitialized
;    data area, and does not need to be a part of the
;    system.
;

SECTION cpm_bios_data

;
;    fixed data tables for four-drive standard drives
;    no translations
;
dpbase:
;    disk Parameter header for disk 00
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    0000h, alv00
;    disk parameter header for disk 01
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    0000h, alv01
;    disk parameter header for disk 02
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    0000h, alv02
;    disk parameter header for disk 03
    defw    0000h, 0000h
    defw    0000h, 0000h
    defw    dirbf, dpblk
    defw    0000h, alv03
;
;   disk parameter block for all disks.
;
dpblk:
    defw    cpmspt      ;SPT - sectors per track
    defb    5           ;BSH - block shift factor from BLS
    defb    31          ;BLM - block mask from BLS
    defb    1           ;EXM - Extent mask
    defw    hstalb-1    ;DSM - Storage size (blocks - 1) 16MB disks
    defw    cpmdir-1    ;DRM - Number of directory entries - 1
    defb    $F0         ;AL0 - 1 bit set per directory block
    defb    $00         ;AL1 -            "
    defw    0           ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
    defw    0           ;OFF - Reserved tracks
;
;    end of fixed tables
;

;
;    scratch ram area for bios use
;

sekdsk:     defs    1       ;seek disk number
sektrk:     defs    2       ;seek track number
seksec:     defs    1       ;seek sector number

hstdsk:     defs    1       ;host disk number
hsttrk:     defs    2       ;host track number
hstsec:     defs    1       ;host sector number

hstlba0:    defs    1       ;host LBA
hstlba1:    defs    1
hstlba2:    defs    1
hstlba3:    defs    1

sekhst:     defs    1       ;seek shr secshf
hstact:     defs    1       ;host active flag
hstwrt:     defs    1       ;host written flag

unacnt:     defs    1       ;unalloc rec cnt
unadsk:     defs    1       ;last unalloc disk
unatrk:     defs    2       ;last unalloc track
unasec:     defs    1       ;last unalloc sector

erflag:     defs    1       ;error reporting
rsflag:     defs    1       ;read sector flag
readop:     defs    1       ;1 if read operation
wrtype:     defs    1       ;write operation type
dmaadr:     defs    2       ;last direct memory address

alv00:      defs    ((hstalb-1)/8)+1    ;allocation vector 0
alv01:      defs    ((hstalb-1)/8)+1    ;allocation vector 1
alv02:      defs    ((hstalb-1)/8)+1    ;allocation vector 2
alv03:      defs    ((hstalb-1)/8)+1    ;allocation vector 3

dirbf:      defs    128     ;scratch directory area
hstbuf:     defs    hstsiz  ;buffer for host disk sector

