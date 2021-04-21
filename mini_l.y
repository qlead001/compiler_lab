/* bison parser for MINI-L programming language */
%{
#include <stdio.h>
#include <string.h>
void yyerror(const char *msg);
void printErr(const char *msg);
extern int currLine;
extern int currPos;
FILE * yyin;
%}

%union{
	char* sval;
 	int ival;
}

%define parse.error verbose
%define parse.lac full
%locations
%printer { fprintf(yyo, "NUMBER %d", $$); } <ival>
%printer { fprintf(yyo, "IDENT %s", $$); } <sval>
%start 	prog_start
%token	FUNCTION "function" BEGIN_PARAMS "beginparams" END_PARAMS "endparams"
	BEGIN_LOCALS "beginlocals" END_LOCALS "endlocals" BEGIN_BODY "beginbody"
	END_BODY "endbody" INTEGER "integer" ARRAY "array" ENUM "enum" OF "of"
	IF "if" THEN "then" ENDIF "endif" ELSE "else" WHILE "while" DO "do"
	BEGINLOOP "beginloop" ENDLOOP "endloop" CONTINUE "continue" READ "read"
	WRITE "write" AND "and" OR "or" NOT "not" TRUE "true" FALSE "false"
	RETURN "return" SUB "-" ADD "+" MULT "*" DIV "/" MOD "%" EQ "==" NEQ "<>"
	LT "<" GT ">" LTE "<=" GTE ">=" SEMICOLON ";" COLON ":" COMMA ","
	L_PAREN "(" R_PAREN ")" L_SQUARE_BRACKET "[" R_SQUARE_BRACKET "]"
	ASSIGN ":="
%token	<sval>	IDENT "identifier"
%token	<ival>	NUMBER "number"
%left	L_PAREN R_PAREN
%left	L_SQUARE_BRACKET R_SQUARE_BRACKET
%right	UMINUS " -"
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
	  FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
	| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS error END_BODY {
		printErr("invalid function, missing body");
		yyclearin; yyerrok;
		}
	;

declarations:
	  /* epsilon */
	| declaration SEMICOLON declarations
	| error SEMICOLON {
		printErr("invalid declaration");
		yyclearin; yyerrok;
		}
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
	| relation_and_exp OR bool_exp
/*
	| relation_and_exp OR relation_and_exp
*/
	;

relation_and_exp:
	  relation_exp
	| relation_exp AND relation_and_exp
/*
	| relation_exp AND relation_exp
*/
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

expressions:
	  /* epsilon */
	| expression COMMA expressions
	;

expression:
	  multiplicative_expression
	| multiplicative_expression SUB expression
	| multiplicative_expression ADD expression
/*
	| multiplicative_expression SUB multiplicative_expression
	| multiplicative_expression ADD multiplicative_expression
*/
	;

multiplicative_expression:
	  term
	| term MOD term
	| term DIV term
	| term MULT term
	;

term:
	  SUB var %prec UMINUS
	| SUB NUMBER %prec UMINUS
	| SUB L_PAREN expression R_PAREN %prec UMINUS
	| var
	| NUMBER
	| L_PAREN expression R_PAREN
	| ident L_PAREN expression R_PAREN
	| ident L_PAREN expressions R_PAREN
/* Wrong?
	| ident L_PAREN R_PAREN
*/
	;

vars:
	  var
	| var COMMA vars
	;

var:
	  ident
	| ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET
	;
%%

int main(int argc, char ** argv) {
	#if YYDEBUG
		yydebug = 1;
	#endif
	if (argc >= 2) {
		yyin = fopen(argv[1], "r");
		if (yyin == NULL) {
			yyin = stdin;
		}
	}else{
		yyin = stdin;
	}

	return yyparse();
}

void yyerror(const char *msg) {
	if (strlen(msg) > 15) {
		char dest[15];
		strncpy(dest, msg, 14);
		dest[14] = '\0';
		if (!strcmp(dest, "syntax error, ")) {
			fprintf(stderr, "Syntax error ");
			msg += 14;
		} else
			fprintf(stderr, "Error ");
	} else
		fprintf(stderr, "Error ");

	if (yylloc.first_line != yylloc.last_line)
		fprintf(stderr, "on lines %d-%d:\t%s\n", yylloc.first_line,
			yylloc.last_line, msg);
	else if (yylloc.first_column != yylloc.last_column)
		fprintf(stderr, "at line %d, columns %d-%d:\t%s\n",
			yylloc.first_line, yylloc.first_column,
			yylloc.last_column, msg);
	else
		fprintf(stderr, "at line %d, column %d:\t%s\n",
			yylloc.first_line, yylloc.first_column, msg);
}

#define	NSPACES	37
void printErr(const char *msg) {
	char spaces[NSPACES+1];
	int i;
	for (i = 0; i < NSPACES; i++)
		spaces[i] = ' ';
	spaces[NSPACES] = '\0';
	fprintf(stderr, "%s\t%s\n", spaces, msg);
}
