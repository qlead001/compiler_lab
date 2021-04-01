/* flex scanner for MINI-L programming language */

%{
int currLine = 1, currPos = 0;
%}

DIGIT	[0-9]

%%

	/* Reserved Keywords */
"function"	{printf("FUNCTION\n"); currPos += yyleng;}

	/* Arithmetic Operators */
"-"		{printf("SUB\n"); currPos += yyleng;}

	/* Comparison Operators */
"=="		{printf("EQ\n"); currPos += yyleng;}

	/* Identifiers */
[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]	{
		printf("IDENT %s\n", yytext); currPos += yyleng;
		}

	/* Invalid Identifiers */
[0-9_][a-zA-Z0-9_]+	{
		printf("Error at line %d, column %d: "
			"identifier \"%s\" must begin with "
			"a letter\n",currLine, currPos, yytext);
		exit(1);
		}
[a-zA-Z][a-zA-Z0-9_]*"_"	{
		printf("Error at line %d, column %d: "
			"identifier \"%s\" cannot end with an "
			"underscore\n",currLine, currPos, yytext);
		exit(1);
		}

	/* Numbers */
{DIGIT}+	{printf("NUMBER %s\n", yytext); currPos += yyleng;}

	/* Special Symbols */
";"		{printf("SEMICOLON\n"); currPos += yyleng;}

	/* Comments */
"##"[^\n]*	/* ignore comments */

	/* White Space */
[ \t]+		{/* ignore */ currPos += yyleng;}
\n+		{currLine += yyleng; currPos = 0;}

	/* Unknown Symbol */
.		{
		printf("Error at line %d, column %d: "
			"unrecognized symbol \"%s\"\n",
			currLine, currPos, yytext);
		exit(1);
		}

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

	yylex();
}
