#ifndef __CTAGSDATABASE_HPP__
#define __CTAGSDATABASE_HPP__

#include <list>
#include <string>
#include <iostream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <tr1/unordered_map>
#include <sqlite3.h>

class TagEntry {
public:
    TagEntry();
    ~TagEntry();

    std::string & GetName()
    { return m_name; }
    void SetName(const std::string &name)
    { m_name = name; }

    std::string & GetFile()
    { return m_file; }
    void SetFile(const std::string &file)
    { m_file = file; }

    unsigned int GetLine()
    { return m_line; }
    void SetLine(unsigned int line)
    { m_line = line; }

    std::string & GetText()
    { return m_text; }
    void SetText(const std::string &text)
    { m_text = text; }

    std::string & GetKind()
    { return m_kind; }
    void SetKind(const std::string &kind)
    { m_kind = kind; }

    std::string & GetParent()
    { return m_parent; }
    void SetParent(const std::string &parent)
    { m_parent = parent; }

    std::string & GetPath()
    { return m_path; }
    void SetPath(const std::string &path)
    { m_path = path; }

    std::string & GetScope()
    { return m_scope; }
    void SetScope(const std::string &scope)
    { m_scope = scope; }

    std::string GetAccess()
    { return GetExtFiled("access"); }
    void SetAccess(const std::string &access)
    { m_extFields["access"] = access; }

    std::string GetInherits()
    { return GetExtFiled("inherits"); }
    void SetInherits(const std::string &inherits)
    { m_extFields["inherits"] = inherits; }

    std::string GetReturn()
    { return GetExtFiled("return"); }
    void SetReturn(const std::string &ret)
    { m_extFields["return"] = ret; }

    std::string GetSignature()
    { return GetExtFiled("signature"); }
    void SetSignature(const std::string &signature)
    { m_extFields["signature"] = signature; }

    std::string GetTemplate()
    { return GetExtFiled("template"); }
    void SetTemplate(const std::string &tmpl)
    { m_extFields["template"] = tmpl; }

    std::string GetTyperef()
    { return GetExtFiled("typeref"); }
    void SetTyperef(const std::string &typeref)
    { m_extFields["typeref"] = typeref; }

    std::string GetParentType()
    { return GetExtFiled("parent_type"); }
    void SetParentType(const std::string &pt)
    { m_extFields["parent_type"] = pt; }

    void Print(FILE *fp = stdout)
    {
        using namespace std;
        using namespace tr1;
        fprintf(fp, "======================================\n");
        fprintf(fp, "Name:\t\t%s\n", GetName().c_str());
        fprintf(fp, "File:\t\t%s\n", GetFile().c_str());
        fprintf(fp, "Line:\t\t%u\n", GetLine());
        fprintf(fp, "Text:\t\t%s\n", GetText().c_str());
        fprintf(fp, "Kind:\t\t%s\n", GetKind().c_str());
        fprintf(fp, "Parent:\t\t%s\n", GetParent().c_str());
        fprintf(fp, "Path:\t\t%s\n", GetPath().c_str());
        fprintf(fp, "Scope:\t\t%s\n", GetScope().c_str());
        fprintf(fp, " ---- Ext fields: ---- \n");
        for ( unordered_map<string, string>::iterator it = m_extFields.begin();
              it != m_extFields.end(); ++it )
        {
            if ( !it->second.empty() )
            {
                fprintf(fp, "%s:\t\t%s\n",
                        it->first.c_str(), it->second.c_str());
            }
        }
        fprintf(fp, "======================================\n");
    }

protected:
    std::string GetExtFiled(const std::string &field)
    {
        if ( m_extFields.find(field) == m_extFields.end() )
        {
            return "";
        }
        else
        {
            return m_extFields[field];
        }
    }
    void SetExtField(const std::string &field, const std::string &value)
    { m_extFields[value] = value; }

private:
    std::string m_name;

    std::string m_file;
    unsigned int m_line;
    std::string m_text;

    std::string m_pattern;

    std::string m_kind;
    std::string m_parent;
    std::string m_path;
    std::string m_scope;
    
    std::tr1::unordered_map<std::string, std::string> m_extFields;
};

class CTagsDatabase {
public:
    CTagsDatabase();
    ~CTagsDatabase();

    int Init(const char *zDbFile);
    void Term();

    int GetOrderedTagsByScopesAndName(std::list<TagEntry> &tags,
                                      const std::list<std::string> &scopes,
                                      const std::string &name,
                                      bool partialMath = false);

    // kind 是全称，例如 "class", "struct"
    int GetTagsByKindAndPath(std::list<TagEntry> &tags,
                             const std::string &kind,
                             const std::string &path)
    { return GetTagsByKindsAndPath(tags, std::list<std::string>(1, kind), path); }

    int GetTagsByKindsAndPath(std::list<TagEntry> &tags,
                              const std::list<std::string> &kinds,
                              const std::string &path);

    int GetTagsByPaths(std::list<TagEntry> &tags,
                       const std::list<std::string> &paths);

    int GetTagsByPath(std::list<TagEntry> &tags, const std::string &path)
    { return GetTagsByPaths(tags, std::list<std::string>(1, path)); }

protected:
    // 这个方法不要随便调用，确保 sqlite3_step() 返回 SQLITE_ROW 才可调用
    void TagEntryFromRow(sqlite3_stmt *pStmt, TagEntry &tag);
    int FetchTags(std::list<TagEntry> &tags, const std::string &sql);

private:
    sqlite3 *m_pDb; // sqlite3 数据库
};

#endif /* __CTAGSDATABASE_HPP__ */
/* vi:set et sts=4: */
