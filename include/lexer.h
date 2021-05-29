/* Structures to print out tokens from lexer */
#ifndef _LEXER_H
#define _LEXER_H

struct yylval {
	int num;
	char *identName;
} yylval;

enum Tokens {
NONE,
/* Reserved Words */
FUNCTION,
BEGIN_PARAMS,
END_PARAMS,
BEGIN_LOCALS,
END_LOCALS,
BEGIN_BODY,
END_BODY,
INTEGER,
ARRAY,
ENUM,
OF,
IF,
THEN,
ENDIF,
ELSE,
WHILE,
DO,
BEGINLOOP,
ENDLOOP,
CONTINUE,
READ,
WRITE,
AND,
OR,
NOT,
TRUE,
FALSE,
RETURN,
/* Arithmetic Operators */
SUB,
ADD,
MULT,
DIV,
MOD,
/* Comparison Operators */
EQ,
NEQ,
LT,
GT,
LTE,
GTE,
/* Other Special Symbols */
IDENT,
NUMBER,
SEMICOLON,
COLON,
COMMA,
L_PAREN,
R_PAREN,
L_SQUARE_BRACKET,
R_SQUARE_BRACKET,
ASSIGN,
END,
};

char *tokenStr[] = {
/* Reserved Words */
[FUNCTION]	"FUNCTION",
[BEGIN_PARAMS]	"BEGIN_PARAMS",
[END_PARAMS]	"END_PARAMS",
[BEGIN_LOCALS]	"BEGIN_LOCALS",
[END_LOCALS]	"END_LOCALS",
[BEGIN_BODY]	"BEGIN_BODY",
[END_BODY]	"END_BODY",
[INTEGER]	"INTEGER",
[ARRAY]	"ARRAY",
[ENUM]	"ENUM",
[OF]	"OF",
[IF]	"IF",
[THEN]	"THEN",
[ENDIF]	"ENDIF",
[ELSE]	"ELSE",
[WHILE]	"WHILE",
[DO]	"DO",
[BEGINLOOP]	"BEGINLOOP",
[ENDLOOP]	"ENDLOOP",
[CONTINUE]	"CONTINUE",
[READ]	"READ",
[WRITE]	"WRITE",
[AND]	"AND",
[OR]	"OR",
[NOT]	"NOT",
[TRUE]	"TRUE",
[FALSE]	"FALSE",
[RETURN]	"RETURN",
/* Arithmetic Operators */
[SUB]	"SUB",
[ADD]	"ADD",
[MULT]	"MULT",
[DIV]	"DIV",
[MOD]	"MOD",
/* Comparison Operators */
[EQ]	"EQ",
[NEQ]	"NEQ",
[LT]	"LT",
[GT]	"GT",
[LTE]	"LTE",
[GTE]	"GTE",
/* Other Special Symbols */
[IDENT]	"IDENT",
[NUMBER]	"NUMBER",
[SEMICOLON]	"SEMICOLON",
[COLON]	"COLON",
[COMMA]	"COMMA",
[L_PAREN]	"L_PAREN",
[R_PAREN]	"R_PAREN",
[L_SQUARE_BRACKET]	"L_SQUARE_BRACKET",
[R_SQUARE_BRACKET]	"R_SQUARE_BRACKET",
[ASSIGN]	"ASSIGN",
};

#endif /* lexer.h */