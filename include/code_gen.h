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

typedef str stmt;

typedef struct expressions {
	strArr places;
	str code;
} exprs;

typedef struct vars {
	exprs arrIndex;
	strArr names;
} vars;

typedef struct var {
	expr arrIndex;
	str name;
} var;

strArr loopStack;

strArr funcTable;
strArr arrTable;
strArr intTable;
strArr enumTable;

int arrSizeTable[128];

#define	IS_FUNC(i)	(contains(funcTable, (i)) > 0)
#define	IS_ARR(i)	(contains(arrTable, (i)) > 0)
#define	IS_INT(i)	(contains(intTable, (i)) > 0)
#define	IS_ENUM(i)	(contains(enumTable, (i)) > 0)

#define	SIZEOF(arr)	(arrSizeTable[contains(arrTable, (arr))])

void initArr(void);

int tempCount;
int labelCount;

str newTemp(void);
str newLabel(void);

str instruction(const char* op, ...);

stmt gen_func(str ident, stmt params, stmt locals, stmt body);
stmt gen_params(strArr idents);
stmt gen_decls(strArr idents);

stmt gen_int(str ident);
stmt gen_arr(str ident);

stmt gen_assign(var v, expr exp);
stmt gen_if(expr boolexp, stmt code);
stmt gen_if_else(expr boolexp, stmt trueCode, stmt falseCode);
stmt gen_while(expr boolexp, stmt code);
stmt gen_do_while(expr boolexp, stmt code);
stmt gen_read(vars v);
stmt gen_write(vars v);
stmt gen_continue(void);
stmt gen_return(expr exp);

expr gen_op(const char* op, expr e1, expr e2);
expr gen_uminus(expr e1);
expr gen_not(expr e1);

expr gen_func_call(str func, exprs paramsExp);

#endif /* code_gen.h */
