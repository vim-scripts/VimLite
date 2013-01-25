#!/usr/bin/env python
# -*- encoding:utf-8 -*-


from ITagsStorage import ITagsStorage
from TagEntry import TagEntry
from FileEntry import FileEntry

import os, os.path
import tempfile
import time
import subprocess
import platform
import sqlite3

# 这两个变量暂时只对本模块生效
CPP_SOURCE_EXT = set(['c', 'cpp', 'cxx', 'c++', 'cc'])
CPP_HEADER_EXT = set(['h', 'hpp', 'hxx', 'hh', 'inl', 'inc', ''])

# 由于无后缀名的文件会视为 c++ 的头文件，所以需要添加一个检查，以下无后缀文件
# 肯定不是 c++ 头文件。不区分大小写
____li = [
    'Makefile',
    'Kconfig',
    'README',
    'configure',
    'ChangeLog',
    'INSTALL',
]
CPP_HEADER_EXCLUDE = set([i.lower() for i in ____li])

def Escape(string, chars):
    result = ''
    for char in string:
        if char in chars:
            # 转义之
            result += '\\' + char
        else:
            result += char
    return result

def MakeQMarkString(count):
    '''生成用于 sqlite3 语句的问号占位符，是包括括号的，一般用 IN 语法
    count 表示需要的 ? 的数量'''
    if count <= 1:
        return "(?)"
    else:
        return "(%s)" % ", ".join(["?" for i in range(count)])

class TagsStorageSQLiteCache:
    '''tags 缓存'''
    def __init__(self):
        # 以 sql 语句为键值
        self.cache = {} # 字符串到标签条目列表的字典 {'fo': ['foo', 'foobar']}

    def DoGet(self, key):
        tags = []
        if self.cache.has_key(key):
            tags = self.cache[key][:]
        return tags

    def DoStore(self, key, tags):
        '''以 sql 语句为键值保存 tags 的副本'''
        self.cache[key] = tags[:]

    def Get(self, sql, kinds = []):
        if not kinds:
            return self.DoGet(sql)
        else:
            key = sql
            for kind in kinds:
                key += "@" + kind
            return self.DoGet(key)

    def Store(self, sql, tags, kinds = []):
        if not kinds:
            return self.DoStore(sql, tags)
        else:
            key = sql
            for kind in kinds:
                # 不是原始的 sql 语句, 是简化过的
                key += "@" + kind
            return self.DoStore(key, tags)

    def Clear(self):
        self.cache.clear()

tagsDatabaseVersion = 2000

