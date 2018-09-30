
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yabios provided labels found in common area 1 ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GLOBAL _bios_sp
_bios_sp                        EQU 0FFDEh

GLOBAL _bank_sp
_bank_sp                        EQU 0003Bh

GLOBAL _bankLockBase
_bankLockBase                   EQU 0F500h

GLOBAL _shadowLock
_shadowLock                     EQU 0F510h

GLOBAL _prt0Lock
_prt0Lock                       EQU 0F511h

GLOBAL _prt1Lock
_prt1Lock                       EQU 0F512h

GLOBAL _dmac0Lock
_dmac0Lock                      EQU 0F513h

GLOBAL _dmac1Lock
_dmac1Lock                      EQU 0F514h

GLOBAL _csioLock
_csioLock                       EQU 0F515h

GLOBAL _APULock
_APULock                        EQU 0F527h

GLOBAL _bios_ioByte
_bios_ioByte                    EQU 0F528h

GLOBAL _asci0RxLock
_asci0RxLock                    EQU 0F52Eh

GLOBAL _asci0TxLock
_asci0TxLock                    EQU 0F534h

GLOBAL _asci1RxLock
_asci1RxLock                    EQU 0F53Ah

GLOBAL _asci1TxLock
_asci1TxLock                    EQU 0F540h

GLOBAL asm_call_far_rst
asm_call_far_rst                EQU 0F592h

GLOBAL asm_jp_far
asm_jp_far                      EQU 0F60Eh

GLOBAL asm_jp_far_rst
asm_jp_far_rst                  EQU 0F614h

GLOBAL asm_exit_far
asm_exit_far                    EQU 0F6D1h

GLOBAL asm_memcpy_far
asm_memcpy_far                  EQU 0F713h

GLOBAL asm_load_hex_fastcall
asm_load_hex_fastcall           EQU 0F7AFh

GLOBAL asm_bank_get_rel
asm_bank_get_rel                EQU 0F860h

GLOBAL asm_bank_get_rel_fastcall
asm_bank_get_rel_fastcall       EQU 0F864h

GLOBAL asm_bank_get_abs
asm_bank_get_abs                EQU 0F872h

GLOBAL asm_bank_get_abs_fastcall
asm_bank_get_abs_fastcall       EQU 0F876h

GLOBAL asm_lock_get
asm_lock_get                    EQU 0F882h

GLOBAL asm_lock_get_fastcall
asm_lock_get_fastcall           EQU 0F886h

GLOBAL asm_lock_try
asm_lock_try                    EQU 0F88Bh

GLOBAL asm_lock_try_fastcall
asm_lock_try_fastcall           EQU 0F88Fh

GLOBAL asm_lock_give
asm_lock_give                   EQU 0F897h

GLOBAL asm_lock_give_fastcall
asm_lock_give_fastcall          EQU 0F89Bh

GLOBAL asm_am9511a_isr
asm_am9511a_isr                 EQU 0F8CDh

GLOBAL asm_am9511a_reset
asm_am9511a_reset               EQU 0F9ABh

GLOBAL asm_am9511a_chk_idle
asm_am9511a_chk_idle            EQU 0FA05h

GLOBAL asm_am9511a_opp
asm_am9511a_opp                 EQU 0FA1Ch

GLOBAL asm_am9511a_cmd
asm_am9511a_cmd                 EQU 0FA58h

GLOBAL asm_asci0_init
asm_asci0_init                  EQU 0FACCh

GLOBAL asm_asci0_flush_Rx_di
asm_asci0_flush_Rx_di           EQU 0FAE6h

GLOBAL asm_asci0_flush_Tx_di
asm_asci0_flush_Tx_di           EQU 0FAFEh

GLOBAL asm_asci0_reset
asm_asci0_reset                 EQU 0FB16h

GLOBAL asm_asci0_getc
asm_asci0_getc                  EQU 0FB20h

GLOBAL asm_asci0_peekc
asm_asci0_peekc                 EQU 0FB36h

GLOBAL asm_asci0_pollc
asm_asci0_pollc                 EQU 0FB42h

GLOBAL asm_asci0_putc
asm_asci0_putc                  EQU 0FB4Ah

GLOBAL asm_asci1_init
asm_asci1_init                  EQU 0FBE9h

GLOBAL asm_asci1_flush_Rx_di
asm_asci1_flush_Rx_di           EQU 0FC03h

GLOBAL asm_asci1_flush_Tx_di
asm_asci1_flush_Tx_di           EQU 0FC1Bh

GLOBAL asm_asci1_reset
asm_asci1_reset                 EQU 0FC33h

GLOBAL asm_asci1_getc
asm_asci1_getc                  EQU 0FC3Dh

GLOBAL asm_asci1_peekc
asm_asci1_peekc                 EQU 0FC53h

GLOBAL asm_asci1_pollc
asm_asci1_pollc                 EQU 0FC5Fh

GLOBAL asm_asci1_putc
asm_asci1_putc                  EQU 0FC67h

GLOBAL asm_ide_read_sector
asm_ide_read_sector             EQU 0FDADh

GLOBAL asm_ide_write_sector
asm_ide_write_sector            EQU 0FDDDh

GLOBAL asm_phexwd
asm_phexwd                      EQU 0FE14h

GLOBAL asm_phex
asm_phex                        EQU 0FE1Eh

GLOBAL asm_pchar
asm_pchar                       EQU 0FE31h

GLOBAL asm_pstring
asm_pstring                     EQU 0FE0Ah

GLOBAL asm_rhex
asm_rhex                        EQU 0FE3Bh

