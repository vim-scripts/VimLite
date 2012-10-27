/*
*   $Id: get.c 559 2007-06-17 03:30:09Z elliotth $
*
*   Copyright (c) 1996-2002, Darren Hiebert
*
*   This source code is released for free distribution under the terms of the
*   GNU General Public License.
*
*   This module contains the high level source read functions (preprocessor
*   directives are handled within this level).
*/

/*
*   INCLUDE FILES
*/
#include "general.h"  /* must always come first */

#include <string.h>

#include "debug.h"
#include "entry.h"
#include "get.h"
#include "options.h"
#include "read.h"
#include "vstring.h"
#include "routines.h"

/* MOD by fanhe */
#include "macro.h"
#include "ftStack.h"

/*
*   MACROS
*/
#define stringMatch(s1,s2)		(strcmp (s1,s2) == 0)
#define isspacetab(c)			((c) == SPACE || (c) == TAB)

/*
*   DATA DECLARATIONS
*/
typedef enum { COMMENT_NONE, COMMENT_C, COMMENT_CPLUS } Comment;

enum eCppLimits {
	MaxCppNestingLevel = 20,
	MaxDirectiveName = 10
};

/*  Defines the one nesting level of a preprocessor conditional.
 */
typedef struct sConditionalInfo {
	boolean ignoreAllBranches;  /* ignoring parent conditional branch */
	boolean singleBranch;       /* choose only one branch */
	boolean branchChosen;       /* branch already selected */
	boolean ignoring;           /* current ignore state */
} conditionalInfo;

enum eState {
	DRCTV_NONE,    /* no known directive - ignore to end of line */
	DRCTV_DEFINE,  /* "#define" encountered */
	DRCTV_HASH,    /* initial '#' read; determine directive */
	DRCTV_IF,      /* "#if" or "#ifdef" encountered */
	DRCTV_PRAGMA,  /* #pragma encountered */
	DRCTV_UNDEF    /* "#undef" encountered */
};

/* 对单行文本的宏判断结果标识 */
typedef enum ePPLineKind {
	PP_LK_INVALID,   /* invalid preprocess directive */

    PP_LK_DEFINE,    /* #define */
    PP_LK_IFDEF,     /* #ifdef */
    PP_LK_IFNDEF,    /* #ifndef */
    PP_LK_IF,        /* #if */
    PP_LK_ELSE,      /* #else */
	PP_LK_ELIF,      /* #elif */
    PP_LK_ENDIF,     /* #endif */
	PP_LK_UNDEF,     /* #undef */

	PP_LK_INCLUDE,   /* #include */
	PP_LK_LINE,      /* #line */
	PP_LK_PRAGMA,    /* #pragma */
    PP_LK_ERROR,     /* #error */

    PP_LK_OTHER      /* other */
} PPLineKind;

/* 预处理条件分支状态机状态标识 */
typedef enum ePPCondInfo {
    PP_CI_NONE,
    PP_CI_HAD_CHOOSE_BRANCH /* had choose one branch(#if/#elif/#else/#endif) */
} PPCondInfo;

/*  Defines the current state of the pre-processor.
 */
typedef struct sCppState {
	int		ungetch, ungetch2;   /* ungotten characters, if any */
	boolean resolveRequired;     /* must resolve if/else/elif/endif branch */
	boolean hasAtLiteralStrings; /* supports @"c:\" strings */
	struct sDirective {
		enum eState state;       /* current directive being processed */
		boolean	accept;          /* is a directive syntactically permitted? */
		vString * name;          /* macro name */
		unsigned int nestLevel;  /* level 0 is not used */
		conditionalInfo ifdef [MaxCppNestingLevel];
	} directive;

	boolean enableCppGetcCache;  /* whether enable cache */
	vString * cppGetcCache;      /* cache string of cppGetc() */

	boolean parsingGlobalMacros; /* whether is parsing global macros */
	Stack * condStack;           /* for handling preprocessor condition */
	Stack * condInfoStack;       /* for record single branch condition */
	HashTable * macrosTable;     /* macros table */
} cppState;

/*
*   DATA DEFINITIONS
*/

HashTable * GlobalMacrosTable = NULL;

/*  Use brace formatting to detect end of block.
 */
static boolean BraceFormat = FALSE;

static cppState Cpp = {
	'\0', '\0',  /* ungetch characters */
	FALSE,       /* resolveRequired */
	FALSE,       /* hasAtLiteralStrings */
	{
		DRCTV_NONE,  /* state */
		FALSE,       /* accept */
		NULL,        /* tag name */
		0,           /* nestLevel */
		{ {FALSE,FALSE,FALSE,FALSE} }  /* ifdef array */
	}  /* directive */

	,FALSE
	,NULL

	,FALSE
};

/*
*   FUNCTION DEFINITIONS
*/

static void ParseGlobalMacros(const char *file);

extern boolean isBraceFormat (void)
{
	return BraceFormat;
}

extern unsigned int getDirectiveNestLevel (void)
{
	return Cpp.directive.nestLevel;
}

