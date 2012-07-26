#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ftString.h"


#define assertTrue(x)\
{\
	if ( !(x) )\
	{\
		printf("%s:%d, assert failed:\n\t%s\n", __FILE__, __LINE__, #x);\
	}\
}

#define assertFalse(x) assertTrue(!(x))


void testStrSplit()
{
    char szBuf[BUFSIZ];
    char szMinBuf[1];
    StrIter iter;
    const char *psz1 = " aB\t Cd ";

    StrIterSplitBySpaceInit(&iter, psz1);
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "aB"));
    StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "Cd"));
    assertFalse(StrIterSplitBySpaceNext(&iter, szBuf, sizeof(szBuf)));

    StrIterSplitInit(&iter, psz1);
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

    StrReplace2(psz1, "aB", "XXX", STR_MAX_32BIT_INT, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, " XXX\t Cd "));
    StrReplace2(psz1, " ", "", STR_MAX_32BIT_INT, szBuf, sizeof(szBuf));
    assertTrue(StrIsEqual(szBuf, "aB\tCd"));

    /* ===== 溢出测试 START ===== */
    StrReplace2(psz1, " aB\t Cd ", "", STR_MAX_32BIT_INT, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == '\0');
    StrReplace2(psz1, " aB\t Cd ", " ", STR_MAX_32BIT_INT, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    StrReplace2(psz1, " ", "", STR_MAX_32BIT_INT, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == 'a');
    StrReplace2(psz1, "", "xx", STR_MAX_32BIT_INT, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    StrReplace2(psz1, "xx", "xxx", STR_MAX_32BIT_INT, szMinBuf, sizeof(szMinBuf));
    assertTrue(szMinBuf[0] == ' ');
    /* ===== 溢出测试 END ===== */

    printf("%s() done.\n", __func__);
}


int main(int argc, char **argv)
{
    testStrSplit();

    return 0;


    char *pszStr;
    char *pszRpl;
    int i;
    char **ppStrArray;
    char szTmp[BUFSIZ];
    StrIter strIter;
    char szBuf[] = "hello world \n snelgj elgjle nlej\r\n lene lekj\n\r ljln lkjelk nelrkje\\\n lw nrlrekwj l\\\njrw lewnlejrl jwelj  r ";

    printf("\"%s\" - \"%s\" = %d\n", "abc", "AbC", StrCmpIC("abc", "AbC"));
    printf("\"%s\" - \"%s\" = %d\n", "abc", "AbC ", StrCmpIC("abc", "AbC "));
    printf("\"%s\" - \"%s\" = %d\n", "abc ", "AbC", StrCmpIC("abc ", "AbC"));

    /*StrSliceMod(szBuf, 0, -2);*/
    StrUpperMod(szBuf);
    puts(szBuf);
    StrLowerMod(szBuf);
    puts(szBuf);

    puts(szBuf);
    puts("==========");
    pszStr = StrDup("abc senlgje abc AGEGE abcde engk");
    puts(pszStr);
    pszRpl = StrReplace(pszStr, "abc", "", 100);
    puts(pszRpl);
    free(pszRpl);
    pszRpl = StrReplace(pszStr, "abc", "XXX", 0);
    puts(pszRpl);
    free(pszRpl);
    pszRpl = StrReplace(pszStr, "abc", "XXX", 1);
    puts(pszRpl);
    free(pszRpl);
    pszRpl = StrReplace(pszStr, "abc", "XXX", 2);
    puts(pszRpl);
    free(pszRpl);
    pszRpl = StrReplace(pszStr, "abc", "XXX", 3);
    puts(pszRpl);
    free(pszRpl);
    free(pszStr);

    puts("========== StrIterLine ===========");
    StrIterLineInit(&strIter, szBuf);
    while ( StrIterLineNext(&strIter, False, szTmp, sizeof(szTmp)) )
    {
        puts(szTmp);
    }

    puts("========== StrIterSerialLine ==========");
    StrIterSerialLineInit(&strIter, szBuf);
    while ( StrIterSerialLineNext(&strIter, szTmp, sizeof(szTmp)) )
    {
        puts(szTmp);
    }
    puts("==========");

    pszStr = StrSlice(szBuf, 0, StrLen(szBuf));
    puts(pszStr);
    free(pszStr);

    pszStr = StrSlice(szBuf, 0, -2);
    puts(pszStr);
    free(pszStr);

    pszStr = StrSlice(szBuf, 0, 3);
    puts(pszStr);
    free(pszStr);

    puts("==========");
    ppStrArray = StrSplitAll(szBuf, " ");
    for ( i = 0; ppStrArray[i] != NULL; i++ )
    {
        puts(ppStrArray[i]);
    }
    StrArrayFree(ppStrArray);

    puts("==========");
    ppStrArray = StrSplitBySpace(szBuf);
    for ( i = 0; ppStrArray[i] != NULL; i++ )
    {
        puts(ppStrArray[i]);
    }
    StrArrayFree(ppStrArray);


    puts("==========");
    printf("hello world\n");
    return 0;
}
