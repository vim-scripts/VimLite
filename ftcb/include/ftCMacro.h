#ifndef __FTCMACRO_H__
#define __FTCMACRO_H__

#include <stddef.h>
#include "ftTypes.h"
#include "ftHashTable.h"

#ifdef __cplusplus
extern "C" {
#endif


/* C 语言的宏
 * NOTE: 里面的作为内容的字符串都不能包含注释 */
typedef struct CMacro_st {
    char    *pszMacroID;    /* 宏名字 */
    char    *pszMacroValue; /* 宏值 */
    Bool    bIsFuncLike;    /* 是否类函数宏 */
    size_t  uArgc;          /* 参数个数 */
    char    **ppszArgv;     /* 参数字符 */
} CMacro;


CMacro * CMacro_Create(char *pszMacroID, char *pszMacroValue,
                       Bool bIsFuncLike, size_t uArgc, char **ppszArgv);

void CMacro_Destroy(CMacro *pCMacro);


/* 根据实际参数（可无参数，不能有注释）处理字符串，不展开任何宏。
 * 返回结果当中，所有空白会被精简，如同执行了 StrCompactCSpace() 一样
 * 执行成功返回 0, 失败返回 -1 */
/* 都假设没有语法错误，不做语法检查，语法错误后果自负。ppRealArgv 可为 NULL */
int CMacro_ExpandCMacroValueArgs(const char *pszMacroValue,
                                 int nArgc,
                                 const char **ppMacroArgv,
                                 const char **ppRealArgv,
                                 char *pszBuf, size_t uBufSize);

/* 根据实际参数（可无参数）展开宏值
 * 执行成功返回 0, 失败返回 -1 */
int CMacro_ExpandCMacroValue(const CMacro *pCMacro,
							 const char **ppRealArgv,
                             const HashTable *pCMacroTable, /* 局部表 */
							 const HashTable *pGlobalTable, /* 全局表 */
							 HashTable *pExceptTable, /* 排除表 */
							 char *pszBuf, size_t uBufSize);

/* 根据宏表预处理字符串，如果字符串缺少参数（如把宏参数写在多行时），
 * ppszContinue 赋值为继续宏处理的位置，否则 ppszContinue 赋值为 NULL
 * 成功返回成功处理的次数，失败返回 -1 */
int CMacro_PreProcessString(const char *pszStr,
                            const HashTable *pCMacroTable, /* 局部表 */
                            const HashTable *pGlobalTable, /* 全局表 */
                            char *pszBuf, size_t uBufSize,
                            char **ppszContinue);


int CMacro_Compare(void *p1, void *p2);

size_t CMacro_Hash(void *p, size_t uBucketSize);


#ifdef __cplusplus
}
#endif

#endif /* __FTCMACRO_H__ */
