#include "CxxParserCommon.hpp"
#include "Utils.hpp"
#include "CxxTokenReader.hpp"
#include "CxxParseType.hpp"
#include <iostream>

using namespace std;

int CxxParser_GetVersion(void)
{
    return VERSION;
}

std::string CxxScope::ToPyEvalStr()
{
    std::string result;
    result += "{";

    result += "\"stmt\": \"";
    result += EscapeChars(JoinTokensToString(m_tokens).c_str(), "\"\\");
    result += "\", ";

    result += "\"kind\": \"";
    result += EscapeChars(GetStrKind().c_str(), "\"\\");
    result += "\", ";

    result += "\"name\": \"";
    result += EscapeChars(m_name.c_str(), "\"\\");
    result += "\", ";

#if 0
    CxxVar var;
    CxxTokenReader tokRdr;
    tokRdr.Init("A<B>");
    var.type = CxxParseType(tokRdr);
    var.name = "abc";
    AddVar(var);
    cout << var.ToPyEvalStr() << endl;
    tokRdr.Term();
    tokRdr.Init("X<Y>");
    var.type = CxxParseType(tokRdr);
    var.name = "xyz";
    AddVar(var);
    cout << var.ToPyEvalStr() << endl;
#endif

    result += "\"vars\": ";
    result += "{";
    if ( !m_vars.empty() )
    {
        VarTable::iterator it = m_vars.begin();
        result += "\"" + it->first + "\": ";
        result += it->second.ToPyEvalStr();
        for ( ++it; it != m_vars.end(); ++it )
        {
            result += ", ";
            result += "\"" + it->first + "\": ";
            result += it->second.ToPyEvalStr();
        }
    }
    result += "}";
    result += ", ";

    // "cusrstmt": "", 
    result += "\"cusrstmt\": \"";
    result += EscapeChars(JoinTokensToString(m_cursorTokens).c_str(), "\"\\");
    result += "\", ";

    //result += "\"nsinfo\": {'nsalias': {}, 'using': {}, 'usingns': []}, ";
    result += "\"nsinfo\": ";
    result += m_nsinfo.ToPyEvalStr();
    result += ", ";
    result += "\"include\": []";

    result += "}";

    return result;
}

