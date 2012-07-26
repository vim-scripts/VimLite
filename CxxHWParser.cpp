#include <iostream>
#include <string>
#include <string.h>
#include "pystring.h"
#include "CxxHWParser.hpp"
#include "Utils.hpp"
#include "CxxParseType.hpp"

using namespace std;
using namespace pystring;

// 跳至指定的 token
CxxToken SkipToToken(CxxTokenReader &tokRdr, int tokid,
                     std::list<CxxToken> *pCollector)
{
    CxxToken tok;
    while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
    {
        if ( pCollector != NULL )
        {
            pCollector->push_back(tok);
        }
        if ( tok.id == tokid )
        {
            break;
        }
    }
    return tok;
}

// 跳至指定 token 中的其中一个
// 返回停止的那个 token
CxxToken SkipToOneOf(CxxTokenReader &tokRdr, const IntSet &ints,
                     std::list<CxxToken> *pCollector)
{
    CxxToken tok;
    while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
    {
        if ( pCollector != NULL )
        {
            pCollector->push_back(tok);
        }
        if ( ints.find(tok.id) != ints.end() )
        {
            break;
        }
    }
    return tok;
}

// 跳至指定 token 中的其中一个，但是出了在 left 和 right 里面的 token
// 例如 (int i, A<B, C> a, int j); B 和 C 之间的 ',' 不算
// 返回停止的那个 token
CxxToken SkipToOneOf(CxxTokenReader &tokRdr, const IntSet &ints,
                     int left, int right,
                     std::list<CxxToken> *pCollector)
{
    int nestLv = 0;
    CxxToken tok;
    while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
    {
        if ( pCollector != NULL )
        {
            pCollector->push_back(tok);
        }

        if ( tok.id == left )
        {
            nestLv += 1;
        }
        else if ( tok.id == right )
        {
            nestLv -= 1;
        }

        if ( nestLv == 0 && ints.find(tok.id) != ints.end() )
        {
            break;
        }
    }

    return tok;
}

// 跳至指定的匹配，tokRdr 读取的下一个 token 为 left 的下一个
void SkipToMatch(CxxTokenReader &tokRdr, int left, int right,
                 std::list<CxxToken> *pCollector)
{
    int nestLv = 1;
    CxxToken tok;
    while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
    {
        if ( pCollector != NULL )
        {
            pCollector->push_back(tok);
        }
        if ( tok.id == left )
        {
            nestLv += 1;
        }
        else if ( tok.id == right )
        {
            nestLv -= 1;
        }

        if ( nestLv == 0 )
        {
            break;
        }
    }
}

std::string CxxParseNonTemplateType(CxxTokenReader &tokRdr)
{
    string result;
    CxxToken tok = tokRdr.GetToken();
    int state = 0; // 0 要 ::，1 要单词
    if ( tok.IsWord() )
    {
        state = 1;
    }

    while ( tok.IsValid() && tok.id != CXX_OP_Semicolon )
    {
        if ( tok.IsWord() )
        {
            if ( state == 1 )
            {
                result += tok.text;
                state = 0; // 要 ::
            }
            else
            {
                goto syntax_error;
            }
        }
        else if ( tok.id == CXX_OP_ColonColon )
        {
            if ( state == 0 )
            {
                result += tok.text;
                state = 1; // 要单词
            }
            else
            {
                goto syntax_error;
            }
        }
        tok = tokRdr.GetToken();
    }

    if ( pystring::endswith(result, "::") )
    {
        goto syntax_error;
    }

    return result;

syntax_error:
    return "";
}

// 解析成功返回 0，否则返回 -1
int CxxParseNamespaceInfo(CxxTokenReader &tokRdr, NSInfo &nsinfo)
{
    CxxToken tok;

    tok = tokRdr.GetToken();
    if ( tok.id == CXX_KW_using )
    {
        if ( tokRdr.PeekToken().id == CXX_KW_namespace )
        {
            // using namespace a::b;
            tokRdr.GetToken();
            string s = CxxParseNonTemplateType(tokRdr);
            if ( s.empty() )
            {
                goto syntax_error;
            }
            nsinfo.AddUsingNamespace(s);
        }
        else
        {
            // using a::b;
            string s = CxxParseNonTemplateType(tokRdr);
            if ( s.empty() )
            {
                goto syntax_error;
            }
            nsinfo.AddUsing(s);
        }
    }
    else if ( tok.id == CXX_KW_namespace )
    {
        // namespace a = b::c;
        std::string s1, s2;
        tok = tokRdr.GetToken();
        if ( tok.IsWord() )
        {
            s1 = tok.text;
            tok = tokRdr.GetToken();
            if ( tok.id == CXX_OP_Equal )
            {
                s2 = CxxParseNonTemplateType(tokRdr);
                if ( s2.empty() )
                {
                    goto syntax_error;
                }
                nsinfo.AddNamespaceAlias(s1, s2);
            }
        }
    }
    else
    {
        goto syntax_error;
    }

    return 0;

syntax_error:
    return -1;
}

