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

false	equ	0
true	equ	not false

asm	equ	true
mac	equ	not asm

sgl	equ	true
dbl	equ	not sgl

	if	mac
	maclib	diskdef
	endif

numdisks equ	4	;number of drives available

;	external jump table (below xios base)
pdisp	equ	$-3
xdos	equ	pdisp-3

;	mds interrupt controller equates
revrt	equ	0fdh	; revert port
intc	equ	0fch	; mask port
icon	equ	0f3h	; control port
rtc	equ	0ffh	; real time clock
inte	equ	1111$1101b ; enable rst 1

;	mds disk controller equates
dskbase	equ	78h	; base of disk io prts
dstat	equ	dskbase	; disk status
rtype	equ	dskbase+1	; result type
rbyte	equ	dskbase+3	; result byte

ilow	equ	dskbase+1	; iopb low address
ihigh	equ	dskbase+2	; iopb high address

readf	equ	4h	; read function
writf	equ	6h	; write function
iordy	equ	4h	; i/o finished mask
retry	equ	10	; max retries on disk i/o

;	basic i/o system jump vector
	jmp	coldstart	;cold start
wboot:
	jmp	warmstart	;warm start
	jmp	const		;console status
	jmp	conin		;console character in
	jmp	conout		;console character out
	jmp	list		;list character out
	jmp	rtnempty	;punch not implemented
	jmp	rtnempty	;reader not implemented
	jmp	home		;move head to home
	jmp	seldsk		;select disk
	jmp	settrk		;set track number
	jmp	setsec		;set sector number
	jmp	setdma		;set dma address
	jmp	read		;read disk
	jmp	write		;write disk
	jmp	pollpt		;list status
	jmp	sect$tran	;sector translate

;	extended i/o system jump vector
	jmp	selmemory	; select memory
	jmp	polldevice	; poll device
	jmp	startclock	; start clock
	jmp	stopclock	; stop clock
	jmp	exitregion	; exit region
	jmp	maxconsole	; maximum console number
	jmp	systeminit	; system initialization
	jmp	idle		; idle procedure

coldstart:
warmstart:
	mvi	c,0		; see system init
				; cold & warm start included only
				; for compatibility with cp/m
	jmp	xdos		; system reset, terminate process

;  MP/M 1.0   console handlers

nmbcns	equ	2	; number of consoles

poll	equ	131	; xdos poll function

pllpt	equ	0	; poll printer
pldsk	equ	1	; poll disk
plco0	equ	2	; poll console out #0 (CRT:)
plco1	equ	3	; poll console out #1 (TTY:)
plci0	equ	4	; poll console in #0 (CRT:)
plci1	equ	5	; poll console in #1 (TTY:)

;
const:			; console status
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0st	; console #0 status routine
	dw	pt1st	; console #1 (TTY:) status rt

conin:			; console input
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0in	; console #0 input
	dw	pt1in	; console #1 (TTY:) input

conout:			; console output
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0out	; console #0 output
	dw	pt1out	; console #1 (TTY:) output

;
ptbljmp:		; compute and jump to handler
			; d = console #
			; do not destroy <d>
	mov	a,d
	cpi	nmbcns
	jc	tbljmp
	pop	psw	; throw away table address
rtnempty:
	xra	a
	ret
tbljmp:			; compute and jump to handler
			; a = table index
	add	a	; double table index for adr offst
	pop	h	; return adr points to jump tbl
	mov	e,a
	mvi	d,0
	dad	d	; add table index * 2 to tbl base
	mov	e,m	; get handler address
	inx	h
	mov	d,m
	xchg
	pchl		; jump to computed cns handler


; ascii character equates

rubout	equ	7fh
space	equ	20h

; serial i/o port address equates

data0	equ	0f6h
sts0	equ	data0+1
data1	equ	0f4h
sts1	equ	data1+1
lptport	equ	0fah
lptsts	equ	lptport+1

; poll console #0 input

polci0:
pt0st:			; return 0ffh if ready,
			;        000h if not
	in	sts0
	ani	2
	rz
	mvi	a,0ffh
	ret
;
; console #0 input
;
pt0in:			; return character in reg a
	mvi	c,poll
	mvi	e,plci0
	call	xdos		; poll console #0 input
	in	data0		; read character
	ani	7fh		; strip parity bit
	ret
;
; console #0 output
;
pt0out:			; reg c = character to output
	in	sts0
	ani	01h
	jnz	co0rdy
	push	b
	call	pt0wait		; poll console #0 output
	pop	b
co0rdy:
	mov	a,c
	out	data0		; transmit character
	ret
;
; wait for console #0 output ready
;
pt0wait:
	mvi	c,poll
	mvi	e,plco0
	jmp	xdos		; poll console #0 output
;	ret

