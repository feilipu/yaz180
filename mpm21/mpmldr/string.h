/*	String functions */

#ifndef	_STDDEF
typedef	int		ptrdiff_t;	/* result type of pointer difference */
typedef	unsigned	size_t;		/* type yielded by sizeof */

typedef unsigned char uint8_t;
typedef char          int8_t;
typedef unsigned int  uint16_t;
typedef int           int16_t;
typedef unsigned long uint32_t;
typedef long          int32_t;

#define	_STDDEF
#define	offsetof(ty, mem)	((int)&(((ty *)0)->mem))
#endif	_STDDEF

#ifndef	NULL
#define	NULL	((void *)0)
#endif	NULL

extern int	errno;			/* system error number */

extern void *	memcpy(void *, void *, size_t);
extern void *	memmove(void *, void *, size_t);
extern char *	strcpy(char *, char *);
extern char *	strncpy(char *, char *, size_t);
extern char *	strcat(char *, char *);
extern char *	strncat(char *, char *, size_t);
extern int	memcmp(void *, void *, size_t);
extern int	strcmp(char *, char *);
extern int	strncmp(char *, char *, size_t);
extern size_t	strcoll(char *, size_t, char *);
extern void *	memchr(void *, int, size_t);
extern size_t	strcspn(char *, char *);
extern char *	strpbrk(char *, char *);
extern size_t	strspn(char *, char *);
extern char *	strstr(char *, char *);
extern char *	strtok(char *, char *);
extern void *	memset(void *, int, size_t);
extern char *	strerror(int);
extern size_t	strlen(char *);
extern char *	strchr(char *, int);
extern char *	strrchr(char *, int);
\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00
