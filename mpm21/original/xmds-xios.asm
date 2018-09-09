;
; Note: this module assumes that an ORG statement will be
;   provided by concatenating either BASE0000.ASM or BASE0100.ASM
;   to the front of this file before assembling.
;
;	title	'Xios for the MDS-800'

;	(four drive single density version)
;			-or-
;	(four drive mixed double/single density)

;	Version 1.1 January, 1980

;	Copyright (C) 1979, 1980
;	Digital Research
;	Box 579, Pacific Grove
;	California, 93950

DEFC false  =  0 
DEFC true  =  not 

DEFC asm  =  true 
DEFC mac  =  not 

DEFC sgl  =  true 
DEFC dbl  =  not 

	if	mac
	maclib	diskdef
	endif

DEFC numdisks  =  4 ;number of drives available

;	external jump table (below xios base)
DEFC pdisp  =  $-3 
DEFC xdos  =  pdisp-3 

;	mds interrupt controller equates
DEFC revrt  =  0fdh ; revert port
DEFC intc  =  0fch ; mask port
DEFC icon  =  0f3h ; control port
DEFC rtc  =  0ffh ; real time clock
DEFC inte  =  1111$1101b ; enable rst 1

;	mds disk controller equates
DEFC dskbase  =  78h ; base of disk io prts
DEFC dstat  =  dskbase ; disk status
DEFC rtype  =  dskbase+1 ; result type
DEFC rbyte  =  dskbase+3 ; result byte

DEFC ilow  =  dskbase+1 ; iopb low address
DEFC ihigh  =  dskbase+2 ; iopb high address

DEFC readf  =  4h ; read function
DEFC writf  =  6h ; write function
DEFC iordy  =  4h ; i/o finished mask
DEFC retry  =  10 ; max retries on disk i/o

;	basic i/o system jump vector
	JP	coldstart	;cold start
wboot:
	JP	warmstart	;warm start
	JP	const		;console status
	JP	conin		;console character in
	JP	conout		;console character out
	JP	list		;list character out
	JP	rtnempty	;punch not implemented
	JP	rtnempty	;reader not implemented
	JP	home		;move head to home
	JP	seldsk		;select disk
	JP	settrk		;set track number
	JP	setsec		;set sector number
	JP	setdma		;set dma address
	JP	read		;read disk
	JP	write		;write disk
	JP	pollpt		;list status
	JP	sect$tran		;sector translate

;	extended i/o system jump vector
	JP	selmemory	; select memory
	JP	polldevice	; poll device
	JP	startclock	; start clock
	JP	stopclock	; stop clock
	JP	exitregion	; exit region
	JP	maxconsole	; maximum console number
	JP	systeminit	; system initialization
	JP	idle		; idle procedure

coldstart:
warmstart:
	LD 	c,0		; see system init
				; cold & warm start included only
				; for compatibility with cp/m
	JP	xdos		; system reset, terminate process

;  MP/M 1.0   console handlers

DEFC nmbcns  =  2 ; number of consoles

DEFC poll  =  131 ; xdos poll function

DEFC pllpt  =  0 ; poll printer
DEFC pldsk  =  1 ; poll disk
DEFC plco0  =  2 ; poll console out #0 (CRT:)
DEFC plco1  =  3 ; poll console out #1 (TTY:)
DEFC plci0  =  4 ; poll console in #0 (CRT:)
DEFC plci1  =  5 ; poll console in #1 (TTY:)

;
const:			; console status
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0st	; console #0 status routine
	DEFW	pt1st	; console #1 (TTY:) status rt

conin:			; console input
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0in	; console #0 input
	DEFW	pt1in	; console #1 (TTY:) input

conout:			; console output
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0out	; console #0 output
	DEFW	pt1out	; console #1 (TTY:) output

;
ptbljmp:		; compute and jump to handler
			; d = console #
			; do not destroy <d>
	LD 	a,d
	CP	nmbcns
	JP	C,tbljmp
	POP	AF	; throw away table address
rtnempty:
	XOR	a
	ret
tbljmp:			; compute and jump to handler
			; a = table index
	ADD	A,a	; double table index for adr offst
	POP	HL	; return adr points to jump tbl
	LD 	e,a
	LD 	d,0
	ADD	HL,DE	; add table index * 2 to tbl base
	LD 	e,(HL)	; get handler address
	INC	HL
	LD 	d,(HL)
	EX	DE,HL
	JP	(HL)		; jump to computed cns handler


; ascii character equates

DEFC rubout  =  7fh 
DEFC space  =  20h 

; serial i/o port address equates