;
; poll console #0 output
;
polco0:
			; return 0ffh if ready,
			;        000h if not
	in	sts0
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
;
; line printer driver:
;
list:			; list output
	in	lptsts
	ani	01h
	jnz	lptrdy
	push	b
	mvi	c, poll
	mvi	e, pllpt
	call	xdos
	pop	b
lptrdy:
	mov	a,c
	cma
	out	lptport
	ret
;
; poll printer output
;
pollpt:
			; return 0ffh if ready,
			;        000h if not
	in	lptsts
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
; poll console #1 (TTY:) input
;
polci1:
pt1st:
			; return 0ffh if ready,
			;        000h if not
	in	sts1
	ani	2
	rz
	mvi	a,0ffh
	ret
;
; console #1 (TTY:) input
;
pt1in:
			; return character in reg a
	mvi	c,poll
	mvi	e,plci1
	call	xdos		; poll console #1 input
	in	data1		; read character
	ani	7fh		; strip parity bit
	ret
;
; console #1 (TTY:) output
;
pt1out:
	in	sts1
	ani	01h
	jnz	co1rdy
			; reg c = character to output
	push	b
	call	pt1wait
	pop	b
co1rdy:
	mov	a,c
	out	data1		; transmit character
	ret

; wait for console #1 (TTY:) output ready

pt1wait:
	mvi	c,poll
	mvi	e,plco1
	jmp	xdos		; poll console #1 output
;	ret

; poll console #1 (TTY:) output

polco1:
			; return 0ffh if ready,
			;        000h if not
	in	sts1
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
;
;  MP/M 1.0   extended i/o system
;
;
nmbdev	equ	6	; number of devices in poll tbl

polldevice:
			; reg c = device # to be polled
			; return 0ffh if ready,
			;        000h if not
	mov	a,c
	cpi	nmbdev
	jc	devok
	mvi	a,nmbdev; if dev # >= nmbdev,
			; set to nmbdev
devok:
	call	tbljmp	; jump to dev poll code

	dw	pollpt	; poll printer output
	dw	poldsk	; poll disk ready
	dw	polco0	; poll console #0 output
	dw	polco1	; poll console #1 (TTY:) output
	dw	polci0	; poll console #0 input
	dw	polci1	; poll console #1 (TTY:) input
	dw	rtnempty; bad device handler


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
	mvi	a,0ffh
	sta	tickn
	ret

; stop clock

stopclock:
			; will stop flag #1 setting at
			;  system time unit tick
	xra	a
	sta	tickn
	ret

; exit region

exitregion:
			; ei if not preempted
	lda	preemp
	ora	a
	rnz
	ei
	ret

; maximum console number

maxconsole:
	mvi	a,nmbcns
	ret

; system initialization

systeminit:
;	note: this system init assumes that the usarts
;	have been initialized by the coldstart boot

;	setup restart jump vectors
	mvi	a,0c3h
	sta	1*8
	lxi	h,int1hnd
	shld	1*8+1		; jmp int1hnd at restart 1

;	setup interrupt controller & real time clock
	mvi	a,inte
	out	intc		; enable int 0,1,7
	xra	a
	out	icon		; clear int mask
	out	rtc		; enable real time clock
	ret

;
; Idle procedure
;
idle:
	mvi	c,dsptch
	jmp	xdos		; perform a dispatch, this form
				;  of idle must be used in systems
				;  without interrupts, i.e. all polled

;	-or-

;	ei			; simply halt until awaken by an
;	hlt			;  interrupt
;	ret


;  MP/M 1.0   interrupt handlers

flagset	equ	133
dsptch	equ	142

int1hnd:
			; interrupt 1 handler entry point
			;  
			;  location 0008h contains a jmp
			;  to int1hnd.
	push	psw
	mvi	a,2h
	out	rtc	; reset real time clock
	out	revrt	; revert intr cntlr
	lda	slice
	dcr	a	; only service every 16th slice
	sta	slice
	jz	t16ms	; jump if 16ms elapsed
	pop	psw
	ei
	ret

t16ms:
	mvi	a,16
	sta	slice	; reset slice counter
	pop	psw
	shld	svdhl
	pop	h
	shld	svdret
	push	psw
	lxi	h,0
	dad	sp
	shld	svdsp		; save users stk ptr
	lxi	sp,intstk+48	; lcl stk for intr hndl
	push	d
	push	b

	mvi	a,0ffh
	sta	preemp	; set preempted flag

	lda	tickn
	ora	a		; test tickn, indicates
				;  delayed process(es)
	jz	notickn
	mvi	c,flagset
	mvi	e,1
	call	xdos		; set flag #1 each tick
