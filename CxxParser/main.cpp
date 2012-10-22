#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "CxxTokenReader.hpp"
#include "CxxParserCommon.hpp"
#include "pystring.h"
#include "gtest/gtest.h"
#include "CxxHWParser.hpp"

using namespace std;
using namespace pystring;

extern CxxUnitType CxxParseUnitType(CxxTokenReader &tokRdr);

int yyparse(CxxTokenReader *pTokRdr);

int LoadFile(const std::string &fileName, std::string &contents, size_t line = 0);

int main(int argc, char **argv)
{
    CxxTokenReader tokRdr;
    CxxToken tok;
    string fileName;
    string contents;
    list<CxxScope> scopes;
    bool testLex = false;
    bool noPrint = false;
    size_t line = 0;

    if ( argc >= 2 && strcmp(argv[1], "-h") == 0 )
    {
        printf("usage: %s {file} [line [-l|-t]]\n", argv[0]);
        return 0;
    }

    if ( argc >= 2 )
    {
        fileName = argv[1];
    }
    if ( argc >= 3 )
    {
        line = atoi(argv[2]);
    }
    if ( !fileName.empty() )
    {
        if ( LoadFile(fileName, contents, line) != 0 )
        {
            perror(fileName.c_str());
            return 1;
        }
    }

    if ( argc >= 4 )
    {
        if ( strcmp(argv[3], "-l") == 0 )
        {
            testLex = true;
        }
        else if ( strcmp(argv[3], "-t") == 0 )
        {
            testLex = true;
            noPrint = true;
        }
    }

    tokRdr.Init(contents.c_str());

#if 0
    yyparse(&tokRdr);
#else
    if ( testLex )
    {
        if ( noPrint )
        {
            while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
            {
            }
        }
        else
        {
            while ( (tok = tokRdr.GetToken(), tok.IsValid()) )
            {
                printf("%3d:%3d:%3d:%s\n",
                       tok.lineno, tok.column, tok.id, tok.text.c_str());
            }
        }
        return 0;
    }
#endif

    if ( tokRdr.PeekToken().IsValid() )
    {
        printf("%s\n", GetScopeStack(tokRdr, scopes).c_str());
        //printf("=====\n");
        //printf("%s\n", GetScopeStack(contents.c_str()));
    }

    tokRdr.Term();
    const char * p= "A<X, Y<Z1, Z2> > a;";
    tokRdr.Init(p);
    CxxUnitType unitType = CxxParseUnitType(tokRdr);
    //printf("%s\n", unitType.text.c_str());
    //printf("%s\n", join("\n", unitType.tmplList).c_str());

    //printf("END.\n");

    if ( argc == 1 )
    {
        testing::InitGoogleTest(&argc, argv);
        return RUN_ALL_TESTS();
    }

    return 0;
}

int LoadFile(const std::string &fileName, std::string &contents, size_t line)
{
    long int size;
    FILE *fp = fopen(fileName.c_str(), "rb");
    if ( fp == NULL )
    {
        return -1;
    }

    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if ( size > 0 )
    {
        char *zBuffer = new char[size + 1];
        zBuffer[size] = '\0';
        fread(zBuffer, size, 1, fp);
        if ( line == 0 )
        {
            contents += zBuffer;
        }
        else
        {
            vector<string> result;
            splitlines(zBuffer, result, true);
            line = result.size() < line ? result.size() : line;
            result.erase(result.begin() + line, result.end());
            contents += join("", result);
        }
        delete[] zBuffer;
    }
    fclose(fp);

    return 0;
}
/* vi:set et sts=4: */
