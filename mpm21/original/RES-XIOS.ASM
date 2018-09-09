	title	'MP/M II V2.0  DSC-2 Basic & Extended I/O Systems'
	cseg
	maclib	diskdef
;
; bios for micro-2 computer
;
;
false	equ	0
true	equ	not false
;
debug	equ	true
ldcmd	equ	true
;
MHz4	equ	true

	if	MHz4
dlycnst	equ	086h
	else
dlycnst	equ	054h
	endif
;
;	org	0000h

;
;	jump vector for individual subroutines
;	jmp	coldstart	;cold start
	jmp	commonbase
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
	jmp	sectran		;sector translate

	jmp	selmemory	; select memory
	jmp	polldevice	; poll device
	jmp	startclock	; start clock
	jmp	stopclock	; stop clock
	jmp	exitregion	; exit region
	jmp	maxconsole	; maximum console number
	jmp	systeminit	; system initialization
	db	0		; force use of internal dispatch @ idle
;	jmp	idle		; idle procedure
;
commonbase:
	 jmp	coldstart
swtuser: jmp	$-$
swtsys:  jmp	$-$
pdisp:   jmp	$-$
xdos:	 jmp	$-$
sysdat:  dw	$-$

coldstart:
warmstart:
	mvi	c,0
	jmp	xdos		; system reset, terminate process
;
;
;I/O handlers
;
;
;  MP/M II V2.0   Console Bios
;
;
nmbcns	equ	3	; number of consoles

poll	equ	131	; XDOS poll function
makeque	equ	134	; XDOS make queue function
readque	equ	137	; XDOS read queue function
writeque equ	139	; XDOS write queue function
xdelay	equ	141	; XDOS delay function
create	equ	144	; XDOS create process function

pllpt	equ	0	; poll printer
plco0	equ	1	; poll console out #0
plco2	equ	2	; poll console out #1
plco3	equ	3	; poll console out #2 (Port 3)
plci3	equ	4	; poll console in #2 (Port 3)
	if	debug
plci0	equ	5	; poll console in #0
	endif

;
const:			; Console Status
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0st	; console #0 status routine
	dw	pt2st	; console #1 (Port 2) status rt
	dw	pt3st	; console #2 (Port 3) status rt

conin:			; Console Input
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0in	; console #0 input
	dw	pt2in	; console #1 (Port 2) input
	dw	pt3in	; console #2 (Port 3) input

conout:			; Console Output
	call	ptbljmp	; compute and jump to hndlr
	dw	pt0out	; console #0 output
	dw	pt2out	; console #1 (Port 2) output
	dw	pt3out	; console #2 (Port 3) output

;
ptbljmp:		; compute and jump to handler
			; d = console #
			; do not destroy d !
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

;
; ASCII Character Equates
;
uline	equ	5fh
rubout	equ	7fh
space	equ	20h
backsp	equ	8h
altrub	equ	uline
;
; Input / Output Port Address Equates
;
data0	equ	40h
sts0	equ	data0+1
cd0	equ	sts0
data1	equ	48h
sts1	equ	data1+1
cd1	equ	sts1
data2	equ	50h
sts2	equ	data2+1
cd2	equ	sts2
data3	equ	58h
sts3	equ	data3+1
cd3	equ	sts3
;
; Poll Console #0 Input
;
	if	debug
polci0:
pt0st:
	if	ldcmd
	lda	pt0cntr
	ora	a
	mvi	a,0
	rnz
	endif

	in	sts0
	ani	2
	rz
	mvi	a,0ffh
	ret
;
pt0in:
	if	ldcmd
	lxi	h,pt0cntr
	mov	a,m
	ora	a
	jz	ldcmd0empty
	dcr	m
	lhld	pt0ptr
	mov	a,m
	inx	h
	shld	pt0ptr
	ret
pt0cntr:
	db	ldcmd0empty-pt0ldcmd
pt0ptr:
	dw	pt0ldcmd
pt0ldcmd:
	db	'tod '
