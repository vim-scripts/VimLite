#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ftCMacro.h"
#include "ftString.h"

/* BUFSIZ 下限值 */
#if BUFSIZ < 1024
# undef BUFSIZ
# define BUFSIZ 1024
#endif

CMacro * CMacro_Create(char *pszMacroID, char *pszMacroValue,
                       Bool bIsFuncLike, size_t uArgc, char **ppszArgv)
{
    CMacro *pCMacro = (CMacro *)malloc(sizeof(CMacro));
    if ( pCMacro == NULL )
    {
        return NULL;
    }
    memset(pCMacro, 0, sizeof(CMacro));

    pCMacro->pszMacroID = pszMacroID;
    pCMacro->pszMacroValue = pszMacroValue;
    pCMacro->bIsFuncLike = bIsFuncLike;
    pCMacro->uArgc = uArgc;
    pCMacro->ppszArgv = ppszArgv;

    return pCMacro;
}


void CMacro_Destroy(CMacro *pCMacro)
{
    if ( pCMacro != NULL )
    {
        int i;
        free(pCMacro->pszMacroID);
        free(pCMacro->pszMacroValue);
        for ( i = 0; i < pCMacro->uArgc; i++ )
        {
            free(pCMacro->ppszArgv[i]);
        }
        free(pCMacro->ppszArgv);
        free(pCMacro);
    }
}


static Bool IsMacroArg(const char *psz, int nArgc, const char **ppMacroArgv,
                       int *pnArgIdx)
{
    int i;
    for ( i = 0; i < nArgc; i++ )
    {
        if ( strcmp(psz, ppMacroArgv[i]) == 0 )
        {
            *pnArgIdx = i;
            return True;
        }
    }
    return False;
}


