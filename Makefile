.PHONY: clean test testlex tests/%.lexer

# Variables for fancy output
COL_RST := $(shell tput sgr0)
COL_SMO := $(shell tput smso)
COL_RED := $(shell tput setaf 1)
COL_GRN := $(shell tput setaf 2)
COL_YEL := $(shell tput setaf 3)

# Tools
CC = gcc
LEX = flex
LIB = -lfl
TEST = git --no-pager diff --exit-code --no-index --

# Get list of tests
LEX_TESTS := $(addsuffix .lexer, $(basename $(wildcard tests/*.tokens)))

lexer: lex.yy.c
	$(CC) -o lexer lex.yy.c -D LEXER $(LIB)

lex.yy.c: mini_l.lex
	$(LEX) -o lex.yy.c mini_l.lex

test: testlex

testlex: $(LEX_TESTS)

tests/%.lexer: tests/%.tokens tests/%.min lexer
	@echo "$(COL_SMO)[Lexer]$(COL_RST) Running $* test..."; \
	./lexer $(word 2, $?) | $(TEST) $< -; \
	if [ "$$?" -eq "0" ]; \
	then \
		printf '$(COL_GRN)Test Passed$(COL_RST)\n'; \
	elif [ "$$?" -eq "1" ]; \
	then \
		printf '$(COL_RED)Test Failed$(COL_RST)\n'; \
	else \
		printf '$(COL_YEL)Warning $(TEST) ' \
		printf 'returned $$?$(COL_RST)'\n; \
	fi

clean:
	rm lexer lex.yy.c
