;
;  Compute a Mandelbrot set on a simple Z80 computer.
;
; From https://rosettacode.org/wiki/Mandelbrot_set#Z80_Assembly
; Adapted to CP/M and colorzied by J.B. Langston
;
; Assemble with z88dk for YAZ180 CP/M, for example:
; zcc +yaz180 -subtype=cpm -v -m --list mandel.asm -o mand180
; appmake +glue --ihex --clean -b mand180 -c mand180
;
; Assemble with z88dk for yabios app model, for example:
; zcc +yaz180 -subtype=app -v -m --list mandel.asm -o mandapu
; appmake +glue --ihex --clean -b mandapu -c mandapu
;
; To calculate the theoretical minimum time at 115200 baud.
; Normally 10 colour codes, and 1 character per point.
; A line is (3 x 80) x 11 + CR + LF = 2642 characters
; There are 10 x 60 / 4 lines = 150 lines
; Therefore 396,300 characters need to be transmitted.
; Serial rate is 115200 baud or 14,400 8 bit characters per second
;
; Therefore the theoretical minimum time is 27.52 seconds.
;
; Results          FCPU         Original    Optimised   z180 mlt     APU
; RC2014 CP/M    7.432MHz         4'51"       4'10"
; YAZ180 CP/M   18.432MHz         1'40"       1'24"       1'00"
; YAZ180 yabios 18.432Mhz                     1'14"         54"
; YAZ180 CP/M   36.864MHz                       58"         46"
; YAZ180 yabios 36.864Mhz                       56"         45"
; 
;
; Porting this program to another Z80 platform should be easy and straight-
; forward: The only dependencies on my homebrew machine are the system-calls
; used to print strings and characters. These calls are performed by loading
; IX with the number of the system-call and performing an RST 08. To port this
; program to another operating system just replace these system-calls with
; the appropriate versions. Only three system-calls are used in the following:
; _crlf: Prints a CR/LF, _puts: Prints a 0-terminated string (the adress of
; which is expected in HL), and _putc: Print a single character which is
; expected in A. RST 0 give control back to the monitor.
;

include "config_yaz180_private.inc"

defc _CPM       = 0
defc _APU       = 1
defc _DOUBLE    = 0

IF !_CPM
extern asm_pchar, asm_pstring
ENDIF

IF _APU
extern asm_am9511a_reset, asm_am9511a_opp, asm_am9511a_cmd
extern asm_am9511a_isr, asm_am9511a_chk_idle
ENDIF

defc bdos       = 05h                     ; bdos vector
defc conout     = 2                       ; console output bdos call
defc condio     = 6                       ; console direct I/O call
defc prints     = 9                       ; print string bdos call
defc cr         = 13                      ; carriage return
defc lf         = 10                      ; line feed
defc esc        = 27                      ; escape

IF _CPM                           ; cp/m ram model 
defc eos        = '$'                     ; end of string marker
ELSE
defc eos        = 0                       ; end of string marker
ENDIF

defc pixel      = '#'                     ; character to output for pixel
defc SCALE      = 256                     ; Do NOT change this - the
                                          ; arithmetic routines rely on
                                          ; this scaling factor! :-)

;------------------------------------------------------------------------------

SECTION  data_user

x:              defw    0                       ; x-coordinate
x_start:        defw    -2 * SCALE              ; Minimum x-coordinate
x_end:          defw    1 * SCALE               ; Maximum x-coordinate
x_step:         defw    SCALE / 80              ; x-coordinate step-width

y:              defw    0                       ; y-coordinate
y_start:        defw    -5 * SCALE / 4          ; Minimum y-coordinate   
y_end:          defw    5 * SCALE / 4           ; Maximum y-coordinate
y_step:         defw    SCALE / 60              ; y-coordinate step-width

iteration_max:  defb    30                      ; How many iterations
divergent:      defw    SCALE * 4
scale:          defw    SCALE
                defw    0

z_0:            defs    4,0
z_1:            defs    4,0

z_2:            defw    0

z_0_square:
z_0_square_low: defw    0
z_0_square_high:defw    0
z_1_square:
z_1_square_low: defw    0
z_1_square_high:defw    0


display:        defm    " .-+*=#@"              ; 8 characters for the display

hsv:            defm 0                          ; hsv color table
                defm 201, 200, 199, 198, 197
                defm 196, 202, 208, 214, 220
                defm 226, 190, 154, 118,  82
                defm 46,   47,  48,  49,  50
                defm 51,   45,  39,  33,  27
                defm 21,   57,  93, 129, 165

