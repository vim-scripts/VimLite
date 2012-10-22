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
#include "ftTypes.h"
#include "ftStack.h"

/** 创建一个栈

    @param  size_t uStackSize - 栈的大小    
    @return Stack * - 成功返回栈指针，失败返回NULL。    
*/
Stack * Stack_Create(size_t uStackSize)
{
    Stack *pStack;

    if ( uStackSize == 0 )
    {
        return NULL;
    }

    pStack = (Stack *)malloc(sizeof(Stack));
    if ( pStack != NULL )
    {
        pStack->ppBase = (void **)malloc(uStackSize * sizeof(void *));
        if ( pStack->ppBase == NULL )
        {
            free(pStack);
            pStack = NULL;
        }
        else
        {
            pStack->ppBase[0] = NULL;
            pStack->uTop = 0;
            pStack->uStackSize = uStackSize;
        }
    }

    return pStack;
}


/** 栈的释放函数，它会将栈中剩余的未弹出数据释放掉，

    @param  Stack * pStack - 栈指针 
    @param  DestroyFunc destroy_func - 数据释放回调函数 
    @return void - 无   
*/
void Stack_Destroy(Stack * pStack, DestroyFunc destroy_func)
{
    if ( pStack != NULL )
    {
        if ( pStack->ppBase != NULL )
        {
            if ( destroy_func != NULL )
            {
                size_t i;
                for ( i = 0; i < pStack->uTop; i++ )
                {
                    if ( pStack->ppBase[i] != NULL )
                    {
                        (*destroy_func)(pStack->ppBase[i]);
                    }
                }
            }
            free(pStack->ppBase);
        }
        free(pStack);
        pStack = NULL;
    }
}


Bool Stack_Pop(Stack * pStack, void **ppOutData)
{
    if ( pStack->uTop == 0 )
    {
        return False;
    }

    pStack->uTop -= 1;

    *ppOutData = pStack->ppBase[pStack->uTop];
    
    return True;
}


Bool Stack_Push(Stack * pStack, void *pData)
{
    /* 判断栈是否满了，如果满了则将栈空间增大一倍 */
    if ( pStack->uTop >= pStack->uStackSize - 1 )
    {
        pStack->ppBase = (void **)realloc(
                pStack->ppBase, ( pStack->uStackSize * 2 ) * sizeof( void * ));
        if ( pStack->ppBase == NULL )
        {
            return False;
        }
        pStack->uStackSize *= 2;
    }
    pStack->ppBase[pStack->uTop] = pData;
    pStack->uTop += 1;

    return True;
}


Bool Stack_IsEmpty(Stack *pStack)
{
    if ( pStack->uTop == 0 )
    {
        return True;
    }
    return False;
}


Bool Stack_Peek(Stack *pStack, void **ppOutData)
{
    if ( pStack->uTop == 0 )
    {
        return False;
    }

    *ppOutData = pStack->ppBase[pStack->uTop - 1];

    return True;
}


size_t  Stack_GetCount(Stack *pStack)
{
    return pStack->uTop;
}


void Stack_IterInit(StackIter *pIter, Stack *pStack)
{
    Stack_BaseToTopIterInit(pIter, pStack);
}

void Stack_BaseToTopIterInit(StackIter *pIter, Stack *pStack)
{
    pIter->uCurIndex = 0;
    pIter->pStack = pStack;
}


Bool Stack_IterNext(StackIter *pIter, void **ppOutData)
{
    return Stack_BaseToTopIterNext(pIter, ppOutData);
}

Bool Stack_BaseToTopIterNext(StackIter *pIter, void **ppOutData)
{
    Stack *pStack = pIter->pStack;

    if ( pIter->uCurIndex >= pStack->uTop )
    {
        return False;
    }
    else
    {
        *ppOutData = pStack->ppBase[pIter->uCurIndex];
        pIter->uCurIndex += 1;
        return True;
    }
}

