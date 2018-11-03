
PUBLIC  _cpm_iobyte
PUBLIC  _cpm_cdisk
PUBLIC  _cpm_bdos
PUBLIC  _cpm_ccp_tfcb
PUBLIC  _cpm_ccp_tbuff
PUBLIC  _cpm_ccp_tbase

_cpm_iobyte:    EQU 0003h   ;intel I/O byte
_cpm_cdisk:     EQU 0004h   ;address of current disk number 0=a,... 15=p
_cpm_bdos:      EQU 0005h   ;jump to BDOS
_cpm_ccp_tfcb:  EQU 005Ch   ;default file control block
_cpm_ccp_tbuff: EQU 0080h   ;i/o buffer and command line storage
_cpm_ccp_tbase: EQU 0100h   ;transient program storage area

PUBLIC  _cpm_dsk0_base
PUBLIC  _cpm_src_bank

_cpm_dsk0_base: EQU 0040h   ;base 32 bit LBA of host file for disk 0 (A:) &
                            ;   3 additional LBA for host files (B:, C:, D:)
_cpm_src_bank:  EQU 0050h   ;source bank for CP/M CCP/BDOS for warm boot

END

