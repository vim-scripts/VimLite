
%{
#include <stdio.h>
#include "IntExpr.h"
#ifdef _DEBUG
# define dbgprintf(...) printf(__VA_ARGS__)
#else
# define dbgprintf(...)
#endif

extern int start_scan_string(const char *str);
extern void close_scan_string(void);

int g_result = 0;

int eval_end(int result);

void yyerror(const char *errmsg);

extern int yylex(void);

int div_safe(int n1, int n2);

int rem_safe(int n1, int n2);

%}

%token NUMBER OCT_NUMBER DEC_NUMBER HEX_NUMBER
%token UNARY_PLUS UNARY_MINUS LOGICAL_NOT BITWISE_NOT
%token MULTIPLICATION DIVISION REMAINDER PLUS MINUS
%token BITWISE_LEFT_SHIFT BITWISE_RIGHT_SHIFT
%token LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL EQUAL NOT_EQUAL
%token BITWISE_AND BITWISE_XOR BITWISE_OR LOGICAL_AND LOGICAL_OR
%token TERNARY_COND_QUEST TERNARY_COND_COLON COMMA OPEN_PAREN CLOSE_PAREN
%token EOL
%token END 0

%left COMMA EOL END
%nonassoc TERNARY_COND_QUEST TERNARY_COND_COLON
%left LOGICAL_OR
%left LOGICAL_AND
%left BITWISE_OR
%left BITWISE_XOR
%left BITWISE_AND
%left EQUAL NOT_EQUAL /* ??? */
%left BITWISE_LEFT_SHIFT BITWISE_RIGHT_SHIFT
%left LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL /* ??? */
%left PLUS MINUS
%left MULTIPLICATION DIVISION REMAINDER
%nonassoc UNARY_PLUS UNARY_MINUS LOGICAL_NOT BITWISE_NOT

%%

expr_line: /* nothing */         { dbgprintf("nothing\n"); }
        | expr_line expr EOL     { eval_end($2); dbgprintf("2> "); }
        | expr_line EOL          { dbgprintf("3> "); }
        | expr_line expr END     { eval_end($2); dbgprintf("4> "); }
        /*| expr_line END          { dbgprintf("> "); }*/
        ;

expr: NUMBER                { $$ = $1; }
    | OCT_NUMBER            { $$ = $1; }
    | DEC_NUMBER            { $$ = $1; }
    | HEX_NUMBER            { $$ = $1; }
    | PLUS expr %prec UNARY_PLUS    { $$ = $2; }
    | MINUS expr %prec UNARY_MINUS  { $$ = -$2; }
    | LOGICAL_NOT expr      { $$ = !$2; }
    | BITWISE_NOT expr      { $$ = ~$2; }
    | expr MULTIPLICATION expr  { $$ = $1 * $3; }
    | expr DIVISION expr    { $$ = div_safe($1, $3); }
    | expr REMAINDER expr   { $$ = rem_safe($1, $3); }
    | expr PLUS expr        { $$ = $1 + $3; }
    | expr MINUS expr       { $$ = $1 - $3; }
    | expr BITWISE_LEFT_SHIFT expr  { $$ = $1 << $3; }
    | expr BITWISE_RIGHT_SHIFT expr { $$ = $1 >> $3; }
    | expr LESS_THAN expr   { $$ = $1 < $3; }
    | expr LESS_EQUAL expr  { $$ = $1 <= $3; }
    | expr GREATER_THAN expr    { $$ = $1 > $3; }
    | expr GREATER_EQUAL expr   { $$ = $1 >= $3; }
    | expr EQUAL expr       { $$ = $1 == $3; }
    | expr NOT_EQUAL expr   { $$ = $1 != $3; }
    | expr BITWISE_AND expr { dbgprintf("%d & %d\n", $1, $3); $$ = $1 & $3; }
    | expr BITWISE_XOR expr { $$ = $1 ^ $3; }
    | expr BITWISE_OR expr  { $$ = $1 | $3; }
    | expr LOGICAL_AND expr { $$ = $1 && $3; }
    | expr LOGICAL_OR expr  { $$ = $1 || $3; }
    | expr TERNARY_COND_QUEST expr TERNARY_COND_COLON expr  { $$ = $1 ? $3 : $5; }
    | OPEN_PAREN expr CLOSE_PAREN   { $$ = $2; }
    | expr COMMA expr       { $$ = $3; }
    ;

%%

void yyerror(const char *errmsg)
{
#ifdef _DEBUG
    fprintf(stderr, "%s\n", errmsg);
#endif
    eval_end(0);
}

int eval_end(int result)
{
    dbgprintf("= %d\n", result);
    g_result = result;
    return result;
}

int Eval_IntExpr(const char *pszExpr)
{
    if ( pszExpr == NULL )
    {
        fprintf(stderr, "Invalid param for Eval_IntExpr()\n");
        return 0;
    }

    if ( start_scan_string(pszExpr) )
    {
        fprintf(stderr, "out of memory");
        return 0;
    }

    g_result = 0;   /* reset result */
    yyparse();

    close_scan_string();

    return g_result;
}

int div_safe(int n1, int n2)
{
    if ( n2 == 0 )
    {
        return 0;
    }
    else
    {
        return n1 / n2;
    }
}

int rem_safe(int n1, int n2)
{
    if ( n2 == 0 )
    {
        return 0;
    }
    else
    {
        return n1 % n2;
    }
}

#ifdef _DEBUG
#include <string.h>

int main(int argc, char **argv)
{
    char buf[BUFSIZ];
    puts("start");

    dbgprintf("0> ");
    while ( fgets(buf, sizeof(buf), stdin) != NULL )
    {
#if 0
        size_t len = strlen(buf);
        if ( len > 0 && buf[len - 1] == '\n' )
        {
            buf[len - 1] = '\0';
        }
#endif
        Eval_IntExpr(buf);
    }

    puts("end");

    return 0;
}
#endif

/* vim: set ts=4 sts=4 et: */
