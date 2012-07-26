/*
 * Copyright (c) 2006-2008
 * Author: Weiming Zhou
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  
 */

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "ftHashTable.h"

#ifdef _WIN32
# pragma warning(disable : 4996)
#endif

/** 哈希表的创建函数

    @param  size_t uBucketSize - 索引的大小    
    @return HashTable * - 成功返回哈希表的指针，失败返回NULL    
*/
HashTable * HashTable_Create(size_t uBucketSize)
{
    HashTable *pTable;

    if ( uBucketSize == 0 )
    {
        return NULL;
    }
    
    pTable = (HashTable *)malloc(sizeof(HashTable));
    if ( pTable == NULL )
    {
        return NULL;
    }

    pTable->uCount = 0;
    pTable->uBucketSize = uBucketSize;

    pTable->ppBucket = (HTSingleNode **)
        malloc(uBucketSize * sizeof(HTSingleNode *));

    if (pTable->ppBucket == NULL)
    {
        free(pTable);
        return NULL;
    }

    memset(pTable->ppBucket, 0, uBucketSize * sizeof(HTSingleNode *));

    return pTable;
}


/** 哈希表的释放函数

    @param  HashTable *pTable - 哈希表指针  
    @param  DestroyFunc destroy_func - 数据释放函数，为NULL时只释放节点辅助
                                      空间，不释放数据  
    @return void - 无   
*/
void HashTable_Destroy(HashTable *pTable, 
                       DestroyFunc destroy_func)
{
    HTSingleNode **ppBucket;
    HTSingleNode  *pNode;
    HTSingleNode  *pFreeNode;
    size_t i;

    if ( pTable == NULL )
    {
        return;
    }
    ppBucket = pTable->ppBucket;
    for ( i = 0; i < pTable->uBucketSize; i++ ) 
    {
        pNode = ppBucket[i];
        while ( pNode != NULL )
        {
            if ( destroy_func != NULL )
            {
                (*destroy_func)(pNode->pData);
            }
            pFreeNode = pNode;
            pNode = pNode->pNext;
            free(pFreeNode);
        }
    }
    free(ppBucket);
    free(pTable);
}


void HashTable_Clear(HashTable *pTable, DestroyFunc destroy_func)
{
    HTSingleNode **ppBucket;
    HTSingleNode  *pNode;
    HTSingleNode  *pFreeNode;
    size_t i;

    ppBucket = pTable->ppBucket;
    for ( i = 0; i < pTable->uBucketSize; i++ ) 
    {
        pNode = ppBucket[i];
        while ( pNode != NULL )
        {
            if ( destroy_func != NULL )
            {
                (*destroy_func)(pNode->pData);
            }
            pFreeNode = pNode;
            pNode = pNode->pNext;
            free(pFreeNode);
        }
        ppBucket[i] = NULL;
    }
    pTable->uCount = 0;
}


Bool HashTable_Insert(HashTable *pTable, void *pData,
                      HashFunc hash_func, CompareFunc compare_func,
                      DestroyFunc destroy_func)
{
    size_t uIndex;
    HTSingleNode *pNode;
    HTSingleNode *pNewNode;

    if ( compare_func != NULL )
    {
        /* 只检查一次，如果有多个重复的项目，自己负责 */
        if ( HashTable_Find(pTable, pData, hash_func, compare_func, NULL) )
        {
            HashTable_Remove(pTable, pData, hash_func, compare_func,
                             destroy_func);
        }
    }

    uIndex = (*hash_func)(pData, pTable->uBucketSize);
    pNode = (pTable->ppBucket)[uIndex];

    pNewNode = (HTSingleNode *)malloc(sizeof(HTSingleNode));
    if ( pNewNode == NULL )
    {
        return False;
    }
    
    /* 将新节点插入到链表的头部 */
    pNewNode->pData = pData;
    pNewNode->pNext = pNode;

    (pTable->ppBucket)[uIndex] = pNewNode;
    pTable->uCount += 1;

    return True;
}


Bool HashTable_Find(const HashTable *pTable,
                    void *pData,
                    HashFunc hash_func,
                    CompareFunc compare_func,
                    void **ppOutData)
{
    size_t uIndex;
    HTSingleNode *pNode;

    uIndex = (*hash_func)(pData, pTable->uBucketSize);
    pNode = (pTable->ppBucket)[uIndex];
    
    /* 在 HashTable 中进行查找 */
    while ( pNode != NULL )
    {
        if ( (*compare_func)(pNode->pData, pData) == 0 )
        {
            /* 已经找到了关键词，返回 */
            if ( ppOutData != NULL )
            {
                *ppOutData = pNode->pData;
            }
            return True;
        }
        pNode = pNode->pNext;
    }

    return False;
}


