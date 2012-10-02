#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''gnu make 里面统一用 / 来分割路径'''

import sys
import os
import os.path
import time
import getpass
import shutil

import Globals
import Macros

import Compiler

from Builder import Builder
from VLWorkspace import VLWorkspaceST
from BuildSettings import BuildSettingsST
from Project import Project
from EnvVarSettings import EnvVar
from EnvVarSettings import EnvVarSettings
from EnvVarSettings import EnvVarSettingsST

BUILDER_NAME = 'GNU makefile for g++/gcc'

from Globals import EscapeString, EscStr4MkSh, PosixPath
EscStr = EscapeString

def ToDQStr(s):
    '''返回用双引号引用的字符串'''
    return '"%s"' % EscStr(s, '"\\')

# DEPRECATED
def __SplitStrBySemicolon(string):
    '''把 ';' 作为分隔符字符串分割，支持 '\\' 转义'''
    charli = []
    result = []
    esc = False
    for c in string:
        if c == '\\':
            esc = True
            continue
        if c == ';' and not esc:
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

def SplitStrBySemicolon(string):
    '''把 ';' 作为分隔符字符串分割，如果想输入 ';'本身，用加倍之即可 ";;"'''
    charli = []
    result = []
    l = len(string)
    idx = 0
    while idx < l:
        c = string[idx]
        if c == ';':
            # 向前查看一个字符，如果仍然是 ';'，当单个 ';'，否则就分割
            if idx+1 >= l:
                nextChar = ''
            else:
                nextChar = string[idx+1]

            if nextChar == ';':
                idx += 1 # 跳过当前
                charli.append(nextChar)
            else:
                # 一次分割
                if charli:
                    result.append(''.join(charli))
                del charli[:]
        else:
            charli.append(c)
        idx += 1
    if charli:
        result.append(''.join(charli))
        del charli[:]
    return result

def SemicolonStr2MkStr(string):
    '''分号分割的字符串安全转为 Makefile 的字符串
    NOTE: 分号分割的字符串是作为原始的命令行参数传过去的，无须作特殊的转义'''
    li = SplitStrBySemicolon(string)
    return " ".join(li)