ldcmd0empty:
	endif

	mvi	c,poll
	mvi	e,plci0
	call	xdos
	in	data0
	ani	7fh
	ret
;
	else
pt0st:
			; return 0ffh if ready,
			;        000h if not
	lda	c0inmsgcnt
	ora	a
	rz
	mvi	a,0ffh
	ret
;
; Console #0 Input
;
c0inpd:
	dw	c2inpd	; pl
	db	0	; status
	db	32	; priority
	dw	c0instk+18 ; stkptr
	db	'c0in    '  ; name
	db	0	; console
	db	0ffh	; memseg
	ds	36

c0instk:
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	c0inp	; starting address

c0inq:
	dw	0	; ql
	db	'c0inque ' ; name
	dw	1	; msglen
	dw	4	; nmbmsgs
	ds	8
c0inmsgcnt:
	ds	2	; msgcnt
	ds	4	; buffer

c0inqcb:
	dw	c0inq	; pointer
	dw	ch0in ; msgadr
ch0in:
	db	0

c0inuqcb:
	dw	c0inq	; pointer
	dw	char0in ; msgadr
char0in:
	db	0

c0inp:
	mvi	c,makeque
	lxi	d,c0inq
	call	xdos	; make the c0inq

c0inloop:
	mvi	c,flagwait
	mvi	e,6
	call	xdos	; wait for c0 in intr flag
	mvi	c,writeque
	lxi	d,c0inqcb
	call	xdos	; write c0in queue
	jmp	c0inloop


pt0in:
			; return character in reg A
	mvi	c,readque
	lxi	d,c0inuqcb
	call	xdos		; read from c0 in queue
	lda	char0in		; get character
	ani	7fh		; strip parity bit
	ret
;
	endif
;
; Console #0 Output
;
pt0out:
			; Reg C = character to output
	in	sts0
	ani	01h
	jnz	tx0rdy
	push	b
	mvi	c,poll
	mvi	e,plco0
	call	xdos	; poll console #0 output
	pop	b
tx0rdy:
	mov	a,c
	out	data0
	ret
;
; poll console #0 output
;
polco0:
	in	sts0
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
;
; Line Printer Driver:  TI 810 Serial Printer
;			TTY Model 40
;
initflag:
	db	0	; printer initialization flag

list:			; List Output
pt1out:
			; Reg c = Character to print
	lda	initflag
	ora	a
	jnz	pt1xx
	mvi	a,27h
	out	49h		; TTY Model 40 init
	sta	initflag
pt1xx:
	in	sts1
	ani	01h
	jnz	tx1rdy
	push	b
	mvi	c,poll
	mvi	e,pllpt
	call	xdos		; poll printer output
	pop	b
tx1rdy:
	mov	a,c		; char to register a
	out	data1
	ret
;
; Poll Printer Output
;
pollpt:
			; return 0ffh if ready,
			;        000h if not
	in	sts1
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
; Poll Console #1 (Port 2) Input
;
pt2st:
			; return 0ffh if ready,
			;        000h if not
	lda	c2inmsgcnt
	ora	a
	rz
	mvi	a,0ffh
	ret
;
; Console #1 (Port 2) Input
;
c2inpd:
	dw	0	; pl
	db	0	; status
	db	34	; priority
	dw	c2instk+18 ; stkptr
	db	'c2in    '  ; name
	db	2	; console
	db	0ffh	; memseg
	ds	36

c2instk:
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h
	dw	c2inp	; starting address

c2inq:
	dw	0	; ql
	db	'c2inque ' ; name
	dw	1	; msglen
	dw	4	; nmbmsgs
	ds	8
c2inmsgcnt:
	ds	2	; msgcnt
	ds	4	; buffer

c2inqcb:
	dw	c2inq	; pointer
	dw	ch2in ; msgadr
ch2in:
	db	0

c2inuqcb:
	dw	c2inq	; pointer
	dw	char2in ; msgadr
char2in:
	db	0

c2inp:
	mvi	c,makeque
	lxi	d,c2inq
	call	xdos	; make the c2inq

