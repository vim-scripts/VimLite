#ifndef __CXXTOKENREADER_HPP__
#define __CXXTOKENREADER_HPP__

#include <list>
#include <stack>
#include <string>
#ifndef __CXXPARSER_HPP__
#define __CXXPARSER_HPP__
# include "CxxParser.hpp"
#endif
#include "CxxLexPrvtData.h"

extern "C" {
#include "CxxLexer.h"
}

class CxxTokenReader;

typedef struct CxxToken_st {
    int id; // 宏 ID
    std::string text; // 字符串
    int lineno;
    int column;

    // 从字符串构造一个 token，只取第一个有效 token，其他的全忽略
    CxxToken_st(const char *str, int line = 1);

    CxxToken_st()
    {
        __init__();
    }

    bool IsEOF()
    {
        return id == 0;
    }

    // 是否有效的符号，即不是 EOF
    bool IsValid()
    {
        return !IsEOF();
    }

    bool IsKeyword()
    {
        return (id >= CXX_KW_and && id <= CXX_KW_final);
    }

    bool IsOP()
    {
        return (id >= CXX_OP_LParen && id <= CXX_OP_Ellipsis);
    }

    bool IsWord()
    {
        return id == CXX_WORD;
    }

private:
    // 统一初始化接口
    void __init__()
    {
        id = 0;
        lineno = 0;
        column = 0;
    }
} CxxToken;


int yylex(CxxToken *yylvalp, CxxTokenReader *pTokRdr);
void yyerror(CxxTokenReader *pTokRdr, const char *msg, ...);

#if 0
class CxxLexPrvtData {
public:
    int yy_state; // 起始状态

    CxxLexPrvtData()
    {
        Init();
    }
    ~CxxLexPrvtData()
    {}

    void Init()
    {
        yy_state = 0; // INITIAL <- 这个符号在 CxxLexer.c 里面，这里看不到
    }

    void Term()
    {
    }
};
#endif

class CxxTokenReader {
public:
    CxxTokenReader()
    {
        m_scaninfo = NULL;
        m_bp = NULL;
        m_inputType = INPUT_FROM_FILE;
    }

    ~CxxTokenReader();

    /* 初始化输入 */
    int Init(const char *buffer);
    int Init(FILE *fp);
    int Init(const std::list<CxxToken> &toks);

    // 对应 Init
    void Term();

    CxxToken GetToken();
    void UngetToken(const CxxToken &tok);
    CxxToken PeekToken();

#if 0
    void SetPrvtData(void *data)
    { m_prvtdata = data; }
    void * GetPrvtData()
    { return m_prvtdata; }
#endif

private:
    yyscan_t m_scaninfo;    // 词法分析器数据
    CxxLexPrvtData m_prvtdata;  // 私有数据
    YY_BUFFER_STATE m_bp;   // 词法分析器缓冲，输入为字符串的时候用

    // 输入类型
    typedef enum InputType_em {
        INPUT_FROM_FILE,
        INPUT_FROM_STRING,
        INPUT_FROM_LIST,
    } InputType;

    InputType m_inputType;
    std::stack<CxxToken> m_ungetBuffer; // 反推回来的符号的缓冲
    std::list<CxxToken> m_tokList;      // 支持某一种 Init() 的时候用到
};

std::string JoinTokensToString(std::list<CxxToken> &tokens);

#endif /* __CXXTOKENREADER_HPP__ */
