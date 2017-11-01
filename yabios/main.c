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

#include "ffconf.h"
#include <lib/yaz180/ff.h>
#include <lib/yaz180/time.h>

/*
  Function Declarations for builtin shell commands:
 */
int8_t ya_cd(char **args);
int8_t ya_help(char **args);
int8_t ya_exit(char **args);


/*
  List of builtin commands.
 */
struct Builtin {
  char *name;
  int8_t (*func) (char** args);
};

struct Builtin builtins[] = {
  { "cd", &ya_cd },
  { "help", &ya_help },
  { "exit", &ya_exit }
};


uint8_t ya_num_builtins() {
  return sizeof(builtins) / sizeof(struct Builtin);
}

/*
  Builtin function implementations.
*/

/**
   @brief Builtin command: change directory.
   @param args List of args.  args[0] is "cd".  args[1] is the directory.
   @return Always returns 1, to continue executing.
 */
int8_t ya_cd(char **args)
{
    if (args[1] == NULL) {
        fprintf(stderr, "yash: expected argument to \"cd\"\n");
    } else {
        if (f_chdir(args[1]) != 0) {
            perror("yash");
        }
    }
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
    return 0;
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
    FATFS *fs;                          /* Pointer to the filesystem object */
    FILINFO Finfo;
    FIL FileOut, FileIn;                /* File object needed for each open file */

    set_zone((int32_t)11 * ONE_HOUR);   /* Australian Eastern Standard Time */
    set_system_time(1506083467 - UNIX_OFFSET);

    fs = malloc(sizeof(FATFS));         /* Get work area for the volume */
    
    f_mount(fs, "", 1);

    // Load config files, if any.

    // Run command loop.
    ya_loop();

    // Perform any shutdown/cleanup.
    
    free(fs);

    return;
}

