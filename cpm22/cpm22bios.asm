;
; Converted to z88dk z80asm for YAZ180 by
; Phillip Stevens @feilipu https://feilipu.me
; December 2017
;

INCLUDE "config_yaz180_private.inc"

EXTERN  asm_asci0_pollc, asm_asci0_getc, asm_asci0_putc
EXTERN  asm_asci1_pollc, asm_asci1_getc, asm_asci1_putc
EXTERN  asm_asci0_flush_Rx, asm_asci1_flush_Rx
EXTERN  ide_write_sector, ide_read_sector

EXTERN  _dmac0Lock

EXTERN  _bank_sp                    ;address of initial SP value

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
;*          CP/M to host disk constants              *
;*                                                   *
;*****************************************************

DEFC    hstalb  =    4096       ;host number of drive allocation blocks
DEFC    hstsiz  =    512        ;host disk sector size
DEFC    hstspt  =    256        ;host disk sectors/trk
DEFC    hstblk  =    hstsiz/128 ;CP/M sects/host buff (4)

DEFC    cpmbls  =    4096       ;CP/M allocation block size BLS
DEFC    cpmdir  =    2048       ;CP/M number of directory blocks (each of 32 Bytes)
DEFC    cpmspt  =    hstspt * hstblk    ;CP/M sectors/track (1024 = 256 * 512 / 128)

DEFC    secmsk  =    hstblk-1   ;sector mask

;
;*****************************************************
;*                                                   *
;*          BDOS constants on entry to write         *
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
    ld      (_cpm_cdisk), a ;select disk zero


    jp      gocpm           ;initialize and go to cp/m

wboot:      ;copy the source bank CP/M CCP/BDOS info and then go to normal start.
    ld      sp,(_bank_sp)   ;set SP to original (temporary) boot setting

    ld      a,(_cpm_src_bank)   ;get CP/M CCP/BDOS/BIOS src bank
    or      a               ;check ROM version exists (src bank non zero)
    jr      Z,gocpm         ;jp to gocpm, if there's nothing to load
                            ;cross fingers that the CCP/BDOS still exists

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

;   jp      gocpm           ;transfer to cp/m if all have been loaded

;=============================================================================
; Common code for cold and warm boot
;=============================================================================
gocpm:
    ld      a,$C3           ;C3 is a jmp instruction
    ld      ($0000),a       ;for jmp to wboot
    ld      hl,wboote       ;wboot entry point
    ld      ($0001),hl      ;set address field for jmp at 0 to wboote

    ld      ($0005),a       ;C3 for jmp to bdos entry point
    ld      hl,__cpm_bdos_head   ;bdos entry point
    ld      ($0006),hl      ;set address field of Jump at 5 to bdos

    ld      bc,$0080        ;default dma address is 0x0080
    call    setdma

    xor     a               ;0 accumulator
    ld      (hstact),a      ;host buffer inactive
    ld      (unacnt),a      ;clear unalloc count

    ld      (_cpm_ccp_tfcb), a
    ld      hl, _cpm_ccp_tfcb
    ld      d, h
    ld      e, l
    inc     de
    ld      bc, 0x20-1
    ldir                    ;clear default FCB

    ld      a,(_cpm_cdisk)  ;get current disk number
    cp      _cpm_disks      ;see if valid disk number
    jr      C,diskchk       ;disk number valid, check existence via valid LBA

diskchg:
    xor     a               ;invalid disk, change to disk 0 (A:)
    ld      (_cpm_cdisk),a  ;reset current disk number to disk0 (A:)
    ld      c,a             ;send default disk number to the ccp
    jp      __cpm_ccp_head  ;go to cp/m ccp for further processing

diskchk:
    ld      c,a             ;send current disk number to the ccp
    call    getLBAbase      ;get the LBA base address
    ld      a,(hl)          ;check that the LBA is non Zero
    inc     hl
    or      a,(hl)
    inc     hl
    or      a,(hl)
    inc     hl
    or      a,(hl)
    jr      Z,diskchg       ;invalid disk LBA, so load disk 0 (A:) to the ccp

    jp      __cpm_ccp_head  ;valid disk, go to ccp for further processing

;=============================================================================
; Console I/O routines
;=============================================================================

const:      ;console status, return 0ffh if character ready, 00h if not
    ld      a,(_cpm_iobyte)
    and     00001011b       ;mask off console and high bit of reader
    cp      00001010b       ;redirected to asci1 TTY
    jr      Z,const1
    cp      00000010b       ;redirected to asci1 TTY
    jr      Z,const1

    and     00000011b       ;remove the reader from the mask - only console bits then remain
    cp      00000001b
    jr      NZ,const1