extern void cppInit (const boolean state, const boolean hasAtLiteralStrings)
{
	BraceFormat = state;

	Cpp.ungetch         = '\0';
	Cpp.ungetch2        = '\0';
	Cpp.resolveRequired = FALSE;
	Cpp.hasAtLiteralStrings = hasAtLiteralStrings;

	Cpp.directive.state     = DRCTV_NONE;
	Cpp.directive.accept    = TRUE;
	Cpp.directive.nestLevel = 0;

	Cpp.directive.ifdef [0].ignoreAllBranches = FALSE;
	Cpp.directive.ifdef [0].singleBranch = FALSE;
	Cpp.directive.ifdef [0].branchChosen = FALSE;
	Cpp.directive.ifdef [0].ignoring     = FALSE;

	if (Cpp.directive.name == NULL)
		Cpp.directive.name = vStringNew ();
	else
		vStringClear (Cpp.directive.name);

	if (Cpp.cppGetcCache == NULL)
		Cpp.cppGetcCache = vStringNew ();
	else
		vStringClear (Cpp.cppGetcCache);

	Cpp.parsingGlobalMacros = FALSE;
	Cpp.condStack = Stack_Create((size_t)MaxCppNestingLevel);
	if (Cpp.condStack == NULL)
		error(FATAL, "out of memory");
	Stack_Push(Cpp.condStack, (void *)TRUE); /* initial condition */
	Cpp.condInfoStack = Stack_Create((size_t)MaxCppNestingLevel);
	if (Cpp.condInfoStack == NULL)
		error(FATAL, "out of memory");
	Stack_Push(Cpp.condInfoStack, (void *)PP_CI_HAD_CHOOSE_BRANCH);

	Cpp.macrosTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
	if (Cpp.macrosTable == NULL)
		error(FATAL, "out of memory");

	if ( GlobalMacrosTable == NULL )
	{
		char buf[BUFSIZ];
		StrIter iter;
		const char *files = NULL;
		GlobalMacrosTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
		if (GlobalMacrosTable == NULL)
			error(FATAL, "out of memory");
#ifdef _DEBUG
		/*files = "global.h,global.hpp";*/
#else
		/* ',' 分割的文件列表，类似 $PATH */
		files = getenv("CTAGS_GLOBAL_MACROS_FILES");
#endif
		if ( files != NULL )
		{
			vString *origFile = vStringNewInit(getSourceFileName());
			int origLang = getSourceLanguage();

			StrIterSplitInit(&iter, files, STR_MAX_SPLIT);
			while ( StrIterSplitNext(&iter, ",", buf, sizeof(buf)) )
			{
				if ( IsBufferOverflow(buf, sizeof(buf)) )
				{
					/* 文件名太长，忽略 */
					error(WARNING, "Is a macro file name too long? Ignored!\n");
					continue;
				}
				Cpp.parsingGlobalMacros = TRUE;
				ParseGlobalMacros(buf);
			}

			cppTerminate();
#ifdef _DEBUG
			PrintMacros(GlobalMacrosTable);
			puts("==========");
#endif

			/* restart */
			fileOpen(vStringValue(origFile), origLang);
			cppInit(state, hasAtLiteralStrings);

			vStringDelete(origFile);
			origFile = NULL;
		}
	}
}

extern void cppTerminate (void)
{
	if (Cpp.directive.name != NULL)
	{
		vStringDelete (Cpp.directive.name);
		Cpp.directive.name = NULL;

		vStringDelete (Cpp.cppGetcCache);
		Cpp.cppGetcCache = NULL;

		Stack_Destroy(Cpp.condStack, NULL);
		Cpp.condStack = NULL;
		Stack_Destroy(Cpp.condInfoStack, NULL);
		Cpp.condInfoStack = NULL;

#ifdef _DEBUG
		PrintMacros(Cpp.macrosTable);
#endif
		HashTable_Destroy(Cpp.macrosTable, (DestroyFunc)CMacroDelete);
		Cpp.macrosTable = NULL;
	}
}

extern void cppBeginStatement (void)
{
	Cpp.resolveRequired = TRUE;
}

extern void cppEndStatement (void)
{
	Cpp.resolveRequired = FALSE;
}

/*
*   Scanning functions
*
*   This section handles preprocessor directives.  It strips out all
*   directives and may emit a tag for #define directives.
*/

/*  This puts a character back into the input queue for the source File.
 *  Up to two characters may be ungotten.
 */
extern void cppUngetc (const int c)
{
	Assert (Cpp.ungetch2 == '\0');
	Cpp.ungetch2 = Cpp.ungetch;
	Cpp.ungetch = c;

	vStringChop (Cpp.cppGetcCache);
}

/*  Reads a directive, whose first character is given by "c", into "name".
 */
static boolean readDirective (int c, char *const name, unsigned int maxLength)
{
	unsigned int i;

	for (i = 0  ;  i < maxLength - 1  ;  ++i)
	{
		if (i > 0)
		{
			c = fileGetc ();
			if (c == EOF  ||  ! isalpha (c))
			{
				fileUngetc (c);
				break;
			}
		}
		name [i] = c;
	}
	name [i] = '\0';  /* null terminate */

	return (boolean) isspacetab (c);
}

/*  Reads an identifier, whose first character is given by "c", into "tag",
 *  together with the file location and corresponding line number.
 */
static void readIdentifier (int c, vString *const name)
{
	vStringClear (name);
	do
	{
		vStringPut (name, c);
	} while (c = fileGetc (), (c != EOF  &&  isident (c)));
	fileUngetc (c);
	vStringTerminate (name);
}

static conditionalInfo *currentConditional (void)
{
	return &Cpp.directive.ifdef [Cpp.directive.nestLevel];
}

static boolean isIgnore (void)
{
	return Cpp.directive.ifdef [Cpp.directive.nestLevel].ignoring;
}

static boolean setIgnore (const boolean ignore)
{
	return Cpp.directive.ifdef [Cpp.directive.nestLevel].ignoring = ignore;
}

static boolean isIgnoreBranch (void)
{
	conditionalInfo *const ifdef = currentConditional ();

	/*  Force a single branch if an incomplete statement is discovered
	 *  en route. This may have allowed earlier branches containing complete
	 *  statements to be followed, but we must follow no further branches.
	 */
	if (Cpp.resolveRequired  &&  ! BraceFormat)
		ifdef->singleBranch = TRUE;

	/*  We will ignore this branch in the following cases:
	 *
	 *  1.  We are ignoring all branches (conditional was within an ignored
	 *        branch of the parent conditional)
	 *  2.  A branch has already been chosen and either of:
	 *      a.  A statement was incomplete upon entering the conditional
	 *      b.  A statement is incomplete upon encountering a branch
	 */
	return (boolean) (ifdef->ignoreAllBranches ||
					 (ifdef->branchChosen  &&  ifdef->singleBranch));
}