DEFC data0  =  0f6h 
DEFC sts0  =  data0+1 
DEFC data1  =  0f4h 
DEFC sts1  =  data1+1 
DEFC lptport  =  0fah 
DEFC lptsts  =  lptport+1 

; poll console #0 input

polci0:
pt0st:			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts0)
	AND	2
	RET	Z
	LD 	a,0ffh
	ret
;
; console #0 input
;
pt0in:			; return character in reg a
	LD 	c,poll
	LD 	e,plci0
	call	xdos		; poll console #0 input
	IN	A,(data0)		; read character
	AND	7fh		; strip parity bit
	ret
;
; console #0 output
;
pt0out:			; reg c = character to output
	IN	A,(sts0)
	AND	01h
	JP	NZ,co0rdy
	PUSH	BC
	call	pt0wait		; poll console #0 output
	POP	BC
co0rdy:
	LD 	a,c
	OUT	(data0),A		; transmit character
	ret
;
; wait for console #0 output ready
;
pt0wait:
	LD 	c,poll
	LD 	e,plco0
	JP	xdos		; poll console #0 output
;	ret

;
; poll console #0 output
;
polco0:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts0)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
;
; line printer driver:
;
list:			; list output
	IN	A,(lptsts)
	AND	01h
	JP	NZ,lptrdy
	PUSH	BC
	LD 	c, poll
	LD 	e, pllpt
	call	xdos
	POP	BC
lptrdy:
	LD 	a,c
	CPL
	OUT	(lptport),A
	ret
;
; poll printer output
;
pollpt:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(lptsts)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
; poll console #1 (TTY:) input
;
polci1:
pt1st:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts1)
	AND	2
	RET	Z
	LD 	a,0ffh
	ret
;
; console #1 (TTY:) input
;
pt1in:
			; return character in reg a
	LD 	c,poll
	LD 	e,plci1
	call	xdos		; poll console #1 input
	IN	A,(data1)		; read character
	AND	7fh		; strip parity bit
	ret
;
; console #1 (TTY:) output
;
pt1out:
	IN	A,(sts1)
	AND	01h
	JP	NZ,co1rdy
			; reg c = character to output
	PUSH	BC
	call	pt1wait
	POP	BC
co1rdy:
	LD 	a,c
	OUT	(data1),A		; transmit character
	ret

; wait for console #1 (TTY:) output ready

pt1wait:
	LD 	c,poll
	LD 	e,plco1
	JP	xdos		; poll console #1 output
;	ret

; poll console #1 (TTY:) output

polco1:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts1)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
;
;  MP/M 1.0   extended i/o system
;
;
DEFC nmbdev  =  6 ; number of devices in poll tbl

polldevice:
			; reg c = device # to be polled
			; return 0ffh if ready,
			;        000h if not
	LD 	a,c
	CP	nmbdev
	JP	C,devok
	LD 	a,nmbdev; if dev # >= nmbdev,
			; set to nmbdev
devok:
	call	tbljmp	; jump to dev poll code

	DEFW	pollpt	; poll printer output
	DEFW	poldsk	; poll disk ready
	DEFW	polco0	; poll console #0 output
	DEFW	polco1	; poll console #1 (TTY:) output
	DEFW	polci0	; poll console #0 input
	DEFW	polci1	; poll console #1 (TTY:) input
	DEFW	rtnempty; bad device handler


; select / protect memory

selmemory:
			; reg bc = adr of mem descriptor
			; bc ->  base   1 byte,
			;        size   1 byte,
			;        attrib 1 byte,
			;        bank   1 byte.

; this hardware does not have memory protection or
;  bank switching

	ret


; start clock

startclock:
			; will cause flag #1 to be set
			;  at each system time unit tick
	LD 	a,0ffh
	LD	(tickn),A
	ret

; stop clock

stopclock:
			; will stop flag #1 setting at
			;  system time unit tick
	XOR	a
	LD	(tickn),A
	ret

; exit region

exitregion:
			; ei if not preempted
	LD	A,(preemp)
	OR	a
	RET	NZ
	ei
	ret

; maximum console number

maxconsole:
	LD 	a,nmbcns
	ret

; system initialization

systeminit:
;	note: this system init assumes that the usarts
;	have been initialized by the coldstart boot

;	setup restart jump vectors
	LD 	a,0c3h
	LD	(1*8),A
	LD	HL,int1hnd
	LD	(1*8+1),HL		; jmp int1hnd at restart 1

;	setup interrupt controller & real time clock
	LD 	a,inte
	OUT	(intc),A		; enable int 0,1,7
	XOR	a
	OUT	(icon),A		; clear int mask
	OUT	(rtc),A		; enable real time clock
	ret

