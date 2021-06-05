/* bison parser for MINI-L programming language */

%{
#include <stdio.h>
#include <string.h>

void yyerror(const char *msg);
void printErr(const char *msg);
void err(const char *msg);
extern int currLine;
extern int currPos;
FILE * yyin;
int ERROR = 0;
int numErr = 0;
#define	free(a) 
#define	freeStrArr(a) 
#ifdef	PARSER
	#include "parser_str.h"
	#define	PROD_RULE(rule)		(printf((rule)))
	#define	PROD_RULE1(rule, arg)	(printf((rule), (arg)))
#else
	#include "str.h"
	#include "code_gen.h"
	#define	PROD_RULE(rule)
	#define	PROD_RULE1(rule, arg)
	#define	semErr(msg)	(err((msg)))
#endif

#define	RECOVER()		ERROR = 0; yyerrok
%}

%code requires {
	#include "str.h"
	#include "code_gen.h"
}

%union{
	str strval;
 	int num;
	stmt statement;
	expr expression;
	exprs expressions;
	var varval;
	vars varvals;
	strArr strs;
}

%define parse.error verbose
%define parse.lac full
%locations
%printer { fprintf(yyo, "NUMBER %d", $$); } <num>
%printer { fprintf(yyo, "%s", $$); } <strval>
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
%token	<strval>	IDENT "identifier"
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

%type	<statement>	functions function statements statement
%type	<expression>	bool_exp relation_and_exp relation_exp expression
			multiplicative_expression term
%type	<expressions>	expressions
%type	<strval>	ident comp
%type	<strs>		declarations declaration identifiers
%type	<varval>	var
%type	<varvals>	vars

%%
prog_start:
	functions {
		PROD_RULE("prog_start -> functions\n");

		if (numErr == 0) {
			STRSTR($1)[STRLEN($1)-10] = '\0';
			puts(STRSTR($1));
			puts("\n");
		}
		}
	;

functions:
	  /* epsilon */ {
		PROD_RULE("functions -> epsilon\n");
		
		str s = strFrom("main");
		if (!IS_FUNC(s)) {
			semErr("missing main function.");
		}
		freeStr(&s);
		}
	| function functions {
		PROD_RULE("functions -> function functions\n");

		concatln(&$1, &$2, NULL);
		freeStr(&$2);
		$$ = $1;
		}
	;

function:
	  FUNCTION ident SEMICOLON {
		if(IS_FUNC($2)) {
			str msg = strFrom(STRSTR($2));
			appendStr(&msg, " function defined twice.");
			semErr(STRSTR(msg));
			freeStr(&msg);
			freeStr(&$2);
		} else {
			str ident = $2;
			push(&funcTable, &ident);
		}
	} BEGIN_PARAMS declarations END_PARAMS
	  BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
		PROD_RULE("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");
		stmt params = gen_params($6);
		stmt locals = gen_decls($9);
		$$ = gen_func($2, params, locals, $12);
		freeStrArr(&$6); freeStrArr(&$9); freeStr(&$12);
		freeStr(&params); freeStr(&locals);
		dumpVars();
		}
/*
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
*/
	;

declarations:
	  /* epsilon */ {
		PROD_RULE("declarations -> epsilon\n");
		}
	| declaration SEMICOLON declarations {
		PROD_RULE("declarations -> declaration SEMICOLON declarations\n");
		
		int i;
		for (i = 0; i < ARRLEN($3); i++) {
			push(&$1, &(ARR($3)[i]));
		}
		free(ARR($3));
		$$ = $1;
		}
	;

