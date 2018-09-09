;	MDS I/O drivers for CP/M 2.0
;	(single drive, single density)
;		     -or-
;	(single drive, double density)

;	MP/M 1.0 Loader BIOS
;	(modified CP/M 2.0 BIOS)


;	Version 1.0   --    Sept 79

vers	equ	20	;version 2.0

;	Copyright (C) 1978, 1979
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
numdsks equ	1	;number of drives available
	endif

ram$top	equ	1d00h	 	; top address+1
bios	equ	ram$top-0600h	; basic input/output system
bdos	equ	bios-0e00h	; base of the bdos

	org	bios


buff	equ	0080h	;default buffer address

retry	equ	10	;max retries on disk i/o before error

;	jump vector for indiviual routines

	jmp	boot
wboote:	jmp	wboot
	jmp	const
	jmp	conin
	jmp	conout
	jmp	list
	jmp	punch
	jmp	reader
	jmp	home
	jmp	seldsk
	jmp	settrk
	jmp	setsec
	jmp	setdma
	jmp	read
	jmp	write
	jmp	list$st		; list status poll
	jmp	sect$tran	; sector translation


;	we also assume the MDS system has four disk drives

numdisks equ	1	;number of drives available
revrt	equ	0fdh	;interrupt revert port
intc	equ	0fch	;interrupt mask port
icon	equ	0f3h	;interrupt control port
inte	equ	0111$1110b	;enable rst 0(warm boot), rst 7 (monitor)

;	MDS monitor equates

rmon80	equ	0ff0fh	;restart mon80 (boot error)

;	disk ports and commands

base	equ	78h	;base of disk command io ports
dstat	equ	base	;disk status (input)
rtype	equ	base+1	;result type (input)
rbyte	equ	base+3	;result byte (input)

ilow	equ	base+1	;iopb low address (output)
ihigh	equ	base+2	;iopb high address (output)

readf	equ	4h	;read function
writf	equ	6h	;write function
recal	equ	3h	;recalibrate drive
iordy	equ	4h	;i/o finished mask
cr	equ	0dh	;carriage return
lf	equ	0ah	;line feed

boot:

wboot:
gocpm:
	ret

crtin:			; crt: input
	in 0f7h ! ani 2 ! jz crtin
	in 0f6h ! ani 7fh
	ret
crtout:			; crt: output
	in 0f7h ! ani 1 ! jz crtout
	mov a,c ! out 0f6h
	ret
crtst:			; crt: status
	in 0f7h ! ani 2 ! rz
	ori 0ffh 
	ret
ttyin:			; tty: input
	in 0f5h ! ani 2 ! jz ttyin
	in 0f4h ! ani 7fh
	ret
ttyout:			; tty: output
	in 0f5h ! ani 1 ! jz ttyout
	mov a,c ! out 0f4h
	ret
;ttyst:
;	in 0f5h ! ani 2 ! rz
;	ori -1
;	ret

lptout:			; lpt: output
	in 0fbh ! ani 1 ! jz lptout
 	mov a,c ! cma ! out 0fah
	ret

lpt$st:
	in 0fbh ! ani 1 ! rz
	ori 0ffh
	ret

conin	equ	crtin
const	equ	crtst
conout	equ	crtout
reader	equ	ttyin
punch	equ	ttyout
list	equ	lptout
listst	equ	lptst



seldsk:	;select disk given by register c
	lxi h, 0 ! mov a,c ! cpi num$disks ! rnc  ; first, insure good select
	ani 2 ! sta dbank	; then save it
	lxi h,sel$table ! mvi b,0 ! dad b ! mov a,m ! sta iof
	mov h,b ! mov l,c
	dad h ! dad h ! dad h ! dad h	; times 16
	lxi d,dpbase ! dad d
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
	mov h,b ! mov l,c ! inx h  ; in case of no translation
	mov a, d ! ora e ! rz	
	xchg ! dad b	; point to physical sector
	mov l,m ! mvi h,0
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

wait0:	call	instat		;wait for completion
	ani	iordy		;ready?
	jz	wait0

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

wready:	;not ready, treat as error for now
	call	inbyte		;clear result byte
	jmp	trycount

werror:	;return hardware malfunction (crc, track, seek, etc.)
;	the MDS controller has returned a bit in each position
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


;	utility subroutines

prmsg:	;print message at h,l to 0
	mov a,m ! ora a ! rz
	push h ! mov c,a ! call conout ! pop h
	inx h ! jmp prmsg


;	data areas (must be in ram)

dbank:	db	0	;disk bank 00 if drive 0,1
			;	   10 if drive 2,3

iopb:			;io parameter block
	db	80h	;normal i/o operation
iof:	db	readf	;io function, initial read
ion:	db	1	;number of sectors to read
iot:	db	2	;track number
ios:	db	1	;sector number
iod:	dw	buff	;io address
;
;

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
	endef
	endif

	if	mac and dbl
	disks	numdisks		; generate drive tables
	diskdef 0,1,52,,2048,243,128,128,2,0
	endef
	endif

	if	asm
dpbase	equ	$		;base of disk param blks
dpe0:	dw	xlt0,0000h	;translate table
	dw	0000h,0000h	;scratch area
	dw	dirbuf,dpb0	;dir buff, parm block
	dw	csv0,alv0	;check, alloc vectors
dpb0	equ	$		;disk param block
	endif

	if	asm and sgl
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
xlt0	equ	$		;translate table
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

	if	asm and dbl
xlt0	equ	0
	endif

	if	asm
begdat	equ	$
dirbuf:	ds	128		;directory access buffer
alv0:	ds	31
csv0:	ds	16
	endif

	if	asm and dbl
	ds	16
	endif

	if	asm
enddat	equ	$
datsiz	equ	$-begdat
	endif

	end

