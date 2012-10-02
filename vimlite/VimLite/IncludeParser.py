#!/usr/bin/env python
# -*- coding:utf-8 -*-


import os, os.path
import re


# 用于展开的 paths
#paths = [
    #'/usr/include/c++/4.4', 
    #'/usr/include/c++/4.4/i486-linux-gnu', 
    #'/usr/include/c++/4.4/backward', 
    #'/usr/local/include', 
    #'/usr/lib/gcc/i486-linux-gnu/4.4.3/include', 
    #'/usr/lib/gcc/i486-linux-gnu/4.4.3/include-fixed', 
    #'/usr/include/i486-linux-gnu', 
    #'/usr/include', 
#]

def GetMTime(fn):
    try:
        return os.path.getmtime(fn)
    except:
        return 0.0

def GetIncludeFiles(fileName, searchPaths = []):
    '''足够准确和高效了，直接替代老接口'''
    return GetIncludeFilesWithPathCache(fileName, searchPaths)

def GetIncludeFiles_old(fileName, searchPaths = []):
    '''外部用接口'''
    guard = set()
    #global paths
    #if searchPaths:
        #bak_paths = paths
        #paths = searchPaths

    absFile = os.path.abspath(fileName)
    ret = DoGetIncludeFiles(absFile, guard, searchPaths)

    #if searchPaths:
        #paths = bak_paths

    return ret

def GetIncludeFilesWithPathCache(fileName, searchPaths = []):
    '''使用 include path 缓存的情况下获取文件在的包含文件'''
    if not os.path.isfile(fileName):
        return []

    guard = set()

    absFile = os.path.abspath(fileName)

    ret = DoGetIncludeFilesWithPathCache(absFile, guard, searchPaths)

    return ret

def GetIncludeStmtsForClang(fileName, excludeFile):
    li = GetIncludeRelatedStmtList(fileName, excludeFile)
    return '\n'.join(li)

def FillHeaderInSource(sSourceFile, sHeaderFile, sHeaderContents):
    '''前两个参数尽量要是绝对路径'''
    sRet = ''
    global reInclude
    sBaseName = os.path.basename(sHeaderFile)
    reBaseName = re.compile(r'[<"/\\]' + sBaseName + r'\b')
    with open(sSourceFile) as f:
        li = f.readlines()
        for (i, sLine) in enumerate(li):
            m = reInclude.match(sLine)
            if m and reBaseName.search(m.group()):
                sRet = ''.join(li[:i]) + sHeaderContents + ''.join(li[i+1:])
                break
        else:
            sRet = ''.join(li)

    return sRet

def FillHeaderWithSource(sHeaderFile, sHeaderContents, sSourceFile):
    '''前两个参数尽量要是绝对路径，用源文件的内容填充头文件的头部和尾部的内容
    返回 (包含指令所在行号, 结果内容)'''
    sRet = ''
    nRow = 0
    global reInclude
    sBaseName = os.path.basename(sHeaderFile)
    reBaseName = re.compile(r'[<"/\\]' + sBaseName + r'\b')
    if not sHeaderContents.endswith('\n'):
        # 文本内容必须以换行结束
        sHeaderContents += '\n'
    with open(sSourceFile) as f:
        li = f.readlines()
        for (i, sLine) in enumerate(li):
            m = reInclude.match(sLine)
            if m and reBaseName.search(m.group()):
                sRet = ''.join(li[:i]) + sHeaderContents + ''.join(li[i+1:])
                nRow = i + 1
                break
        else:
            sRet = sHeaderContents

    return (nRow, sRet)

# ==============================================================================

# 第一个缓存已经不在需要了，如果启动，反而会影响效率
enableCache = False
enablePathCache = True

# 缓存, 只缓存包含列表, 不缓存展开后的绝对路径文件
# 因为分析包含列表复杂度最高, 且展开后的绝对路径文件易变(因为 paths 易变)
# {<filePath>: {'inclist': <include list>, 'mtime': <mtime>}}
CACHE_INCLUDELIST = {} # 'inclist' 项目不带 <> 和 ""
CACHE_RAWINCLUDELIST = {} # 'inclist' 项目带 <> 或 ""

