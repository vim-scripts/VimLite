#include "Utils.hpp"

using namespace std;

static inline std::string NormDoubleQuoteStr(const char *str)
{
    return EscapeChars(str, "\"\\");
}

std::string EscapeChars(const char *str, const char *chars)
{
    if ( str == NULL )
    {
        return "";
    }
    if ( chars == NULL || chars[0] == '\0' )
    {
        return str;
    }

    string result;
    const char *p = str;
    for ( ; *p != '\0'; p++ )
    {
        if ( strchr(chars, *p) != NULL )
        {
            result += "\\";
        }
        result += *p;
    }

    return result;
}

std::string ToPyEvalStr(const StrStrMap &map)
{
    string s = "{";
    if ( !map.empty() )
    {
        StrStrMap::const_iterator it = map.begin();
        s += "\"" + NormDoubleQuoteStr(it->first.c_str()) + "\": ";
        s += "\"" + NormDoubleQuoteStr(it->second.c_str()) + "\"";
        ++it;
        for ( ; it != map.end(); ++it )
        {
            s += ", ";
            s += "\"" + NormDoubleQuoteStr(it->first.c_str()) + "\": ";
            s += "\"" + NormDoubleQuoteStr(it->second.c_str()) + "\"";
        }
    }

    s += "}";
    return s;
}

std::string ToPyEvalStr(const StrList &li)
{
    string s = "[";
    if ( !li.empty() )
    {
        StrList::const_iterator it = li.begin();
        s += "\"" + NormDoubleQuoteStr(it->c_str()) + "\"";
        ++it;
        for ( ; it != li.end(); ++it )
        {
            s += ", ";
            s += "\"" + NormDoubleQuoteStr(it->c_str()) + "\"";
        }
    }
    s += "]";
    return s;
}

