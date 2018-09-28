
#include <sys.h>
#include <stdio.h>
#include <stdlib.h>

#include "yaz180.h"
#include "yabios.h"

#define BLOCK_SIZE 0x100
#define PAGE0_SIZE 0x100        /* size of a Page0 copy buffer (on heap) */

extern void *memcpy_far( void *str_dest, char bank_dest, void *str_src, char bank_src, size_t n);
extern void jp_far( void *str, int8_t bank);

int main(argc, argv)
int argc;
char ** argv;
{
    FILE *fptr;
    char c;
    
    uint8_t * page0Template;    /* pointer to template */
    uint8_t sysdat_page;
    uint8_t init_page;
    
    uint8_t * load_data;

    if(argc == 1)       /* no arguments on command line */
    {
     argv = _getargs(0,"MP/M SYS");
     argc = _argc_;
    }
    
    /* Open file */
    fptr = fopen(argv[1], "rb");
    if(fptr == NULL)
    { 
        printf("failed to read %s \n", argv[1]);
        exit(0); 
    }
    
    load_data = (uint8_t *)malloc((sizeof(uint8_t))*BLOCK_SIZE);  /* Get work area */
    
    if( load_data != NULL)
    {
        fread(load_data, (sizeof(uint8_t)), BLOCK_SIZE, fptr);
        if( ferror(fptr) != 0 )
        {
            fputs("Error reading file", stderr);
            fclose(fptr);
            free(load_data);
            return 0;
        }

        sysdat_page = load_data[0];
        init_page = load_data[11];
        printf("SYSDAT %u INIT %u\n", sysdat_page, init_page);
        
        memcpy_far((uint8_t *)0x8000, 7, load_data, 0, (sizeof(uint8_t)*BLOCK_SIZE));

        free(load_data);
    }
    
    fseek(fptr, 0, 0);      /* Rewind file for testing */

    /* Read contents from file */
    c = fgetc(fptr);
    while(c != EOF)
    { 
        printf ("%c", c);
        c = fgetc(fptr);
    } 
  
    /* Close file */
    fclose(fptr);
    
    page0Template = (uint8_t *)malloc((sizeof(uint8_t))*PAGE0_SIZE);  /* Get work area for the Page 0 */

    if (page0Template != NULL && argv[2] != NULL)
    {
        memcpy((void *)page0Template, (void *)0x0000, PAGE0_SIZE); /* copy the existing ROM Page0 to our working space */
        /* existing RST0 trap code is contained in this space at 0x0080, and jumps to __Start at 0x0100. */
        /* existing RST jumps and INT0 code is correctly copied. */
        /* do the copy
        memcpy_far((void *)0x0000, 8, page0Template, 0, PAGE0_SIZE);
        /* set bank referenced from _bankLockBase, so the the bank is noted as warm.
        lock_give( &bankLockBase[8] );
        fprintf(output,"Initialised Bank: %01X", bank_get_abs((int8_t)atoi(args[1])) );
        free(page0Template);     */   
    }
    return 0;
}