static void chooseBranch (void)
{
	if (! BraceFormat)
	{
		conditionalInfo *const ifdef = currentConditional ();

		ifdef->branchChosen = (boolean) (ifdef->singleBranch ||
										Cpp.resolveRequired);
	}
}

/*  Pushes one nesting level for an #if directive, indicating whether or not
 *  the branch should be ignored and whether a branch has already been chosen.
 */
static boolean pushConditional (const boolean firstBranchChosen)
{
	const boolean ignoreAllBranches = isIgnore ();  /* current ignore */
	boolean ignoreBranch = FALSE;

	if (Cpp.directive.nestLevel < (unsigned int) MaxCppNestingLevel - 1)
	{
		conditionalInfo *ifdef;

		++Cpp.directive.nestLevel;
		ifdef = currentConditional ();

		/*  We take a snapshot of whether there is an incomplete statement in
		 *  progress upon encountering the preprocessor conditional. If so,
		 *  then we will flag that only a single branch of the conditional
		 *  should be followed.
		 */
		ifdef->ignoreAllBranches = ignoreAllBranches;
		ifdef->singleBranch      = Cpp.resolveRequired;
		ifdef->branchChosen      = firstBranchChosen;
		ifdef->ignoring = (boolean) (ignoreAllBranches || (
				! firstBranchChosen  &&  ! BraceFormat  &&
				(ifdef->singleBranch || !Option.if0)));
		ignoreBranch = ifdef->ignoring;
	}
	return ignoreBranch;
}

/*  Pops one nesting level for an #endif directive.
 */
static boolean popConditional (void)
{
	if (Cpp.directive.nestLevel > 0)
		--Cpp.directive.nestLevel;

	return isIgnore ();
}

static void makeDefineTag (const char *const name)
{
	const boolean isFileScope = (boolean) (! isHeaderFile ());

	if (includingDefineTags () &&
		(! isFileScope  ||  Option.include.fileScope))
	{
		tagEntryInfo e;
		initTagEntry (&e, name);
		e.lineNumberEntry = (boolean) (Option.locate != EX_PATTERN);
		e.isFileScope  = isFileScope;
		/*e.truncateLine = TRUE;*/
		e.truncateLine = FALSE;
		e.kindName     = "macro";
		e.kind         = 'd';
		makeTagEntry (&e);
	}
}

static void directiveDefine (const int c)
{
	if (isident1 (c))
	{
		readIdentifier (c, Cpp.directive.name);
		if (! isIgnore () && ! Cpp.parsingGlobalMacros)
			makeDefineTag (vStringValue (Cpp.directive.name));
	}
	Cpp.directive.state = DRCTV_NONE;
}

static void directivePragma (int c)
{
	if (isident1 (c))
	{
		readIdentifier (c, Cpp.directive.name);
		if (stringMatch (vStringValue (Cpp.directive.name), "weak"))
		{
			/* generate macro tag for weak name */
			do
			{
				c = fileGetc ();
			} while (c == SPACE);
			if (isident1 (c) && ! Cpp.parsingGlobalMacros)
			{
				readIdentifier (c, Cpp.directive.name);
				makeDefineTag (vStringValue (Cpp.directive.name));
			}
		}
	}
	Cpp.directive.state = DRCTV_NONE;
}

static boolean directiveIf (const int c)
{
	DebugStatement ( const boolean ignore0 = isIgnore (); )
	const boolean ignore = pushConditional ((boolean) (c != '0'));

	Cpp.directive.state = DRCTV_NONE;
	DebugStatement ( debugCppNest (TRUE, Cpp.directive.nestLevel);
	                 if (ignore != ignore0) debugCppIgnore (ignore); )

	return ignore;
}

static boolean directiveHash (const int c)
{
	boolean ignore = FALSE;
	char directive [MaxDirectiveName];
	DebugStatement ( const boolean ignore0 = isIgnore (); )

	readDirective (c, directive, MaxDirectiveName);
	if (stringMatch (directive, "define"))
		Cpp.directive.state = DRCTV_DEFINE;
	else if (stringMatch (directive, "undef"))
		Cpp.directive.state = DRCTV_UNDEF;
	else if (strncmp (directive, "if", (size_t) 2) == 0)
		Cpp.directive.state = DRCTV_IF;
	else if (stringMatch (directive, "elif")  ||
			stringMatch (directive, "else"))
	{
		ignore = setIgnore (isIgnoreBranch ());
		if (! ignore  &&  stringMatch (directive, "else"))
			chooseBranch ();
		Cpp.directive.state = DRCTV_NONE;
		DebugStatement ( if (ignore != ignore0) debugCppIgnore (ignore); )
	}
	else if (stringMatch (directive, "endif"))
	{
		DebugStatement ( debugCppNest (FALSE, Cpp.directive.nestLevel); )
		ignore = popConditional ();
		Cpp.directive.state = DRCTV_NONE;
		DebugStatement ( if (ignore != ignore0) debugCppIgnore (ignore); )
	}
	else if (stringMatch (directive, "pragma"))
		Cpp.directive.state = DRCTV_PRAGMA;
	else
		Cpp.directive.state = DRCTV_NONE;

	return ignore;
}

/*  Handles a pre-processor directive whose first character is given by "c".
 */
static boolean __unused__ handleDirective (const int c)
{
	boolean ignore = isIgnore ();

	switch (Cpp.directive.state)
	{
		case DRCTV_NONE:    ignore = isIgnore ();        break;
		case DRCTV_DEFINE:  directiveDefine (c);         break;
		case DRCTV_HASH:    ignore = directiveHash (c);  break;
		case DRCTV_IF:      ignore = directiveIf (c);    break;
		case DRCTV_PRAGMA:  directivePragma (c);         break;
		case DRCTV_UNDEF:   directiveDefine (c);         break;
	}
	return ignore;
}

/*  Called upon reading of a slash ('/') characters, determines whether a
 *  comment is encountered, and its type.
 */
