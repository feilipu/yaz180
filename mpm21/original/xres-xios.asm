	title	'MP/M II V2.0  DSC-2 Basic & Extended I/O Systems'
	cseg
	maclib	diskdef
;
; bios for micro-2 computer
;
;
DEFC false  =  0 
DEFC true  =  not 
;
DEFC debug  =  true 
DEFC ldcmd  =  true 
;
DEFC MHz4  =  true 

	if	MHz4
DEFC dlycnst  =  086h 
	else
DEFC dlycnst  =  054h 
	endif
;
;	org	0000h

;
;	jump vector for individual subroutines
;	jmp	coldstart	;cold start
	JP	commonbase
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
	JP	sectran		;sector translate

	JP	selmemory	; select memory
	JP	polldevice	; poll device
	JP	startclock	; start clock
	JP	stopclock	; stop clock
	JP	exitregion	; exit region
	JP	maxconsole	; maximum console number
	JP	systeminit	; system initialization
	DEFM	0		; force use of internal dispatch 0 idle
;	jmp	idle		; idle procedure
;
commonbase:
	 JP	coldstart
swtuser: JP	$-$
swtsys:  JP	$-$
pdisp:   JP	$-$
xdos:	 JP	$-$
sysdat:  DEFW	$-$

coldstart:
warmstart:
	LD 	c,0
	JP	xdos		; system reset, terminate process
;
;
;I/O handlers
;
;
;  MP/M II V2.0   Console Bios
;
;
DEFC nmbcns  =  3 ; number of consoles

DEFC poll  =  131 ; XDOS poll function
DEFC makeque  =  134 ; XDOS make queue function
DEFC readque  =  137 ; XDOS read queue function
DEFC writeque  =  139 ; XDOS write queue function
DEFC xdelay  =  141 ; XDOS delay function
DEFC create  =  144 ; XDOS create process function

DEFC pllpt  =  0 ; poll printer
DEFC plco0  =  1 ; poll console out #0
DEFC plco2  =  2 ; poll console out #1
DEFC plco3  =  3 ; poll console out #2 (Port 3)
DEFC plci3  =  4 ; poll console in #2 (Port 3)
	if	debug
DEFC plci0  =  5 ; poll console in #0
	endif

;
const:			; Console Status
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0st	; console #0 status routine
	DEFW	pt2st	; console #1 (Port 2) status rt
	DEFW	pt3st	; console #2 (Port 3) status rt

conin:			; Console Input
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0in	; console #0 input
	DEFW	pt2in	; console #1 (Port 2) input
	DEFW	pt3in	; console #2 (Port 3) input

conout:			; Console Output
	call	ptbljmp	; compute and jump to hndlr
	DEFW	pt0out	; console #0 output
	DEFW	pt2out	; console #1 (Port 2) output
	DEFW	pt3out	; console #2 (Port 3) output

;
ptbljmp:		; compute and jump to handler
			; d = console #
			; do not destroy d !
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

;
; ASCII Character Equates
;
DEFC uline  =  5fh 
DEFC rubout  =  7fh 
DEFC space  =  20h 
DEFC backsp  =  8h 
DEFC altrub  =  uline 
;
; Input / Output Port Address Equates
;
DEFC data0  =  40h 
DEFC sts0  =  data0+1 
DEFC cd0  =  sts0 
DEFC data1  =  48h 
DEFC sts1  =  data1+1 
DEFC cd1  =  sts1 
DEFC data2  =  50h 
DEFC sts2  =  data2+1 
DEFC cd2  =  sts2 
DEFC data3  =  58h 
DEFC sts3  =  data3+1 
DEFC cd3  =  sts3 
;
; Poll Console #0 Input
;
	if	debug
polci0:
pt0st:
	if	ldcmd
	LD	A,(pt0cntr)
	OR	a
	LD 	a,0
	RET	NZ
	endif

	IN	A,(sts0)
	AND	2
	RET	Z
	LD 	a,0ffh
	ret
;
pt0in:
	if	ldcmd
	LD	HL,pt0cntr
	LD 	a,(HL)
	OR	a
	JP	Z,ldcmd0empty
	DEC	(HL)
	LD	HL,(pt0ptr)
	LD 	a,(HL)
	INC	HL
	LD	(pt0ptr),HL
	ret
