/* Intermediate code generation */
#ifndef	_CODE_GEN_H
#define	_CODE_GEN_H	1

#include "str.h"

/* place:
 * 	holds the name of the identifer or
 * 	temporary that holds the expression
 * code:
 * 	holds the instructions that evaluate
 * 	to the expression
 */
typedef struct expression {
	str place;
	str code;
} expr;

/* start:
 * 	holds the name of the label at the
 * 	start of code
 * end:
 * 	holds the name of the label at the
 * 	end of code
 * code:
 * 	holds the instructions that evaluate
 * 	to the statement
 */
typedef struct statement {
	str start;
	str end;
	str code;
} stmt;

#define	STR_ARR_CAP	16

typedef struct strArr {
	str* ptr;
	int  len;
	int  cap;
} strArr;

/*
typedef struct enumType {
	str name;
	strArr vals;
} enumType;

typedef struct enumArr {
	enumType* ptr;
	int  len;
	int  cap;
} enumArr;
*/

int seenContinue, seenMain;

strArr funcTable;
strArr arrTable;
strArr intTable;
/*
enumArr enumTable;
*/

str newTemp(void);
str newLabel(void);

str concatln(str l1, str l2);

int arrContains(strArr arr, str s);
void arrAppend(strArr* arr, str s);
void arrEmpty(strArr* arr);
void arrFree(strArr* arr);

str gen_func(str params, str locals, str body);
str gen_params(str decls);

str gen_int(strArr idents);
str gen_arr(strArr idents);
/*
str gen_enum(strArr idents, strArr enum_idents);
*/

stmt gen_assign(str v, str exp);
stmt gen_if(expr boolexp, stmt code);
stmt gen_if_else(expr boolexp, stmt trueCode, stmt falseCode);
stmt gen_while(expr boolexp, str code);
stmt gen_do_while(expr boolexp, str code);
stmt gen_read(strArr v);
stmt gen_write(strArr v);
stmt gen_continue(void);
stmt gen_return(expr exp);

expr gen_op(expr e1, expr e2, char* op);
expr gen_not(expr e1);

expr gen_func_call(str func, strArr params);

#endif /* code_gen.h */