# 高速缓存，直接缓存最终的结果，即展开后的路径
# 'paths' 保存缓存时的搜索路径
# {<filePath>: {'inclist': <include list>, 'mtime': <mtime>, 'paths': <paths>}}
CACHE_INCLUDEPATHLIST = {}

# 匹配 #include 行
reInclude = re.compile(r'^\s*#\s*include\s*(<[^>]+>|"[^"]+")')

# 匹配 #include 以及相关的行，如 #if, #else, #ifdef, #endif
patInclude =    r'^\s*#\s*include\b.+'
patIf =         r'^\s*#\s*if\s+.+'
patIfdef =      r'^\s*#\s*ifdef\s+.+'
patIfndef =     r'^\s*#\s*ifndef\s+.+'
patElse =       r'^\s*#\s*else\b'
patEndif =      r'^\s*#\s*endif\b'
reIncludeRelated = re.compile(
    r'|'.join([patInclude, patIf, patIfdef, patIfndef, patElse, patEndif]))

def ClearCache():
    '''这些缓存在系统时间不出错的情况下，理论上是完全没必要清空的'''
    CACHE_INCLUDELIST.clear()
    CACHE_RAWINCLUDELIST.clear()

def ClearPathCache():
    CACHE_INCLUDEPATHLIST.clear()

def ClearAllCache():
    ClearCache()
    ClearPathCache()

def ExpandIncludeFile(searchPaths, include, userHeader = True, fileDir = '.'):
    '''在 searchPaths 中展开 include 字符串
    userHeader 表示用双引号的 include 字符串'''
    ret = ''

    if userHeader:
        '''先搜索文件所在目录'''
        f = os.path.join(fileDir, include)
        if os.path.isfile(f):
            ret = f
            return ret

    for path in searchPaths:
        f = os.path.join(path, include)
        if os.path.isfile(f):
            ret = f
            break

    return ret

def GetIncludeList(file):
    '''获取包含文件列表, 不能区分 <> 和 ""
    
    #include <stdio.h> -> stdio.h
    #include "stdio.h" -> stdio.h
    '''
    ret = []
    global reInclude

    if enableCache:
        # NOTE: 时间戳比较应该用 ==
        if CACHE_INCLUDELIST.has_key(file) and \
           int(GetMTime(file)) == CACHE_INCLUDELIST[file]['mtime']:
            ret = CACHE_INCLUDELIST[file]['inclist']
            return ret

    try:
        f = open(file)
        #p = re.compile(r'^\s*#\s*include\s*(<[^>]+>|"[^"]+")')
        for l in f:
            m = reInclude.match(l)
            if m:
                ret.append(m.group(1)[1:-1])
        f.close()
    except IOError:
        return ret
    else:
        # 缓存结果
        if enableCache:
            CACHE_INCLUDELIST[file] = {}
            CACHE_INCLUDELIST[file]['inclist'] = ret
            CACHE_INCLUDELIST[file]['mtime'] = int(GetMTime(file))

        return ret

def GetRawIncludeList(file):
    '''获取包含文件列表, 包含 <> 或 ""
    
    #include <stdio.h> -> <stdio.h>
    #include "stdio.h" -> "stdio.h"
    '''
    ret = []
    global reInclude

    if enableCache:
        # NOTE: 时间戳比较应该用 ==
        if CACHE_RAWINCLUDELIST.has_key(file) and \
           int(GetMTime(file)) == CACHE_RAWINCLUDELIST[file]['mtime']:
            ret = CACHE_RAWINCLUDELIST[file]['inclist']
            return ret

    try:
        f = open(file)
        #p = re.compile(r'^\s*#\s*include\s*(<[^>]+>|"[^"]+")')
        for l in f:
            m = reInclude.match(l)
            if m:
                ret.append(m.group(1))
        f.close()
    except IOError:
        return ret
    else:
        # 缓存结果
        if enableCache:
            CACHE_RAWINCLUDELIST[file] = {}
            CACHE_RAWINCLUDELIST[file]['inclist'] = ret
            CACHE_RAWINCLUDELIST[file]['mtime'] = int(GetMTime(file))

        return ret

