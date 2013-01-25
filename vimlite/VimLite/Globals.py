#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import sys
import os
import os.path
import time
import re
import getpass
import subprocess
import tempfile
import threading
import shlex
import platform

# TODO: 现在的变量展开是不支持递归的，例如 $(a$(b))

# 版本号 850 -> 0.8.5.0
VIMLITE_VER = 970

# VimLite 起始目录
VIMLITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WORKSPACE_FILE_SUFFIX = 'vlworkspace'
PROJECT_FILE_SUFFIX = 'vlproject'

WSP_PATH_SEP = '/'

# 全局源文件判断控制
# 扩展名约定是包括 '.' 的，例如 .c; .cpp
C_SOURCE_EXT    = set(['.c'])
CPP_SOURCE_EXT  = set(['.cpp', '.cxx', '.c++', '.cc'])
# 头文件扩展名暂不支持修改
CPP_HEADER_EXT  = set(['.h', '.hpp', '.hxx', '.hh', '.inl', '.inc', ''])

DEFAULT_C_SOURCE_EXT    = set(['.c'])
DEFAULT_CPP_SOURCE_EXT  = set(['.cpp', '.cxx', '.c++', '.cc'])

def CSrcExtReset():
    global C_SOURCE_EXT
    C_SOURCE_EXT = DEFAULT_C_SOURCE_EXT.copy()

def CppSrcExtReset():
    global CPP_SOURCE_EXT
    CPP_SOURCE_EXT = DEFAULT_CPP_SOURCE_EXT.copy()

def Cmp(s1, s2):
    '''忽略大小写比较两个字符串'''
    return cmp(s1.lower(), s2.lower())

def CmpNoCase(s1, s2):
    '''忽略大小写比较两个字符串'''
    return cmp(s1.lower(), s2.lower())

def IsLinuxOS():
    '''判断系统是否 Linux'''
    return platform.system() == 'Linux'

def IsWindowsOS():
    '''判断系统是否 Windows'''
    return platform.system() == 'Windows'

def EscapeString(string, chars, escchar = '\\'):
    '''转义字符串'''
    charli = []
    for char in string:
        if char in chars:
            charli.append(escchar)
        charli.append(char)
    return ''.join(charli)

# 更简洁的名字
EscStr = EscapeString

def EscStr4DQ(string):
    '''转义 string，用于放到双引号里面'''
    return EscapeString(string, '"\\')

patMkShStr = re.compile(r'^[a-zA-Z0-9_\-+.\$()/]+$')
def EscStr4MkSh(string):
    '''转义 string，用于在 Makefile 里面传给 shell，不是加引号的方式
    bash 的元字符包括：|  & ; ( ) < > space tab
    NOTE: 换行无法转义，应该把 \n 用 $$'\n'表示的
    
    参考 vim 的 shellescape() 函数'''
    global patMkShStr
    if IsWindowsOS():
        #return '"%s"' % string.replace('"', '""')
        # 在 Windows 下直接不支持带空格的路径好了，因为用双引号也有各种问题
        return '%s' % string
    else:
        #return EscapeString(string, "|&;()<> \t'\"\\")
        # 有必要才转义，主要是为了好看
        if patMkShStr.match(string):
            return string
        else:
            return "'%s'" % string.replace("'", "'\\''")

def SplitSmclStr(s, sep = ';'):
    '''分割 sep 作为分割符的字符串为列表，双倍的 sep 代表 sep 自身'''
    l = len(s)
    idx = 0
    result = []
    chars = []
    while idx < l:
        char = s[idx]
        if char == sep:
            # 检查随后的是否为自身
            if idx + 1 < l:
                if s[idx+1] == sep: # 不是分隔符
                    chars.append(sep)
                    idx += 1 # 跳过下一个字符
                else: # 是分隔符
                    if chars:
                        result.append(''.join(chars))
                    del chars[:] # 清空
            else: # 最后的字符也为分隔符，直接忽略即可
                pass
        else: # 一般情况下，直接添加即可
            chars.append(char)
        idx += 1

    # 最后段
    if chars:
        result.append(''.join(chars))
    del chars[:]

    return result

def JoinToSmclStr(li, sep = ';'):
    '''串联字符串列表为 sep 分割的字符串，sep 用双倍的 sep 来表示'''
    tempList = []
    for elm in li:
        if elm:
            tempList.append(elm.replace(sep, sep + sep)) # 直接加倍即可
    return sep.join(tempList)

