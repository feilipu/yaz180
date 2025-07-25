; address = 0x0000
; must decide if this is a power on reset or a trap

   jp __Test_Trap       ; jump to the start of the trap test at 0x0080

   PUBLIC _bank_cpm_iobyte
   PUBLIC _bank_cpm_default_drive

   _bank_cpm_iobyte:        defb $00
   _bank_cpm_default_drive: defb $00

   PUBLIC _bank_cpm_bdos_addr

   jp __Start       ; main entry to the CP/M BDOS when in banked page0

   defc _bank_cpm_bdos_addr = ASMPC - 2

; address = 0x0008

   ALIGN 0x0008

IF ((__crt_enable_rst & $0202) = $02)

   EXTERN _z180_rst_08h
   jp     _z180_rst_08h

ELSE

   IF ((__crt_enable_rst & $0202) = $0202)

   jp     __z180_rst_08h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $0202) != $0202)

   PUBLIC _z180_rst_08h_vector
   defc   _z180_rst_08h_vector = $09
      
ENDIF

; address = 0x0010

   ALIGN 0x0010

IF ((__crt_enable_rst & $0404) = $04)

   EXTERN _z180_rst_10h
   jp     _z180_rst_10h

ELSE

   IF ((__crt_enable_rst & $0404) = $0404)

   jp     __z180_rst_10h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $0404) != $0404)
   
   PUBLIC _z180_rst_10h_vector
   defc   _z180_rst_10h_vector = $11

ENDIF

; address = 0x0018

   ALIGN 0x0018

IF ((__crt_enable_rst & $0808) = $08)

   EXTERN _z180_rst_18h
   jp     _z180_rst_18h

ELSE

   IF ((__crt_enable_rst & $0808) = $0808)

   jp     __z180_rst_18h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $0808) != $0808)
   
   PUBLIC _z180_rst_18h_vector
   defc   _z180_rst_18h_vector = $19
      
ENDIF

; address = 0x0020

   ALIGN 0x0020

IF ((__crt_enable_rst & $1010) = $10)

   EXTERN _z180_rst_20h
   jp     _z180_rst_20h

ELSE

   IF ((__crt_enable_rst & $1010) = $1010)

   jp     __z180_rst_20h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $1010) != $1010)

   PUBLIC _z180_rst_20h_vector
   defc   _z180_rst_20h_vector = $21

ENDIF

; address = 0x0028

   ALIGN 0x0028

IF ((__crt_enable_rst & $2020) = $20)

   EXTERN _z180_rst_28h
   jp     _z180_rst_28h

ELSE

   IF ((__crt_enable_rst & $2020) = $2020)

   jp     __z180_rst_28h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $2020) != $2020)

   PUBLIC _z180_rst_28h_vector
   defc   _z180_rst_28h_vector = $29

ENDIF

; address = 0x0030

   ALIGN 0x0030

IF ((__crt_enable_rst & $4040) = $40)

   EXTERN _z180_rst_30h
   jp     _z180_rst_30h

ELSE

   IF ((__crt_enable_rst & $4040) = $4040)

   jp     __z180_rst_30h

   ELSE

   jp     l_ret

   ENDIF

ENDIF

IF ((__crt_enable_rst & $4040) != $4040)

   PUBLIC _z180_rst_30h_vector
   defc   _z180_rst_30h_vector = $31
      
ENDIF


; address = 0x0038
; im 1 isr

   ALIGN 0x0038

IF ((__crt_enable_rst & $8080) = $80)

   EXTERN _z180_rst_38h
   jp     _z180_rst_38h

ELSE

   IF ((__crt_enable_rst & $8080) = $8080)

   jp     __z180_rst_38h

   ELSE

   jp     l_ei_reti

   ENDIF

ENDIF

IF ((__crt_enable_rst & $8080) != $8080)
   
   PUBLIC _z180_rst_38h_vector
   defc   _z180_rst_38h_vector = $39

ENDIF


; address = 0x0066

   ALIGN 0x0066

IF (__crt_enable_nmi = 1)

   EXTERN _z180_nmi
   jp     _z180_nmi

ELSE

   IF (__crt_enable_nmi > 1)

   jp     __z180_nmi

   ELSE

   retn

   ENDIF

ENDIF

IF (__crt_enable_nmi <= 1)

   PUBLIC _z180_nmi_vector
   defc   _z180_nmi_vector = $67

ENDIF

; address = 0x0080

   ALIGN 0x0080

__Test_Trap:

   ld a,__IO_BASE_ADDRESS
   out0 (0x3f),a        ; out0 (ICR),a

   in0 a,(ITC)
   xor $80

IF (__crt_enable_trap = 1)

   EXTERN _z180_trap
   call P,_z180_trap

ELSE

   IF (__crt_enable_trap > 1)

   EXTERN __z180_trap
   call P,__z180_trap

   ENDIF

ENDIF

__reset:

   include "../crt_start_di.inc"

IF (REGISTER_SP = -1)

   pop af

ENDIF

IF (__crt_org_vector_table = 0)

   ld a,__IO_VECTOR_BASE
   out0 (IL),a

ENDIF

; now jump down to __Start at 0x0100

   jp __Start

; address = 0x0100

   ALIGN 0x0100

   defc __page_zero_present = 1