pt0cntr:
	DEFM	ldcmd0empty-pt0ldcmd
pt0ptr:
	DEFW	pt0ldcmd
pt0ldcmd:
	DEFM	"tod "
ldcmd0empty:
	endif

	LD 	c,poll
	LD 	e,plci0
	call	xdos
	IN	A,(data0)
	AND	7fh
	ret
;
	else
pt0st:
			; return 0ffh if ready,
			;        000h if not
	LD	A,(c0inmsgcnt)
	OR	a
	RET	Z
	LD 	a,0ffh
	ret
;
; Console #0 Input
;
c0inpd:
	DEFW	c2inpd	; pl
	DEFM	0	; status
	DEFM	32	; priority
	DEFW	c0instk+18 ; stkptr
	DEFM	"c0in    "  ; name
	DEFM	0	; console
	DEFM	0ffh	; memseg
	DEFS	36

c0instk:
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	c0inp	; starting address

c0inq:
	DEFW	0	; ql
	DEFM	"c0inque " ; name
	DEFW	1	; msglen
	DEFW	4	; nmbmsgs
	DEFS	8
c0inmsgcnt:
	DEFS	2	; msgcnt
	DEFS	4	; buffer

c0inqcb:
	DEFW	c0inq	; pointer
	DEFW	ch0in ; msgadr
ch0in:
	DEFM	0

c0inuqcb:
	DEFW	c0inq	; pointer
	DEFW	char0in ; msgadr
char0in:
	DEFM	0

c0inp:
	LD 	c,makeque
	LD	DE,c0inq
	call	xdos	; make the c0inq

c0inloop:
	LD 	c,flagwait
	LD 	e,6
	call	xdos	; wait for c0 in intr flag
	LD 	c,writeque
	LD	DE,c0inqcb
	call	xdos	; write c0in queue
	JP	c0inloop


pt0in:
			; return character in reg A
	LD 	c,readque
	LD	DE,c0inuqcb
	call	xdos		; read from c0 in queue
	LD	A,(char0in)		; get character
	AND	7fh		; strip parity bit
	ret
;
	endif
;
; Console #0 Output
;
pt0out:
			; Reg C = character to output
	IN	A,(sts0)
	AND	01h
	JP	NZ,tx0rdy
	PUSH	BC
	LD 	c,poll
	LD 	e,plco0
	call	xdos	; poll console #0 output
	POP	BC
tx0rdy:
	LD 	a,c
	OUT	(data0),A
	ret
;
; poll console #0 output
;
polco0:
	IN	A,(sts0)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
;
; Line Printer Driver:  TI 810 Serial Printer
;			TTY Model 40
;
initflag:
	DEFM	0	; printer initialization flag

list:			; List Output
pt1out:
			; Reg c = Character to print
	LD	A,(initflag)
	OR	a
	JP	NZ,pt1xx
	LD 	a,27h
	OUT	(49h),A		; TTY Model 40 init
	LD	(initflag),A
pt1xx:
	IN	A,(sts1)
	AND	01h
	JP	NZ,tx1rdy
	PUSH	BC
	LD 	c,poll
	LD 	e,pllpt
	call	xdos		; poll printer output
	POP	BC
tx1rdy:
	LD 	a,c		; char to register a
	OUT	(data1),A
	ret
;
; Poll Printer Output
;
pollpt:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts1)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
; Poll Console #1 (Port 2) Input
;
pt2st:
			; return 0ffh if ready,
			;        000h if not
	LD	A,(c2inmsgcnt)
	OR	a
	RET	Z
	LD 	a,0ffh
	ret
;
; Console #1 (Port 2) Input
;
c2inpd:
	DEFW	0	; pl
	DEFM	0	; status
	DEFM	34	; priority
	DEFW	c2instk+18 ; stkptr
	DEFM	"c2in    "  ; name
	DEFM	2	; console
	DEFM	0ffh	; memseg
	DEFS	36

c2instk:
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h
	DEFW	c2inp	; starting address

c2inq:
	DEFW	0	; ql
	DEFM	"c2inque " ; name
	DEFW	1	; msglen
	DEFW	4	; nmbmsgs
	DEFS	8
c2inmsgcnt:
	DEFS	2	; msgcnt
	DEFS	4	; buffer

