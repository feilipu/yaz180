/***************************************************************************//**

  @file         main.c
  @author       Stephen Brennan, modified by Phillip Stevens
  @brief        YASH (Yet Another SHell)

*******************************************************************************/

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <arch.h>
#include <arch/yaz180/diskio.h>

#include "ffconf.h"
#include <lib/yaz180/ff.h>
#include <lib/yaz180/time.h>

#define BUFFER_SIZE 1024	    // size of working buffer (on heap)
#define LINE_SIZE 256			// size of a command line (on heap)
#define MAX_FILES 4             // number of files open at any time

#define UNUSED(expr) do { (void)(expr); } while (0)

static uint8_t * buffer;        /* put working buffer on heap later */
int32_t AccSize;				/* Work register for scan_files function */
int16_t AccFiles, AccDirs;

static FATFS *fs;               /* Pointer to the filesystem object (on heap) */
static DIR *dir;                /* Pointer to the directory object (on heap) */

static FILINFO Finfo;           /* File Information */
static FIL File[MAX_FILES];     /* File object needed for each open file */


/*
  Function Declarations for builtin shell commands:
 */

// bank related functions
int8_t ya_mkb(char **args);     // initialise the nominated bank (to warm state)
int8_t ya_mvb(char **args);     // move or clone the nominated bank
int8_t ya_rmb(char **args);     // remove the nominated bank (to cold state)
int8_t ya_lsb(char **args);     // list the usage of banks, and whether they are cold, warm, or hot
int8_t ya_initb(char **args);   // jump to and begin executing the nominated bank at nominated address
int8_t ya_loadh(char **args);   // load the nominated bank with intel hex
int8_t ya_loadb(char **args);   // load the nominated bank and address with binary code
int8_t ya_saveb(char **args);   // save the nominated bank from 0x0100 to 0xF000 by default

// system related functions
int8_t ya_reset(char **args);   // reset YAZ180 to cold start, clear all bank information
int8_t ya_help(char **args);    // help
int8_t ya_exit(char **args);    // exit and halt

// fat related functions
int8_t ya_ls(char **args);      // directory listing
int8_t ya_rm(char **args);      // delete a file
int8_t ya_mv(char **args);      // copy a file
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
static void put_dump (const uint8_t *buff, uint32_t ofs, uint8_t cnt);
static FRESULT scan_files (char* path);    // scan through files in a directory
static void put_rc (FRESULT rc);            // print error codes to stderr

/*
  List of builtin commands.
 */
struct Builtin {
  char *name;
  int8_t (*func) (char** args);
};

struct Builtin builtins[] = {
  
  // bank related functions
    { "mkb", &ya_mkb },         // initialise the nominated bank (to warm state)
    { "mvb", &ya_mvb },         // move or clone the nominated bank
    { "rmb", &ya_rmb },         // remove the nominated bank (to cold state)
    { "lsb", &ya_lsb },         // list the usage of banks, and whether they are cold, warm, or hot
    { "initb", &ya_initb },     // jump to and begin executing the nominated bank at nominated address
    { "loadh", &ya_loadh },     // load the nominated bank with intel hex
    { "loadb", &ya_loadb },     // load the nominated bank and address with binary code
    { "saveb", &ya_saveb },     // save the nominated bank from 0x0100 to 0xF000 by default

// system related functions
    { "reset", &ya_reset },     // reset YAZ180 to cold start, clear all bank information
    { "help", &ya_help },       // help
    { "exit", &ya_exit },       // exit and halt

// fat related functions
    { "ls", &ya_ls },           // directory listing
    { "rm", &ya_rm },           // delete a file
    { "mv", &ya_mv },           // copy a file
    { "cd", &ya_cd },           // change the current working directory
    { "pwd", &ya_pwd },         // show the current working directory
    { "mkdir", &ya_mkdir },     // create a new directory
    { "chmod", &ya_chmod },     // change file or directory attributes
    { "mkfs", &ya_mkfs },       // create a FAT file system
    { "mount", &ya_mount },     // mount a FAT file system

// disk related functions
    { "ds", &ya_ds },            // disk status
    { "dd", &ya_dd },            // disk dump sector

// time related functions
    { "clock", &ya_clock },      // set the time (UNIX epoch)
    { "tz", &ya_tz },            // set timezone (no daylight savings, so adjust manually)
    { "diso", &ya_diso },        // print the local time in ISO: 2013-03-23 01:03:52
    { "date", &ya_date }         // print the local time in US: Sun Mar 23 01:03:52 2013
};

