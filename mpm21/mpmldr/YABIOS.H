
#ifndef __YABIOS_H__
#define __YABIOS_H__

#include <stddef.h>

/* GLOBAL VARIABLES */

/* provide the location for stack pointers to be stored */

extern uint16_t *bios_sp;       /* yabios SP here when other banks running */
extern uint16_t *bank_sp;       /* bank SP storage, in Page0 TCB 0x003B */

/* provide the simple mutex locks for hardware resources */

extern uint8_t shadowLock;      /*  mutex for alternate registers */
extern uint8_t prt0Lock;        /*  mutex for PRT0 */
extern uint8_t prt1Lock;        /*  mutex for PRT1 */
extern uint8_t dmac0Lock;       /*  mutex for DMAC0 */
extern uint8_t dmac1Lock;       /*  mutex for DMAC1 */
extern uint8_t csioLock;        /*  mutex for CSI/O */

extern uint8_t asci0RxLock;     /*  mutex for Rx0 */
extern uint8_t asci0TxLock;     /*  mutex for Tx0 */
extern uint8_t asci1RxLock;     /*  mutex for Rx1 */
extern uint8_t asci1TxLock;     /*  mutex for Tx1 */

extern uint8_t APULock;         /*  mutex for APU */

/* provide the simple mutex locks for the BANK (for system usage) */

extern uint8_t bankLockBase[];  /* base address for 16 BANK locks */


/* SYSTEM FUNCTIONS */

/* provide methods to get, try, and give the simple mutex locks */

extern void lock_get(uint8_t * mutex);
extern uint8_t lock_try(uint8_t * mutex);
extern void lock_give(uint8_t * mutex);

/* provide bank relative address functions */

extern int8_t bank_get_rel(uint8_t bankAbs);
extern uint8_t bank_get_abs(int8_t bankRel);

/* provide memcpy_far function */

extern void *memcpy_far(void *str1, int8_t bank1, void *str2, int8_t bank2, size_t n);

/* provide memcpy_far function */

extern void jp_far(void *str, int8_t bank);


#endif
