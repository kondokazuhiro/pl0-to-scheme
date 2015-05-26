struct Node;

typedef struct Farg {
	struct Node *node;
	struct Farg *next;
} Farg;

typedef struct Node {
	char op;
	long val;
	char *ident;
	Farg *arglist;
	struct Node *left;
	struct Node *right;
} Node;

void inc_line_num();

void *hold_memory(void *memory);
void free_memory_holder();
