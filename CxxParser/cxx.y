
%define api.pure
%parse-param { CxxTokenReader *pTokRdr }

%{
#include <stdio.h>
#include "CxxTokenReader.hpp"
#define YYSTYPE CxxToken
%}


%{
// 实现这样调用：token = yylex(YYSTYPE *yylvalp, pTokRdr);
#define YYLEX_PARAM pTokRdr
%}


%token CXX_WORD

%token CXX_KW_and
%token CXX_KW_and_eq
%token CXX_KW_asm
%token CXX_KW_auto
%token CXX_KW_bitand
%token CXX_KW_bitor
%token CXX_KW_bool
%token CXX_KW_break
%token CXX_KW_case
%token CXX_KW_catch
%token CXX_KW_char
%token CXX_KW_class
%token CXX_KW_compl
%token CXX_KW_const
%token CXX_KW_const_cast
%token CXX_KW_continue
%token CXX_KW_default
%token CXX_KW_delete
%token CXX_KW_do
%token CXX_KW_double
%token CXX_KW_dynamic_cast
%token CXX_KW_else
%token CXX_KW_enum
%token CXX_KW_explicit
%token CXX_KW_export
%token CXX_KW_extern
%token CXX_KW_false
%token CXX_KW_float
%token CXX_KW_for
%token CXX_KW_friend
%token CXX_KW_goto
%token CXX_KW_if
%token CXX_KW_inline
%token CXX_KW_int
%token CXX_KW_long
%token CXX_KW_mutable
%token CXX_KW_namespace
%token CXX_KW_new
%token CXX_KW_not
%token CXX_KW_not_eq
%token CXX_KW_operator
%token CXX_KW_or
%token CXX_KW_or_eq
%token CXX_KW_private
%token CXX_KW_protected
%token CXX_KW_public
%token CXX_KW_register
%token CXX_KW_reinterpret_cast
%token CXX_KW_return
%token CXX_KW_short
%token CXX_KW_signed
%token CXX_KW_sizeof
%token CXX_KW_static
%token CXX_KW_static_cast
%token CXX_KW_struct
%token CXX_KW_switch
%token CXX_KW_template
%token CXX_KW_this
%token CXX_KW_throw
%token CXX_KW_true
%token CXX_KW_try
%token CXX_KW_typedef
%token CXX_KW_typeid
%token CXX_KW_typename
%token CXX_KW_union
%token CXX_KW_unsigned
%token CXX_KW_using
%token CXX_KW_virtual
%token CXX_KW_void
%token CXX_KW_volatile
%token CXX_KW_wchar_t
%token CXX_KW_while
%token CXX_KW_xor
%token CXX_KW_xor_eq

/* C++11 */
%token CXX_KW_alignas
%token CXX_KW_alignof
%token CXX_KW_char16_t
%token CXX_KW_char32_t
%token CXX_KW_constexpr
%token CXX_KW_decltype
%token CXX_KW_noexcept
%token CXX_KW_nullptr
%token CXX_KW_static_assert
%token CXX_KW_thread_local
%token CXX_KW_override
%token CXX_KW_final

%token CXX_OP_LParen
%token CXX_OP_RParen
%token CXX_OP_Comma
%token CXX_OP_LBrace
%token CXX_OP_RBrace
%token CXX_OP_LBracket
%token CXX_OP_RBracket
%token CXX_OP_Dot
%token CXX_OP_And
%token CXX_OP_Mul
%token CXX_OP_Plus
%token CXX_OP_Minus
%token CXX_OP_BitNot
%token CXX_OP_Not
%token CXX_OP_Div
%token CXX_OP_Mod
%token CXX_OP_LT
%token CXX_OP_GT
%token CXX_OP_XOR
%token CXX_OP_Or
%token CXX_OP_Question
%token CXX_OP_Colon
%token CXX_OP_Semicolon
%token CXX_OP_Equal

%token CXX_OP_DotStar
%token CXX_OP_ColonColon
%token CXX_OP_Arrow
%token CXX_OP_ArrowStar
%token CXX_OP_Incr
%token CXX_OP_Decr
%token CXX_OP_LShift
%token CXX_OP_RShift
%token CXX_OP_LE
%token CXX_OP_GE
%token CXX_OP_EQ
%token CXX_OP_NE
%token CXX_OP_AndAnd
%token CXX_OP_OrOr
%token CXX_OP_MulEqual
%token CXX_OP_DivEqual
%token CXX_OP_ModEqual
%token CXX_OP_PlusEqual
%token CXX_OP_MinusEqual
%token CXX_OP_LShiftEqual
%token CXX_OP_RShiftEqual
%token CXX_OP_AndEqual
%token CXX_OP_XOREqual
%token CXX_OP_OrEqual
%token CXX_OP_Ellipsis

%token CXX_INTEGER
%token CXX_CHAR
%token CXX_STRING
%token CXX_BLANK
%token CXX_BLANKS
%token CXX_INVALID


%%

translation_unit: /* ignore */
                | CXX_KW_class CXX_WORD CXX_OP_Semicolon {
                    printf("class: '%s'\n", $2.text.c_str());
                }

%%

/* vi:set et sts=4: */