notickn:
	lxi	h,cnt64
	dcr	m		; dec 64 tick cntr
	jnz	not1sec
	mvi	m,64
	mvi	c,flagset
	mvi	e,2
	call	xdos		; set flag #2 @ 1 sec
not1sec:
	xra	a
	sta	preemp	; clear preempted flag
	pop	b
	pop	d
	lhld	svdsp
	sphl			; restore stk ptr
	pop	psw
	lhld	svdret
	push	h
	lhld	svdhl

; the following dispatch call will force round robin
;  scheduling of processes executing at the same priority
;  each 1/64th of a second.
; note: interrupts are not enabled until the dispatcher
;  resumes the next process.  this prevents interrupt
;  over-run of the stacks when stuck or high frequency
;  interrupts are encountered.

	jmp	pdisp		; MP/M dispatch

;
; bios data segment
;
slice:	db	16	; 16 slices = 16ms = 1 tick
cnt64:	db	64	; 64 tick cntr = 1 sec
intstk:	ds	48	; local intrpt stk
svdhl:	dw	0	; saved regs hl during int hndl
svdsp:	dw	0	; saved sp during int hndl
svdret:	dw	0	; saved return during int hndl
tickn:	db	0	; ticking boolean,true = delayed
preemp:	db	0	; preempted boolean
;

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*								*
*	Intel MDS-800 diskette interface routines		*
*								*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

seldsk:	;select disk given by register c
	lxi 	h, 0 
	mov 	a,c
	cpi 	numdisks 
	rnc  		; first, insure good select
	ani 	2 	
	sta 	dbank	; then save it
	lxi 	h,sel$table 
	mvi 	b,0 
	dad 	b 
	mov 	a,m 
	sta 	iof
	mov 	h,b 
	mov 	l,c
	dad 	h 
	dad 	h 
	dad 	h 
	dad 	h	; times 16
	lxi 	d,dpbase 
	dad 	d
	ret

home:	;move to home position
;	treat as track 00 seek
	mvi	c,0
;
settrk:	;set track address given by c
	lxi	h,iot
	mov	m,c
	ret
;
setsec:	;set sector number given by c
	mov	a,c	;sector number to accum
	sta	ios	;store sector number to iopb
	ret
;
setdma:	;set dma address given by regs b,c
	mov	l,c
	mov	h,b
	shld	iod
	ret

sect$tran:		; translate the sector # in <c> if needed
	mov 	h,b 
	mov 	l,c 
	inx 	h  ; in case of no translation
	mov 	a, d 
	ora 	e 
	rz	
	xchg 
	dad 	b	; point to physical sector
	mov 	l,m 
	mvi 	h,0
	ret


read:	;read next disk record (assuming disk/trk/sec/dma set)
	mvi	c,readf	;set to read function
	jmp	setfunc
;
write:	;disk write function
	mvi	c,writf
;
setfunc:
;	set function for next i/o (command in reg-c)
	lxi	h,iof	;io function address
	mov	a,m	;get it to accumulator for masking
	ani	1111$1000b	;remove previous command
	ora	c	;set to new command
	mov	m,a	;replaced in iopb
;	single density drive 1 requires bit 5 on in sector #
;	mask the bit from the current i/o function
	ani	0010$0000b	;mask the disk select bit
	lxi	h,ios		;address the sector select byte
	ora	m		;select proper disk bank
	mov	m,a		;set disk select bit on/off
;
waitio:
	mvi	c,retry	;max retries before perm error
rewait:
;	start the i/o function and wait for completion
	call	intype	;in rtype
	call	inbyte	;clears the controller

	lda	dbank		;set bank flags
	ora	a		;zero if drive 0,1 and nz if 2,3
	mvi	a,iopb and 0ffh	;low address for iopb
	mvi	b,iopb shr 8	;high address for iopb
	jnz	iodr1	;drive bank 1?
	out	ilow		;low address to controller
	mov	a,b
	out	ihigh	;high address
	jmp	wait0		;to wait for complete

iodr1:	;drive bank 1
	out	ilow+10h	;88 for drive bank 10
	mov	a,b
	out	ihigh+10h
wait0:
	push	b		; save retry count
	mvi	c, poll		; function poll
	mvi	e, pldsk	; device is disk
	call	xdos
	pop	b		; restore retry counter in <c>


;	check io completion ok
	call	intype		;must be io complete (00) unlinked
;	00 unlinked i/o complete,    01 linked i/o complete (not used)
;	10 disk status changed       11 (not used)
	cpi	10b		;ready status change?
	jz	wready

;	must be 00 in the accumulator
	ora	a
	jnz	werror		;some other condition, retry

;	check i/o error bits
	call	inbyte
	ral
	jc	wready		;unit not ready
	rar
	ani	11111110b	;any other errors?  (deleted data ok)
	jnz	werror

;	read or write is ok, accumulator contains zero
	ret

