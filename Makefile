.PHONY: clean test testlex

COL_RST := $(shell tput sgr0)
COL_RED := $(shell tput setaf 1)
COL_GRN := $(shell tput setaf 2)
COL_YEL := $(shell tput setaf 3)

CC = gcc
LEX = flex
LIB = -lfl
TEST = diff

lexer: lex.yy.c
	$(CC) -o lexer lex.yy.c $(LIB)

lex.yy.c: mini_l.lex
	$(LEX) -o lex.yy.c mini_l.lex

test: testlex

testlex: tests/*.token

tests/%.token: lexer
	@echo "Running $* test..."; \
	./lexer $(@D)/$*.min | $(TEST) $@ -; \
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
