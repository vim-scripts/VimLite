#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ftString.h"

#define STR_ARRAY_INIT_SIZE 16U

typedef struct STR_RECORD_st {
    const char *pszStr;
    size_t uLen;
} STR_RECORD;

#if 0
static Bool CharIsInChars(char c, const char *pszChars)
{
    size_t i;
    for ( i = 0; pszChars[i] != '\0'; i++ )
    {
        if ( c == pszChars[i] )
        {
            return True;
        }
    }

    return False;
}
#else
#define CharIsInChars(c, pszChars) ((c) == '\0' ? False : strchr(pszChars, c))
#endif

/* 搜索 c 字符串中的字符串，即忽略 ""、'' 和注释包含的内容进行搜索 */
char * strcstr(const char *pszSrc, const char *pszNeedle)
{
    const char *psz, *pszTmp;

    if ( StrIsEmpty(pszNeedle) )
    {
        return (char *)pszSrc; /* 和 strstr() 的行为一致 */
    }

    psz = pszSrc;
    while ( *psz != '\0' )
    {
        char c = *psz;
        if ( c == '"' )
        {
            /* 跳过字符串 */
            pszTmp = StrSkipCString(psz + 1);
            psz = (pszTmp != NULL) ? pszTmp : psz;
        }
        else if ( c == '\'' )
        {
            /* 跳过字符 */
            pszTmp = StrSkipCChar(psz + 1);
            psz = (pszTmp != NULL) ? pszTmp : psz;
        }
        else if ( c == '/' )
        {
            if ( psz[1] == '*' )
            {
                /* C 注释 */
                pszTmp = StrSkipCComment(psz + 2);
                psz = (pszTmp != NULL) ? pszTmp : psz;
            }
            else if ( psz[1] == '/' )
            {
                /* C 行注释 */
                pszTmp = StrSkipCLineComment(psz + 2);
                if ( pszTmp[0] == '\0' )
                {
                    return NULL;
                }
                psz = pszTmp;
            }
        }

        if ( StrStartsWith(psz, pszNeedle, 0, STR_END_INDEX) )
        {
            return (char *)psz;
        }
        psz++;
    }

    return NULL;
}

/* 标准化字符串索引，即把负数索引转为正数索引，并使最大值不大于字符串长度 */
static void StrNormalizeIndex(size_t uLen, int nStart, int nEnd,
                              size_t *puOutStart, size_t *puOutEnd)
{
    if ( nStart < 0 )
    {
        if ( uLen > (size_t)(-nStart) )
        {
            *puOutStart = uLen - (size_t)(-nStart);
        }
        else
        {
            *puOutStart = 0;
        }
    }
    else
    {
        *puOutStart = nStart;
    }

    if ( nEnd < 0 )
    {
        if ( uLen > (size_t)(-nEnd) )
        {
            *puOutEnd = uLen - (size_t)(-nEnd);
        }
        else
        {
            *puOutEnd = 0;
        }
    }
    else
    {
        *puOutEnd = nEnd;
    }

    *puOutStart = (*puOutStart > uLen) ? uLen : *puOutStart;
    *puOutEnd = (*puOutEnd > uLen) ? uLen : *puOutEnd;
}

/* 获取字符串数组的长度 */
size_t StrArrayLen(char **ppStrArray)
{
    size_t u;

    u = 0;
    while ( ppStrArray[u] != NULL )
    {
        u++;
    }

    return u;
}

/* 释放字符串数组 */
void StrArrayFree(char **ppStrArray)
{
    size_t u;

    if ( ppStrArray == NULL )
    {
        return;
    }

    u = 0;
    while ( ppStrArray[u] != NULL )
    {
        free(ppStrArray[u]);
        u++;
    }

    free(ppStrArray);
}

size_t StrCopyMod(char *pszDst, size_t uSize, const char *pszSrc)
{
    size_t u = 0;
    while ( *pszSrc && u < uSize )
    {
        *pszDst = *pszSrc;
        u++;
    }

    return u;
}

#if 0
Bool StrIsEmpty(const char *pszSrc)
{
    return pszSrc[0] == '\0';
}
#endif

#if 0
Bool StrIsEqual(const char *psz1, const char *psz2)
{
    return (StrCmp(psz1, psz2) == 0) ? True : False;
}
#endif

Bool StrIsEqualIC(const char *psz1, const char *psz2)
{
    return (StrCmpIC(psz1, psz2) == 0) ? True : False;
}

int StrCmp(const char *psz1, const char *psz2)
{
    return strcmp(psz1, psz2);
}

int StrCmpIC(const char *psz1, const char *psz2)
{
    int nResult;
    for ( ;; )
    {
        nResult = ToUpper(*psz1) - ToUpper(*psz2);
        if ( nResult != 0 )
        {
            return nResult;
        }

        if ( (*psz1) == '\0' && (*psz2) == '\0' )
        {
            /* 两个字符串完全相等才会到达此分支 */
            return nResult;
        }
        psz1++;
        psz2++;
    }
}

char * StrAdd(const char *psz1, const char *psz2)
{
    char *pszNew;
    size_t uStr1Len, uStr2Len;

    uStr1Len = strlen(psz1);
    uStr2Len = strlen(psz2);

    pszNew = (char *)malloc(uStr1Len + uStr2Len + 1);

    strcpy(pszNew, psz1);
    strcpy(pszNew + uStr1Len, psz2);
    pszNew[uStr1Len + uStr2Len] = '\0';

    return pszNew;
}