welcome:        defm    "Generating a Mandelbrot set"
crlf:           defm    cr, lf, eos
finished:       defm    esc, "[0mComputation finished.", cr, lf, eos
ansifg:         defm    esc, "[38;5;", eos
ansibg:         defm    esc, "[48;5;", eos

;------------------------------------------------------------------------------

SECTION code_user

PUBLIC _main

_main:
        ld      de, welcome             ; Print a welcome message
IF _CPM                                 ; cp/m ram model 
        call    prtmesg
ELSE
        call    asm_pstring
ENDIF
        call    delay
        call    delay

IF _APU

        call    delay
        call    delay
                                        ; DMA/Wait Control Reg Set I/O Wait States
        ld      a,DCNTL_MWI1|DCNTL_IWI1
        out0    (DCNTL),a               ; 2 Memory Wait & 3 I/O Wait

        call    asm_am9511a_reset       ; INITIALISE THE APU
ENDIF

; for (y = <initial_value> ; y <= y_end; y += y_step)
; {
        ld      hl, (y_start)           ; y = y_start
        ld      (y), hl
outer_loop:
        ld      hl, (y_end)             ; Is y <= y_end?
        ld      de, (y)
        and     a                       ; Clear carry
        sbc     hl, de                  ; Perform the comparison
        jp      M, mandel_end           ; End of outer loop reached

;    for (x = x_start; x <= x_end; x += x_step)
;    {
        ld      hl, (x_start)           ; x = x_start
        ld      (x), hl
inner_loop:
        ld      hl, (x_end)             ; Is x <= x_end?
        ld      de, (x)
        and     a
        sbc     hl, de
        jp      M, inner_loop_end       ; End of inner loop reached

;       push af
;       push hl
;       ld hl,(x)
;       call asm_phexwd
;       ld l,':'
;       call asm_pchar
;       ld hl,(y)
;       call asm_phexwd
;       ld l,'>'
;       call asm_pchar
;       call delay
;       call delay
;       pop hl
;       pop af

;      z_0 = z_1 = 0;
        ld      hl, 0
        ld      (z_0), hl
        ld      (z_1), hl

;      for (iteration = iteration_max; iteration; iteration--)
;      {
        ld      a, (iteration_max)
        ld      b, a
iteration_loop:
        push    bc                      ; iteration -> stack
        
IF _APU

        call    apu_calc
        ld      hl,(z_2)                ; HL now contains (z_0 ^ 2 - z_1 ^ 2) / scale

ELSE                                    ; IF !_APU

;        z2 = (z_0 * z_0 - z_1 * z_1) / scale;

        ld      hl, (z_1)               ; Compute DE HL = z_1 * z_1
        ld      d, h
        ld      e, l
        call    mul_16
        ld      (z_1_square_low), hl    ; z_1 ** 2 is needed later again
        ld      (z_1_square_high), de

        ld      hl, (z_0)               ; Compute DE HL = z_0 * z_0
        ld      d, h
        ld      e, l
        call    mul_16
        ld      (z_0_square_low), hl    ; z_1 ** 2 will be also needed
        ld      (z_0_square_high), de

        and     a                       ; Compute subtraction
        ld      bc, (z_1_square_low)
        sbc     hl, bc
        push    hl                      ; Save lower 16 bit of result
        ld      h, d
        ld      l, e
        ld      bc, (z_1_square_high)
        sbc     hl, bc
        pop     bc                      ; HL BC = z_0 ^ 2 - z_1 ^ 2

        ld      c, b                    ; Divide by scale = 256
        ld      b, l                    ; Discard the rest
        push    bc                      ; We need BC later

;        z_3 = 2 * z_0 * z_1 / scale;
        ld      hl, (z_0)               ; Compute DE HL = 2 * z_0 * z_1
        add     hl, hl
        ld      de, (z_1)
        call    mul_16

        ld      b, e                    ; Divide by scale (= 256)
        ld      c, h                    ; BC contains now z_3

;        z_1 = z_3 + y;
        ld      hl, (y)
        add     hl, bc
        ld      (z_1), hl

;        z_0 = z_2 + x;
        pop     bc                      ; Here BC is needed again :-)
        ld      hl, (x)
        add     hl, bc
        ld      (z_0), hl

;        if (z_0 * z_0 / scale + z_1 * z_1 / scale > 4 * scale)
        ld      hl, (z_0_square_low)    ; Use the squares computed
        ld      de, (z_1_square_low)    ; above
        add     hl, de
        ld      b, h                    ; BC contains lower word of sum
        ld      c, l

        ld      hl, (z_0_square_high)
        ld      de, (z_1_square_high)
        adc     hl, de

        ld      h, l                    ; HL now contains (z_0 ^ 2 -
        ld      l, b                    ; z_1 ^ 2) / scale
        
        ld      (z_2),hl                ; save z_2

ENDIF                                   ; IF _APU

        ld      bc,(divergent)
        and     a
        sbc     hl, bc

;          break;
        jr      C, iteration_dec        ; No break
        pop     bc                      ; Get latest iteration counter
        jr      iteration_end           ; Exit loop

;        iteration++;
iteration_dec:
        pop     bc                      ; Get iteration counter
        djnz    iteration_loop          ; We might fall through!
;      }
iteration_end:
;      printf("%c", display[iteration % 7]);
;       call    asciipixel              ; Print the character
        call    colorpixel              ; Print the character

;       ld l,' '
;       call asm_pchar
;       ld hl,(z_2)
;       call asm_phexwd                     ; print final z_2
;       ld l,' '
;       call asm_pchar
;       ld l,b
;       call asm_phex                       ; print the iteration
;       ld l,cr
;       call asm_pchar
;       ld l,lf
;       call asm_pchar
;       call delay
;       call delay
        
IF _CPM                                 ; cp/m ram model 
        ld      c, condio
        call    bdos
ELSE
        ld      l,e
        call    asm_pchar
ENDIF

IF _APU
        call    delay                   ; wait until colour sequence is finished
        call    delay
ENDIF

        ld      de, (x_step)            ; x += x_step
        ld      hl, (x)
        add     hl, de
        ld      (x), hl

        jp      inner_loop
;    }
;    printf("\n");
inner_loop_end:
IF _CPM                                 ; cp/m ram model 
        ld      de, crlf                ; Print a CR/LF pair
        call    prtmesg
