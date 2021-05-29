/* flex scanner for MINI-L programming language */

%{
#ifdef LEXER
	#include "lexer.h"
#else
#	ifdef PARSER
		#include "parser_str.h"
#	else
		#include "str.h"
#	endif
	#include "y.tab.h"
	#define YY_USER_ACTION \
		yylloc.first_line = yylloc.last_line; \
		yylloc.first_column = yylloc.last_column; \
		{int i; \
		for(i = 0; yytext[i] != '\0'; i++) { \
			if(yytext[i] == '\n') { \
				yylloc.last_line++; \
				yylloc.last_column = 0; \
			} \
			else { \
				yylloc.last_column++; \
			} \
		}}
#endif

int currLine = 1, currPos = 0;
%}

DIGIT	[0-9]

%%
	/* Reserved Keywords */
"function"	{currPos += yyleng; return FUNCTION;}
"beginparams"	{currPos += yyleng; return BEGIN_PARAMS;}
"endparams"	{currPos += yyleng; return END_PARAMS;}
"beginlocals"	{currPos += yyleng; return BEGIN_LOCALS;}
"endlocals"	{currPos += yyleng; return END_LOCALS;}
"beginbody"	{currPos += yyleng; return BEGIN_BODY;}
"endbody"	{currPos += yyleng; return END_BODY;}
"integer"	{currPos += yyleng; return INTEGER;}
"array"		{currPos += yyleng; return ARRAY;}
"enum"		{currPos += yyleng; return ENUM;}
"of"		{currPos += yyleng; return OF;}
"if"		{currPos += yyleng; return IF;}
"then"		{currPos += yyleng; return THEN;}
"endif"		{currPos += yyleng; return ENDIF;}
"else"		{currPos += yyleng; return ELSE;}
"while"		{currPos += yyleng; return WHILE;}
"do"		{currPos += yyleng; return DO;}
"beginloop"	{currPos += yyleng; return BEGINLOOP;}
"endloop"	{currPos += yyleng; return ENDLOOP;}
"continue"	{currPos += yyleng; return CONTINUE;}
"read"		{currPos += yyleng; return READ;}
"write"		{currPos += yyleng; return WRITE;}
"and"		{currPos += yyleng; return AND;}
"or"		{currPos += yyleng; return OR;}
"not"		{currPos += yyleng; return NOT;}
"true"		{currPos += yyleng; return TRUE;}
"false"		{currPos += yyleng; return FALSE;}
"return"	{currPos += yyleng; return RETURN;}

	/* Arithmetic Operators */
"-"		{currPos += yyleng; return SUB;}
"+"		{currPos += yyleng; return ADD;}
"*"		{currPos += yyleng; return MULT;}
"/"		{currPos += yyleng; return DIV;}
"%"		{currPos += yyleng; return MOD;}

	/* Comparison Operators */
"=="		{currPos += yyleng; return EQ;}
"<>"		{currPos += yyleng; return NEQ;}
"<"		{currPos += yyleng; return LT;}
">"		{currPos += yyleng; return GT;}
"<="		{currPos += yyleng; return LTE;}
">="		{currPos += yyleng; return GTE;}

	/* Identifiers */
[a-zA-Z]([a-zA-Z0-9_]*[a-zA-Z0-9])?	{
		currPos += yyleng; yylval.identName = strFrom(yytext);
		return IDENT;
		}

	/* Numbers */
{DIGIT}+	{currPos += yyleng; yylval.num = atoi(yytext); return NUMBER;}

	/* Special Symbols */
";"		{currPos += yyleng; return SEMICOLON;}
":"		{currPos += yyleng; return COLON;}
","		{currPos += yyleng; return COMMA;}
"("		{currPos += yyleng; return L_PAREN;}
")"		{currPos += yyleng; return R_PAREN;}
"["		{currPos += yyleng; return L_SQUARE_BRACKET;}
"]"		{currPos += yyleng; return R_SQUARE_BRACKET;}
":="		{currPos += yyleng; return ASSIGN;}

	/* Comments */
"##"[^\n]*	/* ignore comments */

	/* Invalid Identifiers */
[0-9_][a-zA-Z0-9_]+	{
		printf("Error at line %d, column %d: "
			"identifier \"%s\" must begin with "
			"a letter\n",currLine, currPos, yytext);
		currLine += yyleng;
#ifdef	LEXER
		exit(1);
#endif
		}
[a-zA-Z][a-zA-Z0-9_]*"_"	{
		printf("Error at line %d, column %d: "
			"identifier \"%s\" cannot end with an "
			"underscore\n",currLine, currPos, yytext);
		currLine += yyleng;
#ifdef	LEXER
		exit(1);
#endif
		}

	/* White Space */
[ \t]+		{/* ignore */ currPos += yyleng;}
\n+		{currLine += yyleng; currPos = 0;}

	/* Unknown Symbol */
.		{
		printf("Error at line %d, column %d: "
			"unrecognized symbol \"%s\"\n",
			currLine, currPos, yytext);
#ifdef	LEXER
		exit(1);
#else
		currLine += yyleng;
		return yytext[0];
#endif
		}
%%

#ifdef LEXER
int main(int argc, char ** argv) {
	if(argc >= 2) {
		yyin = fopen(argv[1], "r");
		if(yyin == NULL) {
			yyin = stdin;
		}
	}else{
		yyin = stdin;
	}

	enum Tokens token;

	while ((token = yylex())) {
		if (token == END) continue;

		printf("%s", tokenStr[token]);
		if (token == IDENT)
			printf(" %s\n", yylval.identName);
		else if (token == NUMBER)
			printf(" %d\n", yylval.num);
		else printf("\n");
	}

	return 0;
}
#endif