char * StrDup(const char *pszSrc)
{
    char *pszNew = malloc(strlen(pszSrc) + 1);
    if ( pszNew == NULL )
    {
        return NULL;
    }
    strcpy(pszNew, pszSrc);

    return pszNew;
}


size_t StrLen(const char *pszSrc)
{
    return strlen(pszSrc);
}


/* 字符串切片 */
char * StrSlice(const char *pszSrc, int nStart, int nEnd)
{
    char *pszNew;
    size_t uStart, uEnd;
    size_t uLen;
    size_t uNewLen;

    uLen = strlen(pszSrc);
    StrNormalizeIndex(uLen, nStart, nEnd, &uStart, &uEnd);

    uStart = (uStart > uLen) ? uLen : uStart;
    uEnd = (uEnd > uLen) ? uLen : uEnd;

    if ( uEnd > uStart )
    {
        uNewLen = uEnd - uStart;
        pszNew = (char *)malloc(uNewLen + 1);
        strncpy(pszNew, pszSrc + uStart, uNewLen);
        pszNew[uNewLen] = '\0';
    }
    else
    {
        pszNew = (char *)malloc(1);
        pszNew[0] = '\0';
    }

    return pszNew;
}


char * StrSliceToEnd(const char *pszSrc, int nStart)
{
    return StrSlice(pszSrc, nStart, STR_MAX_32BIT_INT);
}

Bool StrEndsWith(const char *pszSrc, const char *pszSuffix,
                 int nStart, int nEnd)
{
    size_t uStart, uEnd;
    size_t uSrcLen;
    size_t uSuffixLen;
    size_t i;
    Bool bResult;


    uSrcLen = strlen(pszSrc);
    uSuffixLen = strlen(pszSuffix);
    StrNormalizeIndex(uSrcLen, nStart, nEnd, &uStart, &uEnd);

    pszSrc += uStart;
    uSrcLen = uEnd - uStart;

    if ( uSuffixLen == 0 )
    {
        return True;
    }
    else if ( uSuffixLen > uSrcLen )
    {
        return False;
    }

    bResult = True;
    /* 这里可以保证两个字符串的长度都不为零，且源字符串的长度比后缀的要长 */
    for ( i = 0; i < uSuffixLen; i++ )
    {
        if ( pszSrc[uSrcLen - 1 - i] != pszSuffix[uSuffixLen - 1 - i] )
        {
            bResult = False;
            break;
        }
        else
        {
            bResult = True;
        }
    }

    return bResult;
}


Bool StrStartsWith(const char *pszSrc, const char *pszPrefix,
                   int nStart, int nEnd)
{
    size_t uStart, uEnd;
    size_t uLen = strlen(pszSrc);

    StrNormalizeIndex(uLen, nStart, nEnd, &uStart, &uEnd);

    if ( uStart >= uEnd )
    {
        /* 空字符串结果的索引 */
        if ( StrIsEmpty(pszPrefix) )
        {
            return True;
        }
        else
        {
            return False;
        }
    }
    else
    {
        /* 在切片子串中比较，这样的算法好处是无需先求出 pszPrefix 的长度 */
        size_t uCmpLen = uEnd - uStart;
        pszSrc += uStart;
        while ( *pszPrefix )
        {
            if ( uCmpLen == 0 )
            {
                /* 表示被比较的源字符串比 pszPrefix 字符串要短 */
                return False;
            }

            if ( *pszSrc != *pszPrefix )
            {
                return False;
            }
            pszSrc++;
            pszPrefix++;
            uCmpLen--;
        }

        /* 比较一直相同，直至结束 */
        return True;
    }
}


