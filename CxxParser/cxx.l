/* C++ 词法分析器，不支持续行的，理论上，续行是在预处理阶段搞定的，
   gcc 就是如此处理的。暂时只用最简单的实现处理大多数的情况
   NOTE(2012-06-28):
     忽略所有预处理指令
     不支持普通状态下的续行，其他四种全局状态的续行已经支持 */

%{
#include <stdio.h>
#include "CxxLexPrvtData.h"
#ifdef _STANDALONE
/* 不和 yacc 一起用的时候 */
# include "symbols.h"
#else
# ifndef __CXXPARSER_HPP__
# define __CXXPARSER_HPP__
#  include "CxxParser.hpp"
# endif
#endif
%}

%option nodefault noyywrap yylineno
%option reentrant
%option prefix="cxx_yy"

 /* 纯词法分析器的私有数据结构，在规则部分通过宏 yyextra 获取 */
%option extra-type="CxxLexPrvtData *"

 /* ======================================================================= */
 /* 基本符号定义 */
WORD [a-zA-Z_][a-zA-Z_0-9]*

 /* 通用字符名 */
UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})
 /* 浮点指数部分 */
EXP ([eE][-+]?[0-9]+)
 /* 整数长度 */
INTLEN ([uU](l|L|ll|LL)?|(l|L|ll|LL)[uU]?)

BLANK [ \t]
SPACE [ \t\v\f\r\n]
NEWLINE (\r\n|\r|\n)

 /* ======================================================================= */
 /* 其他四种全局状态 */
%x X_CXX_CCOMMENT
%x X_CXX_COMMENT
 /* 字符 */
%x X_CXX_CHAR
 /* 字符串 */
%x X_CXX_STRING
 /* 简单处理宏的情况，暂时全部忽略 */
%x X_CXX_PREPROC

%%

%{
    /* 可在这里通过 yyextra 获取私有数据结构（不能这样用） */
    /*static CxxLexPrvtData *s_pPrvtdata = yyextra;*/
%}

 /* C++ 关键词 */
and             { return CXX_KW_and; }
and_eq          { return CXX_KW_and_eq; }
asm             { return CXX_KW_asm; }
auto            { return CXX_KW_auto; }
bitand          { return CXX_KW_bitand; }
bitor           { return CXX_KW_bitor; }
bool            { return CXX_KW_bool; }
break           { return CXX_KW_break; }
case            { return CXX_KW_case; }
catch           { return CXX_KW_catch; }
char            { return CXX_KW_char; }
class           { return CXX_KW_class; }
compl           { return CXX_KW_compl; }
const           { return CXX_KW_const; }
const_cast      { return CXX_KW_const_cast; }
continue        { return CXX_KW_continue; }
default         { return CXX_KW_default; }
delete          { return CXX_KW_delete; }
do              { return CXX_KW_do; }
double          { return CXX_KW_double; }
dynamic_cast    { return CXX_KW_dynamic_cast; }
else            { return CXX_KW_else; }
enum            { return CXX_KW_enum; }
explicit        { return CXX_KW_explicit; }
export          { return CXX_KW_export; }
extern          { return CXX_KW_extern; }
false           { return CXX_KW_false; }
float           { return CXX_KW_float; }
for             { return CXX_KW_for; }
friend          { return CXX_KW_friend; }
goto            { return CXX_KW_goto; }
if              { return CXX_KW_if; }
inline          { return CXX_KW_inline; }
int             { return CXX_KW_int; }
long            { return CXX_KW_long; }
mutable         { return CXX_KW_mutable; }
namespace       { return CXX_KW_namespace; }
new             { return CXX_KW_new; }
not             { return CXX_KW_not; }
not_eq          { return CXX_KW_not_eq; }
operator        { return CXX_KW_operator; }
or              { return CXX_KW_or; }
or_eq           { return CXX_KW_or_eq; }
private         { return CXX_KW_private; }
protected       { return CXX_KW_protected; }
public          { return CXX_KW_public; }
register        { return CXX_KW_register; }
reinterpret_cast    { return CXX_KW_reinterpret_cast; }
return          { return CXX_KW_return; }
short           { return CXX_KW_short; }
signed          { return CXX_KW_signed; }
sizeof          { return CXX_KW_sizeof; }
static          { return CXX_KW_static; }
static_cast     { return CXX_KW_static_cast; }
struct          { return CXX_KW_struct; }
switch          { return CXX_KW_switch; }
template        { return CXX_KW_template; }
this            { return CXX_KW_this; }
throw           { return CXX_KW_throw; }
true            { return CXX_KW_true; }
try             { return CXX_KW_try; }
typedef         { return CXX_KW_typedef; }
typeid          { return CXX_KW_typeid; }
typename        { return CXX_KW_typename; }
union           { return CXX_KW_union; }
unsigned        { return CXX_KW_unsigned; }
using           { return CXX_KW_using; }
virtual         { return CXX_KW_virtual; }
void            { return CXX_KW_void; }
volatile        { return CXX_KW_volatile; }
wchar_t         { return CXX_KW_wchar_t; }
while           { return CXX_KW_while; }
xor             { return CXX_KW_xor; }
xor_eq          { return CXX_KW_xor_eq; }
 /* ==================== C++11 ==================== */
