%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "pl0def.h"

int yylex(void);
void yyerror(char* msg);

#define FUNC_RESULT_SUFFIX "-result"

static int n_indent = 0;

void put_indent();
Farg *new_farg(Node *pnode, Farg *top);
Node *new_node(char op, long val, char *ident, Farg *arglist,
		Node *left, Node *right);
void block_start();
void block_dec_end();
void block_end();
void proc_start(char *procname);
void proc_arg_end();
void proc_end();
void gen_condition(char *op, Node *lp, Node *rp);
void gen_odd(Node *p);
void gen_assign(char *ident, Node *p);
void gen_expr(Node *p);
void push_named_block(char *name);
void pop_named_block();
const char *get_current_block_name();

%}

%union {
	Node *pnode;
	Farg *farg;
	long val;
	char op[3];
	char *ident;
	char *string;
}

%type	<pnode>	expr
%type	<farg> farg farg_list
%token	B_CONST B_VAR B_PROCEDURE B_FUNCTION
%token	B_BEGIN B_END B_IF B_THEN B_ELSE B_WHILE B_DO B_CALL
%token	<val> NUMBER
%token	<op> COMPOP EQOP
%token	ODD WRITE WRITELN
%token	ASSIGNOP
%token	<ident> IDENT
%token	<string> STRING
%token	LP
%token	RP
%left	ADDOP SUBOP
%left	MULOP DIVOP
%right	UMINUS

%%

program
	: block '.'		{ YYACCEPT; }
	;
block
	: block_start const_dec var_dec block_dec_end proc_func_dec statement
				{ block_end(); }
	;
block_start
	: /* empty */		{ block_start(); }
	;
block_dec_end
	: /* empty */		{ block_dec_end(); }
	;
const_dec
	: /* empty */
	| B_CONST const_list ';'
	;
const_list
	: const_elem
	| const_list ',' const_elem
	;
const_elem
	: IDENT EQOP NUMBER	{ put_indent();printf("  (%s %ld);const\n",$1,$3);}
	;
var_dec
	: /* empty */
	| B_VAR var_list ';'
	;
var_list
	: var_elem
	| var_list ',' var_elem
	;
var_elem
	: IDENT			{ put_indent(); printf("  (%s 0)\n",$1); }
	;
proc_func_dec
	: /* empty */
	| proc_func_dec proc_func
	;
proc_func
	: proc_list
	| func_list
	;
proc_list
	: B_PROCEDURE IDENT	{ proc_start($2); }
	  arg_list_dec ';'	{ proc_arg_end(); }
	  block ';'		{ proc_end(); }
	;
func_list
	: B_FUNCTION IDENT	{ proc_start($2); push_named_block($2); }
	  arg_list_dec ';'	{ proc_arg_end(); }
	  block ';'		{ proc_end(); pop_named_block(); }
	;
arg_list_dec
	: /* empty */
	| LP arg_list RP
	;
arg_list
	: arg_elem
	| arg_list ',' arg_elem
	;
arg_elem
	: IDENT			{ printf(" %s", $1); }
	;
statement
	: /* empty */
	| assign
	| call_stmt
	| block_stmt
	| if_stmt
	| while_stmt
	| writeln_stmt
	| write_stmt
	;
stmt_list
	: statement
	| stmt_list ';' statement	{ free_memory_holder(); }
	;
block_stmt
	: B_BEGIN		{ put_indent(); printf("(begin\n"); n_indent++; }
	  stmt_list B_END	{ n_indent--; put_indent(); printf(")\n"); }
	;
assign
	: IDENT ASSIGNOP expr	{ gen_assign($1, $3); }
	;
call_stmt
	: B_CALL IDENT		{ put_indent(); printf("(%s ", $2); }
	  actual_arg		{ printf(")\n"); }
	;
actual_arg
	: /* empty */
	| LP expr_list RP
	;
expr_list
	: expr			{ gen_expr($1); }
	| expr_list ',' expr	{ gen_expr($3); }
	;