c2inqcb:
	DEFW	c2inq	; pointer
	DEFW	ch2in ; msgadr
ch2in:
	DEFM	0

c2inuqcb:
	DEFW	c2inq	; pointer
	DEFW	char2in ; msgadr
char2in:
	DEFM	0

c2inp:
	LD 	c,makeque
	LD	DE,c2inq
	call	xdos	; make the c2inq

c2inloop:
	LD 	c,flagwait
	LD 	e,8
	call	xdos	; wait for c2 in intr flag
	LD 	c,writeque
	LD	DE,c2inqcb
	call	xdos	; write c2in queue
	JP	c2inloop


pt2in:
			; return character in reg A
	LD 	c,readque
	LD	DE,c2inuqcb
	call	xdos		; read from c2 in queue
	LD	A,(char2in)		; get character
	AND	7fh		; strip parity bit
	ret
;
; Console #1 (Port 2) Output
;
pt2out:
			; Reg C = character to output
	IN	A,(sts2)
	AND	01h
	JP	NZ,tx2rdy
	PUSH	BC
	LD 	c,poll
	LD 	e,plco2
	call	xdos	; poll console #1 output
	POP	BC
tx2rdy:
	LD 	a,c
	OUT	(data2),A
	ret
;
; poll console #1 output
;
polco2:
	IN	A,(sts2)
	AND	01h
	RET	Z
	LD 	a,0ffh
	ret
;
; Poll Console #2 (Port 3) Input
;
polci3:
pt3st:			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts3)
	AND	2
	RET	Z
	LD 	a,0ffh
	ret
;
; Console #2 (Port 3) Input
;
pt3in:			; return character in reg A
	LD 	c,poll
	LD 	e,plci3
	call	xdos		; poll console #0 input
	IN	A,(data3)		; read character
	AND	7fh		; strip parity bit
	ret
;
; Console #2 (Port 3) Output
;
pt3out:			; Reg C = character to output
	IN	A,(sts3)
	AND	01h
	JP	NZ,tx3rdy
	PUSH	BC
	LD 	c,poll
	LD 	e,plco3
	call	xdos		; poll console #2 (Port 3) output
	POP	BC
tx3rdy:
	LD 	a,c
	OUT	(data3),A		; transmit character
	ret
;
; Poll Console #2 (Port 3) Output
;
polco3:
			; return 0ffh if ready,
			;        000h if not
	IN	A,(sts3)
	AND	01h
	RET	Z
	LD 	a,0ffh
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
	LD 	a,c
	CP	nmbdev
	JP	C,devok
	LD 	a,nmbdev; if dev # >= nmbdev,
			; set to nmbdev
devok:
	call	tbljmp	; jump to dev poll code

devtbl:
	DEFW	pollpt	; poll printer output
	DEFW	polco0	; poll console #0 output
	DEFW	polco2	; poll console #1 output
	DEFW	polco3	; poll console #2 output
	DEFW	polci3	; poll console #2 input
	if	debug
	DEFW	polci0	; poll console #0 input
	endif
DEFC nmbdev  =  ($-devtbl)/2 ; number of devices to poll
	DEFW	rtnempty; bad device handler
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
	LD 	a,0ffh
	LD	(tickn),A
	ret
;
; Stop Clock
;
stopclock:
			; will stop flag #1 setting at
			;  system time unit tick
	XOR	a
	LD	(tickn),A
	ret
;
; Exit Region
;
exitregion:
			; EI if not preempted or in dispatcher
	LD	A,(preemp)
	OR	a
	RET	NZ
	ei
	ret
;
; Maximum Console Number
;
maxconsole:
	LD 	a,nmbcns
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
	LD 	a,0c3h
	LD	(0038h),A
	LD	HL,inthnd
	LD	(0039h),HL		; JMP INTHND at 0038H

	LD 	c,create
	if	debug
	LD	DE,c2inpd
	else
	LD	DE,c0inpd
	endif
	call	xdos

	LD	A,(intmsk)
	OUT	(60h),A		; init interrupt mask

	DEFM	0edh,056h	; Interrupt Mode 1
				; ** Z80 Instruction **
	ei
	call	home
	LD 	c,flagwait
	LD 	e,5
	JP	xdos		; clear first disk interrupt
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