def GetIncludeRelatedStmtList(file, excludeFile):
    '''获取包含文件的语句的列表, 整个语句'''
    ret = []
    global reIncludeRelated

    # 字符串的前面必须是 " 或 < 或 /(posix) 或 \(Windows)
    if excludeFile:
        reTmp = re.compile(r'[<"/\\]' + excludeFile + r'\b')
    else:
        reTmp = None

    try:
        f = open(file)
        for l in f:
            m = reIncludeRelated.match(l)
            if m:
                if reTmp and reTmp.search(m.group()):
                # 找到了需要排除的文件，直接终止，因为后面的不在需要了
                # TODO: 需要处理预处理条件栈
                    break
                ret.append(m.group())
        f.close()
    except IOError:
        return ret
    else:
        # 缓存结果
        #if enableCache:
            #CACHE_RAWINCLUDELIST[file] = {}
            #CACHE_RAWINCLUDELIST[file]['inclist'] = ret
            #CACHE_RAWINCLUDELIST[file]['mtime'] = int(GetMTime(file))

        return ret

def GetRawIncludeList2(file):
    '''获取包含文件列表, 包含 <> 或 ""
    这个函数表面上看更快, 实际上更慢!
    
    #include <stdio.h> -> <stdio.h>
    #include "stdio.h" -> "stdio.h"
    '''

    if enableCache:
        # NOTE: 时间戳比较应该用 ==
        if CACHE_RAWINCLUDELIST.has_key(file) and \
           int(GetMTime(file)) == CACHE_RAWINCLUDELIST[file]['mtime']:
            ret = CACHE_RAWINCLUDELIST[file]['inclist']
            return ret

    output = os.popen(r'''mawk '/^[ \t]*#[ \t]*include[ \t]*(<[^>]+>|"[^"]+")/ {sub(/^[ \t]*#[ \t]*include[ \t]*/, "");if(match($0, /(<[^>]+>|"[^"]+")/)) print substr($0, RESTART, RLENGTH+1)}' "%s"''' % file).read()
    ret = output.split('\n')
    try:
        while not ret[-1]:
            ret.pop(-1)
    except:
        pass

    # 缓存结果
    if enableCache:
        try:
            CACHE_RAWINCLUDELIST[file] = {}
            CACHE_RAWINCLUDELIST[file]['inclist'] = ret
            CACHE_RAWINCLUDELIST[file]['mtime'] = int(GetMTime(file))
        except:
            # 文件不存在的话, 走到这里
            del CACHE_RAWINCLUDELIST[file]

    return ret

def DoGetIncludeFiles(file, guard, searchPaths):
    '''file 必须为绝对路径'''
    ret = []

    guard.add(file)
    li = GetRawIncludeList(file)
    for i in li:
        if i.startswith('<'):
            '''系统头文件'''
            userHeader = False
        else:
            '''用户头文件'''
            userHeader = True
        fileDir = os.path.dirname(file)
        include = i[1:-1]

        header = ExpandIncludeFile(searchPaths, include, userHeader, fileDir)
        if header and header not in guard:
            ret.append(header)
            ret.extend(DoGetIncludeFiles(header, guard, searchPaths))

    return ret

def DoGetIncludeFilesWithPathCache(file, guard, searchPaths):
    '''file 必须为绝对路径'''
    ret = []

    guard.add(file)

    # 如果可能直接从缓存中获取结果
    if enablePathCache and CACHE_INCLUDEPATHLIST.has_key(file) \
       and CACHE_INCLUDEPATHLIST[file]['mtime'] == int(GetMTime(file)) \
       and CACHE_INCLUDEPATHLIST[file]['paths'] == searchPaths:
        headers = CACHE_INCLUDEPATHLIST[file]['inclist']
    else:
        headers = []
        li = GetRawIncludeList(file)
        # 广度优先遍历
        for i in li:
            if i.startswith('<'):
                '''系统头文件'''
                userHeader = False
            else:
                '''用户头文件'''
                userHeader = True
            fileDir = os.path.dirname(file)
            include = i[1:-1]

            header = ExpandIncludeFile(searchPaths, include, userHeader, fileDir)
            headers.append(header)
        # 缓存结果
        if enablePathCache:
            CACHE_INCLUDEPATHLIST[file] = {}
            CACHE_INCLUDEPATHLIST[file]['inclist'] = headers
            CACHE_INCLUDEPATHLIST[file]['mtime'] = int(GetMTime(file))
            CACHE_INCLUDEPATHLIST[file]['paths'] = searchPaths[:]

    for header in headers:
        if header and header not in guard:
            ret.append(header)
            ret.extend(DoGetIncludeFilesWithPathCache(header, guard,
                                                          searchPaths))

    return ret