;
; Idle procedure
;
idle:
	LD 	c,dsptch
	JP	xdos		; perform a dispatch, this form
				;  of idle must be used in systems
				;  without interrupts, i.e. all polled

;	-or-

;	ei			; simply halt until awaken by an
;	hlt			;  interrupt
;	ret


;  MP/M 1.0   interrupt handlers

DEFC flagset  =  133 
DEFC dsptch  =  142 

int1hnd:
			; interrupt 1 handler entry point
			;  
			;  location 0008h contains a jmp
			;  to int1hnd.
	PUSH	AF
	LD 	a,2h
	OUT	(rtc),A	; reset real time clock
	OUT	(revrt),A	; revert intr cntlr
	LD	A,(slice)
	DEC	a	; only service every 16th slice
	LD	(slice),A
	JP	Z,t16ms	; jump if 16ms elapsed
	POP	AF
	ei
	ret

t16ms:
	LD 	a,16
	LD	(slice),A	; reset slice counter
	POP	AF
	LD	(svdhl),HL
	POP	HL
	LD	(svdret),HL
	PUSH	AF
	LD	HL,0
	ADD	HL,sp
	LD	(svdsp),HL		; save users stk ptr
	LD	sp,intstk+48	; lcl stk for intr hndl
	PUSH	DE
	PUSH	BC

	LD 	a,0ffh
	LD	(preemp),A	; set preempted flag

	LD	A,(tickn)
	OR	a		; test tickn, indicates
				;  delayed process(es)
	JP	Z,notickn
	LD 	c,flagset
	LD 	e,1
	call	xdos		; set flag #1 each tick
notickn:
	LD	HL,cnt64
	DEC	(HL)		; dec 64 tick cntr
	JP	NZ,not1sec
	LD 	(HL),64
	LD 	c,flagset
	LD 	e,2
	call	xdos		; set flag #2 @ 1 sec
not1sec:
	XOR	a
	LD	(preemp),A	; clear preempted flag
	POP	BC
	POP	DE
	LD	HL,(svdsp)
	LD	SP,HL			; restore stk ptr
	POP	AF
	LD	HL,(svdret)
	PUSH	HL
	LD	HL,(svdhl)

; the following dispatch call will force round robin
;  scheduling of processes executing at the same priority
;  each 1/64th of a second.
; note: interrupts are not enabled until the dispatcher
;  resumes the next process.  this prevents interrupt
;  over-run of the stacks when stuck or high frequency
;  interrupts are encountered.

	JP	pdisp		; MP/M dispatch

;
; bios data segment
;
slice:	DEFM	16	; 16 slices = 16ms = 1 tick
cnt64:	DEFM	64	; 64 tick cntr = 1 sec
intstk:	DEFS	48	; local intrpt stk
svdhl:	DEFW	0	; saved regs hl during int hndl
svdsp:	DEFW	0	; saved sp during int hndl
svdret:	DEFW	0	; saved return during int hndl
tickn:	DEFM	0	; ticking boolean,true = delayed
preemp:	DEFM	0	; preempted boolean
;

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*								*
*	Intel MDS-800 diskette interface routines		*
*								*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

seldsk:	;select disk given by register c
	LD 	HL, 0 
	LD  	a,c
	CP 	numdisks 
	RET	NC  		; first, insure good select
	AND 	2 	
	LD 	(dbank),A	; then save it
	LD 	HL,sel$table 
	LD  	b,0 
	ADD	HL,BC 
	LD  	a,(HL) 
	LD 	(iof),A
	LD  	h,b 
	LD  	l,c
	ADD	HL,HL 
	ADD	HL,HL 
	ADD	HL,HL 
	ADD	HL,HL	; times 16
	LD 	DE,dpbase 
	ADD	HL,DE
	ret

home:	;move to home position
;	treat as track 00 seek
	LD 	c,0
;
settrk:	;set track address given by c
	LD	HL,iot
	LD 	(HL),c
	ret
;
setsec:	;set sector number given by c
	LD 	a,c	;sector number to accum
	LD	(ios),A	;store sector number to iopb
	ret
;
setdma:	;set dma address given by regs b,c
	LD 	l,c
	LD 	h,b
	LD	(iod),HL
	ret

sect$tran:		; translate the sector # in <c> if needed
	LD  	h,b 
	LD  	l,c 
	INC 	HL  ; in case of no translation
	LD  	a, d 
	OR 	e 
	RET	Z	
	EX	DE,HL 
	ADD	HL,BC	; point to physical sector
	LD  	l,(HL) 
	LD  	h,0
	ret


