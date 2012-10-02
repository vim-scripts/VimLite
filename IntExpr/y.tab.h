
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
     END = 0,
     NUMBER = 258,
     OCT_NUMBER = 259,
     DEC_NUMBER = 260,
     HEX_NUMBER = 261,
     UNARY_PLUS = 262,
     UNARY_MINUS = 263,
     LOGICAL_NOT = 264,
     BITWISE_NOT = 265,
     MULTIPLICATION = 266,
     DIVISION = 267,
     REMAINDER = 268,
     PLUS = 269,
     MINUS = 270,
     BITWISE_LEFT_SHIFT = 271,
     BITWISE_RIGHT_SHIFT = 272,
     LESS_THAN = 273,
     LESS_EQUAL = 274,
     GREATER_THAN = 275,
     GREATER_EQUAL = 276,
     EQUAL = 277,
     NOT_EQUAL = 278,
     BITWISE_AND = 279,
     BITWISE_XOR = 280,
     BITWISE_OR = 281,
     LOGICAL_AND = 282,
     LOGICAL_OR = 283,
     TERNARY_COND_QUEST = 284,
     TERNARY_COND_COLON = 285,
     COMMA = 286,
     OPEN_PAREN = 287,
     CLOSE_PAREN = 288,
     EOL = 289
   };
#endif
/* Tokens.  */
#define END 0
#define NUMBER 258
#define OCT_NUMBER 259
#define DEC_NUMBER 260
#define HEX_NUMBER 261
#define UNARY_PLUS 262
#define UNARY_MINUS 263
#define LOGICAL_NOT 264
#define BITWISE_NOT 265
#define MULTIPLICATION 266
#define DIVISION 267
#define REMAINDER 268
#define PLUS 269
#define MINUS 270
#define BITWISE_LEFT_SHIFT 271
#define BITWISE_RIGHT_SHIFT 272
#define LESS_THAN 273
#define LESS_EQUAL 274
#define GREATER_THAN 275
#define GREATER_EQUAL 276
#define EQUAL 277
#define NOT_EQUAL 278
#define BITWISE_AND 279
#define BITWISE_XOR 280
#define BITWISE_OR 281
#define LOGICAL_AND 282
#define LOGICAL_OR 283
#define TERNARY_COND_QUEST 284
#define TERNARY_COND_COLON 285
#define COMMA 286
#define OPEN_PAREN 287
#define CLOSE_PAREN 288
#define EOL 289




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;