uint8_t ya_num_builtins() {
  return sizeof(builtins) / sizeof(struct Builtin);
}


/*
  Builtin function implementations.
*/

// bank related functions

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mkb(char **args)   // initialise the nominated bank (to warm state)
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mvb(char **args)    // move or clone the nominated bank
{
    FRESULT res;
    
    return 1;
} 

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_rmb(char **args)     // remove the nominated bank (to cold state)
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_lsb(char **args)     // list the usage of banks, and whether they are cold, warm, or hot
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_initb(char **args)  // jump to and begin executing the nominated bank at nominated address
{
    FRESULT res;
    
    return 1;
} 

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_loadh(char **args) // load the nominated bank with intel hex
{
    FRESULT res;
    
    return 1;
}  

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_loadb(char **args)   // load the nominated bank and address with binary code
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_saveb(char **args)   // save the nominated bank from 0x0100 to CBAR 0xF000 by default
{
    FRESULT res;
    
    return 1;
}

// system related functions

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_reset(char **args)   // reset YAZ180 to cold start, clear all bank information
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: help.
   @param args List of args.  Not examined.
   @return Always returns 1, to continue executing.
 */
int8_t ya_help(char **args)
{
    uint8_t i;
    printf("YABIOS\n");
    printf("Type program names and arguments, and hit enter.\n");
    printf("The following are built in:\n");

    for (i = 0; i < ya_num_builtins(); ++i) {
        printf("  %s\n", builtins[i].name);
    }

    return 1;
}

/**
   @brief Builtin command: exit.
   @param args List of args.  Not examined.
   @return Always returns 0, to terminate execution.
 */
