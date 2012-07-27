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

# 版本号 850 -> 0.8.5.0
VIMLITE_VER = 903

# VimLite 起始目录
VIMLITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WORKSPACE_FILE_SUFFIX = 'vlworkspace'
PROJECT_FILE_SUFFIX = 'vlproject'

WSP_PATH_SEP = '/'

CPP_SOURCE_EXT = set(['c', 'cpp', 'cxx', 'c++', 'cc'])
CPP_HEADER_EXT = set(['h', 'hpp', 'hxx', 'hh', 'inl', 'inc', ''])

def Cmp(s1, s2):
    '''忽略大小写比较两个字符串'''
    return cmp(s1.lower(), s2.lower())

def IsLinuxOS():
    '''判断系统是否 Linux'''
    import platform
    return platform.system() == 'Linux'

def IsWindowsOS():
    '''判断系统是否 Windows'''
    import platform
    return platform.system() == 'Windows'

def EscapeString(string, chars, escchar = '\\'):
    '''转义字符串'''
    charli = []
    for char in string:
        if char in chars:
            charli.append(escchar)
        charli.append(char)
    return ''.join(charli)

def EscStr4DQ(string):
    '''转义 string，用于放到双引号里面'''
    return EscapeString(string, '"\\')

def EscStr4MkSh(string):
    '''转义 string，用于在 Makefile 里面传给 shell，不是加引号的方式
    bash 的元字符包括：|  & ; ( ) < > space tab
    NOTE: 换行无法转义，应该把 \n 用 $$'\n'表示的'''
    return EscapeString(string, "|&;()<> \t'\"\\")

def Escape(string, chars):
    '''两个参数都是字符串'''
    result = ''
    for char in string:
        if char in chars:
            # 转义之
            result += '\\' + char
        else:
            result += char
    return result

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

def StripVariablesForShell(sExpr):
    '''剔除所有 $( name ) 形式的字符串, 防止被 shell 解析'''
    p = re.compile(r'(\$\(\s*[a-zA-Z_]\w*\s*\))')
    return p.sub('', sExpr)

def ExpandVariables(sString, dVariables):
    '''单次(非递归)展开 $(VarName) 形式的变量'''
    if not sString or not dVariables:
        return sString

    p = re.compile(r'(\$\([a-zA-Z_]\w*\))')

    nStartIdx = 0
    sResult = ''
    while True:
        m = p.search(sString, nStartIdx)
        if m:
            sVarName = m.group(1)[2:-1]
            sResult += sString[nStartIdx : m.start(1)]
            if dVariables.has_key(sVarName):
                sResult += str(dVariables[sVarName])
            else:
                sResult += m.group(1)
            nStartIdx = m.end(1)
        else:
            sResult += sString[nStartIdx :]
            break

    return sResult

def ExpandAllVariables(expression, workspace, projName, confToBuild = '', 
                       fileName = ''):
    '''展开所有变量
    会展开脱字符(`)的表达式，但是，不展开 $(shell ) 形式的表达式

    先展开 `` 的表达式，再展开内部的变量，所以不能在 `` 里面使用内部变量

    expression  - 需要展开的表达式, 可为空
    workspace   - 工作区实例, 可为空
    projName    - 项目名字, 可为空
    confToBuild - 项目构建设置名称, 可为空
    fileName    - 文件名字, 要求为绝对路径, 可为空

    RETURN      - 展开后的表达式'''
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
                    backtick, workspace, projName, confToBuild, fileName)

                output = os.popen(expandedBacktick).read()
                tmp = ' '.join([x for x in output.split('\n') if x])
                tmpExp += tmp
        else:
            tmpExp += c
        i += 1

    result = ExpandAllInterVariables(tmpExp, workspace, projName, confToBuild,
                                     fileName)
    # 剔除没有定义的变量并返回
    return StripVariablesForShell(result)

def ExpandAllInterVariables(expression, workspace, projName, confToBuild = '', 
                            fileName = ''):
    '''展开所有内部变量

    expression  - 需要展开的表达式, 可为空
    workspace   - 工作区实例, 可为空
    projName    - 项目名字, 可为空
    confToBuild - 项目构建设置名称, 可为空
    fileName    - 文件名字, 要求为绝对路径, 可为空
    
    支持的变量有:
    $(User)
    $(Date)
    $(CodeLitePath)

    $(WorkspaceName)
    $(WorkspacePath)

    $(ProjectName)
    $(ProjectPath)
    $(ConfigurationName)
    $(IntermediateDirectory)
    $(OutDir)
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

    # 先展开环境变量, 因为内部变量不可能包含环境变量, 反之则可能包含
    expression = \
            EnvVarSettingsST.Get().ExpandVariables(expression)

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

            bldConf = workspace.GetProjBuildConf(project.GetName(), confToBuild)
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

            # TODO: 怎么处理忽略的文件？
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

    return ExpandVariables(expression, dVariables)

def IsCppSourceFile(fileName):
    '''非正式的判断，不能用于构建时判断，构建时以 Builder 的设置为准'''
    ext = os.path.splitext(fileName)[1][1:]
    if ext in CPP_SOURCE_EXT:
        return True
    else:
        return False

def IsCppHeaderFile(fileName):
    '''非正式的判断，不能用于构建时判断，构建时以 Builder 的设置为准'''
    ext = os.path.splitext(fileName)[1][1:]
    if ext in CPP_HEADER_EXT:
        return True
    else:
        return False

#===============================================================================
# shell 命令展开工具
#===============================================================================
def ExpandShellCmd(s):
    p = re.compile(r'\$\(shell +(.+?)\)')
    return p.sub(ExpandCallback, s)

def GetIncludesFromArgs(s, sw = '-I'):
    return filter(lambda x: x.startswith(sw),
                  GetIncludesAndMacrosFromArgs(s, incSwitch = sw))

def GetMacrosFromArgs(s, sw = '-D'):
    return filter(lambda x: x.startswith(sw),
                  GetIncludesAndMacrosFromArgs(s, defSwitch = sw))

def GetIncludesAndMacrosFromArgs(s, incSwitch = '-I', defSwitch = '-D'):
    '''不支持 -I /usr/include 形式，只支持 -I/usr/include'''
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

#===============================================================================


if __name__ == '__main__':
    import unittest

    class test(unittest.TestCase):
        def testGetArgs(self):
            s = r'-I/usr/include -I"/usr/local/include" -I\ \ /us\ r/include'
            s += ' -D_DEBUG'
            res = GetIncludesAndMacrosFromArgs(s)
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
            self.assertTrue(IsCppSourceFile('/a.c'))
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

    unittest.main()

    print GetFileModificationTime(sys.argv[0])

