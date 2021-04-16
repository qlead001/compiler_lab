#!/bin/sh

if [ "$#" -lt 2 ]; then
	printf "Usage: $0 MODIFIER FILE [OPTION]\n\n" >&2
	printf "Modifiers:\tprint_lex\tPhase 1 lexer rules\n" >&2
	printf "\t\ttoken_lex\tPhase 2 lexer rules\n" >&2
	printf "\t\ttokens\t\tPrint tokens separated by OPTION or ' '\n" >&2
	printf "\t\ttok_str\t\tTokens in C style array indexed by an enum\n" >&2
	exit 1
fi

if ! [ -e "$2" ]; then
	echo "Error: $2 does not exist" >&2
	exit 1
fi

if ! [ -f "$2" ]; then
	echo "Error: $2 is not a regular file" >&2
	exit 1
fi

case "$1" in
	# Original Lexer
	'print_lex')
		REP='"\1"\t{printf("\2\\n"); currPos += yyleng;}'
		sed -r 's/^(\S+)\s+([A-Z_]+)$/'"$REP"'/' "$2"
		;;
	# Parser Lexer
	'token_lex')
		REP='"\1"\t{currPos += yyleng; return \2;}'
		sed -r 's/^(\S+)\s+([A-Z_]+)$/'"$REP"'/' "$2"
		;;
	# Tokens
	'tokens')
		SEP=' '
		if [ "$#" -ge 3 ]; then
			SEP=$3
		fi
		sed -rn 's/^(\S+)\s+([A-Z_]+)$/\2<SEPARATOR>/p' "$2" \
		| tr -d '\n' \
		| sed -r -e 's/<SEPARATOR>$/\n/' -e 's/<SEPARATOR>/'"$SEP"'/g'
		;;
	# Token to String
	'tok_str')
		sed -rn 's/^(\S+)\s+([A-Z_]+)$/[\2]\t"\2",/p' "$2"
		;;
	# Default
	*)
		echo "Error: $1 is not a recognised modifier" >&2
		;;
esac