int8_t ya_exit(char **args)
{
    FRESULT res;
    
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
    int32_t p1;
	uint16_t s1, s2;

	res = f_opendir(dir, (const TCHAR*)args[1]);
	if (res) { put_rc(res); return 1; }
	p1 = s1 = s2 = 0;
	while(1) {
		res = f_readdir(dir, &Finfo);
		if ((res != FR_OK) || !Finfo.fname[0]) break;
		if (Finfo.fattrib & AM_DIR) {
			s2++;
		} else {
			s1++; p1 += Finfo.fsize;
		}
		fprintf(stdout, "%c%c%c%c%c %u/%02u/%02u %02u:%02u %9lu  %s\n",
				(Finfo.fattrib & AM_DIR) ? 'D' : '-',
				(Finfo.fattrib & AM_RDO) ? 'R' : '-',
				(Finfo.fattrib & AM_HID) ? 'H' : '-',
				(Finfo.fattrib & AM_SYS) ? 'S' : '-',
				(Finfo.fattrib & AM_ARC) ? 'A' : '-',
				(Finfo.fdate >> 9) + 1980, (Finfo.fdate >> 5) & 15, Finfo.fdate & 31,
				(Finfo.ftime >> 11), (Finfo.ftime >> 5) & 63,
				(DWORD)Finfo.fsize, Finfo.fname);
	}
	fprintf(stdout, "%4u File(s),%10lu bytes total\n%4u Dir(s)", s1, p1, s2);
	res = f_getfree( (const TCHAR*)args[1], (DWORD*)&p1, &fs);
	if (res == FR_OK)
		fprintf(stdout, ", %10lu bytes free\n", p1 * fs->csize * 512);
	else
		put_rc(res);
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "rm".  args[1] is the directory or file.
   @return Always returns 1, to continue executing.
 */
int8_t ya_rm(char **args)      // delete a directory or file
{
    if (args[1] == NULL) {
        fprintf(stderr, "yash: expected arguments to \"rm\"\n");
    } else {
        put_rc(f_unlink(args[1]));
    }
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "mv".  args[1] is the src, args[2] is the dst
   @return Always returns 1, to continue executing.
 */
int8_t ya_mv(char **args)      // copy a file
{
    FRESULT res;
    int32_t p1;
	uint16_t s1, s2;

	fprintf(stdout,"Opening \"%s\"", args[1]);
	res = f_open(&File[0], args[1], FA_OPEN_EXISTING | FA_READ);
	fputc('\n', stdout);
	if (res) {
		put_rc(res);
		return 1;
	}
	fprintf(stdout,"Creating \"%s\"", args[2]);
	res = f_open(&File[1], args[2], FA_CREATE_ALWAYS | FA_WRITE);
	fputc('\n', stdout);
	if (res) {
		put_rc(res);
		f_close(&File[0]);
		return 1;
	}
	fprintf(stdout,"Copying file...");
	p1 = 0;
	while (1) {
		res = f_read(&File[0], buffer, sizeof(buffer), &s1);
		if (res || s1 == 0) break;   /* error or eof */
		res = f_write(&File[1], buffer, s1, &s2);
		p1 += s2;
		if (res || s2 < s1) break;   /* error or disk full */
	}
	fprintf(stdout," %lu bytes copied.\n", p1);
	f_close(&File[0]);
	f_close(&File[1]);
    
    return 1;
}


/**
   @brief Builtin command: change directory.
   @param args List of args.  args[0] is "cd".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_cd(char **args)
{
    if (args[1] == NULL) {
        fprintf(stderr, "yash: expected arguments to \"cd\"\n");
    } else {
        put_rc(f_chdir(args[1]));
    }
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "pwd".
   @return Always returns 1, to continue executing.
 */
int8_t ya_pwd(char **args)     // show the current working directory
{  
    FRESULT res;
    uint8_t * line;                         /* put line buffer on heap */
    
    line = malloc(sizeof(LINE_SIZE));       /* Get work area for the line buffer */
    
    res = f_getcwd(line, sizeof(line));
    if (res)
	    put_rc(res);
    else
	    fprintf(stdout, "%s\n", line);
    
    free(line);
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
        fprintf(stderr, "yash: expected arguments to \"mkdir\"\n");
    } else {
        put_rc(f_mkdir(args[1]));
    }
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "chmod".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_chmod(char **args)   // change file or directory attributes
{
#if FF_USE_CHMOD
    if (args[1] == NULL && args[2] == NULL && args[3] == NULL) {
        fprintf(stderr, "yash: expected 3 arguments to \"chmod\"\n");
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
int8_t ya_mkfs(char **args)    // create a FAT file system
{
#if FF_USE_MKFS
    char *line = NULL;
    ssize_t bufsize = 0; // have getline allocate a buffer for us
    
    if (args[1] == NULL && args[2] == NULL ) {
        fprintf(stderr, "yash: expected 2 arguments to \"mkfs\"\n");
    } else {
        fprintf(stdout, "The drive will be erased and formatted. Are you sure [y/N]\r\n");
        getline(&line, &bufsize, stdin);
        if (line[0] == 'Y')
            put_rc(f_mkfs((const TCHAR*)args[1], atoi(args[2]), atoi(args[3]), buffer, sizeof(buffer)));
    }
#endif
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "mount". args[1] is the volume name, args[2] is the option byte.
   @return Always returns 1, to continue executing.
 */
int8_t ya_mount(char **args)    // mount a FAT file system
{
    uint8_t p1;
    if (args[1] == NULL ) {
        fprintf(stderr, "yash: expected 2 arguments to \"mount\"\n");
    } else {
        put_rc(f_mount(fs, args[1], atoi(args[2])));
    }
    return 1;
}


// disk related functions

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "ds".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_ds(char **args)      // disk status
{
    FRESULT res;
    int32_t p1, p2;
	const uint8_t ft[] = {0, 12, 16, 32};   // FAT type
	
    if (args[1] == NULL) {
        fprintf(stderr, "yash: expected 1 arguments to \"ds\"\n");
    } else {
	    res = f_getfree((const TCHAR*)args[1], (DWORD*)&p1, &fs);
	    if (res) { put_rc(res); return 1; }
	    fprintf(stdout, "FAT type = FAT%u\nBytes/Cluster = %lu\nNumber of FATs = %u\n"
			    "Root DIR entries = %u\nSectors/FAT = %lu\nNumber of clusters = %lu\n"
			    "Volume start (lba) = %lu\nFAT start (lba) = %lu\nDIR start (lba,clustor) = %lu\nData start (lba) = %lu\n\n",
			    ft[fs->fs_type & 3], (DWORD)fs->csize * 512, fs->n_fats,
			    fs->n_rootdir, fs->fsize, (DWORD)fs->n_fatent - 2,
			    fs->volbase, fs->fatbase, fs->dirbase, fs->database);
#if FF_USE_LABEL
	    res = f_getlabel((const TCHAR*)args[1], (char*)buffer, (DWORD*)&p2);
	    if (res) { put_rc(res); return 1; }
	    fprintf(stdout, buffer[0] ? "Volume name is %s\n" : "No volume label\n", (char*)buffer);
	    fprintf(stdout, "Volume S/N is %04X-%04X\n", (DWORD)p2 >> 16, (DWORD)p2 & 0xFFFF);
#endif
	    AccSize = AccFiles = AccDirs = 0;
	    fprintf(stdout, "...");
	    res = scan_files(args[1]);
	    if (res) { put_rc(res); return 1; }
	    fprintf(stdout, "\r%u files, %lu bytes.\n%u folders.\n"
			    "%lu KiB total disk space.\n%lu KiB available.\n",
			    AccFiles, AccSize, AccDirs,
			    (fs->n_fatent - 2) * (fs->csize / 2), (DWORD)p1 * (fs->csize / 2) );
	}
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "dd".  args[1] is the drive. args[2] is the sector.
   @return Always returns 1, to continue executing.
 */
int8_t ya_dd(char **args)      // disk dump sector
{
    FRESULT res;
    static uint32_t ofs, sect;
    static uint8_t drv;
    uint8_t * ptr;
    
    if ( args[2] == NULL ) {
        sect = atoi(args[1]);
    } else {
        if (args[1] == NULL && args[2] == NULL) {
            fprintf(stderr, "yash: expected 2 arguments to \"dd\"\n");
            return 1;
         }
    }
    drv = atoi(args[1]);
    sect = atoi(args[2]);
	res = disk_read(drv, buffer, sect, 1);
	if (res) { fprintf(stdout, "rc=%d\n", (WORD)res); return 1; }
	fprintf(stdout, "PD#:%u LBA:%lu\n", drv, sect++);
	for (ptr=(char*)buffer, ofs = 0; ofs < 0x200; ptr += 16, ofs += 16)
		put_dump(ptr, ofs, 16);
    return 1;
}


// time related functions
int8_t ya_clock(char **args)   // set the time (UNIX epoch)
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_tz(char **args)      // set timezone (no daylight savings, so adjust manually)
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_diso(char **args)    // print the local time in ISO: 2013-03-23 01:03:52
{
    FRESULT res;
    
    return 1;
}

/**
   @brief Builtin command: 
   @param args List of args.  args[0] is "".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_date(char **args)    // print the local time in US: Sun Mar 23 01:03:52 2013
{
    FRESULT res;
    
    return 1;
}


static
void put_dump (const uint8_t *buff, uint32_t ofs, uint8_t cnt)
{
	uint8_t i;

	fprintf(stdout,"%08lX:", ofs);

	for(i = 0; i < cnt; i++)
		fprintf(stdout," %02X", buff[i]);

	fputc(' ', stdout);
	for(i = 0; i < cnt; i++)
		fputc((buff[i] >= ' ' && buff[i] <= '~') ? buff[i] : '.', stdout);

	fputc('\n', stdout);
}


static
FRESULT scan_files (
	char* path		/* Pointer to the path name working buffer */
)
{
	DIR dirs;
	FRESULT res;
	BYTE i;

	if ((res = f_opendir(&dirs, path)) == FR_OK) {
		while (((res = f_readdir(&dirs, &Finfo)) == FR_OK) && Finfo.fname[0]) {
			if (Finfo.fattrib & AM_DIR) {
				AccDirs++;
				i = strlen(path);
				path[i] = '/'; strcpy(&path[i+1], Finfo.fname);
				res = scan_files(path);
				path[i] = '\0';
				if (res != FR_OK) break;
			} else {
				AccFiles++;
				AccSize += Finfo.fsize;
			}
		}
	}
	return res;
}


static
void put_rc (FRESULT rc)
{
	const char *str =
		"OK\0" "DISK_ERR\0" "INT_ERR\0" "NOT_READY\0" "NO_FILE\0" "NO_PATH\0"
		"INVALID_NAME\0" "DENIED\0" "EXIST\0" "INVALID_OBJECT\0" "WRITE_PROTECTED\0"
		"INVALID_DRIVE\0" "NOT_ENABLED\0" "NO_FILE_SYSTEM\0" "MKFS_ABORTED\0" "TIMEOUT\0"
		"LOCKED\0" "NOT_ENOUGH_CORE\0" "TOO_MANY_OPEN_FILES\0" "INVALID_PARAMETER\0";
	FRESULT i;

	for (i = 0; i != rc && *str; i++) {
		while (*str++) ;
	}
	fprintf(stderr,"\r\nrc=%u FR_%s\r\n", (uint8_t)rc, str);
}


/**
   @brief Execute shell built-in.
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

    return 0;
}

#define YA_TOK_BUFSIZE 64
#define YA_TOK_DELIM " \t\r\n\a"
/**
   @brief Split a line into tokens (very naively).
   @param line The line.
   @return Null-terminated array of tokens.
 */
char **ya_split_line(char *line)
{
    int bufsize = YA_TOK_BUFSIZE, position = 0;
    char **tokens = malloc(bufsize * sizeof(char*));
    char *token, **tokens_backup;

    if (!tokens) {
        fprintf(stderr, "yash: allocation error\n");
        exit(EXIT_FAILURE);
    }

    token = strtok(line, YA_TOK_DELIM);
    while (token != NULL) {
        tokens[position] = token;
        position++;

        if (position >= bufsize) {
            bufsize += YA_TOK_BUFSIZE;
            tokens_backup = tokens;
            tokens = realloc(tokens, bufsize * sizeof(char*));
            if (!tokens) {
                free(tokens_backup);
                fprintf(stderr, "yash: allocation error\n");
                exit(EXIT_FAILURE);
            }
        }

        token = strtok(NULL, YA_TOK_DELIM);
    }
    tokens[position] = NULL;
    return tokens;
}

/**
   @brief Loop getting input and executing it.
 */
void ya_loop(void)
{
    char **args;
    char *line = NULL;
    ssize_t bufsize = 0; // have getline allocate a buffer for us  
    int status;

    do {
        printf("> "); 
        getline(&line, &bufsize, stdin);
        args = ya_split_line(line);
        status = ya_execute(args);

        free(line);
        free(args);
    } while (status);
}


/**
   @brief Main entry point.
   @param argc Argument count.
   @param argv Argument vector.
   @return status code
 */
void main(int argc, char **argv)
{  

    set_zone((int32_t)11 * ONE_HOUR);       /* Australian Eastern Summer Time */
    set_system_time(1506083467 - UNIX_OFFSET);

    fs = malloc(sizeof(FATFS));             /* Get work area for the volume */
    dir = malloc(sizeof(DIR));              /* Get work area for the directory */
    buffer = malloc(sizeof(BUFFER_SIZE));   /* Get working buffer space */
    
    f_mount(fs, "", 1);

    // Load config files, if any.

    // Run command loop.
    ya_loop();

    // Perform any shutdown/cleanup.
    
    free(buffer);
    free(dir);
    free(fs);

    return;
}