ELSE
        ld      l,cr
        call    asm_pchar
        ld      l,lf
        call    asm_pchar
ENDIF
        ld      de, (y_step)            ; y += y_step
        ld      hl, (y)
        add     hl, de
        ld      (y), hl                 ; Store new y-value

        jp      outer_loop
; }

mandel_end:
        call    delay
        call    delay

IF _APU
                                        ; DMA/Wait Control Reg Set I/O Wait States
        ld      a,DCNTL_MWI0|DCNTL_IWI1
        out0    (DCNTL),a               ; 1 Memory Wait & 3 I/O Wait
ENDIF

        ld      de, finished            ; Print finished-message
IF _CPM                                 ; cp/m ram model 
        call    prtmesg
ELSE
        call    asm_pstring
ENDIF
        ret                             ; Return to CP/M or yabios
                
colorpixel:
        ld      a,b                     ; iter count in B -> C
        and     $1F                     ; lower five bits only
        ld      c,a
        ld      b,0
        ld      hl, hsv                 ; get ANSI color code
        add     hl, bc
        ld      a,(hl)
        call    setcolor
        ld      e, pixel                ; show pixel
        ret
                
asciipixel:
        ld      a, b                    ; iter count in B -> L
        and     $07                     ; lower three bits only
        sbc     hl, hl
        ld      l, a
        ld      de, display             ; Get start of character array
        add     hl, de                  ; address and load the
        ld      e, (hl)                 ; character to be printed
        ret

setcolor:
        push    af                      ; save accumulator
        ld      de,ansifg               ; start ANSI control sequence to set foreground color
IF _CPM                                 ; cp/m ram model 
        call    prtmesg
ELSE
        call    asm_pstring
ENDIF
        pop     af
        call    printdec                ; print ANSI color code
IF _CPM                                 ; cp/m ram model 
        ld      e,'m'                   ; finish control sequence
        ld      c, condio
        call    bdos
ELSE
        ld      l,'m'                   ; finish control sequence
        call    asm_pchar
ENDIF
        ret
                
printdec:
        ld      c,-100                  ; print 100s place
        call    pd1
        ld      c,-10                   ; 10s place
        call    pd1
        ld      c,-1                    ; 1s place
