# pl0-to-scheme

Translate from PL/0 to Scheme 

## Build

	make

require lex, yacc.

## Run

	src/pl0scm < examples/hanoi.pl0

## Run with Gauche

	src/pl0scm < examples/hanoi.pl0 | gosh
