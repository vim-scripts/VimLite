#include <stdio.h>
#include <string>
#include <gtest/gtest.h>
#include "CxxTokenReader.hpp"
#include "CxxParserCommon.hpp"
#include "CxxHWParser.hpp"
#include "CxxParseType.hpp"

#define ARRAY_SIZE(arr) (sizeof(arr)/sizeof((arr)[0]))

extern int CxxParseNamespaceInfo(CxxTokenReader &tokRdr, NSInfo &nsinfo);

using namespace std;

TEST(CxxParser, CxxHWParser)
{
    // eg1. const MyClass&
    // eg2. const map < int, int >&
    // eg3. MyNs::MyClass
    // eg4. ::MyClass**
    // eg5. MyClass a, *b = NULL, c[1] = {};
    // eg6. A<B>::C::D<E<Z>, F>::G g;
    // eg7. hello(MyClass1 a, MyClass2* b
    // eg8. Label: A a;
    // TODO: eg9. A (*a)[10];

    const char *cases[] = {
        "const MyClass&",
        "const map < int, int >&",
        "MyNs::MyClass",
        "::MyClass**",
        "MyClass a, *b = NULL, c[1] = {};",
        "A<B>::C::D<E<Z>, F>::G g;",
        "hello(MyClass1 a, MyClass2* b",
        "A a;",
        "A (*a)[10];",
        "auto ::A<B, C<D, E> >::F<G>::H a;",
        "A<B>",
    };

    for ( size_t i = 0; i < ARRAY_SIZE(cases); ++i )
    {
        CxxTokenReader tokRdr;
        tokRdr.Init(cases[i]);
        cout << cases[i] << " ->\n";
        CxxType t = CxxParseType(tokRdr);
        cout << t.ToString() << endl;
        cout << t.ToPyEvalStr() << endl;
    }
}

TEST(CxxHWParser, CxxParseNamespaceInfo)
{
    const char *cases[] = {
        "   using  namespace   std ::  tr1;",
        "  using    std  :: string;    ",
        "   namespace xyz  =  abc :: def:: ghi ; ",
        " void std::string();",
    };

    const char *expects[] = {
        "{\"usingns\": [\"std::tr1\"], \"using\": {}, \"nsalias\": {}}",
        "{\"usingns\": [], \"using\": {\"string\": \"std::string\"}, \"nsalias\": {}}",
        "{\"usingns\": [], \"using\": {}, \"nsalias\": {\"xyz\": \"abc::def::ghi\"}}",
        "{\"usingns\": [], \"using\": {}, \"nsalias\": {}}",
    };

    for ( size_t i = 0; i < ARRAY_SIZE(cases); ++i )
    {
        NSInfo nsinfo;
        CxxTokenReader tokRdr;
        tokRdr.Init(cases[i]);
        CxxParseNamespaceInfo(tokRdr, nsinfo);;
        //cout << nsinfo.ToPyEvalStr() << endl;
        ASSERT_STREQ(expects[i], nsinfo.ToPyEvalStr().c_str());
    }
}

TEST(x, y)
{
    CxxTokenReader tokRdr;
    tokRdr.Init("const std::map<int, int> &map)");
    IntSet ints;
    ints.insert(CXX_OP_Comma);
    ints.insert(CXX_OP_RParen);
    SkipToOneOf(tokRdr, ints, CXX_OP_LT, CXX_OP_GT);
}
