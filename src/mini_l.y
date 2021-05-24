/* bison parser for MINI-L programming language */

%{
#include <stdio.h>
#include <string.h>
void yyerror(const char *msg);
void printErr(const char *msg);
void semErr(const char *msg);
void err(const char *msg);
extern int currLine;
extern int currPos;
FILE * yyin;
int ERROR = 0;
int numErr = 0;
int hasMain = 0;

#ifdef	PARSER
	#define	PROD_RULE(rule)		(printf((rule)))
	#define	PROD_RULE1(rule, arg)	(printf((rule), (arg)))
#else
	#define	PROD_RULE(rule)
	#define	PROD_RULE1(rule, arg)
#endif

#define	RECOVER()		ERROR = 0; yyerrok
%}

%union{
	char* identName;
 	int num;
	struct S {
		char* code;
	} statement;
	struct E {
		char* place;
		char* code;
		int isArr;
	} expression;
}

%define parse.error verbose
%define parse.lac full
%locations
%printer { fprintf(yyo, "NUMBER %d", $$); } <num>
%printer { fprintf(yyo, "IDENT %s", $$); } <identName>
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
%token	<identName>	IDENT "identifier"
%token	<num>		NUMBER "number"
%token	UMINUS " -"
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

%type	<statement>	statement
%type	<expression>	expression
%type	<identName>	ident

%%
prog_start:
	functions {
		PROD_RULE("prog_start -> functions\n");
		}
	;

functions:
	  /* epsilon */ {
		PROD_RULE("functions -> epsilon\n");

		if (!hasMain) {
			semErr("missing main function.");
		}
		}
	| function functions {
		PROD_RULE("functions -> function functions\n");
		}
	;

function:
	  FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
		PROD_RULE("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");

		if (strcmp($2, "main") == 0) {
			hasMain = 1;
		}
		}
	| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS error FUNCTION {
		printErr("invalid function, missing body");
		YYBACKUP(FUNCTION,(YYSTYPE)FUNCTION); RECOVER();
		}
	| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS
	  error BEGIN_BODY {
		printErr("invalid function, missing locals");
		RECOVER();
		} statements END_BODY
	| FUNCTION ident SEMICOLON error BEGIN_LOCALS {
		printErr("invalid function, missing parameters");
		RECOVER();
		}
	  declarations END_LOCALS BEGIN_BODY statements END_BODY
	| error FUNCTION {
		printErr("invalid function");
		YYBACKUP(FUNCTION,(YYSTYPE)FUNCTION); RECOVER();
		}
	;

declarations:
	  /* epsilon */ {
		PROD_RULE("declarations -> epsilon\n");
		}
	| declaration SEMICOLON declarations {
		PROD_RULE("declarations -> declaration SEMICOLON declarations\n");
		}
	;