pd1:
        ld      e,'0'-1                 ; start ASCII right before 0
pd2:
        inc     e                       ; increment ASCII code
        add     a,c                     ; subtract 1 place value
        jr      C,pd2                   ; loop until negative
        sub     c                       ; add back the last value
        push    af                      ; save accumulator
        ld      a,-1                    ; are we in the ones place?
        cp      c
        jr      Z,pd3                   ; if so, skip to output
        ld      a,'0'                   ; don't print leading 0s
        cp      e
        jr      Z,pd4
pd3:
IF _CPM                                 ; cp/m ram model 
        ld      c, condio
        call    bdos
ELSE
        ld      l,e
        call    asm_pchar
ENDIF
pd4:
        pop     af                      ; restore accumulator
        ret

;   Print message pointed to by (DE). It will end with a '$'.
;   modifies AF, DE, & HL
prtmesg:
        ld      a,(de)      ; Get character from DE address
        cp      '$'
        ret     Z
        inc     de
        push    de        ;otherwise, bump pointer and print it.
        ld      e,a
        ld      c, condio
        call    bdos
        pop     de
        jr      prtmesg

IF _APU

apu_calc:

IF _DOUBLE

;;;;;;; double calc

        ld hl,z_0                       ; Extend 16 bit z_0 to 32 bit
        inc hl
        ld a,(hl)
        add a,a                         ; Put sign bit into carry
        sbc a,a                         ; A = 0 if carry == 0, $FF otherwise
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a

        ld hl,z_1                       ; Extend 16 bit z_1 to 32 bit
        inc hl
        ld a,(hl)
        add a,a                         ; Put sign bit into carry
        sbc a,a                         ; A = 0 if carry == 0, $FF otherwise
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a

