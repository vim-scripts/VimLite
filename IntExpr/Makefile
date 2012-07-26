.PHONY: all clean

all: test

test: lex_src
	@yacc -d IntExpr.y -o y.tab.c
	$(CC) -o $@ y.tab.c IntExpr.c -D_WITH_YACC -D_DEBUG

clean:
	@rm -fv test
	@rm -fv lex_bin

lex_src:
	@lex -o IntExpr.c IntExpr.l

lex_bin: lex_src
	$(CC) -o $@ IntExpr.c -ll
