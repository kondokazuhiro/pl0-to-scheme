%{

#include <string.h>
#include "pl0def.h"
#include "y.tab.h"

#define STRBUF_SIZE	256
static char strbuf[STRBUF_SIZE];
static int strcnt;

%}

%start	COMMENT STR

%%
<INITIAL>"const"	return B_CONST;
<INITIAL>"var"	return B_VAR;
<INITIAL>"procedure"	return B_PROCEDURE;
<INITIAL>"function"	return B_FUNCTION;
<INITIAL>"begin"	return B_BEGIN;
<INITIAL>"end"	return B_END;
<INITIAL>"if"	return B_IF;
<INITIAL>"then"	return B_THEN;
<INITIAL>"else"	return B_ELSE;
<INITIAL>"while"	return B_WHILE;
<INITIAL>"do"	return B_DO;
<INITIAL>"call"	return B_CALL;
<INITIAL>"odd"	return ODD;
<INITIAL>"writeln"	return WRITELN;
<INITIAL>"write"	return WRITE;
<INITIAL>"="	{ strcpy(yylval.op, yytext); return EQOP;}
<INITIAL>"<>"	{ strcpy(yylval.op, yytext); return COMPOP;}
<INITIAL>"<"	{ strcpy(yylval.op, yytext); return COMPOP;}
<INITIAL>">"	{ strcpy(yylval.op, yytext); return COMPOP;}
<INITIAL>"<="	{ strcpy(yylval.op, yytext); return COMPOP;}
<INITIAL>">="	{ strcpy(yylval.op, yytext); return COMPOP;}
<INITIAL>":="	return ASSIGNOP;
<INITIAL>"+"	return ADDOP;
<INITIAL>"-"	return SUBOP;
<INITIAL>"*"	return MULOP;
<INITIAL>"/"	return DIVOP;
<INITIAL>"("	return LP;
<INITIAL>")"	return RP;
<INITIAL>[0-9]+	{ yylval.val = atol(yytext); return NUMBER; }
<INITIAL>[_A-Za-z]+[_A-Za-z0-9]*	{
					yylval.ident = strdup(yytext);
					return IDENT;
					}
<INITIAL>[ \t]	;
<INITIAL>"\n"	inc_line_num();
<INITIAL>"{"	BEGIN COMMENT;
<INITIAL>\"	{ strcnt = 0; BEGIN STR; }
<INITIAL>.	return yytext[0];
<COMMENT>"}"	BEGIN INITIAL;
<COMMENT>"\n"	inc_line_num();
<COMMENT>.	;
<STR>\"		{
			if (strcnt >= STRBUF_SIZE - 1)
				return 0;
			strbuf[strcnt] = '\0';
			yylval.string = strdup(strbuf);
			BEGIN INITIAL;
			return STRING;
		}
<STR>\\n	{
			if (strcnt < STRBUF_SIZE - 1)
				strbuf[strcnt++] = '\n';
		}
<STR>\\e	{
			if (strcnt < STRBUF_SIZE - 1)
				strbuf[strcnt++] = 0x1b;
		}
<STR>\\\"	{
			if (strcnt < STRBUF_SIZE - 1)
				strbuf[strcnt++] = '"';
		}
<STR>\n		{
			return 0;
		}
<STR>.		{
			if (strcnt < STRBUF_SIZE - 1)
				strbuf[strcnt++] = yytext[0];
		}
%%