static Comment isComment (void)
{
	Comment comment;
	const int next = fileGetc ();

	if (next == '*')
		comment = COMMENT_C;
	else if (next == '/')
		comment = COMMENT_CPLUS;
	else
	{
		fileUngetc (next);
		comment = COMMENT_NONE;
	}
	return comment;
}

/*  Skips over a C style comment. According to ANSI specification a comment
 *  is treated as white space, so we perform this substitution.
 */
int skipOverCComment (void)
{
	int c;
	disableCppPreprocess ();
	c = fileGetc ();

	while (c != EOF)
	{
		if (c != '*')
			c = fileGetc ();
		else
		{
			const int next = fileGetc ();

			if (next != '/')
				c = next;
			else
			{
				c = SPACE;  /* replace comment with space */
				break;
			}
		}
	}
	enableCppPreprocess ();
	return c;
}

/*  Skips over a C++ style comment.
 */
static int skipOverCplusComment (void)
{
	int c;

	disableCppPreprocess ();
	while ((c = fileGetc ()) != EOF)
	{
		if (c == BACKSLASH)
			fileGetc ();  /* throw away next character, too */
		else if (c == NEWLINE)
			break;
	}
	enableCppPreprocess ();
	return c;
}

/*  Skips to the end of a string, returning a special character to
 *  symbolically represent a generic string.
 */
static int skipToEndOfString (boolean ignoreBackslash, vString *const collector)
{
	int c;

	disableCppPreprocess ();
	while ((c = fileGetc ()) != EOF)
	{
		if ( collector )
		{
			vStringPut (collector, c);
		}

		if (c == BACKSLASH && ! ignoreBackslash)
		{
			c = fileGetc ();  /* throw away next character, too */
			if ( collector )
			{
				vStringPut (collector, c);
			}
		}
		else if (c == DOUBLE_QUOTE)
		{
			break;
		}
	}
	enableCppPreprocess ();
	return STRING_SYMBOL;  /* symbolic representation of string */
}

/*  Skips to the end of the three (possibly four) 'c' sequence, returning a
 *  special character to symbolically represent a generic character.
 *  Also detects Vera numbers that include a base specifier (ie. 'b1010).
 */
static int skipToEndOfChar (vString *const collector)
{
	int c;
	int count = 0, veraBase = '\0';

	disableCppPreprocess ();
	while ((c = fileGetc ()) != EOF)
	{
		if ( collector )
		{
			vStringPut (collector, c);
		}

	    ++count;
		if (c == BACKSLASH)
		{
			c = fileGetc ();  /* throw away next character, too */
			if ( collector )
			{
				vStringPut (collector, c);
			}
		}
		else if (c == SINGLE_QUOTE)
		{
			break;
		}
		else if (c == NEWLINE)
		{
			fileUngetc (c);
			break;
		}
		else if (count == 1  &&  strchr ("DHOB", toupper (c)) != NULL)
		{
			veraBase = c;
		}
		else if (veraBase != '\0'  &&  ! isalnum (c))
		{
			fileUngetc (c);
			break;
		}
	}
	enableCppPreprocess ();
	return CHAR_SYMBOL;  /* symbolic representation of character */
}

#if 0
/*  This function returns the next character, stripping out comments,
 *  C pre-processor directives, and the contents of single and double
 *  quoted strings. In short, strip anything which places a burden upon
 *  the tokenizer.
 */
extern int cppGetc (void)
{
	boolean directive = FALSE;
	boolean ignore = FALSE;
	int c;

	if (Cpp.ungetch != '\0')
	{
		c = Cpp.ungetch;
		Cpp.ungetch = Cpp.ungetch2;
		Cpp.ungetch2 = '\0';

		if (Cpp.enableCppGetcCache)
			vStringPut (Cpp.cppGetcCache, c);

		return c;  /* return here to avoid re-calling debugPutc () */
	}
	else do
	{
		c = fileGetc ();
process:
		switch (c)
		{
			case EOF:
				ignore    = FALSE;
				directive = FALSE;
				break;

			case TAB:
			case SPACE:
				break;  /* ignore most white space */

			case NEWLINE:
				if (directive  &&  ! ignore)
					directive = FALSE;
				Cpp.directive.accept = TRUE;
				break;

			case DOUBLE_QUOTE:
				Cpp.directive.accept = FALSE;
				c = skipToEndOfString (FALSE, NULL);
				break;

			case '#':
				if (Cpp.directive.accept)
				{
					directive = TRUE;
					Cpp.directive.state  = DRCTV_HASH;
					Cpp.directive.accept = FALSE;
				}
				break;

			case SINGLE_QUOTE:
				Cpp.directive.accept = FALSE;
				c = skipToEndOfChar (NULL);
				break;

			case '/':
			{
				const Comment comment = isComment ();

				if (comment == COMMENT_C)
					c = skipOverCComment ();
				else if (comment == COMMENT_CPLUS)
				{
					c = skipOverCplusComment ();
					if (c == NEWLINE)
						fileUngetc (c);
				}
				else
					Cpp.directive.accept = FALSE;
				break;
			}

			case BACKSLASH:
			{
				int next = fileGetc ();

				if (next == NEWLINE)
					continue;
				else if (next == '?')
					cppUngetc (next);
				else
					fileUngetc (next);
				break;
			}

			case '?':
			{
				int next = fileGetc ();
				if (next != '?')
					fileUngetc (next);
				else
				{
					next = fileGetc ();
					switch (next)
					{
						case '(':          c = '[';       break;
						case ')':          c = ']';       break;
						case '<':          c = '{';       break;
						case '>':          c = '}';       break;
						case '/':          c = BACKSLASH; goto process;
						case '!':          c = '|';       break;
						case SINGLE_QUOTE: c = '^';       break;
						case '-':          c = '~';       break;
						case '=':          c = '#';       goto process;
						default:
							fileUngetc (next);
							cppUngetc ('?');
							break;
					}
				}
			} break;

			default:
				if (c == '@' && Cpp.hasAtLiteralStrings)
				{
					int next = fileGetc ();
					if (next == DOUBLE_QUOTE)
					{
						Cpp.directive.accept = FALSE;
						c = skipToEndOfString (TRUE, NULL);
						break;
					}
				}
				Cpp.directive.accept = FALSE;
				if (directive)
					ignore = handleDirective (c);
				break;
		}
	} while (directive || ignore);

	DebugStatement ( debugPutc (DEBUG_CPP, c); )
	DebugStatement ( if (c == NEWLINE)
				debugPrintf (DEBUG_CPP, "%6ld: ", getInputLineNumber () + 1); )

	if (Cpp.enableCppGetcCache)
		vStringPut (Cpp.cppGetcCache, c);

	return c;
}
#else
static boolean handleDirective2 (const int c);

