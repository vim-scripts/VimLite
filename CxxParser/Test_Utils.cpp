#include <iostream>
#include <gtest/gtest.h>
#include "Utils.hpp"

using namespace std;

TEST(Utils, EscapeChars)
{
    const char *s = "hello \" \\  \" world";
    //cout << s << endl;
    //cout << EscapeChars(s, "\"\\") << endl;
    ASSERT_STREQ("hello \\\" \\\\  \\\" world", EscapeChars(s, "\"\\").c_str());
}

TEST(Utils, ToPyEvalStr)
{
    StrStrMap map;
    StrList li;
    map["a'b\\c\""] = "xyz";
    map["haha"] = "\\";
    li.push_back("x\"\\\"xx");
    li.push_back("o\\oo");
    //cout << ToPyEvalStr(map) << endl;
    //cout << ToPyEvalStr(li) << endl;
}

