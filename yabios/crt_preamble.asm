
IF (__page_zero_present)

    xor     a               ; Zero Accumulator

                            ; Clear Refresh Control Reg (RCR)
    out0    (RCR),a         ; DRAM Refresh Enable (0 Disabled)

                            ; Clear INT/TRAP Control Register (ITC)             
    out0    (ITC),a         ; Disable all external interrupts.             

                            ; Set Operation Mode Control Reg (OMCR)
    ld      a,OMCR_M1E      ; Enable M1 for single step, disable 64180 I/O _RD Mode
    out0    (OMCR),a        ; X80 Mode (M1 Disabled, IOC Disabled)

                            ; Set PHI = CCR x 2 = 36.864MHz
                            ; if using ZS8180 or Z80182 at High-Speed
    ld      a,CMR_X2        ; Set Hi-Speed flag
    out0    (CMR),a         ; CPU Clock Multiplier Reg (CMR)

                            ; Set CCR = crystal = 18.432MHz
                            ; if using ZS8180 or Z80182 at High-Speed
    ld      a,CCR_XTAL_X2   ; Set Hi-Speed flag
    out0    (CCR),a         ; CPU Control Reg (CCR)

                            ; DMA/Wait Control Reg Set I/O Wait States
    ld      a,DCNTL_MWI0|DCNTL_IWI1
    out0    (DCNTL),a       ; 1 Memory Wait & 3 I/O Wait

                            ; Set Logical RAM Addresses
                            ; $F000-$FFFF RAM   CA1  -> $F.
                            ; $C000-$EFFF RAM   BANK
                            ; $0000-$BFFF Flash BANK -> $.0

    ld      a,$F0           ; Set New Common 1 / Bank Areas for RAM
    out0    (CBAR),a

    ld      a,$00           ; Set Common 1 Base Physical $0F000 -> $00
    out0    (CBR),a

    ld      a,$00           ; Set Bank Base Physical $00000 -> $00
    out0    (BBR),a

                            ; set up COMMON_AREA_1 Data
    EXTERN  __rodata_common1_data_head
    EXTERN  __rodata_common1_data_size

                            ; load the DMA engine registers with source, destination, and count
    xor     a               ; using BANK0
    ld      hl, __rodata_common1_data_head
    out0    (SAR0L), l
    out0    (SAR0H), h
    out0    (SAR0B), a

    ld      hl, __COMMON_AREA_1_PHASE_DATA
    out0    (DAR0L), l
    out0    (DAR0H), h
    out0    (DAR0B), a

    ld      hl, __rodata_common1_data_size
    out0    (BCR0L), l
    out0    (BCR0H), h   

    ld      bc, +(DMODE_MMOD)*$100+DSTAT_DE0
    out0    (DMODE), b      ; DMODE_MMOD - memory++ to memory++, burst mode
    out0    (DSTAT), c      ; DSTAT_DE0 - enable DMA channel 0, no interrupt
                            ; in burst mode the Z180 CPU stops until the DMA completes

                            ; set up COMMON_AREA_1 Drivers
    EXTERN  __rodata_common1_driver_head
    EXTERN  __rodata_common1_driver_size

                            ; load the DMA engine registers with source, destination, and count
    xor     a               ; using BANK0
    ld      hl, __rodata_common1_driver_head
    out0    (SAR0L), l
    out0    (SAR0H), h
    out0    (SAR0B), a

    ld      hl, __COMMON_AREA_1_PHASE_DRIVER
    out0    (DAR0L), l
    out0    (DAR0H), h
    out0    (DAR0B), a

    ld      hl, __rodata_common1_driver_size
    out0    (BCR0L), l
    out0    (BCR0H), h   

    ld      bc, +(DMODE_MMOD)*$100+DSTAT_DE0
    out0    (DMODE), b      ; DMODE_MMOD - memory++ to memory++, burst mode
    out0    (DSTAT), c      ; DSTAT_DE0 - enable DMA channel 0, no interrupt
                            ; in burst mode the Z180 CPU stops until the DMA completes

    EXTERN  _prt0Lock
                            ; now there's valid COMMON_AREA_1
                            ; we can start the system_tick
    ld      hl, _prt0Lock   ; take the PRT0 lock, forever basically
    sra     (hl)
                            ; we do 256 ticks per second
    ld      hl, __CPU_CLOCK/__CPU_TIMER_SCALE/256-1 
    out0    (RLDR0L), l
    out0    (RLDR0H), h
                            ; enable down counting and interrupts for PRT0
    ld      a, TCR_TIE0|TCR_TDE0
    out0    (TCR), a        ; using the driver/z180/system_tick.asm

    EXTERN  _bios_ioByte    ; set default interface to asci0
    ld      hl, _bios_ioByte
    ld      (hl), $01       ; via the bios IO Byte
           
    EXTERN  _bankLockBase   ; lock BANK0 whilst the yabios CLI is running
    ld      hl, _bankLockBase
    ld      (hl), $FF

    EXTERN  _asci0_init
    call    _asci0_init     ; initialise the asci0 and,

    EXTERN  _asci1_init    
    call    _asci1_init     ; the asci1 interfaces

ENDIF

IF (__crt_org_code = 0) && !(__page_zero_present)

INCLUDE "crt_page_zero_yabios.inc"

ENDIF