alignas         { return CXX_KW_alignas; }
alignof         { return CXX_KW_alignof; }
char16_t        { return CXX_KW_char16_t; }
char32_t        { return CXX_KW_char32_t; }
constexpr       { return CXX_KW_constexpr; }
decltype        { return CXX_KW_decltype; }
noexcept        { return CXX_KW_noexcept; }
nullptr         { return CXX_KW_nullptr; }
static_assert   { return CXX_KW_static_assert; }
thread_local    { return CXX_KW_thread_local; }
override        { return CXX_KW_override; }
final           { return CXX_KW_final; }


"("             { return (CXX_OP_LParen); }
")"             { return (CXX_OP_RParen); }
","             { return (CXX_OP_Comma); }
"{"             { return (CXX_OP_LBrace); }
"}"             { return (CXX_OP_RBrace); }
"["             { return (CXX_OP_LBracket); }
"]"             { return (CXX_OP_RBracket); }
"."             { return (CXX_OP_Dot); }
"&"             { return (CXX_OP_And); }
"*"             { return (CXX_OP_Mul); }
"+"             { return (CXX_OP_Plus); }
"-"             { return (CXX_OP_Minus); }
"~"             { return (CXX_OP_BitNot); }
"!"             { return (CXX_OP_Not); }
"/"             { return (CXX_OP_Div); }
"%"             { return (CXX_OP_Mod); }
"<"             { return (CXX_OP_LT); }
">"             { return (CXX_OP_GT); }
"^"             { return (CXX_OP_XOR); }
"|"             { return (CXX_OP_Or); }
"?"             { return (CXX_OP_Question); }
":"             { return (CXX_OP_Colon); }
";"             { return (CXX_OP_Semicolon); }
"="             { return (CXX_OP_Equal); }

".*"            { return (CXX_OP_DotStar); }
"::"            { return (CXX_OP_ColonColon); }
"->"            { return (CXX_OP_Arrow); }
"->*"           { return (CXX_OP_ArrowStar); }
"++"            { return (CXX_OP_Incr); }
"--"            { return (CXX_OP_Decr); }
"<<"            { return (CXX_OP_LShift); }
">>"            { return (CXX_OP_RShift); }
"<="            { return (CXX_OP_LE); }
">="            { return (CXX_OP_GE); }
"=="            { return (CXX_OP_EQ); }
"!="            { return (CXX_OP_NE); }
"&&"            { return (CXX_OP_AndAnd); }
"||"            { return (CXX_OP_OrOr); }
"*="            { return (CXX_OP_MulEqual); }
"/="            { return (CXX_OP_DivEqual); }
"%="            { return (CXX_OP_ModEqual); }
"+="            { return (CXX_OP_PlusEqual); }
"-="            { return (CXX_OP_MinusEqual); }
"<<="           { return (CXX_OP_LShiftEqual); }
">>="           { return (CXX_OP_RShiftEqual); }
"&="            { return (CXX_OP_AndEqual); }
"^="            { return (CXX_OP_XOREqual); }
"|="            { return (CXX_OP_OrEqual); }
"..."           { return (CXX_OP_Ellipsis); }


 /* 预处理指令
  define, undef, include, if, ifdef, ifndef, else, elif, endif, line, error, 
  warning, pragma
  */
 /* 预处理全部忽略 */
^{BLANK}*"#"{BLANK}*        { BEGIN X_CXX_PREPROC; }
 /* 跳过其他四种全局状态，不需要提取 */