read:	;read next disk record (assuming disk/trk/sec/dma set)
	LD 	c,readf	;set to read function
	JP	setfunc
;
write:	;disk write function
	LD 	c,writf
;
setfunc:
;	set function for next i/o (command in reg-c)
	LD	HL,iof	;io function address
	LD 	a,(HL)	;get it to accumulator for masking
	AND	1111$1000b	;remove previous command
	OR	c	;set to new command
	LD 	(HL),a	;replaced in iopb
;	single density drive 1 requires bit 5 on in sector #
;	mask the bit from the current i/o function
	AND	0010$0000b	;mask the disk select bit
	LD	HL,ios		;address the sector select byte
	OR	(HL)		;select proper disk bank
	LD 	(HL),a		;set disk select bit on/off
;
waitio:
	LD 	c,retry	;max retries before perm error
rewait:
;	start the i/o function and wait for completion
	call	intype	;in rtype
	call	inbyte	;clears the controller

	LD	A,(dbank)		;set bank flags
	OR	a		;zero if drive 0,1 and nz if 2,3
	LD 	a,iopb and 0ffh	;low address for iopb
	LD 	b,iopb shr 8	;high address for iopb
	JP	NZ,iodr1	;drive bank 1?
	OUT	(ilow),A		;low address to controller
	LD 	a,b
	OUT	(ihigh),A	;high address
	JP	wait0		;to wait for complete

iodr1:	;drive bank 1
	OUT	(ilow+10h),A	;88 for drive bank 10
	LD 	a,b
	OUT	(ihigh+10h),A
wait0:
	PUSH	BC		; save retry count
	LD 	c, poll		; function poll
	LD 	e, pldsk	; device is disk
	call	xdos
	POP	BC		; restore retry counter in <c>


;	check io completion ok
	call	intype		;must be io complete (00) unlinked
;	00 unlinked i/o complete,    01 linked i/o complete (not used)
;	10 disk status changed       11 (not used)
	CP	10b		;ready status change?
	JP	Z,wready

;	must be 00 in the accumulator
	OR	a
	JP	NZ,werror		;some other condition, retry

;	check i/o error bits
	call	inbyte
	RLA
	JP	C,wready		;unit not ready
	RRA
	AND	11111110b	;any other errors?  (deleted data ok)
	JP	NZ,werror

;	read or write is ok, accumulator contains zero
	ret

poldsk:
	call	instat			; get current controller status
	AND	iordy			; operation complete ?
	RET	Z				; not done
	LD 	a,0ffh			; done flag
	ret				; to xdos


wready:	;not ready, treat as error for now
	call	inbyte		;clear result byte
	JP	trycount

werror:	;return hardware malfunction (crc, track, seek, etc.)
;	the mds controller has returned a bit in each position
;	of the accumulator, corresponding to the conditions:
;	0	- deleted data (accepted as ok above)
;	1	- crc error
;	2	- seek error
;	3	- address error (hardware malfunction)
;	4	- data over/under flow (hardware malfunction)
;	5	- write protect (treated as not ready)
;	6	- write error (hardware malfunction)
;	7	- not ready
;	(accumulator bits are numbered 7 6 5 4 3 2 1 0)

trycount:
;	register c contains retry count, decrement 'til zero
	DEC	c
	JP	NZ,rewait	;for another try

;	cannot recover from error
	LD 	a,1	;error code
	ret

;	intype, inbyte, instat read drive bank 00 or 10
intype:	LD	A,(dbank)
	OR	a
	JP	NZ,intyp1	;skip to bank 10
	IN	A,(rtype)
	ret
intyp1:	IN	A,(rtype+10h)	;78 for 0,1  88 for 2,3
	ret

inbyte:	LD	A,(dbank)
	OR	a
	JP	NZ,inbyt1
	IN	A,(rbyte)
	ret
inbyt1:	IN	A,(rbyte+10h)
	ret

instat:	LD	A,(dbank)
	OR	a
	JP	NZ,insta1
	IN	A,(dstat)
	ret
insta1:	IN	A,(dstat+10h)
	ret



;	data areas (must be in ram)

dbank:	DEFM	0	;disk bank 00 if drive 0,1
			;	   10 if drive 2,3

iopb:			;io parameter block
	DEFM	80h	;normal i/o operation
iof:	DEFM	readf	;io function, initial read
ion:	DEFM	1	;number of sectors to read
iot:	DEFM	2	;track number
ios:	DEFM	1	;sector number
iod:	DEFW	$-$	;io address


