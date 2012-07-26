#include <gtest/gtest.h>

#include "ftCMacro.h"

TEST(ftCMacro, CMacro_ExpandCMacroValue_1)
{
    HashTable *pCMacroTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    HashTable *pGlobalTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    HashTable *pExceptTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    char szBuf[256] = {'\0'};

    CMacro m1, m2, m3;

    m1.pszMacroID = "A";
    m1.pszMacroValue = "A B B A";
    m1.bIsFuncLike = False;
    m1.uArgc = 0;
    m1.ppszArgv = NULL;

    m2.pszMacroID = "B";
    m2.pszMacroValue = "B C B";
    m2.bIsFuncLike = False;
    m2.uArgc = 0;
    m2.ppszArgv = NULL;

    m3.pszMacroID = "C";
    m3.pszMacroValue = "C A C";
    m3.bIsFuncLike = False;
    m3.uArgc = 0;
    m3.ppszArgv = NULL;

    HashTable_Insert(pCMacroTable, (void *)&m1, CMacro_Hash, CMacro_Compare,
                     NULL);
    HashTable_Insert(pCMacroTable, (void *)&m2, CMacro_Hash, CMacro_Compare,
                     NULL);
    HashTable_Insert(pCMacroTable, (void *)&m3, CMacro_Hash, CMacro_Compare,
                     NULL);

    CMacro_ExpandCMacroValue(&m1, NULL, pCMacroTable, pGlobalTable, pExceptTable,
                             szBuf, sizeof(szBuf));
	EXPECT_STREQ("A B C A C B B C A C B A", szBuf);
    //puts(szBuf);
    CMacro_ExpandCMacroValue(&m2, NULL, pCMacroTable, pGlobalTable, pExceptTable,
                             szBuf, sizeof(szBuf));
	EXPECT_STREQ("B C A B B A C B", szBuf);
    //puts(szBuf);
    CMacro_ExpandCMacroValue(&m3, NULL, pCMacroTable, pGlobalTable, pExceptTable,
                             szBuf, sizeof(szBuf));
	EXPECT_STREQ("C A B C B B C B A C", szBuf);
    //puts(szBuf);

	HashTable_Destroy(pCMacroTable, NULL);
	HashTable_Destroy(pGlobalTable, NULL);
	HashTable_Destroy(pExceptTable, NULL);
}


TEST(ftCMacro, CMacro_ExpandCMacroValue_2)
{
    HashTable *pCMacroTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    HashTable *pGlobalTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    HashTable *pExceptTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    char szBuf[256] = {'\0'};

    CMacro m1, m2, m3, m4;

    m1.pszMacroID = "X";
    m1.pszMacroValue = "x";
    m1.bIsFuncLike = False;
    m1.uArgc = 0;
    m1.ppszArgv = NULL;

    m2.pszMacroID = "Y";
    m2.pszMacroValue = "y";
    m2.bIsFuncLike = False;
    m2.uArgc = 0;
    m2.ppszArgv = NULL;

	const char *ppszArgv3[] = {"x", "y"};
    m3.pszMacroID = "F1";
    m3.pszMacroValue = "x##y, x, y";
    m3.bIsFuncLike = True;
    m3.uArgc = 2;
    m3.ppszArgv = (char **)ppszArgv3;

	const char *ppszArgv4[] = {"x", "y"};
	m4.pszMacroID = "F2";
	m4.pszMacroValue = "F1  (Y, X), x, y, F2(x, X)";
    m4.bIsFuncLike = True;
    m4.uArgc = 2;
    m4.ppszArgv = (char **)ppszArgv4;

    HashTable_Insert(pCMacroTable, (void *)&m1, CMacro_Hash, CMacro_Compare,
                     NULL);
    HashTable_Insert(pCMacroTable, (void *)&m2, CMacro_Hash, CMacro_Compare,
                     NULL);
    HashTable_Insert(pCMacroTable, (void *)&m3, CMacro_Hash, CMacro_Compare,
                     NULL);
    HashTable_Insert(pCMacroTable, (void *)&m4, CMacro_Hash, CMacro_Compare,
                     NULL);

	const char *ppszRealArgv[] = {"30", "40"};
    CMacro_ExpandCMacroValue(&m4, ppszRealArgv, pCMacroTable, pGlobalTable, pExceptTable,
                             szBuf, sizeof(szBuf));
	EXPECT_STREQ("YX, y, x, 30, 40, F2(30, x)", szBuf);
	//puts(szBuf);

	HashTable_Destroy(pCMacroTable, NULL);
	HashTable_Destroy(pGlobalTable, NULL);
	HashTable_Destroy(pExceptTable, NULL);
}