DEFC flagwait  =  132 
DEFC flagset  =  133 
DEFC dsptch  =  142 

inthnd:
			; Interrupt handler entry point
			;  All interrupts gen a RST 7
			;  Location 0038H contains a jmp
			;  to INTHND.
	LD	(svdhl),HL
	POP	HL
	LD	(svdret),HL
	PUSH	AF
	LD	HL,0
	ADD	HL,sp
	LD	(svdsp),HL		; save users stk ptr
	LD	sp,lstintstk	; lcl stk for intr hndl
	PUSH	DE
	PUSH	BC

	LD 	a,0ffh
	LD	(preemp),A	; set preempted flag

	IN	A,(60h)		; read interrupt mask
	AND	01000000b	; test & jump if clk int
	JP	NZ,clk60hz
;
	IN	A,(stat)		; read disk status port
	AND	08h
	JP	NZ,diskintr

	if	not debug
	IN	A,(sts0)
	AND	2
	JP	NZ,con0in
	endif

	IN	A,(sts2)
	AND	2
	JP	NZ,con2in

;	...			; test/handle other ints
;
	JP	intdone

diskintr:
	XOR	a
	OUT	(cmd1),A		; reset disk interrupt
	LD 	e,5
	JP	concmn		; set flag #5

	if	not debug
con0in:
	IN	A,(data0)
	LD	(ch0in),A
	LD 	e,6
	JP	concmn		; set flag #6
	endif

con2in:
	IN	A,(data2)
	LD	(ch2in),A
	LD 	e,8
;	jmp	concmn		; set flag #8

concmn:
	LD 	c,flagset
	call	xdos
	JP	intdone

clk60hz:
				; 60 Hz clock interrupt
	LD	A,(tickn)
	OR	a		; test tickn, indicates
				;  delayed process(es)
	JP	Z,notickn
	LD 	c,flagset
	LD 	e,1
	call	xdos		; set flag #1 each tick
notickn:
	LD	HL,cnt60
	DEC	(HL)		; dec 60 tick cntr
	JP	NZ,not1sec
	LD 	(HL),60
	LD 	c,flagset
	LD 	e,2
	call	xdos		; set flag #2 @ 1 sec
not1sec:
	XOR	a
	OUT	(60h),A
	LD	A,(intmsk)
	OUT	(60h),A		; ack clock interrupt
;	jmp	intdone
;
;	...
; Other interrupt handlers
;	...
;
intdone:
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
; The following dispatch call will force round robin
;  scheduling of processes executing at the same priority
;  each 1/60th of a second.
; Note: Interrupts are not enabled until the dispatcher
;  resumes the next process.  This prevents interrupt
;  over-run of the stacks when stuck or high frequency
;  interrupts are encountered.
	JP	pdisp		; MP/M dispatch
;
;
;	Disk I/O Drivers
;
; Disk Port Equates
;
DEFC cmd1  =  80h 
DEFC stat  =  80h 
DEFC haddr  =  81h 
DEFC laddr  =  82h 
DEFC cmd2  =  83h 
;
;
home:	;move to the track o0 position of current drive
	call	headload
; h,l point to word with track for selected disk
homel:
	LD 	(HL),00	;set current track ptr back to 0
	IN	A,(stat)	;read fdc status
	AND	4	;test track 0 bit
	RET	Z		;return if at 0
	SCF		;direction=out
	call	step	;step one track
	JP	homel	;loop
;
seldsk:
	;drive number in c
	LD	HL,0	;0000 in hl produces select error
	LD 	a,c	;a is disk number 0 ... ndisks-1
	CP	ndisks	;less than ndisks?
	RET	NC		;return with HL = 0000 if not
;make sure dummy is 0 (for use in double add to h,l)
	XOR	a
	LD	(dummy),A
	LD 	a,c
	AND	07h	;get only disk select bits
	LD	(diskno),A
	LD 	c,a
;set up the second command port
	LD	A,(port)
	AND	0f0h	;clear out old disk select bits
	OR	c	;put in new disk select bits
	OR	08h	; force double density
	LD	(port),A