if_stmt
	: B_IF			{ put_indent(); printf("(if "); n_indent++; }
	  condition B_THEN	{ printf("\n"); }
	  statement		{ n_indent--; }
	  else_part		{ put_indent(); printf(")\n"); }
	;
else_part
	: /* empty */
	| B_ELSE		{ n_indent++; }
	  statement		{ n_indent--; }
	;
while_stmt
	: B_WHILE		{ put_indent(); printf("(while "); n_indent++; }
	  condition B_DO	{ printf("\n"); }
	  statement		{ n_indent--; put_indent(); printf(")\n"); }
	;
writeln_stmt
	: WRITELN		{ put_indent(); printf("(display \"\\n\")\n"); }
	| WRITELN LP write_list RP
				{ put_indent(); printf("(display \"\\n\")\n"); }
	;
write_stmt
	: WRITE LP write_list RP
	;
write_list
	: write_elem
	| write_list ',' write_elem
	;
write_elem
	: expr		{ put_indent(); printf("(display ");
				gen_expr($1); printf(")\n"); }
	| STRING	{ put_indent(); printf("(display \"%s\")\n", $1); }
	;
condition
	: expr COMPOP expr	{ gen_condition($2, $1, $3); }
	| expr EQOP expr	{ gen_condition($2, $1, $3); }
	| ODD expr		{ gen_odd($2); }
	;
expr
	: expr ADDOP expr	{ $$ = new_node('+', 0, NULL, NULL, $1, $3); }
	| expr SUBOP expr	{ $$ = new_node('-', 0, NULL, NULL, $1, $3); }
	| expr MULOP expr	{ $$ = new_node('*', 0, NULL, NULL, $1, $3); }
	| expr DIVOP expr	{ $$ = new_node('/', 0, NULL, NULL, $1, $3); }
	| LP expr RP		{ $$ = $2; }
	| SUBOP expr %prec UMINUS
				{ $$ = new_node('M', 0, NULL, NULL, NULL, $2); }
	| NUMBER		{ $$ = new_node('C', $1, NULL,NULL,NULL,NULL); }
	| IDENT			{ $$ = new_node('I', 0, $1, NULL, NULL, NULL); }
	| IDENT LP farg RP	{ $$ = new_node('F', 0, $1, $3, NULL, NULL); }
	;
farg
	: /* empty */		{ $$ = NULL; }
	| farg_list		{ $$ = $1; }
	; 
farg_list
	: expr			{ $$ = new_farg($1, NULL); }
	| farg_list ',' expr	{ $$ = new_farg($3, $1); }
	;
%%

static int line_num = 1;

void inc_line_num()
{
	line_num++;
}

int main()
{
	extern int yyparse();
	int exit_code;

	exit_code = yyparse();
	free_memory_holder();
	return exit_code;
}

void yyerror(char *s)
{
	fprintf(stderr, "(%d): %s\n", line_num, s);
}

int yywrap(void)
{
    return 1;
}

void put_indent()
{
	int i;

	for (i = 0; i < n_indent; i++) {
		printf("  ");
	}
}

Farg *new_farg(Node *pnode, Farg *top)
{
	Farg *farg_ptr = hold_memory(malloc(sizeof (Farg)));
	Farg *res = farg_ptr;
	Farg *p;

	assert(farg_ptr != NULL);

	farg_ptr->node = pnode;
	farg_ptr->next = NULL;
	if (top != NULL) {
		res = top;
		for (p = top; p->next != NULL; p = p->next)
			;
		p->next = farg_ptr;
	}
	return res;
}

Node *new_node(char op, long val, char *ident, Farg *arglist,
		Node *left, Node *right)
{
	Node *node_ptr = hold_memory(malloc(sizeof (Node)));
	assert(node_ptr != NULL);

	node_ptr->op = op;
	node_ptr->val = val;
	node_ptr->ident = ident;
	node_ptr->arglist = arglist;
	node_ptr->left = left;
	node_ptr->right = right;
	return node_ptr;
}

