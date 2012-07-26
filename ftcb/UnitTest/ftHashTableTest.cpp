#include <gtest/gtest.h>

#include "ftHashTable.h"

TEST(ftHashTable, All)
{
    size_t i;
    HashTableIter iter;
    void *pData;
    HashTable *pTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    const char *pp[] = {
        "ABC",
        "abc",
        "xyz",
    };

    for ( i = 0; i < sizeof(pp) / sizeof(pp[0]); ++i )
    {
        HashTable_Insert(pTable, (void *)pp[i], HashString, NULL, NULL);
    }

    HashTable_IterInit(&iter, pTable);
    for ( i = 0; HashTable_IterNext(&iter, &pData); i++ )
    {
        EXPECT_TRUE(strcmp(pp[i], (char *)pData));
        //printf("%s\n", (char *)pData);
    }
    EXPECT_TRUE(i == 3);

    EXPECT_TRUE(HashTable_Pop(pTable, (void *)pp[0], HashString, (CompareFunc)strcmp, &pData));
    EXPECT_TRUE(HashTable_Pop(pTable, (void *)pp[1], HashString, (CompareFunc)strcmp, &pData));
    EXPECT_TRUE(HashTable_Pop(pTable, (void *)pp[2], HashString, (CompareFunc)strcmp, &pData));
    EXPECT_FALSE(HashTable_Pop(pTable, (void *)"bc", HashString, (CompareFunc)strcmp, &pData));
    EXPECT_FALSE(HashTable_Pop(pTable, (void *)pp[0], HashString, (CompareFunc)strcmp, &pData));
    EXPECT_FALSE(HashTable_Pop(pTable, (void *)pp[1], HashString, (CompareFunc)strcmp, &pData));
    EXPECT_FALSE(HashTable_Pop(pTable, (void *)pp[2], HashString, (CompareFunc)strcmp, &pData));

    for ( i = 0; i < sizeof(pp) / sizeof(pp[0]); ++i )
    {
        HashTable_Insert(pTable, (void *)pp[i], HashString, NULL, NULL);
    }

    EXPECT_TRUE(HashTable_Remove(pTable, (void *)"abc", HashString,
                                 (CompareFunc)strcmp, NULL));
    EXPECT_FALSE(HashTable_Remove(pTable, (void *)"bc", HashString,
                                  (CompareFunc)strcmp, NULL));

    HashTable_IterInit(&iter, pTable);
    for ( i = 0; HashTable_IterNext(&iter, &pData); i++ )
    {
        EXPECT_TRUE(strcmp(pp[i], (char *)pData));
        //printf("%s\n", (char *)pData);
    }
    EXPECT_TRUE(i == 2);

    HashTable_Destroy(pTable, NULL);
    pTable = NULL;
}