def IsCxxSource(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    return ext in set(['cpp', 'cxx', 'c++', 'cc'])

def IsCSource(fileName):
    ext = os.path.splitext(fileName)[1][1:]
    return ext in set(['c'])


class BuilderGnuMake(Builder):
    '''GNU make'''
    def __init__(self, d = {}):
        Builder.__init__(self, d)
        #self.name = BUILDER_NAME

    def Export(self, projName, wspConfName = '', force = False):
        return self.Exports(projName, wspConfName, force)

    def Exports(self, projNames, wspConfName = "", force = False):
        '''导出 Makefile 的接口，这个不算通用接口吧？！
        若 wspConfName 为空，即表示用当前选择的工作区设置'''
        if not projNames:
            return False

        if isinstance(projNames, str):
            projNames = [projNames]

        # 忽略不存在的项目
        removeList = []
        for projName in projNames:
            projInst = VLWorkspaceST.Get().FindProjectByName(projName)
            if not projInst:
                removeList.append(projName)
                print "%s not found" % projName
                continue

        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        if not wspConfName:
            wspConfName = matrix.GetSelectedConfigurationName()
        else:
            force = True # 不使用默认设置，就肯定要强制

        # 工作区的 Makefile
        wspMakefile = VLWorkspaceST.Get().GetName() + '_wsp.mk'
        # 转为绝对路径
        wspMakefile = os.path.join(VLWorkspaceST.Get().dirName, wspMakefile)

        text = ''
        text += 'PHONY := all clean\n\n'

        allTgtText = 'all:\n'
        cleanTgtText = 'clean:\n'
        customTgtText = ''

        for idx, projName in enumerate(projNames):
            # 项目设置名称
            projInst = VLWorkspaceST.Get().FindProjectByName(projName)
            if not projInst:
                continue
            projConfName = matrix.GetProjectSelectedConf(wspConfName, projName)
            # 项目设置实例
            projBldConfIns = VLWorkspaceST.Get().GetProjBuildConf(
                projName, projConfName)

            projMakefile = projName + ".mk"
            cddir = os.path.relpath(projInst.dirName,
                                    VLWorkspaceST.Get().dirName)

            envCmd = ''
            # FIXME: 找到办法把这个命令放到项目的 Makefile 前暂时这么做
            cmplName = projBldConfIns.GetCompilerType()
            cmpl = BuildSettingsST.Get().GetCompilerByName(cmplName)
            if cmpl and cmpl.envSetupCmd:
                envCmd = '%s && ' % cmpl.envSetupCmd

            # all 目标的命令部分
            allTgtText += \
                    '\t@echo "----------Building Project:[ %s - %s ]----------"\n'\
                    % (projName, projConfName)
            allTgtText += '\t@%scd %s && $(MAKE) -f %s $@\n' \
                    % (envCmd, EscStr4MkSh(cddir), EscStr4MkSh(projMakefile))

            # clean 目标的命令部分
            cleanTgtText += \
                    '\t@echo "----------Cleaning Project:[ %s - %s ]----------"\n'\
                    % (projName, projConfName)
            cleanTgtText += '\t@cd %s && $(MAKE) -f %s $@\n' \
                    % (EscStr4MkSh(cddir), EscStr4MkSh(projMakefile))

            # 第一个项目的时候，需要添加 Custom Build 目标，如果必要的话
            # 因为 Batch Build 是不支持特殊的 Custom Build 目标的
            if idx == 0 and projBldConfIns.IsCustomBuild():
                for k, v in projBldConfIns.GetCustomTargets().iteritems():
                    customTgtText += 'PHONY += %s\n' % k
                    customTgtText += '%s:\n' % k
                    customTgtText += '\t@cd %s && $(MAKE) -f %s $@\n' \
                            % (EscStr4MkSh(cddir), EscStr4MkSh(projMakefile))

            # 生成项目自身的 Makefile
            self.GenerateMakefile(projName, projConfName, force)

        text += allTgtText + "\n" + cleanTgtText + "\n" + customTgtText
        text += '\n'
        text += '.PHONY: $(PHONY)\n'

        tmpf = Globals.TempFile()
        try:
            f = open(tmpf, "wb")
            f.write(text)
            f.close()
            shutil.move(tmpf, wspMakefile)
        except:
            os.remove(tmpf)
            raise

        #return text
        return True

    def GetPrepFileCmd(self, projName, fileName, wspConfName = ''):
        '''create a command to execute for preprocessing single source file'''
        '''fileName 应该是相对路径'''
        return self.__GetPrpOrObjCmd(projName, fileName, wspConfName, 'prp')

    def GetCmplFileCmd(self, projName, fileName, wspConfName = ''):
        '''create a command to execute for compiling single source file'''
        return self.__GetPrpOrObjCmd(projName, fileName, wspConfName, 'obj')

    def GetBuildCommand(self, projName, wspConfName = ''):
        return self.__GetDefaultBldCmd(projName, wspConfName) + ' all'

    def GetCleanCommand(self, projName, wspConfName = ''):
        return self.__GetDefaultBldCmd(projName, wspConfName) + ' clean'

    def GetBatchBuildCommand(self, projNames, wspConfName = ''):
        '''获取批量构建的命令'''
        if not projNames:
            return ''
        return self.__GetDefaultBldCmd(projNames, wspConfName) + ' all'

    def GetBatchCleanCommand(self, projNames, wspConfName = ''):
        '''获取批量清理的命令'''
        if not projNames:
            return ''
        return self.__GetDefaultBldCmd(projNames, wspConfName) + ' clean'

    def GenerateMakefile(self, projName, projConfName, force = False):
        '''此函数会跳过不必要的 Makefile 创建行为'''
        wspIns = VLWorkspaceST.Get()
        projInst = wspIns.FindProjectByName(projName)
        if not projInst or not projConfName:
            return False
        
        settings = projInst.GetSettings()
        projBldConfIns = wspIns.GetProjBuildConf(projName, projConfName)
        if not settings or not projBldConfIns:
            return False

        ds = Globals.DirSaver()
        os.chdir(projInst.dirName)

        absProjMakefile = os.path.join(projInst.dirName, projName + '.mk')
        # 如果已存在 makefile，且非强制，且项目文件没有修改，跳过
        if not force and not projInst.IsModified() \
           and os.path.exists(absProjMakefile):
            # 添加判断，比较项目文件与 makefile 的时间戳，
            # 只有 makefile 比项目文件新才跳过
            mkModTime = Globals.GetMTime(absProjMakefile)
            if mkModTime > Globals.GetMTime(projInst.GetFileName()):
                return True # 无须重建，直接结束

        # 自定义构建的处理是不一样的
        isCustomBuild = projBldConfIns.IsCustomBuild()
        #isCustomBuild = True

        mkdir = 'gmkdir -p' if Globals.IsWindowsOS() else 'mkdir -p'

        # 重建流程
        text = ''
        text += '##\n'
        text += '## Auto generated by Builder "%s" of VimLite\n' % self.name
        text += '## Do not edit this file, any manual changes will be erased\n'
        text += '##\n'

        # 输出环境变量
        # 必须首先输出, 因为内部变量可能用到了环境变量
        text += '\n'
        text += '##\n'
        text += '## User defined environment variables\n'
        text += '##\n'
        for envVar in EnvVarSettingsST.Get().GetActiveEnvVars():
            text += '%s := %s\n' % (envVar.GetKey(), envVar.GetValue())
        text += '\n'

        if isCustomBuild: # 自定义构建的处理
            buildCmds = projBldConfIns.GetCustomBuildCmd()
            cleanCmds = projBldConfIns.GetCustomCleanCmd()
            workDir = projBldConfIns.GetCustomBuildWorkingDir()
            if not workDir:
                workDir = '.'
            cdCmd = 'cd $(WorkDir) && '
            text += '''\
## variables
MKDIR   := %s
WorkDir := %s
PHONY   := all clean DirSanity Build Clean Rebuild

## builtin targets
define BuildCommands
%s
endef

define CleanCommands
%s
endef

all: Build

clean: Clean

DirSanity:
\t@$(MKDIR) $(WorkDir)

Build: DirSanity
\t$(BuildCommands)

Clean: DirSanity
\t$(CleanCommands)

Rebuild: DirSanity
\t$(CleanCommands)
\t$(BuildCommands)

''' % (mkdir, EscStr4MkSh(workDir), cdCmd + buildCmds, cdCmd + cleanCmds)
            customTargets = projBldConfIns.GetCustomTargets()
            customTargetsText = ''
            for tgt, cmd in customTargets.iteritems():
                customTargetsText += 'PHONY += %s\n' % tgt
                customTargetsText += '%s: DirSanity\n' % tgt
                customTargetsText += '\t%s\n' % (cdCmd + cmd,)
                customTargetsText += '\n'
            text += customTargetsText
            text += '.PHONY: $(PHONY)'
        #### 自定义构建处理完毕
        else: # 非自定义构建时的处理
            text += self.CreateConfigsVariables(projInst, projBldConfIns)

            # 如此实现批量添加包含路径即可
            text += '# auto\n'
            # CPPFLAGS 为 C 和 C++ 编译器共享
            text += 'CPPFLAGS  += $(foreach Dir,$(CmpIncPaths) $(IncPaths),$(IncPat))\n'
            # 预定义的宏
            text += 'CPPFLAGS  += $(foreach Mac,$(Macros),$(MacPat))\n'
            # 库文件搜索路径
            text += 'LDFLAGS   += $(foreach Lip,$(CmpLibPaths) $(LibPaths),$(LipPat))\n'
            # 链接的库
            text += 'LDFLAGS   += $(foreach Lib,$(Libraries),$(LibPat))\n'
            text += '\n'

            text += '# ###\n'
            # 源文件
            text += 'SourceFile = $<\n'
            # 对象文件
            text += 'ObjectFile = $(OutDir)/$(notdir $(basename $(SourceFile)))$(ObjExt)\n'
            # 输出的依赖文件
            text += 'DependFile = $(OutDir)/$(notdir $(basename $(SourceFile)))$(DepExt)\n'
            # 输出的预处理文件
            text += 'PrePrcFile = $(OutDir)/$(notdir $(basename $(SourceFile)))$(PrpExt)\n'
            text += '\n'

            t1, fileRules = self.CreateFileTargets(projInst, projBldConfIns)

            text += t1

            preBldCmd = ''
            postBldCmd =''
            preCmds = [i for i in projBldConfIns.GetPreBuildCommands() if i.enabled]
            if preCmds:
                preBldCmd += '\t@echo ===== Pre Build Commands Start... =====\n'
                preBldCmd += '\n'.join(['\t%s' % i.command for i in preCmds]) + '\n'
                preBldCmd += '\t@echo ===== Pre Build Commands Done. =====\n'
            postCmds = [i for i in projBldConfIns.GetPostBuildCommands() if i.enabled]
            if postCmds:
                postBldCmd += '\t@echo ===== Post Build Commands Start... =====\n'
                postBldCmd += '\n'.join(['\t%s' % i.command for i in postCmds]) + '\n'
                postBldCmd += '\t@echo ===== Post Build Commands Done. =====\n'

            text += 'MKDIR = %s\n' % (mkdir,)

            # DirSanity -> PreBuild -> $(Objects) -> $(OutputFile) -> PostBuild
            # DirSanity 放到 all 的依赖列表的第一位，会跑得比较快，测试表明可用
            # NOTE: 如果作为 PreBuild 的依赖，则可能 $(Objects): PreBuild 会导致
            # 依赖查找，而先于 DirSanity 执行，最终会造成找不到 c 依赖文件而终止
            # $(Objects): | PreBuild 的 PreBuild 仅为了顺序，
            # 不会影响 $(Objects) 的重建
            text += '''\
PHONY = all clean PreBuild Building PostBuild DirSanity

# ===== Targets =====
all: DirSanity PostBuild

PostBuild: Building
%s

Building: $(OutputFile)

$(OutputFile): $(Objects)
ifeq ($(ProjectType),app)
\t$(LinkCmd)
endif
ifeq ($(ProjectType),so)
\t$(SoGenCmd)
endif
ifeq ($(ProjectType),ar)
\t$(ArGenCmd)
endif

$(Objects): | PreBuild

PreBuild:
%s

DirSanity:
\t@$(MKDIR) $(OutDir)
\t@$(MKDIR) $(dir $(OutputFile))

clean:
\t$(RM) $(PrePrcs)
\t$(RM) $(Depends)
\t$(RM) $(Objects)
\t$(RM) $(OutputFile)

''' % (postBldCmd, preBldCmd)

            text += fileRules

            # NOTE: include 的时候，如果文件不存在，会在本 Makefile 中查找以这个
            # 文件名为目标的规则，如果这个规则需要一些中间目录的话，就会出错，
            # 因为这个查找是先于任何规则的，即使 Makefile 的第一个规则就是创建
            # 中间目录也没有用
            #text += '#-include $(Depends)\n'
            #text += '-include $(OutDir)/*$(DepExt)\n' # 用这句才行，真不懂
            text += '''\
ifeq ($(shell test -d $(OutDir) && echo yes || echo no),yes)
-include $(Depends)
endif
'''
            text += '\n'
            text += '.PHONY: $(PHONY)\n'
        #### 内建构建处理完毕

        #absProjMakefile = 'test.mk'
        # 写到文件
        tmpf = Globals.TempFile()
        try:
            f = open(tmpf, "wb")
            f.write(text)
            f.close()
            shutil.move(tmpf, absProjMakefile)
        except:
            os.remove(tmpf)
            print '%s: save failed!' % absProjMakefile
            raise

        projInst.SetModified(False)
        #return text
        return True

    # ========================================================================
    def __GetDefaultBldCmd(self, projNames, wspConfName):
        '''projNames 可以是单个项目名称的字符串'''
        wspIns = VLWorkspaceST.Get()
        self.Exports(projNames, wspConfName)
        blderCmd = self.command
        blderCmd = EnvVarSettingsST.Get().ExpandVariables(blderCmd)
        wspMakefile = '%s_wsp.mk' % wspIns.GetName()
        return 'cd %s && %s %s' % (ToDQStr(wspIns.dirName), blderCmd,
                                   ToDQStr(wspMakefile))

    def __GetPrpOrObjCmd(self, projName, fileName, wspConfName = '', t = 'prp'):
        wspIns = VLWorkspaceST.Get()
        wspConfName = wspConfName \
                or wspIns.GetBuildMatrix().GetSelectedConfigurationName()
        self.Exports(projName, wspConfName)
        projInst = wspIns.FindProjectByName(projName)
        projBldConfIns = self.GetProjectBuildConfig(projName, wspConfName)
        cmplName = projBldConfIns.GetCompilerType()
        cmpl = BuildSettingsST.Get().GetCompilerByName(cmplName)
        if projBldConfIns.IsCustomBuild():
            return ''
        if not cmpl: # 编译器实例总会可能是空的
            return 'echo "%s is not a valid complier!"'
        ds = Globals.DirSaver()
        os.chdir(projInst.dirName)
        if os.path.isabs(fileName):
            fileName = os.path.relpath(fileName)
        mkFile = '%s.mk' % projName
        bwd = projBldConfIns.GetIntermediateDirectory() or '.'
        # 展开所有 VimLite 内置变量
        bwd = Globals.ExpandAllInterVariables(bwd, wspIns, projName, wspConfName)
        if t == 'prp': # 预处理目标
            fn = os.path.splitext(fileName)[0] + cmpl.prpExt
        else: # 对象目标，用于编译文件
            fn = os.path.splitext(fileName)[0] + cmpl.objExt
        tgt = '%s/%s' % (bwd, fn)
        cmd = 'cd %s && make -f %s %s ' % (ToDQStr(projInst.dirName),
                                           ToDQStr(mkFile), ToDQStr(tgt))
        return cmd

    def GetProjectBuildConfig(self, projName, wspConfName = ''):
        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        if not wspConfName:
            wspConfName = matrix.GetSelectedConfigurationName()
        projConfName = matrix.GetProjectSelectedConf(wspConfName, projName)
        projInst = VLWorkspaceST.Get().FindProjectByName(projName)
        projBldConfIns = VLWorkspaceST.Get().GetProjBuildConf(projName,
                                                              projConfName)
        return projBldConfIns

    def CreateFileTargets(self, projInst, projBldConfIns):
        '''返回 (文件列表变量定义文本, 编译文件的规则命令文本)'''
        text = '# ===== Sources and Objects and Depends and PrePrcs =====\n'
        text += 'Sources := \\\n'
        relFiles = projInst.GetAllFiles(False, projBldConfIns.GetName())
        for idx, relFile in enumerate(relFiles):
            if not IsCxxSource(relFile) and not IsCSource(relFile):
                continue
            text += '    %s \\\n' % relFile
        text += '\n\n'

        rulesText = ''

        text += 'Objects := \\\n'
        for idx, relFile in enumerate(relFiles):
            isCxx = False
            isC = False
            if IsCxxSource(relFile):
                isCxx = True
            elif IsCSource(relFile):
                isC = True
            else:
                continue
            fn = os.path.splitext(os.path.basename(relFile))[0]
            text += '    $(OutDir)/%s$(ObjExt) \\\n' % fn

            # 预处理规则
            rulesText += '$(OutDir)/%s$(PrpExt): %s\n' % (fn, relFile)
            if isC:
                rulesText += '\t$(CPrpCmd)\n'
            else:
                rulesText += '\t$(CxxPrpCmd)\n'
            rulesText += '\n'

            # 对象文件规则
            rulesText += '$(OutDir)/%s$(ObjExt): %s $(OutDir)/%s$(DepExt)\n' \
                    % (fn, relFile, fn)
            if isC:
                rulesText += '\t$(CCmpCmd)\n'
            else:
                rulesText += '\t$(CxxCmpCmd)\n'
            rulesText += '\n'

            # 依赖文件规则
            rulesText += '$(OutDir)/%s$(DepExt): %s\n' % (fn, relFile)
            if isC:
                rulesText += '\t@$(CDepGenCmd)\n'
            else:
                rulesText += '\t@$(CxxDepGenCmd)\n'
            rulesText += '\n'
        text += '\n\n'

        # 这两个列表就不需要写出来了
        text += 'Depends := $(foreach Src,$(Sources),$(OutDir)/$(notdir $(basename $(Src)))$(DepExt))\n'
        text += 'PrePrcs := $(foreach Src,$(Sources),$(OutDir)/$(notdir $(basename $(Src)))$(PrpExt))\n'
        text += '\n'

        return text, rulesText

    def CreateConfigsVariables(self, projInst, projBldConfIns):
        cmplName = projBldConfIns.GetCompilerType()
        cmpl = BuildSettingsST.Get().GetCompilerByName(cmplName)
        if not cmpl:
            return ""

        text = '# ===== Compiler Variables =====\n'
        if cmpl.PATH:
            text += 'export PATH := %s:$(PATH)\n' % cmpl.PATH
            text += '\n'
        text += 'CCmpCmd      = %s\n' % cmpl.cCmpCmd
        text += 'CxxCmpCmd    = %s\n' % cmpl.cxxCmpCmd
        text += 'CPrpCmd      = %s\n' % cmpl.cPrpCmd
        text += 'CxxPrpCmd    = %s\n' % cmpl.cxxPrpCmd
        text += 'CDepGenCmd   = %s\n' % cmpl.cDepGenCmd
        text += 'CxxDepGenCmd = %s\n' % cmpl.cxxDepGenCmd
        text += 'LinkCmd      = %s\n' % cmpl.linkCmd
        text += 'ArGenCmd     = %s\n' % cmpl.arGenCmd
        text += 'SoGenCmd     = %s\n' % cmpl.soGenCmd
        text += '\n'

        text += 'ObjExt := %s\n' % cmpl.objExt
        text += 'DepExt := %s\n' % cmpl.depExt
        text += 'PrpExt := %s\n' % cmpl.prpExt
        text += '\n'

        text += 'CmpIncPaths := %s\n' % SemicolonStr2MkStr(cmpl.includePaths)
        text += 'CmpLibPaths := %s\n' % SemicolonStr2MkStr(cmpl.libraryPaths)
        text += '\n'

        text += 'IncPat = %s\n' % cmpl.incPat
        text += 'MacPat = %s\n' % cmpl.macPat
        text += 'LipPat = %s\n' % cmpl.lipPat
        text += 'LibPat = %s\n' % cmpl.libPat
        text += '\n'


        # 项目特定的变量
        cmplOpts = projBldConfIns.GetCCompileOptions()
        cxxCmplOpts = projBldConfIns.GetCompileOptions()
        linkOpts = projBldConfIns.GetLinkOptions()
        incPaths = projBldConfIns.GetIncludePath()
        libPaths = projBldConfIns.GetLibPath()
        libraries = projBldConfIns.GetLibraries()
        macros = projBldConfIns.GetPreprocessor()
        projType = 'app'
        if projBldConfIns.GetProjectType() == Project.DYNAMIC_LIBRARY:
            projType = 'so'
        elif projBldConfIns.GetProjectType() == Project.STATIC_LIBRARY:
            projType = 'ar'
        text += '# ===== Project Variables =====\n'
        text += 'ProjectName            := %s\n' % projInst.GetName()
        text += 'ProjectPath            := $(CURDIR)\n'
        text += 'ConfigurationName      := %s\n' % projBldConfIns.GetName()
        text += 'IntermediateDirectory  := %s\n' % projBldConfIns.GetIntermediateDirectory() or '.'
        text += 'OutDir                 := %s\n' % '$(IntermediateDirectory)'
        text += 'User                   := %s\n' % getpass.getuser()
        text += 'Date                   := %s\n' % time.strftime('%Y-%m-%d', time.localtime())
        text += 'OutputFile             := %s\n' % projBldConfIns.GetOutputFileName() or 'null'
        text += 'CPPFLAGS               := %s\n' % ''
        text += 'CFLAGS                 := %s\n' % SemicolonStr2MkStr(cmplOpts)
        text += 'CXXFLAGS               := %s\n' % SemicolonStr2MkStr(cxxCmplOpts)
        text += 'IncPaths               := %s\n' % SemicolonStr2MkStr(incPaths)
        text += 'Macros                 := %s\n' % SemicolonStr2MkStr(macros)
        text += 'LDFLAGS                := %s\n' % SemicolonStr2MkStr(linkOpts)
        text += 'LibPaths               := %s\n' % SemicolonStr2MkStr(libPaths)
        text += 'Libraries              := %s\n' % SemicolonStr2MkStr(libraries)
        text += 'ProjectType            := %s\n' % projType
        text += '\n'

        return text

# ============================================================================
def test():
    assert SplitStrBySemicolon('abc;def') == ['abc', 'def']
    assert SplitStrBySemicolon(';abc;def') == ['abc', 'def']
    assert SplitStrBySemicolon('abc;def;') == ['abc', 'def']
    assert SplitStrBySemicolon('abc;;d;ef;') == ['abc;d', 'ef']

    from BuilderManager import BuilderManagerST
    import json
    assert SplitStrBySemicolon("snke\;;snekg;") == ['snke;', 'snekg']
    print SemicolonStr2MkStr("s n'\"\"'ke\;;snekg;")
    ins = VLWorkspaceST.Get()
    ins.OpenWorkspace("CxxParser/CxxParser.vlworkspace")
    print ins.projects
    bm = BuilderManagerST.Get()
    #blder = BuilderGnuMake(
        #BuildSettingsST.Get().GetBuilderByName(
            #"GNU makefile for g++/gcc").ToDict())
    blder = bm.GetActiveBuilder()
    bs = BuildSettingsST.Get()
    #print bs.ToDict()
    #print bs.GetCompilerByName('gnu g++')
    print blder.Exports(['CxxParser'])
    #print blder.GenerateMakefile('CxxParser', 'mindll')
    #print '=' * 78
    #print blder.GenerateMakefile('CxxParser', 'Debug')
    print blder.GetPrepFileCmd('CxxParser', 'main.cpp', 'Debug')
    print blder.GetCmplFileCmd('CxxParser', 'main.cpp', 'Debug')
    print blder.GetBuildCommand('CxxParser')
    print blder.GetCleanCommand('CxxParser')
    print blder.GetBatchBuildCommand(['CxxParser'])
    print blder.GetBatchCleanCommand(['CxxParser'])
    print json.dumps(blder.ToDict())

if __name__ == "__main__":
    test()
