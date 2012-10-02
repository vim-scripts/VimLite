#include <stdio.h>
#include "ftTypes.h"
#include "ftStack.h"

extern int yylex();
extern char *yytext;

int Eval_IntExpr(const char * pszExpr);

int eval(void);

int GetPrecede(int tokenType);

int main(int argc, char **argv)
{
    eval();

    return 0;
}

BOOL IsOperator(enum Tokens_em tokenType)
{
    BOOL result = False;
    switch ( tokenType )
    {
        case LOGICAL_NOT:    /* ! */
        case BITWISE_NOT:    /* ~ */
        case MULTIPLICATION: /* * */
        case DIVISION:   /* / */
        case REMAINDER:  /* % */
        case PLUS:       /* + */
        case MINUS:      /* - */
        case BITWISE_LEFT_SHIFT:     /* << */
        case BITWISE_RIGHT_SHIFT:    /* >> */
        case LESS_THAN:  /* < */
        case LESS_EQUAL: /* <= */
        case GREATER_THAN:   /* > */
        case GREATER_EQUAL:  /* >= */
        case EQUAL:          /* == */
        case NOT_EQUAL:      /* != */
        case BITWISE_AND:    /* & */
        case BITWISE_XOR:    /* ^ */
        case BITWISE_OR:     /* | */
        case LOGICAL_AND:    /* && */
        case LOGICAL_OR:     /* || */
        case TERNARY_COND_QUEST:   /* ? of ?: */
        case TERNARY_COND_COLON: /* : of ?: */
        case OPEN_PAREN:     /* ( */
        case CLOSE_PAREN:    /* ) */
        case COMMA:          /* , */
            result = True;
            break;

        default:
            result = False;
    }

    return result;
}

int PrecedeCompare(int n1, int n2)
{
    return GetPrecede(n1) - GetPrecede(n2);
}

int eval(void)
{
    int ret, result = 0;
    Stack *pOperands = Stack_Create(16);
    Stack *pOperators = Stack_Create(16);
    if ( pOperands == NULL || pOperators == NULL )
    {
        result = -1;
        goto err_out;
    }

    while ( (ret = yylex()) != 0 )
    {
        if ( !IsOperator(ret) ) /* 不是运算符，进栈 */
        {
            Stack_Push(pOperands, (void *)ret);
        }
        else
        {
            Stack_Push(pOperators, (void *)ret);
        }
        printf("%d: %s\n", ret, yytext);
    }

err_out:
    Stack_Destroy(pOperands, NULL);
    pOperands = NULL;
    Stack_Destroy(pOperators, NULL);
    pOperators = NULL;
    return result;
}


int GetPrecede(int tokenType)
{
    static int arr[TOKENS_MAX - TOKENS_MIN] = {
    }
}


/* vim: set ts=4 sts=4 et: */
