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

#ifndef __FTSTACK_H__
#define __FTSTACK_H__

#include "ftTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Stack_st {
    void      **ppBase;     /* 用来记录任意类型数据的数组 */
    size_t      uTop;       /* 栈顶位置 */
    unsigned    uStackSize; /* 栈的最大尺寸，也就是数组的大小 */
} Stack;

typedef struct StackIter_st {
    size_t      uCurIndex;
    Stack      *pStack;
} StackIter;

Stack * Stack_Create(size_t uStackSize);
void    Stack_Destroy(Stack *pStack, DestroyFunc destroy_func);
Bool    Stack_Peek(Stack *pStack, void **ppOutData);
Bool    Stack_Pop(Stack *pStack, void **ppOutData);
Bool    Stack_Push(Stack *pStack, void *pData);
Bool    Stack_IsEmpty(Stack *pStack);
size_t  Stack_GetCount(Stack *pStack);

/* 从栈底到栈顶 */
void    Stack_IterInit(StackIter *pIter, Stack *pStack);
Bool    Stack_IterNext(StackIter *pIter, void **ppOutData);

void    Stack_BaseToTopIterInit(StackIter *pIter, Stack *pStack);
Bool    Stack_BaseToTopIterNext(StackIter *pIter, void **ppOutData);

#ifdef __cplusplus
}
#endif

#endif /* __FTSTACK_H__ */