poldsk:
	call	instat			; get current controller status
	ani	iordy			; operation complete ?
	rz				; not done
	mvi	a,0ffh			; done flag
	ret				; to xdos


wready:	;not ready, treat as error for now
	call	inbyte		;clear result byte
	jmp	trycount

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
	dcr	c
	jnz	rewait	;for another try

;	cannot recover from error
	mvi	a,1	;error code
	ret

;	intype, inbyte, instat read drive bank 00 or 10
intype:	lda	dbank
	ora	a
	jnz	intyp1	;skip to bank 10
	in	rtype
	ret
intyp1:	in	rtype+10h	;78 for 0,1  88 for 2,3
	ret

inbyte:	lda	dbank
	ora	a
	jnz	inbyt1
	in	rbyte
	ret
inbyt1:	in	rbyte+10h
	ret

instat:	lda	dbank
	ora	a
	jnz	insta1
	in	dstat
	ret
insta1:	in	dstat+10h
	ret



;	data areas (must be in ram)

dbank:	db	0	;disk bank 00 if drive 0,1
			;	   10 if drive 2,3

iopb:			;io parameter block
	db	80h	;normal i/o operation
iof:	db	readf	;io function, initial read
ion:	db	1	;number of sectors to read
iot:	db	2	;track number
ios:	db	1	;sector number
iod:	dw	$-$	;io address


sel$table:
	if	sgl
	db	00h, 30h, 00h, 30h	; drive select bits
	endif
	if	dbl
	db	00h, 10h, 00h, 30h	; drive select bits
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
dpbase	equ	$		;base of disk param blks
dpe0:	dw	xlt0,0000h	;translate table
	dw	0000h,0000h	;scratch area
	dw	dirbuf,dpb0	;dir buff, parm block
	dw	csv0,alv0	;check, alloc vectors
dpe1:	dw	xlt1,0000h	;translate table
	dw	0000h,0000h	;scratch area
	dw	dirbuf,dpb1	;dir buff, parm block
	dw	csv1,alv1	;check, alloc vectors
dpe2:	dw	xlt2,0000h	;translate table
	dw	0000h,0000h	;scratch area
	dw	dirbuf,dpb2	;dir buff, parm block
	dw	csv2,alv2	;check, alloc vectors
dpe3:	dw	xlt3,0000h	;translate table
	dw	0000h,0000h	;scratch area
	dw	dirbuf,dpb3	;dir buff, parm block
	dw	csv3,alv3	;check, alloc vectors
dpb0	equ	$		;disk param block
	endif

	if	asm and dbl
	dw	52		;sec per track
	db	4		;block shift
	db	15		;block mask
	db	1		;extnt mask
	dw	242		;disk size-1
	dw	127		;directory max
	db	192		;alloc0
	db	0		;alloc1
	dw	32		;check size
	dw	2		;offset
xlt0	equ	0		;translate table
dpb1	equ	dpb0
xlt1	equ	xlt0
dpb2	equ	$
	endif

	if	asm
	dw	26		;sec per track
	db	3		;block shift
	db	7		;block mask
	db	0		;extnt mask
	dw	242		;disk size-1
	dw	63		;directory max
	db	192		;alloc0
	db	0		;alloc1
	dw	16		;check size
	dw	2		;offset
	endif

	if	asm and sgl
xlt0	equ	$
	endif

	if	asm and dbl
xlt2	equ	$
	endif

	if	asm
	db	1
	db	7
	db	13
	db	19
	db	25
	db	5
	db	11
	db	17
	db	23
	db	3
	db	9
	db	15
	db	21
	db	2
	db	8
	db	14
	db	20
	db	26
	db	6
	db	12
	db	18
	db	24
	db	4
	db	10
	db	16
	db	22
	endif

	if	asm and sgl
dpb1	equ	dpb0
xlt1	equ	xlt0
dpb2	equ	dpb0
xlt2	equ	xlt0
dpb3	equ	dpb0
xlt3	equ	xlt0
	endif

	if	asm and dbl
dpb3	equ	dpb2
xlt3	equ	xlt2
	endif

	if	asm
begdat	equ	$
dirbuf:	ds	128		;directory access buffer
	endif

	if	asm and sgl
alv0:	ds	31
csv0:	ds	16
alv1:	ds	31
csv1:	ds	16
	endif

	if	asm and dbl
alv0:	ds	31
csv0:	ds	32
alv1:	ds	31
csv1:	ds	32
	endif

	if	asm
alv2:	ds	31
csv2:	ds	16
alv3:	ds	31
csv3:	ds	16
enddat	equ	$
datsiz	equ	$-begdat
	endif

	db	0	; this last db is req'd to
			; ensure that the hex file
			; output includes the entire
			; diskdef

	end