c2inloop:
	mvi	c,flagwait
	mvi	e,8
	call	xdos	; wait for c2 in intr flag
	mvi	c,writeque
	lxi	d,c2inqcb
	call	xdos	; write c2in queue
	jmp	c2inloop


pt2in:
			; return character in reg A
	mvi	c,readque
	lxi	d,c2inuqcb
	call	xdos		; read from c2 in queue
	lda	char2in		; get character
	ani	7fh		; strip parity bit
	ret
;
; Console #1 (Port 2) Output
;
pt2out:
			; Reg C = character to output
	in	sts2
	ani	01h
	jnz	tx2rdy
	push	b
	mvi	c,poll
	mvi	e,plco2
	call	xdos	; poll console #1 output
	pop	b
tx2rdy:
	mov	a,c
	out	data2
	ret
;
; poll console #1 output
;
polco2:
	in	sts2
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
; Poll Console #2 (Port 3) Input
;
polci3:
pt3st:			; return 0ffh if ready,
			;        000h if not
	in	sts3
	ani	2
	rz
	mvi	a,0ffh
	ret
;
; Console #2 (Port 3) Input
;
pt3in:			; return character in reg A
	mvi	c,poll
	mvi	e,plci3
	call	xdos		; poll console #0 input
	in	data3		; read character
	ani	7fh		; strip parity bit
	ret
;
; Console #2 (Port 3) Output
;
pt3out:			; Reg C = character to output
	in	sts3
	ani	01h
	jnz	tx3rdy
	push	b
	mvi	c,poll
	mvi	e,plco3
	call	xdos		; poll console #2 (Port 3) output
	pop	b
tx3rdy:
	mov	a,c
	out	data3		; transmit character
	ret
;
; Poll Console #2 (Port 3) Output
;
polco3:
			; return 0ffh if ready,
			;        000h if not
	in	sts3
	ani	01h
	rz
	mvi	a,0ffh
	ret
;
;
;  MP/M II V2.0   Xios
;
;
polldevice:
			; Reg C = device # to be polled
			; return 0ffh if ready,
			;        000h if not
	mov	a,c
	cpi	nmbdev
	jc	devok
	mvi	a,nmbdev; if dev # >= nmbdev,
			; set to nmbdev
devok:
	call	tbljmp	; jump to dev poll code

devtbl:
	dw	pollpt	; poll printer output
	dw	polco0	; poll console #0 output
	dw	polco2	; poll console #1 output
	dw	polco3	; poll console #2 output
	dw	polci3	; poll console #2 input
	if	debug
	dw	polci0	; poll console #0 input
	endif
nmbdev	equ	($-devtbl)/2	; number of devices to poll
	dw	rtnempty; bad device handler
;

; Select / Protect Memory
;
selmemory:
			; Reg BC = adr of mem descriptor
			; BC ->  base   1 byte,
			;        size   1 byte,
			;        attrib 1 byte,
			;        bank   1 byte.
; this hardware does not have memory protection or
;  bank switching
	ret
;
; Start Clock
;
startclock:
			; will cause flag #1 to be set
			;  at each system time unit tick
	mvi	a,0ffh
	sta	tickn
	ret
;
; Stop Clock
;
stopclock:
			; will stop flag #1 setting at
			;  system time unit tick
	xra	a
	sta	tickn
	ret
;
; Exit Region
;
exitregion:
			; EI if not preempted or in dispatcher
	lda	preemp
	ora	a
	rnz
	ei
	ret
;
; Maximum Console Number
;
maxconsole:
	mvi	a,nmbcns
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
	mvi	a,0c3h
	sta	0038h
	lxi	h,inthnd
	shld	0039h		; JMP INTHND at 0038H

	mvi	c,create
	if	debug
	lxi	d,c2inpd
	else
	lxi	d,c0inpd
	endif
	call	xdos

	lda	intmsk
	out	60h		; init interrupt mask

	db	0edh,056h	; Interrupt Mode 1
				; ** Z80 Instruction **
	ei
	call	home
	mvi	c,flagwait
	mvi	e,5
	jmp	xdos		; clear first disk interrupt