// 为了提高一点总体效率，简单地排除不可能是变量声明/定义的情况
static bool IsVarDeclOrDefi(std::list<CxxToken> &stmtToks)
{
    if ( stmtToks.empty() )
    {
        return false;
    }

    CxxToken firstToken = stmtToks.front();

    if ( firstToken.id == CXX_KW_if || firstToken.id == CXX_KW_else
         || firstToken.id == CXX_KW_while || firstToken.id == CXX_KW_switch )
    {
        return false;
    }

    // 寻找变量声明特征词
    // storage 修饰
    /* storage-class-specifier:
        auto            Removed in C++0x
        register
        static
        thread_local    C++0x
        extern
        mutable

       const volatile
    */
    if ( firstToken.id == CXX_KW_auto || firstToken.id == CXX_KW_register
         || firstToken.id == CXX_KW_static || firstToken.id == CXX_KW_thread_local
         || firstToken.id == CXX_KW_extern || firstToken.id == CXX_KW_mutable
         || firstToken.id == CXX_KW_const || firstToken.id == CXX_KW_volatile )
    {
        // 很大可能是变量声明，但是也可能是函数声明
        return true;
    }

    return true;
}

// 自动解析语句中的变量声明/定义，并添加到 scope
// struct SA { int n; } sa; // <- 这种比较麻烦
// struct SB sb, sc = {,}, sd;
// union enum class 都支持如上形式
// A va;
// A vb = x + y - z;
// A<B> vc(x, y);
// A<B> a, b, c = x, d;
void DetermineVariable(std::list<CxxToken> &stmtToks, CxxScope &scope)
{
    CxxTokenReader tokRdr;
    tokRdr.Init(stmtToks);
    list<CxxVar> varCache; // 变量暂存

    // ';' 和 ','
    IntSet ints;
    ints.insert(CXX_OP_Semicolon);
    ints.insert(CXX_OP_Comma);

    CxxToken peekTok = tokRdr.PeekToken();
    // 处理以下两种情况
    // struct SA { int n; } sa; // <- 这种比较麻烦，不是在这里处理的
    // struct AB sb = {,}, sc;
    if ( peekTok.id == CXX_KW_class || peekTok.id == CXX_KW_struct
         || peekTok.id == CXX_KW_union || peekTok.id == CXX_KW_enum )
    {
        tokRdr.GetToken();
    }

    CxxType type = CxxParseType(tokRdr);
    if ( type.IsError() )
    {
        return;
    }

    int line = stmtToks.front().lineno;
    CxxVar var;
    var.type = type;
    var.line = line;
    CxxToken tok;

    do
    {
        while ( tok = tokRdr.GetToken(), tok.IsValid() )
        {
            // * & const 这三个 token 直接跳过并继续
            if ( tok.id == CXX_OP_Mul || tok.id == CXX_OP_And
                 || tok.id == CXX_KW_const )
            {
                continue;
            }
            break;
        }
        if ( !tok.IsWord() )
        {
            goto error;
        }
        var.name = tok.text;
        // 简单地检查到底是函数声明还是变量定义
        if ( tokRdr.PeekToken().id == CXX_OP_LParen ) // A<B> a(x, y);
        {
            tokRdr.GetToken(); // '('
            tok = tokRdr.GetToken();
            // 类声明定义的判断相当复杂
            // X x((const void *)a.b()->c, x * 20);
            CxxType t = CxxParseType(tokRdr);
            if ( t.IsError() )
            {
                // 解析类型出错的话，应该就不是函数了
                // 跳到右括号处，亦即初始化结束处
                SkipToMatch(tokRdr, CXX_OP_LParen, CXX_OP_RParen);
            }
            else // 继续判断
            {
                // 跳过 '&'
                while ( tokRdr.PeekToken().id == CXX_OP_And )
                {
                    tokRdr.GetToken();
                }
                // 跳过 '*'
                while ( tokRdr.PeekToken().id == CXX_OP_Mul )
                {
                    tokRdr.GetToken();
                }
                // void func(const A & a)
                if ( tokRdr.PeekToken().IsWord() )
                {
                    tokRdr.GetToken();
                    if ( tokRdr.PeekToken().id == CXX_OP_Comma
                         || tokRdr.PeekToken().id == CXX_OP_RParen )
                    {
                        goto error;
                    }
                }
                // 到这里表示很大几率是变量声明/定义
                // 当然，要绝对准确的话，得分析实际参数到底是变量名还是类型名，
                // 这需要上下文信息，不做这么复杂
                // 跳到匹配的右括号
                SkipToMatch(tokRdr, CXX_OP_LParen, CXX_OP_RParen);
                tok = tokRdr.GetToken();
                if ( tok.id == CXX_OP_Semicolon || tok.id == CXX_OP_Comma )
                {
                    // 继续下面的流程
                }
                else
                {
                    // 语法错误
                    goto error;
                }
            }
        }
        varCache.push_back(var);
        // 处理如此形式: A<B> a, b(x, y), c;
        while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
        {
            if ( tok.id == CXX_OP_LParen )
            {
                SkipToMatch(tokRdr, CXX_OP_LParen, CXX_OP_RParen);
                continue;
            }
            else if ( tok.id == CXX_OP_LBrace )
            {
                SkipToMatch(tokRdr, CXX_OP_LBrace, CXX_OP_RBrace);
                continue;
            }
            if ( ints.find(tok.id) != ints.end() )
            {
                break;
            }
        }
    } while ( tok.id == CXX_OP_Comma );

end:
    for ( list<CxxVar>::iterator it = varCache.begin();
          it != varCache.end(); ++it )
    {
        scope.AddVar(*it);
    }

error:
    return;
}