;	proper disk number, return dpb element address
	LD 	l,c
	ADD	HL,HL	;*2
	ADD	HL,HL	;*4
	ADD	HL,HL	;*8
	ADD	HL,HL	;*16
	LD	DE,dpbase
	ADD	HL,DE	;HL=.dpb
	LD	(tran),HL	;translate table base
	ret
;
;
;
settrk:	;set track given by register c
	call	headload
;h,l reference correct track indicator according to
;selected disk
	LD 	a,c	;desired track
	CP	(HL)
	RET	Z		;we are already on the track
settkx:
	call	step	;step track-carry has direction
			;step will update trk indicator
	LD 	a,c
	CP	(HL)	;are we where we want to be
	JP	NZ,settkx	;not yet
;have stepped enough
seekrt:
;need 10 msec delay for final step time and head settle time
	LD 	a,20d
;	call	delay
;	ret		;end of settrk routine

;
delay:	;delay for c[A] X .5 milliseconds
	PUSH	BC
delay1:
	LD 	c,dlycnst ;constant adjusted to .5 ms loop
delay2:
	DEC	c
	JP	NZ,delay2
	DEC	a
	JP	NZ,delay1
	POP	BC
	ret		;end of delay routine

;
setsec:	;set sector given by register c
	INC	c
	LD 	a,c
	LD	(sector),A
	ret
;
sectran:
	;sector number in c
	;translate logical to physical sector
	LD	HL,(tran)	;hl=..translate
	LD 	e,(HL)	;E=low(.translate)
	INC	HL
	LD 	d,(HL)	;DE=.translate
	LD 	a,e	;zero?
	OR	d	;00 or 00 = 00
	LD 	h,0
	LD 	l,c	;HL = untranslated sector
	RET	Z		;skip if so
	EX	DE,HL
	LD 	b,d	;BC=00ss
	ADD	HL,BC	;HL=.translate(sector)
	LD 	l,(HL)
	LD 	h,d	;HL=translate(sector)
	ret
;
setdma:	;set dma address given by registers b and c
	LD 	l,c	;low order address
	LD 	h,b	;high order address
	LD	(dmaad),HL	;save the address
	ret
;
;
read:	;perform read operation.
	;this is similar to write, so set up read
	; command and use common code in write
	LD 	b,040h	;set read flag
	JP	waitio	;to perform the actual I/O
;
write:	;perform a write operation
	LD 	b,080h	;set write command
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
	LD 	a,10d	;set error count
	LD	(errors),A	;retry some failures 10 times
			;before giving up
tryagn:
	PUSH	BC
	call	headload
;h,l point to track byte for selected disk
	POP	BC
	LD 	c,(HL)
; decide whether to allow disk write precompenstation
	LD 	a,39d	;inhibit precomp on trks 0-39
	CP	c
	JP	C,allowit
;inhibit precomp
	LD 	a,10h
	OR	b
	LD 	b,a	;goes out on the same port
			; as read/write
allowit:
	LD	HL,(dmaad)	;get buffer address
	PUSH	BC	;b has r/w code   c has track
	DEC	HL	;save and replace 3 bytes below
			;buf with trk,sctr,adr mark
	LD 	e,(HL)
;figure correct address mark

	LD	A,(port)
	AND	08h
	LD 	a,0fbh
	JP	Z,sin
	AND	0fh	;was double 
			;0bh is double density 
			;0fbh is single density
sin:
	LD 	(HL),a
;fill in sector
	DEC	HL
	LD 	d,(HL)
	LD	A,(sector)	;note that invalid sector number
			;will result in head unloaded
			;error, so dont check
	LD 	(HL),a
;fill in track
	DEC	HL
	POP	BC
	LD 	a,c
	LD 	c,(HL)
	LD 	(HL),a
	LD 	a,h	;set up fdc dma address
	OUT	(haddr),A	;high byte
	LD 	a,l
	OUT	(laddr),A	;low byte
	LD 	a,b	;get r/w flag
	OUT	(cmd1),A	;start disk read/write

rwwait:
	PUSH	BC
	PUSH	DE
	PUSH	HL

	LD 	c,flagwait
	LD 	e,5
	call	xdos		; wait for disk intrpt flag

	POP	HL
	POP	DE
	POP	BC
	LD 	(HL),c	;restore 3 bytes below buf
	INC	HL
	LD 	(HL),d
	INC	HL
	LD 	(HL),e
	IN	A,(stat)	;test for errors
	AND	0f0h
	RET	Z		;a will be 0 if no errors