sel$table:
	if	sgl
	DEFM	00h, 30h, 00h, 30h	; drive select bits
	endif
	if	dbl
	DEFM	00h, 10h, 00h, 30h	; drive select bits
	endif

	if	mac and sgl
	disks	numdisks		; generate drive tables
	diskdef	0,1,26,6,1024,243,64,64,2
	diskdef	1,0
	diskdef	2,0
	diskdef	3,0
	endef
	endif

	if	mac and dbl
	disks	numdisks		; generate drive tables
	diskdef 0,1,52,,2048,243,128,128,2
	diskdef	1,0
	diskdef	2,1,26,6,1024,243,64,64,2
	diskdef	3,2
	endef
	endif

	if	asm
DEFC dpbase  =  $ ;base of disk param blks
dpe0:	DEFW	xlt0,0000h	;translate table
	DEFW	0000h,0000h	;scratch area
	DEFW	dirbuf,dpb0	;dir buff, parm block
	DEFW	csv0,alv0	;check, alloc vectors
dpe1:	DEFW	xlt1,0000h	;translate table
	DEFW	0000h,0000h	;scratch area
	DEFW	dirbuf,dpb1	;dir buff, parm block
	DEFW	csv1,alv1	;check, alloc vectors
dpe2:	DEFW	xlt2,0000h	;translate table
	DEFW	0000h,0000h	;scratch area
	DEFW	dirbuf,dpb2	;dir buff, parm block
	DEFW	csv2,alv2	;check, alloc vectors
dpe3:	DEFW	xlt3,0000h	;translate table
	DEFW	0000h,0000h	;scratch area
	DEFW	dirbuf,dpb3	;dir buff, parm block
	DEFW	csv3,alv3	;check, alloc vectors
DEFC dpb0  =  $ ;disk param block
	endif

	if	asm and dbl
	DEFW	52		;sec per track
	DEFM	4		;block shift
	DEFM	15		;block mask
	DEFM	1		;extnt mask
	DEFW	242		;disk size-1
	DEFW	127		;directory max
	DEFM	192		;alloc0
	DEFM	0		;alloc1
	DEFW	32		;check size
	DEFW	2		;offset
DEFC xlt0  =  0 ;translate table
DEFC dpb1  =  dpb0 
DEFC xlt1  =  xlt0 
DEFC dpb2  =  $ 
	endif

	if	asm
	DEFW	26		;sec per track
	DEFM	3		;block shift
	DEFM	7		;block mask
	DEFM	0		;extnt mask
	DEFW	242		;disk size-1
	DEFW	63		;directory max
	DEFM	192		;alloc0
	DEFM	0		;alloc1
	DEFW	16		;check size
	DEFW	2		;offset
	endif

	if	asm and sgl
DEFC xlt0  =  $ 
	endif

	if	asm and dbl
DEFC xlt2  =  $ 
	endif

	if	asm
	DEFM	1
	DEFM	7
	DEFM	13
	DEFM	19
	DEFM	25
	DEFM	5
	DEFM	11
	DEFM	17
	DEFM	23
	DEFM	3
	DEFM	9
	DEFM	15
	DEFM	21
	DEFM	2
	DEFM	8
	DEFM	14
	DEFM	20
	DEFM	26
	DEFM	6
	DEFM	12
	DEFM	18
	DEFM	24
	DEFM	4
	DEFM	10
	DEFM	16
	DEFM	22
	endif

	if	asm and sgl
DEFC dpb1  =  dpb0 
DEFC xlt1  =  xlt0 
DEFC dpb2  =  dpb0 
DEFC xlt2  =  xlt0 
DEFC dpb3  =  dpb0 
DEFC xlt3  =  xlt0 
	endif

	if	asm and dbl
DEFC dpb3  =  dpb2 
DEFC xlt3  =  xlt2 
	endif

	if	asm
DEFC begdat  =  $ 
dirbuf:	DEFS	128		;directory access buffer
	endif

	if	asm and sgl
alv0:	DEFS	31
csv0:	DEFS	16
alv1:	DEFS	31
csv1:	DEFS	16
	endif

	if	asm and dbl
alv0:	DEFS	31
csv0:	DEFS	32
alv1:	DEFS	31
csv1:	DEFS	32
	endif

	if	asm
alv2:	DEFS	31
csv2:	DEFS	16
alv3:	DEFS	31
csv3:	DEFS	16
DEFC enddat  =  $ 
DEFC datsiz  =  $-begdat 
	endif

	DEFM	0	; this last db is req"d to
			; ensure that the hex file
			; output includes the entire
			; diskdef

	end