void PrintStmtToks(const std::list<CxxToken> &stmtToks)
{
    if ( stmtToks.empty() )
    {
        return;
    }
    list<CxxToken>::const_iterator it = stmtToks.begin();
    cout << it->lineno << ":" << it->text;
    for ( ++it; it != stmtToks.end(); ++it )
    {
        cout << " " << it->text;
    }
    cout << endl;
}

// scopes 是输出
std::string GetScopeStack(CxxTokenReader &tokRdr, std::list<CxxScope> scopes)
{
    string errmsg;
    CxxToken tok;
    list<CxxToken> stmtToks; // 当前语句的字符串
    bool singleStmtScope = false; // for(;;); 的单句 scope
    string output;
    CxxScope *pCurScope = NULL; // 当前 scope 的指针
    CxxScope fileScope;
    fileScope.SetKind(CxxScope::CXXSCOPE_FILE);
    scopes.push_back(fileScope);
    pCurScope = &scopes.back();
    while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
    {
        stmtToks.push_back(tok);
        if ( tok.id == CXX_OP_LBrace ) // 进入一个新的 scope
        {
            // 要用到 '{' 的情况有几种的，例如 struct s s={,}; 特征是 '='
            CxxToken prevTok;
            list<CxxToken>::reverse_iterator rit = stmtToks.rbegin();
            ++rit;
            if ( rit != stmtToks.rend() )
            {
                prevTok = *rit;
            }

            if ( prevTok.id == CXX_OP_Equal )
            {
                // 不是一个块的开始，跳到匹配的 '}'
                SkipToMatch(tokRdr, CXX_OP_LBrace, CXX_OP_RBrace, &stmtToks);
                continue;
            }
            else // (1) 一个作用块的开始
            {
                CxxScope scope;
                // 删除尾随的 '{'
                if ( stmtToks.back().id == CXX_OP_LBrace )
                {
                    stmtToks.pop_back();
                }
                scope.SetStmtToks(stmtToks);
                //cout << "push"; PrintStmtToks(stmtToks);
                scopes.push_back(scope);
                pCurScope = &scopes.back();

                // 这里就有可能要分析变量声明了，例如 for 和函数定义
                if ( stmtToks.front().id == CXX_KW_for )
                {
                    list<CxxToken> tmpToks = stmtToks;
                    tmpToks.pop_front(); // 扔掉 "for"
                    tmpToks.pop_front(); // 扔掉 '{'
                    if ( IsVarDeclOrDefi(tmpToks) )
                    {
                        DetermineVariable(tmpToks, *pCurScope);
                    }
                }
                else // 试一下是否一个函数定义，简单地判断是否有括号即可？！
                {
                    list<list<CxxToken> > decls; // 函数实参列表
                    list<CxxToken> toks;
                    CxxTokenReader tmpTokRdr;
                    tmpTokRdr.Init(stmtToks);
                    CxxToken tmpPrevTok; // 上一个 token，用来实现向前看来预测
                    CxxToken tmpTok;
                    IntSet commaNrparen;
                    commaNrparen.insert(CXX_OP_Comma);
                    commaNrparen.insert(CXX_OP_RParen);
                    for ( ; (tmpTok = tmpTokRdr.GetToken(), tmpTok.IsValid());
                          tmpPrevTok = tmpTok )
                    {
                        if ( tmpTok.id == CXX_OP_LParen )
                        {
                            if ( !tmpPrevTok.IsWord() )
                            {
                                // if else while switch 之类的
                                break;
                            }
                            do
                            {
                                toks.clear();
                                tmpTok = SkipToOneOf(tmpTokRdr, commaNrparen,
                                                     CXX_OP_LT, CXX_OP_GT,
                                                     &toks);
                                if ( tmpTok.IsValid() )
                                {
                                    // 成功提取一个变量声明
                                    int line = toks.back().lineno;
                                    toks.pop_back();
                                    toks.push_back(CxxToken(";", line));
                                    decls.push_back(toks);
                                }
                            } while ( tmpTok.IsValid() );
                            break; // 都要跳出去
                        }
                    }
                    for ( list<list<CxxToken> >::iterator it = decls.begin();
                          it != decls.end(); ++it )
                    {
                        if ( IsVarDeclOrDefi(*it) )
                        {
                            DetermineVariable(*it, *pCurScope);
                        }
                    }
                }
            }
        }
        else if ( tok.id == CXX_OP_RBrace ) // 退出一个 scope
        {
            if ( scopes.empty() )
            {
                // 语法错误
                goto syntax_error;
            }

            // 遇到 '}' 要处理如下情况: struct Sa {int n;} sa;
            if ( !pCurScope->GetStmtToks().empty() )
            {
                CxxTokenReader tmpTokRdr;
                tmpTokRdr.Init(pCurScope->GetStmtToks());
                CxxToken tmpTok = tmpTokRdr.GetToken();
                if ( tmpTok.id == CXX_KW_class || tmpTok.id == CXX_KW_struct
                     || tmpTok.id == CXX_KW_union || tmpTok.id == CXX_KW_enum )
                {
                    tmpTok = tmpTokRdr.GetToken();
                    // scope 的 stmtToks 最后的 '{' 已经在加入 scopes 前被剔除
                    if ( tmpTok.IsWord() && tmpTokRdr.PeekToken().IsEOF() )
                    {
                        stmtToks.pop_back(); // 扔掉 '}'
                        // 拼接并且跳至 ';'
                        list<CxxToken> tmp = pCurScope->GetStmtToks();
                        stmtToks.splice(stmtToks.begin(), tmp);
                        tok = SkipToToken(tokRdr, CXX_OP_Semicolon, &stmtToks);
                    }
                }
            }

            scopes.pop_back();
#ifdef _DEBUG
            cout << "pop "; PrintStmtToks(stmtToks);
            if ( scopes.size() == 1 )
            {
                cout << "line:" << stmtToks.front().lineno << endl;
            }
#endif
            if ( scopes.empty() )
            {
                goto syntax_error;
            }
            pCurScope = &scopes.back();
        }
        else if ( tok.id == CXX_OP_Colon )
        {
            // 剔除标号 xxx: 和 case xxx:
            if ( (stmtToks.front().IsWord() && stmtToks.size() == 2)
                 || stmtToks.front().id == CXX_KW_public
                 || stmtToks.front().id == CXX_KW_protected
                 || stmtToks.front().id == CXX_KW_private
                 || stmtToks.front().id == CXX_KW_case )
            {
                stmtToks.clear();
                continue;
            }
        }

        if ( tok.id == CXX_OP_Semicolon
             || tok.id == CXX_OP_LBrace || tok.id == CXX_OP_RBrace )
        {
            // 处理 for(;;) 语句
            // 只有 for 才需要添加个新的 scope，其他的不需要，
            // 因为 for 里面可以声明局部变量
            if ( tok.id == CXX_OP_Semicolon
                 && stmtToks.begin()->id == CXX_KW_for )
            {
                // 跳到 ')'
                SkipToMatch(tokRdr, CXX_OP_LParen, CXX_OP_RParen, &stmtToks);
                // NOTE: 处理这种情形: for(;;);
                if ( tokRdr.PeekToken().id != CXX_OP_LBrace )
                {
                    CxxScope scope;
                    scope.SetStmtToks(stmtToks);
                    //cout << "push"; PrintStmtToks(stmtToks);
                    scopes.push_back(scope);
                    pCurScope = &scopes.back();
                    singleStmtScope = true;
                    stmtToks.clear();
                }
                continue;
            }
            
            // ===== 清空语句前，需要分析语句 =====
            // ===== START =====
            // 分析名空间信息
            if ( stmtToks.front().id == CXX_KW_using
                 || stmtToks.front().id == CXX_KW_namespace )
            {
                CxxTokenReader tmpTokRdr;
                tmpTokRdr.Init(stmtToks);
                CxxParseNamespaceInfo(tmpTokRdr, pCurScope->GetNSInfo());
            } 

            if ( tok.id == CXX_OP_Semicolon ) // 一般语句的结束
            {
                // 判断当前语句是否变量声明或定义
                if ( IsVarDeclOrDefi(stmtToks) )
                {
                    DetermineVariable(stmtToks, *pCurScope);
                }

                // NOTE: 处理这种情形: for(;;);
                if ( singleStmtScope )
                {
                    if ( scopes.empty() )
                    {
                        goto syntax_error;
                    }
                    scopes.pop_back();
#ifdef _DEBUG
                    cout << "pop "; PrintStmtToks(stmtToks);
                    if ( scopes.size() == 1 )
                    {
                        cout << "line:" << stmtToks.front().lineno << endl;
                    }
#endif
                    if ( scopes.empty() )
                    {
                        goto syntax_error;
                    }
                    pCurScope = &scopes.back();
                    singleStmtScope = false;
                }
            }
            // ===== END =====

            // 清空 stmtToks
            //PrintStmtToks(stmtToks);
            stmtToks.clear();
        }
    }

    // 到达文件尾部，可能有未完成的语句，添加到尾部的 scope 相应的字段
    pCurScope->SetCursorTokens(stmtToks);

    output += "[";
    if ( !scopes.empty() )
    {
        list<CxxScope>::iterator it = scopes.begin();
        output += it->ToPyEvalStr();
        for ( ++it; it != scopes.end(); ++it )
        {
            output += ", ";
            output += it->ToPyEvalStr();
        }
    }
    output += "]";

    return output;

syntax_error:
    //PrintStmtToks(stmtToks);
    if ( !errmsg.empty() )
    {
        cerr << errmsg << endl;
    }
    return "[]";
}

