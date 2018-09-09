;
; Converted to z88dk z80asm for YAZ180 by
; Phillip Stevens @feilipu https://feilipu.me
; September 2018
;

;==============================================================================
;
;           mpm load bios for MP/M 2.1
;

SECTION   mpm_bios  ;origin of the mpm loader bios

;
;    jump vector for individual subroutines
;

EXTERN    boot      ;cold start
EXTERN    wboot     ;warm start
EXTERN    const     ;console status
EXTERN    conin     ;console character in
EXTERN    conout    ;console character out
EXTERN    list      ;list character out
EXTERN    punch     ;punch character out
EXTERN    reader    ;reader character out
EXTERN    home      ;move head to home position
EXTERN    seldsk    ;select disk
EXTERN    settrk    ;set track number
EXTERN    setsec    ;set sector number
EXTERN    setdma    ;set dma address
EXTERN    read      ;read disk
EXTERN    write     ;write disk
EXTERN    listst    ;return list status
EXTERN    sectran   ;sector translate

    jp    boot      ;cold start
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
    jp    sectran   ;sector translate;

