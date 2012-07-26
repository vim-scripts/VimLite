#ifndef __FTSTRING_H__
#define __FTSTRING_H__


#ifdef __cplusplus
extern "C" {
#endif

#include "ftTypes.h"

/* 基本约定
 * 作为输出的缓冲区，正常情况下总会自动添加 '\0'，并且把缓冲区的最后位置为 '\0'
 * 当缓冲区末尾不是 '\0'，表示缓冲区不足以装下返回的内容，
 * 所以可以检查缓冲区尾部来检测是否可能存在缓冲区溢出问题 */

#define STR_MAX_32BIT_INT   2147483647

#define STR_END_INDEX       STR_MAX_32BIT_INT

#define STR_MAX_SPLIT       STR_MAX_32BIT_INT

#define STR_MAX_REPLACE     STR_MAX_32BIT_INT

#define STR_SPACE_CHARS     " \f\n\r\t\v"

/* 字符串迭代器 */
typedef struct StrIter_st {
    const char *pszSrc;
    size_t uCurPos;
    size_t uCurCount;
    size_t uMaxCount;
} StrIter;


/* ========================================================================== */
/* 单字符判断宏 */
/* ========================================================================== */

#define IsUpper(c) ((c) >= 'A' && (c) <= 'Z')
#define IsLower(c) ((c) >= 'a' && (c) <= 'z')
#define IsAlpha(c) (IsUpper(c) || IsLower(c))
#define IsDigit(c) ((c) >= '0' && (c) <= '9')
#define IsSpace(c) \
    ((c) == ' ' || (c) == '\f' || (c) == '\n' || \
     (c) == '\r' || (c) == '\t' || (c) == '\v')
#define IsBlank(c) ((c) == ' ' || (c) == '\t')
#define IsAlNum(c) (IsAlpha(c) || IsDigit(c))

#define ToUpper(c) (IsLower(c) ? ((c) - 'a' + 'A') : (c))
#define ToLower(c) (IsUpper(c) ? ((c) - 'A' + 'a') : (c))

#define IsIdtfrS(c) (IsAlpha(c) || (c) == '_')
#define IsIdtfr(c) (IsAlNum(c) || (c) == '_')

#define freev(pp) StrArrayFree(pp)

#define IsBufferOverflow(buf, size) ((buf)[(size) - 1] != '\0')

/* 字符串数组，以 NULL 标识边界 */
typedef char ** StrArray;

/* 获取字符串数组的长度 */
size_t StrArrayLen(char **ppStrArray);

/* 释放字符串数组 */
void StrArrayFree(char **ppStrArray);

/* ========================================================================== */
/* 变种函数 */
/* ========================================================================== */

/* 复制 pszSrc 字符串到 pszDst，返回复制成功的数目，始终不会自动添加 '\0'
 * 返回复制的字符串的计数，uSize 不足以存放 pszSrc，只复制 uSize 个字符
 */
/*size_t StrCpyMod(char *pszDst, size_t uSize, const char *pszSrc);*/

/* ========================================================================== */
/* 对应 python string 的基本操作 */
/* ========================================================================== */

#if 0
Bool StrIsEmpty(const char *pszSrc);
#else
#define StrIsEmpty(pszSrc) ((pszSrc)[0] == '\0')
#endif

#if 0
Bool StrIsEqual(const char *psz1, const char *psz2);
#else
#define StrIsEqual(psz1, psz2) (strcmp(psz1, psz2) == 0)
#endif

Bool StrIsEqualIC(const char *psz1, const char *psz2);

int StrCmp(const char *psz1, const char *psz2);

/* 忽略大小写比较两个字符串 */
int StrCmpIC(const char *psz1, const char *psz2);

char * StrAdd(const char *psz1, const char *psz2);

char * StrDup(const char *pszSrc);

/* 字符串切片，支持负数索引 */
char * StrSlice(const char *pszSrc, int nStart, int nEnd);

char * StrSliceToEnd(const char *pszSrc, int nStart);

size_t StrLen(const char *pszSrc);

char * StrCapitalize(const char *pszSrc);

char * StrCenter(size_t uWidth, char cFillchar);

size_t StrCount(const char *pszSrc, const char *pszSub);

Bool StrEndsWith(const char *pszSrc, const char *pszSuffix,
                 int nStart, int nEnd);

char * StrExpandTabs(const char *pszSrc, size_t uTabSize);

/* 返回指定范围字符串中匹配 pszSub 的最小索引 */
int StrFind(const char *pszSrc, const char *pszSub, int nStart, int nEnd);

/* 同 StrFind */
/*int StrIndex(const char *pszSrc, const char *pszSub, int nStart, int nEnd);*/

Bool StrIsAlNum(const char *pszSrc);

Bool StrIsAlpha(const char *pszSrc);

Bool StrIsDigit(const char *pszSrc);

Bool StrIsLower(const char *pszSrc);

/* " \f\n\r\t\v" 都视为空白 */
Bool StrIsSpace(const char *pszSrc);

/* " \t"，与 Linux 系统一致，具体 man isblank */
Bool StrIsBlank(const char *pszSrc);

Bool StrIsTitle(const char *pszSrc);

Bool StrIsUpper(const char *pszSrc);

char * StrJoin(const char *pszSep, const char **ppStrArray);

/* s = "abc"; s.ljust(10, x) -> "abcxxxxxxx"  */
char * StrLJust(const char *pszSrc, size_t uWidth, char cFillChar);

char * StrLower(const char *pszSrc);

char * StrLStrip(const char *pszSrc, const char *pszChars);

/* StrPartition("abc  xyz", " ") -> ["abc", "", " xyz"] */
char ** StrPartition(const char *pszSrc, const char *pszSep);

/* 字符串替换 */
char * StrReplace(const char *pszSrc, const char *pszOld, const char *pszNew,
                  int nMaxReplace);

char * StrReplaceAll(const char *pszSrc,
                     const char *pszOld, const char *pszNew);

int StrRFind(const char *pszSrc, const char *pszSub, int nStart, int nEnd);

int StrRIndex(const char *pszSrc, const char *pszSub, int nStart, int nEnd);

char * StrRJust(const char *pszSrc, size_t uWidth, char cFillChar);

char ** StrRPartition(const char *pszSrc, const char *pszSep);

char ** StrRSplit(const char *pszSrc, const char *pszSep, int nMaxSplit);
char ** StrRSplitAll(const char *pszSrc, const char *pszSep);

char * StrRStrip(const char *pszSrc, const char *pszChars);

char ** StrSplit(const char *pszSrc, const char *pszSep, int nMaxSplit);
char ** StrSplitAll(const char *pszSrc, const char *pszSep);

char ** StrSplitLines(const char *pszSrc, Bool bKeepEnds);

Bool StrStartsWith(const char *pszSrc, const char *pszPrefix,
                   int nStart, int nEnd);

char * StrStrip(const char *pszSrc, const char *pszChars);

char * StrSwapCase(const char *pszSrc);

char * StrTitle(const char *pszSrc);

#if 0
char * StrTranslate(const char *pszSrc);
#endif

char * StrUpper(const char *pszSrc);

/* 填充 "0" 到字符串的左边，uWidth 指定最终的字符串的长度 */
char * StrZFill(const char *pszSrc, size_t uWidth);


/* ========================================================================== */
/* 特殊行为的函数 */
/* ========================================================================== */

char * StrLStripSpace(const char *pszSrc);
char * StrRStripSpace(const char *pszSrc);
char * StrStripSpace(const char *pszSrc);

/* 以任意空白为分割符分割字符串，并把结果中所有的空字符串删除 */
char ** StrSplitBySpace(const char *pszSrc);

/* 以任意空白为分割符从右边分割字符串，并把结果中所有的空字符串删除 */
char ** StrRSplitBySpace(const char *pszSrc);

/* ========================================================================== */
/* 使用缓冲区作为输出的版本 */
/* ========================================================================== */

void StrReplace2(const char *pszSrc, const char *pszOld, const char *pszNew,
                 int nMaxReplace, char *pszBuf, size_t uBufSize);

void StrReplaceAll2(const char *pszSrc, const char *pszOld, const char *pszNew,
                    char *pszBuf, size_t uBufSize);


/* ========================================================================== */
/* 直接修改传入的字符串的版本，不一定全部上述函数都有对应的版本 */
/* ========================================================================== */

/* 字符串切片，支持负数索引 */
void StrSliceMod(char *pszSrc, int nStart, int nEnd);

void StrSliceToEndMod(char *pszSrc, int nStart);

#if 0
void StrCapitalizeMod(char *pszSrc);
#endif

void StrLowerMod(char *pszSrc);

void StrLStripMod(char *pszSrc, const char *pszChars);

void StrRStripMod(char *pszSrc, const char *pszChars);

void StrStripMod(char *pszSrc, const char *pszChars);

void StrSwapCaseMod(char *pszSrc);

#if 0
void StrTitleMod(char *pszSrc);
#endif

#if 0
void StrTranslateMod(char *pszSrc);
#endif

void StrUpperMod(char *pszSrc);

void StrLStripSpaceMod(char *pszSrc);
void StrRStripSpaceMod(char *pszSrc);
void StrStripSpaceMod(char *pszSrc);

/* 亦即模拟正则表达式中的 substitute(s, '[xxx]', 'y', 'g')，某些时候用到 */
void StrCharsReplaceMod(char *pszSrc, const char *pszChars, char c);

/* 替换所有连续的空白为单个空格 */
#define StrCompactSpace(pszSrc) StrCharsReplaceMod(pszSrc, " \f\n\r\t\v", ' ')

void StrEscapeChars(const char *pszSrc, const char *pszChars,
					char *pszBuf, size_t uBufSize);

/* ========================================================================== */
/* 迭代函数 */
/* ========================================================================== */

void StrIterInit(StrIter *pStrIter, const char *pszSrc, size_t uMaxCount);

#define StrIterLineInit(pIter, psz) \
    StrIterInit(pIter, psz, 0)
Bool StrIterLineNext(StrIter *pStrIter, Bool bKeepEnds,
					 char *pszBuf, size_t uBufSize);

#define StrIterSerialLineInit(pIter, psz) \
    StrIterInit(pIter, psz, 0)
Bool StrIterSerialLineNext(StrIter *pStrIter, char *pszBuf, size_t uBufSize);

#define StrIterSplitInit(pIter, psz, uMaxSplit) \
    StrIterInit(pIter, psz, uMaxSplit)
Bool StrIterSplitNext(StrIter *pIter, const char *pszSep,
                      char *pszBuf, size_t uBufSize);

/* NOTE: 当计数分割的时候，源字符串的左则和右侧的空白不计入分割计数
 *       即如左则和右侧的空白被剔除了一样 */
#define StrIterSplitBySpaceInit(pIter, psz, uMaxSplit) \
    StrIterInit(pIter, psz, uMaxSplit)
Bool StrIterSplitBySpaceNext(StrIter *pStrIter, char *pszBuf, size_t uBufSize);

/* 分割 C 代码，注释、字符、字符串里面的分隔符被忽略 */
#define StrIterSplitCCodeInit(pIter, psz, uMaxSplit) \
    StrIterInit(pIter, psz, uMaxSplit)
Bool StrIterSplitCCodeNext(StrIter *pStrIter, const char *pszSep,
                           char *pszBuf, size_t uBufSize);

/* 迭代获取 C 源代码字符串中的字符，透明化注释 */
#define StrIterCCharInit(pIter, psz) \
    StrIterInit(pIter, psz, STR_MAX_32BIT_INT)
Bool StrIterCCharNext(StrIter *pStrIter, char *pc);

/* ========================================================================== */
/* C 源码处理函数 */
/* ========================================================================== */
/* StrSkipXXX (不包括 StrSkipToNon)系列函数的输入参数必须是相应的起始匹配字符之
 * 后的一个位置，例如 StrSkipCString()，输入参数必须是起始双引号之后的字符串 */

/* 亦即模拟正则表达式中的 substitute(s, '[xxx]', 'y', 'g')，某些时候用到
 * 不处理 C 的字符和字符串里面的内容 */
void StrCCharsReplaceMod(char *pszSrc, const char *pszChars, char c);
#define StrCompactCSpace(pszSrc) StrCCharsReplaceMod(pszSrc, " \f\n\r\t\v", ' ')

/* 把 C 代码的两种注释替换成空格 */
void StrStripCAllComment(char *pszSrc);

/* 搜索字符串的 C 标识符，忽略注释、字符、字符串里面的内容
 * 若搜索失败返回 NULL */
const char * StrSearchCId(const char *pszSrc, size_t *puStart, size_t *puEnd);

/* 跳到非空字符位置 */
const char * StrSkipToNonSpace(const char *pszSrc);

/* 跳过 C 字符串的字符串，pszSrc 为 '"' 之后的字符串，如没有找到，返回 NULL */
const char * StrSkipCString(const char *pszSrc);

/* 跳过 C 字符串的字符，pszSrc 为 '\'' 之后的字符串，如没有找到，返回 NULL */
const char * StrSkipCChar(const char *pszSrc);

/* 跳过 C 注释，如果找到结束字符，返回结束字符之后的位置，否则返回 NULL */
const char * StrSkipCComment(const char *pszSrc);

/* 跳过 C 行注释，如果找到换行符，返回换行符之后的位置，否则返回 '\0' 的位置 */
const char * StrSkipCLineComment(const char *pszSrc);

/* 跳过 C 字符串的匹配，pszSrc 为 pszPair[0] 之后的字符串，
 * 如没有找到，返回 NULL */
const char * StrSkipCMatch(const char *pszSrc, const char *pszPair);

#ifdef __cplusplus
}
#endif


#endif /* __FTSTRING_H__ */
