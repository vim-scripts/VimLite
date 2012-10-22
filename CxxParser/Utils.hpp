#ifndef __UTILS_HPP__
#define __UTILS_HPP__

#include <stdlib.h>
#include <string.h>
#include <string>
#include <map>
#include <list>
#include <string>
#include <tr1/unordered_map>

typedef std::string String;
typedef std::tr1::unordered_map<std::string, std::string> StrStrMap;
typedef std::list<std::string> StrList;

static inline char * StrDup(const char *src)
{
    char *str = (char *)malloc(strlen(src) + 1);
    if ( str == NULL )
    {
        return NULL;
    }
    strcpy(str, src);
    return str;
}

std::string EscapeChars(const char *str, const char *chars);

std::string ToPyEvalStr(const StrStrMap &map);
std::string ToPyEvalStr(const StrList &li);


#endif /* __UTILS_HPP__ */
