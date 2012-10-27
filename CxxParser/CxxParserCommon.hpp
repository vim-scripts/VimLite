#ifndef __CXXPARSERCOMMON_HPP__
#define __CXXPARSERCOMMON_HPP__

#include <list>
#include <vector>
#include <string>
#include <tr1/unordered_map>
#include "pystring.h"
#include "CxxTokenReader.hpp"
#include "Utils.hpp"


#define VERSION     1020

extern "C" int CxxParser_GetVersion(void);

typedef enum CxxParseResult_em {
    CxxPR_SUCCESS = 0,
    CxxPR_FAILURE,
} CxxParseResult;


// 公共数据结构定义

// A a;
// A<B, C<D> > a;
class CxxUnitType {
public:
    std::string text; // 文本
    std::list<std::string> tmplList; // 模板列表，可能为空

    bool IsValid()
    { return !text.empty(); }
    bool IsError()
    { return !IsValid(); }

    std::string ToString()
    {
        std::string str = text;
        if ( !tmplList.empty() )
        {
            str += "< ";
            str += pystring::join(", ", tmplList);
            str += " >";
        }
        return str;
    }

    std::string ToPyEvalStr()
    {
        // {"name": "", "til": []}
        std::string str = "{";
        str += "\"name\": \"" + EscapeChars(text.c_str(), "\"\\") + "\", ";
        str += "\"til\": ";
        str += ::ToPyEvalStr(tmplList);
        str += "}";
        return str;
    }
};

// C++ 类型
// A::B<C>::D x;
class CxxType {
public:
    std::list<CxxUnitType> typeList;
    bool global; // 是否强制为全局作用域，如 ::A::B

    CxxType()
    {
        global = false;
    }

    bool IsValid()
    { return !typeList.empty(); }
    bool IsError()
    { return typeList.empty(); }
    // 设置为错误
    void ToError()
    { typeList.clear(); }

    std::string ToString()
    {
        std::string str = global ? "::" : "";
        bool firstEnter = true;
        for ( std::list<CxxUnitType>::iterator it = typeList.begin();
              it != typeList.end();
              ++it )
        {
            if ( firstEnter )
            {
                str += it->ToString();
                firstEnter = false;
            }
            else
            {
                str += "::" + it->ToString();
            }
        }
        return str;
    }

    std::string ToPyEvalStr()
    {
        // {"types": []}
        std::string str = "{";
        str += "\"types\": ";
        str += "[";
        if ( !typeList.empty() )
        {
            std::list<CxxUnitType>::iterator it = typeList.begin();
            str += it->ToPyEvalStr();
            for ( ++it; it != typeList.end(); ++it )
            {
                str += ", " + it->ToPyEvalStr();
            }
        }
        str += "]";
        str += "}";
        return str;
    }
};

// 代表 C++ 中的一个变量
// eg. A<B>::C<D, E<F> > **x, &y; x 和 y 都有一个 CxxVar 实例
class CxxVar {
public:
    std::string name; // 变量的名字
    CxxType type; // 变量的类型
    size_t line; // 变量所在的行

    CxxVar()
    {
        line = 0;
    }

    // TODO: 返回一个 python 字典
    std::string ToPyEvalStr()
    {
        char buf[32] = {'\0'};
        std::string s;
        s += "{";
        sprintf(buf, "%lu", (unsigned long)line);
        s += "\"line\": ";
        s += buf;
        s += ", ";

        s += "\"type\": ";
        s += type.ToPyEvalStr();
        s += "}";
        return s;
    }
};

// 名空间信息，把名空间别名，using 指示(using namespace std)，using 声明集中管理
class NSInfo {
public:
    void AddUsingNamespace(const std::string &nsName)
    { m_usingns.push_back(nsName); }

    void AddUsing(std::string usingDecl)
    {
        std::vector<std::string> result;
        pystring::split(usingDecl, result, "::");
        if ( result.empty() )
        {
            return;
        }
        m_using[result.back()] = usingDecl;
    }

    void AddNamespaceAlias(const std::string &s1, const std::string &s2)
    { m_nsalias[s1] = s2; }

    std::string ToPyEvalStr()
    {
        std::string s = "{";
        s += "\"usingns\": ";
        s += ::ToPyEvalStr(m_usingns);
        s += ", ";

        s += "\"using\": ";
        s += ::ToPyEvalStr(m_using);
        s += ", ";

        s += "\"nsalias\": ";
        s += ::ToPyEvalStr(m_nsalias);
        s += "}";
        return s;
    }

private:
    StrList m_usingns; // using namespace std;
    StrStrMap m_using; // using std::string;
    StrStrMap m_nsalias; // namespace s = std;
};

typedef std::tr1::unordered_map<std::string, CxxVar> VarTable;

// 代表一个 C++ 的 {} 块
class CxxScope {
public:
    typedef enum CxxScopeKind_em {
        CXXSCOPE_FILE,
        CXXSCOPE_CONTAINER,
        CXXSCOPE_FUNCTION,
        CXXSCOPE_OTHER,
    } CxxScopeKind;

    CxxScope()
    {
        m_kind = CXXSCOPE_OTHER;
    }

    ~CxxScope() {}

    const std::string & GetName()
    { return m_name; }
    void SetName(std::string &name)
    { m_name = name; }

    CxxScopeKind GetKind()
    { return m_kind; }
    void SetKind(CxxScopeKind kind)
    { m_kind = kind; }

    NSInfo & GetNSInfo()
    { return m_nsinfo; }

    std::string GetStrKind()
    {
        switch ( m_kind )
        {
        case CXXSCOPE_FILE:
            return "file";
            break;
        case CXXSCOPE_CONTAINER:
            return "container";
            break;
        case CXXSCOPE_FUNCTION:
            return "function";
            break;
        case CXXSCOPE_OTHER:
            return "other";
            break;
        default:
            return "";
            break;
        }
    }

    // 输出 python 字典
    std::string ToPyEvalStr();

    void SetStmtToks(const std::list<CxxToken> &toks)
    { m_tokens = toks; }
    std::list<CxxToken> & GetStmtToks()
    { return m_tokens; }

    void SetCursorTokens(const std::list<CxxToken> &toks)
    { m_cursorTokens = toks; }
    std::list<CxxToken> & GetCursorTokens()
    { return m_cursorTokens; }

    void AddVar(const CxxVar &var)
    { m_vars[var.name] = var; }

    bool HasVar(const std::string &name)
    { return m_vars.find(name) != m_vars.end(); }

private:
    CxxScopeKind m_kind; // 类型
    std::string m_name; // 名字
    std::list<std::string> m_includes; // 这个暂时不支持
    VarTable m_vars; // 本作用域的变量
    std::list<CxxToken> m_tokens; // 当前 scope 的 token
    NSInfo m_nsinfo; // 当前 scope 的名空间信息
    std::list<CxxToken> m_cursorTokens; // 光标前的不完整语句的 token
};

// =============================================================================
// 根据 http://www.nongnu.org/hcb/ 手写的解析例程

CxxParseResult CxxParse_enum_specifier(CxxTokenReader &tokRdr);
CxxParseResult CxxParse_class_key(CxxTokenReader &tokRdr);
CxxParseResult CxxParse_enum_key(CxxTokenReader &tokRdr);


#endif /* __CXXPARSERCOMMON_HPP__ */