const0:
    call    asm_asci0_pollc ;check whether any characters are in CRT Rx0 buffer
    jr      NC, dataEmpty
dataReady:
    ld      a,$FF
    ret

const1:
    call    asm_asci1_pollc ;check whether any characters are in TTY Rx1 buffer
    jr      C, dataReady
dataEmpty:
    xor     a
    ret

conin:    ;console character into register a
    ld      a,(_cpm_iobyte)
    and     00000011b
    cp      00000010b
    jr      Z,reader        ;"BAT:" redirect
    cp      00000001b
    jr      NZ,conin1
conin0:
   call     asm_asci0_getc  ;check whether any characters are in CRT Rx0 buffer
   jr       NC, conin0      ;if Rx buffer is empty
;  and      $7F             ;omit strip parity bit - support 8 bit XMODEM
   ret

conin1:
   call     asm_asci1_getc  ;check whether any characters are in TTY Rx1 buffer
   jr       NC, conin1      ;if Rx buffer is empty
;  and      $7F             ;omit strip parity bit - support 8 bit XMODEM
   ret

reader:
    ld      a,(_cpm_iobyte)
    and     00001100b
    cp      00000100b
    jr      Z,conin0
    cp      00000000b
    jr      Z,conin1
    ld      a,$1A           ;CTRL-Z if not asci0 or asci1
    ret

conout:    ;console character output from register c
    ld      l,c             ;Store character
    ld      a,(_cpm_iobyte)
    and     00000011b
    cp      00000010b
    jr      Z,list          ;"BAT:" redirect
    cp      00000001b
    jp      NZ,asm_asci1_putc
    jp      asm_asci0_putc

list:
    ld      l,c             ;Store character
    ld      a,(_cpm_iobyte)
    and     11000000b
    cp      01000000b
    jp      Z,asm_asci0_putc
    cp      00000000b
    jp      Z,asm_asci1_putc
    ret

punch:
    ld      l,c             ;Store character
    ld      a,(_cpm_iobyte)
    and     00110000b
    cp      00010000b
    jp      Z,asm_asci0_putc
    cp      00000000b
    jp      Z,asm_asci1_putc
    ret

listst:     ;return list status
    ld      a,$FF           ;Return list status of 0xFF (ready).
    ret

;=============================================================================
; Disk processing entry points
;=============================================================================

home:       ;move to the track 00 position of current drive
    ld      a,(hstwrt)      ;check for pending write
    or      a
    jr      NZ,homed
    ld      (hstact),a      ;clear host active flag
homed:
    ld      bc,$0000

settrk:     ;set track passed from BDOS in register BC
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
    ld      a,c
    cp      _cpm_disks      ;must be between 0 and 3
    jr      C,chgdsk        ;if invalid drive will result in BDOS error

seldskreset:
    xor     a               ;reset default disk back to 0 (A:)
    ld      (_cpm_cdisk),a
    ld      (sekdsk),a      ;and set the seeked disk
    ld      hl,$0000        ;return error code in HL
    ret

chgdsk:
    call    getLBAbase      ;get the LBA base address for disk
    ld      a,(hl)          ;check that the LBA is non-Zero
    inc     hl
    or      a,(hl)
    inc     hl
    or      a,(hl)
    inc     hl
    or      a,(hl)
    jr      Z,seldskreset   ;invalid disk LBA, so load default disk

    ld      a,c             ;recover selected disk
    ld      (sekdsk),a      ;and set the seeked disk
    add     a,a             ;*2 calculate offset into dpbase
    add     a,a             ;*4
    add     a,a             ;*8
    add     a,a             ;*16
    ld      hl,dpbase
    add     a,l
    ld      l,a
    ret     NC              ;return the disk dpbase in HL, no carry
    inc     h
    ret                     ;return the disk dpbase in HL

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
;Track number in 'sektrk'
;Sector number in 'seksec'
;Dma address in 'dmaadr' (0-65535)

;read the selected CP/M sector
read:
    xor     a
    ld      (unacnt),a      ;unacnt = 0
    inc     a
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
;Track number in 'sektrk'
;Sector number in 'seksec'
;Dma address in 'dmaadr' (0-65535)

;write the selected CP/M sector
write:
    xor     a               ;0 to accumulator
    ld      (readop),a      ;not a read operation
    ld      a,c             ;write type in c
    ld      (wrtype),a
    and     wrual           ;write unallocated?
    jr      Z,chkuna        ;check for unalloc