declaration:
	  identifiers COLON INTEGER {
		PROD_RULE("declaration -> identifiers COLON INTEGER\n");

		int i;
		for (i = 0; i < ARRLEN($1); i++) {
			str ident = GETSTR($1, i);
			if (IS_INT(ident) || IS_ARR(ident) || IS_ENUM(ident)) {
				str msg = strFrom(STRSTR(ident));
				appendStr(&msg, " is defined multiple times.");
				semErr(STRSTR(msg));
				freeStr(&msg);
				freeStr(&ident);
			} else
				push(&intTable, &ident);
		}
		$$ = $1;
		}
	| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET
	  OF INTEGER {
		PROD_RULE1("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5);

		int i;
		for (i = 0; i < ARRLEN($1); i++) {
			str ident = GETSTR($1, i);
			if (IS_INT(ident) || IS_ARR(ident) || IS_ENUM(ident)) {
				str msg = strFrom(STRSTR(ident));
				appendStr(&msg, " is defined multiple times.");
				semErr(STRSTR(msg));
				freeStr(&msg);
				freeStr(&ident);
			} else {
				arrSizeTable[ARRLEN(arrTable)] = $5;
				push(&arrTable, &ident);
			}
		}
		if ($5 <= 0)
			semErr("Cannot declare an array with size <= 0.");
		$$ = $1;
		}
	| identifiers COLON ENUM L_PAREN identifiers R_PAREN {
		PROD_RULE("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n");

		int i;
		for (i = 0; i < ARRLEN($1); i++) {
			str ident = GETSTR($1, i);
			if (IS_INT(ident) || IS_ARR(ident) || IS_ENUM(ident)) {
				str msg = strFrom(STRSTR(ident));
				appendStr(&msg, " is defined multiple times.");
				semErr(STRSTR(msg));
				freeStr(&msg);
				freeStr(&ident);
			} else
				push(&intTable, &ident);
		}
		for (i = 0; i < ARRLEN($5); i++) {
			str ident = GETSTR($5, i);
			if (IS_INT(ident) || IS_ARR(ident) || IS_ENUM(ident)) {
				str msg = strFrom(STRSTR(ident));
				appendStr(&msg, " is defined multiple times.");
				semErr(STRSTR(msg));
				freeStr(&msg);
				freeStr(&ident);
			} else
				push(&enumTable, &ident);
			push(&$1, &(ARR($5)[i]));
		}
		free(ARR($5));
		$$ = $1;
		}
	| error {
		printErr("invalid declaration");
		yyclearin; RECOVER();
		}
	;

identifiers:
	  ident {
		PROD_RULE("identifiers -> ident\n");

		$$ = newStrArr();
		push(&$$, &$1);
		}
	| ident COMMA identifiers {
		PROD_RULE("identifiers -> ident COMMA identifiers\n");

		push(&$3, &$1);
		$$ = $3;
		}
	;

ident:
	  IDENT {
		PROD_RULE1("ident -> IDENT %s\n", STRSTR($1));
		}
	;


statements:
	  statement SEMICOLON {
		PROD_RULE("statements -> statement SEMICOLON\n");
		}
	| statement SEMICOLON statements {
		PROD_RULE("statements -> statement SEMICOLON statements\n");

		concatln(&$1, &$3, NULL);
		freeStr(&$3);
		$$ = $1;
		}
	;

statement:
	  var ASSIGN expression {
		PROD_RULE("statement -> var ASSIGN expression\n");
		$$ = gen_assign($1, $3);
		freeStr(&($1.name));
		freeStr(&($1.arrIndex.code)); freeStr(&($1.arrIndex.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| IF bool_exp THEN statements ENDIF {
		PROD_RULE("statement -> IF bool_exp THEN statements ENDIF\n");
		$$ = gen_if($2, $4);
		freeStr(&($2.code)); freeStr(&($2.place));
		freeStr(&$4);
		}
	| IF bool_exp THEN statements ELSE statements ENDIF {
		PROD_RULE("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");
		$$ = gen_if_else($2, $4, $6);
		freeStr(&($2.code)); freeStr(&($2.place));
		freeStr(&$4); freeStr(&$6);
		}
	| WHILE bool_exp BEGINLOOP {str temp = newLabel(); push(&loopStack, &temp);}
	  statements ENDLOOP {
		PROD_RULE("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");
		$$ = gen_while($2, $5);
		freeStr(&($2.code)); freeStr(&($2.place));
		freeStr(&$5);
		}
	| DO BEGINLOOP {str temp = newLabel(); push(&loopStack, &temp);}
	  statements ENDLOOP WHILE bool_exp {
		PROD_RULE("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");
		$$ = gen_do_while($7, $4);
		freeStr(&($7.code)); freeStr(&($7.place));
		freeStr(&$4);
		}
	| READ vars {
		PROD_RULE("statement -> READ vars\n");
		$$ = gen_read($2);
		freeStrArr(&($2.names)); freeStr(&($2.arrIndex.code));
		freeStrArr(&($2.arrIndex.places));
		}
	| WRITE vars {
		PROD_RULE("statement -> WRITE vars\n");
		$$ = gen_write($2);
		freeStrArr(&($2.names)); freeStr(&($2.arrIndex.code));
		freeStrArr(&($2.arrIndex.places));
		}
	| CONTINUE {
		PROD_RULE("statement -> CONTINUE\n");
		$$ = gen_continue();
		}
	| RETURN expression {
		PROD_RULE("statement -> RETURN expression\n");
		$$ = gen_return($2);
		freeStr(&($2.code)); freeStr(&($2.place));
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
		$$ = gen_op("||", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	;

relation_and_exp:
	  relation_exp {
		PROD_RULE("relation_and_exp -> relation_exp\n");
		}
	| relation_exp AND relation_and_exp {
		PROD_RULE("relation_and_exp -> relation_exp AND relation_and_exp\n");
		$$ = gen_op("&&", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	;

relation_exp:
	  NOT expression comp expression {
		PROD_RULE("relation_exp -> NOT expression comp expression\n");
		expr e = gen_op(STRSTR($3), $2, $4);
		freeStr(&$3);
		freeStr(&($2.code)); freeStr(&($2.place));
		freeStr(&($4.code)); freeStr(&($4.place));
		$$ = gen_not(e);
		freeStr(&(e.code)); freeStr(&(e.place));
		}
	| NOT TRUE {
		PROD_RULE("relation_exp -> NOT TRUE\n");
		$$.place = newTemp();
		$$.code = instruction(".", &($$.place), NULL);
		str zero = strFrom("0");
		str line = instruction("=", &($$.place), &zero, NULL);
		concatln(&($$.code), &line, NULL);
		freeStr(&zero); freeStr(&line);
		}
	| NOT FALSE {
		PROD_RULE("relation_exp -> NOT FALSE\n");
		$$.place = newTemp();
		$$.code = instruction(".", &($$.place), NULL);
		str one = strFrom("1");
		str line = instruction("=", &($$.place), &one, NULL);
		concatln(&($$.code), &line, NULL);
		freeStr(&one); freeStr(&line);
		}
	| NOT L_PAREN bool_exp R_PAREN {
		PROD_RULE("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");
		$$ = gen_not($3);
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| expression comp expression {
		PROD_RULE("relation_exp -> expression comp expression\n");
		$$ = gen_op(STRSTR($2), $1, $3);
		freeStr(&$2);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| TRUE {
		PROD_RULE("relation_exp -> TRUE\n");
		$$.place = newTemp();
		$$.code = instruction(".", &($$.place), NULL);
		str one = strFrom("1");
		str line = instruction("=", &($$.place), &one, NULL);
		concatln(&($$.code), &line, NULL);
		freeStr(&one); freeStr(&line);
		}
	| FALSE {
		PROD_RULE("relation_exp -> FALSE\n");
		$$.place = newTemp();
		$$.code = instruction(".", &($$.place), NULL);
		str zero = strFrom("0");
		str line = instruction("=", &($$.place), &zero, NULL);
		concatln(&($$.code), &line, NULL);
		freeStr(&zero); freeStr(&line);
		}
	| L_PAREN bool_exp R_PAREN {
		PROD_RULE("relation_exp -> L_PAREN bool_exp R_PAREN\n");
		$$ = $2;
		}
	;

comp:
	  EQ {
		PROD_RULE("comp -> EQ\n");
		$$ = strFrom("==");
		}
	| NEQ {
		PROD_RULE("comp -> NEQ\n");
		$$ = strFrom("!=");
		}
	| LT {
		PROD_RULE("comp -> LT\n");
		$$ = strFrom("<");
		}
	| GT {
		PROD_RULE("comp -> GT\n");
		$$ = strFrom(">");
		}
	| LTE {
		PROD_RULE("comp -> LTE\n");
		$$ = strFrom("<=");
		}
	| GTE {
		PROD_RULE("comp -> GTE\n");
		$$ = strFrom(">=");
		}
	;

expressions:
	  /* epsilon */ {
		PROD_RULE("expressions -> epsilon\n");
		}
	| expression {
		PROD_RULE("expressions -> expression\n");
		$$.places = newStrArr();
		push(&($$.places), &($1.place));
		$$.code = $1.code;
		}
	| expression COMMA expressions {
		PROD_RULE("expressions -> expression COMMA expressions\n");

		$$.places = newStrArr();
		push(&($$.places), &($1.place));

		int i;
		for (i = 0; i < ARRLEN($3.places); i++)
			push(&($$.places), &(ARR($3.places)[i]));
		free(ARR($3.places));

		concatln(&($1.code), &($3.code), NULL);
		freeStr(&($3.code));

		$$.code = $1.code;
		}
	;

expression:
	  multiplicative_expression {
		PROD_RULE("expression -> multiplicative_expression\n");
		}
	| multiplicative_expression SUB expression {
		PROD_RULE("expression -> multiplicative_expression SUB expression\n");

		$$ = gen_op("-", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| multiplicative_expression ADD expression {
		PROD_RULE("expression -> multiplicative_expression ADD expression\n");

		$$ = gen_op("+", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
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

		$$ = gen_op("%", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| term DIV multiplicative_expression {
		PROD_RULE("multiplicative_expression -> term DIV multiplicative_expression\n");

		$$ = gen_op("/", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| term MULT multiplicative_expression {
		PROD_RULE("multiplicative_expression -> term MULT multiplicative_expression\n");

		$$ = gen_op("*", $1, $3);
		freeStr(&($1.code)); freeStr(&($1.place));
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	;

term:
	  SUB var %prec UMINUS {
		PROD_RULE("term -> SUB var\n");

		expr e;
		e.place = newTemp();
		str line1 = instruction(".", &(e.place), NULL);
		str line2;
		if (IS_ARR($2.name)) {
			e.code = $2.arrIndex.code;
			line2 = instruction("=[]", &(e.place), &($2.name), &($2.arrIndex.place), NULL);
			concatln(&(e.code), &line1, &line2, NULL);
			freeStr(&line1);
		} else {
			e.code = line1;
			line2 = instruction("=", &(e.place), &($2.name), NULL);
			concatln(&(e.code), &line2, NULL);
		}
		freeStr(&line2);

		$$ = gen_uminus(e);
		freeStr(&(e.code)); freeStr(&(e.place));
		}
	| SUB NUMBER %prec UMINUS {
		PROD_RULE1("term -> SUB NUMBER %d\n", $2);

		expr e;
		e.place = newTemp();
		char buf[11];
		sprintf(buf, "%d", $2);
		str strNum = strFrom(buf);
		e.code = instruction("=", &(e.place), &strNum, NULL);
		freeStr(&strNum);

		$$ = gen_uminus(e);
		freeStr(&(e.code)); freeStr(&(e.place));
		}
	| SUB L_PAREN expression R_PAREN %prec UMINUS {
		PROD_RULE("term -> SUB L_PAREN expression R_PAREN\n");
		$$ = gen_uminus($3);
		freeStr(&($3.code)); freeStr(&($3.place));
		}
	| var {
		PROD_RULE("term -> var\n");

		$$.place = newTemp();
		str line1 = instruction(".", &($$.place), NULL);
		str line2;
		if (IS_ARR($1.name)) {
			$$.code = $1.arrIndex.code;
			line2 = instruction("=[]", &($$.place), &($1.name), &($1.arrIndex.place), NULL);
			concatln(&($$.code), &line1, &line2, NULL);
			freeStr(&line1);
		} else {
			$$.code = line1;
			line2 = instruction("=", &($$.place), &($1.name), NULL);
			concatln(&($$.code), &line2, NULL);
		}
		freeStr(&line2);
		}
	| NUMBER {
		PROD_RULE1("term -> NUMBER %d\n", $1);

		$$.place = newTemp();
		char buf[11];
		sprintf(buf, "%d", $1);
		str strNum = strFrom(buf);
		$$.code = instruction("=", &($$.place), &strNum, NULL);
		freeStr(&strNum);
		}
	| L_PAREN expression R_PAREN {
		PROD_RULE("term -> L_PAREN expression R_PAREN\n");

		$$.place = $2.place;
		$$.code = $2.code;
		}
	| ident L_PAREN expressions R_PAREN {
		PROD_RULE("term -> ident L_PAREN expressions R_PAREN\n");
		$$ = gen_func_call($1, $3);
		freeStr(&$1); freeStr(&($3.code)); freeStrArr(&($3.places));
		}
	;

vars:
	  var {
		PROD_RULE("vars -> var\n");

		$$.names = newStrArr();
		push(&($$.names), &($1.name));
		$$.arrIndex.places = newStrArr();
		push(&($$.arrIndex.places), &($1.arrIndex.place));
		$$.arrIndex.code = $1.arrIndex.code;
		}
	| var COMMA vars {
		PROD_RULE("vars -> var COMMA vars\n");

		$$.names = newStrArr();
		push(&($$.names), &($1.name));
		$$.arrIndex.places = newStrArr();
		push(&($$.arrIndex.places), &($1.arrIndex.place));
		int i;
		for (i = 0; i < ARRLEN($3.arrIndex.places); i++)
			push(&($$.arrIndex.places), &(ARR($3.arrIndex.places)[i]));
		free(ARR($3.arrIndex.places));
		for (i = 0; i < ARRLEN($3.names); i++)
			push(&($$.names), &(ARR($3.names)[i]));
		free(ARR($3.names));
		concatln(&($1.arrIndex.code), &($3.arrIndex.code), NULL);
		freeStr(&($3.arrIndex.code));
		$$.arrIndex.code = $1.arrIndex.code;
		}
	;

var:
	  ident {
		PROD_RULE("var -> ident\n");

		if (IS_ARR($1))
			semErr("Cannot access array as a scalar.");
		else if (!IS_INT($1) && !IS_ENUM($1))
			semErr("Variable not declared.");
		$$.name = $1;
		$$.arrIndex.place = newStr();
		$$.arrIndex.code = newStr();
		}
	| ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
		PROD_RULE("var -> ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");

		if (IS_INT($1) || IS_ENUM($1))
			semErr("Cannot access scalar as an array.");
		else if (!IS_ARR($1))
			semErr("Variable not declared.");
		$$.name = $1;
		$$.arrIndex = $3;
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

	initArr();

	return yyparse();
}

void yyerror(const char *msg) {
	err(msg);
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
