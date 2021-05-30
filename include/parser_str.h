/* Replacements for functions that are not
 * necessary for the standalone parser
 */
#ifndef	_PARSER_STR_H
#define	_PARSER_STR_H	1

#define	STRSTR(s)	(s)

#define	append(s1, s2)	(s1)
#define appendStr(s1, s2)	(s1)

#define	strFrom(s)	(s)
#define	newStr()	""
#define	freeStr(s)

typedef char* str;

#endif /* parser_str.h */