/*  This function returns the next character, stripping out comments,
 *  C pre-processor directives, and the contents of single and double
 *  quoted strings. In short, strip anything which places a burden upon
 *  the tokenizer.
 */
extern int cppGetc (void)
{
	boolean directive = FALSE; /* 期望预处理标识符，亦即 '#' 之后 */
	boolean cond = TRUE; /* 预处理状态 */
	int c;

	if (Cpp.ungetch != '\0')
	{
		c = Cpp.ungetch;
		Cpp.ungetch = Cpp.ungetch2;
		Cpp.ungetch2 = '\0';

		if (Cpp.enableCppGetcCache)
        {
			vStringPut (Cpp.cppGetcCache, c);
        }

		return c;  /* return here to avoid re-calling debugPutc () */
	}
	else do
	{
		c = fileGetc ();
process:
		switch (c)
		{
			case EOF:
				directive = FALSE;
				cond      = TRUE;
				break;

			case TAB:
			case SPACE:
				break;  /* ignore most white space */

			case NEWLINE:
				Cpp.directive.accept = TRUE; /* 开始了一个新行，可能有预处理 */
				break;

			case DOUBLE_QUOTE:
				Cpp.directive.accept = FALSE;
				c = skipToEndOfString (FALSE, NULL);
				break;

			case '#':
				if (Cpp.directive.accept)
				{
					directive = TRUE;
					Cpp.directive.state  = DRCTV_HASH;
					Cpp.directive.accept = FALSE;
				}
				break;

			case SINGLE_QUOTE:
				Cpp.directive.accept = FALSE; /* 遇到了单引号，
												 新行前都不可能是预处理 */
				c = skipToEndOfChar (NULL);
				break;

			case '/':
			{
				const Comment comment = isComment ();

				if (comment == COMMENT_C)
				{
					c = skipOverCComment ();
				}
				else if (comment == COMMENT_CPLUS)
				{
					c = skipOverCplusComment ();
					if (c == NEWLINE)
						fileUngetc (c);
				}
				else
				{
					Cpp.directive.accept = FALSE;
				}
				break;
			}

			case BACKSLASH:
			{
				int next = fileGetc ();

				if (next == NEWLINE)
				{
					continue;
				}
				else if (next == '?')
				{
					cppUngetc (next);
				}
				else
				{
					fileUngetc (next);
				}
				break;
			}

			case '?':
			{
				int next = fileGetc ();
				if (next != '?')
				{
					fileUngetc (next);
				}
				else
				{
					next = fileGetc ();
					switch (next)
					{
						case '(':          c = '[';       break;
						case ')':          c = ']';       break;
						case '<':          c = '{';       break;
						case '>':          c = '}';       break;
						case '/':          c = BACKSLASH; goto process;
						case '!':          c = '|';       break;
						case SINGLE_QUOTE: c = '^';       break;
						case '-':          c = '~';       break;
						case '=':          c = '#';       goto process;
						default:
							fileUngetc (next);
							cppUngetc ('?');
							break;
					}
				}
			} break;

			default:
				if (c == '@' && Cpp.hasAtLiteralStrings)
				{
					int next = fileGetc ();
					if (next == DOUBLE_QUOTE)
					{
						Cpp.directive.accept = FALSE;
						c = skipToEndOfString (TRUE, NULL);
						break;
					}
				}
				Cpp.directive.accept = FALSE;
				if (directive)
				{
                    directive = FALSE; /* 预处理行已经独立处理，这个变量直接重置 */
					cond = handleDirective2 (c); /* 函数里面肯定跳到预处理器的最后 */
					c = fileGetc ();
					goto process; /* 从头再来 */
				}
				break;
		}
	} while (directive || !cond);

	DebugStatement ( debugPutc (DEBUG_CPP, c); )
	DebugStatement ( if (c == NEWLINE)
				debugPrintf (DEBUG_CPP, "%6ld: ", getInputLineNumber () + 1); )

	if (Cpp.enableCppGetcCache)
    {
		vStringPut (Cpp.cppGetcCache, c);
    }

	return c;
}
#endif

extern void enableCppGetcCache (void)
{
	Cpp.enableCppGetcCache = TRUE;
}

extern void disableCppGetcCache (void)
{
	Cpp.enableCppGetcCache = FALSE;
}

extern void clearCppGetcCache (void)
{
	vStringClear (Cpp.cppGetcCache);
}

extern const vString * getCppGetcCache (void)
{
	return Cpp.cppGetcCache;
}

extern HashTable * getCppMacrosTable (void)
{
	return Cpp.macrosTable;
}

extern HashTable * getCppGlobalMacrosTable (void)
{
	return GlobalMacrosTable;
}

extern void freeGlobalMacrosTable (void)
{
	HashTable_Destroy (GlobalMacrosTable, (DestroyFunc)CMacroDelete);
	GlobalMacrosTable = NULL;
}

/* ========================================================================== */
/* added by fanhe on 2012-01-12 */
/* ========================================================================== */

/* 透明化注释获取字符，亦即把所有注释替换为空格 */
enum eCppStatesOfGet {
	NORMAL,
	STRING,
	CHAR,
	COMMENT,
	CPP_COMMENT
};