;	ret			;   & return

;
; Idle procedure
;
;idle:
;	ret

;	-or-

;	ei
;	hlt
;	ret			; for full interrupt system

;
;  MP/M II V2.0   Interrupt Handlers
;

flagwait equ	132
flagset	equ	133
dsptch	equ	142

inthnd:
			; Interrupt handler entry point
			;  All interrupts gen a RST 7
			;  Location 0038H contains a jmp
			;  to INTHND.
	shld	svdhl
	pop	h
	shld	svdret
	push	psw
	lxi	h,0
	dad	sp
	shld	svdsp		; save users stk ptr
	lxi	sp,lstintstk	; lcl stk for intr hndl
	push	d
	push	b

	mvi	a,0ffh
	sta	preemp	; set preempted flag

	in	60h		; read interrupt mask
	ani	01000000b	; test & jump if clk int
	jnz	clk60hz
;
	in	stat		; read disk status port
	ani	08h
	jnz	diskintr

	if	not debug
	in	sts0
	ani	2
	jnz	con0in
	endif

	in	sts2
	ani	2
	jnz	con2in

;	...			; test/handle other ints
;
	jmp	intdone

diskintr:
	xra	a
	out	cmd1		; reset disk interrupt
	mvi	e,5
	jmp	concmn		; set flag #5

	if	not debug
con0in:
	in	data0
	sta	ch0in
	mvi	e,6
	jmp	concmn		; set flag #6
	endif

con2in:
	in	data2
	sta	ch2in
	mvi	e,8
;	jmp	concmn		; set flag #8

concmn:
	mvi	c,flagset
	call	xdos
	jmp	intdone

clk60hz:
				; 60 Hz clock interrupt
	lda	tickn
	ora	a		; test tickn, indicates
				;  delayed process(es)
	jz	notickn
	mvi	c,flagset
	mvi	e,1
	call	xdos		; set flag #1 each tick
notickn:
	lxi	h,cnt60
	dcr	m		; dec 60 tick cntr
	jnz	not1sec
	mvi	m,60
	mvi	c,flagset
	mvi	e,2
	call	xdos		; set flag #2 @ 1 sec
not1sec:
	xra	a
	out	60h
	lda	intmsk
	out	60h		; ack clock interrupt
;	jmp	intdone
;
;	...
; Other interrupt handlers
;	...
;
intdone:
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
; The following dispatch call will force round robin
;  scheduling of processes executing at the same priority
;  each 1/60th of a second.
; Note: Interrupts are not enabled until the dispatcher
;  resumes the next process.  This prevents interrupt
;  over-run of the stacks when stuck or high frequency
;  interrupts are encountered.
	jmp	pdisp		; MP/M dispatch
;
;
;	Disk I/O Drivers
;
; Disk Port Equates
;
cmd1	equ	80h
stat	equ	80h
haddr	equ	81h
laddr	equ	82h
cmd2	equ	83h
;
;
home:	;move to the track o0 position of current drive
	call	headload
; h,l point to word with track for selected disk
homel:
	mvi	m,00	;set current track ptr back to 0
	in	stat	;read fdc status
	ani	4	;test track 0 bit
	rz		;return if at 0
	stc		;direction=out
	call	step	;step one track
	jmp	homel	;loop
;
seldsk:
	;drive number in c
	lxi	h,0	;0000 in hl produces select error
	mov	a,c	;a is disk number 0 ... ndisks-1
	cpi	ndisks	;less than ndisks?
	rnc		;return with HL = 0000 if not
;make sure dummy is 0 (for use in double add to h,l)
	xra	a
	sta	dummy
	mov	a,c
	ani	07h	;get only disk select bits
	sta	diskno
	mov	c,a
;set up the second command port
	lda	port
	ani	0f0h	;clear out old disk select bits
	ora	c	;put in new disk select bits
	ori	08h	; force double density
	sta	port