def SplitStrBy(string, sep):
    '''把 sep 作为分隔符的字符串分割，支持 '\\' 转义
    sep 必须是单个字符'''
    charli = []
    result = []
    esc = False
    for c in string:
        if c == '\\':
            esc = True
            continue
        if c == sep and not esc:
            if charli:
                result.append(''.join(charli))
            del charli[:]
            continue
        charli.append(c)
        esc = False
    if charli:
        result.append(''.join(charli))
        del charli[:]
    return result

def Escape(string, chars):
    return EscapeString(string, chars)

def GetMTime(fn):
    try:
        return os.path.getmtime(fn)
    except:
        return 0.0

def TempFile():
    fd, fn = tempfile.mkstemp()
    os.close(fd)
    return fn

def GetFileModificationTime(fileName):
    '''获取文件最后修改时间
    
    返回自 1970-01-01 以来的秒数'''
    try:
        ret = int(os.path.getmtime(fileName))
    except OSError:
        ret = 0
    finally:
        return ret

def Touch(lFiles):
    if isinstance(lFiles, str): lFiles = [lFiles]
    for sFile in lFiles:
        #print "touching %s" % sFile
        try:
            os.utime(sFile, None)
        except OSError:
            open(sFile, "ab").close()

def NormalizePath(string):
    '''把路径分割符全部转换为 posix 标准的分割符'''
    return string.replace('\\', '/')

def PosixPath(p):
    '''把路径分割符全部转换为 posix 标准的分割符'''
    return string.replace('\\', '/')

class DirSaver:
    '''用于在保持当前工作目录下，跳至其他目录工作，
    在需要作用的区域，必须保持一个引用！'''
    def __init__(self):
        self.curDir = os.getcwd()
        #print 'curDir =', self.curDir
    
    def __del__(self):
        os.chdir(self.curDir)
        #print 'back to', self.curDir

def Obj2Dict(obj):
    '''常规对象转为字典
    把所有公共属性（不包含方法）作为键，把属性值作为值
    NOTE: 不会递归转换，也就是只转一层'''
    d = {}
    for k in dir(obj):
        v = getattr(obj, k)
        if callable(v) or k.startswith("_"):
            continue
        d[k] = v
    return d

def Dict2Obj(obj, d):
    '''把字典转为对象
    字典的键对应对象的属性，字典的值对应对象的属性值
    NOTE: 不会递归转换，也就是只转一层'''
    for k, v in d.iteritems():
        if isinstance(v, unicode):
            # 统一转成 utf-8 编码的字符串，唉，python2 的软肋
            v = v.encode('utf-8')
        setattr(obj, k, v)
    return obj

def StripVariablesForShell(sExpr):
    '''剔除所有 $( name ) 形式的字符串, 防止被 shell 解析'''
    p = re.compile(r'(\$\(\s*[a-zA-Z_]\w*\s*[^)]*\))')
    return p.sub('', sExpr)

def SplitVarDef(string):
    '''按照 gnu make 的方式分割变量，返回 key, val'''
    key = ''
    val = ''
    # TODO: 虽然这样已经处理绝大多数情况了
    key, op, val = string.partition('=')
    if not op: # 语法错误的话
        key = ''
        val = ''
    key = key.strip()
    val = val.lstrip()
    return key, val

def ExpandVariables(sString, dVariables, bTrimVar = False):
    '''单次(非递归)展开 $(VarName) 形式的变量
    只要确保 dVariables 字典的值是最终展开的值即可
    bTrimVar 为真时，未定义的变量会用空字符代替，否则就保留原样
             默认值是为了兼容'''
    if not sString or not dVariables:
        return sString

    p = re.compile(r'(\$+\([a-zA-Z_]\w*\))')

    nStartIdx = 0
    sResult = ''
    while True:
        m = p.search(sString, nStartIdx)
        if m:
            # 例如 $$(name) <- 这不是要求展开变量
            sResult += sString[nStartIdx : m.start(1)]
            n = m.group(1).find('$(')
            if not n & 1: # $( 前面的 $ 的数目是双数，需要展开
                sVarName = m.group(1)[n+2:-1]
                if bTrimVar:
                    sVarVal = str(dVariables.get(sVarName, ''))
                    sResult += '$' * n
                    sResult += sVarVal
                else:
                    if dVariables.has_key(sVarName):
                        # 成功展开变量的时候，前面的 $ 全数保留
                        sResult += '$' * n
                        sResult += str(dVariables[sVarName])
                    else: # 不能展开的，保留原样，$ 全数保留
                        sResult += m.group(1)
            else:
                #sResult += '$' * ((n - 1) / 2)
                #sResult += m.group(1)[n:]
                sResult += m.group(1)
            nStartIdx = m.end(1)
        else:
            sResult += sString[nStartIdx :]
            break

    return sResult

