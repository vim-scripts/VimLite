
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton interface for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     CXX_WORD = 258,
     CXX_KW_and = 259,
     CXX_KW_and_eq = 260,
     CXX_KW_asm = 261,
     CXX_KW_auto = 262,
     CXX_KW_bitand = 263,
     CXX_KW_bitor = 264,
     CXX_KW_bool = 265,
     CXX_KW_break = 266,
     CXX_KW_case = 267,
     CXX_KW_catch = 268,
     CXX_KW_char = 269,
     CXX_KW_class = 270,
     CXX_KW_compl = 271,
     CXX_KW_const = 272,
     CXX_KW_const_cast = 273,
     CXX_KW_continue = 274,
     CXX_KW_default = 275,
     CXX_KW_delete = 276,
     CXX_KW_do = 277,
     CXX_KW_double = 278,
     CXX_KW_dynamic_cast = 279,
     CXX_KW_else = 280,
     CXX_KW_enum = 281,
     CXX_KW_explicit = 282,
     CXX_KW_export = 283,
     CXX_KW_extern = 284,
     CXX_KW_false = 285,
     CXX_KW_float = 286,
     CXX_KW_for = 287,
     CXX_KW_friend = 288,
     CXX_KW_goto = 289,
     CXX_KW_if = 290,
     CXX_KW_inline = 291,
     CXX_KW_int = 292,
     CXX_KW_long = 293,
     CXX_KW_mutable = 294,
     CXX_KW_namespace = 295,
     CXX_KW_new = 296,
     CXX_KW_not = 297,
     CXX_KW_not_eq = 298,
     CXX_KW_operator = 299,
     CXX_KW_or = 300,
     CXX_KW_or_eq = 301,
     CXX_KW_private = 302,
     CXX_KW_protected = 303,
     CXX_KW_public = 304,
     CXX_KW_register = 305,
     CXX_KW_reinterpret_cast = 306,
     CXX_KW_return = 307,
     CXX_KW_short = 308,
     CXX_KW_signed = 309,
     CXX_KW_sizeof = 310,
     CXX_KW_static = 311,
     CXX_KW_static_cast = 312,
     CXX_KW_struct = 313,
     CXX_KW_switch = 314,
     CXX_KW_template = 315,
     CXX_KW_this = 316,
     CXX_KW_throw = 317,
     CXX_KW_true = 318,
     CXX_KW_try = 319,
     CXX_KW_typedef = 320,
     CXX_KW_typeid = 321,
     CXX_KW_typename = 322,
     CXX_KW_union = 323,
     CXX_KW_unsigned = 324,
     CXX_KW_using = 325,
     CXX_KW_virtual = 326,
     CXX_KW_void = 327,
     CXX_KW_volatile = 328,
     CXX_KW_wchar_t = 329,
     CXX_KW_while = 330,
     CXX_KW_xor = 331,
     CXX_KW_xor_eq = 332,
     CXX_KW_alignas = 333,
     CXX_KW_alignof = 334,
     CXX_KW_char16_t = 335,
     CXX_KW_char32_t = 336,
     CXX_KW_constexpr = 337,
     CXX_KW_decltype = 338,
     CXX_KW_noexcept = 339,
     CXX_KW_nullptr = 340,
     CXX_KW_static_assert = 341,
     CXX_KW_thread_local = 342,
     CXX_KW_override = 343,
     CXX_KW_final = 344,
     CXX_OP_LParen = 345,
     CXX_OP_RParen = 346,
     CXX_OP_Comma = 347,
     CXX_OP_LBrace = 348,
     CXX_OP_RBrace = 349,
     CXX_OP_LBracket = 350,
     CXX_OP_RBracket = 351,
     CXX_OP_Dot = 352,
     CXX_OP_And = 353,
     CXX_OP_Mul = 354,
     CXX_OP_Plus = 355,
     CXX_OP_Minus = 356,
     CXX_OP_BitNot = 357,
     CXX_OP_Not = 358,
     CXX_OP_Div = 359,
     CXX_OP_Mod = 360,
     CXX_OP_LT = 361,
     CXX_OP_GT = 362,
     CXX_OP_XOR = 363,
     CXX_OP_Or = 364,
     CXX_OP_Question = 365,
     CXX_OP_Colon = 366,
     CXX_OP_Semicolon = 367,
     CXX_OP_Equal = 368,
     CXX_OP_DotStar = 369,
     CXX_OP_ColonColon = 370,
     CXX_OP_Arrow = 371,
     CXX_OP_ArrowStar = 372,
     CXX_OP_Incr = 373,
     CXX_OP_Decr = 374,
     CXX_OP_LShift = 375,
     CXX_OP_RShift = 376,
     CXX_OP_LE = 377,
     CXX_OP_GE = 378,
     CXX_OP_EQ = 379,
     CXX_OP_NE = 380,
     CXX_OP_AndAnd = 381,
     CXX_OP_OrOr = 382,
     CXX_OP_MulEqual = 383,
     CXX_OP_DivEqual = 384,
     CXX_OP_ModEqual = 385,
     CXX_OP_PlusEqual = 386,
     CXX_OP_MinusEqual = 387,
     CXX_OP_LShiftEqual = 388,
     CXX_OP_RShiftEqual = 389,
     CXX_OP_AndEqual = 390,
     CXX_OP_XOREqual = 391,
     CXX_OP_OrEqual = 392,
     CXX_OP_Ellipsis = 393,
     CXX_INTEGER = 394,
     CXX_CHAR = 395,
     CXX_STRING = 396,
     CXX_BLANK = 397,
     CXX_BLANKS = 398,
     CXX_INVALID = 399
   };
