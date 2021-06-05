#include<stdlib.h>
#include<stdarg.h>
#include<stdio.h>
#include<string.h>

#include "code_gen.h"
#include "str.h"

#define free(a)

extern void err(const char *msg);

/* Allocate new strArr's for globals */
void initArr(void) {
	loopStack = newStrArr();
	funcTable = newStrArr();
	arrTable = newStrArr();
	intTable = newStrArr();
	enumTable = newStrArr();
}

void dumpVars(void) {
	dumpArr(&loopStack);
	dumpArr(&arrTable);
	dumpArr(&intTable);
	dumpArr(&enumTable);
	memset(arrSizeTable, 0, 128*sizeof(int));
}

/* Create a string for a new temp variable */
str newTemp(void) {
	char strNum[11];
	str temp = strFrom("__temp__");
	
	sprintf(strNum, "%d", tempCount++);

	appendStr(&temp, strNum);
	return temp;
}

/* Create a string for a new label */
str newLabel(void) {
	char strNum[11];
	str label = strFrom("__label__");
	
	sprintf(strNum, "%d", labelCount++);

	appendStr(&label, strNum);
	return label;
}

/* Create a intermediate instruction for op
 *  Parameters:
 *  	op	Operator for instruction
 *      str*	arguments for instruction
 *      NULL	terminate variadic args
 *  Return Value:
 *  	str of "op arg1, arg2, ..., argn"
 */
str instruction(const char* op, ...) {
	str* s;
	str instruct = strFrom(op);

	va_list args;
	va_start(args, op);

	s = va_arg(args, str*);
	if (s == NULL) return instruct;
	appendStr(&instruct, " ");
	append(&instruct, *s);

	while ((s = va_arg(args, str*))) {
		appendStr(&instruct, ", ");
		append(&instruct, *s);
	}

	return instruct;
}

stmt gen_func(str ident, stmt params, stmt locals, stmt body) {
	stmt func = instruction("func", &ident, NULL);
	concatln(&func, &params, &locals, &body, NULL);
	appendStr(&func, "\nendfunc\n");
	return func;
}

/* Take a list of identifiers and generate declarations.
 * After each declaration generate initialise variable
 * as a parameter with $n.
 */
stmt gen_params(strArr idents) {
	int i;
	char arg[12] = "$";
	str ident, argStr, line;
	stmt param;
	
	for (i = 0; i < ARRLEN(idents)-1; i++) {
		sprintf(arg+1, "%d", i);
		argStr = strFrom(arg);
		ident = GETSTR(idents, i);

		if (i == 0) 
			param = gen_int(ident);
		else {
			line = gen_int(ident);
			concatln(&param, &line, NULL);
			freeStr(&line);
		}

		line = instruction("=", &ident, &argStr, NULL);
		concatln(&param, &line, NULL);
		freeStr(&line);
		freeStr(&argStr);
	}
	if(i==0) param = newStr();

	return param;
}

stmt gen_decls(strArr idents) {
	int i, num;
	str ident;
	stmt decls, line;

	for (i = 0; i < ARRLEN(idents)-1; i++) {
		ident = GETSTR(idents, i);

		if (IS_INT(ident) || IS_ENUM(ident))
			line = gen_int(ident);
		else if (IS_ARR(ident))
			line = gen_arr(ident);
		
		if (i == 0)
			decls = line;
		else {
			concatln(&decls, &line, NULL);
			freeStr(&line);
		}

		if ((num = contains(enumTable, ident)) != -1) {
			char buf[11];
			sprintf(buf, "%d", num);
			str strNum = strFrom(buf);
			line = instruction("=", &ident, &strNum, NULL);
			concatln(&decls, &line, NULL);
			freeStr(&line);
			freeStr(&strNum);
		}
	}
	if (i == 0) decls = newStr();
	
	return decls;
}

stmt gen_int(str ident) {
	return instruction(".", &ident, NULL);
}

stmt gen_arr(str ident) {
	char aSize[11];
	str arrSize;
	sprintf(aSize, "%d", SIZEOF(ident));
	arrSize = strFrom(aSize);
	str line = instruction(".[]", &ident, &arrSize, NULL);
	freeStr(&arrSize);
	return line;
}

stmt gen_assign(var v, expr exp) {
	str line;
	stmt assign = newStr();
	append(&assign, exp.code);
	if (IS_INT(v.name))
		line = instruction("=", &(v.name), &(exp.place), NULL);
	else if (IS_ARR(v.name)) {
		concatln(&assign, &(v.arrIndex.code), NULL);
		line = instruction("[]=", &(v.name), &(v.arrIndex.place),
				&(exp.place), NULL);
	}
	concatln(&assign, &line, NULL);
	freeStr(&line);
	return assign;
}

stmt gen_if(expr boolexp, stmt code) {
	str mid = newLabel();
	str end = newLabel();

	stmt if_st = newStr();
	append(&if_st, boolexp.code);
	str line1 = instruction(":?", &mid, &(boolexp.place), NULL);
	str line2 = instruction(":=", &end, NULL);
	str line3 = instruction(":", &mid, NULL);
	str line4 = instruction(":", &end, NULL);
	concatln(&if_st, &line1, &line2, &line3, &code, &line4, NULL);
	freeStr(&mid); freeStr(&end);
	return if_st;
}

stmt gen_if_else(expr boolexp, stmt trueCode, stmt falseCode) {
	str mid = newLabel();
	str end = newLabel();

	stmt if_st = newStr();
	append(&if_st, boolexp.code);
	str line1 = instruction(":?", &mid, &(boolexp.place), NULL);
	str line2 = instruction(":=", &end, NULL);
	str line3 = instruction(":", &mid, NULL);
	str line4 = instruction(":", &end, NULL);
	concatln(&if_st, &line1, &falseCode, &line2, &line3, &trueCode,
		&line4, NULL);
	freeStr(&line1); freeStr(&line2); freeStr(&line3); freeStr(&line4);
	freeStr(&mid); freeStr(&end);
	return if_st;
}

stmt gen_while(expr boolexp, stmt code) {
	str begin = pop(&loopStack);
	str mid = newLabel();
	str end = newLabel();

	stmt wh_st = newStr();
	append(&wh_st, boolexp.code);
	str line0 = instruction(":", &begin, NULL);
	str line1 = instruction(":?", &mid, &(boolexp.place), NULL);
	str line2 = instruction(":=", &end, NULL);
	str line3 = instruction(":", &mid, NULL);
	str line4 = instruction(":=", &begin, NULL);
	str line5 = instruction(":", &end, NULL);
	concatln(&wh_st, &line0, &line1, &line2, &line3, &code, &line4,
		&line5, NULL);

	freeStr(&line0); freeStr(&line1); freeStr(&line2); freeStr(&line3);
	freeStr(&line4); freeStr(&line5); freeStr(&begin); freeStr(&mid);
	freeStr(&end);

	return wh_st;
}

stmt gen_do_while(expr boolexp, stmt code) {
	str begin = newLabel();
	str mid = pop(&loopStack);

	stmt wh_st = newStr();
	str line0 = instruction(":", &begin, NULL);
	append(&wh_st, line0);
	str line1 = instruction(":", &mid, NULL);
	str line2 = instruction(":?", &begin, &(boolexp.place), NULL);
	concatln(&wh_st, &code, &(boolexp.code), &line1, &line2, NULL);

	freeStr(&line0); freeStr(&line1); freeStr(&line2);
	freeStr(&begin); freeStr(&mid);

	return wh_st;
}

stmt gen_read(vars v) {
	str ident, line;
	int i;
	stmt read = newStr();
	append(&read, v.arrIndex.code);
	for (i = 0; i < ARRLEN(v.names); i++) {
		ident = GETSTR(v.names, i);
		if (IS_INT(ident))
			line = instruction(".<", &ident, NULL);
		else
			line = instruction(".[]<", &ident,
				&(ARR(v.arrIndex.places)[i]), NULL);
		if (STRLEN(read) == 0)
			appendFree(&read, &line);
		else {
			concatln(&read, &line, NULL);
			freeStr(&line);
		}
	}
	return read;
}

stmt gen_write(vars v) {
	str ident, line;
	int i;
	stmt write = newStr();
	append(&write, v.arrIndex.code);
	for (i = 0; i < ARRLEN(v.names); i++) {
		ident = GETSTR(v.names, i);
		if (IS_INT(ident))
			line = instruction(".>", &ident, NULL);
		else
			line = instruction(".[]>", &ident,
				&(ARR(v.arrIndex.places)[i]), NULL);
		if (STRLEN(write) == 0)
			appendFree(&write, &line);
		else {
			concatln(&write, &line, NULL);
			freeStr(&line);
		}
	}
	return write;
}

stmt gen_continue(void) {
	if (ARRLEN(loopStack) <= 0) {
		err("Continue outside of loop.");
		return newStr();
	}
	str label = peek(loopStack);
	return instruction(":=", &label, NULL);
}

stmt gen_return(expr exp) {
	stmt ret = newStr();
	append(&ret, exp.code);
	str line = instruction("ret", &(exp.place), NULL);
	concatln(&ret, &line, NULL);
	freeStr(&line);
	return ret;
}

expr gen_op(const char* op, expr e1, expr e2) {
	expr e;
	e.place = newTemp();
	e.code = instruction(".", &(e.place), NULL);
	str line = instruction(op, &(e.place), &(e1.place), &(e2.place), NULL);
	concatln(&(e.code), &(e1.code), &(e2.code), &line, NULL);
	freeStr(&line);
	return e;
}

expr gen_uminus(expr e1) {
	expr e;
	e.place = newTemp();
	e.code = instruction(".", &(e.place), NULL);
	str zero = strFrom("0");
	str line = instruction("-", &(e.place), &zero, &(e1.place), NULL);
	concatln(&(e.code), &(e1.code), &line, NULL);
	freeStr(&line); freeStr(&zero);
	return e;
}

expr gen_not(expr e1) {
	expr e;
	e.place = newTemp();
	e.code = instruction(".", &(e.place), NULL);
	str line = instruction("!", &(e.place), &(e1.place), NULL);
	concatln(&(e.code), &(e1.code), &line, NULL);
	freeStr(&line);
	return e;
}

expr gen_func_call(str func, exprs paramExp) {
	if (!IS_FUNC(func)) {
		str msg = strFrom(STRSTR(func));
		appendStr(&msg, " has not been defined as a function.");
		err(STRSTR(msg));
		freeStr(&msg);
	}
	int i;
	expr e;
	e.place = newTemp();
	e.code = instruction(".", &(e.place), NULL);
	concatln(&(e.code), &(paramExp.code), NULL);
	str line, line2;
	str ident;
	strArr params = paramExp.places;
	for (i = 0; i < ARRLEN(params); i++) {
		ident = GETSTR(params, i);
		line = instruction("param", &ident, NULL);
		concatln(&(e.code), &line, NULL);
		freeStr(&line);
	}
	line = instruction(".", &(e.place), NULL);
	line2 = instruction("call", &func, &(e.place), NULL);
	concatln(&(e.code), &line, &line2, NULL);
	freeStr(&line);
	freeStr(&line2);
	return e;
}
