;
; Converted to z88dk z80asm for YAZ180 by
; Phillip Stevens @feilipu https://feilipu.me
; September 2018
;

INCLUDE "config_yaz180_private.inc"

EXTERN  _asci0_pollc, _asci0_getc, _asci0_putc
EXTERN  _asci1_pollc, _asci1_getc, _asci1_putc
EXTERN  _asci0_flush_Rx_di, _asci1_flush_Rx_di
EXTERN  ide_write_sector, ide_read_sector

EXTERN  _dmac0Lock          ;mutex for DMA Controller 0

EXTERN  _bank_sp            ;address of initial SP value

PUBLIC  _cdisk              ;current disk number 0=a,... 15=p
PUBLIC  _dsk_base           ;base 32 bit LBA of host file for disk 0 (A:) &
                            ;3 additional LBA for host files (B:, C:, D:)
;
;*****************************************************
;*                                                   *
;*                 MP/M constants                    *
;*                                                   *
;*****************************************************

EXTERN  _cpm_ccp_tfcb       ;default file control block
EXTERN  _cpm_ccp_tbuff      ;i/o buffer and command line storage
EXTERN  _cpm_ccp_tbase      ;transient program storage area

DEFC    mpm_cons   =   2    ;XXX DO NOT CHANGE number of consoles
DEFC    mpm_disks  =   4    ;XXX DO NOT CHANGE number of disks

;
;*****************************************************
;*                                                   *
;*           MP/M to host disk constants             *
;*                                                   *
;*****************************************************

DEFC    hstalb  =    4096       ;host number of drive allocation blocks
DEFC    hstsiz  =    512        ;host disk sector size
DEFC    hstspt  =    32         ;host disk sectors/trk
DEFC    hstblk  =    hstsiz/128 ;MP/M sects/host buff (4)

DEFC    cpmbls  =    4096       ;MP/M allocation block size BLS
DEFC    cpmdir  =    512        ;MP/M number of directory blocks (each of 32 Bytes)
DEFC    cpmspt  =    hstspt * hstblk    ;MP/M sectors/track (128 = 32 * 512 / 128)

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
;*****************************************************
;*                                                   *
;*                 XIOS for MP/M 2.1                 *
;*                                                   *
;*****************************************************

SECTION mpm_xios    ;origin of the mpm xios

;
;       jump vector for individual subroutines
;

PUBLIC  commonbase  ;base of resident (non-bankable) XIOS

PUBLIC  coldstart   ;cold start
PUBLIC  warmstart   ;warm start
PUBLIC  const       ;console status
PUBLIC  conin       ;console character in
PUBLIC  conout      ;console character out
PUBLIC  list        ;list character out
PUBLIC  punch       ;punch character out
PUBLIC  reader      ;reader character out

PUBLIC  home        ;move head to home position
PUBLIC  seldsk      ;select disk
PUBLIC  settrk      ;set track number
PUBLIC  setsec      ;set sector number
PUBLIC  setdma      ;set dma address
PUBLIC  read        ;read disk
PUBLIC  write       ;write disk
PUBLIC  listst      ;return list status
PUBLIC  sectran     ;sector translate

PUBLIC  selmemory	;select memory
PUBLIC  polldevice	;poll device
PUBLIC  startclock	;start clock
PUBLIC  stopclock	;stop clock
PUBLIC  exitregion	;exit region
PUBLIC  maxconsole	;maximum console number
PUBLIC  systeminit	;system initialization
PUBLIC  idle        ;idle procedure
	
    jp  commonbase  ;base of resident (non-bankable) XIOS
wboot:
    jp  warmstart   ;warm start
    jp  const       ;console status
    jp  conin       ;console character in
    jp  conout      ;console character out
    jp  list        ;list character out
    jp  punch       ;punch character out
    jp  reader      ;reader character out

    jp  home        ;move head to home position
    jp  seldsk      ;select disk
    jp  settrk      ;set track number
    jp  setsec      ;set sector number
    jp  setdma      ;set dma address
    jp  read        ;read disk
    jp  write       ;write disk
    jp  listst      ;return list status
    jp  sectran     ;sector translate

	jp  selmemory	;select memory
	jp  polldevice	;poll device
	jp  startclock	;start clock
	jp  stopclock	;stop clock
	jp  exitregion	;exit region
	jp  maxconsole	;maximum console number
	jp  systeminit	;system initialization
	jp  idle        ;idle procedure

;
;*****************************************************
;*                                                   *
;*          COMMONBASE of resident XIOS              *
;*                                                   *
;*****************************************************