if __name__ == '__main__':
    import unittest
    import time

    class Test(unittest.TestCase):
        def setUp(self):
            pass

        def test_01(self):
            global enableCache
            global enablePathCache
            enableCache = False
            enablePathCache = False

            fileName = '/usr/include/stdio.h'
            paths = ['/usr/include']
            n = 100

            print '=' * 20, 'raw include', '=' * 20
            print GetRawIncludeList(fileName)

            print '=' * 20, 'firstly get include files', '=' * 20
            li1 = GetIncludeFiles(fileName)
            print '\n'.join(li1)
            print '=' * 20, 'secondly get include files', '=' * 20
            li2 = GetIncludeFiles(fileName)
            print '\n'.join(li2)
            print li1 == li2
            print '=' * 20, 'get include list and expand', '=' * 20
            li = GetIncludeList(fileName)
            for i in li:
                print ExpandIncludeFile(paths, i)
            #print GetRawIncludeList2(fileName)

            enableCache = True
            enablePathCache = False
            ClearAllCache()
            t1 = time.time()
            for i in range(n):
                li = GetIncludeFiles(fileName, paths)
            t2 = time.time()
            print '=' * 20, 'enable cache, get include files and expand'
            print t2 - t1
            #print '\n'.join(li)

            enableCache = False
            enablePathCache = True
            ClearAllCache()
            t1 = time.time()
            for i in range(n):
                li = GetIncludeFiles(fileName, paths)
            t2 = time.time()
            print '=' * 20, 'disable cache, get include files and expand'
            print t2 - t1
            #print '\n'.join(li)

            enablePathCache = True
            enableCache = True
            ClearAllCache()
            print '=' * 10, 'enable path cache, '\
                    'get include files with path cache expand'
            t1 = time.time()
            for i in range(n):
                li2 = GetIncludeFilesWithPathCache(fileName, paths)
            t2 = time.time()
            print t2 - t1
            self.assertEquals(li, li2)

            enablePathCache = False
            enableCache = False
            ClearAllCache()
            print '=' * 10, 'disable path cache, '\
                    'get include files with path cache expand'
            t1 = time.time()
            for i in range(n):
                li2 = GetIncludeFilesWithPathCache(fileName, paths)
            t2 = time.time()
            print t2 - t1

            return
            print '\n'.join(GetIncludeFilesWithPathCache(fileName, paths))
            for k, v in CACHE_INCLUDEPATHLIST.iteritems():
                print '=' * 10, k
                print v['paths']
                print v['mtime']
                print '\n'.join(v['inclist'])

        def test02(self):
            return

            sFile = '/home/eph/Desktop/projects/mcapi/TestApi/THashTable.cpp'
            #sFile = '/home/eph/Desktop/VimLite/VIMClangCC/t2.hpp'
            excludeFile = 'THashTable.h'
            #excludeFile = 'AVLTree.h'
            sHeaderFile = '/home/eph/Desktop/projects/mcapi/TestApi/THashTable.h'

            with open(sHeaderFile) as f:
                print FillHeaderWithSource(sHeaderFile, f.read(), sFile)
            return

            li = GetIncludeRelatedStmtList(sFile, '')
            print '\n'.join(li)
            print '=' * 40
            #print GetRawIncludeList(sFile)
            reTmp = re.compile('%s\\b' % excludeFile)
            print '\n'.join(filter(lambda x: not reTmp.search(x), li))
            print '=' * 40
            print GetIncludeStmtsForClang(sFile, excludeFile)

    unittest.main()