;           write to unallocated, set parameters
    ld      a,cpmbls/128    ;next unalloc recs
    ld      (unacnt),a
    ld      a,(sekdsk)      ;disk to seek
    ld      (unadsk),a      ;unadsk = sekdsk
    ld      a,(sektrk)
    ld      (unatrk),a      ;unatrk = sectrk
    ld      hl,(seksec)
    ld      (unasec),hl     ;unasec = seksec

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
    ld      a,(sektrk)      ;same track?
    ld      hl,unatrk
    cp      (hl)            ;low byte compare sektrk = unatrk?
    jr      NZ,alloc        ;skip if not

;           tracks are the same
    ld      de,seksec       ;same sector?
    ld      hl,unasec
    ld      a,(de)          ;low byte compare seksec = unasec?
    cp      (hl)            ;same?
    jr      NZ,alloc        ;skip if not
    inc     de
    inc     hl
    ld      a,(de)          ;high byte compare seksec = unasec?
    cp      (hl)            ;same?
    jr      NZ,alloc        ;skip if not

;           match, move to next sector for future ref
    ld      hl,(unasec)
    inc     hl              ;unasec = unasec+1
    ld      (unasec),hl
    ld      de,cpmspt       ;count CP/M sectors
    sbc     hl,de           ;end of track?
    jr      C,noovf         ;skip if no overflow

;           overflow to next track
    ld      hl,0
    ld      (unasec),hl     ;unasec = 0
    ld      hl,unatrk
    inc     (hl)            ;unatrk = unatrk+1

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
    ld      hl,(seksec)     ;compute host sector
    ld      a,l             ;assuming 4 CP/M sectors per host sector
    srl     h               ;shift right
    rra
    srl     h               ;shift right
    rra
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
    ld      a,(sektrk)
    ld      hl,hsttrk
    cp      (hl)            ;sektrk = hsttrk?
    jr      NZ,nomatch

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
    ld      a,(sektrk)
    ld      (hsttrk),a
    ld      a,(sekhst)
    ld      (hstsec),a
    ld      a,(rsflag)      ;need to read?
    or      a
    call    NZ,readhst      ;yes, if 1
    xor     a               ;0 to accum
    ld      (hstwrt),a      ;no pending write

match:
;           copy data to or from buffer
    ld      a,(seksec)      ;mask buffer number LSB
    and     secmsk          ;least significant bits, shifted off in sekhst calculation
    ld      h,0             ;double count
    ld      l,a             ;ready to shift

    xor     a               ;shift left 7, for 128 bytes x seksec LSBs
    srl     h
    rr      l
    rra
    ld      h,l
    ld      l,a

;           HL has relative host buffer address
    ld      de,hstbuf
    add     hl,de           ;HL = host address
    ld      de,(dmaadr)     ;get/put CP/M data destination in DE
    ld      bc,128          ;length of move
    ld      a,(readop)      ;which way?
    or      a
    jr      NZ,rwmove       ;skip if read

;           write operation, mark and switch direction
    ld      a,1
    ld      (hstwrt),a      ;hstwrt = 1
    ex      de,hl           ;source/dest swap

rwmove:
    in0     a,(BBR)         ;get the current bank
    rrca                    ;move the current bank to low nibble
    rrca
    rrca
    rrca                    ;save current bank in address format
    out0    (SAR0B),a       ;(SAR0B has only 4 bits)
    out0    (DAR0B),a       ;(DAR0B has only 4 bits)

    out0    (SAR0H),h
    out0    (SAR0L),l
    out0    (DAR0H),d
    out0    (DAR0L),e

    out0    (BCR0H),b       ;set up the transfer size   
    out0    (BCR0L),c

    ld      bc,+(DMODE_MMOD)*$100+DSTAT_DE0
    out0    (DMODE),b       ;DMODE_MMOD - memory++ to memory++, burst mode
    out0    (DSTAT),c       ;DSTAT_DE0 - enable DMA channel 0, no interrupt
                            ;in burst mode the Z180 CPU stops until the DMA completes

;           data has been moved to/from host buffer
    ld      a,(wrtype)      ;write type
    and     wrdir           ;to directory?
    ld      a,(erflag)      ;in case of errors
    ret     Z               ;no further processing

;           clear host buffer for directory write
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
;*    WRITEHST performs the physical write to        *
;*    the host disk, READHST reads the physical      *
;*    disk.                                          *
;*                                                   *
;*****************************************************

writehst:
    ;hstdsk = host disk #, 0,1,2,3
    ;hsttrk = host track #, 64 tracks = 6 bits
    ;hstsec = host sect #, 256 sectors per track = 8 bits
    ;write "hstsiz" bytes
    ;from hstbuf and return error flag in erflag.
    ;return erflag non-zero if error

    call    setLBAaddr      ;get the required LBA into BCDE
    ld      hl,hstbuf       ;get hstbuf address into HL

    ;write a sector
    ;specified by the 4 bytes in BCDE
    ;the address of the origin buffer is in HL
    ;HL is left incremented by 512 bytes
    ;return carry on success, no carry for an error
    call    ide_write_sector
    ret     C
    ld      a,$01
    ld      (erflag),a
    ret