commonbase:                 ;base of resident (non-bankable) XIOS
    jp  coldstart
swtuser:
    jp  $-$
swtsys:
    jp  $-$
pdisp:
    jp  $-$
xdos:
    jp  $-$
sysdat:
    DEFW    $-$

coldstart:
warmstart:
	ld  a,0		            ;see system init
				            ;cold & warm start included only
				            ;for compatibility with cp/m
	jp  xdos                ;system reset, terminate process

;=============================================================================
; Console I/O routines
;=============================================================================

const:      ;console status, return 0ffh if character ready, 00h if not
    ld      a,d
    and     00000001b
    jr      NZ,const1
const0:
    call    _asci0_pollc    ;check whether any characters are in CRT Rx0 buffer
    jr      NC, dataEmpty
dataReady:
    ld      a,$FF
    ret

const1:
    call    _asci1_pollc    ;check whether any characters are in TTY Rx1 buffer
    jr      C, dataReady
dataEmpty:
    xor     a
    ret

conin:    ;console character into register a
    ld      a,d
    and     00000001b
    jr      NZ,conin1
conin0:
   call     _asci0_getc     ;check whether any characters are in CRT Rx0 buffer
   jr       NC, conin0      ;if Rx buffer is empty
;  and      $7F             ;strip parity bit - support 8 bit XMODEM
   ret

conin1:
   call     _asci1_getc     ;check whether any characters are in TTY Rx1 buffer
   jr       NC, conin1      ;if Rx buffer is empty
;  and      $7F             ;strip parity bit - support 8 bit XMODEM
   ret

conout:    ;console character output from register c
    ld      l,c             ;Store character
    ld      a,d
    and     00000001b
    jp      NZ,_asci1_putc
    jp      _asci0_putc

list:
    ld      l,c             ;Store character
    ld      a,d
    and     00000001b
    jp      NZ,_asci1_putc 
    jp      _asci0_putc

punch:	    ;punch not implemented in MP/M
    ret

reader:     ;reader not implemented in MP/M
    ret

listst:     ;return list status
    ld      a,$FF           ;Return list status of 0xFF (ready).
    ret

;
;*****************************************************
;*                                                   *
;*          Disk processing entry points             *
;*                                                   *
;*****************************************************

home:       ;move to the track 00 position of current drive
    ld      a,(hstwrt)      ;check for pending write
    or      a
    jr      NZ,homed
    ld      (hstact),a      ;clear host active flag
homed:
    ld      bc,$0000

settrk:     ;set track passed from BDOS in register BC.
    ld      (sektrk),bc
    ret

setsec:     ;set sector passed from BDOS given by register C
    ld      a,c
    ld      (seksec),a
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
    cp      mpm_disks       ;must be between 0 and 3
    jr      C,chgdsk        ;if invalid drive will result in BDOS error
    
 seldskreset:
    xor     a               ;reset default disk back to 0 (A:)
    ld      (cdisk),a
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

;Read one MP/M sector from disk.
;Return a 00h in register a if the operation completes properly,
; and 01h if an error occurs during the read.
;Disk number in 'sekdsk'
;Track number in 'sektrk'
;Sector number in 'seksec'
;Dma address in 'dmaadr' (0-65535)

;read the selected MP/M sector
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

;Write one MP/M sector to disk.
;Return a 00h in register a if the operation completes properly,
; and 0lh if an error occurs during the read or write
;Disk number in 'sekdsk'
;Track number in 'sektrk'
;Sector number in 'seksec'
;Dma address in 'dmaadr' (0-65535)

;write the selected MP/M sector
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
    cp      cpmspt          ;count MP/M sectors
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
                            ;assuming 4 MP/M sectors per host sector
    srl     a               ;shift right
    srl     a               ;shift right
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
    ex      de,hl           ;now in DE
    ld      hl,(dmaadr)     ;get/put MP/M data
    ld      bc,128          ;length of move
    ex      de,hl           ;source in HL, destination in DE
    ld      a,(readop)      ;which way?
    or      a
    jr      NZ,rwmove       ;skip if read

;           write operation, mark and switch direction
    ld      a,1
    ld      (hstwrt),a      ;hstwrt = 1
    ex      de,hl           ;source/dest swap

rwmove:
    ldir

;           data has been moved to/from host buffer
    ld      a,(wrtype)      ;write type
    and     wrdir           ;to directory?
    ld      a,(erflag)      ;in case of errors
    ret     Z               ;no further processing

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
    cp      (hl)            ;same?
    ret     NZ              ;return if not
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