declaration:
	  identifiers COLON INTEGER {
		PROD_RULE("declaration -> identifiers COLON INTEGER\n");
		}
	| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET
	  OF INTEGER {
		PROD_RULE1("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5);
		}
	| identifiers COLON ENUM L_PAREN identifiers R_PAREN {
		PROD_RULE("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n");
		}
	| error {
		printErr("invalid declaration");
		yyclearin; RECOVER();
		}
	;

identifiers:
	  ident {
		PROD_RULE("identifiers -> ident\n");
		}
	| ident COMMA identifiers {
		PROD_RULE("identifiers -> ident COMMA identifiers\n");
		}
	;

ident:
	  IDENT {
		PROD_RULE1("ident -> IDENT %s\n", $1);
		}
	;


statements:
	  statement SEMICOLON {
		PROD_RULE("statements -> statement SEMICOLON\n");
		}
	| statement SEMICOLON statements {
		PROD_RULE("statements -> statement SEMICOLON statements\n");
		}
	;

statement:
	  var ASSIGN expression {
		PROD_RULE("statement -> var ASSIGN expression\n");
		}
	| IF bool_exp THEN statements ENDIF {
		PROD_RULE("statement -> IF bool_exp THEN statements ENDIF\n");
		}
	| IF bool_exp THEN statements ELSE statements ENDIF {
		PROD_RULE("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");
		}
	| WHILE bool_exp BEGINLOOP statements ENDLOOP {
		PROD_RULE("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");
		}
	| DO BEGINLOOP statements ENDLOOP WHILE bool_exp {
		PROD_RULE("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");
		}
	| READ vars {
		PROD_RULE("statement -> READ vars\n");
		}
	| WRITE vars {
		PROD_RULE("statement -> WRITE vars\n");
		}
	| CONTINUE {
		PROD_RULE("statement -> CONTINUE\n");
		}
	| RETURN expression {
		PROD_RULE("statement -> RETURN expression\n");
		}
	| error {
		printErr("invalid statement");
		yyclearin; RECOVER();
		}
	;

bool_exp:
	  relation_and_exp {
		PROD_RULE("bool_exp -> relation_and_exp\n");
		}
	| relation_and_exp OR bool_exp {
		PROD_RULE("bool_exp -> relation_and_exp OR bool_exp\n");
		}
	;

relation_and_exp:
	  relation_exp {
		PROD_RULE("relation_and_exp -> relation_exp\n");
		}
	| relation_exp AND relation_and_exp {
		PROD_RULE("relation_and_exp -> relation_exp AND relation_and_exp\n");
		}
	;

relation_exp:
	  NOT expression comp expression {
		PROD_RULE("relation_exp -> NOT expression comp expression\n");
		}
	| NOT TRUE {
		PROD_RULE("relation_exp -> NOT TRUE\n");
		}
	| NOT FALSE {
		PROD_RULE("relation_exp -> NOT FALSE\n");
		}
	| NOT L_PAREN bool_exp R_PAREN {
		PROD_RULE("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");
		}
	| expression comp expression {
		PROD_RULE("relation_exp -> expression comp expression\n");
		}
	| TRUE {
		PROD_RULE("relation_exp -> TRUE\n");
		}
	| FALSE {
		PROD_RULE("relation_exp -> FALSE\n");
		}
	| L_PAREN bool_exp R_PAREN {
		PROD_RULE("relation_exp -> L_PAREN bool_exp R_PAREN\n");
		}
	;

comp:
	  EQ {
		PROD_RULE("comp -> EQ\n");
		}
	| NEQ {
		PROD_RULE("comp -> NEQ\n");
		}
	| LT {
		PROD_RULE("comp -> LT\n");
		}
	| GT {
		PROD_RULE("comp -> GT\n");
		}
	| LTE {
		PROD_RULE("comp -> LTE\n");
		}
	| GTE {
		PROD_RULE("comp -> GTE\n");
		}
	;

expressions:
	  /* epsilon */ {
		PROD_RULE("expressions -> epsilon\n");
		}
	| expression {
		PROD_RULE("expressions -> expression\n");
		}
	| expression COMMA expressions {
		PROD_RULE("expressions -> expression COMMA expressions\n");
		}
	;

expression:
	  multiplicative_expression {
		PROD_RULE("expression -> multiplicative_expression\n");
		}
	| multiplicative_expression SUB expression {
		PROD_RULE("expression -> multiplicative_expression SUB expression\n");
		}
	| multiplicative_expression ADD expression {
		PROD_RULE("expression -> multiplicative_expression ADD expression\n");
		}
	| error {
		printErr("invalid expression");
		yyclearin; RECOVER();
		}
	;

multiplicative_expression:
	  term {
		PROD_RULE("multiplicative_expression -> term\n");
		}
	| term MOD multiplicative_expression {
		PROD_RULE("multiplicative_expression -> term MOD multiplicative_expression\n");
		}
	| term DIV multiplicative_expression {
		PROD_RULE("multiplicative_expression -> term DIV multiplicative_expression\n");
		}
	| term MULT multiplicative_expression {
		PROD_RULE("multiplicative_expression -> term MULT multiplicative_expression\n");
		}
	;

term:
	  SUB var %prec UMINUS {
		PROD_RULE("term -> SUB var\n");
		}
	| SUB NUMBER %prec UMINUS {
		PROD_RULE1("term -> SUB NUMBER %d\n", $2);
		}
	| SUB L_PAREN expression R_PAREN %prec UMINUS {
		PROD_RULE("term -> SUB L_PAREN expression R_PAREN\n");
		}
	| var {
		PROD_RULE("term -> var\n");
		}
	| NUMBER {
		PROD_RULE1("term -> NUMBER %d\n", $1);
		}
	| L_PAREN expression R_PAREN {
		PROD_RULE("term -> L_PAREN expression R_PAREN\n");
		}
	| ident L_PAREN expressions R_PAREN {
		PROD_RULE("term -> ident L_PAREN expressions R_PAREN\n");
		}
	;

vars:
	  var {
		PROD_RULE("vars -> var\n");
		}
	| var COMMA vars {
		PROD_RULE("vars -> var COMMA vars\n");
		}
	;

var:
	  ident {
		PROD_RULE("var -> ident\n");
		}
	| ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
		PROD_RULE("var -> ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");
		}
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
	err(msg);
}

void semErr(const char *msg) {
#ifndef	PARSER
	err(msg);
#endif
}

void err(const char *msg) {
	numErr++;
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
	if (!ERROR) {
		numErr++;
		ERROR = 1;
		char spaces[NSPACES+1];
		int i;
		for (i = 0; i < NSPACES; i++)
			spaces[i] = ' ';
		spaces[NSPACES] = '\0';
		fprintf(stderr, "%s\t%s\n", spaces, msg);
	}
}
