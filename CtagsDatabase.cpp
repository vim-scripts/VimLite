#include <sqlite3.h>
#include <list>
#include <string>
#include <iostream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <tr1/unordered_map>
#include "CtagsDatabase.hpp"
#include "pystring.h"

#define SEARCH_LIMIT std::string("1000")

using namespace std;

TagEntry::TagEntry()
{
    m_line = 0;
}

TagEntry::~TagEntry()
{
}


CTagsDatabase::CTagsDatabase()
{
    m_pDb = NULL;
}

CTagsDatabase::~CTagsDatabase()
{
    Term();
}

void CTagsDatabase::Term()
{
    if ( m_pDb != NULL )
    {
        sqlite3_close(m_pDb);
    }
    m_pDb = NULL;
}

int CTagsDatabase::Init(const char *zDbFile)
{
    int ret = sqlite3_open(zDbFile, &m_pDb);
    if ( ret != 0 )
    {
        return ret;
    }
    return 0;
}

int CTagsDatabase::GetOrderedTagsByScopesAndName(
        std::list<TagEntry> &tags,
        const std::list<std::string> &scopes, const std::string &name,
        bool partialMath)
{
    string name2 = pystring::replace(name, "_", "^_");
    string sql = "SELECT * FROM TAGS WHERE SCOPE IN('";
    sql += pystring::join("', '", scopes);
    sql += "') ";

    if ( partialMath )
    {
        sql += "AND name LIKE '" + name2 + "%' ESCAPE '^' ";
    }
    else
    {
        sql += "AND name = '" + name + "' ";
    }

    sql += "ORDER BY name ASC ";
    sql += "LIMIT " + SEARCH_LIMIT;

    return FetchTags(tags, sql);
}

int CTagsDatabase::GetTagsByKindsAndPath(std::list<TagEntry> &tags,
                                         const std::list<std::string> &kinds,
                                         const std::string &path)
{
    string sql = "SELECT * FROM TAGS WHERE path = '" + path + "' ";
    sql += "AND kind IN('";
    sql += pystring::join("', '", kinds);
    sql += "')";
    return FetchTags(tags, sql);
}

int CTagsDatabase::GetTagsByPaths(std::list<TagEntry> &tags,
                                  const std::list<std::string> &paths)
{
    string sql = "SELECT * FROM TAGS WHERE path IN('";
    sql += pystring::join("', '", paths);
    sql += "')";
    return FetchTags(tags, sql);
}

int CTagsDatabase::FetchTags(std::list<TagEntry> &tags, const std::string &sql)
{
    sqlite3_stmt *pStmt = NULL;
    sqlite3_prepare_v2(m_pDb, sql.c_str(), sql.length(), &pStmt, NULL);
    if ( pStmt == NULL )
    {
        return -1;
    }
    while ( sqlite3_step(pStmt) == SQLITE_ROW )
    {
#if 0
        for ( int i = 0; i < sqlite3_column_count(pStmt); ++i )
        {
            cout << sqlite3_column_text(pStmt, i) << "|";
        }
        cout << "\n";
#endif
        TagEntry tag;
        TagEntryFromRow(pStmt, tag);
        tags.push_back(tag);
    }
    sqlite3_finalize(pStmt);
    pStmt = NULL;
    return 0;
}

void CTagsDatabase::TagEntryFromRow(sqlite3_stmt *pStmt, TagEntry &tag)
{
    tag.SetName((const char *)sqlite3_column_text(pStmt, 1));
    tag.SetFile((const char *)sqlite3_column_text(pStmt, 2));
    tag.SetLine(sqlite3_column_int(pStmt, 3));
    tag.SetText((const char *)sqlite3_column_text(pStmt, 4));

    tag.SetAccess((const char *)sqlite3_column_text(pStmt, 5));
    tag.SetInherits((const char *)sqlite3_column_text(pStmt, 6));
    tag.SetKind((const char *)sqlite3_column_text(pStmt, 7));
    tag.SetParent((const char *)sqlite3_column_text(pStmt, 8));
    tag.SetParentType((const char *)sqlite3_column_text(pStmt, 9));
    tag.SetPath((const char *)sqlite3_column_text(pStmt, 10));
    tag.SetReturn((const char *)sqlite3_column_text(pStmt, 11));
    tag.SetScope((const char *)sqlite3_column_text(pStmt, 12));
    tag.SetSignature((const char *)sqlite3_column_text(pStmt, 13));
    tag.SetTemplate((const char *)sqlite3_column_text(pStmt, 14));
    tag.SetTyperef((const char *)sqlite3_column_text(pStmt, 15));
}

void PrintTags(list<TagEntry> &tags)
{
    list<TagEntry>::iterator it = tags.begin();
    for ( ; it != tags.end(); it++ )
    {
        it->Print();
    }
}

#if 0
int main(int argc, char **argv)
{
    CTagsDatabase db;
    if ( db.Init("./test.vltags") != 0 )
    {
        cerr << "open database failed!" << endl;
        return 1;
    }
    std::list<string> scopes;
    std::list<TagEntry> tags;
    std::list<string> paths;
    std::list<string> kinds;
    std::string name;
    std::string path;
    std::string kind;

    tags.clear();
    db.GetTagsByPath(tags, "Cls::Cls");
    //PrintTags(tags);

    tags.clear();
    paths.clear();
    paths.push_back("Cls::Cls");
    paths.push_back("Cls::m_n");
    paths.push_back("Cls::m_x");
    db.GetTagsByPaths(tags, paths);
    //PrintTags(tags);

    tags.clear();
    scopes.clear();
    scopes.push_back("<global>");
    scopes.push_back("Cls");
    name = "m_";
    db.GetOrderedTagsByScopesAndName(tags, scopes, name, true);
    PrintTags(tags);

    tags.clear();
    path = "Cls";
    kind = "class";
    db.GetTagsByKindAndPath(tags, kind, path);
    PrintTags(tags);

    tags.clear();
    path = "Cls::m_n";
    kinds.push_back("class");
    kinds.push_back("member");
    db.GetTagsByKindsAndPath(tags, kinds, path);
    PrintTags(tags);

    return 0;
}
#endif

/* vi:set et sts=4: */
