.PHONY: all debug clean test doc grammardoc zip \
testlex tests/%.lexer testparse tests/%.parser

# Variables for fancy output
COL_RST := $(shell tput sgr0)
COL_SMO := $(shell tput smso)
COL_RED := $(shell tput setaf 1)
COL_GRN := $(shell tput setaf 2)
COL_YEL := $(shell tput setaf 3)

# Tools
CC = gcc
# Enable most warnings expect for those caused by flex
CC_FLAGS = -Wall -Wextra -Wno-unused-function -Wno-implicit-function-declaration
CC_FLAGS += -Wformat=2
LEX = flex
LEX_FLAGS = # empty
LIB = -lfl -iquote include -iquote cstring/include
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
PARSE_TESTS := $(addsuffix .parser, $(basename $(wildcard tests/*.parse)))

all: compiler parser lexer

debug: all

compiler: y.tab.c lex.yy.c cstring/str.c src/code_gen.c
	$(CC) $(CC_FLAGS) -o $@ $^ $(LIB)

parser: y.tab.c lex.yy.c
	$(CC) $(CC_FLAGS) -Wno-unused-parameter -o $@ $^ -D PARSER $(LIB)

y.tab.c: src/mini_l.y
	$(PARSE) $(PARSE_FLAGS) $^

lexer: lex.yy.c
	$(CC) $(CC_FLAGS) -o $@ $^ -D LEXER $(LIB)

lex.yy.c: src/mini_l.lex
	$(LEX) $(LEX_FLAGS) -o $@ $^

test: testlex testparse

testlex: $(LEX_TESTS)

tests/%.lexer: tests/%.tokens tests/%.min lexer
	@echo "$(COL_SMO)[Lexer]$(COL_RST) Running $* test..."; \
	./lexer $(word 2, $?) 2>&1 | $(TEST) $< -; \
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

testparse: $(PARSE_TESTS)

tests/%.parser: tests/%.parse tests/%.min parser
	@echo "$(COL_SMO)[Parser]$(COL_RST) Running $* test..."; \
	./parser $(word 2, $?) 2>&1 | $(TEST) $< -; \
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

mini_l_grammar.pdf: doc/mini_l_grammar.tex
	mkdir -p $(TEX_DIR)
	$(TEX) $(TEX_FLAGS) $<
	mv $(TEX_DIR)/$@ $@

zip: quinn_leader_compiler.zip
	rm -rf '$(TMP_DIR)'

# Generate a temporary directory
ifndef TMP_DIR
ifeq ($(firstword $(filter zip,$(MAKECMDGOALS))),zip)
zip: TMP_DIR := $(shell mktemp -d tmp_zip.XXXXXXXXXX)
endif
endif

quinn_leader_compiler.zip: src/mini_l.lex src/mini_l.y cstring/include/str.h \
			   cstring/str.c include/code_gen.h src/code_gen.c \
			   release/template_makefile
	@echo "mktemp -d tmp_zip.XXXXXXXXXX"
	@echo "$(TMP_DIR)"
	cp -t '$(TMP_DIR)' $(wordlist 2, $(words $?), foo $?)
	printf '# Generated at %s\n\n%s\n' "$$(date)" \
		"$$(cat $(lastword $?))" > '$(TMP_DIR)/Makefile'
	zip -j $@ $(addprefix $(TMP_DIR)/, $(notdir $(wordlist 2, \
		$(words $?), foo $?)) Makefile)

## Generate a temporary directory
#ifndef TMP_DIR
#ifeq ($(firstword $(filter zip,$(MAKECMDGOALS))),zip)
#quinn_leader_parser.zip: TMP_DIR := \
#			 $(shell mktemp -d tmp_parser.XXXXXXXXXX)
#endif
#endif

quinn_leader_parser.zip: src/mini_l.lex src/mini_l.y mini_l_grammar.pdf \
			 release/template_makefile
	@echo "mktemp -d tmp_zip.XXXXXXXXXX"
	@echo "$(TMP_DIR)"
	cp -t '$(TMP_DIR)' $(wordlist 2, $(words $?), foo $?)
	printf '# Generated at %s\n\n%s\n' "$$(date)" \
		"$$(cat $(lastword $?))" > '$(TMP_DIR)/Makefile'
	zip -j $@ $(addprefix $(TMP_DIR)/, $(notdir $(wordlist 2, \
		$(words $?), foo $?)) Makefile)

clean:
	rm -rf lexer lex.yy.c parser y.tab.c y.tab.h y.output compiler \
	mini_l_grammar.pdf $(TEX_DIR) quinn_leader_*.zip $(if \
	$(value TMP_DIR),$(TMP_DIR),tmp_zip.*) \
	milRun.stat *.mil