writehst:
    ;hstdsk = host disk #,
    ;hsttrk = host track #, maximum 2048 tracks = 11 bits
    ;hstsec = host sect #. 32 sectors per track = 5 bits
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
    ;hstdsk = host disk #,
    ;hsttrk = host track #, maximum 2048 tracks = 11 bits
    ;hstsec = host sect #. 32 sectors per track = 5 bits
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
; The translation activity is to set the LBA correctly, using the hstdsk, hstsec,
; and hsttrk information.
;
; Since hstsec is 32 sectors per track, we need to use 5 bits for hstsec.
; Also hsttrk can be any number of bits, but since we never have more than 32MB
; of data then 11 bits is a sensible maximum.
;
; This also matches nicely with the calculation, where a 16 bit addition of the
; translation can be added to the base LBA to get the sector.
;

setLBAaddr:
    ld      a,(hstdsk)      ;get disk number (0,1,2,3)
    call    getLBAbase      ;get the LBA base address
    ex      de,hl           ;DE contains address of active disk (file) LBA LSB

    ld      a,(hstsec)      ;prepare the hstsec (5 bits, 32 sectors per track)
    add     a,a             ;shift hstsec left three bits to remove irrelevant MSBs
    add     a,a
    add     a,a

    ld      hl,(hsttrk)     ;get both bytes of the hsttrk (maximum 11 bits)

    srl     h               ;shift HL&A registers (24bits) down three bits
    rr      l               ;to get the required 16 bits of CPM LBA
    rra                     ;to add to the file base LBA 28 bits
    srl     h
    rr      l
    rra
    srl     h
    rr      l
    rra

    ld      h,l             ;move LBA offset back to the 16 (11 + 5) bit pair
    ld      l,a
               
    ex      de,hl           ;HL contains address of active disk (file) base LBA LSB
                            ;DE contains the hsttrk:hstsec result

    ld      a,(hl)          ;get disk LBA LSB
    add     a,e             ;add hsttrk:hstsec LSB
    ld      e,a             ;write LBA LSB, put it in E

    inc     hl
    ld      a,(hl)          ;get disk LBA 1SB
    adc     a,d             ;add hsttrk:hstsec 1SB, with carry
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

    ld      hl,dsk_base     ;get the address for disk LBA base address
    add     a,l             ;add the offset to the base address
    ld      l,a
    ret     NC              ;LBA base address in HL, no carry
    inc     h
    ret                     ;LBA base address in HL

;
;*****************************************************
;*                                                   *
;*                   XIOS calls                      *
;*                                                   *
;*****************************************************

;
; Select / Protect Memory
;
selmemory:
			; Reg BC = adr of mem descriptor
			; BC ->  base   1 byte,
			;        size   1 byte,
			;        attrib 1 byte,
			;        bank   1 byte.

    ret

;
; Poll Devices
;
polldevice:
			; Reg C = device # to be polled
			; return 0ffh if ready,
			;        000h if not
    ret
    
;
; Start Clock
;
startclock:
			; will cause flag #1 to be set
			;  at each system time unit tick
	ld  a,0ffh
	ld	(tickn),a
	ret

;
; Stop Clock
;
stopclock:
			; will stop flag #1 setting at
			;  system time unit tick
	xor a
	LD	(tickn),a
	ret

;
; Exit Region
;
exitregion:
			; EI if not preempted or in dispatcher
	ld  a,(preemp)
	or  a
	ret NZ
	ei
	ret

;
; Maximum Console Number
;
maxconsole:
	ld  a,mpm_cons
	ret

;
; System Initialization
;
systeminit:
;
;  This is the place to insert code to initialize
;  the time of day clock, if it is desired on each
;  booting of the system.
;
	ld 	a,0c3h
	ld	(0038h),A
	ld    HL,inthnd
	ld	(0039h),HL		;JMP INTHND at 0038H

	ld 	c,create
	if    debug
	ld    DE,c2inpd
	else
	ld    DE,c0inpd
	endif
	call xdos

	ld    A,(intmsk)
	out	(60h),A		    ;init interrupt mask

	im  1	            ;Interrupt Mode 1
	ei
	call    home
	ld 	c,flagwait
	ld 	e,5
	jp    xdos		    ;clear first disk interrupt


;=============================================================================
; Common code for cold and warm boot
;=============================================================================

;boot:      ;simplest case is to just perform parameter initialization
;   xor     a               ;zero in the accum
;   ld      (cdisk), a ;select disk zero


;   jp      gompm           ;initialize and go to mp/m

