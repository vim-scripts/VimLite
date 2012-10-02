
%option noyywrap nodefault yylineno

/* integer length */
INTLEN  ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)

%{
#include <stdio.h>
#ifdef _WITH_YACC
# include "y.tab.h"
#else
# include "tokens.h"
#endif

extern int start_scan_string(const char *str);
extern void close_scan_string(void);
YY_BUFFER_STATE g_bp = NULL;
%}

%%

 /* dec */
0[0-7]*{INTLEN}?            { sscanf(yytext, "%o", &yylval); return OCT_NUMBER; }
[1-9][0-9]*{INTLEN}?        { yylval = atoi(yytext); return DEC_NUMBER; }
0[Xx][0-9a-fA-F]+{INTLEN}?  { sscanf(yytext+2, "%x", &yylval); return HEX_NUMBER; }

"!" return LOGICAL_NOT;
"~" return BITWISE_NOT;
"*" return MULTIPLICATION;
"/" return DIVISION;
"%" return REMAINDER;
"+" return PLUS;
"-" return MINUS;

"<" return LESS_THAN;
">" return GREATER_THAN;

"?" return TERNARY_COND_QUEST;
":" return TERNARY_COND_COLON;

"&" return BITWISE_AND;
"^" return BITWISE_XOR;
"|" return BITWISE_OR;

"," return COMMA;

"(" return OPEN_PAREN;
")" return CLOSE_PAREN;

"<<" return BITWISE_LEFT_SHIFT;
">>" return BITWISE_RIGHT_SHIFT;

"<=" return LESS_EQUAL;
">=" return GREATER_EQUAL;

"==" return EQUAL;
"!=" return NOT_EQUAL;

"&&" return LOGICAL_AND;
"||" return LOGICAL_OR;

\n      { return EOL; }

 /* white space */
[ \t]+      { /* ignore */ }


 /* invalid character */
.   { fprintf(stderr, "Mystery character '%s'\n", yytext); }

%%

int start_scan_string(const char *str)
{
    g_bp = yy_scan_string(str);
    if ( g_bp == NULL )
    {
        return -1;
    }
    yy_switch_to_buffer(g_bp);

    return 0;
}

void close_scan_string(void)
{
    yy_flush_buffer(g_bp);
    yy_delete_buffer(g_bp);
    g_bp = NULL;
}

#ifdef _WITH_YACC

#else
int main(int argc, char **argv)
{
    int ret;

    while ( (ret = yylex()) != 0 )
    {
        printf("%d: %s\n", ret, yytext);
    }

    return 0;
}
#endif

/* vim: set ts=4 sts=4 et: */