class TagsStorageSQLite(ITagsStorage):
    def __init__(self):
        ITagsStorage.__init__(self)
        self.db = None      # sqlite3 的连接实例, 取此名字是为了与 codelite 统一
        self.cache = None   # TagsStorageSQLiteCache 类的实例

        # 测试时关闭缓存
        self.SetUseCache(False)

    def __del__(self):
        if self.db:
            self.db.close()
            self.db = None

    def GetVersion(self):
        return tagsDatabaseVersion

    def Begin(self):
        if self.db:
            try:
                self.db.execute("begin;")
            except sqlite3.OperationalError:
                pass

    def Commit(self):
        if self.db:
            try:
                self.db.commit()
            except sqlite3.OperationalError:
                pass

    def Rollback(self):
        if self.db:
            try:
                self.db.rollback()
            except sqlite3.OperationalError:
                pass

    def OpenDatabase(self, fileName = ''):
        # TODO: 验证文件是否有效

        # 如果相同, 表示已经打开了相同的数据库, 直接返回
        if self.fileName == os.path.abspath(fileName):
            return True

        # Did we get a file name to use?
        # 未打开任何数据库, 且请求打开的文件无效, 直接返回
        if not self.fileName and not fileName:
            return False

        # We did not get any file name to use BUT we
        # do have an open database, so we will use it
        # 传进来的是无效的文件, 但已经打开了某个数据库, 继续用之
        if not fileName:
            return True

        absFileName = os.path.abspath(fileName)
        if fileName == ':memory:':
            # 允许连接内存数据库
            absFileName = fileName

        try:
            if not self.fileName:
                # First time we open the db
                # 没有打开着的数据库
                self.db = sqlite3.connect(absFileName)
                self.db.text_factory = str # 以字符串方式保存而不是 unicode
                self.CreateSchema()
                self.fileName = absFileName
            else:
                # We have both fileName & self.fileName and they
                # are different, close previous db
                # 已经打开了某个数据库, 请求打开另外的, 需要先关闭旧的
                self.db.close()
                self.db = sqlite3.connect(absFileName)
                self.db.text_factory = str # 以字符串方式保存而不是 unicode
                self.CreateSchema()
                self.fileName = absFileName
            return True
        except sqlite3.OperationalError:
            return False

    def CreateSchema(self):
        try:
            # improve performace by using pragma command:
            # (this needs to be done before the creation of the
            # tables and indices)
            sql = "PRAGMA synchronous = OFF;"
            self.db.execute(sql)

            sql = "PRAGMA temp_store = MEMORY;"
            self.db.execute(sql)

            sql = "CREATE TABLE IF NOT EXISTS TAGS "\
                    "(ID INTEGER PRIMARY KEY AUTOINCREMENT, "\
                    "name string, file string, line integer, text string, "\
                    "access string, "\
                    "inherits string, "\
                    "kind string, "\
                    "parent string, "\
                    "parent_type string, "\
                    "path string, "\
                    "return string, "\
                    "scope string, "\
                    "signature string, "\
                    "template string, "\
                    "typeref string)"
            self.db.execute(sql)

            sql = "CREATE TABLE IF NOT EXISTS FILES (ID INTEGER PRIMARY KEY "\
                    "AUTOINCREMENT, file string, last_retagged integer);"
            self.db.execute(sql)

            # create unuque index on Files' file column
            sql = "CREATE UNIQUE INDEX IF NOT EXISTS FILES_NAME on FILES(file)"
            self.db.execute(sql)

            # Create unique index on tags table
            #sql = "CREATE UNIQUE INDEX IF NOT EXISTS TAGS_UNIQ on tags(kind, "\
                    #"path, signature);"
            # mod on 2011-01-07
            # 不同源文件文件之间会存在相同的符号
            sql = "CREATE UNIQUE INDEX IF NOT EXISTS TAGS_UNIQ on TAGS("\
                    "file, line, kind, path, signature);"
            self.db.execute(sql)

            sql = "CREATE INDEX IF NOT EXISTS KIND_IDX on TAGS(kind);"
            self.db.execute(sql)

            sql = "CREATE INDEX IF NOT EXISTS FILE_IDX on TAGS(file);"
            self.db.execute(sql)

            # Create search indexes
            sql = "CREATE INDEX IF NOT EXISTS TAGS_NAME on TAGS(name);"
            self.db.execute(sql)

            sql = "CREATE INDEX IF NOT EXISTS TAGS_SCOPE on TAGS(scope);"
            self.db.execute(sql)

            sql = "CREATE INDEX IF NOT EXISTS TAGS_PATH on TAGS(path);"
            self.db.execute(sql)

            sql = "CREATE INDEX IF NOT EXISTS TAGS_PARENT on TAGS(parent);"
            self.db.execute(sql)

            sql = "CREATE TABLE IF NOT EXISTS TAGS_VERSION (version INTEGER "\
                    "PRIMARY KEY);"
            self.db.execute(sql)

            sql = "CREATE UNIQUE INDEX IF NOT EXISTS TAGS_VERSION_UNIQ on "\
                    "TAGS_VERSION(version);"
            self.db.execute(sql)

            self.db.execute("INSERT OR REPLACE INTO TAGS_VERSION VALUES(?)",
                            (self.GetVersion(), ))

            # 必须提交
            self.Commit()
        except sqlite3.OperationalError:
            pass

    def RecreateDatabase(self):
        if not self.fileName:
            return

        fileName = self.fileName

        try:
            # commit any open transactions
            self.Commit()

            # Close the database
            if self.db:
                self.db.close()

            try:
                if self.fileName != ':memory:':
                    try:
                        os.remove(fileName)
                    except WindowsError:
                        print "WindowsError: remove %s failed" % fileName
                        pass
                else:
                    raise sqlite3.OperationalError
            except:
                # re-open the database
                self.fileName = ''
                self.OpenDatabase(fileName)

                # and drop tables
                self.db.execute("DROP TABLE IF EXISTS TAGS")
                self.db.execute("DROP TABLE IF EXISTS TAGS_VERSION")
                self.db.execute("DROP TABLE IF EXISTS FILES")

                # drop indexes
                self.db.execute("DROP INDEX IF EXISTS FILES_NAME")
                self.db.execute("DROP INDEX IF EXISTS TAGS_UNIQ")
                self.db.execute("DROP INDEX IF EXISTS KIND_IDX")
                self.db.execute("DROP INDEX IF EXISTS FILE_IDX")
                self.db.execute("DROP INDEX IF EXISTS TAGS_NAME")
                self.db.execute("DROP INDEX IF EXISTS TAGS_SCOPE")
                self.db.execute("DROP INDEX IF EXISTS TAGS_PATH")
                self.db.execute("DROP INDEX IF EXISTS TAGS_PARENT")
                self.db.execute("DROP INDEX IF EXISTS TAGS_VERSION_UNIQ")

                # Recreate the schema
                self.CreateSchema()
            else:
                # We managed to delete the file
                # re-open it
                self.fileName = ''
                self.OpenDatabase(fileName)
        except sqlite3.OperationalError:
            pass

    def GetSchemaVersion(self):
        try:
            version = ''
            sql = "SELECT * FROM TAGS_VERSION"
            for row in self.db.execute(sql):
                version = row[0]
            return version
        except sqlite3.OperationalError:
            pass
        return ''

    def Store(self, tagTree, dbFile = '', autoCommit = True, indicator = None):
        '''需要 tagTree
        
        tagTree 为标签的 path 树'''
        ret = False

        # 现阶段, 支持直接从标签文本保存
        if isinstance(tagTree, str):
            # 直接从字符串保存
            tags = tagTree

            if not dbFile and not self.fileName:
                return False

            if not tags:
                return False

            self.OpenDatabase(dbFile) # 这里, 如果 dbFile 为空, 表示使用原来的
            try:
                updateList = [] # 不存在的直接插入, 存在的需要更新

                if autoCommit:
                    self.Begin()
                    #self.db.execute('begin;')

                tagList = tags.split('\n')
                tagListLen = len(tagList)
                for idx, line in enumerate(tagList):
                    # does not matter if we insert or update, 
                    # the cache must be cleared for any related tags

                    if indicator:
                        indicator(idx, tagListLen - 1)

                    tagEntry = TagEntry()
                    tagEntry.FromLine(line)

                    if not self.InsertTagEntry(tagEntry):
                        # 插入不成功?
                        # InsertTagEntry() 貌似是不会失败的?!
                        updateList.append(tagEntry)

                if autoCommit:
                    self.Commit()

                # Do we need to update?
                if updateList:
                    if autoCommit:
                        self.Begin()
                        #self.db.execute('begin;')

                    for i in updateList:
                        self.UpdateTagEntry(i)

                    if autoCommit:
                        self.Commit()
                ret = True
            except sqlite3.OperationalError:
                ret = False
                try:
                    if autoCommit:
                        self.db.rollback()
                except sqlite3.OperationalError:
                    pass
        else:
            pass
        return ret

    def StoreFromTagFile(self, tagFile, dbFile = '', autoCommit = True):
        '''从 tags 文件保存'''
        ret = False

        if not dbFile and not self.fileName:
            return False

        if not tagFile:
            return False

        self.OpenDatabase(dbFile) # 这里, 如果 dbFile 为空, 表示使用原来的
        try:
            updateList = [] # 不存在的直接插入, 存在的需要更新

            if autoCommit:
                self.Begin()

            try:
                f = open(tagFile)
            except:
                return False

            for line in f:
                # does not matter if we insert or update, 
                # the cache must be cleared for any related tags
                if line.startswith('!'): # 跳过注释
                    continue

                tagEntry = TagEntry()
                tagEntry.FromLine(line)

                if not self.InsertTagEntry(tagEntry):
                    # 插入不成功?
                    # InsertTagEntry() 貌似是不会失败的?!
                    updateList.append(tagEntry)

                # enumerator 要双份，因为在两个作用域内有效
                # added on 2012-05-17
                #if tagEntry.GetParentType() == 'enum':
                #    tagEntryDup = tagEntry
                #    # 需要修改 scope 和 path
                #    scope = tagEntryDup.GetScope()
                #    # 扔掉 scope 最后的部分
                #    scope = '::'.join(scope.split('::')[:-1])
                #    if not scope:
                #        scope = '<global>'
                #    tagEntryDup.SetScope(scope)
                #    tagEntryDup.UpdatePath(scope)
                #    if not self.InsertTagEntry(tagEntryDup):
                #        updateList.append(tagEntryDup)

            if autoCommit:
                self.Commit()

            # Do we need to update?
            if updateList:
                if autoCommit:
                    self.Begin()

                for i in updateList:
                    self.UpdateTagEntry(i)

                if autoCommit:
                    self.Commit()

            f.close()
            ret = True
        except sqlite3.OperationalError:
            ret = False
            try:
                if autoCommit:
                    self.db.rollback()
            except sqlite3.OperationalError:
                pass

        return ret

    def SelectTagsByFile(self, file, dbFile = ''):
        '''取出属于 file 文件的全部标签'''
        # Incase empty dbFile is provided, use the current file name
        if not dbFile:
            dbFile = self.fileName
        self.OpenDatabase(dbFile)

        sql = "select * from tags where file='" + file + "' "
        return self.DoFetchTags(sql)

    def DeleteByFileName(self, dbFile, fileName, autoCommit = True):
        # [DEPRECATE]
        '''删除属于指定文件名 fileName 的所有标签'''
        # make sure database is open
        try:
            self.OpenDatabase(dbFile)
            if autoCommit:
                self.Begin()
                #self.db.execute('begin;')

            self.db.execute("DELETE FROM TAGS WHERE file=?", (fileName, ))

            if autoCommit:
                self.Commit()
        except:
            if autoCommit:
                self.db.rollback()

    def DeleteTagsByFiles(self, files, dbFile = '', autoCommit = True):
        '''删除属于指定文件名 fileName 的所有标签'''
        ret = False
        # make sure database is open
        self.OpenDatabase(dbFile)
        try:
            if autoCommit:
                self.Begin()

            self.db.execute(
                "DELETE FROM tags WHERE file IN('%s')" % "', '".join(files))

            if autoCommit:
                self.Commit()
            ret = True
        except:
            ret = False
            if autoCommit:
                self.db.rollback()
        return ret

    def UpdateTagsFileColumnByFile(self, newFile, oldFile, autoCommit = True):
        ret = False
        try:
            if autoCommit:
                self.Begin()
            self.db.execute("UPDATE TAGS set file=? WHERE file=?",
                            (newFile, oldFile))
            if autoCommit:
                self.Commit()
            ret = True
        except:
            ret = False
            if autoCommit:
                self.Rollback()
        return ret

    def Query(self, sql, dbFile = ''):
        '''Execute a query sql and return result set.
        
        这个函数特别之处在于自动 OpenDatabase()'''
        try:
            self.OpenDatabase(dbFile)
            return self.db.execute(sql)
        except:
            pass
        return [] # 具备迭代器的空对象

    def ExecuteUpdate(self, sql):
        try:
            self.db.execute(sql)
        except:
            pass

    def IsOpen(self):
        if self.db:
            return True
        else:
            return False

    def GetFiles(self, partialName = ''):
        files = []

        if not partialName:
            try:
                sql = "select * from files order by file"
                res = self.db.execute(sql)
                for row in res:
                    fe = FileEntry()
                    fe.SetId(row[0])
                    fe.SetFile(row[1])
                    fe.SetLastRetaggedTimestamp(row[2])
                    files.append(fe)
            except:
                pass
        else:
            try:
                matchPath = partialName and partialName.endswith(os.sep)
                tmpName = partialName.replace('_', '^_')
                sql = "select * from files where file like '%" + tmpName \
                        + "%' ESCAPE '^' "
                res = self.db.execute(sql)
                for row in res:
                    fe = FileEntry()
                    fe.SetId(row[0])
                    fe.SetFile(row[1])
                    fe.SetLastRetaggedTimestamp(row[2])

                    fileName = fe.GetFile()
                    match = os.path.basename(fileName)
                    if matchPath:
                        match = fileName

                    # TODO: windows 下文件名全部保存为小写

                    if match.startswith(partialName):
                        files.append(fe)
            except:
                pass

        return files

    def GetFilesMap(self, matchFiles = []):
        '''返回文件到文件条目的字典, 方便比较'''
        filesMap = {}

        if not matchFiles:
            try:
                sql = "select * from files order by file"
                res = self.db.execute(sql)
                for row in res:
                    fe = FileEntry()
                    fe.SetId(row[0])
                    fe.SetFile(row[1])
                    fe.SetLastRetaggedTimestamp(row[2])
                    filesMap[fe.GetFile()] = fe
            except:
                pass
        else:
            try:
                sql = "select * from files where file in('%s')" \
                        % "','".join(matchFiles)
                res = self.db.execute(sql)
                for row in res:
                    fe = FileEntry()
                    fe.SetId(row[0])
                    fe.SetFile(row[1])
                    fe.SetLastRetaggedTimestamp(row[2])
                    filesMap[fe.GetFile()] = fe
            except:
                pass

        return filesMap

    def DeleteByFilePrefix(self, dbFile, filePrefix):
        try:
            self.OpenDatabase(dbFile)
            sql = "delete from tags where file like '" \
                    + filePrefix.replace('_', '^_') + "%' ESCAPE '^' "
            self.db.execute(sql)
        except:
            pass

    def DeleteFromFiles(self, files):
        if not files:
            return

        sql = "delete from FILES where file in ("
        for file in files:
            sql += "'" + file + "',"

        # remove last ','
        sql = sql[:-1] + ')'

        try:
            self.db.execute(sql)
        except:
            pass

    def DeleteFromFilesByPrefix(self, dbFile, filePrefix):
        try:
            self.OpenDatabase(dbFile)
            sql = "delete from FILES where file like '" \
                    + filePrefix.replace('_', '^_') + "%' ESCAPE '^' "
            self.db.execute(sql)
        except:
            pass

    def PPTokenFromSQlite3ResultSet(self, rs, token):
        pass

    def FromSQLite3ResultSet(self, row):
        '''从数据库的一行数据中提取标签对象'''
        entry = TagEntry()
        entry.SetId         (row[0])
        entry.SetName       (row[1])
        entry.SetFile       (row[2])
        entry.SetLine       (row[3])
        entry.SetText       (row[4])

        entry.SetAccess     (row[5])
        entry.SetInherits   (row[6])
        entry.SetKind       (row[7])
        entry.SetParent     (row[8])
        entry.SetParentType (row[9])
        entry.SetPath       (row[10])
        entry.SetReturn     (row[11])
        entry.SetScope      (row[12])
        entry.SetSignature  (row[13])
        entry.SetTemplate   (row[14])
        entry.SetTyperef    (row[15])

        return entry

    def DoFetchTags(self, sql, kinds = []):
        '''从数据库中取出 tags'''
        tags = []

        if not kinds:
            if self.GetUseCache():
                # 尝试从缓存中获取
                tags = self.cache.Get(sql)
                if tags:
                    print '[CACHED ITEMS] %s\n' % sql
                    return

            try:
                exRs = self.Query(sql)

                # add results from external database to the workspace database
                for row in exRs:
                    tag = self.FromSQLite3ResultSet(row)
                    tags.append(tag)
            except:
                pass

            if self.GetUseCache():
                # 保存到缓存以供下次快速使用
                self.cache.Store(sql, tags)
        else:
            if self.GetUseCache():
                # 尝试从缓存中获取
                tags = self.cache.Get(sql, kinds)
                if tags:
                    print '[CACHED ITEMS] %s\n' % sql
                    return

            try:
                exRs = self.Query(sql)
                for row in exRs:
                    try:
                        kinds.index(row[7])
                    except ValueError:
                        continue
                    else:
                        tag = self.FromSQLite3ResultSet(row)
                        tags.append(tag)
            except:
                pass

            if self.GetUseCache():
                # 保存到缓存以供下次快速使用
                self.cache.Store(sql, tags, kinds)

        return tags

    def GetTagsByScopeAndName(self, scope, name, partialNameAllowed = False):
        if type(scope) == type(''):
            if not scope:
                return []

            tmpName = name.replace('_', '^_')

            sql = "select * from tags where "

            # did we get scope?
            if scope:
                sql += "scope='" + scope + "' and "

            # add the name condition
            if partialNameAllowed:
                sql += " name like '" + tmpName + "%' ESCAPE '^' "
            else:
                sql += " name ='" + name + "' "

            sql += " LIMIT " + str(self.GetSingleSearchLimit())

            # get the tags
            return self.DoFetchTags(sql)
        elif type(scope) == type([]):
            scopes = scope
            if not scopes:
                return []

            tmpName = name.replace('_', '^_')

            sql = "select * from tags where scope in("
            for i in scopes:
                sql += "'" + i + "',"
            sql = sql[:-1] + ") and "

            # add the name condition
            if partialNameAllowed:
                sql += " name like '" + tmpName + "%' ESCAPE '^' "
            else:
                sql += " name ='" + name + "' "

            # get the tags
            return self.DoFetchTags(sql)
        else:
            return []

    def GetOrderedTagsByScopesAndName(self, scopes, name, partialMatch = False):
        '''获取按名字升序排序后的 tags'''
        if not scopes:
            return []

        tmpName = name.replace('_', '^_')

        sql = "select * from tags where scope in("
        for i in scopes:
            sql += "'" + i + "',"
        sql = sql[:-1] + ") and "

        # add the name condition
        if partialMatch:
            sql += " name like '" + tmpName + "%' ESCAPE '^' "
        else:
            sql += " name ='" + name + "' "

        sql += 'order by name ASC'
        sql += ' LIMIT ' + str(self.GetSingleSearchLimit())

        # get the tags
        return self.DoFetchTags(sql)

    def GetTagsByScope(self, scope):
        sql = "select * from tags where scope='" + scope + "' limit " \
                + str(self.GetSingleSearchLimit())
        return self.DoFetchTags(sql)

    def GetTagsByKinds(self, kinds, orderingColumn, order):
        sql = "select * from tags where kind in ("
        for i in kinds:
            sql += "'" + i + "',"

        sql = sql[:-1] + ") "

        if orderingColumn:
            sql += "order by " + orderingColumn
            if order == ITagsStorage.OrderAsc:
                sql += " ASC"
            elif order == ITagsStorage.OrderDesc:
                sql += " DESC"
            else:
                pass

        return self.DoFetchTags(sql)

    def GetTagsByPath(self, path):
        if type(path) == type([]):
            sql = "select * from tags where path IN("
            for i in path:
                sql += "'" + i + "',"
            sql = sql[:-1] + ") "
            return self.DoFetchTags(sql)
        else:
            # FIXME: 为什么要 LIMIT 1 ？
            #sql = "select * from tags where path ='" + path + "' LIMIT 1"
            sql = "select * from tags where path ='%s'" % path
            # NOTE: 为什么？按照函数语义，不应该这么做，应该交给外层过滤
            #sql = "select * from tags where path ='%s' and kind != 'externvar' "\
                    #"LIMIT 1" % (path, )
            return self.DoFetchTags(sql)

    def GetTagsByPaths(self, paths):
        return self.GetTagsByPath(paths)

    def GetTagsByNameAndParent(self, name, parent):
        '''根据标签名称和其父亲获取标签'''
        sql = "select * from tags where name='" + name + "'"
        tags = self.DoFetchTags(sql)

        # 过滤掉不符合要求的标签
        return [i for i in tags if i.GetParent() == parent]

    def GetTagsByKindsAndPath(self, kinds, path):
        if not kinds:
            return []

        sql = "select * from tags where path='" + path + "'"
        return self.DoFetchTags(sql, kinds)

    def GetTagsByKindAndPath(self, kind, path):
        return self.GetTagsByKindsAndPath([kind], path)

    def GetTagsByFileAndLine(self, file, line):
        sql = "select * from tags where file='" + file \
                + "' and line=" + line + " "
        return self.DoFetchTags(sql)

    def GetTagsByScopeAndKind(self, scope, kind):
        return self.GetTagsByScopesAndKinds([scope], [kind])

    def GetTagsByScopeAndKinds(self, scope, kinds):
        if not kinds:
            return []

        sql = "select * from tags where scope='" + scope + "'"
        return self.DoFetchTags(sql, kinds)

    def GetTagsByKindsAndFile(self, kinds, fileName, orderingColumn, order):
        if not kinds:
            return []

        sql = "select * from tags where file='" + fileName + "' and kind in ("
        for i in kinds:
            sql += "'" + i + "',"
        sql = sql[:-1] + ")"

        if orderingColumn:
            sql += "order by " + orderingColumn
            if order == ITagsStorage.OrderAsc:
                sql += " ASC"
            elif order == ITagsStorage.OrderDesc:
                sql += " DESC"
            else:
                pass

        return self.DoFetchTags(sql)

    def DeleteFileEntry(self, fileName):
        try:
            self.db.execute("DELETE FROM FILES WHERE file=?", (fileName,))
            self.Commit()
        except:
            # TODO: 区分错误代码
            return False
        else:
            return True

    def DeleteFileEntries(self, files):
        try:
            self.db.execute("DELETE FROM FILES WHERE file IN %s" 
                            % MakeQMarkString(len(files)), tuple(files))
            self.Commit()
        except:
            return False
        else:
            return True

    def InsertFileEntry(self, fileName, timestamp):
        try:
            # 理论上, 不会插入失败
            self.db.execute("INSERT OR REPLACE INTO FILES VALUES(NULL, ?, ?)", 
                           (fileName, timestamp))
            self.Commit()
        except:
            return False
        else:
            return True

    def UpdateFileEntry(self, fileName, timestamp):
        try:
            self.db.execute(
                "UPDATE OR REPLACE FILES SET last_retagged=? WHERE file=?", 
                (timestamp, fileName))
            self.Commit()
        except:
            return False
        else:
            return True

    def DeleteTagEntry(self, kind, signature, path):
        try:
            self.db.execute(
                "DELETE FROM TAGS WHERE Kind=? AND Signature=? AND Path=?", 
                (kind, signature, path))
            self.Commit()
        except:
            return False
        else:
            return True

    def InsertTagEntry(self, tag):
        if not tag.IsOk():
            return False

        if self.GetUseCache():
            self.ClearCache()

        try:
        #if 1:
            # INSERT OR REPLACE 貌似是不会失败的?!
            # 添加 parentType
            self.db.execute(
                "INSERT OR REPLACE INTO TAGS VALUES (NULL, "\
                "?, ?, ?, ?, "
                "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                (tag.GetName(),
                 tag.GetFile(),
                 tag.GetLine(),
                 tag.GetText(),

                 tag.GetAccess(),
                 tag.GetInheritsAsString(),
                 tag.GetKind(),
                 tag.GetParent(),
                 tag.GetParentType(),
                 tag.GetPath(),
                 tag.GetReturn(),
                 tag.GetScope(),
                 tag.GetSignature(),
                 tag.GetTemplate(),
                 tag.GetTyperef()))
        except:
            return False
        else:
            return True

    def UpdateTagEntry(self, tag):
        if not tag.IsOk():
            return True

        if self.GetUseCache():
            self.ClearCache()

        try:
            # 添加 parentType
            self.db.execute(
                "UPDATE OR REPLACE TAGS SET "
                "name=?, file=?, line=?, text=?, "
                "access=?, inherits=?, kind=?, parent=?, parent_type=?"
                "path=?, return=?, scope=?, signature=?, template=?, typeref=?"
                "WHERE file=? AND kind=? AND path=? AND signature=?", 
                (tag.GetName(),
                 tag.GetFile(),
                 tag.GetLine(),
                 tag.GetText(),

                 tag.GetAccess(),
                 tag.GetInheritsAsString(),
                 tag.GetKind(),
                 tag.GetParent(),
                 tag.GetParentType(),
                 tag.GetPath(),
                 tag.GetReturn(),
                 tag.GetScope(),
                 tag.GetSignature(),
                 tag.GetTemplate(),
                 tag.GetTyperef(),

                 # where 这四个参数能唯一定位?
                 tag.GetFile(),
                 tag.GetKind(), 
                 tag.GetPath(), 
                 tag.GetSignature()))
            self.Commit()
        except:
            return False
        else:
            return True

    def IsTypeAndScopeContainer(self, typeName, scope):
        '''返回有三个元素的元组 (Ture/False, typeName, scope)
        True if type exist under a given scope.
        
        Incase it exist but under the <global> scope, 'scope' will be changed
        '''
        # Break the typename to 'name' and scope
        typeNameNoScope = typeName.rpartition(':')[2]
        scopeOne        = typeName.rpartition(':')[0]

        if scopeOne.endswith(':'):
            scopeOne = scopeOne[:-1]

        combinedScope = ''

        if scope != '<global>':
            combinedScope += scope

        if scopeOne:
            if combinedScope:
                combinedScope += '::'
            combinedScope += scopeOne

        sql = "select scope,kind from tags where name='" + typeNameNoScope + "'"

        foundGlobal = False

        try:
            for row in self.Query(sql):
                scopeFounded = row[0]
                kindFounded = row[1]
                containerKind = kindFounded == "struct" \
                        or kindFounded == "class"
                if scopeFounded == combinedScope and containerKind:
                    scope = combinedScope
                    typeName = typeNameNoScope
                    return True, typeName, scope
                elif scopeFounded == scopeOne and containerKind:
                    # this is equal to cases like this:
                    # class A {
                    #     typedef std::list<int> List;
                    #     List l;
                    # };
                    # the combinedScope will be: 'A::std'
                    # however, the actual scope is 'std'
                    scope = scopeOne
                    typeName = typeNameNoScope
                    return True, typeName, scope
                elif containerKind and scopeFounded == "<global>":
                    foundGlobal = True
        except:
            pass

        if foundGlobal:
            scope = "<global>"
            typeName = typeNameNoScope
            return True, typeName, scope

        return False, typeName, scope

    def IsTypeAndScopeExist(self, typeName, scope):
        bestScope = ''
        tmpScope = scope

        strippedName    = typeName.rpartition(':')[2]
        secondScope     = typeName.rpartition(':')[0]

        if secondScope.endswith(':'):
            secondScope = secondScope[:-1]

        if not strippedName:
            return False

        sql = "select scope,parent from tags where name='" + strippedName \
                + "' and kind in ('class', 'struct', 'typedef') LIMIT 50"
        foundOther = 0

        if secondScope:
            tmpScope += '::' + secondScope

        parent = tmpScope.rpartition(':')[2]

        try:
            for row in self.Query(sql):
                scopeFounded = row[0]
                parentFounded = row[1]

                if scopeFounded == tmpScope:
                    scope = scopeFounded
                    typeName = strippedName
                    return True
                elif parentFounded == parent:
                    bestScope = scopeFounded
                else:
                    foundOther += 1
        except:
            pass

        # if we reached here, it means we did not find any exact match
        if bestScope:
            scope = bestScope
            typeName = strippedName
            return True
        elif foundOther == 1:
            scope = scopeFounded
            typeName = strippedName
            return True

        return False

    def GetScopesFromFileAsc(self, fileName, scopes):
        '''传入的 scopes 为列表'''
        sql = "select * from tags where file = '" + fileName + "' " \
                + " and kind in('prototype', 'function', 'enum')" \
                + " order by scope ASC"

        # we take the first entry
        try:
            for row in self.Query(sql):
                scopes.append(row[0])
                break
        except:
            pass

    def GetTagsByFileScopeAndKinds(self, fileName, scopeName, kinds):
        sql = "select * from tags where file = '" + fileName + "' " \
                + " and scope='" + scopeName + "' "

        if kinds:
            sql += " and kind in("
            for i in kinds:
                sql += "'" + i + "',"
            sql = sql[:-1] + ")"

        return DoFetchTags(sql)

    def GetAllTagsNames(self):
        names = []
        try:
            sql = "SELECT distinct name FROM tags order by name ASC LIMIT " \
                    + str(self.GetMaxWorkspaceTagToColour())

            for row in self.Query(sql):
                # add unique strings only
                names.append(row[0])
        except:
            pass

        return names

    def GetTagsNames(self, kinds):
        if not kinds:
            return []

        names = []
        try:
            whereClause = " kind IN ("
            for kind in kinds:
                whereClause += "'" + kind + "',"

            whereClause = whereClause[:-1] + ") "

            sql = "SELECT distinct name FROM tags WHERE "
            sql += whereClause + " order by name ASC LIMIT " \
                    + str(self.GetMaxWorkspaceTagToColour())
            for row in self.Query(sql):
                names.append(row[0])
        except:
            pass

        return names

    def GetTagsByScopesAndKinds(self, scopes, kinds):
        if not kinds or not scopes:
            return []

        sql = "select * from tags where scope in ("
        for scope in scopes:
            sql += "'" + scope + "',"
        sql = sql[:-1] + ") "

        return self.DoFetchTags(sql, kinds)

    def GetGlobalFunctions(self):
        sql = "select * from tags where scope = '<global>' "\
                "AND kind IN ('function', 'prototype') LIMIT " \
                + str(self.GetSingleSearchLimit())
        return self.DoFetchTags(sql)

    def GetTagsByFiles(self, files):
        if not files:
            return []

        sql = "select * from tags where file in ("
        for file in files:
            sql += "'" + file + "',"
        sql = sql[:-1] + ")"
        return self.DoFetchTags(sql)

    def GetTagsByFilesAndScope(self, files, scope):
        if not files:
            return []

        sql = "select * from tags where file in ("
        for file in files:
            sql += "'" + file + "',"
        sql = sql[:-1] + ")"
        sql += " AND scope='" + scope + "'"
        return self.DoFetchTags(sql)

    def GetTagsByFilesKindsAndScope(self, files, kinds, scope):
        if not files:
            return []

        sql = "select * from tags where file in ("
        for file in files:
            sql += "'" + file + "',"
        sql = sql[:-1] + ")"

        sql += " AND scope='" + scope + "'"

        return self.DoFetchTags(sql, kinds)

    def GetTagsByFilesScopeTyperefAndKinds(self, files, kinds, scope, typeref):
        if not files:
            return []

        sql = "select * from tags where file in ("
        for file in files:
            sql += "'" + file + "',"
        sql = sql[:-1] + ")"

        sql += " AND scope='" + scope + "'"
        sql += " AND typeref='" + typeref + "'"

        return self.DoFetchTags(sql, kinds)

    def GetTagsByKindsLimit(self, kinds, orderingColumn, order, limit, partName):
        sql = "select * from tags where kind in ("
        for kind in kinds:
            sql += "'" + kind + "',"
        sql = sql[:-1] + ") "

        if orderingColumn:
            sql += "order by " + orderingColumn
            if order == ITagsStorage.OrderAsc:
                sql += " ASC"
            elif order == ITagsStorage.OrderDesc:
                sql += " DESC"
            else:
                pass

        if partName:
            tmpName = partName.replace('_', '^_')
            sql += " AND name like '%" + tmpName + "%' ESCAPE '^' "

        if limit > 0:
            sql += " LIMIT " + str(limit)

        return self.DoFetchTags(sql)

    def IsTypeAndScopeExistLimitOne(self, typeName, scope):
        path = ''

        # Build the path
        if scope and scope != "<global>":
            path += scope + "::"

        path += typeName
        sql += "select ID from tags where path='" + path \
                + "' and kind in ('class', 'struct', 'typedef') LIMIT 1"

        try:
            for row in self.Query(sql):
                return True
        except:
            pass

        return False

    def GetDereferenceOperator(self, scope):
        sql = "select * from tags where scope ='" + scope \
                + "' and name like 'operator%->%' LIMIT 1"
        return self.DoFetchTags(sql)

    def GetSubscriptOperator(self, scope):
        sql = "select * from tags where scope ='" + scope \
                + "' and name like 'operator%[%]%' LIMIT 1"
        return self.DoFetchTags(sql)

    def ClearCache(self):
        if self.cache:
            self.cache.Clear()


VIMLITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#CTAGS = 'ctags'
#CTAGS = os.path.expanduser('~/bin/vlctags2')
CPPTAGSDB = os.path.expanduser('~/bin/cpptagsdb')
if platform.architecture()[0] == '64bit':
    if platform.system() == 'Windows':
        CTAGS = os.path.join(VIMLITE_DIR, 'bin', 'vlctags2.exe')
    else:
        CTAGS = os.path.join(VIMLITE_DIR, 'bin', 'vlctags2')
else:
    if platform.system() == 'Windows':
        CTAGS = os.path.join(VIMLITE_DIR, 'bin', 'vlctags2.exe')
    else:
        CTAGS = os.path.join(VIMLITE_DIR, 'bin', 'vlctags2')
CTAGS_OPTS = '--excmd=pattern --sort=no --fields=aKmSsnit '\
        '--c-kinds=+px --c++-kinds=+px'
CTAGS_OPTS_LIST = ['--excmd=pattern', '--sort=no', '--fields=aKmSsnit',
                   '--c-kinds=+px', '--c++-kinds=+px']
# 强制视全部文件为 C++
CTAGS_OPTS += ' --language-force=c++'
CTAGS_OPTS_LIST += ['--language-force=c++']

def AppendCtagsOpt(opt):
    global CTAGS_OPTS, CTAGS_OPTS_LIST
    CTAGS_OPTS += ' ' + opt
    CTAGS_OPTS_LIST += [opt]

def IsCppSourceFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    if ext in CPP_SOURCE_EXT:
        return True
    else:
        return False

def IsCppHeaderFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]

    if not ext and os.path.basename(fileName).lower() in CPP_HEADER_EXCLUDE:
            return False

    if ext in CPP_HEADER_EXT:
        return True
    else:
        return False

def ParseFiles(files, macrosFiles = []):
    '返回标签文本'
    if not files:
        return ''

    envDict = os.environ.copy()
    if macrosFiles: # 全局宏定义文件列表
        envDict['CTAGS_GLOBAL_MACROS_FILES'] = ','.join(macrosFiles)

    tags = ''
    if platform.system() == 'Windows':
        cmd = '"%s" %s -f - "%s"' % (CTAGS, CTAGS_OPTS, '" "'.join(files))
        p = subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=envDict)
    else:
        #cmd = '"%s" %s -f - "%s"' % (CTAGS, CTAGS_OPTS, '" "'.join(files))
        cmd = [CTAGS] + CTAGS_OPTS_LIST + ['-f', '-'] + files
        # NOTE: 不用 shell，会快近两倍！
        p = subprocess.Popen(cmd, shell=False,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=envDict)

    # NOTE: 详见 python 手册关于 subprocess 的 warning
    out, err = p.communicate()
    tags = out

    if p.returncode != 0:
        print cmd
        print '%d: ctags occured some errors' % p.returncode
        print err

    return tags

