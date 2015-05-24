PROG = pl0scm
SRCS = y.tab.c lex.yy.c
OBJS = ${SRCS:%.c=%.o}
CFLAGS = -Wall

CC ?= gcc

ifdef USE_FLEX
	LEX = flex
	LEX_FLAGS = -8
else
	LEX = lex
	LEX_FLAFS =
endif

ifdef USE_BISON
	YACC = bison
	YACC_FLAGS = -dy -v
else
	YACC = yacc
	YACC_FLAGS = -d -v
endif

all:	${PROG}

${PROG}: y.tab.c lex.yy.c
	${CC} -o $@ ${CFLAGS} ${SRCS}

lex.yy.c: pl0lex.l
	${LEX} ${LEX_FLAGS} $<

y.tab.c: pl0scm.y
	${YACC} ${YACC_FLAGS} $<

clean:
	-rm ${PROG} ${OBJS} y.tab.h y.tab.c lex.yy.c y.output
