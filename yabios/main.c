/***************************************************************************//**

  @file         main.c
  @author       Phillip Stevens, inspired by Stephen Brennan
  @brief        YASH (Yet Another SHell)

  This programme reached working state on Melbourne Cup Day, 2017.

*******************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <arch.h>
#include <arch/yaz180.h>

#include <time.h>
#include <sys/time.h>
#include <lib/yaz180/time.h>

#include "ffconf.h"
#include <lib/yaz180/ff.h>
#include <arch/yaz180/diskio.h>

// PRAGMAS

#pragma output REGISTER_SP             = 0xFFDE // __BIOS_SP
#pragma output CRT_ENABLE_RST          = 0x00FE
#pragma output CRT_ENABLE_TRAP         = 1

#pragma output CLIB_MALLOC_HEAP_SIZE   = 9984   // 0x2700 measured maximum free

// DEFINES

#define MAX_FILES 2             // number of files open at any time
#define BUFFER_SIZE 1024        // size of working buffer (on heap)
#define LINE_SIZE 256           // size of a command line (on heap)

#define PAGE0_SIZE 0x0100       // size of a Page0 copy buffer (on heap)

// GLOBALS

static void * buffer;           /* create a scratch buffer on heap later */

static FATFS *fs;               /* Pointer to the filesystem object (on heap) */
static DIR *dir;                /* Pointer to the directory object (on heap) */

static FILINFO Finfo;           /* File Information */
static FIL File[MAX_FILES];     /* File object needed for each open file */

static uint32_t driveLBAbase[4];/* Base of CPM drive files */

static FILE *input;             /* defined input */
static FILE *output;            /* defined output */
static FILE *error;             /* defined output */