def ParseFilesToTags(files, tagFile, macrosFiles = []):
    if not files or not tagFile:
        return False

    ret = True
    envDict = os.environ.copy()
    if macrosFiles:
        envDict['CTAGS_GLOBAL_MACROS_FILES'] = ','.join(macrosFiles)

    if platform.system() == 'Windows':
        cmd = '"%s" %s -f "%s" "%s"' % (CTAGS, CTAGS_OPTS, tagFile,
                                        '" "'.join(files))
        p = subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=envDict)
    else:
        #cmd = '"%s" %s -f "%s" "%s"' % (CTAGS, CTAGS_OPTS, tagFile,
                                        #'" "'.join(files))
        cmd = [CTAGS] + CTAGS_OPTS_LIST + ['-f', tagFile] + files
        # NOTE: 不用 shell，会快近两倍！
        p = subprocess.Popen(cmd, shell=False,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=envDict)

    out, err = p.communicate()

    if p.returncode != 0:
        print cmd
        print '%d: ctags occured some errors' % p.returncode
        print err
        ret = False

    return ret

def CppTagsDbParseFilesAndStore(dbFile, files, macrosFiles = []):
    if not dbFile or not files:
        return False

    ret = True

    envDict = os.environ.copy()
    if macrosFiles:
        envDict['CTAGS_GLOBAL_MACROS_FILES'] = ','.join(macrosFiles)

    tags = ''
    if platform.system() == 'Windows':
        cmd = '"%s" %s -f - "%s" | "%s" -o "%s" -' \
                % (CTAGS, CTAGS_OPTS, '" "'.join(files),
                   CPPTAGSDB, dbFile)
    else:
        cmd = '"%s" %s -f - "%s" | "%s" -o "%s" -' \
                % (CTAGS, CTAGS_OPTS, '" "'.join(files),
                   CPPTAGSDB, dbFile)

    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, env=envDict)
    p.communicate()

    #print cmd

    if p.returncode != 0:
        print '%d: ctags and cpptagsdb occured some errors' % p.returncode
        ret = False

    return ret

