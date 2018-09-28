
#ifndef __YAZ180_H__
#define __YAZ180_H__

/* YAZ180 Hardware */

#define __YAZ180  1

#define __CPU_CLOCK  36864000

#define __IO_BASE_ADDRESS 0x0

#define __BIOS_SP   0xFFDE
#define __BANK_SP   0x003B

#define __COMMON_AREA_1_BASE  0xF000
#define __COMMON_AREA_1_PHASE_DATA  0xf000
#define __COMMON_AREA_1_PHASE_DRIVER  0xf580

#define __ASCI0_RX_SIZE  0x100
#define __ASCI0_TX_SIZE  0x080

#define __ASCI1_RX_SIZE  0x100
#define __ASCI1_TX_SIZE  0x080

#define __IO_BREAK  0x2000

#define __IO_PIO_PORT_BASE  0x4000

#define __IO_PCA9665_1_PORT_BASE  0xA000
#define __IO_PCA9665_2_PORT_BASE  0x8000

#define __APU_CMD_SIZE  0x100
#define __APU_PTR_SIZE  0x100

#define __IO_APU_PORT_BASE  0xC000

/* Z180 */

#undef  __Z180
#define __Z180  0x04

#define __Z180_Z80180  0x01
#define __Z180_Z8L180  0x02
#define __Z180_Z8S180  0x04

#define __CPU_INFO  0x00

#define __CPU_INFO_ENABLE_SLL  0x01

#define __CPU_TIMER_SCALE  20

/* Z8S180 / Z8L180 CLASS */

#define __IO_CNTLA0  0x0
#define __IO_CNTLA1  0x1
#define __IO_CNTLB0  0x2
#define __IO_CNTLB1  0x3
#define __IO_STAT0  0x4
#define __IO_STAT1  0x5
#define __IO_TDR0  0x6
#define __IO_TDR1  0x7
#define __IO_RDR0  0x8
#define __IO_RDR1  0x9
#define __IO_ASEXT0  0x12
#define __IO_ASEXT1  0x13
#define __IO_ASTC0L  0x1a
#define __IO_ASTC0H  0x1b
#define __IO_ASTC1L  0x1c
#define __IO_ASTC1H  0x1d

#define __IO_CNTR  0xa
#define __IO_TRDR  0xb

#define __IO_TMDR0L  0xc
#define __IO_TMDR0H  0xd
#define __IO_RLDR0L  0xe
#define __IO_RLDR0H  0xf
#define __IO_TCR  0x10
#define __IO_TMDR1L  0x14
#define __IO_TMDR1H  0x15
#define __IO_RLDR1L  0x16
#define __IO_RLDR1H  0x17

#define __IO_FRC  0x18
#define __IO_CMR  0x1e
#define __IO_CCR  0x1f

#define __IO_SAR0L  0x20
#define __IO_SAR0H  0x21
#define __IO_SAR0B  0x22
#define __IO_DAR0L  0x23
#define __IO_DAR0H  0x24
#define __IO_DAR0B  0x25
#define __IO_BCR0L  0x26
#define __IO_BCR0H  0x27
#define __IO_MAR1L  0x28
#define __IO_MAR1H  0x29
#define __IO_MAR1B  0x2a
#define __IO_IAR1L  0x2b
#define __IO_IAR1H  0x2c
#define __IO_IAR1B  0x2d
#define __IO_BCR1L  0x2e
#define __IO_BCR1H  0x2f
#define __IO_DSTAT  0x30
#define __IO_DMODE  0x31
#define __IO_DCNTL  0x32

#define __IO_IL  0x33
#define __IO_ITC  0x34

#define __IO_RCR  0x36

#define __IO_CBR  0x38
#define __IO_BBR  0x39
#define __IO_CBAR  0x3a

#define __IO_OMCR  0x3e
#define __IO_ICR  0x3f

/* I/O REGISTER BIT FIELDS */

