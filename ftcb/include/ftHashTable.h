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

#ifndef __FTHASHTABLE_H__
#define __FTHASHTABLE_H__

#include "ftTypes.h"

#ifdef __cplusplus
extern "C" {
#endif


#define HASHTABLE_DEFAULT_SIZE (1 << 15)


/* 单链表的节点结构 */
typedef struct HTSingleNode_st {
    struct HTSingleNode_st *pNext;
    void *pData;
} HTSingleNode;

typedef struct HashTable_st {
    HTSingleNode  **ppBucket;       /* 索引表指针 */
    size_t          uBucketSize;    /* 索引表的大小 */
    size_t          uCount;         /* 表中的实际节点个数 */
} HashTable;

typedef struct HashTableIter_st {
    size_t uCurBucketIndex;
    HTSingleNode *pCurItem;
    const HashTable *pTable;
} HashTableIter;


/*** Hash Table operation functions ***/
HashTable * HashTable_Create(size_t uBucketSize);

void        HashTable_Destroy(HashTable *pTable,
							  DestroyFunc destroy_func);

HashTable * HashTable_Copy(const HashTable *pTable,
                           CopyFunc copy_func);

void        HashTable_Clear(HashTable *pTable,
							DestroyFunc destroy_func);


/* 如果 compare_func 非空，不允许相同的项目存在 */
Bool    HashTable_Insert(HashTable *pTable,
                         void *pData,
                         HashFunc hash_func,
                         CompareFunc compare_func,
                         DestroyFunc destroy_func);

Bool    HashTable_Find(const HashTable *pTable,
                       void *pData,
                       HashFunc hash_func,
                       CompareFunc compare_func,
                       void **ppOutData);

Bool    HashTable_Pop(HashTable *pTable,
                      void *pData,
                      HashFunc hash_func,
                      CompareFunc compare_func,
                      void **ppOutData);

Bool    HashTable_Remove(HashTable *pTable,
                         void *pData,
                         HashFunc hash_func,
                         CompareFunc compare_func,
                         DestroyFunc destroy_func);

size_t  HashTable_GetCount(const HashTable *pTable);

void    HashTable_IterInit(HashTableIter *pIter, const HashTable *pTable);
Bool    HashTable_IterNext(HashTableIter *pIter, void **ppOutData);


/* ========================================================================== */
/* some hash functions */
/* ========================================================================== */

size_t HashString(void *pKey, size_t uBucketSize);


#ifdef __cplusplus
}
#endif


#endif /* __FTHASHTABLE_H__ */
