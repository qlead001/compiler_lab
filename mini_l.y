/* bison parser for MINI-L programming language */
%{
void yyerror(const char *msg);
extern int currLine;
extern int currPos;
FILE * yyin;
%}

%union{
	char* sval;
 	int ival;
}

%error-verbose
%start 	program
%token	FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY
	END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP
	ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD
	MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN
	R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN
%token	<sval>	IDENT
%token	<ival>	NUMBER
%left	L_PAREN R_PAREN
%left	L_SQUARE_BRACKET R_SQUARE_BRACKET
%right	UMINUS

%%
prog_start:
	functions
	;

functions:
	  \* empty *\
	| function functions
	;
%%

int main(int argc, char ** argv) {
	if(argc >= 2) {
		yyin = fopen(argv[1], "r");
		if(yyin == NULL) {
			yyin = stdin;
		}
	}else{
		yyin = stdin;
	}
	yyparse();

	return 0;
}

void yyerror(const char *msg) {
	printf("Syntax error at line %d, column %d: %s\n",
		currLine, currPos, msg);
}