;       z_2 = (z_0 * z_0 - z_1 * z_1) / scale;

        ld de,z_0
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_PTOD           ; COMMAND for PTOD (push double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_DMUL           ; COMMAND for DMUL (multiply lower)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOD           ; COMMAND for PTOD (push double)
        call asm_am9511a_cmd            ; ENTER a COMMAND
        
        ld de,z_0_square
        ld bc,__IO_APU_OP_REM32         ; REMOVE 32 bit (double) to z_0_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER
        
        ld de,z_1
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_PTOD           ; COMMAND for PTOD (push double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_DMUL           ; COMMAND for DMUL (multiply lower)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOD           ; COMMAND for PTOD (push double)
        call asm_am9511a_cmd            ; ENTER a COMMAND
        
        ld de,z_1_square
        ld bc,__IO_APU_OP_REM32         ; REMOVE 32 bit (double) to z_1_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DSUB           ; COMMAND for DSUB (subtract double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DDIV           ; COMMAND for DDIV (divide double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_POPS           ; COMMAND for POPS (pop single)
        call asm_am9511a_cmd            ; ENTER a COMMAND   
        
;       z_0 = z_2 + x;

        ld de,x
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (word)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_SADD           ; COMMAND for SADD (add single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

;       z_3 = 2 * z_0 * z_1 / scale;

        ld de,z_0
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_PTOD           ; COMMAND for PTOD (push double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_DADD           ; COMMAND for DADD (add double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,z_1
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DMUL           ; COMMAND for DMUL (multiply lower)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DDIV           ; COMMAND for DDIV (divide double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

;       z_1 = z_3 + y;

        ld c,__IO_APU_OP_POPS           ; COMMAND for POPS (pop single)
        call asm_am9511a_cmd            ; ENTER a COMMAND 

        ld de,y
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (word)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_SADD           ; COMMAND for SADD (add single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,z_1
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (word) to z_1
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER
        
        ld de,z_0
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (word) to z_0
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

;       if (z_0 * z_0 / scale + z_1 * z_1 / scale > 4 * scale)

        ld de,z_0_square
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double) from z_0_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld de,z_1_square
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double) from z_1_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DADD           ; COMMAND for DADD (add double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (double)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_DDIV           ; COMMAND for DDIV (divide double)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_POPS           ; COMMAND for POPS (pop single)
        call asm_am9511a_cmd            ; ENTER a COMMAND 

        ld de,z_2
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (single) to z_2
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

ELSE                                    ; IF !_DOUBLE

;;;;;;; float calc

;       z_2 = (z_0 * z_0 - z_1 * z_1) / scale;

        ld de,z_0
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOF           ; COMMAND for PTOF (push float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FMUL           ; COMMAND for FMUL (multiply float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOF           ; COMMAND for PTOF (push float)
        call asm_am9511a_cmd            ; ENTER a COMMAND
        
        ld de,z_0_square
        ld bc,__IO_APU_OP_REM32         ; REMOVE 32 bit (float) to z_0_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER
        
        ld de,z_1
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOF           ; COMMAND for PTOF (push float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FMUL           ; COMMAND for FMUL (multiply float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOF           ; COMMAND for PTOF (push float)
        call asm_am9511a_cmd            ; ENTER a COMMAND
        
        ld de,z_1_square
        ld bc,__IO_APU_OP_REM32         ; REMOVE 32 bit (float) to z_1_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FSUB           ; COMMAND for FSUB (subtract float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FDIV           ; COMMAND for FDIV (divide float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FIXS           ; COMMAND for FIXS (fix single)
        call asm_am9511a_cmd            ; ENTER a COMMAND        
        
;       z_0 = z_2 + x;

        ld de,x
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (word)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_SADD           ; COMMAND for SADD (add single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

;       z_3 = 2 * z_0 * z_1 / scale;

        ld de,z_0
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_PTOF           ; COMMAND for PTOF (push float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FADD           ; COMMAND for FADD (add float)
        call asm_am9511a_cmd            ; ENTER a COMMAND


        ld de,z_1
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FMUL           ; COMMAND for FMUL (multiply float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (single)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FDIV           ; COMMAND for FDIV (divide float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FIXS           ; COMMAND for FIXS (fix single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

;       z_1 = z_3 + y;

        ld de,y
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (word)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_SADD           ; COMMAND for SADD (add single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,z_1
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (word) to z_1
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER
        
        ld de,z_0
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (word) to z_0
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

;       if (z_0 * z_0 / scale + z_1 * z_1 / scale > 4 * scale)

        ld de,z_0_square
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (float) from z_0_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld de,z_1_square
        ld bc,__IO_APU_OP_ENT32         ; ENTER 32 bit (float) from z_1_square
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FADD           ; COMMAND for FADD (add float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,scale
        ld bc,__IO_APU_OP_ENT16         ; ENTER 16 bit (word)
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

        ld c,__IO_APU_OP_FLTS           ; COMMAND for FLTS (float single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FDIV           ; COMMAND for FDIV (divide float)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld c,__IO_APU_OP_FIXS           ; COMMAND for FIXS (fix single)
        call asm_am9511a_cmd            ; ENTER a COMMAND

        ld de,z_2
        ld bc,__IO_APU_OP_REM16         ; REMOVE 16 bit (single) to z_2
        call asm_am9511a_opp            ; POINTER TO OPERAND IN OPERAND BUFFER

ENDIF                                   ; IF !_DOUBLE

        call asm_am9511a_isr            ; KICK OFF APU PROCESS, WHICH THEN INTERRUPTS

        jp asm_am9511a_chk_idle         ; CHECK, because it could be doing a last command

ELSE                                    ; IF !_APU

IF __Z180

   ; signed multiplication of two 16-bit numbers into a 32-bit product.
   ; using the z180 hardware unsigned 8x8 multiply instruction
   ;
   ; enter : de = 16-bit multiplicand = y
   ;         hl = 16-bit multiplier = x
   ;
   ; exit  : dehl = 32-bit product
   ;         carry reset
   ;
   ; uses  : af, bc, de, hl

mul_16:
   ld b,d                       ; d = MSB of multiplicand
   ld c,h                       ; h = MSB of multiplier
   push bc                      ; save sign info

   bit 7,d
   jr Z,l_pos_de                ; take absolute value of multiplicand

   ld a,e
   cpl 
   ld e,a
   ld a,d
   cpl
   ld d,a
   inc de

l_pos_de:
   bit 7,h
   jr Z,l_pos_hl                ; take absolute value of multiplier

   ld a,l
   cpl
   ld l,a
   ld a,h
   cpl
   ld h,a
   inc hl

l_pos_hl:
                                ; prepare unsigned dehl = de x hl
   ld b,l                       ; xl
   ld c,d                       ; yh
   ld d,l                       ; xl
   ld l,c
   push hl                      ; xh yh
   ld l,e                       ; yl

   ; bc = xl yh
   ; de = xl yl
   ; hl = xh yl
   ; stack = xh yh

   mlt de                       ; xl * yl

   mlt bc                       ; xl * yh
   mlt hl                       ; xh * yl
   
   xor a
   add hl,bc                    ; sum cross products
   adc a,a                      ; collect carry

   ld b,a                       ; carry from cross products
   ld c,h                       ; LSB of MSW from cross products

   ld a,d
   add a,l
   ld d,a                       ; de = final product LSW

   pop hl
   mlt hl                       ; xh * yh

   adc hl,bc                    ; hl = final product MSW
   ex de,hl

   pop bc                       ; recover sign info from multiplicand and multiplier
   ld a,b
   xor c
   ret P                        ; return if positive product

   ld a,l                       ; negate product and return
   cpl
   ld l,a
   ld a,h
   cpl
   ld h,a
   ld a,e
   cpl
   ld e,a
   ld a,d
   cpl
   ld d,a
   inc l
   ret NZ
   inc h
   ret NZ
   inc de
   ret

ELSE                                ; IF !__Z180

;
; Compute DEHL = DE * HL (signed): This routine is not too clever but it
; works. It is based on a standard 16-by-16 multiplication routine for unsigned
; integers. At the beginning the sign of the result is determined based on the
; signs of the operands which are negated if necessary. Then the unsigned
; multiplication takes place, followed by negating the result if necessary.
;

mul_16:
       ld b,d                       ; d = MSB of multiplicand
       ld c,h                       ; h = MSB of multiplier
       push bc                      ; save sign info

       bit 7,d
       jr Z,l_pos_de                ; take absolute value of multiplicand

       ld a,e
       cpl 
       ld e,a
       ld a,d
       cpl
       ld d,a
       inc de

l_pos_de:
       bit 7,h
       jr Z,l_pos_hl                ; take absolute value of multiplier

       ld a,l
       cpl
       ld l,a
       ld a,h
       cpl
       ld h,a
       inc hl

l_pos_hl:
       ld      b, h
       ld      c, l

       ld      hl, 0                ; Start multiplication
       rl      e
       rl      d
       jr      NC, mul_16_01
       add     hl, bc
       jr      NC, mul_16_01
       inc     de
mul_16_01:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_02
       add     hl, bc
       jr      NC, mul_16_02
       inc     de
mul_16_02:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_03
       add     hl, bc
       jr      NC, mul_16_03
       inc     de
mul_16_03:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_04
       add     hl, bc
       jr      NC, mul_16_04
       inc     de
mul_16_04:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_05
       add     hl, bc
       jr      NC, mul_16_05
       inc     de
mul_16_05:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_06
       add     hl, bc
       jr      NC, mul_16_06
       inc     de
mul_16_06:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_07
       add     hl, bc
       jr      NC, mul_16_07
       inc     de
mul_16_07:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_08
       add     hl, bc
       jr      NC, mul_16_08
       inc     de
mul_16_08:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_09
       add     hl, bc
       jr      NC, mul_16_09
       inc     de
mul_16_09:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_10
       add     hl, bc
       jr      NC, mul_16_10
       inc     de
mul_16_10:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_11
       add     hl, bc
       jr      NC, mul_16_11
       inc     de
mul_16_11:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_12
       add     hl, bc
       jr      NC, mul_16_12
       inc     de
mul_16_12:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_13
       add     hl, bc
       jr      NC, mul_16_13
       inc     de
mul_16_13:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_14
       add     hl, bc
       jr      NC, mul_16_14
       inc     de
mul_16_14:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_15
       add     hl, bc
       jr      NC, mul_16_15
       inc     de
mul_16_15:

       add     hl, hl
       rl      e
       rl      d
       jr      NC, mul_16_16
       add     hl, bc
       jr      NC, mul_16_16
       inc     de
mul_16_16:

       pop bc                       ; recover sign info from multiplicand and multiplier
       ld a,b
       xor c
       ret P                        ; return if positive product

       ld a,l                       ; negate product and return
       cpl
       ld l,a
       ld a,h
       cpl
       ld h,a
       ld a,e
       cpl
       ld e,a
       ld a,d
       cpl
       ld d,a
       inc l
       ret NZ
       inc h
       ret NZ
       inc de
       ret


ENDIF                           ; IF __Z180

ENDIF                           ; IF _APU

delay:
        push bc
        ld b, $00
delay_loop:
        ex (sp), hl
        ex (sp), hl
        djnz delay_loop
        pop bc
        ret
