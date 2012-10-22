#ifndef __TOKENS_H__
#define __TOKENS_H__


#ifdef __cplusplus
extern "C" {
#endif


enum Tokens_em {
    TOKENS_MIN = 258,

    DEC_NUMBER,     /* dec */
    OCT_NUMBER,     /* oct */
    HEX_NUMBER,     /* hex */
    NUMBER,         /*  */

    INCREMENT,  /* ++ */
    DECREMENT,  /* -- */

    UNARY_PLUS,     /* 一元 + *UNUSED* */
    UNARY_MINUS,    /* 一元 - *UNUSED* */
    LOGICAL_NOT,    /* ! */
    BITWISE_NOT,    /* ~ */
    SIZEOF,     /* ??? */

    MULTIPLICATION, /* * */
    DIVISION,   /* / */
    REMAINDER,  /* % */

    PLUS,       /* + */
    MINUS,      /* - */

    BITWISE_LEFT_SHIFT,     /* << */
    BITWISE_RIGHT_SHIFT,    /* >> */

    LESS_THAN,  /* < */
    LESS_EQUAL, /* <= */
    GREATER_THAN,   /* > */
    GREATER_EQUAL,  /* >= */

    EQUAL,          /* == */
    NOT_EQUAL,      /* != */

    BITWISE_AND,    /* & */

    BITWISE_XOR,    /* ^ */

    BITWISE_OR,     /* | */

    LOGICAL_AND,    /* && */

    LOGICAL_OR,     /* || */

    TERNARY_COND_QUEST,   /* ? of ?: */
    TERNARY_COND_COLON, /* : of ?: */

    COMMA,          /* , */

    OPEN_PAREN,     /* ( */
    CLOSE_PAREN,    /* ) */

    EOL,
    START_EXPR,
    END_EXPR,

    TOKENS_MAX
};


#ifdef __cplusplus
}
#endif


#endif /* __TOKENS_H__ */

/* vim: set ts=4 sts=4 et: */