Bool HashTable_Pop(HashTable *pTable, void *pData, HashFunc hash_func,
                   CompareFunc compare_func, void **ppOutData)
{
    size_t uIndex;
    HTSingleNode *pNode;
    HTSingleNode *pPrevNode;

    uIndex = (*hash_func)(pData, pTable->uBucketSize);
    pNode = (pTable->ppBucket)[uIndex];
    pPrevNode = pNode;

    /* 从哈希表中查找 */
    while ( pNode != NULL )
    {
        if ( (*compare_func)(pNode->pData, pData) == 0 )
        {
            if ( pPrevNode == pNode )
            {
                pTable->ppBucket[uIndex] = pNode->pNext;
            }
            else
            {
                pPrevNode->pNext = pNode->pNext;
            }

            /* 弹出对应节点 */
            if ( ppOutData != NULL )
            {
                *ppOutData = pNode->pData;
            }
            free(pNode);

            pTable->uCount -= 1;

            return True;
        }

        pPrevNode = pNode;
        pNode = pNode->pNext;
    }

    return False;
}


Bool HashTable_Remove(HashTable *pTable, 
                      void *pData, 
                      HashFunc hash_func,
                      CompareFunc compare_func,
                      DestroyFunc destroy_func)

{
    void *pOutData;
    if ( HashTable_Pop(pTable, pData, hash_func, compare_func, &pOutData) )
    {
        if ( destroy_func != NULL )
        {
            (*destroy_func)(pOutData);
        }
        return True;
    }
    else
    {
        return False;
    }
}

/** 获取哈希表中的实际节点个数

    @param  HashTable *pTable - 哈希表指针  
    @return size_t - 返回哈希表中的实际节点数量 
*/
size_t HashTable_GetCount(const HashTable *pTable)
{
    return pTable->uCount;
}

#if 0 /* TODO */
HashTable * HashTable_Copy(const HashTable *pTable, CopyFunc copy_func)
{
    size_t i;
    HTSingleNode *pNode;
    HashTable *pCopyTable = HashTable_Create(pTable->uBucketSize);
    if ( pCopyTable == NULL )
    {
        return NULL;
    }

    for ( i = 0; i < pTable->uBucketSize; i++ )
    {
        pNode = ppBucket[i];
        while ( pNode != NULL )
        {
            HTSingleNode *pNewNode = (HTSingleNode *)malloc(sizeof(HTSingleNode));
            if ( pNewNode == NULL )
            {
                HashTable_Destroy(pCopyTable);
                return NULL;
            }
            pNode = pNode->pNext;
        }
    }

    return pCopyTable;
}
#endif

void HashTable_IterInit(HashTableIter *pIter, const HashTable *pTable)
{
    pIter->uCurBucketIndex = 0;
    pIter->pCurItem = pTable->ppBucket[0];
    pIter->pTable = pTable;
}


Bool HashTable_IterNext(HashTableIter *pIter, void **ppOutData)
{
    while ( pIter->pCurItem == NULL )
    {
        pIter->uCurBucketIndex += 1;
        if ( pIter->uCurBucketIndex >= pIter->pTable->uBucketSize )
        {
            return False;
        }
        pIter->pCurItem = pIter->pTable->ppBucket[pIter->uCurBucketIndex];
    }

    if ( ppOutData != NULL )
    {
        *ppOutData = pIter->pCurItem->pData;
    }

    pIter->pCurItem = pIter->pCurItem->pNext;

    return True;
}


/* ========================================================================== */
/* some hash functions */
/* ========================================================================== */

size_t HashString(void *pKey, size_t uBucketSize)
{
    unsigned long value = 0;
    const unsigned char *p;

    char *string = (char *)pKey;

    /*  We combine the various words of the multiword key using the method
     *  described on page 512 of Vol. 3 of "The Art of Computer Programming".
     */
    for (p = (const unsigned char *) string  ;  *p != '\0'  ;  ++p)
    {
        value <<= 1;
        if (value & 0x00000100L)
            value = (value & 0x000000ffL) + 1L;
        value ^= *p;
    }
    /*  Algorithm from page 509 of Vol. 3 of "The Art of Computer Programming"
     *  Treats "value" as a 16-bit integer plus 16-bit fraction.
     */
    value *= 40503L;               /* = 2^16 * 0.6180339887 ("golden ratio") */
    /*value &= 0x0000ffffL;          [> keep fractional part <]*/
    /*value >>= 16 - HASH_EXPONENT;  [> scale up by hash size and move down <]*/

    return value % uBucketSize;
}

/* vi: set et */
