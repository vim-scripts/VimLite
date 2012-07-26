#include <set>
#include <list>
#include <iostream>
#include <tr1/unordered_map>
#include "CxxParserCommon.hpp"
#include "CxxTokenReader.hpp"
#include "CxxHWParser.hpp"
#include "CxxParseType.hpp"
#include "pystring.h"

// 理论上进入任何处理函数前都要先预测

using namespace std;
using namespace pystring;

CxxType CxxParseType(CxxTokenReader &tokRdr)
{
    CxxType typeResult;
    CxxToken tok;
    tok = tokRdr.GetToken();
    // 跳过 storage 修饰
    /* storage-class-specifier:
        auto            Removed in C++0x
        register
        static
        thread_local    C++0x
        extern
        mutable

       const volatile
    */
    while ( tok.id == CXX_KW_auto || tok.id == CXX_KW_register
            || tok.id == CXX_KW_static || tok.id == CXX_KW_thread_local
            || tok.id == CXX_KW_extern || tok.id == CXX_KW_mutable
            || tok.id == CXX_KW_const || tok.id == CXX_KW_volatile )
    {
        tok = tokRdr.GetToken();
    }

    // 处理前导的 "::"
    if ( tok.id == CXX_OP_ColonColon )
    {
        typeResult.global = true;
        tok = tokRdr.GetToken();
    }

    // 校验完成
    tokRdr.UngetToken(tok);
    do
    {
        CxxUnitType ut = CxxParseUnitType(tokRdr);
        if ( ut.IsError() )
        {
            // 语法错误
            typeResult.ToError();
            goto out;
        }
        typeResult.typeList.push_back(ut);
        // 不是 "::" 的话，直接结束
        if ( tokRdr.PeekToken().id != CXX_OP_ColonColon )
        {
            break;
        }
        else
        {
            // 扔掉 "::"
            tokRdr.GetToken();
        }
    } while ( tokRdr.PeekToken().IsValid() );

out:
    return typeResult;
}

// 获取单元类型
/* Character
 *  signed char
 *  unsigned char
 *  char
 *  wchar_t
 *  char16_t(C++11)
 *  char32_t(C++11)
 *
 * Integer
 *  short int (short | short int | signed short | signed short int)
 *  unsigned short int (unsigned short | unsigned short int)
 *  int (int | signed | signed int)
 *  unsigned int (unsigned | unsigned int)
 *  long int (long | long int | signed long | signed long int)
 *  unsigned long int (unsigned long | unsigned long int)
 *  long long int (long long | long long int | signed long long | signed long long int)
 *  unsigned long long int (unsigned long long | unsigned long long int)
 *
 * Floating
 *  float
 *  double
 *  long double
 *
 * */
CxxUnitType CxxParseUnitType(CxxTokenReader &tokRdr)
{
    CxxUnitType unitType;
    CxxToken tok = tokRdr.GetToken();
    // 向前看一个 token
    CxxToken tok2 = tokRdr.PeekToken();

    if ( tok.IsKeyword() )
    {
        switch ( tok.id )
        {
        case CXX_KW_unsigned:
        case CXX_KW_signed:
            if ( tok2.id == CXX_KW_char )
            {
                tokRdr.UngetToken(tok);
                unitType.text = CxxParseUnitType_Char(tokRdr);
            }
            else
            {
                tokRdr.UngetToken(tok);
                // empty() 即语法错误
                unitType.text = CxxParseUnitType_Int(tokRdr);
            }
            break;

        case CXX_KW_long:
            if ( tok2.id == CXX_KW_double )
            {
                tokRdr.UngetToken(tok);
                unitType.text = CxxParseUnitType_Float(tokRdr);
            }
            else
            {
                tokRdr.UngetToken(tok);
                // empty() 即语法错误
                unitType.text = CxxParseUnitType_Int(tokRdr);
            }
            break;

        // int 特征
        case CXX_KW_int:
        case CXX_KW_short:
            tokRdr.UngetToken(tok);
            // empty() 即语法错误
            unitType.text = CxxParseUnitType_Int(tokRdr);
            break;

        // char 特征
        case CXX_KW_char:
        case CXX_KW_wchar_t:
        case CXX_KW_char16_t:
        case CXX_KW_char32_t:
            tokRdr.UngetToken(tok);
            unitType.text = CxxParseUnitType_Char(tokRdr);
            break;

        // float 特征
        case CXX_KW_float:
        case CXX_KW_double:
            tokRdr.UngetToken(tok);
            // s.empty() 即语法错误
            unitType.text = CxxParseUnitType_Float(tokRdr);
            break;

        default:
            // 又是关键词又不是基础类型？
            // TODO
            SkipToToken(tokRdr, CXX_OP_Semicolon);
            break;
        }
    }
    else if ( tok.IsWord() )
    {
        // A<X<Y>, Z> a;
        unitType.text = tok.text;
        if ( tokRdr.PeekToken().id == CXX_OP_LT )
        {
        // 收集模板
            tokRdr.GetToken();
            int nestLv = 1;
            string text;
            for ( tok = tokRdr.GetToken();
                  tok.IsValid();
                  tok = tokRdr.GetToken() )
            {
                if ( tok.id == CXX_OP_LT )
                {
                    nestLv += 1;
                }
                else if ( tok.id == CXX_OP_GT )
                {
                    nestLv -= 1;
                    if ( nestLv == 0 )
                    {
                        unitType.tmplList.push_back(text);
                        text.clear();
                        break;
                    }
                }
                else if ( tok.id == CXX_OP_Comma )
                {
                    if ( nestLv == 1 )
                    {
                        unitType.tmplList.push_back(text);
                        text.clear();
                        continue;
                    }
                }

                // 收集字符
                if ( nestLv >= 1 )
                {
                    text += text.empty() ? tok.text : " " + tok.text;
                }
            }
        }
    }
    else
    {
        // TODO
    }

    return unitType;

syntax_error:
    // TODO
    return unitType;
}

