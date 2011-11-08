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

def GetIncludeFiles(fileName, searchPaths = []):
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

# ==============================================================================

enableCache = True

# 缓存, 只缓存包含列表, 不缓存展开后的绝对路径文件
# 因为分析包含列表复杂度最高, 且展开后的绝对路径文件易变(因为 paths 易变)
# {<filePath>: {'inclist': <include list>, 'mtime': <mtime>}}
CACHE_INCLUDELIST = {}
CACHE_RAWINCLUDELIST = {}

# 匹配 #include 行
reInclude = re.compile(r'^\s*#\s*include\s*(<[^>]+>|"[^"]+")')

def ClearCache():
    CACHE_INCLUDELIST.clear()
    CACHE_RAWINCLUDELIST.clear()

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
           int(os.path.getmtime(file)) == CACHE_INCLUDELIST[file]['mtime']:
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
            CACHE_INCLUDELIST[file]['mtime'] = int(os.path.getmtime(file))

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
           int(os.path.getmtime(file)) == CACHE_RAWINCLUDELIST[file]['mtime']:
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
            CACHE_RAWINCLUDELIST[file]['mtime'] = int(os.path.getmtime(file))

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
           int(os.path.getmtime(file)) == CACHE_RAWINCLUDELIST[file]['mtime']:
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
            CACHE_RAWINCLUDELIST[file]['mtime'] = int(os.path.getmtime(file))
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

if __name__ == '__main__':
    enableCache = False
    import sys
    if len(sys.argv) > 1:
        #li1 = GetIncludeFiles(sys.argv[1])
        #print '\n'.join(li1)
        print '=' * 40
        #li2 = GetIncludeFiles(sys.argv[1])
        #print '\n'.join(li2)
        print '=' * 40
        #print li1 == li2
        #li = GetIncludeList(sys.argv[1])
        #for i in li:
            #print ExpandIncludeFile(paths, i)
        print GetRawIncludeList(sys.argv[1])
        print '=' * 40
        print GetRawIncludeList2(sys.argv[1])

    import time
    t1 = time.time()
    for i in range(1):
        li = GetIncludeFiles(sys.argv[1])
    t2 = time.time()
    print li
    print t2 - t1

    t1 = time.time()
    for i in range(1):
        li = GetIncludeFiles(sys.argv[1])
    t2 = time.time()
    print li
    print t2 - t1