def ExpandAllVariables(expression, workspace, projName, projConfName = '', 
                       fileName = ''):
    '''展开所有变量，所有变量引用的形式都会被替换
    会展开脱字符(`)的表达式，但是，不展开 $(shell ) 形式的表达式

    先展开 `` 的表达式，再展开内部的变量，所以不能在 `` 里面使用内部变量

    expression      - 需要展开的表达式, 可为空
    workspace       - 工作区实例, 可为空
    projName        - 项目名字, 可为空
    projConfName    - 项目构建设置名称, 可为空
    fileName        - 文件名字, 要求为绝对路径, 可为空

    RETURN          - 展开后的表达式'''
    tmpExp = ''
    i = 0
    # 先展开所有命令表达式
    # 只支持 `` 内的表达式, 不支持 $() 形式的
    # 因为经常用到在 Makefile 里面的变量, 为了统一, 无法支持 $() 形式
    # TODO: 用以下正则匹配脱字符包含的字符串 r'`(?:[^`]|(?<=\\)`)*`'
    while i < len(expression):
        c = expression[i]
        if c == '`':
            backtick = ''
            found = False
            i += 1
            while i < len(expression):
                if expression[i] == '`':
                    found = True
                    break
                backtick += expression[i]
                i += 1

            if not found:
                print 'Syntax error in expression: ' + expression \
                        + ": expecting '`'"
                return expression
            else:
                expandedBacktick = ExpandAllInterVariables(
                    backtick, workspace, projName, projConfName, fileName)

                output = os.popen(expandedBacktick).read()
                tmp = ' '.join([x for x in output.split('\n') if x])
                tmpExp += tmp
        else:
            tmpExp += c
        i += 1

    result = ExpandAllInterVariables(tmpExp, workspace, projName, projConfName,
                                     fileName, True)
    result = StripVariablesForShell(result)
    # 处理转义的 '$'
    return result.replace('$$', '$')

def ExpandAllInterVariables(expression, workspace, projName, projConfName = '', 
                            fileName = '', trim = False):
    '''展开所有内部变量

    expression      - 需要展开的表达式, 可为空
    workspace       - 工作区实例, 可为空
    projName        - 项目名字, 可为空
    projConfName    - 项目构建设置名称, 可为空
    fileName        - 文件名字, 要求为绝对路径, 可为空
    trim            - 是否用空字符展开没有定义的变量引用
    
    支持的变量有:
    $(User)
    $(Date)
    $(CodeLitePath)

    $(WorkspaceName)
    $(WorkspacePath)

    $(ProjectName)
    $(ProjectPath)
    $(ConfigurationName)
    $(IntermediateDirectory)    - 这个变量可能嵌套
    $(OutDir)                   - 这个变量可能嵌套

    $(ProjectFiles)
    $(ProjectFilesAbs)

    $(CurrentFileName)
    $(CurrentFileExt)
    $(CurrentFilePath)
    $(CurrentFileFullPath)
    '''
    from EnvVarSettings import EnvVarSettingsST

    if not '$' in expression:
        return expression

    dVariables = {}

    dVariables['User'] = getpass.getuser()
    dVariables['Date'] = time.strftime('%Y-%m-%d', time.localtime())
    dVariables['CodeLitePath'] = os.path.expanduser('~/.codelite')

    if workspace:
        dVariables['WorkspaceName'] = workspace.GetName()
        dVariables['WorkspacePath'] = workspace.dirName
        project = workspace.FindProjectByName(projName)
        if project:
            dVariables['ProjectName'] = project.GetName()
            dVariables['ProjectPath'] = project.dirName

            bldConf = workspace.GetProjBuildConf(project.GetName(), projConfName)
            if bldConf:
                dVariables['ConfigurationName'] = bldConf.GetName()
                imd = bldConf.GetIntermediateDirectory()
                # 先展开中间目录的变量
                # 中间目录不能包含自身和自身的别名 $(OutDir)
                # 可包含的变量为此之前添加的变量
                imd = EnvVarSettingsST.Get().ExpandVariables(imd)
                imd = ExpandVariables(imd, dVariables)
                dVariables['IntermediateDirectory'] = imd
                dVariables['OutDir'] = imd

            # NOTE: 是必定包含忽略的文件的
            if '$(ProjectFiles)' in expression:
                dVariables['ProjectFiles'] = \
                        ' '.join([ '"%s"' % i for i in project.GetAllFiles()])
            if '$(ProjectFilesAbs)' in expression:
                dVariables['ProjectFilesAbs'] = \
                        ' '.join([ '"%s"' % i for i in project.GetAllFiles(True)])

    if fileName:
        dVariables['CurrentFileName'] = \
                os.path.splitext(os.path.basename(fileName))[0]
        dVariables['CurrentFileExt'] = \
                os.path.splitext(os.path.basename(fileName))[1][1:]
        dVariables['CurrentFilePath'] = \
                NormalizePath(os.path.dirname(fileName))
        dVariables['CurrentFileFullPath'] = NormalizePath(fileName)

    if dVariables.has_key('OutDir'): # 这个变量由于由用户定义，所以可以嵌套变量
        imd = dVariables['OutDir']
        del dVariables['OutDir']
        del dVariables['IntermediateDirectory']
        imd = ExpandVariables(imd, dVariables, False)
        # 再展开环境变量
        imd = EnvVarSettingsST.Get().ExpandVariables(imd, True)
        dVariables['OutDir'] = imd
        dVariables['IntermediateDirectory'] = dVariables['OutDir']

    # 先这样展开，因为内部变量不允许覆盖，内部变量可以保证不嵌套变量
    expression = ExpandVariables(expression, dVariables, False)
    # 再展开环境变量, 因为内部变量不可能包含环境变量
    expression = EnvVarSettingsST.Get().ExpandVariables(expression, trim)

    return expression