;	proper disk number, return dpb element address
	mov	l,c
	dad	h	;*2
	dad	h	;*4
	dad	h	;*8
	dad	h	;*16
	lxi	d,dpbase
	dad	d	;HL=.dpb
	shld	tran	;translate table base
	ret
;
;
;
settrk:	;set track given by register c
	call	headload
;h,l reference correct track indicator according to
;selected disk
	mov	a,c	;desired track
	cmp	m
	rz		;we are already on the track
settkx:
	call	step	;step track-carry has direction
			;step will update trk indicator
	mov	a,c
	cmp	m	;are we where we want to be
	jnz	settkx	;not yet
;have stepped enough
seekrt:
;need 10 msec delay for final step time and head settle time
	mvi	a,20d
;	call	delay
;	ret		;end of settrk routine

;
delay:	;delay for c[A] X .5 milliseconds
	push	b
delay1:
	mvi	c,dlycnst ;constant adjusted to .5 ms loop
delay2:
	dcr	c
	jnz	delay2
	dcr	a
	jnz	delay1
	pop	b
	ret		;end of delay routine

;
setsec:	;set sector given by register c
	inr	c
	mov	a,c
	sta	sector
	ret
;
sectran:
	;sector number in c
	;translate logical to physical sector
	lhld	tran	;hl=..translate
	mov	e,m	;E=low(.translate)
	inx	h
	mov	d,m	;DE=.translate
	mov	a,e	;zero?
	ora	d	;00 or 00 = 00
	mvi	h,0
	mov	l,c	;HL = untranslated sector
	rz		;skip if so
	xchg
	mov	b,d	;BC=00ss
	dad	b	;HL=.translate(sector)
	mov	l,m
	mov	h,d	;HL=translate(sector)
	ret
;
setdma:	;set dma address given by registers b and c
	mov	l,c	;low order address
	mov	h,b	;high order address
	shld	dmaad	;save the address
	ret
;
;
read:	;perform read operation.
	;this is similar to write, so set up read
	; command and use common code in write
	mvi	b,040h	;set read flag
	jmp	waitio	;to perform the actual I/O
;
write:	;perform a write operation
	mvi	b,080h	;set write command
;
waitio:
;enter here from read and write to perform the actual
; I/O  operation.  return a 00h in register a if the
; operation completes properly, and 01h if an error
; occurs during the read or write
;
;in this case, the disk number saved in 'diskno' 
;			the track number in 'track' 
;			the sector number in 'sector' 
;			the dma address in 'dmaad' 
			;b still has r/w flag
	mvi	a,10d	;set error count
	sta	errors	;retry some failures 10 times
			;before giving up
tryagn:
	push	b
	call	headload
;h,l point to track byte for selected disk
	pop	b
	mov	c,m
; decide whether to allow disk write precompenstation
	mvi	a,39d	;inhibit precomp on trks 0-39
	cmp	c
	jc	allowit
;inhibit precomp
	mvi	a,10h
	ora	b
	mov	b,a	;goes out on the same port
			; as read/write
allowit:
	lhld	dmaad	;get buffer address
	push	b	;b has r/w code   c has track
	dcx	h	;save and replace 3 bytes below
			;buf with trk,sctr,adr mark
	mov	e,m
;figure correct address mark

	lda	port
	ani	08h
	mvi	a,0fbh
	jz	sin
	ani	0fh	;was double 
			;0bh is double density 
			;0fbh is single density
sin:
	mov	m,a
;fill in sector
	dcx	h
	mov	d,m
	lda	sector	;note that invalid sector number
			;will result in head unloaded
			;error, so dont check
	mov	m,a
;fill in track
	dcx	h
	pop	b
	mov	a,c
	mov	c,m
	mov	m,a
	mov	a,h	;set up fdc dma address
	out	haddr	;high byte
	mov	a,l
	out	laddr	;low byte
	mov	a,b	;get r/w flag
	out	cmd1	;start disk read/write