typedef struct sCppStateOfGet {
	int state;          /* 记录当前状态，字符串还是字符还是注释 */
	boolean backslash;  /* 上一个字符是否反斜杠，即当前字符是否被转义 */
} cppStateOfGet;

static void cppGetValidChar_Init(cppStateOfGet *pState)
{
	pState->state = NORMAL;
	pState->backslash = FALSE;
}

static int cppGetValidChar(cppStateOfGet *pState)
{
	int c = fileGetc();

	if ( c == '/' )
	{
		if ( pState->state == NORMAL )  /* 只有正常状态时才需要检测是否注释 */
		{
			const Comment comment = isComment();

			if (comment == COMMENT_C)
			{
				c = skipOverCComment(); /* always replace comment with space */
			}
			else if (comment == COMMENT_CPLUS)
			{
				c = skipOverCplusComment();
				if (c == NEWLINE)
				{
					fileUngetc(c);
				}
				c = SPACE; /* replace comment with space */
			}
			else
			{
				/* nothing to do */
			}
		}
	}

	/* 更新状态 */
	if ( c == '"' )
	{
		if ( !pState->backslash )
		{
			if ( pState->state == STRING )
			{
				pState->state = NORMAL;
			}
			else
			{
				pState->state = STRING;
			}
		}
	}
	else if ( c == '\'' )
	{
		if ( !pState->backslash )
		{
			if ( pState->state == CHAR )
			{
				pState->state = NORMAL;
			}
			else
			{
				pState->state = CHAR;
			}
		}
	}

	/* 更新转义状态 */
	if ( c == BACKSLASH )
	{
		pState->backslash = TRUE;
	}
	else
	{
		pState->backslash = FALSE;
	}

	return c;
}

int skipToNonCommentNonSpace(void)
{
	int c;
	cppStateOfGet st;
	cppGetValidChar_Init(&st);
	for ( ;; )
	{
		c = cppGetValidChar(&st);
		if ( isspace(c) )
		{
			/* nothing to do */
		}
		else
		{
			break;
		}
	}
	return c;
}

void skipToEndOfPP(vString *const collector)
{
	int c;
	cppStateOfGet st;
	cppGetValidChar_Init(&st);
	while ( c = cppGetValidChar(&st), (c != EOF && c != NEWLINE) )
	{
		if ( c == BACKSLASH )
		{
			int c2 = fileGetc();
			if ( c2 == NEWLINE )
			{
				/* 续行情况下，"\\\\n" 都跳过 */
				continue;
			}
			else
			{
				fileUngetc(c2);
			}
		}

		if ( collector )
		{
			vStringPut(collector, c);
		}
	}

	fileUngetc(c);
}

static int readPPDirective(vString *const PPDrctv)
{
	int c = fileGetc(); /* throw away '#' */

	vStringClear(PPDrctv);

	if ( c != '#' )
	{
		vStringPut(PPDrctv, c);
	}

	while ( c = fileGetc(), (c != EOF && isalpha(c)) )
	{
		vStringPut(PPDrctv, c);
	}
	fileUngetc(c);
	vStringTerminate(PPDrctv);

	return c;
}

static int readPPToken(int c, vString *const PPToken)
{
	vStringClear(PPToken);
	do
	{
		vStringPut(PPToken, c);
	} while (c = fileGetc (), (c != EOF  &&  isident (c)));
	fileUngetc (c);
	vStringTerminate(PPToken);

	return c;
}

static PPLineKind determinePPLineKind(vString *const PPDrctv)
{
	PPLineKind kind = PP_LK_INVALID;
	if ( stringMatch(vStringValue(PPDrctv), "define") )
	{
		kind = PP_LK_DEFINE;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "ifdef") )
	{
		kind = PP_LK_IFDEF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "ifndef") )
	{
		kind = PP_LK_IFNDEF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "if") )
	{
		kind = PP_LK_IF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "else") )
	{
		kind = PP_LK_ELSE;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "elif") )
	{
		kind = PP_LK_ELIF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "endif") )
	{
		kind = PP_LK_ENDIF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "undef") )
	{
		kind = PP_LK_UNDEF;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "include") )
	{
		kind = PP_LK_INCLUDE;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "line") )
	{
		kind = PP_LK_LINE;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "pragma") )
	{
		kind = PP_LK_PRAGMA;
	}
	else if ( stringMatch(vStringValue(PPDrctv), "error") )
	{
		kind = PP_LK_ERROR;
	}
	else
	{
		/* 还有其他的预处理？ */
		kind = PP_LK_OTHER;
	}

	return kind;
}

static void handlePPDefine(void);
static boolean handlePPIfdef(void);
static boolean handlePPIfndef(void);
static boolean handlePPIf(void);
static boolean handlePPElif(void);
static void handlePPUndef(void);

static boolean evalPPCondition(Stack *pCondStack)
{
	StackIter iter;
	void *pData;
	int result = 1;
	Stack_IterInit(&iter, pCondStack);
	while ( Stack_IterNext(&iter, &pData) )
	{
		result = result && (long)pData;	/* 这种数据结构就是搓，统一用 long */
	}
	return result ? TRUE : FALSE;
}

/* 计算预处理表达式 */
static boolean evalPPExpression(const vString *const expression);

/*  Handles a pre-processor directive whose first character is given by "c".
 *  added by fanhe
 */
