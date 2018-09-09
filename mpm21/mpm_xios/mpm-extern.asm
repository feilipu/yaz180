
PUBLIC  _cpm_iobyte
PUBLIC  _cpm_cdisk
PUBLIC  _cpm_bdos
PUBLIC  _cpm_ccp_tfcb
PUBLIC  _cpm_ccp_tbuff
PUBLIC  _cpm_ccp_tbase

DEFC    _cpm_iobyte     =   $0003   ;intel I/O byte
DEFC    _cpm_cdisk      =   $0004   ;address of current disk number 0=a,... 15=p
DEFC    _cpm_bdos       =   $0005   ;jump to BDOS
DEFC    _cpm_ccp_tfcb   =   $005C   ;default file control block
DEFC    _cpm_ccp_tbuff  =   $0080   ;i/o buffer and command line storage
DEFC    _cpm_ccp_tbase  =   $0100   ;transient program storage area

PUBLIC  _cpm_dsk0_base
PUBLIC  _cpm_src_bank

DEFC    _cpm_dsk0_base  =   $0040   ;base 32 bit LBA of host file for disk 0 (A:) &
                                    ;3 additional LBA for host files (B:, C:, D:)
DEFC    _cpm_src_bank   =   $0050   ;source bank for CP/M CCP/BDOS for warm boot

END
