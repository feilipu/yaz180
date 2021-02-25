
INCLUDE "config_yaz180_private.inc"

;------------------------------------------------------------------------------
; start of definitions
;------------------------------------------------------------------------------

PUBLIC  _bios_sp

defc    _bios_sp    =   __BIOS_SP   ; yabios BANK0 SP here, when other banks running

; start of the Transitory Program Area (TPA) Control Block (TCB)
; for BANK1 through BANK12
; this area is Flash (essentially ROM) for BANK0, BANK13, BANK14, & BANK15,
; and can't be easily written to
;
; TCB is from 0x003B through to 0x005B (scratch space for CP/M)

PUBLIC  _bank_sp                        ; DEFW at 0x003B in Page 0

defc    _bank_sp    =   __BANK_SP

;------------------------------------------------------------------------------
; start of common area 1 - page aligned data
;------------------------------------------------------------------------------

SECTION rodata_common1_data

PHASE   __COMMON_AREA_1_PHASE_DATA

PUBLIC APUCMDBuf, APUPTRBuf

APUCMDBuf:      defs    __APU_CMD_SIZE
APUPTRBuf:      defs    __APU_PTR_SIZE

PUBLIC asci0RxBuffer, asci1RxBuffer

asci0RxBuffer:  defs    __ASCI0_RX_SIZE ; Space for the Rx0 Buffer
asci1RxBuffer:  defs    __ASCI1_RX_SIZE ; Space for the Rx1 Buffer

PUBLIC asciTxBuffer

asciTxBuffer:   defs    __ASCI0_TX_SIZE+__ASCI1_TX_SIZE ; Space for the Tx0 & Tx1 Buffer

;------------------------------------------------------------------------------
; start of common area 1 - non aligned data
;------------------------------------------------------------------------------

; pad to next 256 byte boundary

ALIGN           0x100

; immediately after page aligned area so that we don't have to worry about the
; LSB when indexing, for call_far, jp_far, and system_rst

PUBLIC _bankLockBase

_bankLockBase:  defs    $10, $00        ; base address for 16 BANK locks
                                        ; $00 = BANK cold (uninitialised)
                                        ; $FE = BANK available to be entered
                                        ; $FF = BANK locked (active thread)

PUBLIC _shadowLock, _prt0Lock, _prt1Lock, _dmac0Lock, _dmac1Lock, _csioLock

_shadowLock:    defb    $FE             ; mutex for alternate registers
_prt0Lock:      defb    $FE             ; mutex for PRT0 
_prt1Lock:      defb    $FE             ; mutex for PRT1
_dmac0Lock:     defb    $FE             ; mutex for DMAC0
_dmac1Lock:     defb    $FE             ; mutex for DMAC1
_csioLock:      defb    $FE             ; mutex for CSI/O

PUBLIC __system_time_fraction, __system_time

__system_time_fraction: defb    0       ; uint8_t (1/256) fractional time
__system_time:          defs    4       ; uint32_t time_t

PUBLIC APUCMDInPtr, APUCMDOutPtr
PUBLIC APUPTRInPtr, APUPTROutPtr
PUBLIC APUCMDBufUsed, APUPTRBufUsed
PUBLIC APUStatus, APUError, APULock

APUCMDInPtr:            defw    APUCMDBuf
APUCMDOutPtr:           defw    APUCMDBuf
APUPTRInPtr:            defw    APUPTRBuf
APUPTROutPtr:           defw    APUPTRBuf
APUCMDBufUsed:          defb    0
APUPTRBufUsed:          defb    0
APUStatus:              defb    0
APUError:               defb    0
APULock:                defb    $FE     ; mutex for APU

; currently active console interface, only bit 0 is distinguished with TTY=0 CRT=1
PUBLIC  _bios_ioByte

_bios_ioByte:   defb    0               ; intel I/O byte

PUBLIC asci0RxCount, asci0RxIn, asci0RxOut, asci0RxLock

asci0RxCount:   defb    0               ; Space for Rx Buffer Management 
asci0RxIn:      defw    asci0RxBuffer   ; non-zero item since it's initialized anyway
asci0RxOut:     defw    asci0RxBuffer   ; non-zero item since it's initialized anyway
asci0RxLock:    defb    $FE             ; mutex for Rx0

PUBLIC asci0TxCount, asci0TxIn, asci0TxOut, asci0TxLock

asci0TxCount:   defb    0               ; Space for Tx Buffer Management
asci0TxIn:      defw    asciTxBuffer    ; non-zero item since it's initialized anyway
asci0TxOut:     defw    asciTxBuffer    ; non-zero item since it's initialized anyway
asci0TxLock:    defb    $FE             ; mutex for Tx0

PUBLIC asci1RxCount, asci1RxIn, asci1RxOut, asci1RxLock
 
asci1RxCount:   defb    0               ; Space for Rx Buffer Management 
asci1RxIn:      defw    asci1RxBuffer   ; non-zero item since it's initialized anyway
asci1RxOut:     defw    asci1RxBuffer   ; non-zero item since it's initialized anyway
asci1RxLock:    defb    $FE             ; mutex for Rx1

PUBLIC asci1TxCount, asci1TxIn, asci1TxOut, asci1TxLock

asci1TxCount:   defb    0               ; Space for Tx Buffer Management
asci1TxIn:      defw    asciTxBuffer+1  ; non-zero item since it's initialized anyway
asci1TxOut:     defw    asciTxBuffer+1  ; non-zero item since it's initialized anyway
asci1TxLock:    defb    $FE             ; mutex for Tx1

PUBLIC initString, invalidOpCode, invalidTypeStr, badCheckSumStr, LoadOKStr, newLine

initString:     defm    CHAR_CR,CHAR_LF,"::",0
invalidOpCode:  defm    CHAR_CR,CHAR_LF,"Invalid Instruction @ 0x",0
invalidTypeStr: defm    CHAR_CR,CHAR_LF,"Invalid Type!",CHAR_CR,CHAR_LF,0
badCheckSumStr: defm    CHAR_CR,CHAR_LF,"Bad Checksum!",CHAR_CR,CHAR_LF,0
LoadOKStr:      defm    CHAR_CR,CHAR_LF,"Done!"
newLine:        defm    CHAR_CR,CHAR_LF,0

DEPHASE