def ParseFile(fileName, macrosFiles = []):
    return ParseFiles([fileName], macrosFiles)

def ParseFilesAndStore(storage, files, macrosFiles = [], filterNotNeed = True, 
                       indicator = None, useCppTagsDb = False):
    # 确保打开了一个数据库
    if not storage.OpenDatabase():
        return

    # NOTE: 全部转为绝对路径, 仅 parse C++ 头文件和源文件
    tmpFiles = [os.path.abspath(f) for f in files
                if IsCppSourceFile(f) or IsCppHeaderFile(f)]

    # 过滤不需要的. 通过比较时间戳
    if filterNotNeed:
        filesMap = storage.GetFilesMap(tmpFiles)
        mapLen = len(tmpFiles)
        idx = 0
        while idx < mapLen and filesMap:
            f = tmpFiles[idx]
            if filesMap.has_key(f):
                # 开始比较时间戳
                try:
                    mtime = int(os.path.getmtime(f))
                except OSError:
                    # 可能文件 f 不存在, 设置为 0, 即跳过
                    mtime = 0
                if filesMap[f].GetLastRetaggedTimestamp() >= mtime:
                    # 过滤掉
                    del tmpFiles[idx]
                    mapLen -= 1
                    continue
            idx += 1

    # 分批 parse
    totalCount = len(tmpFiles)
    batchCount = totalCount / 10
    if batchCount > 100: # 上限
        batchCount = 100
    if batchCount <= 0: # 下限
        batchCount = 1
    if batchCount > 10 and platform.system() == 'Windows':
        # Windows 下的 cmd.exe 不支持过长的命令行
        batchCount = 10

    i = 0
    batchFiles = tmpFiles[i : i + batchCount]
    if indicator:
        indicator(0, 100)

    if useCppTagsDb:
        # 先删除全部需要更新的
        if not storage.DeleteTagsByFiles(batchFiles, autoCommit = True):
            print 'storage.DeleteTagsByFiles() failed'

    # 这个时间取尽量早的时间，理论上使用文件的修改时间戳比较好
    lastRetagTime = int(time.time())

    tagFileFd, tagFile = tempfile.mkstemp()
    while batchFiles:
        parseRet = True
        if useCppTagsDb:
            if not CppTagsDbParseFilesAndStore(
                storage.GetDatabaseFileName(), batchFiles, macrosFiles):
                print 'CppTagsDbParseFilesAndStore() failed'
        elif True:
            # 使用临时文件
            parseRet = ParseFilesToTags(batchFiles, tagFile, macrosFiles)
            if parseRet: # 只有解析成功才入库
                storage.Begin()
                if not storage.DeleteTagsByFiles(batchFiles, autoCommit = False):
                    storage.Rollback()
                    storage.Begin()
                if not storage.StoreFromTagFile(tagFile, autoCommit = False):
                    storage.Rollback()
                    storage.Begin()
                storage.Commit()
        else:
            tags = ParseFiles(batchFiles, macrosFiles)
            storage.Begin()
            if not storage.DeleteTagsByFiles(batchFiles, autoCommit = False):
                storage.Rollback()
                storage.Begin()
            if not storage.Store(tags, autoCommit = False, indicator = None):
                storage.Rollback()
                storage.Begin()
            storage.Commit()

        if parseRet: # 只有解析成功才入库
            for f in batchFiles:
                if os.path.isfile(f):
                    storage.InsertFileEntry(f, int(time.time()))

        if indicator:
            indicator(i, totalCount - 1)
        i += batchCount
        # 下一个 batchFiles
        batchFiles = tmpFiles[i : i + batchCount]

    os.close(tagFileFd)
    os.remove(tagFile)

    if indicator:
        indicator(100, 100)

    #for f in tmpFiles:
        #if os.path.isfile(f):
            #storage.InsertFileEntry(f, lastRetagTime)


def test():
    files = ['/usr/include/unistd.h', 'xstring.hpp']
    files = ['/usr/include/stdio.h', '/usr/include/stdlib.h']
    macrosFiles = ['global.h', 'global.hpp']
    storage = TagsStorageSQLite()

    #storage.OpenDatabase('test1.db')
    #storage.RecreateDatabase()
    #t1 = time.time()
    #ParseFilesAndStore(storage, files,
                       #filterNotNeed = False, useCppTagsDb = True)
    #t2 = time.time()
    #print "%f" % (t2 - t1)

    storage.OpenDatabase('test2.db')
    storage.RecreateDatabase()
    t1 = time.time()
    ParseFilesAndStore(storage, files, macrosFiles,
                       filterNotNeed = False, useCppTagsDb = False)
    t2 = time.time()
    print "%f" % (t2 - t1)

    print storage.GetFilesMap(['/usr/include/stdio.h',
                               '/usr/include/unistd.h',
                               'xstring.hpp'])
    print storage.DeleteFileEntries(files)


if __name__ == '__main__':
    test()

