#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import sys
import os
import os.path
import time
import re
import getpass

import EnvVarSettings

# 版本号 850 -> 0.8.5.0
VIMLITE_VER = 862

CPP_SOURCE_EXT = set(['c', 'cpp', 'cxx', 'c++', 'cc'])
CPP_HEADER_EXT = set(['h', 'hpp', 'hxx', 'hh', 'inl', 'inc'])

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


def GetFileModificationTime(fileName):
    '''获取文件最后修改时间
    
    返回自 1970-01-01 以来的秒数'''
    try:
        ret = int(os.path.getmtime(fileName))
    except OSError:
        ret = 0
    finally:
        return ret

def NormalizePath(string):
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
    
    expression  - 需要展开的表达式, 可为空
    workspace   - 工作区实例, 可为空
    projName    - 项目名字, 可为空
    confToBuild - 工作区构建设置名称, 可为空
    fileName    - 文件名字, 要求为绝对路径, 可为空

    RETURN      - 展开后的表达式'''
    tmpExp = ''
    i = 0
    # 先展开所有命令表达式
    # 只支持 `` 内的表达式, 不支持 $() 形式的
    # 因为经常用到在 Makefile 里面的变量, 为了统一, 无法支持 $() 形式
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
    confToBuild - 工作区构建设置名称, 可为空
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
    if not '$' in expression:
        return expression

    # 先展开环境变量, 因为内部变量不可能包含环境变量, 反之则可能包含
    expression = \
            EnvVarSettings.EnvVarSettingsST.Get().ExpandVariables(expression)

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
                imd = EnvVarSettings.EnvVarSettingsST.Get().ExpandVariables(imd)
                imd = ExpandVariables(imd, dVariables)
                dVariables['IntermediateDirectory'] = imd
                dVariables['OutDir'] = imd

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

def IsSourceFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    if ext in CPP_SOURCE_EXT:
        return True
    else:
        return False

def IsHeaderFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    if ext in CPP_HEADER_EXT:
        return True
    else:
        return False


if __name__ == '__main__':
    
    def TestDirSaver():
        ds = DirSaver()
        os.chdir('/')
        print 'I am in', os.getcwd()
        print 'Byebye'
    
    TestDirSaver()
    print os.getcwd()
    
    li = range(10)

    li.append(20)

    print IsSourceFile('/a.c')
    print IsSourceFile('./a.cxx')
    print IsSourceFile('./a.cx')
    print IsHeaderFile('b.h')
    print IsHeaderFile('/homt/a.hxx')

    print StripVariablesForShell(' sne $(CodeLitePath) , $( ooxx  )')
    print StripVariablesForShell('')
    
    print GetFileModificationTime(sys.argv[0])