#endif
/* Tokens.  */
#define CXX_WORD 258
#define CXX_KW_and 259
#define CXX_KW_and_eq 260
#define CXX_KW_asm 261
#define CXX_KW_auto 262
#define CXX_KW_bitand 263
#define CXX_KW_bitor 264
#define CXX_KW_bool 265
#define CXX_KW_break 266
#define CXX_KW_case 267
#define CXX_KW_catch 268
#define CXX_KW_char 269
#define CXX_KW_class 270
#define CXX_KW_compl 271
#define CXX_KW_const 272
#define CXX_KW_const_cast 273
#define CXX_KW_continue 274
#define CXX_KW_default 275
#define CXX_KW_delete 276
#define CXX_KW_do 277
#define CXX_KW_double 278
#define CXX_KW_dynamic_cast 279
#define CXX_KW_else 280
#define CXX_KW_enum 281
#define CXX_KW_explicit 282
#define CXX_KW_export 283
#define CXX_KW_extern 284
#define CXX_KW_false 285
#define CXX_KW_float 286
#define CXX_KW_for 287
#define CXX_KW_friend 288
#define CXX_KW_goto 289
#define CXX_KW_if 290
#define CXX_KW_inline 291
#define CXX_KW_int 292
#define CXX_KW_long 293
#define CXX_KW_mutable 294
#define CXX_KW_namespace 295
#define CXX_KW_new 296
#define CXX_KW_not 297
#define CXX_KW_not_eq 298
#define CXX_KW_operator 299
#define CXX_KW_or 300
#define CXX_KW_or_eq 301
#define CXX_KW_private 302
#define CXX_KW_protected 303
#define CXX_KW_public 304
#define CXX_KW_register 305
#define CXX_KW_reinterpret_cast 306
#define CXX_KW_return 307
#define CXX_KW_short 308
#define CXX_KW_signed 309
#define CXX_KW_sizeof 310
#define CXX_KW_static 311
#define CXX_KW_static_cast 312
#define CXX_KW_struct 313
#define CXX_KW_switch 314
#define CXX_KW_template 315
#define CXX_KW_this 316
#define CXX_KW_throw 317
#define CXX_KW_true 318
#define CXX_KW_try 319
#define CXX_KW_typedef 320
#define CXX_KW_typeid 321
#define CXX_KW_typename 322
#define CXX_KW_union 323
#define CXX_KW_unsigned 324
#define CXX_KW_using 325
#define CXX_KW_virtual 326
#define CXX_KW_void 327
#define CXX_KW_volatile 328
#define CXX_KW_wchar_t 329
#define CXX_KW_while 330
#define CXX_KW_xor 331
#define CXX_KW_xor_eq 332
#define CXX_KW_alignas 333
#define CXX_KW_alignof 334
#define CXX_KW_char16_t 335
#define CXX_KW_char32_t 336
#define CXX_KW_constexpr 337
#define CXX_KW_decltype 338
#define CXX_KW_noexcept 339
#define CXX_KW_nullptr 340
#define CXX_KW_static_assert 341
#define CXX_KW_thread_local 342
#define CXX_KW_override 343
#define CXX_KW_final 344
#define CXX_OP_LParen 345
#define CXX_OP_RParen 346
#define CXX_OP_Comma 347
#define CXX_OP_LBrace 348
#define CXX_OP_RBrace 349
#define CXX_OP_LBracket 350
#define CXX_OP_RBracket 351
#define CXX_OP_Dot 352
#define CXX_OP_And 353
#define CXX_OP_Mul 354
#define CXX_OP_Plus 355
#define CXX_OP_Minus 356
#define CXX_OP_BitNot 357
#define CXX_OP_Not 358
#define CXX_OP_Div 359
#define CXX_OP_Mod 360
#define CXX_OP_LT 361
#define CXX_OP_GT 362
#define CXX_OP_XOR 363
#define CXX_OP_Or 364
#define CXX_OP_Question 365
#define CXX_OP_Colon 366
#define CXX_OP_Semicolon 367
#define CXX_OP_Equal 368
#define CXX_OP_DotStar 369
#define CXX_OP_ColonColon 370
#define CXX_OP_Arrow 371
#define CXX_OP_ArrowStar 372
#define CXX_OP_Incr 373
#define CXX_OP_Decr 374
#define CXX_OP_LShift 375
#define CXX_OP_RShift 376
#define CXX_OP_LE 377
#define CXX_OP_GE 378
#define CXX_OP_EQ 379
#define CXX_OP_NE 380
#define CXX_OP_AndAnd 381
#define CXX_OP_OrOr 382
#define CXX_OP_MulEqual 383
#define CXX_OP_DivEqual 384
#define CXX_OP_ModEqual 385
#define CXX_OP_PlusEqual 386
#define CXX_OP_MinusEqual 387
#define CXX_OP_LShiftEqual 388
#define CXX_OP_RShiftEqual 389
#define CXX_OP_AndEqual 390
#define CXX_OP_XOREqual 391
#define CXX_OP_OrEqual 392
#define CXX_OP_Ellipsis 393
#define CXX_INTEGER 394
#define CXX_CHAR 395
#define CXX_STRING 396
#define CXX_BLANK 397
#define CXX_BLANKS 398
#define CXX_INVALID 399




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif




