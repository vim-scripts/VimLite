#include <gtest/gtest.h>

#include "ftString.h"
#include "ftCMacro.h"


#define assertTrue(x)\
{\
	if ( !(x) )\
	{\
		printf("%s:%d, assert failed:\n\t%s\n", __FILE__, __LINE__, #x);\
	}\
}

#define assertFalse(x) assertTrue(!(x))


// 老代码，直接移植
void testStrSplit()
{
    char szBuf[BUFSIZ];
    char szMinBuf[1];
    StrIter iter;
    const char *psz1 = " aB\t Cd ";

    StrIterSplitBySpaceInit(&iter, psz1, STR_MAX_SPLIT);
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "aB"));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "Cd"));
    assertFalse(StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf)));

    StrIterSplitInit(&iter, psz1, STR_MAX_SPLIT);
    StrIterSplitNext(&iter, "aB", szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, " "));
    StrIterSplitNext(&iter, "aB", szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "\t Cd "));
    assertFalse(StrIterSplitNext(&iter, "aB", szBuf, sizeof(szBuf)));

    strcpy(szBuf, psz1);
    StrSwapCaseMod(szBuf);
    assertTrue(StrIsEqual(szBuf, " Ab\t cD "));

    strcpy(szBuf, psz1);
    StrUpperMod(szBuf);
    assertTrue(StrIsEqual(szBuf, " AB\t CD "));

    strcpy(szBuf, psz1);
    StrLowerMod(szBuf);
    assertTrue(StrIsEqual(szBuf, " ab\t cd "));

    StrReplace2(psz1, "aB", "XXX", STR_MAX_REPLACE, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, " XXX\t Cd "));
    StrReplace2(psz1, " ", "", STR_MAX_REPLACE, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "aB\tCd"));

    /* ===== 溢出测试 START ===== */
    StrReplace2(psz1, " aB\t Cd ", "", STR_MAX_REPLACE,
                szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == '\0');
    StrReplace2(psz1, " aB\t Cd ", " ", STR_MAX_REPLACE,
                szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    StrReplace2(psz1, " ", "", STR_MAX_REPLACE, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == 'a');
    StrReplace2(psz1, "", "xx", STR_MAX_REPLACE, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    StrReplace2(psz1, "xx", "xxx", STR_MAX_REPLACE, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    /* ===== 溢出测试 END ===== */

}


TEST(ftStringTest, StrSplit)
{
    int i;
    char szBuf[BUFSIZ];
    char szBuf2[BUFSIZ];
    StrIter iter;
    const char *psz = "\t# define Ma_01  xyz abc";
    testStrSplit();

    strcpy(szBuf, psz);

    StrLStripMod(szBuf, " \t#");
    strcpy(szBuf2, szBuf);
    StrIterSplitBySpaceInit(&iter, szBuf2, 2);
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "define"));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "Ma_01"));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "xyz abc"));
    EXPECT_FALSE(StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf)));

    const char *ppszResult[] = {"#", "define", "Ma_01", "xyz", "abc"};
    StrIterSplitBySpaceInit(&iter, psz, STR_MAX_SPLIT);
    i = 0;
    while ( StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf)) )
    {
        //puts(szBuf);
        EXPECT_TRUE(StrIsEqual(szBuf, ppszResult[i]));
        i++;
    }

    StrIterSplitBySpaceInit(&iter, psz, 2);
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, ppszResult[0]));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, ppszResult[1]));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "Ma_01  xyz abc"));
    EXPECT_FALSE(StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf)));

    StrIterSplitInit(&iter, psz, 4);
    StrIterSplitNext(&iter, " ", szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "\t#"));
    StrIterSplitNext(&iter, " ", szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "define"));
    StrIterSplitNext(&iter, " ", szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "Ma_01"));
    StrIterSplitNext(&iter, " ", szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, ""));
    StrIterSplitNext(&iter, " ", szBuf, sizeof(szBuf));
    EXPECT_TRUE(StrIsEqual(szBuf, "xyz abc"));

    strcpy(szBuf, "  abc    bcd  ce   ");
    StrCharsReplaceMod(szBuf, " \t", ' ');
    EXPECT_TRUE(StrIsEqual(szBuf, " abc bcd ce "));

    strcpy(szBuf, "\t ");
    StrCharsReplaceMod(szBuf, " \t", 'c');
    EXPECT_TRUE(StrIsEqual(szBuf, "c"));
}


TEST(ftStringTest, StrLRStrip)
{
    ASSERT_TRUE(1);
}


TEST(ftStringTest, SplitMacroArgs)
{
#if 0
	char szBuf[BUFSIZ];
	const char *psz = "xx, yy, zz";
	StrIter iter;

	StrIterSplitInit(&iter, psz, STR_MAX_SPLIT);
	while ( StrIterSplitNext(&iter, ",", szBuf, sizeof(szBuf)) )
	{
		StrStripSpaceMod(szBuf);
		puts(szBuf);
	}
#endif
}


TEST(ftStringTest, StrIterSplitCCode)
{
    char c;
    size_t uStart, uEnd, i;
    char szBuf[BUFSIZ];
    const char *pszCode = " AAA  \"##\"  X ## /* ## \" ' */ x1 # x1 ## x2 '##' // ##  Y '##'";
    const char *psz;
	const char *ppszSplitCCodeRes[] = {
		" AAA  \"##\"  X ",
		" /* ## \" ' */ x1 # x1 ",
		" x2 '##' // ##  Y '##'",
	};
	const char *pszIterCCharRes = " AAA  \"##\"  X ##   x1 # x1 ## x2 '##'  ";
    /* "AAA \"##\" X##x1#x1##x2Y '##'" */
    StrIter iter;
	i = 0;
    StrIterSplitCCodeInit(&iter, pszCode, STR_MAX_SPLIT);
    while ( StrIterSplitCCodeNext(&iter, "##", szBuf, sizeof(szBuf)) )
    {
        //puts(szBuf);
		EXPECT_TRUE(StrIsEqual(szBuf, ppszSplitCCodeRes[i]));
		i++;
    }
	EXPECT_TRUE(i == 3);

    //puts("==========");
	i = 0;
    StrIterCCharInit(&iter, pszCode);
    while ( StrIterCCharNext(&iter, &c) )
    {
        //printf("%c\n", c);
		EXPECT_TRUE(c == pszIterCCharRes[i]);
		i++;
    }
	EXPECT_TRUE( i == strlen(pszIterCCharRes));

    //puts("==========");
    psz = pszCode;
	const char *ppszRes[] = {
		"AAA",
		"X",
		"x1",
		"x1",
		"x2",
	};
	i = 0;
    while ( StrSearchCId(psz, &uStart, &uEnd) )
    {
        strncpy(szBuf, psz + uStart, uEnd - uStart);
        szBuf[uEnd - uStart] = '\0';
        psz += uEnd;
        //puts(szBuf);
		EXPECT_TRUE(StrIsEqual(szBuf, ppszRes[i]));
		i++;
    }
	EXPECT_EQ(5, i);

    const char *psz2 = "x1LL 234 1X LL 'xy.# ";    // LL xy
    psz = psz2;
	i = 0;
    while ( StrSearchCId(psz, &uStart, &uEnd) )
    {
        strncpy(szBuf, psz + uStart, uEnd - uStart);
        szBuf[uEnd - uStart] = '\0';
        psz += uEnd;
        puts(szBuf);
		i++;
    }

}


TEST(ftStringTest, MacroReplace)
{
    StrIter iter;
    char szBuf[BUFSIZ] = {'\0'};
	char szRes[BUFSIZ] = {'\0'};

	/* x1 -> "XX", x2 - > "YY" */
	const char *ppMacroArgv[] = {"x1", "x2"};
	const char *ppRealArgv[] = {"XX", "YY"};
    const char *pszCode = "  AAA  \"##\"  X ## x1 # x1 Y ## x2 ##  Y '##'  ";
	const char *pszRes = "AAA \"##\" XXX \"XX\" YYYY '##'";
	//StrExpandCMacroValue(pszCode, szBuf, sizeof(szBuf), 2, ppMacroArgv, ppRealArgv);
	CMacro_ExpandCMacroValueArgs(pszCode, 2, ppMacroArgv, ppRealArgv, szBuf, sizeof(szBuf));
	EXPECT_TRUE(StrIsEqual(szBuf, pszRes));

    StrIterSplitCCodeInit(&iter, pszCode, STR_MAX_SPLIT);
    while ( StrIterSplitCCodeNext(&iter, "##", szBuf, sizeof(szBuf)) )
    {
        //puts(szBuf);
    }
}