char * GetScopeStack(const char *buffer)
{
    CxxTokenReader tokRdr;
    list<CxxScope> scopes;
    tokRdr.Init(buffer);
    string result = GetScopeStack(tokRdr, scopes);
    return StrDup(result.c_str());
}


void * CxxHWParser_Create(const char *pszSymbolDBFile)
{
    CxxHWParser *pCxxHWParser = (CxxHWParser *)malloc(sizeof(CxxHWParser));
    if ( pCxxHWParser == NULL )
    {
        return NULL;
    }

    pCxxHWParser->p = NULL;
    return (void *)pCxxHWParser;
}

void CxxHWParser_Destroy(void *pParser)
{
    free(pParser);
}

void * CxxOmniCpp_Create(void *pParser, const char *buffer)
{
    CxxHWParser *pCxxHWParser = (CxxHWParser *)pParser;
    if ( pParser == NULL )
    {
        return NULL;
    }

    CxxOmniResult *pOmniCppResult = (CxxOmniResult *)
        malloc(sizeof(CxxOmniResult));
    if ( pOmniCppResult == NULL )
    {
        return NULL;
    }
    CxxTokenReader tokRdr;
    tokRdr.Init(buffer);
    string result = "hello world!";
    pOmniCppResult->pszSearchScopes = (char *)malloc(result.size() + 1);
    if ( pOmniCppResult->pszSearchScopes == NULL )
    {
        CxxOmniCpp_Destroy(pOmniCppResult);
        return NULL;
    }
    strcpy(pOmniCppResult->pszSearchScopes, result.c_str());

    return (void *)pOmniCppResult;
}

void CxxOmniCpp_Destroy(void *pOmniCppResult)
{
    free(((CxxOmniResult *)pOmniCppResult)->pszSearchScopes);
    free(pOmniCppResult);
}

const char * CxxOmniCpp_GetSearchScopes(void *pOmniCppResult)
{
    if ( pOmniCppResult == NULL )
    {
        return NULL;
    }
    return ((CxxOmniResult *)pOmniCppResult)->pszSearchScopes;
}
/* vi:set et sts=4: */
