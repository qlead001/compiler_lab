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
PARSE_TESTS := $(addsuffix .parser, $(basename $(wildcard tests/*.parse)))

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

mini_l_grammar.pdf: mini_l_grammar.tex
	mkdir -p $(TEX_DIR)
	$(TEX) $(TEX_FLAGS) $<
	mv $(TEX_DIR)/$@ $@

zip: quinn_leader_parser.zip

# Generate a temporary directory
ifndef TMP_DIR
$(warning No TMP_DIR)
ifeq ($(firstword $(filter zip,$(MAKECMDGOALS))),zip)
$(warning Making dir)
quinn_leader_parser.zip: private TMP_DIR := \
			 $(shell mktemp -d tmp_parser.XXXXXXXXXX)
endif
endif

quinn_leader_parser.zip: mini_l.lex mini_l.y mini_l_grammar.pdf \
			 template_makefile
	@echo "mktemp -d tmp_parser.XXXXXXXXXX"
	@echo "$(TMP_DIR)"
	cp -t '$(TMP_DIR)' $(wordlist 1, 3, $?)
	printf '# Generated at %s\n\n%s\n' "$$(date)" \
		"$$(cat $(word 4, $?))" > '$(TMP_DIR)/Makefile'
	zip -j $@ $(addprefix $(TMP_DIR)/, $(wordlist 1, 3, $?) Makefile)
	rm -rf '$(TMP_DIR)'

clean:
	rm -rf lexer lex.yy.c parser y.tab.c y.tab.h y.output \
	mini_l_grammar.pdf $(TEX_DIR) quinn_leader_parser.zip \
	$(if $(value TMP_DIR),$(TMP_DIR),tmp_parser.*)