<X_CXX_PREPROC>"/*" { yyextra->yySavedState = YY_START; BEGIN X_CXX_CCOMMENT; }
<X_CXX_PREPROC>"//" { yyextra->yySavedState = YY_START; BEGIN X_CXX_COMMENT; }
<X_CXX_PREPROC>\"   { yyextra->yySavedState = YY_START; BEGIN X_CXX_STRING; }
<X_CXX_PREPROC>\'   { yyextra->yySavedState = YY_START; BEGIN X_CXX_CHAR; }
<X_CXX_PREPROC>\\{NEWLINE}  { /* 续行 */ }
<X_CXX_PREPROC>.            { /* 全部忽略 */ }
<X_CXX_PREPROC>{NEWLINE}    { BEGIN INITIAL; }
<X_CXX_PREPROC><<EOF>>      { yyterminate(); }


{WORD}  { return CXX_WORD; }

 /* 整数 */
0[0-7]*{INTLEN}?            |
[1-9][0-9]*{INTLEN}?        |
0[xX][0-9a-fA-F]+{INTLEN}   { return CXX_INTEGER; }

[ \t]       { /*return CXX_BLANK;*/ /* 忽略空白 */ }
[ \t]+      { /*return CXX_BLANKS;*/ /* 忽略空白 */ }

 /* 跳过 C 注释 */
"/*"    { yyextra->yySavedState = YY_START; BEGIN X_CXX_CCOMMENT; }

 /* 跳过 C++ 注释 */
"//"    { yyextra->yySavedState = YY_START; BEGIN X_CXX_COMMENT; }

 /* 普通状态时，需要提取字符和字符串，所以不是用这种方式
\'      { yyextra->yySavedState = YY_START; BEGIN X_CXX_CHAR; }
\"      { yyextra->yySavedState = YY_START; BEGIN X_CXX_STRING; }
 */

 /* 提取字符，错误的格式也会包含进 yytext */
\'[^']*\'           {   

    /* '"' 前面的连续的反斜杠的总数，只有为奇数时才需要特殊处理 */
    int cnt = 0;
    int i;
    for ( i = yyleng - 2; i >= 0; i-- ) {
        if ( yytext[i] != '\\' ) {
            break;
        }
        cnt += 1;
    }
    
    if ( cnt & 0x1 ) {
            yyless(yyleng-1);
            yymore();
        } else {
            return CXX_CHAR;
        }
}

 /* 提取字符串 */
L?\"[^"]*\"         {
    /* '"' 前面的连续的反斜杠的总数，只有为奇数时才需要特殊处理 */
    int cnt = 0;
    int i;
    for ( i = yyleng - 2; i >= 0; i-- ) {
        if ( yytext[i] != '\\' ) {
            break;
        }
        cnt += 1;
    }

    if ( cnt & 0x1 ) {
        yyless(yyleng-1);
        yymore();
    } else {
        return CXX_STRING;
    }
}

 /* ========================================================================= */
 /* 除普通状态外的其他四个全局状态，需要跳过的时候用，需要提取的话，不能用 */
 /* 跳过 C 注释 */
<X_CXX_CCOMMENT>.           |
<X_CXX_CCOMMENT>{NEWLINE}   { /* 忽略 */ }
<X_CXX_CCOMMENT>"*/"        { BEGIN yyextra->yySavedState; }
<X_CXX_CCOMMENT><<EOF>>     { yyterminate(); }

 /* 跳过 C++ 注释 */
<X_CXX_COMMENT>\\{NEWLINE}  { /* 支持续行了 */ }
<X_CXX_COMMENT>.            { }
<X_CXX_COMMENT>{NEWLINE}    { yyless(0); BEGIN yyextra->yySavedState; }
<X_CXX_COMMENT><<EOF>>      { yyterminate(); }

 /* 需要跳过字符的时候用，需要提取的话，不能用 */
<X_CXX_CHAR>\\{NEWLINE} { /* 支持续行 */ }
<X_CXX_CHAR>\\\'        { }
<X_CXX_CHAR>[^']        { }
<X_CXX_CHAR>\'          { BEGIN yyextra->yySavedState; }
<X_CXX_CHAR><<EOF>>     { yyterminate(); }

 /* 需要跳过字符串的时候用，需要提取的话，不能用 */
<X_CXX_STRING>\\{NEWLINE}   { /* 支持续行 */ }
<X_CXX_STRING>\\\"          { }
<X_CXX_STRING>[^"]          { }
<X_CXX_STRING>\"            { BEGIN yyextra->yySavedState; }
<X_CXX_STRING><<EOF>>       { yyterminate(); }
 /* ========================================================================= */

.           { return CXX_INVALID; }

{NEWLINE}   { }

<<EOF>>     { yyterminate(); }

%%

 /* vi:set et sts=4: */
