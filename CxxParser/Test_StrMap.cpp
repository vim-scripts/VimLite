#include <iostream>
#include <gtest/gtest.h>
#include "StrMap.hpp"

using namespace std;

TEST(StrMap, 01)
{
    StrMap<int> di;
    di.SetItem("abc", 10);
    di.SetItem("xyz", 100);
    cout << di.GetItem("xyz") << endl;
    cout << di.GetItem("abc") << endl;
    try
    {
        cout << di.GetItem("xxx") << endl;
    }
    catch (const StrMapKeyError &e)
    {
        cout << e.key << endl;
    }
    cout << di.Pop("xyz") << endl;
    try
    {
        cout << di.Pop("xyz") << endl;
    }
    catch (const StrMapKeyError &e)
    {
        cout << e.key << endl;
    }
    cout << di.GetCount() << endl;
    di.Clear();
    cout << di.GetCount() << endl;
}