; error from disk
	PUSH	AF	;save error condition
;check for 10 errors
	LD	HL,errors
	DEC	(HL)
	JP	NZ,redo	;not ten yet.  do a retry
;we have too many errors. print out hex number for last
;received error type. cpm will print perm error message.
	POP	AF	;get code
;set error return for operating system
	LD 	a,1
	ret
redo:
;b still has read/write flag
	POP	AF	;get error code
	AND	0e0h	;retry if not track error
	JP	NZ,tryagn	;
;was a track error so need to reseek
	PUSH	BC	;save	read/write indicator
;figure out the desired track
	LD	DE,track
	LD	HL,(diskno)	;selected disk
	ADD	HL,DE	;point to correct trk indicator
	LD 	a,(HL)	;desired track
	PUSH	AF	;save it
	call	home
	POP	AF
	LD 	c,a
	call	settrk
	POP	BC	;get read/write indicator
	JP	tryagn
;
;
;
step:			;step head out towards zero
			;if carry is set; else
			;step in
; h,l point to correct track indicator word
	JP	C,outx
	INC	(HL)	;increment current track byte
	LD 	a,04h	;set direction = in
dostep:
	OR	2
	OUT	(cmd1),A	;pulse step bit
	AND	0fdh
	OUT	(cmd1),A	;turn off pulse
;the fdc-2 had a stepp ready line. the fdc-3 relies on
;software time out
	LD 	a,16d	;delay 8 ms
	JP	delay
;	ret
;
outx:
	DEC	(HL)	;update track byte
	XOR	a
	JP	dostep
;
headload:
;select and load the head on the correct drive
	LD	HL,prtout	;old slect info
	LD 	b,(HL)
	DEC	HL	;new select info
	LD 	a,(HL)
	INC	HL
	LD 	(HL),a

	OR	10h	; enable interrupt

	OUT	(cmd2),A	;select the drive
	AND	0efh
;set up h.l to point to track byte for selected disk
	LD	DE,track
	LD	HL,(diskno)
	ADD	HL,DE
;now check for needing a 35 ms delay
;if we have changed drives or if the head is unloaded
;we need to wait 35 ms for head settle
	CP	b	;are we on the same drive
	JP	NZ,needdly
;we are on the same drive
;is the head loaded?
	IN	A,(stat)
	AND	80h
	RET	Z		;already loaded
needdly:
	XOR	a
	OUT	(cmd1),A	;load the head
	LD 	a,70d
	JP	delay
;	ret

;
; BIOS Data Segment
;
cnt60:	DEFM	60	; 60 tick cntr = 1 sec
intstk:			; local intrpt stk
	DEFW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DEFW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
lstintstk:
svdhl:	DEFW	0	; saved Regs HL during int hndl
svdsp:	DEFW	0	; saved SP during int hndl
svdret:	DEFW	0	; saved return during int hndl
tickn:	DEFM	0	; ticking boolean,true = delayed
	if	debug
intmsk:	DEFM	44h	; intrpt msk, enables clk intrpt, & con2
	else
intmsk:	DEFM	54h	; intrpt msk, enables clk intrpt, & con0/2
	endif
preemp:	DEFM	0	; preempted boolean
;
scrat:			; start of scratch area
track:	DEFM	0	; current trk on drive 0
trak1:	DEFM	0	; current trk on drive 1
trak2:	DEFM	0	
trak3:	DEFM	0
sector:	DEFM	0	; currently selected sctr
dmaad:	DEFW	0	; current dma address
diskno:	DEFM	0	; current disk number
dummy:	DEFM	0	; must be 0 for dbl add
errors:	DEFM	0
port:	DEFM	0
prtout:	DEFM	0
dnsty:	DEFM	0
;
	disks	2
DEFC bpb  =  2*1024 ;bytes per block
DEFC rpb  =  bpb/128 ;records per block
DEFC maxb  =  255 ;max block number
	diskdef	0,1,58,,bpb,maxb+1,128,128,2,0
	diskdef	1,0
;
tran:	DEFS	2
;
	endef

	DEFM	0	;force out last byte in hex file

	end