void block_start()
{
	const char *blockName = get_current_block_name();

	put_indent();
	printf("(let (");
	if (blockName != NULL) {
		printf("(%s%s #f)", blockName, FUNC_RESULT_SUFFIX);
	}
	printf("\n");
	n_indent++;
}

void block_dec_end()
{
	put_indent();
	printf(")\n");
}

void block_end()
{
	const char *blockName = get_current_block_name();

	if (blockName != NULL) {
		put_indent();
		printf("%s%s\n", blockName, FUNC_RESULT_SUFFIX);
	}
	n_indent--;
	put_indent();
	printf(")\n");
}

void proc_start(char *procname)
{
	put_indent();
	printf("(define (%s ", procname);
	n_indent++;
}

void proc_arg_end()
{
	printf(")\n");
}

void proc_end()
{
	n_indent--;
	put_indent();
	printf(")\n");
}

void gen_condition(char *op, Node *lp, Node *rp)
{
	printf("(%s", op);
	gen_expr(lp);
	gen_expr(rp);
	printf(")");
}

void gen_odd(Node *p)
{
	printf("(odd? ");
	gen_expr(p);
	printf(")");
}

void gen_assign(char *ident, Node *p)
{
	const char *blockName = get_current_block_name();

	put_indent();
	if (blockName != NULL && strcmp(ident, blockName) == 0) {
		printf("(set! %s%s ", blockName, FUNC_RESULT_SUFFIX);
	} else {
		printf("(set! %s ", ident);
	}
	gen_expr(p);
	printf(")\n");
}

void gen_expr(Node *p)
{
	Node *l = p->left;
	Node *r = p->right;
	Farg *args = p->arglist;

	printf(" ");
	switch (p->op) {
	case '+':
		printf("(+");
		gen_expr(l);
		gen_expr(r);
		printf(")");
		break;
	case '-':
		printf("(-");
		gen_expr(l);
		gen_expr(r);
		printf(")");
		break;
	case '*':
		printf("(*");
		gen_expr(l);
		gen_expr(r);
		printf(")");
		break;
	case '/':
		printf("(/");
		gen_expr(l);
		gen_expr(r);
		printf(")");
		break;
	case 'M':
		assert(r != NULL);
		printf("(- ");
		gen_expr(r);
		printf(")");
		break;
	case 'C':
		printf("%ld", p->val);
		break;
	case 'I':
		printf("%s", p->ident);
		break;
	case 'F':	/* function */
		printf("(%s ", p->ident);
		while (args != NULL) {
			gen_expr(args->node);
			args = args->next;
		}
		printf(")");
		break;
	}
}

/*----------------------------------------------------------------*/

typedef struct {
	char *name;
} NamedBlock;

#define MAX_NAMED_BLOCKS	256
static NamedBlock named_blocks[MAX_NAMED_BLOCKS];
static int named_block_index = 0;

void push_named_block(char *name)
{
	NamedBlock *bp;

	assert(named_block_index < MAX_NAMED_BLOCKS - 1);

	bp = &named_blocks[++named_block_index];
	bp->name = strdup(name);
	assert(bp->name != NULL);
}

void pop_named_block()
{
	assert(named_block_index > 0);
	free(named_blocks[named_block_index].name);
	named_block_index--;
}

const char *get_current_block_name()
{
	return named_blocks[named_block_index].name;
}

/*----------------------------------------------------------------*/

typedef struct MemoryHolder {
	void *memory;
	struct MemoryHolder *next;
} MemoryHolder;

static MemoryHolder *memory_holder_head = NULL;

void *hold_memory(void *memory)
{
	MemoryHolder *hp = malloc(sizeof (MemoryHolder));

	assert(memory != NULL);
	assert(hp != NULL);

	hp->memory = memory;
	hp->next = memory_holder_head;
	memory_holder_head = hp;
	return memory;
}

void free_memory_holder()
{
	MemoryHolder *hp = memory_holder_head;
	while (hp != NULL) {
		MemoryHolder *next = hp->next;
		free(hp->memory);
		free(hp);
		hp = next;
	}
	memory_holder_head = NULL;
}
