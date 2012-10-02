#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include "CxxTokenReader.hpp"

CxxTokenReader::~CxxTokenReader()
{
    Term();
}

int CxxTokenReader::Init(const char *buffer)
{
    m_inputType = INPUT_FROM_STRING;
    //m_prvtdata.Init();
    CxxLexPrvtData_Init(&m_prvtdata);
    cxx_yylex_init_extra(&m_prvtdata, &m_scaninfo);
    m_bp = cxx_yy_scan_string(buffer, m_scaninfo);
    cxx_yy_switch_to_buffer(m_bp, m_scaninfo);
    cxx_yyset_lineno(1, m_scaninfo);
    return 0;
}

int CxxTokenReader::Init(FILE *fp)
{
    m_inputType = INPUT_FROM_FILE;
    //m_prvtdata.Init();
    CxxLexPrvtData_Init(&m_prvtdata);
    cxx_yylex_init_extra(&m_prvtdata, &m_scaninfo);
    m_bp = NULL;
    cxx_yyset_in(fp, m_scaninfo);
    cxx_yyset_lineno(1, m_scaninfo);
    return 0;
}

int CxxTokenReader::Init(const std::list<CxxToken> &toks)
{
    m_inputType = INPUT_FROM_LIST;
    m_tokList = toks;
    return 0;
}

void CxxTokenReader::Term()
{
    if ( m_bp != NULL )
    {
        cxx_yy_delete_buffer(m_bp, m_scaninfo);
        m_bp = NULL;
    }
    if ( m_scaninfo != NULL )
    {
        cxx_yylex_destroy(m_scaninfo);
        m_scaninfo = NULL;
    }
    while ( !m_ungetBuffer.empty() )
    {
        m_ungetBuffer.pop();
    }
    //m_prvtdata.Term();
    CxxLexPrvtData_Term(&m_prvtdata);
}

void CxxTokenReader::UngetToken(const CxxToken &tok)
{
    m_ungetBuffer.push(tok);
}

CxxToken CxxTokenReader::GetToken()
{
    CxxToken tok;
    if ( !m_ungetBuffer.empty() )
    {
        tok = m_ungetBuffer.top();
        m_ungetBuffer.pop();
    }
    else
    {
        if ( m_inputType == INPUT_FROM_LIST )
        {
            if ( !m_tokList.empty() )
            {
                tok = m_tokList.front();
                m_tokList.pop_front();
            }
        }
        else
        {
            tok.id = cxx_yylex(m_scaninfo);
            tok.text = cxx_yyget_text(m_scaninfo);
            tok.lineno = cxx_yyget_lineno(m_scaninfo);
            //tok.column = cxx_yyget_column(m_scaninfo);
        }
    }

    return tok;
}

CxxToken CxxTokenReader::PeekToken()
{
    CxxToken tok = GetToken();
    UngetToken(tok);
    return tok;
}


int yylex(CxxToken *yylvalp, CxxTokenReader *pTokRdr)
{
    *yylvalp = pTokRdr->GetToken();
    return yylvalp->id;
}

void yyerror(CxxTokenReader *pTokRdr, const char *msg, ...)
{
    va_list ap;
    CxxToken tok = pTokRdr->PeekToken();
    fprintf(stderr, "%3d:%3d:%d:%s\n",
           tok.lineno, tok.column, tok.id, tok.text.c_str());
    va_start(ap, msg);
    vfprintf(stderr, msg, ap);
    va_end(ap);
}

std::string JoinTokensToString(std::list<CxxToken> &tokens)
{
    if ( tokens.empty() )
    {
        return "";
    }

    std::list<CxxToken>::iterator it = tokens.begin();
    if ( tokens.size() == 1 )
    {
        return it->text;
    }

    std::string result = it->text;
    it++;
    for ( ; it != tokens.end(); it++ )
    {
        result += " " + it->text;
    }
    return result;
}

CxxToken_st::CxxToken_st(const char *str, int line)
{
    __init__();
    if ( str == NULL )
    {
        return;
    }

    CxxTokenReader tokRdr;
    tokRdr.Init(str);
    *this = tokRdr.GetToken();
}
