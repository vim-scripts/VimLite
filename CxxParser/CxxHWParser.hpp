// 手写的 C++ 语法分析器

#ifndef __CXXHWPARSER_HPP__
#define __CXXHWPARSER_HPP__

#include <set>
#include <string>
#include "CxxParserCommon.hpp"
#include "CxxTokenReader.hpp"

typedef std::set<int> IntSet;

CxxToken SkipToToken(CxxTokenReader &tokRdr, int tokid,
                     std::list<CxxToken> *pCollector = NULL);
CxxToken SkipToOneOf(CxxTokenReader &tokRdr, const IntSet &ints,
                     std::list<CxxToken> *pCollector = NULL);
// 跳至指定 token 中的其中一个，但是出了在 left 和 right 里面的 token
// 例如 (int i, A<B, C> a, int j); B 和 C 之间的 ',' 不算
CxxToken SkipToOneOf(CxxTokenReader &tokRdr, const IntSet &ints,
                     int left, int right,
                     std::list<CxxToken> *pCollector = NULL);
void SkipToMatch(CxxTokenReader &tokRdr, int left, int right,
                 std::list<CxxToken> *pCollector = NULL);

typedef struct CxxHWParser_st {
    void *p;      // 测试
} CxxHWParser;

typedef struct CxxOmniResult_st {
    char *pszSearchScopes;
} CxxOmniResult;

// 解析不含模板的类型，例如 A::B::C;
// 用于 using 之类的语句
// 解析错误返回空字符串
std::string CxxParseNonTemplateType(CxxTokenReader &tokRdr);

std::string GetScopeStack(CxxTokenReader &tokRdr, std::list<CxxScope> scopes);

// 导出的 C 函数
extern "C" void * CxxHWParser_Create(const char *pszSymbolDBFile);
extern "C" void CxxHWParser_Destroy(void *pParser);
extern "C" void * CxxOmniCpp_Create(void *pParser, const char *buffer);
extern "C" void CxxOmniCpp_Destroy(void *pOmniCppResult);
extern "C" const char * CxxOmniCpp_GetSearchScopes(void *pOmniCppResult);

extern "C" char * GetScopeStack(const char *buffer);


#endif /* __CXXHWPARSER_HPP__ */