int CMacro_ExpandCMacroValueArgs(const char *pszMacroValue,
                                 int nArgc,
                                 const char **ppMacroArgv,
                                 const char **ppRealArgv,
                                 char *pszBuf, size_t uBufSize)
{
    char m;
    size_t i;
    size_t uStart, uEnd;
    size_t uCopyLen;
    size_t uWriteLen;
    int nArgIdx;
    char szTmpBuf[BUFSIZ]; /* 存放临时的 c 标识符 */
    Bool bFound = False; /* 是否找到匹配的引号 */
    Bool bStringlize = False;

    if ( uBufSize == 0 )
    {
        return 0; /* 非法缓冲，外部负责 */
    }
    pszBuf[uBufSize - 1] = '\0';
    uWriteLen = 0;

    for ( i = 0; pszMacroValue[i] != '\0'; i++ )
    {
        switch ( pszMacroValue[i] )
        {
            case '"': /* 跳过字符串 */
            case '\'': /* 跳过字符 */
                m = pszMacroValue[i];
                uStart = i;
                uEnd = uStart;
                bFound = False;
                for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                {
                    if ( pszMacroValue[i] == '\\' )
                    {
                        i++;
                    }
                    else if ( pszMacroValue[i] == m )
                    {
                        bFound = True;
                        uEnd = i + 1;
                        break; /* 完成 */
                    }
                }

                if ( bFound )
                {
                    uCopyLen = uEnd - uStart;
                    if ( uCopyLen + uWriteLen >= uBufSize )
                    {
                        /* 输出缓冲溢出 */
                        uCopyLen = uBufSize - uWriteLen;
                        strncpy(pszBuf + uWriteLen, pszMacroValue + uStart,
                                uCopyLen);
                        uWriteLen += uCopyLen;
                        return 0;
                    }
                    else
                    {
                        strncpy(pszBuf + uWriteLen, pszMacroValue + uStart,
                                uCopyLen);
                        uWriteLen += uCopyLen;
                    }

                    i = uEnd - 1;
                }
                else
                {
                    i = uStart; /* 没有匹配的双引号，不跳过，继续分析 */
                }
                break;

            case '#': /* 可能特殊的宏字符 */
                if ( pszMacroValue[i + 1] == '#' ) /* 字符串连接 */
                {
                    i++;
                    if ( uWriteLen >= uBufSize )
                    {
                        return 0;
                    }
                    pszBuf[uWriteLen++] = '\0';
                    StrRStripSpaceMod(pszBuf);
                    uWriteLen = strlen(pszBuf);
                    /* 寻找标识符 */
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsSpace(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    goto default_process; /* 常规处理 */
                }
                else /* 字符串化 */
                {
                    /* 跳过空白 */
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsSpace(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    /* 此时 pszMacroValue[i] 不是 [a-zA-Z_] 的话就是语法错误 */
                    if ( IsIdtfrS(pszMacroValue[i]) )
                    {
                        bStringlize = True;
                        goto default_process;
                    }
                    else
                    {
                        /* NOTE: 理论上是语法错误，暂时处理为添加空字符串 "" */
                        uCopyLen = 2;
                        if ( uWriteLen + uCopyLen > uBufSize )
                        {
                            uCopyLen = uBufSize - uWriteLen;
                            strncpy(pszBuf + uWriteLen, "\"\"", uCopyLen);
                            uWriteLen += uCopyLen;
                            return 0;
                        }
                        else
                        {
                            strncpy(pszBuf + uWriteLen, "\"\"", uCopyLen);
                            uWriteLen += uCopyLen;
                        }
                        i -= 1;
                    }
                }
                break;

            default:
default_process:
                if ( IsSpace(pszMacroValue[i]) )
                {
                    /* 顺便精简空白为单个空格 */
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsSpace(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    if ( uWriteLen >= uBufSize )
                    {
                        return 0;
                    }
                    pszBuf[uWriteLen++] = ' ';
                    i -= 1;
                }
                /* 单词的开头条件是:
                 * 前一个字符是 \W(!\w) 且当前字符为 [a-zA-Z_] */
                else if ( IsIdtfrS(pszMacroValue[i]) 
                          && !(i > 0 && IsIdtfr(pszMacroValue[i - 1])) )
                {
                    const char *psz;

                    uStart = i;
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsIdtfr(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    uEnd = i;
                    uCopyLen = uEnd - uStart;
                    if ( uCopyLen >= sizeof(szTmpBuf) )
                    {
                        /* 临时缓冲不足，不允许这种情况 */
                        printf("name of identifier \"%s\" is too long",
                               pszMacroValue + uStart);
                        return -1;
                    }
                    strncpy(szTmpBuf, pszMacroValue + uStart, uCopyLen);
                    szTmpBuf[uCopyLen] = '\0';

                    if ( IsMacroArg(szTmpBuf, nArgc, ppMacroArgv, &nArgIdx) )
                    {
                        if ( ppRealArgv == NULL )   /* 允许为 NULL */
                        {
                            psz = "";
                        }
                        else
                        {
                            psz = ppRealArgv[nArgIdx];
                        }

                        if ( psz == NULL ) /* 实际参数可能不足，
                                              不一定是语法错误，
                                              例如在注释里面 */
                        {
                            psz = "";
                        }

                        if ( bStringlize )
                        {
                            StrEscapeChars(psz, "\"\\", szTmpBuf, sizeof(szTmpBuf));
                            if ( IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                            {
                                return -1;
                            }
                            psz = szTmpBuf;
                        }

                        uCopyLen = strlen(psz);
                    }
                    else
                    {
                        /* 可能的情况:
                         * 1) 普通的标识符
                         * 2) # 之后是一个有效的 C 标识符，但不是一个宏参数，
                         *    理论上是一个语法错误，直接把这个标识符字符串化 */
                        psz = szTmpBuf;
                    }

                    if ( bStringlize )
                    {
                        if ( uWriteLen >= uBufSize )
                        {
                            return 0;
                        }
                        pszBuf[uWriteLen++] = '"';
                    }

                    if ( uWriteLen + uCopyLen >= uBufSize )
                    {
                        uCopyLen = uBufSize - uWriteLen;
                        strncpy(pszBuf + uWriteLen, psz, uCopyLen);
                        uWriteLen += uCopyLen;
                        return 0;
                    }
                    else
                    {
                        strncpy(pszBuf + uWriteLen, psz, uCopyLen);
                        uWriteLen += uCopyLen;
                    }

                    if ( bStringlize )
                    {
                        if ( uWriteLen >= uBufSize )
                        {
                            return 0;
                        }
                        pszBuf[uWriteLen++] = '"';
                    }

                    i = uEnd - 1;
                }
                else /* 默认处理，字符复制 */
                {
                    if ( uWriteLen >= uBufSize )
                    {
                        return 0;
                    }
                    pszBuf[uWriteLen++] = pszMacroValue[i];
                }

                bStringlize = False;
                break;
        }
    }

    if ( uWriteLen >= uBufSize )
    {
        return 0;
    }
    pszBuf[uWriteLen++] = '\0';
    StrStripSpaceMod(pszBuf); /* 剔除前后的空白 */

    return 0;
}


int CMacro_ExpandCMacroValue(const CMacro *pCMacro,
                             const char **ppRealArgv,
                             const HashTable *pCMacroTable, /* 局部表 */
                             const HashTable *pGlobalTable, /* 全局表 */
                             HashTable *pExceptTable, /* 排除表 */
                             char *pszBuf, size_t uBufSize)
{
    char m;
    size_t i;
    size_t uStart, uEnd;
    size_t uCopyLen;
    size_t uWriteLen;
    const char *pszMacroValue;
    int nRet, nRes;
    CMacro tmpMacro;
    void *pOutData;
    char szTmpBuf[BUFSIZ]; /* 存放临时的 c 标识符等等 */
    Bool bFound = False; /* 是否找到匹配的引号 */

    nRes = 0;
    if ( uBufSize == 0 )
    {
        return nRes; /* 非法缓冲，外部负责 */
    }
    pszBuf[uBufSize - 1] = '\0';
    uWriteLen = 0;

    HashTable_Insert(pExceptTable, (void *)pCMacro,
                     CMacro_Hash, CMacro_Compare, NULL);

    pszMacroValue = NULL;
    if ( pCMacro->bIsFuncLike )
    {
        if ( ppRealArgv == NULL )
        {
            /* 没有获取到有效的宏实参，不处理 */
            nRet = 0;
            szTmpBuf[sizeof(szTmpBuf) - 1] = '\0'; /* sizeof(szTmpBuf) 一定大于 0 的吧？ */
            strncpy(szTmpBuf, pCMacro->pszMacroID, sizeof(szTmpBuf));
        }
        else
        {
            /* 先遍历一次，展开所有宏参数，但不展开宏 */
            nRet = CMacro_ExpandCMacroValueArgs(pCMacro->pszMacroValue,
                                                (int)pCMacro->uArgc,
                                                (const char **)pCMacro->ppszArgv,
                                                ppRealArgv,
                                                szTmpBuf, sizeof(szTmpBuf));
        }

        if ( nRet < 0 || IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
        {
            nRes = -1;
            goto return_label;
        }
        else
        {
            int nLen = strlen(szTmpBuf);
            pszMacroValue = (const char *)malloc(nLen + 1);
            if ( pszMacroValue == NULL )
            {
                nRes = -1;
                goto return_label;
            }
            strcpy((char *)pszMacroValue, szTmpBuf);
        }
    }
    else
    {
        pszMacroValue = pCMacro->pszMacroValue;
    }

    for ( i = 0; pszMacroValue[i] != '\0'; i++ )
    {
        switch ( pszMacroValue[i] )
        {
            case '"': /* 跳过字符串 */
            case '\'': /* 跳过字符 */
                m = pszMacroValue[i];
                uStart = i;
                uEnd = uStart;
                bFound = False;
                for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                {
                    if ( pszMacroValue[i] == '\\' )
                    {
                        i++;
                    }
                    else if ( pszMacroValue[i] == m )
                    {
                        bFound = True;
                        uEnd = i + 1;
                        break; /* 完成 */
                    }
                }

                if ( bFound )
                {
                    uCopyLen = uEnd - uStart;
                    if ( uCopyLen + uWriteLen >= uBufSize )
                    {
                        /* 输出缓冲溢出 */
                        uCopyLen = uBufSize - uWriteLen;
                        strncpy(pszBuf + uWriteLen, pszMacroValue + uStart,
                                uCopyLen);
                        uWriteLen += uCopyLen;
                        goto return_label;
                    }
                    else
                    {
                        strncpy(pszBuf + uWriteLen, pszMacroValue + uStart,
                                uCopyLen);
                        uWriteLen += uCopyLen;
                    }

                    i = uEnd - 1;
                }
                else
                {
                    i = uStart; /* 没有匹配的双引号，不跳过，继续分析 */
                }
                break;

            default:
                if ( IsSpace(pszMacroValue[i]) )
                {
                    /* 顺便精简空白为单个空格 */
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsSpace(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    if ( uWriteLen >= uBufSize )
                    {
                        goto return_label;
                    }
                    pszBuf[uWriteLen++] = ' ';
                    i -= 1;
                }
                /* 单词的开头条件是:
                 * 前一个字符是 \W(!\w) 且当前字符为 [a-zA-Z_] */
                else if ( IsIdtfrS(pszMacroValue[i]) 
                          && !(i > 0 && IsIdtfr(pszMacroValue[i - 1])) )
                {
                    const char *psz;

                    uStart = i;
                    for ( i = i + 1; pszMacroValue[i] != '\0'; i++ )
                    {
                        if ( !IsIdtfr(pszMacroValue[i]) )
                        {
                            break;
                        }
                    }
                    uEnd = i;
                    uCopyLen = uEnd - uStart;
                    if ( uCopyLen >= sizeof(szTmpBuf) )
                    {
                        /* 临时缓冲不足，不允许这种情况 */
                        printf("name of identifier \"%s\" is too long",
                               pszMacroValue + uStart);
                        nRes = -1;
                        goto return_label;
                    }
                    /* 保存正在处理的 C 标识符 */
                    strncpy(szTmpBuf, pszMacroValue + uStart, uCopyLen);
                    szTmpBuf[uCopyLen] = '\0';

                    psz = szTmpBuf;
                    /* 处理标识符 */
                    tmpMacro.pszMacroID = szTmpBuf;
                    if ( HashTable_Find(pExceptTable, &tmpMacro,
                                        CMacro_Hash, CMacro_Compare,
                                        &pOutData) )
                    {
                        /* #define A A 的情况，不处理 */
                    }
                    /* 先查局部表，再查全局表 */
                    else if ( HashTable_Find(pCMacroTable,
                                             &tmpMacro,
                                             CMacro_Hash,
                                             CMacro_Compare,
                                             &pOutData)
                              || (pGlobalTable != NULL
                                  && HashTable_Find(pGlobalTable,
                                                    &tmpMacro,
                                                    CMacro_Hash,
                                                    CMacro_Compare,
                                                    &pOutData)) )
                    {
                        char **ppszRealArgvTmp = NULL;
                        CMacro *pOutCMacro = (CMacro *)pOutData;
                        if ( pOutCMacro->bIsFuncLike )
                        {
                            /* 如果此宏是类函数的，需要收集实际参数 */
                            size_t j = uEnd;
                            for ( ; IsSpace(pszMacroValue[j]); j++ )
                                ; /* 跳至非空白字符 */
                            if ( pszMacroValue[j] == '(' )
                            {
                                StrIter iterTmp;
                                size_t k, uCopyLenTmp;
                                char *pszTmp = (char *)StrSkipCMatch(
                                        pszMacroValue + j + 1, "()");
                                if ( pszTmp == NULL )
                                {
                                    /* 致命的语法错误 */
                                    nRes = -1;
                                    goto return_label;
                                }
                                uCopyLenTmp = pszTmp - (pszMacroValue + j);
                                uEnd = j + uCopyLenTmp; /* 新的起点为匹配的 ) 之后 */
                                if ( uCopyLenTmp >= sizeof(szTmpBuf) )
                                {
                                    /* 失败 */
                                    nRes = -1;
                                    goto return_label;
                                }
                                /* 前后括号不复制 */
                                strncpy(szTmpBuf,
                                        pszMacroValue + j + 1, uCopyLenTmp - 2);
                                szTmpBuf[uCopyLenTmp - 2] = '\0';
                                pszTmp = StrDup(szTmpBuf);
                                if ( pszTmp == NULL )
                                {
                                    nRes = -1;
                                    goto return_label;
                                }
                                ppszRealArgvTmp = (char **)malloc(
                                        sizeof(char *) * pOutCMacro->uArgc);
                                if ( ppszRealArgvTmp == NULL )
                                {
                                    free(pszTmp);
                                    nRes = -1;
                                    goto return_label;
                                }
                                memset(ppszRealArgvTmp, 0,
                                       sizeof(char *) * pOutCMacro->uArgc);

                                StrIterSplitCCodeInit(&iterTmp, pszTmp,
                                                      pOutCMacro->uArgc - 1);
                                k = 0;
                                while ( StrIterSplitCCodeNext(
                                                &iterTmp, ",",
                                                szTmpBuf, sizeof(szTmpBuf)) )
                                {
                                    if ( IsBufferOverflow(szTmpBuf,
                                                          sizeof(szTmpBuf)) )
                                    {
                                        goto overflow_label;
                                    }
                                    StrCompactCSpace(szTmpBuf); /* 精简间隔空白 */
                                    StrStripSpaceMod(szTmpBuf); /* 剔除前后空白 */
                                    ppszRealArgvTmp[k] = StrDup(szTmpBuf);
                                    if ( ppszRealArgvTmp[k] == NULL )
                                    {
overflow_label:
                                        for ( k = 0; k < pOutCMacro->uArgc; k++ )
                                        {
                                            free(ppszRealArgvTmp[k]);
                                        }
                                        free(ppszRealArgvTmp);
                                        free(pszTmp);
                                        nRes = -1;
                                        goto return_label;
                                    }
                                    k++;
                                }
                                free(pszTmp);
                            }
                        }

                        /* 递归处理 */
                        nRet = CMacro_ExpandCMacroValue(
                                pOutCMacro, (const char **)ppszRealArgvTmp,
                                pCMacroTable, pGlobalTable, pExceptTable,
                                szTmpBuf, sizeof(szTmpBuf));
                        if ( nRet < 0
                             || IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                        {
                            nRes = -1;
                            goto return_label;
                        }
                        psz = szTmpBuf;
                        uCopyLen = strlen(szTmpBuf);

                        if ( ppszRealArgvTmp != NULL )
                        {
                            size_t k;
                            for ( k = 0; k < pOutCMacro->uArgc; k++ )
                            {
                                free(ppszRealArgvTmp[k]);
                                ppszRealArgvTmp[k] = NULL;
                            }
                            free(ppszRealArgvTmp);
                            ppszRealArgvTmp = NULL;
                        }
                    }

                    if ( uWriteLen + uCopyLen >= uBufSize )
                    {
                        uCopyLen = uBufSize - uWriteLen;
                        strncpy(pszBuf + uWriteLen, psz, uCopyLen);
                        uWriteLen += uCopyLen;
                        goto return_label;
                    }
                    else
                    {
                        strncpy(pszBuf + uWriteLen, psz, uCopyLen);
                        uWriteLen += uCopyLen;
                    }

                    i = uEnd - 1;
                }
                else
                {
                    if ( uWriteLen >= uBufSize )
                    {
                        goto return_label;
                    }
                    pszBuf[uWriteLen++] = pszMacroValue[i];
                }

                break;
        }
    }

    if ( uWriteLen >= uBufSize )
    {
        goto return_label;
    }
    pszBuf[uWriteLen++] = '\0';
    StrStripSpaceMod(pszBuf); /* 剔除前后的空白 */

return_label:
    HashTable_Remove(pExceptTable, (void *)pCMacro,
                     CMacro_Hash, CMacro_Compare, NULL);
    if ( pCMacro->bIsFuncLike )
    {
        free((char *)pszMacroValue);
        pszMacroValue = NULL;
    }

    return nRes;
}


int CMacro_PreProcessString(const char *pszStr,
                            const HashTable *pCMacroTable, /* 局部表 */
                            const HashTable *pGlobalTable, /* 全局表，可为 NULL */
                            char *pszBuf, size_t uBufSize,
                            char **ppszContinue)
{
    const char *psz;
    const char *p;
    size_t uStart, uEnd, uCopyLen;
    size_t uWriteLen;
    void *pOutData;
    CMacro *pCMacro;
    CMacro tmpMacro;
    int nProcessCount;
    HashTable *pExceptTable;
    char szTmpBuf[BUFSIZ] = {'\0'};
    
    uWriteLen = 0;
    nProcessCount = 0;

    if ( uBufSize == 0 )
    {
        return 0; /* 无效的缓冲区 */
    }
    pszBuf[uBufSize - 1] = '\0';
    if ( ppszContinue != NULL )
    {
        *ppszContinue = NULL;
    }

    pExceptTable = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    if ( pExceptTable == NULL )
    {
        /* 出错 */
        return -1;
    }

    p = pszStr;
    while ( StrSearchCId(p, &uStart, &uEnd) != NULL )
    {
        uCopyLen = uStart;
        if ( uWriteLen + uCopyLen >= uBufSize )
        {
            uCopyLen = uBufSize - uWriteLen;
            strncpy(pszBuf + uWriteLen, p, uCopyLen);
            uWriteLen += uCopyLen;
            nProcessCount = 0;
            goto return_label;
            /*return 0; [> 缓冲区不足，由外部检查 <]*/
        }
        else
        {
            strncpy(pszBuf + uWriteLen, p, uCopyLen);
            uWriteLen += uCopyLen;
        }

        uCopyLen = uEnd - uStart;
        if ( uCopyLen >= sizeof(szTmpBuf) )
        {
            /* 临时缓冲区不足，名字太长了，不允许这种情况 */
            nProcessCount = -1;
            goto return_label;
            /*return -1;*/
        }
        strncpy(szTmpBuf, p + uStart, uCopyLen);
        szTmpBuf[uCopyLen] = '\0';
        tmpMacro.pszMacroID = szTmpBuf;
        /* 先查局部表，再查全局表 */
        if ( HashTable_Find(pCMacroTable,
                            &tmpMacro,
                            CMacro_Hash,
                            CMacro_Compare,
                            &pOutData)
             || (pGlobalTable != NULL && HashTable_Find(pGlobalTable,
                                                        &tmpMacro,
                                                        CMacro_Hash,
                                                        CMacro_Compare,
                                                        &pOutData)) )
        {
            /* 需要处理宏替换 */
            pCMacro = (CMacro *)pOutData;
            if ( pCMacro->bIsFuncLike )
            {
                const char *pszTmp1, *pszTmp2;

                uCopyLen = strlen(pCMacro->pszMacroValue);
                psz = pCMacro->pszMacroValue;

                /* 类函数宏 */
                pszTmp1 = StrSkipToNonSpace(p + uEnd);
                if ( pszTmp1[0] == '(' )
                {
                    pszTmp2 = StrSkipCMatch(pszTmp1 + 1, "()");
                    if ( pszTmp2 == NULL )
                    {
                        /* 参数不全，返回，并提示继续 */
                        if ( uWriteLen < uBufSize )
                        {
                            pszBuf[uWriteLen++] = '\0';
                        }
                        if ( ppszContinue != NULL )
                        {
                            *ppszContinue = (char *)p + uStart;
                        }
                        goto return_label;
                        /*return nProcessCount;*/
                    }
                    else
                    {
                        size_t j;
                        StrIter iter;
                        char **ppszRealArgv;
                        char *szArgsBuf = (char *)malloc(
                                sizeof(char) * (pszTmp2 - pszTmp1 - 2 + 1));
                        if ( szArgsBuf == NULL )
                        {
                            nProcessCount = -1;
                            goto return_label;
                            /*return -1;*/
                        }
                        strncpy(szArgsBuf, pszTmp1 + 1, pszTmp2 - pszTmp1 - 2);
                        szArgsBuf[pszTmp2 - pszTmp1 - 2] = '\0';

                        ppszRealArgv = (char **)malloc(
                                sizeof(char *) * pCMacro->uArgc);
                        if ( ppszRealArgv == NULL )
                        {
                            free(szArgsBuf);
                            nProcessCount = -1;
                            goto return_label;
                            /*return -1;*/
                        }
                        memset(ppszRealArgv, 0, sizeof(char *) * pCMacro->uArgc);

                        /* 限定分割次数即可支持可变参数宏 __VA_ARGS__ */
                        StrIterSplitCCodeInit(&iter, szArgsBuf, pCMacro->uArgc - 1);
                        j = 0;
                        while ( StrIterSplitCCodeNext(&iter, ",",
                                                      szTmpBuf, sizeof(szTmpBuf)) )
                        {
                            if ( IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                            {
                                goto overflow_label; /* 缓冲区不足 */
                            }
                            StrStripCAllComment(szTmpBuf); /* 剔除注释 */
                            StrCompactCSpace(szTmpBuf); /* 精简间隔空白 */
                            StrStripSpaceMod(szTmpBuf); /* 剔除前后空白 */
                            ppszRealArgv[j] = malloc(strlen(szTmpBuf) + 1);
                            if ( ppszRealArgv == NULL )
                            {
overflow_label:
                                for ( j = 0; j < pCMacro->uArgc; j++ )
                                {
                                    free(ppszRealArgv[j]);
                                }
                                free(ppszRealArgv);
                                free(szArgsBuf);
                                nProcessCount = -1;
                                goto return_label;
                                /*return -1;*/
                            }
                            strcpy(ppszRealArgv[j], szTmpBuf);
                            j++;
                        }

                        /*if ( j != pCMacro->uArgc )*/
                        /*{*/
                            /* 参数不足，可能在注释里面，暂时忽略处理 */
                        /*}*/

#if 0
                        if ( StrExpandCMacroValue(pCMacro->pszMacroValue,
                                                  szTmpBuf, sizeof(szTmpBuf),
                                                  pCMacro->uArgc,
                                                  (const char **)pCMacro->ppszArgv,
                                                  (const char **)ppszRealArgv) < 0
                             || IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                        {
                            goto overflow_label; /* 不允许任何错误 */
                        }
#endif
                        if ( CMacro_ExpandCMacroValue(pCMacro,
                                                      (const char **)ppszRealArgv,
                                                      pCMacroTable,
                                                      pGlobalTable,
                                                      pExceptTable,
                                                      szTmpBuf,
                                                      sizeof(szTmpBuf)) < 0
                             || IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                        {
                            goto overflow_label; /* 不允许任何错误 */
                        }

                        uCopyLen = strlen(szTmpBuf);
                        psz = szTmpBuf;

                        for ( j = 0; j < pCMacro->uArgc; j++ )
                        {
                            free(ppszRealArgv[j]);
                        }
                        free(ppszRealArgv);

                        free(szArgsBuf);

                        uEnd = pszTmp2 - p;
                    }
                }
            }
            else
            {
                if ( CMacro_ExpandCMacroValue(pCMacro,
                                              NULL,
                                              pCMacroTable,
                                              pGlobalTable,
                                              pExceptTable,
                                              szTmpBuf,
                                              sizeof(szTmpBuf)) < 0
                     || IsBufferOverflow(szTmpBuf, sizeof(szTmpBuf)) )
                {
                    /* 不允许任何错误 */
                    nProcessCount = -1;
                    goto return_label;
                }
                uCopyLen = strlen(szTmpBuf);
                psz = szTmpBuf;
            }
            nProcessCount++; /* 成功处理一次，不管输出缓冲问题 */
        }
        else
        {
            psz = p + uStart;
        }

        if ( uWriteLen + uCopyLen >= uBufSize )
        {
            uCopyLen = uBufSize - uWriteLen;
            strncpy(pszBuf + uWriteLen, psz, uCopyLen);
            uWriteLen += uCopyLen;
            goto return_label;
            /*return nProcessCount; [> 缓冲区不足，暂时当失败处理 <]*/
        }
        else
        {
            strncpy(pszBuf + uWriteLen, psz, uCopyLen);
            uWriteLen += uCopyLen;
        }

        p += uEnd;
    }

    if ( p[0] != '\0' )
    {
        /* 最后那段字符串 */
        uCopyLen = strlen(p);
        if ( uWriteLen + uCopyLen >= uBufSize )
        {
            uCopyLen = uBufSize - uWriteLen;
        }

        strncpy(pszBuf + uWriteLen, p, uCopyLen);
        uWriteLen += uCopyLen;
    }

    /* 添加结尾 */
    if ( uWriteLen < uBufSize )
    {
        pszBuf[uWriteLen++] = '\0';
    }

return_label:
    HashTable_Destroy(pExceptTable, NULL);

    return nProcessCount;
}


int CMacro_Compare(void *p1, void *p2)
{
    return strcmp(((CMacro *)p1)->pszMacroID, ((CMacro *)p2)->pszMacroID);
}


size_t CMacro_Hash(void *p, size_t uBucketSize)
{
    return HashString(((CMacro *)p)->pszMacroID, uBucketSize);
}