/* 调用这个函数前，已经确保当前行是以 # 开始的了 */
/* NOTE: 不要私自吞掉标识预处理结束的换行符，应该交给上层以示预处理行结束 */
static boolean handleDirective2 (const int c)
{
	boolean cond; /* 最外层的预处理状态 */
	Stack *pCondStack;
	Stack *pCondInfoStack;
	PPLineKind curPPLineKind;
	vString *PPDrctv;
	int next;
	void *pCond = NULL;
	void *pInfo = NULL;

	fileUngetc(c);

	pCondStack = Cpp.condStack;
	pCondInfoStack = Cpp.condInfoStack;

	cond = evalPPCondition(pCondStack);
	Stack_Peek(pCondStack, &pCond);
    PPDrctv = vStringNew();

	next = readPPDirective(PPDrctv);

	curPPLineKind = determinePPLineKind(PPDrctv);
	vStringDelete(PPDrctv);

	switch ( curPPLineKind )
	{
		case PP_LK_DEFINE:
			if ( cond )
			{
				handlePPDefine();
			}
			break;

		case PP_LK_IFDEF:
			if ( cond )
			{
				cond = handlePPIfdef();
			}
			else
			{
				/* 上层为假时，可不用计算，直接当条件真，
				 * 因为这个结果已经不重要了 */
				cond = TRUE;
			}
			/* 有这个选项的话，恒真 */
			if ( Option.allCCBranch )
			{
				cond = TRUE;
			}
			Stack_Push(pCondStack, (void *)cond);
			cond = evalPPCondition(pCondStack);
			if ( cond )
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_HAD_CHOOSE_BRANCH);
			}
			else
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_NONE);
			}
			break;

		case PP_LK_IFNDEF:
			if ( cond )
			{
				cond = handlePPIfndef();
			}
			else
			{
				cond = TRUE;
			}
			/* 有这个选项的话，恒真 */
			if ( Option.allCCBranch )
			{
				cond = TRUE;
			}
			Stack_Push(pCondStack, (void *)cond);
			cond = evalPPCondition(pCondStack);
			if ( cond )
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_HAD_CHOOSE_BRANCH);
			}
			else
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_NONE);
			}
			break;

		case PP_LK_IF:
			/* 在 handlePPIf 内部控制，外部就无须控制了 */
			if ( cond )
			{
				cond = handlePPIf();
			}
			else
			{
				cond = TRUE;
			}
			Stack_Push(pCondStack, (void *)cond);
			cond = evalPPCondition(pCondStack);
			if ( cond )
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_HAD_CHOOSE_BRANCH);
			}
			else
			{
				Stack_Push(pCondInfoStack, (void *)PP_CI_NONE);
			}
			break;

		case PP_LK_ELSE:
			Stack_Pop(pCondStack, &pCond);
			Stack_Pop(pCondInfoStack, &pInfo);
			if ( ((PPCondInfo)pInfo) != PP_CI_HAD_CHOOSE_BRANCH )
			{
				/* 上面一直是假 */
				cond = TRUE;
				pInfo = (void *)PP_CI_HAD_CHOOSE_BRANCH;
			}
			else
			{
				cond = FALSE;
			}
			/* 有这个选项的话，恒真 */
			if ( Option.allCCBranch )
			{
				cond = TRUE;
			}
			Stack_Push(pCondStack, (void *)cond);
			Stack_Push(pCondInfoStack, pInfo);
            cond = evalPPCondition(pCondStack);
			skipToEndOfPP(NULL);
			break;

		case PP_LK_ELIF:
			Stack_Pop(pCondStack, &pCond);
			Stack_Pop(pCondInfoStack, &pInfo);
			if ( ((PPCondInfo)pInfo) != PP_CI_HAD_CHOOSE_BRANCH )
			{
				/* 上面一直是假 */
				cond = handlePPElif();
				if ( cond )
				{
					pInfo = (void *)PP_CI_HAD_CHOOSE_BRANCH;
				}
			}
			else
			{
				cond = FALSE;
			}
			/* 有这个选项的话，恒真 */
			if ( Option.allCCBranch )
			{
				cond = TRUE;
			}
			Stack_Push(pCondStack, (void *)cond);
			Stack_Push(pCondInfoStack, pInfo);
            cond = evalPPCondition(pCondStack);
			break;

		case PP_LK_ENDIF:
			Stack_Pop(pCondStack, &pCond);
			Stack_Pop(pCondInfoStack, &pInfo);
			cond = evalPPCondition(pCondStack);
			skipToEndOfPP(NULL);
			break;

		case PP_LK_UNDEF:
			if ( cond )
			{
				handlePPUndef();
			}
			break;

		case PP_LK_INCLUDE:	    /* #include */
		case PP_LK_LINE:        /* #line */
		case PP_LK_PRAGMA:      /* #pragma */
		case PP_LK_ERROR:       /* #error */
			skipToEndOfPP(NULL);

		default:
			break;
	}

	return cond;
}

static void handlePPDefine(void)
{
	int c;
	cppStateOfGet st;
	HashTable *macrosTable;
	CMacro *pCMacro;
	vString *PPToken = vStringNew();
	vString *PPTokenArgs = vStringNew(); /* 包括括号，原始文本 */
	vString *PPValue = vStringNew();

	if ( Cpp.parsingGlobalMacros )
	{
		macrosTable = GlobalMacrosTable;
	}
	else
	{
		macrosTable = Cpp.macrosTable;
	}

	c = skipToNonCommentNonSpace();
	if ( isident1(c) )
	{
		readPPToken(c, PPToken);
		if ( !Cpp.parsingGlobalMacros )
		{
			makeDefineTag(vStringValue(PPToken));
		}
	}
	else
	{
		/* #define 后面没有有效的标识符，语法错误，直接忽略 */
		skipToEndOfPP(NULL);
		goto end_label;
	}

	c = fileGetc();
	cppGetValidChar_Init(&st);
	if ( c == '(' )
	{
		vStringPut(PPTokenArgs, c);
		/* 类函数宏，需要添加宏参数信息 */
		while ((c = cppGetValidChar(&st)) != ')')
		{
			vStringPut(PPTokenArgs, c);
		}
		vStringPut(PPTokenArgs, c);
		StrCompactSpace(PPTokenArgs->buffer);
		vStringSetLength(PPTokenArgs);
	}
	else
	{
		fileUngetc(c);
	}

	skipToEndOfPP(PPValue); /* 已经把注释替换成空格 */
	StrStripSpaceMod(PPValue->buffer);
	vStringSetLength(PPValue);

	/* 宏里面的内容都没有注释 */
	pCMacro = CMacroNew(vStringValue(PPToken),
						vStringValue(PPTokenArgs),
						vStringValue(PPValue));
	AddMacro(macrosTable, pCMacro);

end_label:
	vStringDelete(PPToken);
	vStringDelete(PPTokenArgs);
	vStringDelete(PPValue);
}