def IsCSourceFile(fileName):
    ext = os.path.splitext(fileName)[1]
    if ext in C_SOURCE_EXT:
        return True
    else:
        return False

def IsCppSourceFile(fileName):
    ext = os.path.splitext(fileName)[1]
    if ext in CPP_SOURCE_EXT:
        return True
    else:
        return False

def IsCCppSourceFile(fileName):
    return IsCSourceFile(fileName) or IsCppSourceFile(fileName)

def IsCppHeaderFile(fileName):
    ext = os.path.splitext(fileName)[1]
    if ext in CPP_HEADER_EXT:
        return True
    else:
        return False

#===============================================================================
# shell 命令展开工具
#===============================================================================
# DEPRECATED
def __ExpandShellCmd(s):
    p = re.compile(r'\$\(shell +(.+?)\)')
    return p.sub(ExpandCallback, s)

def GetIncludesFromArgs(s, sw = '-I'):
    #return filter(lambda x: x.startswith(sw),
                  #GetIncludesAndMacrosFromArgs(s, incSwitch = sw))
    return GetOptsFromArgs(s, sw)

def GetMacrosFromArgs(s, sw = '-D'):
    '''返回的结果带 switch'''
    #return filter(lambda x: x.startswith(sw),
                  #GetIncludesAndMacrosFromArgs(s, defSwitch = sw))
    return GetOptsFromArgs(s, sw)

def GetOptsFromArgs(s, sw):
    if len(sw) != 2: raise ValueError('Invalid function parameter: %s' % sw)
    # 使用内建的方法，更好
    li = shlex.split(s)
    idx = 0
    result = []
    while idx < len(li):
        elm = li[idx]
        if elm.startswith(sw):
            if elm == sw: # '-D abc' 形式
                if idx + 1 < len(li):
                    result.append(sw + li[idx+1])
                    idx += 1
                else: # 这里是参数错误了
                    pass
            else:
                result.append(elm)
        idx += 1
    return result

# = DEPRECATED =
def _GetIncludesAndMacrosFromArgs(s, incSwitch = '-I', defSwitch = '-D'):
    '''不支持 -I /usr/include 形式，只支持 -I/usr/include
    返回的结果带 switch'''
    results = []
    p = re.compile(r'(?:' + incSwitch + r'"((?:[^"]|(?<=\\)")*)")'
                   + r'|' + incSwitch + r'((?:\\ |\S)+)'
                   + r'|(' + defSwitch + r'[a-zA-Z_][a-zA-Z_0-9]*)')
    for m in p.finditer(s):
        if m.group(1):
            # -I""
            results.append(incSwitch + m.group(1).replace('\\', ''))
        if m.group(2):
            # -I\ \ a 和 -Iabc
            results.append(incSwitch + m.group(2).replace('\\', ''))
        if m.group(3):
            # -D_DEBUG
            results.append(m.group(3))

    return results

