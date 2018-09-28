/*	Standard utility functions */

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

#define	RAND_MAX	32767		/* max value returned by rand() */

extern double	atof(char *);
extern int	atoi(char *);
extern long	atol(char *);
extern int	rand(void);
extern void	srand(unsigned int);
extern void *	calloc(size_t, size_t);
extern void	free(void *);
extern void *	malloc(size_t);
extern void *	realloc(void *, size_t);
extern void	abort(void);
extern void	exit(int);
extern char *	getenv(char *);
extern int	system(char *);
extern void	qsort(void *, size_t, size_t, int (*)(void *, void *));
extern int	abs(int);
extern long	labs(long);
\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00