#define __IO_CNTLA0_MPE   0x80
#define __IO_CNTLA0_RE   0x40
#define __IO_CNTLA0_TE   0x20
#define __IO_CNTLA0_RTS0   0x10
#define __IO_CNTLA0_MPBR   0x08
#define __IO_CNTLA0_EFR   0x08
#define __IO_CNTLA0_MODE_MASK   0x07
#define __IO_CNTLA0_MODE_8P2   0x07
#define __IO_CNTLA0_MODE_8P1   0x06
#define __IO_CNTLA0_MODE_8N2   0x05
#define __IO_CNTLA0_MODE_8N1   0x04
#define __IO_CNTLA0_MODE_7P2   0x03
#define __IO_CNTLA0_MODE_7P1   0x02
#define __IO_CNTLA0_MODE_7N2   0x01
#define __IO_CNTLA0_MODE_7N1   0x00

#define __IO_CNTLA1_MPE   0x80
#define __IO_CNTLA1_RE   0x40
#define __IO_CNTLA1_TE   0x20
#define __IO_CNTLA1_CKA1D   0x10
#define __IO_CNTLA1_MPBR   0x08
#define __IO_CNTLA1_EFR   0x08
#define __IO_CNTLA1_MODE_MASK   0x07
#define __IO_CNTLA1_MODE_8P2   0x07
#define __IO_CNTLA1_MODE_8P1   0x06
#define __IO_CNTLA1_MODE_8N2   0x05
#define __IO_CNTLA1_MODE_8N1   0x04
#define __IO_CNTLA1_MODE_7P2   0x03
#define __IO_CNTLA1_MODE_7P1   0x02
#define __IO_CNTLA1_MODE_7N2   0x01
#define __IO_CNTLA1_MODE_7N1   0x00

#define __IO_CNTLB0_MPBT   0x80
#define __IO_CNTLB0_MP   0x40
#define __IO_CNTLB0_CTS   0x20
#define __IO_CNTLB0_PS   0x20
#define __IO_CNTLB0_PEO   0x10
#define __IO_CNTLB0_DR   0x08
#define __IO_CNTLB0_SS_MASK   0x07
#define __IO_CNTLB0_SS_EXT   0x07
#define __IO_CNTLB0_SS_DIV_64   0x06
#define __IO_CNTLB0_SS_DIV_32   0x05
#define __IO_CNTLB0_SS_DIV_16   0x04
#define __IO_CNTLB0_SS_DIV_8   0x03
#define __IO_CNTLB0_SS_DIV_4   0x02
#define __IO_CNTLB0_SS_DIV_2   0x01
#define __IO_CNTLB0_SS_DIV_1   0x00

#define __IO_CNTLB1_MPBT   0x80
#define __IO_CNTLB1_MP   0x40
#define __IO_CNTLB1_CTS   0x20
#define __IO_CNTLB1_PS   0x20
#define __IO_CNTLB1_PEO   0x10
#define __IO_CNTLB1_DR   0x08
#define __IO_CNTLB1_SS_MASK   0x07
#define __IO_CNTLB1_SS_EXT   0x07
#define __IO_CNTLB1_SS_DIV_64   0x06
#define __IO_CNTLB1_SS_DIV_32   0x05
#define __IO_CNTLB1_SS_DIV_16   0x04
#define __IO_CNTLB1_SS_DIV_8   0x03
#define __IO_CNTLB1_SS_DIV_4   0x02
#define __IO_CNTLB1_SS_DIV_2   0x01
#define __IO_CNTLB1_SS_DIV_1   0x00

#define __IO_STAT0_RDRF   0x80
#define __IO_STAT0_OVRN   0x40
#define __IO_STAT0_PE   0x20
#define __IO_STAT0_FE   0x10
#define __IO_STAT0_RIE   0x08
#define __IO_STAT0_DCD0   0x04
#define __IO_STAT0_TDRE   0x02
#define __IO_STAT0_TIE   0x01

