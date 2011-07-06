#!/usr/bin/env python
# -*- coding:utf-8 -*-

import TagsStorageSQLite as TagsStorage
from TagEntry import ToFullKind, ToFullKinds



def TagEntry2Tag(tagEntry):
    '''把 python 的 TagEntry 转为 vim 的 tag 字典'''
    tag = {} # taglist() 返回的列表的项目
    # 必不可少的五个字段
    # omnicpp 需要完整的名字
    #tag['name'] = tagEntry.GetPath()
    tag['name'] = tagEntry.GetName()
    tag['filename'] = tagEntry.GetFile()
    # FIXME: 若模式中有单引号暂无办法安全传到 vim
    # 即使替换成 vim 的双单引号转义, 最终显示的是 "\'\'", 无解!
    tag['cmd'] = tagEntry.GetPattern().replace("'", " ")
    # 全称改为简称, 用命令参数控制
    tag['kind'] = tagEntry.GetAbbrKind()
    tag['static'] = 0 # 作用不明

    # 附加
    tag['parent'] = tagEntry.GetParent() # 父亲的名字, 不带路径
    tag['scope'] = tagEntry.GetScope()
    tag['path'] = tagEntry.GetPath()
    tag['qualifiers'] = tagEntry.GetQualifiers()

    # 附加字段
    if tagEntry.GetAccess():
        tag['access'] = tagEntry.GetAccess()
    if tagEntry.GetInherits():
        tag['inherits'] = tagEntry.GetInherits()
    if tagEntry.GetSignature():
        tag['signature'] = tagEntry.GetSignature()
    if tagEntry.GetTyperef():
        tag['typeref'] = tagEntry.GetTyperef()
    if tagEntry.GetParentType():
        tag[tagEntry.GetParentType()]\
                = tagEntry.GetScope()

    return tag

def TagEntries2Tags(tagEntries):
    tags = [] # 符合 vim 接口的 tags 列表
    tags = []
    for tagEntry in tagEntries:
        tags.append(TagEntry2Tag(tagEntry))
    return tags



class VimTagsManager:
    def __init__(self, dbFile = ''):
        self.storage = TagsStorage.TagsStorageSQLite()
        if dbFile:
            self.storage.OpenDatabase(dbFile)

    def OpenDatabase(self, dbFile):
        self.storage.OpenDatabase(dbFile)

    def CloseDatabase(self):
        self.storage = TagsStorage.TagsStorageSQLite()

    def RecreateDatabase(self):
        self.storage.RecreateDatabase()

    def ParseFiles(self, files, replacements = [], indicator = None):
        TagsStorage.ParseFilesAndStore(files, self.storage, replacements, 
                                       indicator = indicator)

    def GetTagsByScopeAndName(self, scope, name):
        tagEntries = self.storage.GetTagsByScopeAndName(scope, name, True)
        return TagEntries2Tags(tagEntries)

    def GetTagsByScopesAndName(self, scopes, name):
        tagEntries = self.storage.GetTagsByScopeAndName(scopes, name, True)
        return TagEntries2Tags(tagEntries)

    def GetOrderedTagsByScopesAndName(self, scopes, name):
        tagEntries = self.storage.GetOrderedTagsByScopesAndName(
            scopes, name, True)
        return TagEntries2Tags(tagEntries)

    def GetTagsByScopeAndKind(self, scope, kind):
        return self.GetTagsByScopesAndKinds([scope], [kind])

    def GetTagsByScopesAndKinds(self, scopes, kinds):
        tagEntries = self.storage.GetTagsByScopesAndKinds(scopes, 
                                                          ToFullKinds(kinds))
        return TagEntries2Tags(tagEntries)

    def GetTagsByPath(self, path):
        tagEntries = self.storage.GetTagsByPath(path)
        return TagEntries2Tags(tagEntries)

    def GetTagsByKindAndPath(self, kind, path):
        tagEntries = self.storage.GetTagsByKindAndPath(ToFullKind(kind), path)
        return TagEntries2Tags(tagEntries)

if __name__ == '__main__':
    vtm = VimTagsManager()
    vtm.OpenDatabase('TestTags3.db')
    print vtm.storage.fileName
    #tags = vtm.GetTagsByScopesAndKinds(
        #['DFoo', 'Foo', 'Foo2'], ['member', 'function'])
    #print str(tags)
    #tags = vtm.GetTagsByScopesAndName(['DFoo', 'Foo', 'Foo2'], '')
    #tags = vtm.GetTagsByScopeAndName(['<global>'], 'test')
    tags = vtm.GetTagsByPath('TestNamespace')
    print tags
    print len(tags)
    for tag in tags:
        print tag['name']

