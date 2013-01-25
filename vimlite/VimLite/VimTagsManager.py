#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import threading
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
    # 暂时只能替换为空格(可以约定一个特殊字符然后替换?)
    #tag['cmd'] = tagEntry.GetPattern().replace("'", " ")
    tag['cmd'] = tagEntry.GetText() # 这个域暂时用 'text' 域填充
    # 全称改为简称, 用命令参数控制
    tag['kind'] = tagEntry.GetAbbrKind()
    tag['static'] = 0 # 作用不明

    # 必不可少的附加域
    tag['text'] = tagEntry.GetText()
    tag['line'] = tagEntry.GetLine() # 行号, 用于定位
    tag['parent'] = tagEntry.GetParent() # 父亲的名字, 不带路径
    tag['path'] = tagEntry.GetPath()
    tag['scope'] = tagEntry.GetScope()

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
        tag[tagEntry.GetParentType()] = tagEntry.GetScope()
    if tagEntry.GetTemplate():
        tag['template'] = tagEntry.GetTemplate()
    if tagEntry.GetReturn():
        tag['return'] = tagEntry.GetReturn()

    return tag

def TagEntries2Tags(tagEntries):
    tags = [] # 符合 vim 接口的 tags 列表
    tags = []
    for tagEntry in tagEntries:
        tags.append(TagEntry2Tag(tagEntry))
    return tags

AppendCtagsOpt = TagsStorage.AppendCtagsOpt

class ParseFilesThread(threading.Thread):
    '''同时只允许单个线程工作'''
    lock = threading.Lock()

    def __init__(self, dbFile, files, macrosFiles = [],
                 PostCallback = None, callbackPara = None,
                 filterNotNeed = True):
        '''
        异步 parse 文件线程
        NOTE: sqlite3 是线程安全的
        NOTE: 不同线程不能使用同一个连接实例，必须新建
        '''
        threading.Thread.__init__(self)

        self.dbFile = dbFile
        self.files = files
        self.macrosFiles = macrosFiles

        self.PostCallback = PostCallback
        self.callbackPara = callbackPara
        self.filterNotNeed = filterNotNeed

    def run(self):
        ParseFilesThread.lock.acquire()

        try:
            storage = TagsStorage.TagsStorageSQLite()
            storage.OpenDatabase(self.dbFile)
            TagsStorage.ParseFilesAndStore(storage, self.files,
                                           self.macrosFiles, self.filterNotNeed)
            del storage
        except:
            print 'ParseFilesThread() failed'

        ParseFilesThread.lock.release()

        if self.PostCallback:
            try:
                self.PostCallback(self.callbackPara)
            except:
                pass


class VimTagsManager:
    def __init__(self, dbFile = ''):
        self.storage = TagsStorage.TagsStorageSQLite()
        if dbFile:
            self.storage.OpenDatabase(dbFile)

        self.parseThread = threading.Thread()
        self.parseThread.start()

    def OpenDatabase(self, dbFile):
        self.storage.OpenDatabase(dbFile)

    def CloseDatabase(self):
        self.storage = TagsStorage.TagsStorageSQLite()

    def RecreateDatabase(self):
        self.storage.RecreateDatabase()

    def AsyncParseFiles(self, files, macrosFiles = [],
                        PostCallback = None, callbackPara = None,
                        filterNotNeed = True):
        # 暂时只允许单个异步 parse
        try:
            self.parseThread.join()
        except RuntimeError:
            pass

        self.parseThread = ParseFilesThread(self.storage.GetDatabaseFileName(),
                                            files, macrosFiles,
                                            PostCallback, callbackPara,
                                            filterNotNeed)
        self.parseThread.start()

    def ParseFiles(self, files, macrosFiles = [], indicator = None):
        # 需要等待 parse 线程
        try:
            self.parseThread.join()
        except RuntimeError:
            pass
        TagsStorage.ParseFilesAndStore(self.storage, files, macrosFiles, 
                                       indicator = indicator)

    def DeleteTagsByFile(self, fn):
        return self.DeleteTagsByFiles([fn])

    def DeleteTagsByFiles(self, files):
        return self.storage.DeleteTagsByFiles(files)

    def DeleteFileEntry(self, fn):
        return self.DeleteFileEntries([fn])

    def DeleteFileEntries(self, files):
        return self.storage.DeleteFileEntries(files)

    def InsertFileEntry(self, fn, retagTime = int(time.time())):
        return self.storage.InsertFileEntry(fn, retagTime)

    def UpdateTagsFileColumnByFile(self, newFile, oldFile):
        return self.storage.UpdateTagsFileColumnByFile(newFile, oldFile)

    def GetTagsByScopeAndName(self, scope, name):
        tagEntries = self.storage.GetTagsByScopeAndName(scope, name, True)
        return TagEntries2Tags(tagEntries)

    def GetTagsByScopesAndName(self, scopes, name, partialMatch = True):
        tagEntries = self.storage.GetTagsByScopeAndName(
            scopes, name, partialMatch)
        return TagEntries2Tags(tagEntries)

    def GetOrderedTagsByScopesAndName(self, scopes, name, partialMatch = True):
        tagEntries = self.storage.GetOrderedTagsByScopesAndName(
            scopes, name, partialMatch)
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


def test():
    import time
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

    def Test(x):
        print 'Test()'

    #return
    #print '=' * 40
    #print "start"
    vtm.AsyncParseFiles(['/usr/include/stdio.h'],
                        PostCallback = Test, callbackPara = None)
    while True:
        if vtm.parseThread.isAlive():
            print "parsing"
        else:
            print "End"
            break

if __name__ == '__main__':
    test()

