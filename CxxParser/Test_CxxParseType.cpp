#include <stdio.h>
#include <string>
#include <iostream>
#include <gtest/gtest.h>
#include "CxxTokenReader.hpp"
#include "CxxParserCommon.hpp"
#include "CxxParseType.hpp"
#include "CxxHWParser.hpp"

#define ARRAY_SIZE(arr) (sizeof(arr)/sizeof((arr)[0]))

using namespace std;

typedef struct INT2_st {
    int n1;
    int n2;
} INT2;

typedef struct STR2_st {
    const char *psz1;
    const char *psz2;
} STR2;


//extern std::string CxxParseUnitType_Int(CxxTokenReader &tokRdr);
//extern std::string CxxParseUnitType_Char(CxxTokenReader &tokRdr);
//extern std::string CxxParseUnitType_Float(CxxTokenReader &tokRdr);


TEST(CxxParser, CxxParseUnitType_Int)
{
    STR2 testCases[] = {
        {"short",               "short int"},
        {"short int",           "short int"},
        {"signed short",        "short int"},
        {"signed short int",    "short int"},
        {"short signed",        "short int"},
        {"short signed int",    "short int"},

        {"unsigned short",      "unsigned short int"},
        {"unsigned short int",  "unsigned short int"},
        {"short unsigned",      "unsigned short int"},
        {"short unsigned int",  "unsigned short int"},

        {"int",         "int"},
        {"signed",      "int"},
        {"signed int",  "int"},

        {"unsigned",        "unsigned int"},
        {"unsigned int",    "unsigned int"},

        {"long", "long int"},
        {"long int", "long int"},
        {"signed long", "long int"},
        {"signed long int", "long int"},
        {"long signed", "long int"},
        {"long signed int", "long int"},

        {"unsigned long", "unsigned long int"},
        {"unsigned long int", "unsigned long int"},
        {"long unsigned", "unsigned long int"},
        {"long unsigned int", "unsigned long int"},

        {"long long", "long long int"},
        {"long long int", "long long int"},
        {"signed long long", "long long int"},
        {"signed long long int", "long long int"},
        {"long long signed", "long long int"},
        {"long long signed int", "long long int"},

        {"unsigned long long", "unsigned long long int"},
        {"unsigned long long int", "unsigned long long int"},
        {"long long unsigned", "unsigned long long int"},
        {"long long unsigned int", "unsigned long long int"},
    };

    for ( size_t i = 0; i < ARRAY_SIZE(testCases); ++i )
    {
        CxxTokenReader tokRdr;
        tokRdr.Init(testCases[i].psz1);
        //printf("-----\n");
        //printf("%s\n", testCases[i].psz1);
        //printf("%s\n", testCases[i].psz2);
        ASSERT_STREQ(testCases[i].psz2, CxxParseUnitType_Int(tokRdr).c_str());
        ASSERT_TRUE(tokRdr.PeekToken().IsEOF());
    }
}

TEST(CxxParser, CxxParseUnitType_Char)
{
    const char *testCases[] = {
        "signed char",
        "unsigned char",
        "char",
        "wchar_t",
        "char16_t",
        "char32_t",
    };

    for ( size_t i = 0; i < ARRAY_SIZE(testCases); ++i )
    {
        CxxTokenReader tokRdr;
        tokRdr.Init(testCases[i]);
        ASSERT_STREQ(testCases[i], CxxParseUnitType_Char(tokRdr).c_str());
        ASSERT_TRUE(tokRdr.PeekToken().IsEOF());
    }
}

TEST(CxxParser, CxxParseUnitType_Float)
{
    const char *testCases[] = {
        "float",
        "double",
        "long double",
    };

    for ( size_t i = 0; i < ARRAY_SIZE(testCases); ++i )
    {
        CxxTokenReader tokRdr;
        tokRdr.Init(testCases[i]);
        ASSERT_STREQ(testCases[i], CxxParseUnitType_Float(tokRdr).c_str());
        ASSERT_TRUE(tokRdr.PeekToken().IsEOF());
    }
}


TEST(CxxParser, CxxParseUnitType)
{
}


TEST(CxxParser, GetScopeStack)
{
    const char *buffer = "  int func() { int i; void fun2 () { int x; }  ";
    std::list<CxxScope> scopes;
    CxxTokenReader tokRdr;
    tokRdr.Init(buffer);
    //cout << GetScopeStack(tokRdr, scopes) << endl;
    //cout << GetScopeStack(buffer) << endl;
}