static boolean handlePPIfdef(void)
{
	int c;
	boolean cond = FALSE;
	vString *PPToken = vStringNew();

	c = skipToNonCommentNonSpace();
	if ( isident1(c) )
	{
		if ( !Cpp.parsingGlobalMacros )
		{
			readPPToken(c, PPToken);
			/* 先查本文件的宏表，再查全局的宏表 */
			if ( GetMacro(Cpp.macrosTable, vStringValue(PPToken)) != NULL 
				 || GetMacro(GlobalMacrosTable, vStringValue(PPToken)) != NULL )
			{
				cond = TRUE;
			}
			else
			{
				cond = FALSE;
			}
		}
	}
	else
	{
		/* #ifdef 后面没有有效的标识符，语法错误，强制为假 */
		cond = FALSE;
	}

	skipToEndOfPP(NULL);
	vStringDelete(PPToken);

	return cond;
}

static boolean handlePPIfndef(void)
{
	boolean cond = !handlePPIfdef(); /* just reverse the result */
	return cond;
}

static boolean handlePPIf(void)
{
	boolean cond = TRUE;
	vString *expr = vStringNew();
	skipToEndOfPP(expr);
	StrStripSpaceMod(expr->buffer);
	vStringSetLength(expr);
	cond = evalPPExpression(expr);

	/* 有这个选项的话，恒真，但是 #if 0 的话，这个选项没效 */
	if ( strcmp(vStringValue(expr), "0") != 0 && Option.allCCBranch )
	{
		cond = TRUE;
	}

	vStringDelete(expr);
	return cond;
}

static boolean handlePPElif(void)
{
	boolean cond = TRUE;
	vString *expr = vStringNew();
	skipToEndOfPP(expr);
	StrStripSpaceMod(expr->buffer);
	vStringSetLength(expr);
	cond = evalPPExpression(expr);
	vStringDelete(expr);

	return cond;
}

static void handlePPUndef(void)
{
	int c;
	HashTable *macrosTable;
	vString *PPToken = vStringNew();

	if ( Cpp.parsingGlobalMacros )
	{
		macrosTable = GlobalMacrosTable;
	}
	else
	{
		macrosTable = Cpp.macrosTable;
	}

	c = skipToNonCommentNonSpace();
	if ( isident1(c) )
	{
		if ( !Cpp.parsingGlobalMacros )
		{
			readPPToken(c, PPToken);
			DelMacro(macrosTable, vStringValue(PPToken));
		}
	}
	else
	{
		/* #define 后面没有有效的标识符，语法错误，直接忽略 */
	}
	skipToEndOfPP(NULL);
	vStringDelete(PPToken);
}

/* 传进来的字符串为原始的表达式，这个函数负责展开表达式 */
static boolean evalPPExpression(const vString *const expression)
{
	int n;
	size_t start, end;
	boolean result, followDefined;
	char *expr, *psz;
	vString *str;
	char buf[BUFSIZ];

	str = vStringNew();
	result = TRUE;

	followDefined = FALSE;
	psz = vStringValue(expression);
    while ( StrSearchCId(psz, &start, &end) != NULL )
    {
		vStringNCatS(str, psz, start);
		if ( end - start >= sizeof(buf) )
		{
			/* 缓冲区不足，标识符长度太长了，强制返回 FALSE */
			vStringDelete(str);
			return FALSE;
		}

        strncpy(buf, psz + start, end - start);
        buf[end - start] = '\0';
		if ( strcmp(buf, "defined") == 0 )
		{
			followDefined = TRUE;
		}
		else
		{
			if ( followDefined )
			{
				if ( GetMacro(Cpp.macrosTable, buf) != NULL
					 || GetMacro(GlobalMacrosTable, buf) != NULL )
				{
					vStringPut(str, '1');
				}
				else
				{
					vStringPut(str, '0');
				}
			}
			else
			{
				CMacro *macro;
				if ( (macro = GetMacro(Cpp.macrosTable, buf)) != NULL
					 || (macro = GetMacro(GlobalMacrosTable, buf)) != NULL )
				{
					/*vStringCatS(str, macro->pszMacroValue);*/
					vStringCatS(str, buf); /* 第二次遍历的时候再展开 */
				}
				else
				{
					/* 符号没有定义时，强制为 0 */
					vStringPut(str, '0');
				}
			}

			followDefined = FALSE;
		}
        psz += end;
    }
	if ( psz[0] != '\0' ) /* 最后的那段 */
	{
		vStringCatS(str, psz);
	}

	/* NOTE: 也可能有没被展开的宏，
	 * 如某宏是类函数宏，但是在这个表达中没有跟随括号
	 * 反正有任何异常即当表达式为假即可 */
	if ( CMacro_PreProcessString(vStringValue(str),
								 Cpp.macrosTable, GlobalMacrosTable,
								 buf, sizeof(buf), NULL) >= 0
		 && !IsBufferOverflow(buf, sizeof(buf)) )
	{
		vStringClear(str);
		vStringCatS(str, buf);
	}

	expr = vStringValue(str);

	/* expr 是一个整数表达式，但可能有语法错误
	 * 有任何语法错误，应该直接返回 0 */
	n = calculateIntegerExpression(expr);

	result = n ? TRUE : FALSE;
	vStringDelete(str);

	return result;
}

static void ParseGlobalMacros(const char *file)
{
	if ( fileOpen(file, getFileLanguage("x.cpp")) )
	{
		while ( cppGetc() != EOF )
		{
			/* do nothing */
		}
		fileClose();
	}
}

/* ========================================================================== */
/* END */
/* ========================================================================== */

/* vi:set tabstop=4 shiftwidth=4 noet: */