rwwait:
	push	b
	push	d
	push	h

	mvi	c,flagwait
	mvi	e,5
	call	xdos		; wait for disk intrpt flag

	pop	h
	pop	d
	pop	b
	mov	m,c	;restore 3 bytes below buf
	inx	h
	mov	m,d
	inx	h
	mov	m,e
	in	stat	;test for errors
	ani	0f0h
	rz		;a will be 0 if no errors

; error from disk
	push	psw	;save error condition
;check for 10 errors
	lxi	h,errors
	dcr	m
	jnz	redo	;not ten yet.  do a retry
;we have too many errors. print out hex number for last
;received error type. cpm will print perm error message.
	pop	psw	;get code
;set error return for operating system
	mvi	a,1
	ret
redo:
;b still has read/write flag
	pop	psw	;get error code
	ani	0e0h	;retry if not track error
	jnz	tryagn	;
;was a track error so need to reseek
	push	b	;save	read/write indicator
;figure out the desired track
	lxi	d,track
	lhld	diskno	;selected disk
	dad	d	;point to correct trk indicator
	mov	a,m	;desired track
	push	psw	;save it
	call	home
	pop	psw
	mov	c,a
	call	settrk
	pop	b	;get read/write indicator
	jmp	tryagn
;
;
;
step:			;step head out towards zero
			;if carry is set; else
			;step in
; h,l point to correct track indicator word
	jc	outx
	inr	m	;increment current track byte
	mvi	a,04h	;set direction = in
dostep:
	ori	2
	out	cmd1	;pulse step bit
	ani	0fdh
	out	cmd1	;turn off pulse
;the fdc-2 had a stepp ready line. the fdc-3 relies on
;software time out
	mvi	a,16d	;delay 8 ms
	jmp	delay
;	ret
;
outx:
	dcr	m	;update track byte
	xra	a
	jmp	dostep
;
headload:
;select and load the head on the correct drive
	lxi	h,prtout	;old slect info
	mov	b,m
	dcx	h	;new select info
	mov	a,m
	inx	h
	mov	m,a

	ori	10h	; enable interrupt

	out	cmd2	;select the drive
	ani	0efh
;set up h.l to point to track byte for selected disk
	lxi	d,track
	lhld	diskno
	dad	d
;now check for needing a 35 ms delay
;if we have changed drives or if the head is unloaded
;we need to wait 35 ms for head settle
	cmp	b	;are we on the same drive
	jnz	needdly
;we are on the same drive
;is the head loaded?
	in	stat
	ani	80h
	rz		;already loaded
needdly:
	xra	a
	out	cmd1	;load the head
	mvi	a,70d
	jmp	delay
;	ret

;
; BIOS Data Segment
;
cnt60:	db	60	; 60 tick cntr = 1 sec
intstk:			; local intrpt stk
	dw	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	dw	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
lstintstk:
svdhl:	dw	0	; saved Regs HL during int hndl
svdsp:	dw	0	; saved SP during int hndl
svdret:	dw	0	; saved return during int hndl
tickn:	db	0	; ticking boolean,true = delayed
	if	debug
intmsk:	db	44h	; intrpt msk, enables clk intrpt, & con2
	else
intmsk:	db	54h	; intrpt msk, enables clk intrpt, & con0/2
	endif
preemp:	db	0	; preempted boolean
;
scrat:			; start of scratch area
track:	db	0	; current trk on drive 0
trak1:	db	0	; current trk on drive 1
trak2:	db	0	
trak3:	db	0
sector:	db	0	; currently selected sctr
dmaad:	dw	0	; current dma address
diskno:	db	0	; current disk number
dummy:	db	0	; must be 0 for dbl add
errors:	db	0
port:	db	0
prtout:	db	0
dnsty:	db	0
;
	disks	2
bpb	equ	2*1024	;bytes per block
rpb	equ	bpb/128	;records per block
maxb	equ	255	;max block number
	diskdef	0,1,58,,bpb,maxb+1,128,128,2,0
	diskdef	1,0
;
tran:	ds	2
;
	endef

	db	0	;force out last byte in hex file

	end

