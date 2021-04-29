.PHONY: all debug clean test testlex tests/%.lexer doc grammardoc

# Variables for fancy output
COL_RST := $(shell tput sgr0)
COL_SMO := $(shell tput smso)
COL_RED := $(shell tput setaf 1)
COL_GRN := $(shell tput setaf 2)
COL_YEL := $(shell tput setaf 3)

# Tools
CC = gcc
LEX = flex
LEX_FLAGS = # empty
LIB = -lfl
PARSE = bison
PARSE_FLAGS = -v -d --file-prefix=y
TEST = git --no-pager diff --exit-code --no-index --
TEX = pdflatex
TEX_FLAGS = -output-directory $(TEX_DIR)
TEX_DIR = texbuild

# Debug flags
debug: PARSE_FLAGS += -t
debug: LEX_FLAGS += -d

# Get list of tests
LEX_TESTS := $(addsuffix .lexer, $(basename $(wildcard tests/*.tokens)))

all: parser lexer

debug: all

parser: y.tab.c lex.yy.c
	$(CC) -o $@ $^ $(LIB)

y.tab.c: mini_l.y
	$(PARSE) $(PARSE_FLAGS) $^

lexer: lex.yy.c
	$(CC) -o $@ $^ -D LEXER $(LIB)

lex.yy.c: mini_l.lex
	$(LEX) $(LEX_FLAGS) -o $@ $^

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

doc: grammardoc

grammardoc: mini_l_grammar.pdf

mini_l_grammar.pdf: mini_l_grammar.tex
	mkdir -p $(TEX_DIR)
	$(TEX) $(TEX_FLAGS) $<
	mv $(TEX_DIR)/$@ $@

clean:
	rm -rf lexer lex.yy.c parser y.tab.c y.tab.h y.output \
	mini_l_grammar.pdf $(TEX_DIR)