;wboot:     ;copy the source bank MP/M CCP/BDOS info and then go to normal start.
;   ld      sp,(_bank_sp)   ;set SP to original (temporary) boot setting

;   ld      a,(_cpm_src_bank)   ;get MP/M CCP/BDOS/BIOS src bank
;   or      a               ;check ROM version exists (src bank non zero)
;   jr      Z,gocpm         ;jp to gocpm, if there's nothing to load
                            ;cross fingers that the CCP/BDOS still exists

;   ld      hl, _dmac0Lock
;   sra     (hl)            ;take the DMAC0 lock
;   jr      C, wboot

;   out0    (SAR0B),a       ;set source bank for MP/M CCP/BDOS loading

;   in0     a,(BBR)         ;get the current bank
;   rrca                    ;move the current bank to low nibble
;   rrca
;   rrca
;   rrca
;   out0    (DAR0B),a       ;set destination (our) bank

;   ld      hl,__cpm_bdos_data_tail-__cpm_ccp_head
;   out0    (BCR0H),h       ;set up the transfer size
;   out0    (BCR0L),l

;   ld      hl,__cpm_ccp_head
;   out0    (SAR0H),h       ;set up source and destination addresses
;   out0    (SAR0L),l
;   out0    (DAR0H),h
;   out0    (DAR0L),l

;   ld      hl,DMODE_MMOD*$100+DSTAT_DE0
;   out0    (DMODE),h       ;DMODE_MMOD - memory++ to memory++, burst mode
;   out0    (DSTAT),l       ;DSTAT_DE0 - enable DMA channel 0, no interrupt
                            ;in burst mode the Z180 CPU stops until the DMA completes
;   ld      a,$FE
;   ld      (_dmac0Lock), a ;give DMAC0 free

;   jp      gocpm           ;transfer to MP/M if all have been loaded


gompm:
    ld      a,$C3           ;C3 is a jmp instruction
    ld      ($0000),a       ;for jmp to wboot
    ld      hl,wboot        ;wboot entry point
    ld      ($0001),hl      ;set address field for jmp at 0 to wboot

    ld      ($0005),a       ;C3 for jmp to bdos entry point
    ld      hl,__cpm_bdos_head   ;bdos entry point
    ld      ($0006),hl      ;set address field of Jump at 5 to bdos

    ld      bc,$0080        ;default dma address is 0x0080
    call    setdma

    xor     a               ;0 accumulator
    ld      (hstact),a      ;host buffer inactive
    ld      (unacnt),a      ;clear unalloc count

    ld      (_cpm_ccp_tfcb), a
    ld      hl,_cpm_ccp_tfcb
    ld      d,h
    ld      e,l
    inc     de
    ld      bc,0x20-1
    ldir                    ;clear default FCB

    call    _asci0_flush_Rx_di
    call    _asci1_flush_Rx_di

    ld      a,(cdisk)       ;get current disk number
    cp      mpm_disks       ;see if valid disk number
    jr      C,diskchk       ;disk number valid, check existence via valid LBA

diskchg:
    xor     a               ;invalid disk, change to disk 0 (A:)
    ld      (cdisk),a       ;reset current disk number to disk0 (A:)
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


;
; Idle procedure
;
idle:
    ei
    halt
    ret			        ;for full interrupt system


;------------------------------------------------------------------------------
; start of fixed tables - non aligned rodata
;------------------------------------------------------------------------------
;

SECTION mpm_xios_data

ALIGN 0x0008                ;align the bios data

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
    defb    $F0         ;AL0 - 1 bit set per directory block (ALLOC0)
    defb    $00         ;AL1 - 1 bit set per directory block (ALLOC0)
    defw    0           ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk) (ALLOC1)
    defw    0           ;OFF - Reserved tracks offset

;------------------------------------------------------------------------------
;    end of fixed tables
;------------------------------------------------------------------------------

;
;    scratch ram area for bios use
;

_cdisk:     defs    1       ;current disk number 0=a,... 15=p
_dsk_base:  defs    16      ;base 32 bit LBA of host file for disk 0 (A:) &
                            ;3 additional LBA for host files (B:, C:, D:)

sekdsk:     defs    1       ;seek disk number
sektrk:     defs    2       ;seek track number
seksec:     defs    1       ;seek sector number

hstdsk:     defs    1       ;host disk number
hsttrk:     defs    2       ;host track number
hstsec:     defs    1       ;host sector number

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

tickn       defb    0       ;ticking boolean, true = delayed
preempt:    defb    0       ;preempted boolean & ensure HEX file is complete