readhst:
    ;hstdsk = host disk #, 0,1,2,3
    ;hsttrk = host track #, 64 tracks = 6 bits
    ;hstsec = host sect #, 256 sectors per track = 8 bits
    ;read "hstsiz" bytes
    ;into hstbuf and return error flag in erflag.

    call    setLBAaddr      ;get the required LBA into BCDE
    ld      hl,hstbuf       ;get hstbuf address into HL

    ;read a sector
    ;LBA specified by the 4 bytes in BCDE
    ;the address of the buffer to fill is in HL
    ;HL is left incremented by 512 bytes
    ;return carry on success, no carry for an error
    call    ide_read_sector
    ret     C
    ld      a,$01
    ld      (erflag),a
    ret

;=============================================================================
; Convert track/head/sector into LBA for physical access to the disk
;=============================================================================
;
; The bios provides us with the LBA base location for each of 4 files,
; in _cpm_dsk0_base. Each LBA is 4 bytes, total 16 bytes
;
; The translation activity is to set the LBA correctly, using the hstdsk, hstsec,
; and hsttrk information.
;
; Since hstsec is 256 sectors per track, we need to use 8 bits for hstsec.
; Since we never have more than 8MB, hsttrk is 6 bits.
;
; This also matches nicely with the calculation, where a 16 bit addition of the
; translation can be added to the base LBA to get the sector.
;

setLBAaddr:
    ld      a,(hstdsk)      ;get disk number (0,1,2,3)
    call    getLBAbase      ;get the LBA base address
                            ;HL contains address of active disk (file) LBA LSB

    ld      a,(hstsec)      ;prepare the hstsec (8 bits, 256 sectors per track)
    add     a,(hl)          ;add hstsec + LBA LSB
    ld      e,a             ;write LBA LSB, put it in E

    inc     hl
    ld      a,(hsttrk)      ;prepare the hsttrk (6 bits, 64 tracks per disk)
    adc     a,(hl)          ;add hsttrk + LBA 1SB, with carry
    ld      d,a             ;write LBA 1SB, put it in D

    inc     hl
    ld      a,(hl)          ;get disk LBA 2SB
    adc     a,$00           ;get disk LBA 2SB, with carry
    ld      c,a             ;write LBA 2SB, put it in C

    inc     hl
    ld      a,(hl)          ;get disk LBA MSB
    adc     a,$00           ;get disk LBA MSB, with carry
    ld      b,a             ;write LBA MSB, put it in B

    ret

getLBAbase:
    add     a,a             ;uint32_t off-set for each disk (file) LBA base address
    add     a,a             ;so left shift 2 (x4), to create offset to disk base address

    ld      hl,_cpm_dsk0_base;get the address for disk LBA base address
    add     a,l             ;add the offset to the base address
    ld      l,a
    ret     NC              ;LBA base address in HL, no carry
    inc     h
    ret                     ;LBA base address in HL

;
;    the remainder of the cbios is reserved uninitialized
;    data area, and does not need to be a part of the
;    system.
;

SECTION cpm_bios_data

;------------------------------------------------------------------------------
; start of fixed tables - non aligned rodata
;------------------------------------------------------------------------------
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
    defw    hstalb-1    ;DSM - Storage size (blocks - 1)
    defw    cpmdir-1    ;DRM - Number of directory entries - 1
    defb    $FF         ;AL0 - 1 bit set per directory block (ALLOC0)
    defb    $FF         ;AL1 - 1 bit set per directory block (ALLOC0)
    defw    0           ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk) (ALLOC1)
    defw    0           ;OFF - Reserved tracks offset

;------------------------------------------------------------------------------
; end of fixed tables
;------------------------------------------------------------------------------

;
;    scratch ram area for bios use
;

sekdsk:     defs    1       ;seek disk number
sektrk:     defs    2       ;seek track number
seksec:     defs    2       ;seek sector number

hstdsk:     defs    1       ;host disk number
hsttrk:     defs    1       ;host track number
hstsec:     defs    1       ;host sector number

sekhst:     defs    1       ;seek shr secshf
hstact:     defs    1       ;host active flag
hstwrt:     defs    1       ;host written flag

unacnt:     defs    1       ;unalloc rec cnt

unadsk:     defs    1       ;last unalloc disk
unatrk:     defs    2       ;last unalloc track
unasec:     defs    2       ;last unalloc sector

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