#define __IO_STAT1_RDRF   0x80
#define __IO_STAT1_OVRN   0x40
#define __IO_STAT1_PE   0x20
#define __IO_STAT1_FE   0x10
#define __IO_STAT1_RIE   0x08
#define __IO_STAT1_CTS1E   0x04
#define __IO_STAT1_TDRE   0x02
#define __IO_STAT1_TIE   0x01

#define __IO_CNTR_EF   0x80
#define __IO_CNTR_EIE   0x40
#define __IO_CNTR_RE   0x20
#define __IO_CNTR_TE   0x10
#define __IO_CNTR_SS_MASK   0x07
#define __IO_CNTR_SS_EXT   0x07
#define __IO_CNTR_SS_DIV_1280   0x06
#define __IO_CNTR_SS_DIV_640   0x05
#define __IO_CNTR_SS_DIV_320   0x04
#define __IO_CNTR_SS_DIV_160   0x03
#define __IO_CNTR_SS_DIV_80   0x02
#define __IO_CNTR_SS_DIV_40   0x01
#define __IO_CNTR_SS_DIV_20   0x00

/* PRT REGISTER BIT FIELDS */

#define __IO_TCR_TIF1    0x80
#define __IO_TCR_TIF0    0x40
#define __IO_TCR_TIE1    0x20
#define __IO_TCR_TIE0    0x10
#define __IO_TCR_TOC1    0x08
#define __IO_TCR_TOC0    0x04
#define __IO_TCR_TDE1    0x02
#define __IO_TCR_TDE0    0x01

/* DMA REGISTER BIT FIELDS */

#define __IO_DSTAT_DE1    0x80
#define __IO_DSTAT_DE0    0x40
#define __IO_DSTAT_DWE1   0x20
#define __IO_DSTAT_DWE0   0x10
#define __IO_DSTAT_DIE1   0x08
#define __IO_DSTAT_DIE0   0x04
#define __IO_DSTAT_DME    0x01

#define __IO_DMODE_DM1    0x20
#define __IO_DMODE_DM0    0x10
#define __IO_DMODE_SM1    0x08
#define __IO_DMODE_SM0    0x04
#define __IO_DMODE_MMOD   0x02

#define __IO_DCNTL_MWI1   0x80
#define __IO_DCNTL_MWI0   0x40
#define __IO_DCNTL_IWI1   0x20
#define __IO_DCNTL_IWI0   0x10
#define __IO_DCNTL_DMS1   0x08
#define __IO_DCNTL_DMS0   0x04
#define __IO_DCNTL_DIM1   0x02
#define __IO_DCNTL_DIM0   0x01

/* INT/TRAP CONTROL REGISTER (ITC) BIT FIELDS */

#define __IO_ITC_TRAP   0x80
#define __IO_ITC_UFO   0x40
#define __IO_ITC_ITE2   0x04
#define __IO_ITC_ITE1   0x02
#define __IO_ITC_ITE0   0x01

/* Refresh CONTROL REGISTER (RCR) BIT FIELDS */

#define __IO_RCR_REFE   0x80
#define __IO_RCR_REFW   0x40
#define __IO_RCR_CYC1   0x02
#define __IO_RCR_CYC0   0x01

/* Operation Mode CONTROL REGISTER (OMCR) BIT FIELDS */

#define __IO_OMCR_M1E   0x80
#define __IO_OMCR_M1TE   0x40
#define __IO_OMCR_IOC   0x20

/* CPU CLOCK MULTIPLIER REGISTER (CMR) BIT FIELDS (Z8S180 & higher Only) */

#define __IO_CMR_X2   0x80
#define __IO_CMR_LN_XTAL   0x40

/* CPU CONTROL REGISTER (CCR) BIT FIELDS (Z8S180 & higher Only) */

#define __IO_CCR_XTAL_X2   0x80
#define __IO_CCR_STANDBY   0x40
#define __IO_CCR_BREXT   0x20
#define __IO_CCR_LNPHI   0x10
#define __IO_CCR_IDLE   0x08
#define __IO_CCR_LNIO   0x04
#define __IO_CCR_LNCPUCTL   0x02
#define __IO_CCR_LNAD   0x01

#endif
