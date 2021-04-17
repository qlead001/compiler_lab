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
%left	MULT DIV MOD
%left	ADD SUB
%left	LT LTE GT GTE EQ NEQ
%right	NOT
%left	AND
%left	OR
%right	ASSIGN

%%
prog_start:
	functions
	;

functions:
	  /* epsilon */
	| function functions
	;

function:
	  FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
	;

declarations:
	  /* epsilon */
	| declaration SEMICOLON declarations
	;

declaration:
	  identifiers COLON INTEGER
	| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET
	  OF INTEGER
	| identifiers COLON ENUM L_PAREN identifiers R_PAREN
	;

identifiers:
	  ident
	| ident COMMA identifiers
	;

ident:
	  IDENT
	;

statements:
	  /* epsilon */
	| statement SEMICOLON statements
	;

statement:
	  var ASSIGN expression
	| IF bool_exp THEN statements ENDIF
	| IF bool_exp THEN statements ELSE statements ENDIF
	| WHILE bool_exp BEGINLOOP statements ENDLOOP
	| DO BEGINLOOP statements ENDLOOP WHILE bool_exp
	| READ vars
	| WRITE vars
	| CONTINUE
	| RETURN expression
	;

bool_exp:
	  relation_and_exp
	| relation_and_exp OR relation_and_exp
	;

relation_and_exp:
	  relation_exp
	| relation_exp AND relation_exp
	;

relation_exp:
	  NOT expression comp expression
	| NOT TRUE
	| NOT FALSE
	| NOT L_PAREN bool_exp R_PAREN
	| expression comp expression
	| TRUE
	| FALSE
	| L_PAREN bool_exp R_PAREN
	;

comp:
	  EQ
	| NEQ
	| LT
	| GT
	| LTE
	| GTE
	;

expression:
	  multiplicative_expression
	| multiplicative_expression ADD multiplicative_expression
	| multiplicative_expression SUB multiplicative_expression
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
