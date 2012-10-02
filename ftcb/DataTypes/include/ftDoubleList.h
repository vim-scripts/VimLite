#ifndef __FTDOUBLELIST_H__
#define __FTDOUBLELIST_H__

#include "ftTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

/* 双向不循环链表 */

typedef struct DoubleNode_st {
	struct DoubleNode_st *pPrev;    /* 上一个节点 */
	struct DoubleNode_st *pNext;    /* 下一个节点 */
	void *pData;					/* 数据指针 */
} DoubleNode;

typedef struct DoubleList_st {
    DoubleNode *pHead;  /* 头部节点 */
    DoubleNode *pTail;  /* 尾部节点 */
    size_t uCount;      /* 节点总数 */
} DoubleList;

typedef struct DoubleListIter_st {
	DoubleNode *pCursor;
} DoubleListIter;

DoubleList * DoubleList_Create(void);
void DoubleList_Destroy(DoubleList *pList, DestroyFunc destroy_func);

/* 清空链表，保留空链表结构 */
void DoubleList_Clear(DoubleList *pList, DestroyFunc destroy_func);

Bool DoubleList_Append(DoubleList *pList, void *pData);
Bool DoubleList_Prepend(DoubleList *pList, void *pData);

Bool DoubleList_PopHead(DoubleList *pList, void **ppOutData);
Bool DoubleList_PopTail(DoubleList *pList, void **ppOutData);
Bool DoubleList_Pop(DoubleList *pList, int nIndex, void **ppOutData);

Bool DoubleList_GetHead(DoubleList *pList, void **ppOutData);
Bool DoubleList_GetTail(DoubleList *pList, void **ppOutData);
Bool DoubleList_Get(DoubleList *pList, int nIndex, void **ppOutData);

void DoubleList_Insert(DoubleList *pList, int nIndex);

void DoubleList_Reverse(DoubleList *pList);

void DoubleList_Traverse(DoubleList *pList,
						 VisitFunc visit_func, void *pPrivateData);

#if 0
size_t DoubleList_GetCount(DoubleList *pList);
#else
#define DoubleList_GetCount(pList) (pList)->uCount
#endif

/* 迭代列表 */
void DoubleList_IterInit(DoubleListIter *pIter, DoubleList *pList);
Bool DoubleList_IterNext(DoubleListIter *pIter, void **ppOutData);

#ifdef __cplusplus
}
#endif


#endif /* __FTDOUBLELIST_H__ */