Bool StrIsAlNum(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsAlNum(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

Bool StrIsAlpha(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsAlpha(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

Bool StrIsDigit(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsDigit(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

Bool StrIsLower(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsLower(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

/* " \f\n\r\t\v" 都视为空白 */
Bool StrIsSpace(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsSpace(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

/* " \t"，与 Linux 系统一致，具体 man isblank */
Bool StrIsBlank(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsBlank(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

Bool StrIsTitle(const char *pszSrc);

Bool StrIsUpper(const char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( !IsUpper(*pszSrc) )
        {
            return False;
        }
        pszSrc++;
    }
    return True;
}

char ** StrSplitBySpace(const char *pszSrc)
{
    char **ppStrArray;
    size_t u;
    size_t i;
    size_t uLen;
    size_t uStart, uEnd;
    int nState;
    size_t uStrArraySize = STR_ARRAY_INIT_SIZE;

    ppStrArray = (char **)malloc(uStrArraySize * sizeof(char *));

    u = 0;
    uStart = 0;
    uEnd = 0;
    uLen = strlen(pszSrc);
    nState = 0; /* 寻找切片起点 */
    for ( i = 0; i < uLen; i++ )
    {
        if ( IsSpace(pszSrc[i]) )
        {
            /* 当前字符为空白，如果正在寻找切片终点，则切换提取字符串 */
            if ( nState == 1 )
            {
                nState = 0; /* 寻找切片起点 */
                uEnd = i;
                ppStrArray[u] = StrSlice(pszSrc, uStart, uEnd);
                u++;
                if ( u >= uStrArraySize - 2 )
                {
                    /* 需要再分配空间 */
                    uStrArraySize *= 2;
                    ppStrArray = realloc(ppStrArray,
                                         uStrArraySize * sizeof(char *));
                }
            }
        }
        else
        {
            /* 当前字符为非空白，如果正在寻找切片起点，则切换寻找状态 */
            if ( nState == 0 )
            {
                nState = 1; /* 寻找切片终点 */
                uStart = i;
            }
        }
    }

    if ( nState == 1 )
    {
        ppStrArray[u] = StrSliceToEnd(pszSrc, uStart);
        u++;
    }

    ppStrArray[u] = NULL;

    return ppStrArray;
}


char ** StrSplit(const char *pszSrc, const char *pszSep, int nMaxSplit)
{
    const char *pszTmp;
    size_t uSepLen;
    size_t uStart, uEnd;
    size_t u;
    int nSplitCount;
    char **ppStrArray;

    size_t uStrArraySize = STR_ARRAY_INIT_SIZE;

    uSepLen = strlen(pszSep);

    ppStrArray = (char **)malloc(uStrArraySize * sizeof(char *));
    if ( nMaxSplit <= 0 || uSepLen == 0 )
    {
        ppStrArray[0] = StrSliceToEnd(pszSrc, 0);
        ppStrArray[1] = NULL;
        return ppStrArray;
    }

    pszTmp = pszSrc;
    u = 0;
    nSplitCount = 0;
    uStart = 0;
    uEnd = 0;
    while ( (pszTmp = strstr(pszSrc + uStart, pszSep)) != NULL )
    {
        if ( nSplitCount >= nMaxSplit )
        {
            break;
        }

        uEnd = pszTmp - pszSrc;
        ppStrArray[u] = StrSlice(pszSrc, uStart, uEnd);
        uStart = uEnd + uSepLen;

        u++;
        if ( u >= uStrArraySize - 2 )
        {
            /* 需要再分配空间 */
            uStrArraySize *= 2;
            ppStrArray = realloc(ppStrArray, uStrArraySize * sizeof(char *));
        }

        nSplitCount++;
    }

    ppStrArray[u] = StrSliceToEnd(pszSrc, uStart);
    u++;
    ppStrArray[u] = NULL;

    return ppStrArray;
}


char ** StrSplitAll(const char *pszSrc, const char *pszSep)
{
    return StrSplit(pszSrc, pszSep, STR_MAX_32BIT_INT);
}


char * StrLStrip(const char *pszSrc, const char *pszChars)
{
    char *pszNew;
    size_t i;
    size_t uLen;
    size_t uStart;
    
    pszNew = StrDup(pszSrc);

    if ( StrIsEmpty(pszChars) )
    {
        return pszNew;
    }

    uLen = strlen(pszNew);
    uStart = 0;
    for ( i = 0; i < uLen; i++ )
    {
        if ( CharIsInChars(pszNew[i], pszChars) )
        {
            uStart++;
        }
    }

    memmove(pszNew, pszNew + uStart, uLen - uStart);
    pszNew[uLen - uStart] = '\0';

    return pszNew;
}


char * StrRStrip(const char *pszSrc, const char *pszChars)
{
    char *pszNew;
    size_t i;
    size_t uLen;
    size_t uEnd;
    
    pszNew = StrDup(pszSrc);

    if ( StrIsEmpty(pszChars) )
    {
        return pszNew;
    }

    uLen = strlen(pszNew);
    if ( uLen == 0 )
    {
        return pszNew;
    }

    uEnd = uLen;
    for ( i = uLen - 1; i >= 0; i-- )
    {
        if ( CharIsInChars(pszNew[i], pszChars) )
        {
            uEnd--;
        }
    }

    pszNew[uEnd] = '\0';

    return pszNew;
}


char * StrReplace(const char *pszSrc, const char *pszOld, const char *pszNew,
                  int nMaxReplace)
{
    size_t uStrRecordCount;
    size_t uSrcStrLen;
    size_t uOldStrLen;
    size_t uNewStrLen;
    size_t uResultLen;
    size_t uStart;
    size_t uEnd;
    size_t uLen;
    size_t i;
    const char *pszTmp;
    char *pszResult;
    int nReplaceCount;

    STR_RECORD **ppStrRecord;
    STR_RECORD *pStrRecord;
    size_t uStrRecordSize = STR_ARRAY_INIT_SIZE;

    ppStrRecord = (STR_RECORD **)malloc(uStrRecordSize * sizeof(STR_RECORD *));

    uSrcStrLen = strlen(pszSrc);
    uOldStrLen = strlen(pszOld);
    uNewStrLen = strlen(pszNew);
    uResultLen = 0;

    /* Step 1. 首先遍历源字符串 */
    uStrRecordCount = 0;
    nReplaceCount = 0;
    uStart = 0;
    uEnd = 0;
    while ( (pszTmp = strstr(pszSrc + uStart, pszOld)) != NULL )
    {
        if ( nReplaceCount >= nMaxReplace )
        {
            break;
        }

        uEnd = pszTmp - pszSrc;
        uLen = uEnd - uStart;

        /* 添加一个记录 */
        pStrRecord = (STR_RECORD *)malloc(sizeof(STR_RECORD));
        pStrRecord->pszStr = pszSrc + uStart;
        pStrRecord->uLen = uLen;
        uResultLen += uLen;
        ppStrRecord[uStrRecordCount] = pStrRecord;
        uStrRecordCount++;
        if ( uStrRecordCount >= uStrRecordSize - 1 )
        {
            /* 两倍分配 */
            uStrRecordSize *= 2;
            ppStrRecord = realloc(ppStrRecord, uStrRecordSize);
        }

        uStart = uEnd + uOldStrLen;

        nReplaceCount++;
    }

    uEnd = uSrcStrLen;
    /* 添加一个记录 */
    uLen = uEnd - uStart;
    pStrRecord = (STR_RECORD *)malloc(sizeof(STR_RECORD));
    pStrRecord->pszStr = pszSrc + uStart;
    pStrRecord->uLen = uLen;
    ppStrRecord[uStrRecordCount] = pStrRecord;
    uStrRecordCount++;
    uResultLen += uLen;

    uResultLen += nReplaceCount * uNewStrLen;

    pszResult = (char *)malloc(uResultLen + 1);

    uStart = 0;
    for ( i = 0; i < uStrRecordCount; i++ )
    {
        strncpy(pszResult + uStart, ppStrRecord[i]->pszStr, ppStrRecord[i]->uLen);
        uStart += ppStrRecord[i]->uLen;
        free(ppStrRecord[i]);

        if ( i < nReplaceCount )
        {
            strncpy(pszResult + uStart, pszNew, uNewStrLen);
            uStart += uNewStrLen;
        }
    }
    free(ppStrRecord);
    pszResult[uResultLen] = '\0';

    return pszResult;
}


char * StrReplaceAll(const char *pszSrc,
                     const char *pszOld, const char *pszNew)
{
    return StrReplace(pszSrc, pszOld, pszNew, STR_MAX_32BIT_INT);
}


void StrReplace2(const char *pszSrc, const char *pszOld, const char *pszNew,
                 int nMaxReplace, char *pszBuf, size_t uBufSize)
{
    size_t uOldStrLen;
    size_t uNewStrLen;
    size_t uResultLen;
    size_t uStart;
    size_t uEnd;
    size_t uCopyLen;
    const char *pszTmp;
    int nReplaceCount;

    if ( uBufSize == 0 )
    {
        return;
    }

    pszBuf[uBufSize - 1] = '\0';

    uOldStrLen = strlen(pszOld);
    uNewStrLen = strlen(pszNew);

    if ( uOldStrLen == 0 )
    {
        /* 空字符串不用替换，直接复制整个源字符串 */
        strncpy(pszBuf, pszSrc, uBufSize);
        return;
    }

    /* 一次遍历源字符串收工 */
    uStart = 0;
    uResultLen = 0;
    nReplaceCount = 0;
    while ( (pszTmp = strstr(pszSrc + uStart, pszOld)) != NULL )
    {
        if ( nReplaceCount >= nMaxReplace )
        {
            break;
        }

        uEnd = pszTmp - pszSrc;

        uCopyLen = uEnd - uStart;
        if ( uResultLen + uCopyLen >= uBufSize )
        {
            uCopyLen = uBufSize - uResultLen;
        }
        else
        {
            (pszBuf + uResultLen)[uCopyLen] = '\0';
        }
        strncpy(pszBuf + uResultLen, pszSrc + uStart, uCopyLen);
        uResultLen += uCopyLen;
        if ( uResultLen >= uBufSize )
        {
            /* 溢出了 */
            return;
        }

        uCopyLen = uNewStrLen;
        if ( uResultLen + uCopyLen >= uBufSize )
        {
            uCopyLen = uBufSize - uResultLen;
        }
        else
        {
            (pszBuf + uResultLen)[uCopyLen] = '\0';
        }
        strncpy(pszBuf + uResultLen, pszNew, uCopyLen);
        uResultLen += uCopyLen;
        if ( uResultLen >= uBufSize )
        {
            /* 溢出了 */
            return;
        }

        uStart = uEnd + uOldStrLen;
        nReplaceCount++;
    }

    if ( !StrIsEmpty(pszSrc + uStart) )
    {
        size_t uCopyLen = strlen(pszSrc + uStart);
        if ( uResultLen + uCopyLen >= uBufSize )
        {
            /* 缓冲区长度不足 */
            uCopyLen = uBufSize - uResultLen;
        }
        else
        {
            (pszBuf + uResultLen)[uCopyLen] = '\0';
        }
        strncpy(pszBuf + uResultLen, pszSrc + uStart, uCopyLen);
        uResultLen += uCopyLen;
    }

    return;
}


void StrReplaceAll2(const char *pszSrc, const char *pszOld, const char *pszNew,
                    char *pszBuf, size_t uBufSize)
{
    StrReplace2(pszSrc, pszOld, pszNew, STR_MAX_32BIT_INT, pszBuf, uBufSize);
}


/* ========================================================================== */
/* 直接修改传入的字符串的版本，不一定全部上述函数都有对应的版本 */
/* ========================================================================== */

/* 字符串切片，支持负数索引 */
void StrSliceMod(char *pszSrc, int nStart, int nEnd)
{
    size_t uStart, uEnd;
    size_t uLen;
    size_t uNewLen;

    uLen = strlen(pszSrc);
    StrNormalizeIndex(uLen, nStart, nEnd, &uStart, &uEnd);

    uStart = (uStart > uLen) ? uLen : uStart;
    uEnd = (uEnd > uLen) ? uLen : uEnd;

    if ( uEnd > uStart )
    {
        uNewLen = uEnd - uStart;
        memmove(pszSrc, pszSrc + uStart, uNewLen);
        pszSrc[uNewLen] = '\0';
    }
    else
    {
        pszSrc[0] = '\0';
    }
}

void StrSliceToEndMod(char *pszSrc, int nStart)
{
    StrSliceMod(pszSrc, nStart, STR_MAX_32BIT_INT);
}

void StrCapitalizeMod(char *pszSrc);

void StrLowerMod(char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( IsUpper(*pszSrc) )
        {
            *pszSrc = *pszSrc - 'A' + 'a';
        }
        pszSrc++;
    }
}

void StrLStripMod(char *pszSrc, const char *pszChars)
{
    size_t i;
    size_t uLen;
    size_t uStart;
    
    uLen = strlen(pszSrc);
    uStart = 0;
    for ( i = 0; i < uLen; i++ )
    {
        if ( CharIsInChars(pszSrc[i], pszChars) )
        {
            uStart++;
        }
        else
        {
            break;
        }
    }

    memmove(pszSrc, pszSrc + uStart, uLen - uStart);
    pszSrc[uLen - uStart] = '\0';
}

void StrRStripMod(char *pszSrc, const char *pszChars)
{
    size_t i;
    size_t uLen;
    size_t uEnd;
    
    uLen = strlen(pszSrc);
    if ( uLen == 0 )
    {
        return;
    }

    uEnd = uLen;
    for ( i = uLen - 1; i >= 0; i-- )
    {
        if ( CharIsInChars(pszSrc[i], pszChars) )
        {
            uEnd--;
        }
        else
        {
            break;
        }
    }

    pszSrc[uEnd] = '\0';
}

void StrStripMod(char *pszSrc, const char *pszChars)
{
    StrLStripMod(pszSrc, pszChars);
    StrRStripMod(pszSrc, pszChars);
}

void StrSwapCaseMod(char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( IsUpper(*pszSrc) )
        {
            *pszSrc = *pszSrc - 'A' + 'a';
        }
        else if ( IsLower(*pszSrc) )
        {
            *pszSrc = *pszSrc - 'a' + 'A';
        }
        pszSrc++;
    }
}

/*void StrTitleMod(char *pszSrc);*/

/*void StrTranslateMod(char *pszSrc);*/

void StrUpperMod(char *pszSrc)
{
    while ( *pszSrc )
    {
        if ( IsLower(*pszSrc) )
        {
            *pszSrc = *pszSrc - 'a' + 'A';
        }
        pszSrc++;
    }
}

void StrLStripSpaceMod(char *pszSrc)
{
    StrLStripMod(pszSrc, " \f\n\r\t\v");
}

void StrRStripSpaceMod(char *pszSrc)
{
    StrRStripMod(pszSrc, " \f\n\r\t\v");
}

void StrStripSpaceMod(char *pszSrc)
{
    StrLStripSpaceMod(pszSrc);
    StrRStripSpaceMod(pszSrc);
}


void StrCharsReplaceMod(char *pszSrc, const char *pszChars, char c)
{
    size_t uStart, uEnd;
    size_t uSavePos; /* 字符串移动的目标地址的起始索引 */
    size_t i;
    size_t uCopyLen;

    uStart = 0;
    uEnd = uStart;
    uSavePos = 0;
    for ( i = 0; pszSrc[i] != '\0'; i++ )
    {
        if ( CharIsInChars(pszSrc[i], pszChars) )
        {
        }
        else
        {
            uStart = i;

            if ( uStart > uEnd )
            {
                *(pszSrc + uSavePos) = c;
                uSavePos++;
            }

            /* 寻找 uEnd */
            for ( ; pszSrc[i] != '\0' ; i++ )
            {
                if ( CharIsInChars(pszSrc[i], pszChars) )
                {
                    uEnd = i;

                    /* 成功找到一段要复制的字符串 */
                    uCopyLen = uEnd - uStart;
                    memmove(pszSrc + uSavePos, pszSrc + uStart, uCopyLen);
                    uSavePos += uCopyLen;

                    uStart = uEnd;
                    break;
                }
            }

            /* 最后 */
            if ( i > uStart )
            {
                uCopyLen = i - uStart;
                memmove(pszSrc + uSavePos, pszSrc + uStart, i - uStart);
                uSavePos += uCopyLen;

                uEnd = i; /* 防止下面的"最后"多添加字符 */
                *(pszSrc + uSavePos) = '\0';
                break;
            }
        }
    }

    /* 最后 */
    if ( i > uEnd )
    {
        *(pszSrc + uSavePos) = c;
        uSavePos++;
        *(pszSrc + uSavePos) = '\0';
    }

    return;
}


void StrEscapeChars(const char *pszSrc, const char *pszChars,
                    char *pszBuf, size_t uBufSize)
{
    size_t uWriteLen;
    const char *psz = pszSrc;
    if ( uBufSize == 0 || StrIsEmpty(pszChars) )
    {
        return;
    }

    pszBuf[uBufSize - 1] = '\0';

    for ( uWriteLen = 0;
          uWriteLen < uBufSize && *psz != '\0';
          uWriteLen++, psz++ )
    {
        if ( CharIsInChars(*psz, pszChars) )
        {
            pszBuf[uWriteLen++] = '\\';
            if ( uWriteLen >= uBufSize )
            {
                /* 缓冲区不足 */
                break;
            }
        }
        pszBuf[uWriteLen] = *psz;
    }

    if ( uWriteLen < uBufSize )
    {
        pszBuf[uWriteLen] = '\0';
    }
}


void StrIterInit(StrIter *pStrIter, const char *pszSrc, size_t uMaxCount)
{
    pStrIter->pszSrc = pszSrc;
    pStrIter->uCurPos = 0;
    pStrIter->uCurCount = 0;
    pStrIter->uMaxCount = uMaxCount;
}

Bool StrIterLineNext(StrIter *pStrIter, Bool bKeepEnds,
                     char *pszBuf, size_t uBufSize)
{
    size_t i;
    size_t uEnd;
    size_t uNewStart;
    const char *pszStr;

    pszStr = pStrIter->pszSrc + pStrIter->uCurPos;
    if ( StrIsEmpty(pszStr) || uBufSize == 0 )
    {
        return False;
    }

    pszBuf[uBufSize - 1] = '\0'; /* 先假设缓冲区足够大 */

    uNewStart = pStrIter->uCurPos;
    uEnd = 0;
    /* 支持三种换行符，'\r\n', '\n', \r' */
    for ( i = 0; ; i++ )
    {
        if ( pszStr[i] == '\0' )
        {
            /* 到达字符串的最后 */
            uEnd = i;
            uNewStart = i;
            break;
        }
        else if ( pszStr[i] == '\r' )
        {
            if ( pszStr[i + 1] == '\0' )
            {
                /* 结束 */
                if ( bKeepEnds )
                {
                    uEnd = i + 1;
                }
                else
                {
                    uEnd = i;
                }
                uNewStart = i;
                break;
            }
            else
            {
                if ( pszStr[i + 1] == '\n' )
                {
                    /* '\r\n' 式换行，结束 */
                    if ( bKeepEnds )
                    {
                        uEnd = i + 2;
                    }
                    else
                    {
                        uEnd = i;
                    }
                    uNewStart = i + 2;
                    break;
                }
                else
                {
                    /* '\r' 式换行，结束 */
                    if ( bKeepEnds )
                    {
                        uEnd = i + 1;
                    }
                    else
                    {
                        uEnd = i;
                    }
                    uNewStart = i + 1;
                    break;
                }
            }
        }
        else if ( pszStr[i] == '\n' )
        {
            /* '\n' 式换行 */
            if ( bKeepEnds )
            {
                uEnd = i + 1;
            }
            else
            {
                uEnd = i;
            }
            uNewStart = i + 1;
            break;
        }
    }

    pStrIter->uCurPos += uNewStart;

    if ( uEnd > uBufSize )
    {
        /* 缓冲区不足以保存输出结果，由外部检查 */
        strncpy(pszBuf, pszStr, uEnd);
        return True;
    }
    else
    {
        strncpy(pszBuf, pszStr, uEnd);
        pszBuf[uEnd] = '\0';
        return True;
    }
}

Bool StrIterSerialLineNext(StrIter *pIter, char *pszBuf, size_t uBufSize)
{
    char *pszTmp;
    size_t uTmpBufSize;
    size_t uLen;
    Bool bResult;

    bResult = False;
    pszTmp = pszBuf;
    uTmpBufSize = uBufSize;
    while ( StrIterLineNext(pIter, False, pszTmp, uTmpBufSize) )
    {
        bResult = True;

        if ( IsBufferOverflow(pszTmp, uTmpBufSize) )
        {
			/* 缓冲区不足以装下返回的内容 */
            break;
        }

        if ( StrEndsWith(pszTmp, "\\", 0, STR_END_INDEX) )
        {
            /* 续行，继续迭代 */
            StrSliceMod(pszTmp, 0, -1); /* 删除最后的 '\\' */
            uLen = strlen(pszTmp);
            pszTmp += uLen;
            uTmpBufSize -= uLen;
        }
        else
        {
            /* 续行成功 */
            break;
        }
    }

    return bResult;
}

Bool StrIterSplitNext(StrIter *pIter, const char *pszSep,
                      char *pszBuf, size_t uBufSize)
{
    const char *pszTmp;
    size_t uSepLen;
    size_t uCopyLen;
    const char *psz;
    Bool bResult = False;

    psz = pIter->pszSrc + pIter->uCurPos;

    if ( uBufSize == 0 || pIter->uCurCount > pIter->uMaxCount
         || *psz == '\0' )
    {
        return False;
    }

    pszBuf[uBufSize - 1] = '\0';

    if ( pIter->uCurCount == pIter->uMaxCount )
    {
        /* 不再分割了 */
        uCopyLen = strlen(psz);
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        return True;
    }

    uSepLen = strlen(pszSep);

    pszTmp = strstr(psz, pszSep);
    if ( pszTmp != NULL )
    {
        uCopyLen = pszTmp - psz;
        pIter->uCurPos += uCopyLen + uSepLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }

        strncpy(pszBuf, psz, uCopyLen);

        bResult = True;
    }
    else if ( psz[0] != '\0' )
    {
        /* 后面没有分隔符，但是当前字符串非空，复制整个字符串 */
        uCopyLen = strlen(psz);
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        bResult = True;
    }

    return bResult;
}

Bool StrIterSplitBySpaceNext(StrIter *pIter, char *pszBuf, size_t uBufSize)
{
    size_t uStart, uEnd;
    size_t uCopyLen;
    const char *psz;
    Bool bResult = False;

    psz = pIter->pszSrc + pIter->uCurPos;

    if ( uBufSize == 0 || pIter->uCurCount > pIter->uMaxCount
         || *psz == '\0' )
    {
        return False;
    }

    pszBuf[uBufSize - 1] = '\0'; /* 先假设缓冲区足够大 */

    if ( pIter->uCurCount == pIter->uMaxCount )
    {
        /* 不再分割了 */
        uCopyLen = strlen(psz);
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        return True;
    }

    uStart = 0;
    uEnd = uStart;
    for ( ; psz[uEnd] != '\0'; uEnd++ )
    {
        if ( IsSpace(psz[uEnd]) )
        {
            if ( uEnd == uStart )
            {
                /* 表示要分割的字符串以空白开始，继续 */
                uStart++;
            }
            else
            {
                uCopyLen = uEnd - uStart;
                pIter->uCurPos += uEnd;
                pIter->uCurCount++;

                /* 跳至下一非空的位置 */
                while ( IsSpace(*(pIter->pszSrc + pIter->uCurPos)) )
                {
                    pIter->uCurPos++;
                }

                if ( uCopyLen >= uBufSize )
                {
                    /* 缓冲区不够的情况，由外部检查 */
                    uCopyLen = uBufSize;
                }
                else
                {
                    pszBuf[uCopyLen] = '\0';
                }
                strncpy(pszBuf, psz + uStart, uCopyLen);

                bResult = True;
                break;
            }
        }
    }

    if ( psz[uStart] != '\0' && psz[uEnd] == '\0' )
    {
        /* 没有找到分隔符，但是当前字符串非空，是最后的字符串了 */
        uCopyLen = uEnd - uStart;
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        bResult = True;
    }

    return bResult;
}


Bool StrIterSplitCCodeNext(StrIter *pIter, const char *pszSep,
                           char *pszBuf, size_t uBufSize)
{
    const char *pszTmp;
    size_t uSepLen;
    size_t uCopyLen;
    const char *psz;
    Bool bResult = False;

    psz = pIter->pszSrc + pIter->uCurPos;

    if ( uBufSize == 0 || pIter->uCurCount > pIter->uMaxCount
         || *psz == '\0' )
    {
        return False;
    }

    pszBuf[uBufSize - 1] = '\0';
    
    if ( pIter->uCurCount == pIter->uMaxCount )
    {
        /* 不再分割了 */
        uCopyLen = strlen(psz);
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        return True;
    }

    uSepLen = strlen(pszSep);

    pszTmp = strcstr(psz, pszSep);
    if ( pszTmp != NULL )
    {
        uCopyLen = pszTmp - psz;
        pIter->uCurPos += uCopyLen + uSepLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }

        strncpy(pszBuf, psz, uCopyLen);

        bResult = True;
    }
    else if ( psz[0] != '\0' )
    {
        /* 后面没有分隔符，但是当前字符串非空，复制整个字符串 */
        uCopyLen = strlen(psz);
        pIter->uCurPos += uCopyLen;
        pIter->uCurCount++;

        if ( uCopyLen >= uBufSize )
        {
            /* 缓冲区不足 */
            uCopyLen = uBufSize;
        }
        else
        {
            pszBuf[uCopyLen] = '\0';
        }
        strncpy(pszBuf, psz, uCopyLen);

        bResult = True;
    }

    return bResult;
}


const char * StrSearchCId(const char *pszSrc, size_t *puStart, size_t *puEnd)
{
    const char *psz, *pszTmp;
    const char *pszResult = NULL;

    psz = pszSrc;
    while ( *psz != '\0' )
    {
        if ( *psz == '"' )
        {
            /* 跳过字符串 */
            pszTmp = StrSkipCString(psz + 1);
            psz = (pszTmp != NULL) ? pszTmp : psz;
        }
        else if ( *psz == '\'' )
        {
            /* 跳过字符 */
            pszTmp = StrSkipCChar(psz + 1);
            psz = (pszTmp != NULL) ? pszTmp : psz;
        }
        else if ( *psz == '/' )
        {
            if ( psz[1] == '*' )
            {
                /* C 注释 */
                pszTmp = StrSkipCComment(psz + 2);
                /*if ( pszTmp == NULL ) [> 不完整的 C 注释，拒绝继续搜索 <]*/
                /*{*/
                    /*return NULL;*/
                /*}*/
                psz = (pszTmp != NULL) ? pszTmp : psz;
            }
            else if ( psz[1] == '/' )
            {
                /* C 行注释 */
                pszTmp = StrSkipCLineComment(psz + 2);
                if ( pszTmp[0] == '\0' )
                {
                    return NULL;
                }
                psz = pszTmp;
            }
        }

        /* *psz 前面的字符不能是 \w。eg. 1LL */
        if ( IsIdtfrS(*psz) 
             && !((psz - pszSrc) > 0 && IsIdtfr(*(psz - 1))) )
        {
            pszResult = psz;
            *puStart = psz - pszSrc;

            *puEnd = *puStart + 1;
            for ( ; *psz != '\0'; psz++ )
            {
                if ( !IsIdtfr(*psz) )
                {
                    *puEnd = psz - pszSrc;
                    break;
                }
            }
            if ( *psz == '\0' )
            {
                *puEnd = psz - pszSrc;
            }

            break;
        }

        psz++;
    }

    return pszResult;
}


Bool StrIterCCharNext(StrIter *pIter, char *pc)
{
    const char *psz, *pszTmp;
    Bool bResult = False;

    psz = pIter->pszSrc + pIter->uCurPos;
    if ( *psz != '\0' )
    {
        char c = *psz;
        pIter->uCurPos += 1;
        if ( c == '/' )
        {
            if ( psz[1] == '*' )
            {
                /* C 注释 */
                pszTmp = StrSkipCComment(psz + 2);
                psz = (pszTmp != NULL) ? pszTmp : psz;
                c = ' '; /* 注释替换成空格 */
                pIter->uCurPos = psz - pIter->pszSrc;
            }
            else if ( psz[1] == '/' )
            {
                /* C 行注释 */
                pszTmp = StrSkipCLineComment(psz + 2);
                psz = pszTmp;
                c = ' '; /* 注释替换成空格 */
                pIter->uCurPos = psz - pIter->pszSrc;
            }
        }

        *pc = c;
        bResult = True;
    }

    return bResult;
}


/* ========================================================================== */
/* ========================================================================== */
/* ========================================================================== */

void StrCCharsReplaceMod(char *pszSrc, const char *pszChars, char cRepl)
{
    char c;
    size_t uWriteLen;
    char *pszTmp;
    char *psz = pszSrc;
    uWriteLen = 0;

    if ( pszChars[0] == '\0' )
    {
        return;
    }

    while ( *psz != '\0' )
    {
        c = *psz;
        if ( c == '"' )
        {
            pszTmp = (char *)StrSkipCString(psz + 1);
            if ( pszTmp != NULL )
            {
                /*strncpy(pszSrc + uWriteLen, psz, pszTmp - psz);*/
                memmove(pszSrc + uWriteLen, psz, pszTmp - psz);
                uWriteLen += pszTmp - psz;
                psz = pszTmp;
                continue;
            }
        }
        else if ( c == '\'' )
        {
            pszTmp = (char *)StrSkipCChar(psz + 1);
            if ( pszTmp != NULL )
            {
                /*strncpy(pszSrc + uWriteLen, psz, pszTmp - psz);*/
                memmove(pszSrc + uWriteLen, psz, pszTmp - psz);
                uWriteLen += pszTmp - psz;
                psz = pszTmp;
                continue;
            }
        }

        if ( CharIsInChars(c, pszChars) )
        {
            pszSrc[uWriteLen++] = cRepl;
            for ( psz += 1; CharIsInChars(*psz, pszChars); psz++ )
            {
                /* 跳过连续的需要剔除的字符 */
            }
        }
        else
        {
            pszSrc[uWriteLen++] = c;
            psz++;
        }
    }
    pszSrc[uWriteLen++] = '\0';
}


/* 把 C 代码的两种注释替换成空格 */
void StrStripCAllComment(char *pszSrc)
{
    size_t uWriteLen = 0;
    char *psz = pszSrc, *pszTmp;
    while ( *psz != '\0' )
    {
        if ( *psz == '/' )
        {
            if ( psz[1] == '*' )
            {
                pszTmp = (char *)StrSkipCComment(psz + 2);
                psz = (pszTmp != NULL) ? pszTmp : psz;
                pszSrc[uWriteLen++] = ' ';
                continue;
            }
            else if ( psz[1] == '/' )
            {
                pszTmp = (char *)StrSkipCLineComment(psz + 2);
                if ( pszTmp[0] == '\0' )
                {
                    pszSrc[uWriteLen++] = ' ';
                    pszSrc[uWriteLen++] = '\0';
                    break;
                }
                pszSrc[uWriteLen++] = ' ';
                psz = pszTmp;
                continue;
            }
        }
        pszSrc[uWriteLen++] = *psz;
        psz++;
    }
    pszSrc[uWriteLen++] = '\0';
}


const char * StrSkipToNonSpace(const char *pszSrc)
{
    size_t i;
    for ( i = 0; pszSrc[i] != '\0'; i++ )
    {
        if ( !IsSpace(pszSrc[i]) )
        {
            break;
        }
    }

    return pszSrc + i;
}


const char * StrSkipCString(const char *pszSrc)
{
    size_t i;
    for ( i = 0; pszSrc[i] != '\0'; i++ )
    {
        if ( pszSrc[i] == '\\' )
        {
            i++;
        }
        else if ( pszSrc[i] == '"' )
        {
            return pszSrc + i + 1;
        }
    }

    return NULL;
}


const char * StrSkipCChar(const char *pszSrc)
{
    size_t i;
    for ( i = 0; pszSrc[i] != '\0'; i++ )
    {
        if ( pszSrc[i] == '\\' )
        {
            i++;
        }
        else if ( pszSrc[i] == '\'' )
        {
            return pszSrc + i + 1;
        }
    }

    return NULL;
}


/* 跳过 C 注释，如果找到结束字符，返回结束字符之后的位置，否则返回 NULL */
const char * StrSkipCComment(const char *pszSrc)
{
    const char *p = strstr(pszSrc, "*/");
    if ( p != NULL )
    {
        p += 2;
    }
    return p;
}

/* 跳过 C 行注释，如果找到换行符，返回换行符之后的位置，否则返回 '\0' 的位置 */
const char * StrSkipCLineComment(const char *pszSrc)
{
    const char *p = pszSrc;
    for ( ; *p != '\0' && *p != '\n'; p++ )
    {
    }
    return p;
}


const char * StrSkipCMatch(const char *pszSrc, const char *pszPair)
{
    size_t i;
    char cBegin, cEnd, uNest;
    Bool bBreak;
    const char *pszResult, *pszTmp;

    cBegin = pszPair[0];
    cEnd = pszPair[1];
    uNest = 1; /* 从 1 开始 */

    pszResult = NULL;

    bBreak = False;
    for ( i = 0; pszSrc[i] != '\0' && !bBreak; i++ )
    {
        switch ( pszSrc[i] )
        {
            case '"':
                pszTmp = StrSkipCString(pszSrc + i + 1);
                if ( pszTmp != NULL )
                {
                    i += pszTmp - (pszSrc + i + 1);
                }
                break;

            case '\'':
                pszTmp = StrSkipCChar(pszSrc + i + 1);
                if ( pszTmp != NULL )
                {
                    i += pszTmp - (pszSrc + i + 1);
                }
                break;

            default:
                if ( pszSrc[i] == cBegin )
                {
                    uNest += 1;
                }
                else if ( pszSrc[i] == cEnd )
                {
                    uNest -= 1;
                    if ( uNest == 0 )
                    {
                        pszResult = pszSrc + i + 1;
                        bBreak = True;
                    }
                }
                break;
        }
    }

    return pszResult;
}

/* ========================================================================== */