TEST(ftStringTest, SkipToXXX)
{
	const char *p1 = "\"aa\\\"bb\\\"cc\"ok";
	const char *p2 = "'aa\\'bbcc'ok";
	const char *p3 = "( \")(aa\\\"bb\\\"cc\"ok ( ')(aa\\'bbcc'ok )  )ok";
	const char *p4 = " \n ok";
	EXPECT_STREQ("ok", StrSkipCString(p1 + 1));
	EXPECT_STREQ("ok", StrSkipCChar(p2 + 1));
	EXPECT_STREQ("ok", StrSkipCMatch(p3 + 1, "()"));
	EXPECT_STREQ("ok", StrSkipToNonSpace(p4));
}


TEST(ftStringTest, PreProcessString)
{
    StrIter iter;
    char szBuf[BUFSIZ] = {'\0'};
	char szRes[BUFSIZ] = {'\0'};
    size_t uStart, uEnd;
    const char *psz = NULL;
	char *pszContinue;

    const char *pszCode = " _XXX  (XX, YY) template<typename T> class Cls : _STD basic_string<char> {} ";

    // #define _STD std::

    HashTable *pCMacroTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    CMacro m;
    m.bIsFuncLike = False;
    m.pszMacroID = "_STD";
    m.pszMacroValue = "std::";
    m.uArgc = 0;
    m.ppszArgv = NULL;

	CMacro m2;
	m2.bIsFuncLike = True;
	m2.pszMacroID = "_XXX";
	m2.pszMacroValue = "  AAA  \"##\"  X ## x1 # x1 Y ## x2 ##  Y '##'  ";
	m2.uArgc = 2;
	m2.ppszArgv = (char **)malloc(sizeof(char *) * m2.uArgc);
	m2.ppszArgv[0] = "x1";
	m2.ppszArgv[1] = "x2";

    HashTable_Insert(pCMacroTable, (void *)&m, CMacro_Hash, NULL, NULL);
    HashTable_Insert(pCMacroTable, (void *)&m2, CMacro_Hash, NULL, NULL);

    CMacro_PreProcessString(pszCode, pCMacroTable, NULL, szRes, sizeof(szRes), &pszContinue);
    puts(pszCode);
    puts(szRes);

	pszCode = "  AAA  \"##\"  X ## x1 # x1 Y ## x2 ##  Y '##'  ";

#if 0
    psz = pszCode;
    while ( StrSearchCId(psz, &uStart, &uEnd) )
    {
        strncpy(szBuf, psz + uStart, uEnd - uStart);
        szBuf[uEnd - uStart] = '\0';
        psz += uEnd;
        puts(szBuf);
    }
#endif

	free(m2.ppszArgv);
	HashTable_Destroy(pCMacroTable, NULL);
}


TEST(ftStringTest, StrCCharsReplaceMod)
{
	char psz[] = "  \" \\\" \"    ' \\\' '   ";
	StrCCharsReplaceMod(psz, " ", 'x');
	EXPECT_TRUE(StrIsEqual(psz, "x\" \\\" \"x' \\\' 'x"));
}

TEST(ftStringTest, StrEscapeChars)
{
	const char *psz = " abc ' \" e \" \\ ";
	const char *pszRes = " abc \\\' \\\" e \\\" \\\\ ";
	char szBuf[BUFSIZ];
	//puts(psz);
	StrEscapeChars(psz, "'\"\\", szBuf, sizeof(szBuf));
	EXPECT_TRUE(StrIsEqual(szBuf, pszRes));
	//puts(szBuf);
}

TEST(ftStringTest, StrStripCAllComment)
{
	char psz[] = "x, y /*  */, //  \n z /*  */;";
	//puts(psz);
	StrStripCAllComment(psz);
	EXPECT_STREQ("x, y  ,  \n z  ;", psz);
	//puts(psz);
}
