
#include <stddef.h>

/* SYSTEM FUNCTIONS */

/* provide methods to get, try, and give the simple mutex locks */
void lock_get(uint8_t * mutex);
uint8_t lock_try(uint8_t * mutex);
void lock_give(uint8_t * mutex);

/* provide bank relative address functions */
int8_t bank_get_rel(uint8_t bankAbs);
uint8_t bank_get_abs(int8_t bankRel);

/* provide memcpy_far function */
void *memcpy_far( void *str_dest, char bank_dest, void *str_src, char bank_src, size_t n);

/* provide memcpy_far function */
void jp_far( void *str, int8_t bank);


/*------------------------------------------------------------------------------
 * void lock_get(uint8_t * mutex)
 *
 * mutex − This is a pointer to a simple mutex semaphore
 *
 */

void lock_get(mutex)
uint8_t * mutex;
{
#asm
    global asm_lock_get_fastcall
    ld h,(ix+6+1)
    ld l,(ix+6+0)
    call asm_lock_get_fastcall
#endasm
    return;
}


/*------------------------------------------------------------------------------
 * uint8_t lock_try(uint8_t * mutex)
 *
 * mutex − This is a pointer to a simple mutex semaphore
 *
 * This function returns 1 if it got the lock, 0 otherwise
 *
 */

uint8_t lock_try(mutex)
uint8_t * mutex;
{
    register uint8_t ret;
#asm
    global asm_lock_try_fastcall
    ld h,(ix+6+1)
    ld l,(ix+6+0)
    call asm_lock_try_fastcall
    push hl
    pop iy
#endasm
    return ret;
}


/*------------------------------------------------------------------------------
 * void lockGive(uint8_t * mutex)
 *
 * mutex − This is a pointer to a simple mutex semaphore
 *
 */

void lockGive(mutex)
uint8_t * mutex;
{
#asm
    global asm_lock_give_fastcall
    ld h,(ix+6+1)
    ld l,(ix+6+0)
    call asm_lock_give_fastcall
#endasm
    return;
}


/*------------------------------------------------------------------------------
 * int8_t bank_get_rel(uint8_t bankAbs)
 *
 * bankAbs − This is the absolute bank address
 *
 * Returns the relative bank address
 *
 */

int8_t bank_get_rel(bankAbs)
uint8_t bankAbs;
{
    register int8_t bank;
#asm
    global asm_bank_get_rel_fastcall
    ld l,(ix+6+0)
    call asm_bank_get_rel_fastcall
    push hl
    pop iy
#endasm
    return bank;
}


/*------------------------------------------------------------------------------
 * uint8_t bank_get_abs(int8_t bankRel)
 *
 * bankRel − This is the relative bank address (-128 to +127)
 *
 * Returns the capped absolute bank address (0 to 15)
 *
 */

uint8_t bank_get_abs(bankRel)
int8_t bankRel;
{
    register uint8_t bank;
#asm
    global asm_bank_get_abs_fastcall
    ld l,(ix+6+0)
    call asm_bank_get_abs_fastcall
    push hl
    pop iy
#endasm
    return bank;
}


/*------------------------------------------------------------------------------
 * void *memcpy_far(void *str1, int8_t bank1, const void *str2, const int8_t bank2, size_t n)
 *
 * str1 − This is a pointer to the destination array where the content is to be
 *       copied, type-cast to a pointer of type void*.
 * bank1− This is the destination bank, relative to the current bank.
 * str2 − This is a pointer to the source of data to be copied,
 *       type-cast to a pointer of type const void*.
 * bank2− This is the source bank, relative to the current bank.
 * n    − This is the number of bytes to be copied.
 * 
 * This function returns a void* to destination, which is str1, in HL.
 *
 * stack:
 *   n high
 *   n low
 *   bank2 far
 *   str2 high
 *   str2 low
 *   bank1 far
 *   str1 high
 *   str1 low
 *   ret high
 *   ret low
 *
 */

void *memcpy_far(str_dest, bank_dest, str_src, bank_src, n)
void *str_dest;
char bank_dest;
void *str_src;
char bank_src;
size_t n;
{
    register void * addr;
#asm
    global asm_memcpy_far
    ld h,(ix+6+9)    
    ld l,(ix+6+8)
    push hl
    ld h,(ix+6+6)
    push hl
    inc sp
    ld h,(ix+6+5)
    ld l,(ix+6+4)
    push hl
    ld h,(ix+6+2)
    push hl
    inc sp
    ld h,(ix+6+1)
    ld l,(ix+6+0)
    push hl
    call asm_memcpy_far
    push hl
    pop iy
#endasm
    return addr;
}


/*------------------------------------------------------------------------------
 * void jp_far(void *str, int8_t bank)
 *
 * str − This is a pointer to the destination address to which we will jump,
 *       type-cast to a pointer of type void*.
 * bank− This is the destination bank, relative to the current bank.
 *
 * This function returns a void.
 *
 * stack:
 *   bank far
 *   str high
 *   str low
 *   ret high
 *   ret low
 *
 */

void jp_far(str, bank)
void *str;
int8_t bank;
{
#asm
    global asm_jp_far
    ld h,(ix+6+2)
    push hl
    inc sp
    ld h,(ix+6+1)
    ld l,(ix+6+0)
    push hl
    call asm_jp_far
#endasm
    return;
}

