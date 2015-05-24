CC ?= gcc

PROG = pl0scm
SRCS = y.tab.c lex.yy.c
OBJS = ${SRCS:%.c=%.o}
CFLAGS = -Wall

all:	${PROG}

${PROG}: y.tab.c lex.yy.c
	${CC} -o $@ ${CFLAGS} ${SRCS}

lex.yy.c: pl0lex.l
	lex $<

y.tab.c: pl0scm.y
	yacc -d -v $<

clean:
	-rm ${PROG} ${OBJS} y.tab.h y.tab.c lex.yy.c y.output