def GetCmdOutput(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return p.stdout.read().rstrip()

def ExpandCallback(m):
    return GetCmdOutput(m.group(1))

class SimpleThread(threading.Thread):
    def __init__(self, callback, prvtData, 
                 PostCallback = None, callbackPara = None):
        '''简单线程接口'''
        threading.Thread.__init__(self)

        self.callback = callback
        self.prvtData = prvtData

        self.PostCallback = PostCallback
        self.callbackPara = callbackPara

    def run(self):
        try:
            self.callback(self.prvtData)
        except:
            #print 'SimpleThread() failed'
            pass

        if self.PostCallback:
            try:
                self.PostCallback(self.callbackPara)
            except:
                pass

def RunSimpleThread(callback, prvtData):
    thrd = SimpleThread(callback, prvtData)
    thrd.start()
    return thrd

def GetBgThdCnt():
    return threading.active_count() - 1

#===============================================================================

if __name__ == '__main__':
    import unittest
    import shlex
    import getopt

    def ppp(yy):
        import time
        time.sleep(3)
        print dir(yy)
    #print RunSimpleThread(ppp, list)

    print GetBgThdCnt()
    print threading.active_count()

    class test(unittest.TestCase):
        def testGetArgs(self):
            s = r'-I/usr/include -I"/usr/local/include" -I\ \ /us\ r/include'
            s += ' -D_DEBUG'
            res = _GetIncludesAndMacrosFromArgs(s)
            #print res
            self.assertTrue(res[0] == '-I/usr/include')
            self.assertTrue(res[1] == '-I/usr/local/include')
            self.assertTrue(res[2] == '-I  /us r/include')
            self.assertTrue(res[3] == '-D_DEBUG')

            res = GetIncludesFromArgs(s)
            self.assertTrue(res[0] == '-I/usr/include')
            self.assertTrue(res[1] == '-I/usr/local/include')
            self.assertTrue(res[2] == '-I  /us r/include')

            res = GetMacrosFromArgs(s)
            self.assertTrue(res[0] == '-D_DEBUG')

        def testIsCppSourceFile(self):
            self.assertFalse(IsCppSourceFile('/a.c'))
            self.assertTrue(IsCSourceFile('/a.c'))
            self.assertTrue(IsCppSourceFile('./a.cxx'))
            self.assertTrue(not IsCppSourceFile('./a.cx'))

        def testIsCppHeaderFile(self):
            self.assertTrue(IsCppHeaderFile('b.h'))
            self.assertTrue(IsCppHeaderFile('/homt/a.hxx'))
            self.assertTrue(IsCppHeaderFile('iostream'))
            self.assertTrue(not IsCppHeaderFile('iostream.a'))

        def testDirSaver(self):
            def TestDirSaver():
                ds = DirSaver()
                os.chdir('/')
                self.assertTrue(os.getcwd() == '/')
                #print 'I am in', os.getcwd()
                #print 'Byebye'

            cwd = os.getcwd()
            TestDirSaver()
            self.assertTrue(cwd == os.getcwd())

        def testStripVariablesForShell(self):
            self.assertTrue(
                StripVariablesForShell(' sne $(CodeLitePath) , $( ooxx  )')
                 == ' sne  , ')
            self.assertTrue(StripVariablesForShell('') == '')

        def testSplitStrBy(self):
            self.assertTrue(SplitStrBy("snke\;;snekg;", ';') 
                            == ['snke;', 'snekg'])

        def testExpandVariables(self):
            d = {'name': 'aa', 'value': 'bb', 'temp': 'cc'}
            s = '  $$$(name), $$(value), $(temp) $$$(x) '
            print ExpandVariables(s, d)
            self.assertTrue(ExpandVariables(s, d, True) 
                            == '  $$aa, $$(value), cc $$ ')
            self.assertTrue(ExpandVariables(s, d, False) 
                            == '  $$aa, $$(value), cc $$$(x) ')

    s = r'-I/usr/include -I"/usr/local/include" -I\ \ /us\ r/include'
    s += ' -D_DEBUG'
    s += ' -I /usr/xxx/include'
    li = shlex.split(s)
    print s
    print li
    optlist, args = getopt.getopt(li, 'I:D:')
    print optlist
    print args
    print '-' * 10
    print GetIncludesFromArgs(s)
    print GetMacrosFromArgs(s)

    s = ';abc;;d;efg;'
    l = ['abc;d', 'efg']
    assert l == SplitSmclStr(s)
    assert 'abc;;d;efg' == JoinToSmclStr(l)
    assert l == SplitSmclStr(JoinToSmclStr(l))

    print GetFileModificationTime(sys.argv[0])

    print StripVariablesForShell('a $(shell wx-config --cxxflags) b')

    print '= unittest ='
    unittest.main() # 跑这个函数会直接退出，所以后面的语句会全部跑不了