static uint8_t directoryBlock[32] = {0xE5,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20, \
                                            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

// EXTERNAL FUNCTIONS

#if __SCCZ80

extern void exit_far(void) __smallc;

extern uint8_t asci0_flush_Rx(void) __smallc;   // Rx0 flush routine
extern uint8_t asci0_pollc(void) __smallc;      // Rx0 polling routine, checks Rx0 buffer fullness
extern uint8_t asci0_getc(void) __smallc;       // Rx0 receive routine, from Rx0 buffer
extern uint8_t asci1_flush_Rx(void) __smallc;   // Rx1 flush routine
extern uint8_t asci1_pollc(void) __smallc;      // Rx1 polling routine, checks Rx1 buffer fullness
extern uint8_t asci1_getc(void) __smallc;       // Rx1 receive routine, from Rx1 buffer

#elif __SDCC

extern void exit_far(void) __preserves_regs(b,c,d,e,h,l,iyl,iyh);

extern uint8_t asci0_flush_Rx(void) __preserves_regs(b,c,d,e,iyl,iyh);  // Rx0 flush routine
extern uint8_t asci0_pollc(void) __preserves_regs(b,c,d,e,iyl,iyh);     // Rx0 polling routine, checks Rx0 buffer fullness
extern uint8_t asci0_getc(void) __preserves_regs(b,c,d,e,iyl,iyh);      // Rx0 receive routine, from Rx0 buffer
extern uint8_t asci1_flush_Rx(void) __preserves_regs(b,c,d,e,iyl,iyh);  // Rx1 flush routine
extern uint8_t asci1_pollc(void) __preserves_regs(b,c,d,e,iyl,iyh);     // Rx1 polling routine, checks Rx1 buffer fullness
extern uint8_t asci1_getc(void) __preserves_regs(b,c,d,e,iyl,iyh);      // Rx1 receive routine, from Rx1 buffer

#endif

/*
  Function Declarations for built-in shell commands:
 */

// CP/M related functions
int8_t ya_mkcpmb(char **args);  // initialise CP/M bank with up to 4 drives
int8_t ya_mkcpmd(char **args);  // create a FATFS file for CP/M drive

// bank related functions
int8_t ya_mkb(char **args);     // initialise the nominated bank (to warm state)
int8_t ya_cpb(char **args);     // copy or clone the nominated bank
int8_t ya_rmb(char **args);     // remove the nominated bank (to cold state)
int8_t ya_lsb(char **args);     // list the usage of banks, and whether they are cold, warm, or hot
int8_t ya_initb(char **args);   // jump to and begin executing the nominated bank at nominated address
int8_t ya_loadh(char **args);   // load the nominated bank with intel hex from asci0/1
int8_t ya_loadb(char **args);   // load the nominated bank and address with binary code
int8_t ya_saveb(char **args);   // save the nominated bank from 0x0100 to 0xF000 by default

// system related functions
int8_t ya_md(char **args);      // memory dump
int8_t ya_help(char **args);    // help
int8_t ya_exit(char **args);    // exit and restart

// fat related functions
int8_t ya_ls(char **args);      // directory listing
int8_t ya_rm(char **args);      // delete a file
int8_t ya_cp(char **args);      // copy a file
int8_t ya_mv(char **args);      // move (rename) a file
int8_t ya_cd(char **args);      // change the current working directory
int8_t ya_pwd(char **args);     // show the current working directory
int8_t ya_mkdir(char **args);   // create a new directory
int8_t ya_chmod(char **args);   // change file or directory attributes
int8_t ya_mkfs(char **args);    // create a FAT file system
int8_t ya_mount(char **args);   // mount a FAT file system

// disk related functions
int8_t ya_ds(char **args);      // disk status
int8_t ya_dd(char **args);      // disk dump sector

// time related functions
int8_t ya_clock(char **args);   // set the time (UNIX epoch)
int8_t ya_tz(char **args);      // set timezone (no daylight savings, so adjust manually)
int8_t ya_diso(char **args);    // print the local time in ISO: 2013-03-23 01:03:52
int8_t ya_date(char **args);    // print the local time in US: Sun Mar 23 01:03:52 2013

// helper functions
static void put_rc (FRESULT rc);        // print error codes to defined error IO
static void put_dump (const uint8_t *buff, uint32_t ofs, uint8_t cnt);

/*
  List of builtin commands.
 */

struct Builtin {
  const char *name;
  int8_t (*func) (char** args);
  const char *help;
};

struct Builtin builtins[] = {
  // CP/M related functions
    { "mkcpmb", &ya_mkcpmb, "[src][dest][file][][][] - initialise dest bank for CP/M from src, 4 drive files"},
    { "mkcpmd", &ya_mkcpmd, "[file][dir][bytes] - create a drive file for CP/M, dir entries, of bytes size"},

  // bank related functions
    { "mkb", &ya_mkb, "[bank] - initialise the nominated bank (to warm state)"},
    { "cpb", &ya_cpb, "[src][dest] - copy or clone the nominated bank"},
    { "rmb", &ya_rmb, "[bank] - remove the nominated bank (to cold state)"},
    { "lsb", &ya_lsb, "- list the usage of banks, and whether they are cold, warm, or hot"},
    { "initb", &ya_initb, "[bank][origin] - begin executing the nominated bank at nominated address"},
    { "loadh", &ya_loadh, "[bank] - load the nominated bank with intel hex"},
    { "loadb", &ya_loadb, "[path][bank][origin] - load the nominated bank from origin with binary code"},
    { "saveb", &ya_saveb, "[bank][path] - save the nominated bank from 0x0100 to 0xF000"},

// system related functions
    { "md", &ya_md, "- [bank][origin] - memory dump"},
    { "help", &ya_help, "- this is it"},
    { "exit", &ya_exit, "- exit and restart"},

// fat related functions
    { "mount", &ya_mount, "[option] - mount a FAT file system"},
    { "ls", &ya_ls, "[path] - directory listing"},
    { "rm", &ya_rm, "[file] - delete a file"},
    { "cp", &ya_cp, "[src][dest] - copy a file"},
    { "mv", &ya_mv, "[src][dest] - move (rename) a file"},
    { "cd", &ya_cd, "[path] - change the current working directory"},
    { "pwd", &ya_pwd, "- show the current working directory"},
    { "mkdir", &ya_mkdir, "[path] - create a new directory"},
    { "chmod", &ya_chmod, "[path][attr][mask] - change file or directory attributes"},
    { "mkfs", &ya_mkfs, "[type][block size] - create a FAT file system (excluded)"},

// disk related functions
    { "ds", &ya_ds, " - disk status"},
    { "dd", &ya_dd, "[sector] - disk dump, sector in decimal"},

// time related functions
    { "clock", &ya_clock, "[timestamp] - set the time (UNIX epoch) 'date +%s'"},
    { "tz", &ya_tz, "[tz] - set timezone (no daylight saving)"},
    { "diso", &ya_diso, "- local time ISO format: 2013-03-23 01:03:52"},
    { "date", &ya_date, "- local time: Sun Mar 23 01:03:52 2013" }
};

uint8_t ya_num_builtins() {
  return sizeof(builtins) / sizeof(struct Builtin);
}


/*
  Builtin function implementations.
*/


// CP/M related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mkcpmb".  args[1] is the source bank.  args[2] is the CP/M destination bank.
                              args[3][4][5][6] are names of drive files.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkcpmb(char **args)   // initialise CP/M bank with up to 4 drives
{
    FRESULT res;
    uint8_t * page0Template;
    uint8_t srcBank;
    uint8_t destBank;
    uint8_t i = 0;

    if (args[1] == NULL || args[2] == NULL || args[3] == NULL) {
        fprintf(output, "yash: expected 3 arguments to \"mkcpmb\"\n");
    } else {
        page0Template = (uint8_t *)malloc(sizeof(uint8_t)*PAGE0_SIZE);  /* Get work area for the Page 0 */

        if (page0Template != NULL && args[1] != NULL && args[2] != NULL)
        {
            srcBank = bank_get_abs((int8_t)atoi(args[1]));
            destBank = bank_get_abs((int8_t)atoi(args[2]));

            memcpy( page0Template, (uint8_t *)0x0000, PAGE0_SIZE ); // copy the existing ROM Page0 to our working space
            // existing RST0 trap code is contained in this space at 0x0080, and jumps to __Start at 0x0100.

            // set the new bank SP to point to top of BANKnn for _jp_far(), _bank_sp = 0x003B
            *(volatile uint16_t*)(page0Template + (uint16_t)&bank_sp) = __COMMON_AREA_1_BASE;

            // set up (up to 4) CPM drive LBA locations, before copying to Page 0 template
            while(args[i+3] != NULL)
            {
                fprintf(output,"Opening \"%s\"", args[i+3]);
                res = f_open(&File[0], (const TCHAR *)args[i+3], FA_OPEN_EXISTING | FA_READ);
                if (res != FR_OK) { put_rc(res); return 1; }
                driveLBAbase[i] = (&File[0])->obj.fs->database + ((&File[0])->obj.fs->csize * ((&File[0])->obj.sclust - 2));
                fprintf(output," at LBA %lu\n", driveLBAbase[i]);
                f_close(&File[0]);
                ++i;                // go to next file
            }

            // copy up to 4x LBA base addresses into the Page 0 template YABIOS scratch at 0x0040
            memcpy( (volatile uint8_t*)(page0Template + 0x0040), (const uint8_t*)driveLBAbase, sizeof(uint32_t)*4 );

            // copy the source bank for CP/M CCP/BDOS/BIOS for CP/M BIOS wboot usage to Page 0 at 0x0050
            *(volatile uint8_t*)(page0Template + 0x0050) = srcBank;

            // copy over source bank CP/M CCP/BDOS/BIOS to dest bank, if it exists args[1] != 0
            if ( srcBank != 0x00)
            {
                // do the copy from CP/M CCP/BDOS/BIOS src to final destination bank
                memcpy_far( (void *)0x0100, (int8_t)destBank, (void *)0x0100, (int8_t)srcBank, (__COMMON_AREA_1_BASE - PAGE0_SIZE) );
                // do the Page 0 copy from template to final destination bank Page 0
                memcpy_far( (void *)0x0000, (int8_t)destBank, page0Template, 0, PAGE0_SIZE );
                // do the Page 0 initialisation from CP/M CCP/BDOS/BIOS src to final destination bank
                memcpy_far( (void *)0x0000, (int8_t)destBank, (void *)0x0000, (int8_t)srcBank, 0x08 );
                // do the cpm_iobyte initialisation from the bios_ioByte as this is volatile
                memcpy_far( (void *)0x0003, (int8_t)destBank, &bios_ioByte, 0, 0x01 );
            } else {
                // we'll have to load CP/M using loadh later
                // do the Page 0 copy from template to final destination bank Page 0
                memcpy_far( (void *)0x0000, (int8_t)destBank, page0Template, 0, PAGE0_SIZE );
                // do the cpm_iobyte initialisation from the bios_ioByte as this is volatile
                memcpy_far( (void *)0x0003, (int8_t)destBank, &bios_ioByte, 0, 0x01 );
            }

            // set bank referenced from _bankLockBase, so the the bank is noted as warm.
            lock_give( &bankLockBase[ destBank ] );

            fprintf(output,"Initialised Bank: %01X, for CP/M", destBank);
            free(page0Template);
        }
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mkcpmd".  args[1] is the nominated drive name.
                              args[2] is the number of directory entries,  args[3] is file size in bytes.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkcpmd(char **args)  // create a file for CP/M drive
{
    FRESULT res;
    int16_t dirEntries;
    int16_t dirBytesWritten;
    uint32_t lbaBase;

    if (args[1] == NULL || args[2] == NULL || args[3] == NULL) {
        fprintf(output, "yash: expected 3 arguments to \"mkcpmd\"\n");
    } else {
        fprintf(output,"Creating \"%s\"", args[1]);
        res = f_open(&File[0], (const TCHAR*)args[1], FA_CREATE_ALWAYS | FA_WRITE);
        if (res != FR_OK) { put_rc(res); return 1; }

        res = f_expand(&File[0], atol(args[3]), 1);
        if (res != FR_OK) {
            put_rc(res);
            f_close(&File[0]);
            return 1;
        }

        dirEntries = atoi(args[2]);

        for (uint16_t i = 0; i < dirEntries; i++) {

            // There are 4 Directory Entries (Extents) per CPM sector
            res = f_write ( &File[0], (const uint8_t *)directoryBlock, 32, &dirBytesWritten );
            if (res != FR_OK || dirBytesWritten != 32) {
                fprintf(output, "\nCP/M Directory incomplete");
                put_rc(res);
                f_close(&File[0]);
                return 1;
            }
        }

        lbaBase = (&File[0])->obj.fs->database + ((&File[0])->obj.fs->csize * ((&File[0])->obj.sclust - 2));
        f_close(&File[0]);

        fprintf(output," at base sector LBA %lu", lbaBase);
    }
    return 1;
}


// bank related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mkb".  args[1] is the nominated bank.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkb(char **args)      // initialise the nominated bank (to warm state)
{
    uint8_t * page0Template;

    page0Template = (uint8_t *)malloc(sizeof(uint8_t)*PAGE0_SIZE);  /* Get work area for the Page 0 */

    if (page0Template != NULL && args[1] != NULL)
    {
        memcpy(page0Template, (uint8_t *)0x0000, PAGE0_SIZE); // copy the existing ROM Page0 to our working space
        // existing RST0 trap code is contained in this space at 0x0080, and jumps to __Start at 0x0100.
        // existing RST jumps and INT0 code is correctly copied.
        *(volatile uint16_t*)(page0Template + (uint16_t)&bank_sp) = __COMMON_AREA_1_BASE; // set the new bank SP to point to top of BANKnn
        // do the copy
        memcpy_far((void *)0x0000, (int8_t)atoi(args[1]), page0Template, 0, PAGE0_SIZE);
        // set bank referenced from _bankLockBase, so the the bank is noted as warm.
        lock_give( &bankLockBase[ bank_get_abs((int8_t)atoi(args[1])) ] );
        fprintf(output,"Initialised Bank: %01X", bank_get_abs((int8_t)atoi(args[1])) );
        free(page0Template);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "cpb".  args[1] is source bank. args[2] is the destination bank.
   @return Always returns 1, to continue executing.
 */
int8_t ya_cpb(char **args)      // move or clone the nominated bank
{
    if ( (args[2] != NULL) && (bank_get_abs((int8_t)atoi(args[1])) != 0) && (bank_get_abs((int8_t)atoi(args[2])) != 0) )   // the source and destination can never be BANK0
    {
        // do the copy
        memcpy_far((void *)0x0000, (int8_t)atoi(args[2]), (void *)0x0000, (int8_t)atoi(args[1]), (__COMMON_AREA_1_BASE-0)); // copy it all
        // set bank referenced from _bankLockBase, so the clone bank is noted as the same state as its parent.
        bankLockBase[ bank_get_abs((int8_t)atoi(args[2])) ] = bankLockBase[ bank_get_abs((int8_t)atoi(args[1])) ];
        fprintf(output,"Cloned Bank: %01X into Bank: %01X", bank_get_abs((int8_t)atoi(args[1])), bank_get_abs((int8_t)atoi(args[2])));
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "rmb".  args[1] is the nominated bank.
   @return Always returns 1, to continue executing.
 */
int8_t ya_rmb(char **args)      // remove the nominated bank (to cold state)
{
    if (args[1] == NULL) {
        fprintf(output, "yash: expected 1 argument to \"rmb\"\n");
    } else {
        // set bank referenced from _bankLockBase, so the the bank is noted as cold.
        bankLockBase[ bank_get_abs((int8_t)atoi(args[1])) ] = 0x00;
        fprintf(output,"Deleted Bank: %01X", bank_get_abs((int8_t)atoi(args[1])) );
    }
   return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "lsb".
   @return Always returns 1, to continue executing.
 */
int8_t ya_lsb(char **args)      // list the usage of banks, and whether they are cold, warm, or hot
{
    (void *)args;
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "initb".  args[1] is the nominated bank. args[2] is the nominated origin.
   @return only returns when the jumped to bank exits.
 */
int8_t ya_initb(char **args)    // jump to and begin executing the nominated bank at nominated address
{
    uint8_t * origin;
    uint8_t bank;

    if (args[1] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"initb\"\n");
    } else {
        if (args[2] == NULL) {
            origin = (uint8_t *)0x100;
        } else {
            origin = (uint8_t *)strtoul(args[2], NULL, 16);
        }
        bank = (int8_t)atoi(args[1]);
        jp_far(origin, bank);   // manages the stack swap from _bios_sp to _bank_sp
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "loadh".  args[1] is the nominated initial bank.
   @return Always returns 1, to continue executing.
 */
int8_t ya_loadh(char **args)    // load the nominated bank with intel hex using current port
{
    uint8_t initialBank;

    if (args[1] == NULL) {
        fprintf(output, "yash: expected 1 argument to \"loadh\"\n");
    } else {
        initialBank = bank_get_abs((int8_t)atoi(args[1]));
        load_hex( initialBank );
        // set bank referenced from _bankLockBase, so the the bank is noted as warm.
        lock_give( &bankLockBase[ initialBank ] );
        fprintf(output,"Loaded Bank: %01X", initialBank );
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "loadb".  args[1] is the path.
        args[2] is the nominated bank. args[3] is the origin address.
   @return Always returns 1, to continue executing.
 */
int8_t ya_loadb(char **args)    // load the nominated bank and address with binary code
{
    FRESULT res;
    uint8_t * dest;
    uint32_t p1;
    uint16_t s1;

    struct timespec startTime, endTime, resTime;

    if (args[1] == NULL || args[2] == NULL) {
        fprintf(output, "yash: expected 3 arguments to \"loadb\"\n");
    } else {
        if (args[3] == NULL) {
            dest = (uint8_t *)0x0100;
        } else {
            dest = (uint8_t *)strtoul(args[3], NULL, 16);
        }
        fprintf(output,"Opening \"%s\"\n", args[1]);
        res = f_open(&File[0], (const TCHAR *)args[1], FA_OPEN_EXISTING | FA_READ);
        if (res != FR_OK) { put_rc(res); return 1; }

        fprintf(output,"Loading \"%s\" to %01X:%04X...", args[1], bank_get_abs((int8_t)atoi(args[2])), (uint16_t)dest );

        clock_gettime( CLOCK_MONOTONIC, &startTime );

        p1 = 0;
        while ((uint16_t)dest < (__COMMON_AREA_1_BASE-0)) {
            res = f_read(&File[0], buffer, sizeof(char)*BUFFER_SIZE, &s1);
            if (res != FR_OK || s1 == 0) break;   /* error or eof */

            if (s1 > (__COMMON_AREA_1_BASE-0) - (uint16_t)dest) {       // don't overwrite COMMON AREA 1
                s1 = (__COMMON_AREA_1_BASE-0) - (uint16_t)dest;
            }
            memcpy_far((void *)dest, (int8_t)atoi(args[2]), buffer, 0, s1);     // write s1 bytes to ram
            dest += s1;
            p1 += s1;
        }

        clock_gettime( CLOCK_MONOTONIC, &endTime );

        f_close(&File[0]);

        // set bank referenced from _bankLockBase, so the the bank is noted as warm.
        lock_give( &bankLockBase[ bank_get_abs((int8_t)atoi(args[2])) ] );

        timersub(&endTime, &startTime, &resTime);

        fprintf(output, "\nLoaded %lu bytes, the time taken was %li.%.4lu seconds", p1, resTime.tv_sec, resTime.tv_nsec/100000);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "saveb".  args[1] is the nominated bank. args[2] is the filename / directory
   @return Always returns 1, to continue executing.
 */
int8_t ya_saveb(char **args)    // save the nominated bank from 0x0100 to CBAR 0xF000 by default
{
    FRESULT res;
    uint8_t * origin;
    uint32_t p1;
    uint16_t s1, s2;

    struct timespec startTime, endTime, resTime;

    if (args[1] == NULL || args[2] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"saveb\"\n");
    } else {
        origin = (uint8_t *)0x0100;

        fprintf(output,"Creating \"%s\"...\n", args[2]);
        res = f_open(&File[0], (const TCHAR *)args[2], FA_CREATE_ALWAYS | FA_WRITE);
        if (res != FR_OK) { put_rc(res); return 1; }

        fprintf(output,"Saving Bank %01X to \"%s\"", bank_get_abs((int8_t)atoi(args[1])), args[2] );

        clock_gettime( CLOCK_MONOTONIC, &startTime );

        p1 = 0;
        while ((uint16_t)origin < (__COMMON_AREA_1_BASE-0)) {
            memcpy_far(buffer, 0, (void *)origin, (uint8_t)atoi(args[1]), sizeof(char)*BUFFER_SIZE);   // read sizeof(buffer) bytes from ram

            s1 = sizeof(char)*BUFFER_SIZE;

            if (s1 > (__COMMON_AREA_1_BASE-0) - (uint16_t)origin) {       // don't overwrite COMMON AREA 1
                s1 = (__COMMON_AREA_1_BASE-0) - (uint16_t)origin;
            }

            if ( s1 == 0) break;                /* end of BANK at (__COMMON_AREA_1_BASE-1) */

            res = f_write(&File[0], buffer, s1, &s2);
            origin += s2;
            p1 += s2;
            if (res != FR_OK || s2 < s1) break; /* error or disk full */
        }

        clock_gettime( CLOCK_MONOTONIC, &endTime );

        f_close(&File[0]);

        timersub(&endTime, &startTime, &resTime);

        fprintf(output, "\nSaved %lu bytes, the time taken was %li.%.4lu seconds", p1, resTime.tv_sec, resTime.tv_nsec/100000);
    }
    return 1;
}


// system related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "md". args[1] is the nominated bank. args[2] is the origin address.
   @return Always returns 1, to continue executing.
 */
int8_t ya_md(char **args)       // dump RAM contents from nominated bank from nominated origin.
{
    static uint8_t * origin;
    static uint8_t bank;
    uint32_t ofs;
    uint8_t * ptr;

    if (args[1] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"md\"\n");
    } else {
        if (args[2] == NULL) {
             origin = (uint8_t *)strtoul(args[1], NULL, 16);
        } else {
            bank = bank_get_abs((int8_t)atoi(args[1]));
            origin = (uint8_t *)strtoul(args[2], NULL, 16);
        }
    }

    memcpy_far(buffer, 0, (void *)origin, (int8_t)bank, 0x100); // grab a page
    fprintf(output, "\nOrigin: %01X:%04X\n", bank, (uint16_t)origin);

    for (ptr=(uint8_t *)buffer, ofs = 0; ofs < 0x100; ptr += 16, ofs += 16) {
        put_dump(ptr, ofs, 16);
    }

    origin += 0x100;                                            // go to next page (next time)
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "help".
   @return Always returns 1, to continue executing.
 */
int8_t ya_help(char **args)
{
    uint8_t i;
    (void *)args;

    fprintf(output,"YAZ180 - yabios v2.2 2022\n");
    fprintf(output,"The following functions are built in:\n");

    for (i = 0; i < ya_num_builtins(); ++i) {
        fprintf(output,"  %s %s\n", builtins[i].name, builtins[i].help);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "exit".
   @return Always returns 0, to terminate execution.
 */
int8_t ya_exit(char **args)
{
    (void *)args;
    f_mount(0, (const TCHAR*)"", 0);        /* Unmount the default drive */
    return 0;
}


// fat related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "ls".  args[1] is the path.
   @return Always returns 1, to continue executing.
 */
int8_t ya_ls(char **args)
{
    FRESULT res;
    uint32_t p1;
    uint16_t s1, s2;

    res = f_mount(fs, (const TCHAR*)"", 0);
    if (res != FR_OK) { put_rc(res); return 1; }

    if(args[1] == NULL) {
        res = f_opendir(dir, (const TCHAR*)".");
    } else {
        res = f_opendir(dir, (const TCHAR*)args[1]);
    }
    if (res != FR_OK) { put_rc(res); return 1; }

    p1 = s1 = s2 = 0;
    while(1) {
        res = f_readdir(dir, &Finfo);
        if ((res != FR_OK) || !Finfo.fname[0]) break;
        if (Finfo.fattrib & AM_DIR) {
            s2++;
        } else {
            s1++; p1 += Finfo.fsize;
        }
        fprintf(output, "%c%c%c%c%c %u/%02u/%02u %02u:%02u %9lu  %s\n",
                (Finfo.fattrib & AM_DIR) ? 'D' : '-',
                (Finfo.fattrib & AM_RDO) ? 'R' : '-',
                (Finfo.fattrib & AM_HID) ? 'H' : '-',
                (Finfo.fattrib & AM_SYS) ? 'S' : '-',
                (Finfo.fattrib & AM_ARC) ? 'A' : '-',
                (Finfo.fdate >> 9) + 1980, (Finfo.fdate >> 5) & 15, Finfo.fdate & 31,
                (Finfo.ftime >> 11), (Finfo.ftime >> 5) & 63,
                (DWORD)Finfo.fsize, Finfo.fname);
    }
    fprintf(output, "%4u File(s),%10lu bytes total\n%4u Dir(s)", s1, p1, s2);

    if(args[1] == NULL) {
        res = f_getfree( (const TCHAR*)".", (DWORD*)&p1, &fs);
    } else {
        res = f_getfree( (const TCHAR*)args[1], (DWORD*)&p1, &fs);
    }
    if (res == FR_OK) {
        fprintf(output, ", %10lu bytes free\n", p1 * fs->csize * 512);
    } else {
        put_rc(res);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "rm".  args[1] is the directory or file.
   @return Always returns 1, to continue executing.
 */
int8_t ya_rm(char **args)       // delete a directory or file
{
    if (args[1] == NULL) {
        fprintf(output, "yash: expected 1 argument to \"rm\"\n");
    } else {
        put_rc(f_unlink((const TCHAR*)args[1]));
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "cp".  args[1] is the src, args[2] is the dst
   @return Always returns 1, to continue executing.
 */
int8_t ya_cp(char **args)       // copy a file
{
    FRESULT res;
    uint32_t p1;
    uint16_t s1, s2;

    struct timespec startTime, endTime, resTime;

    if (args[1] == NULL || args[2] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"cp\"\n");
    } else {
        fprintf(output,"Opening \"%s\"\n", args[1]);
        res = f_open(&File[0], (const TCHAR*)args[1], FA_OPEN_EXISTING | FA_READ);
        if (res != FR_OK) { put_rc(res); return 1; }
        fprintf(output,"Creating \"%s\"\n", args[2]);
        res = f_open(&File[1], (const TCHAR*)args[2], FA_CREATE_ALWAYS | FA_WRITE);
        if (res != FR_OK) {
            put_rc(res);
            f_close(&File[0]);
            return 1;
        }
        fprintf(output,"Copying file...");

        clock_gettime( CLOCK_MONOTONIC, &startTime );

        p1 = 0;
        while (1) {
            res = f_read(&File[0], buffer, sizeof(char)*BUFFER_SIZE, &s1);
            if (res != FR_OK || s1 == 0) break;   /* error or eof */
            res = f_write(&File[1], buffer, s1, &s2);
            p1 += s2;
            if (res != FR_OK || s2 < s1) break;   /* error or disk full */
        }

        clock_gettime( CLOCK_MONOTONIC, &endTime );

        f_close(&File[1]);
        f_close(&File[0]);

        timersub(&endTime, &startTime, &resTime);

        fprintf(output, "\nCopied %lu bytes, the time taken was %li.%.4lu seconds", p1, resTime.tv_sec, resTime.tv_nsec/100000);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mv".  args[1] is the src, args[2] is the dst
   @return Always returns 1, to continue executing.
 */
int8_t ya_mv(char **args)       // move (rename) a file
{
    if (args[1] == NULL || args[2] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"mv\"\n");
    } else {
        put_rc(f_rename((const TCHAR*)args[1],(const TCHAR*)args[2]));
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "cd".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_cd(char **args)
{
    if (args[1] == NULL) {
        fprintf(output, "yash: expected 1 argument to \"cd\"\n");
    } else {
        put_rc(f_chdir((const TCHAR*)args[1]));
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "pwd".
   @return Always returns 1, to continue executing.
 */
int8_t ya_pwd(char **args)      // show the current working directory
{
    FRESULT res;
    uint8_t * directory;                         /* put directory buffer on heap */

    (void *)args;

    directory = (uint8_t *)malloc(sizeof(uint8_t)*LINE_SIZE);     /* Get area for directory buffer */

    if (directory != NULL) {
        res = f_getcwd(directory, sizeof(uint8_t)*LINE_SIZE);
        if (res != FR_OK) {
            put_rc(res);
        } else {
            fprintf(output, "%s", directory);
        }
        free(directory);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mkdir".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkdir(char **args)    // create a new directory
{
    if (args[1] == NULL) {
        fprintf(output, "yash: expected 1 argument to \"mkdir\"\n");
    } else {
        put_rc(f_mkdir((const TCHAR*)args[1]));
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "chmod".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_chmod(char **args)    // change file or directory attributes
{
#if !FF_USE_CHMOD
    (void *)args;
#else
    if (args[1] == NULL && args[2] == NULL && args[3] == NULL) {
        fprintf(output, "yash: expected 3 arguments to \"chmod\"\n");
    } else {
        put_rc(f_chmod((const TCHAR*)args[1], atoi(args[2]), atoi(args[3])));
    }
#endif
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mkfs".  args[1] is the type, args[2] is the block size.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkfs(char **args)     // create a FAT file system
{
#if !FF_USE_MKFS
    (void *)args;
#else
    char *line = NULL;
    ssize_t bufsize = 0;        // have getline allocate a buffer for us

    if (args[1] == NULL && args[2] == NULL) {
        fprintf(output, "yash: expected 2 arguments to \"mkfs\"\n");
    } else {
        fprintf(output, "The drive will be erased and formatted. Are you sure [y/N]\n");
        getline(&line, &bufsize, input);
        if (line[0] == 'Y')
            put_rc(f_mkfs((const TCHAR*)args[1], atoi(args[2]), atoi(args[3]), buffer, sizeof(char)*BUFFER_SIZE));
        free(line);
    }
#endif
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "mount". args[1] is the option byte.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mount(char **args)    // mount a FAT file system
{
    if (args[1] == NULL) {
        put_rc(f_mount(fs, (const TCHAR*)"", 0));
    } else {
        put_rc(f_mount(fs, (const TCHAR*)"", atoi(args[1])));
    }
    return 1;
}


// disk related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "ds".
   @return Always returns 1, to continue executing.
 */
int8_t ya_ds(char **args)       // disk status
{
    FRESULT res;
    int32_t p1;
    const uint8_t ft[] = {0, 12, 16, 32};   // FAT type
    (void *)args;

    res = f_getfree( (const TCHAR*)"", (DWORD*)&p1, &fs);
    if (res != FR_OK) { put_rc(res); return 1; }

    fprintf(output, "FAT type = FAT%u\nBytes/Cluster = %lu\nNumber of FATs = %u\n"
        "Root DIR entries = %u\nSectors/FAT = %lu\nNumber of clusters = %lu\n"
        "Volume start (lba) = %lu\nFAT start (lba) = %lu\nDIR start (lba,cluster) = %lu\nData start (lba) = %lu\n",
        ft[fs->fs_type & 3], (DWORD)fs->csize * 512, fs->n_fats,
        fs->n_rootdir, fs->fsize, (DWORD)fs->n_fatent - 2,
        fs->volbase, fs->fatbase, fs->dirbase, fs->database);
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "dd". args[1] is the sector in decimal.
   @return Always returns 1, to continue executing.
 */
int8_t ya_dd(char **args)       // disk dump
{
    FRESULT res;
    static uint32_t sect;
    uint32_t ofs;
    uint8_t * ptr;

    if (args[1] != NULL) {
        sect = strtoul(args[1], NULL, 10);
    }

    fprintf(output, "LBA:%lu\n", sect);
    res = disk_read( 0, buffer, sect, 1);
    if (res != FR_OK) { fprintf(output, "rc=%d\n", (WORD)res); return 1; }

    for (ptr=(uint8_t *)buffer, ofs = 0; ofs < 0x200; ptr += 16, ofs += 16)
        put_dump(ptr, ofs, 16);

    ++sect;
    return 1;
}


// time related functions

/**
   @brief Builtin command:
   @param args List of args.  args[0] is "clock".  args[1] is the UNIX time.
   @return Always returns 1, to continue executing.
 */
int8_t ya_clock(char **args)    // set the time (using UNIX epoch)
{
    if (args[1] != NULL) {
        set_system_time(atol(args[1]) - UNIX_OFFSET);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "tz".  args[1] is TZ offset in hours.
   @return Always returns 1, to continue executing.
 */
int8_t ya_tz(char **args)       // set timezone (no daylight savings, so adjust manually)
{
    if (args[1] != NULL) {
        set_zone(atol(args[1]) * ONE_HOUR);
    }
    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "diso".
   @return Always returns 1, to continue executing.
 */
int8_t ya_diso(char **args)     // print the local time in ISO std: 2013-03-23 01:03:52
{
    time_t theTime;
    struct tm CurrTimeDate;     // set up an array for the RTC info.
    char timeStore[26];

    (void *)args;

    time(&theTime);
    localtime_r(&theTime, &CurrTimeDate);
    isotime_r(&CurrTimeDate, timeStore);
    fprintf(output, "%s\n", timeStore);

    return 1;
}


/**
   @brief Builtin command:
   @param args List of args.  args[0] is "date".
   @return Always returns 1, to continue executing.
 */
int8_t ya_date(char **args)     // print the local time: Sun Mar 23 01:03:52 2013
{
    time_t theTime;
    struct tm CurrTimeDate;     // set up an array for the RTC info.
    char timeStore[26];

    (void *)args;

    time(&theTime);
    localtime_r(&theTime, &CurrTimeDate);
    asctime_r(&CurrTimeDate, timeStore);
    fprintf(output, "%s\n", timeStore);

    return 1;
}


// helper functions

static
void put_rc (FRESULT rc)
{
    const char *str =
        "OK\0" "DISK_ERR\0" "INT_ERR\0" "NOT_READY\0" "NO_FILE\0" "NO_PATH\0"
        "INVALID_NAME\0" "DENIED\0" "EXIST\0" "INVALID_OBJECT\0" "WRITE_PROTECTED\0"
        "INVALID_DRIVE\0" "NOT_ENABLED\0" "NO_FILE_SYSTEM\0" "MKFS_ABORTED\0" "TIMEOUT\0"
        "LOCKED\0" "NOT_ENOUGH_CORE\0" "TOO_MANY_OPEN_FILES\0" "INVALID_PARAMETER\0";

    FRESULT i;
    uint8_t res;

    res = (uint8_t)rc;

    for (i = 0; i != res && *str; ++i) {
        while (*str++) ;
    }
    fprintf(error,"\r\nrc=%u FR_%s\r\n", res, str);
}


static
void put_dump (const uint8_t *buff, uint32_t ofs, uint8_t cnt)
{
    uint8_t i;

    fprintf(output,"%08lX:", ofs);

    for(i = 0; i < cnt; ++i) {
        fprintf(output," %02X", buff[i]);
    }
    fputc(' ', output);
    for(i = 0; i < cnt; ++i) {
        fputc((buff[i] >= ' ' && buff[i] <= '~') ? buff[i] : '.', output);
    }
    fputc('\n', output);
}


/**
   @brief Execute shell built-in function.
   @param args Null terminated list of arguments.
   @return 1 if the shell should continue running, 0 if it should terminate
 */
int8_t ya_execute(char **args)
{
    uint8_t i;

    if (args[0] == NULL) {
        // An empty command was entered.
        return 1;
    }

    for (i = 0; i < ya_num_builtins(); ++i) {
        if (strcmp(args[0], builtins[i].name) == 0) {
            return (*builtins[i].func)(args);
        }
    }
    return 1;
}

#define YA_TOK_BUFSIZE 32
#define YA_TOK_DELIM " \t\r\n\a"
/**
   @brief Split a line into tokens (very naively).
   @param line The line.
   @return Null-terminated array of tokens.
 */
char **ya_split_line(char *line)
{
    uint16_t bufsize = YA_TOK_BUFSIZE;
    uint16_t position = 0;
    char *token;
    char **tokens, **tokens_backup;

    tokens = (char **)malloc(sizeof(char*)*bufsize);

    if (tokens && line)
    {
        token = strtok(line, YA_TOK_DELIM);
        while (token != NULL) {
            tokens[position] = token;
            position++;

            // If we have exceeded the tokens buffer, reallocate.
            if (position >= bufsize) {
                bufsize += YA_TOK_BUFSIZE;
                tokens_backup = tokens;
                tokens = (char **)realloc(tokens, sizeof(char*)*bufsize);
                if (tokens == NULL) {
                    free(tokens_backup);
                    fprintf(output, "yash: tokens realloc failure\n");
                    exit(EXIT_FAILURE);
                }
            }
            token = strtok(NULL, YA_TOK_DELIM);
        }
        tokens[position] = NULL;
    }
    return tokens;
}

/**
   @brief Loop getting input and executing it.
 */
void ya_loop(void)
{
    char **args;
    int status;
    char *line;
    uint16_t len;

    line = (char *)malloc(sizeof(char)*LINE_SIZE);      /* Get work area for the line buffer */
    if (line == NULL) return;

    asci0_flush_Rx();
    asci1_flush_Rx();

    while (1){                                          /* look for ":" to select the valid serial port */
        if (asci0_pollc() != 0) {
            if (asci0_getc() == ':') {
                input = stdin;
                output = stdout;
                error = stderr;
                bios_ioByte = 1;
                break;
            } else {
                asci0_flush_Rx();
            }
        }
        if (asci1_pollc() != 0) {
            if (asci1_getc() == ':') {
                input = ttyin;
                output = ttyout;
                error = ttyerr;
                bios_ioByte = 0;
                break;
            } else {
                asci1_flush_Rx();
            }
        }
    }
    fprintf(output," :-)\n");

    len = LINE_SIZE;

    do {
        fprintf(output,"\n> ");
        fflush(input);

        getline(&line, &len, input);
        args = ya_split_line(line);

        status = ya_execute(args);
        free(args);

    } while (status);

    free(line);
}


/**
   @brief Main entry point.
   @param argc Argument count.
   @param argv Argument vector.
   @return status code
 */
int main(int argc, char **argv)
{
    (void)argc;
    (void *)argv;

    set_zone((int32_t)10 * ONE_HOUR);               /* Australian Eastern Standard Time */
    set_system_time(1646092800 - UNIX_OFFSET);      /* Initial time: 00.00 March 1, 2022 UTC */

    fs = (FATFS *)malloc(sizeof(FATFS));                    /* Get work area for the volume */
    dir = (DIR *)malloc(sizeof(DIR));                       /* Get work area for the directory */
    buffer = (char *)malloc(sizeof(char)*BUFFER_SIZE);      /* Get working buffer space */

    // Load config files, if any.

    fprintf(stdout, "\n\nYAZ180 - yabios - CRT\n\n> :?");
    fprintf(ttyout, "\n\nYAZ180 - yabios - TTY\n\n> :?");

    // Run command loop if we got all the memory allocations we need.
    if ( fs && dir && buffer)
        ya_loop();

    // Perform any shutdown/cleanup.
    free(buffer);
    free(dir);
    free(fs);

    return 0;
}