// 以下三个函数返回空字符串表示解析出错
std::string CxxParseUnitType_Char(CxxTokenReader &tokRdr)
{
    string result;
    CxxToken tok = tokRdr.GetToken();
    switch ( tok.id )
    {
    case CXX_KW_signed:
        if ( tokRdr.PeekToken().id == CXX_KW_char )
        {
            result = "signed char";
            tokRdr.GetToken();
        }
        break;
    case CXX_KW_unsigned:
        if ( tokRdr.PeekToken().id == CXX_KW_char )
        {
            result = "unsigned char";
            tokRdr.GetToken();
        }
        break;
    case CXX_KW_char:
        result = "char";
        break;
    case CXX_KW_wchar_t:
        result = "wchar_t";
        break;
    case CXX_KW_char16_t:
        result = "char16_t";
        break;
    case CXX_KW_char32_t:
        result = "char32_t";
        break;

    default:
        break;
    }

    return result;
}

std::string CxxParseUnitType_Int(CxxTokenReader &tokRdr)
{
    string result;
    CxxToken tok = tokRdr.GetToken();
    switch ( tok.id )
    {
    case CXX_KW_signed:
        {
            result += "";
            tok = tokRdr.GetToken();
            switch ( tok.id )
            {
            case CXX_KW_short: // short
                result += "short";
                if ( tokRdr.PeekToken().id == CXX_KW_int )
                {
                    tokRdr.GetToken();
                }
                result += " int";
                break;
            case CXX_KW_long: // long | long long
                result += "long";
                if ( tokRdr.PeekToken().id == CXX_KW_long )
                {
                    result += " long";
                    tokRdr.GetToken();
                }
                if ( tokRdr.PeekToken().id == CXX_KW_int )
                {
                    tokRdr.GetToken();
                }
                result += " int";
                break;
            case CXX_KW_int:
                result += "int";
                break;
            case CXX_WORD: // 省略用法
                result += "int";
                tokRdr.UngetToken(tok);
                break;
            default:
                //result.clear();
                result += "int";
                tokRdr.UngetToken(tok);
                break;
            }
        }
        break;
    case CXX_KW_unsigned:
        {
            result += "unsigned";
            tok = tokRdr.GetToken();
            switch ( tok.id )
            {
            case CXX_KW_short: // short
                result += " short";
                if ( tokRdr.PeekToken().id == CXX_KW_int )
                {
                    tokRdr.GetToken();
                }
                result += " int";
                break;
            case CXX_KW_long: // long | long long
                result += " long";
                if ( tokRdr.PeekToken().id == CXX_KW_long )
                {
                    result += " long";
                    tokRdr.GetToken();
                }
                if ( tokRdr.PeekToken().id == CXX_KW_int )
                {
                    tokRdr.GetToken();
                }
                result += " int";
                break;
            case CXX_KW_int:
                result += " int";
                break;
            case CXX_WORD: // 省略用法
                result += " int";
                tokRdr.UngetToken(tok);
                break;
            default:
                //result.clear();
                result += " int";
                tokRdr.UngetToken(tok);
                break;
            }
        }
        break;
    case CXX_KW_int:
        result += "int";
        break;
    case CXX_KW_short:
        result += "short";
        // 处理 signed 和 unsigned
        if ( tokRdr.PeekToken().id == CXX_KW_unsigned )
        {
            result = "unsigned " + result;
            tokRdr.GetToken();
        }
        else if ( tokRdr.PeekToken().id == CXX_KW_signed )
        {
            tokRdr.GetToken();
        }
        if ( tokRdr.PeekToken().id == CXX_KW_int )
        {
            tokRdr.GetToken();
        }
        result += " int";
        break;
    case CXX_KW_long:
        result += "long";
        if ( tokRdr.PeekToken().id == CXX_KW_long )
        {
            result += " long";
            tokRdr.GetToken();
        }
        // 处理 signed 和 unsigned
        if ( tokRdr.PeekToken().id == CXX_KW_unsigned )
        {
            result = "unsigned " + result;
            tokRdr.GetToken();
        }
        else if ( tokRdr.PeekToken().id == CXX_KW_signed )
        {
            tokRdr.GetToken();
        }
        if ( tokRdr.PeekToken().id == CXX_KW_int )
        {
            tokRdr.GetToken();
        }
        result += " int";
        break;

    default:
        break;
    }

    return result;
}

std::string CxxParseUnitType_Float(CxxTokenReader &tokRdr)
{
    string result;
    CxxToken tok = tokRdr.GetToken();
    switch ( tok.id )
    {
    case CXX_KW_float:
        result = "float";
        break;
    case CXX_KW_double:
        result = "double";
        break;
    case CXX_KW_long:
        if ( tokRdr.PeekToken().id == CXX_KW_double )
        {
            result = "long double";
            tokRdr.GetToken();
        }
        break;

    default:
        break;
    }

    return result;
}

