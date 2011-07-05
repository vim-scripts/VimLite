#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import sys
import os
import os.path
import time


def GetFileModificationTime(fileName):
    '''获取文件最后修改时间
    
    返回自 1970-01-01 以来的秒数'''
    try:
        ret = int(os.stat(fileName).st_mtime)
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

def ExpandAllVariables(expression, workspace, projName, confToBuild, fileName):
    '''展开所有变量'''
    tmpExp = ''
    i = 0
    # 先展开所有命令表达式
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
                        + ': expecting \'`\''
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

    return ExpandAllInterVariables(
        tmpExp, workspace, projName, confToBuild, fileName)

def ExpandAllInterVariables(expression, workspace, projName, confToBuild, fileName):
    '''展开所有内部变量'''
    output = expression
    if not '$' in output:
        return output

    if workspace:
        output = output.replace('$(WorkspaceName)', workspace.GetName())
        project = workspace.FindProjectByName(projName)
        if project:
            # make sure that the project name does not contain any spaces
            projectName = project.GetName().replace(' ', '_')
            output = output.replace('$(ProjectName)', projectName)
            output = output.replace('$(ProjectPath)', project.dirName)
            output = output.replace('$(WorkspacePath)', workspace.dirName)

            output = output.replace('$(CodeLitePath)', 
                                    os.path.expanduser('~/.codelite'))

            bldConf = workspace.GetProjBuildConf(project.GetName(), confToBuild)
            if bldConf:
                output = output.replace('$(ConfigurationName)', bldConf.GetName())

                imd = bldConf.GetIntermediateDirectory()
                # Substitute all macros from $(IntermediateDirectory)
                imd = imd.replace('$(ProjectPath)', project.dirName)
                imd = imd.replace('$(WorkspacePath)', workspace.dirName)
                imd = imd.replace('$(ProjectName)', projectName)
                imd = imd.replace('$(ConfigurationName)', bldConf.GetName())

                output = output.replace('$(IntermediateDirectory)', imd)
                output = output.replace('$(OutDir)', imd)

            if '$(ProjectFiles)' in output:
                output = output.replace(
                    '$(ProjectFiles)', 
                    ' '.join([ '"%s"' % i for i in project.GetAllFiles()]))
            if '$(ProjectFilesAbs)' in output:
                output = output.replace(
                    '$(ProjectFilesAbs)', 
                    ' '.join([ '"%s"' % i for i in project.GetAllFiles(True)]))

    if fileName:
        output = output.replace('$(CurrentFileName)', 
                                os.path.splitext(os.path.basename(fileName))[0])
        output = output.replace('$(CurrentFileExt)', 
                                os.path.splitext(os.path.basename(fileName))[1][1:])
        output = output.replace('$(CurrentFilePath)', 
                               os.path.dirname(fileName).replace('\\', '/'))
        output = output.replace('$(CurrentFileFullPath)', 
                               fileName.replace('\\', '/'))

    output = output.replace('$(User)', os.environ['USER'])
    output = output.replace('$(Date)', time.strftime('%Y-%m-%d', time.localtime()))

    # TODO: 展开所有环境变量

    return output

def IsSourceFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    if ext in set(['c', 'cpp', 'cxx', 'c++', 'cc']):
        return True
    else:
        return False

def IsHeaderFile(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    if ext in set(['h', 'hpp', 'hxx', 'hh', 'inl', 'inc']):
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
    
    #print GetFileModificationTime(sys.argv[1])

