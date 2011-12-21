#!/usr/bin/env python
# -*- encoding:utf-8 -*-

'''gnu make 里面统一用 / 来分割路径'''

import os
import os.path
import time
import getpass

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


'''
GNU make 构建步骤
1. MakeDirStep, PreBuild 和 $(Objects)，这三个目标可以不按顺序
2. $(OutputFile)，输出文件，确保不能为空，否则 PostBuild 不执行
3. PostBuild，最后执行

根据 Makefile 的依赖来实现先后顺序，如: all: PostBuild
'''


def GetMakeDirCmd(bldConf, relPath = ''):
    intermediateDirectory = bldConf.GetIntermediateDirectory()
    relativePath = relPath

    intermediateDirectory = intermediateDirectory.replace('\\', '/').strip()
    if intermediateDirectory.startswith('./') and relativePath == './':
        relativePath = ''

    if intermediateDirectory.startswith('./') and relativePath:
        intermediateDirectory = intermediateDirectory[2:]

    text = ''

    makingDirName = relativePath + intermediateDirectory
    escStr = Globals.Escape(makingDirName, '"\\')

    if Globals.IsWindowsOS():
        # NOTE: 如果是 Windows 下 md 命令，只能忽略错误，无法抑制错误信息的输出
        text += '@-$(MakeDirCommand) "%s"' % escStr
    else:
        # posix 下
        text += '@test -d "%s" || $(MakeDirCommand) "%s"' % (escStr, escStr)

    return text


class BuilderGnuMake(Builder):
    '''GnuMake 的 Buidler'''
    def __init__(self, name = 'GNU makefile for g++/gcc', command = 'make -f'):
        Builder.__init__(self, name, command)
    
    def Export(self, projName, confToBuild = '', isProjectOnly = False, 
               force = False):
        '''导出工作空间 makefile，如果没有指定 confToBuild，
        则导出工作空间当前选择的构建设置。
        
        因为工作空间的 Makefile 管理所有子 Makefile, 而每次的目标都可能不同,
        所以每次调用此函数, 都会重新生成工作空间的 Makefile 的内容.
        由于此 Makefile 的内容并不多, 每次都重新生成的开销可以接受.
        绝大多数情况下，可不指定 confToBuild。'''
        if not projName:
            return False
        
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            print '%s not found' % (projName,)
            return False
        
        if isProjectOnly:
            return self.Export2([projName], confToBuild, force)
        else:
            bldConfName = confToBuild
            if not confToBuild:
                # 没有指定构建的配置，从 BuildMatrix 获取默认值
                bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, '')
                if not bldConf:
                    print 'Cant find build configuration for project "%s"' \
                            % (projName,)
                    return False
                bldConfName = bldConf.GetName()
            
            # 获取依赖的项目名称列表
            deps = project.GetDependencies(bldConfName)

            return self.Export2(deps + [projName], confToBuild, force)

    # 灵活版本的 Export
    def Export2(self, projects, confToBuild = '', force = False):
        '''导出工作空间 makefile，如果没有指定 confToBuild（工作区的设置名），
        则导出工作空间当前选择的构建设置。
        
        因为工作空间的 Makefile 管理所有子 Makefile, 而每次的目标都可能不同,
        所以每次调用此函数, 都会重新生成工作空间的 Makefile 的内容.
        由于此 Makefile 的内容并不多, 每次都重新生成的开销可以接受.
        绝大多数情况下，可不指定 confToBuild。'''
        if not projects:
            return False
        
        removeList = []
        # 检查所有的项目是否都存在，现在的处理是简单地忽略不存在的项目
        for projName in projects:
            project = VLWorkspaceST.Get().FindProjectByName(projName)
            if not project:
                # Missing dependencies project, just ignore
                removeList.append(projName)
                print 'Can not find project: ', projName
                # TODO: 添加移除选择
        
        wspMakefile = VLWorkspaceST.Get().GetName() + '_wsp.mk'
        # 转为绝对路径
        wspMakefile = os.path.join(VLWorkspaceST.Get().dirName, wspMakefile)
        wspFile = VLWorkspaceST.Get().GetWorkspaceFileName()

        text = ''
        
        text += '.PHONY: all clean\n\n'
        text += 'all:\n'
        
        builderCmd = self.GetBuilderCommand(False)
        # 展开环境变量
        builderCmd = EnvVarSettingsST.Get().ExpandVariables(builderCmd)
        #replace all Windows like slashes to POSIX
        builderCmd = builderCmd.replace('\\', '/')
        
        # generate the makefile for the selected workspace configuration
        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        if confToBuild:
            wspSelConfName = confToBuild
        else:
            wspSelConfName = matrix.GetSelectedConfigurationName()
        
        for projName in projects:
            isCustom = False
            project = VLWorkspaceST.Get().FindProjectByName(projName)
            if not project:
                continue
            
            projectSelConfName = matrix.GetProjectSelectedConf(
                wspSelConfName, project.GetName())
            projectBldConf = VLWorkspaceST.Get().GetProjBuildConf(
                project.GetName(), projectSelConfName)
            
            if projectBldConf and projectBldConf.IsCustomBuild():
                isCustom = True

            # 手动指定构建配置名称，强制重建 makefile，但是这种情况很少出现
            if confToBuild:
                project.SetModified(True)

            # 构建前缀显示
            text += '\t@echo ' + Macros.BUILD_PROJECT_PREFIX \
                    + project.GetName() + ' - ' + projectSelConfName \
                    + ' ]----------\n'

            relProjFile = os.path.relpath(project.GetFileName(), 
                                          os.path.dirname(wspFile))

            if isCustom:
            # 如果是自定义构建，PreBuild 和 PostBuild 命令写到工作区的 Makefile
                # Custom Build 项目的构建命令全部写到工作区的 Makefile
                text += self.CreateCustomPreBuildEvents(projectBldConf)

                customWd = projectBldConf.GetCustomBuildWorkingDir()
                buildCmd = projectBldConf.GetCustomBuildCmd()
                customWdCmd = ''

                # 为 customWd 和 buildCmd 展开所有变量
                customWd = Globals.ExpandAllVariables(
                    customWd, VLWorkspaceST.Get(), project.GetName(), 
                    projectBldConf.GetName(), '')
                buildCmd = Globals.ExpandAllVariables(
                    buildCmd, VLWorkspaceST.Get(), project.GetName(), 
                    projectBldConf.GetName(), '')

                buildCmd = buildCmd.strip()

                if not buildCmd:
                    buildCmd += '@echo Project has no custom build command!'

                # 如果提供自定义命令的工作目录，用之，否则使用项目默认的
                customWd = customWd.strip()
                if customWd:
                    customWdCmd += '@cd "' + Globals.ExpandAllVariables(
                        customWd, VLWorkspaceST.Get(), 
                        project.GetName(), '', '') + '" && '
                else:
                    customWdCmd += self.GetCdCmd(wspFile, relProjFile)

                text += '\t' + customWdCmd + buildCmd + '\n'
                text += self.CreateCustomPostBuildEvents(projectBldConf)
            else:
                # generate the project makefile
                self.GenerateMakefile(project, projectSelConfName, \
                                      confToBuild and True or force)
                text += '\t' + self.GetCdCmd(wspFile, relProjFile)
                text += self.GetProjectMakeCommand(project, confToBuild,\
                                                   '\n', False, False, False)

        # create the clean target
        text += 'clean:\n'
        for projName in projects:
            isCustom = False
            projectSelConfName = matrix.GetProjectSelectedConf(
                wspSelConfName, projName)
            project = VLWorkspaceST.Get().FindProjectByName(projName)
            if not project:
                continue

            text += '\t@echo ' + Macros.CLEAN_PROJECT_PREFIX \
                    + project.GetName() + ' - ' + projectSelConfName \
                    + ' ]----------\n'

            relProjFile = os.path.relpath(project.GetFileName(), 
                                          os.path.dirname(wspFile))

            projectBldConf = VLWorkspaceST.Get().GetProjBuildConf(
                project.GetName(), projectSelConfName)
            if projectBldConf and projectBldConf.IsCustomBuild():
                isCustom = True

            if not isCustom:
                text += '\t' + self.GetCdCmd(wspFile, relProjFile) \
                        + builderCmd + ' "' + project.GetName() \
                        + '.mk" clean\n'
            else:
                customWd = projectBldConf.GetCustomBuildWorkingDir()
                cleanCmd = projectBldConf.GetCustomCleanCmd()

                # 为 customWd 和 buildCmd 展开所有变量
                customWd = Globals.ExpandAllVariables(
                    customWd, VLWorkspaceST.Get(), project.GetName(), 
                    projectBldConf.GetName(), '')
                buildCmd = Globals.ExpandAllVariables(
                    buildCmd, VLWorkspaceST.Get(), project.GetName(), 
                    projectBldConf.GetName(), '')

                customWdCmd = ''

                cleanCmd = cleanCmd.strip()
                if not cleanCmd:
                    cleanCmd += '@echo Project has no custom clean command!'

                customWd = customWd.strip()
                if customWd:
                    customWdCmd += '@cd "' + Globals.ExpandAllVariables(
                        customWd, VLWorkspaceST.Get(), 
                        project.GetName(), '', '') + '" && '
                else:
                    customWdCmd += self.GetCdCmd(wspFile, relProjFile)
                text += '\t' + customWdCmd + cleanCmd + '\n'

        # dump the content to file
        try:
            f = open(wspMakefile, 'wb')
            f.write(text)
            f.close()
        except IOError:
            print wspMakefile, 'open failed!'
            raise IOError

        return True

    def GetBuildCommand(self, projName, confToBuild):
        cmd = ''
        bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, confToBuild)
        if not bldConf:
            print projName, 'have not any build config'
            return ''

        self.Export(projName, confToBuild, False, False)

        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        builderCmd = self.GetBuilderCommand(True)
        # 展开环境变量
        builderCmd = EnvVarSettingsST.Get().ExpandVariables(builderCmd)

        # Fix: replace all Windows like slashes to POSIX
        # Not need
        #builderCmd = builderCmd.replace('\\', '/')

        cmd += builderCmd + ' "' + VLWorkspaceST.Get().GetName() + '_wsp.mk"'

        return cmd

    def GetCleanCommand(self, projName, confToBuild):
        return self.GetBuildCommand(projName, confToBuild) + ' clean'

    def GetBatchBuildCommand(self, projects, confToBuild):
        cmd = ''
        #print projects

        if not projects:
            return cmd

        self.Export2(projects, confToBuild, False)

        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        builderCmd = self.GetBuilderCommand(True)
        # 展开环境变量
        builderCmd = EnvVarSettingsST.Get().ExpandVariables(builderCmd)

        # Fix: replace all Windows like slashes to POSIX
        #builderCmd = builderCmd.replace('\\', '/')

        cmd += builderCmd + ' "' + VLWorkspaceST.Get().GetName() + '_wsp.mk"'

        return cmd

    def GetBatchCleanCommand(self, projects, confToBuild):
        if not projects:
            return ''
        else:
            return self.GetBatchBuildCommand(projects, confToBuild) + ' clean'

    def GetCompileFileCmd(self, projName, confToBuild, fileName):
        '''利用已生成的 Makefile，直接 make 指定文件的对象文件的目标'''
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            return ''

        self.Export(projName, confToBuild, True, False)

        target = ''
        cmpType = ''
        fn = fileName

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, confToBuild)
        if not bldConf:
            return ''

        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        objNamePrefix = self.DoGetTargetPrefix(fn, project.dirName)
        target += bldConf.GetIntermediateDirectory() + '/' + objNamePrefix \
                + os.path.splitext(os.path.basename(fn))[0] \
                + cmp.GetObjectSuffix()

        # 展开变量 target
        target = Globals.ExpandAllVariables(
            target, VLWorkspaceST.Get(), project.GetName(), confToBuild)

        cmd = self.GetProjectMakeCommand(project, confToBuild, target, False,
                                         False)
        # 展开环境变量 cmd
        cmd = EnvVarSettingsST.Get().ExpandVariables(cmd)

        return cmd
    
    def GetPreprocessFileCmd(self, projName, confToBuild, fileName):
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            return ''

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, confToBuild)
        if not bldConf:
            return ''

        self.Export(projName, confToBuild, True, False)

        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        builderCmd = self.GetBuilderCommand(True)

        # Fix: replace all Windows like slashes to POSIX
        #builderCmd = builderCmd.replace('\\', '/')

        # create the target
        target = ''
        fn = fileName

        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)
        
        objNamePrefix = self.DoGetTargetPrefix(fn, project.dirName)
        target += bldConf.GetIntermediateDirectory() + '/' + objNamePrefix \
                + os.path.splitext(os.path.basename(fn))[0] \
                + cmp.GetPreprocessSuffix()

        # 展开变量 target
        target = Globals.ExpandAllVariables(
            target, VLWorkspaceST.Get(), project.GetName(), confToBuild)

        cmd = self.GetProjectMakeCommand(project, confToBuild, target, False, 
                                        False)
        # 展开环境变量 cmd
        cmd = EnvVarSettingsST.Get().ExpandVariables(cmd)

        return cmd
    
    def GetPOBuildCommand(self, projName, confToBuild):
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            return ''

        # generate the makefile
        self.Export(projName, confToBuild, True, False)
        cmd = self.GetProjectMakeCommand(project, confToBuild, 'all', False, 
                                         False)
        return cmd
    
    def GetPOCleanCommand(self, projName, confToBuild):
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            return ''

        # generate the makefile
        self.Export(projName, confToBuild, True, False)
        cmd = self.GetProjectMakeCommand(project, confToBuild, 'clean', False, 
                                         True)
        return cmd
    
    def GetPORebuildCommand(self, projName, confToBuild):
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            return ''

        # generate the makefile
        self.Export(projName, confToBuild, True, False)
        cmd = self.GetProjectMakeCommand(project, confToBuild, 'all', True, 
                                         False)
        return cmd

    # protected methods?
    def CreateListMacros(self, project, confToBuild):
        return self.CreateObjectList(project, confToBuild)
    
    def CreateSrcList(self, project, confToBuild):
        # TODO: 暂不需要
        text = ''
        text += 'Srcs='

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        files = project.GetAllFiles(False, bldConf.GetName())

        relPath = ''

        return text
    
    def CreateObjectList(self, project, confToBuild):
        text = ''
        text += 'Objects=\\\n'

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        cwd = project.dirName

        files = project.GetAllFiles(True, bldConf.GetName())   # 绝对路径

        for i in files:
            ft = cmp.GetCmpFileType(os.path.splitext(i)[1][1:])
            # is this a valid file?
            if ft.kind == Compiler.CmpFileKindInvalid:
                continue

            if ft.kind == Compiler.CmpFileKindResource and bldConf \
               and not bldConf.IsResCompilerRequired():
                # 不需要资源编译器
                continue

            objPrefix = self.DoGetTargetPrefix(i, cwd)

            text += '\t'

            if ft.kind == Compiler.CmpFileKindResource:
                # 资源文件
                text += '$(IntermediateDirectory)/' + objPrefix \
                        + os.path.dirname(i) \
                        + '$(ObjectSuffix) '
            else:
                # 源文件
                text += '$(IntermediateDirectory)/' + objPrefix \
                        + os.path.splitext(os.path.basename(i))[0] \
                        + '$(ObjectSuffix) '

            text += '\\\n'

        if text.endswith('\\\n'):
            text = text.rstrip('\\\n')
        text += '\n\n'

        return text
    
    def CreateLinkTargets(self, type, bldConf):
        '''执行顺序: MakeDirStep PreBuild $(Objects) $(OutputFile) PostBuild'''
        # incase project is type exe or dll, force link
        # this is to workaround bug in the generated makefiles
        # which causes the makefile to report 'nothing to be done'
        # even when a dependency was modified
        readObjectsFromFile = bldConf.GetCompiler() \
                and bldConf.GetCompiler().GetReadObjectFilesFromList()

        text = ''
        if type == Project.EXECUTABLE or type == Project.DYNAMIC_LIBRARY:
            text += 'all: '
            if readObjectsFromFile:
                text += 'objects_file '
            #text += '$(OutputFile)\n\n'
            text += 'PostBuild\n\n'

            #text += '$(OutputFile): MakeDirStep $(Objects)\n'
            # 添加 PreBuild 和 PostBuild 依赖
            text += '$(OutputFile): MakeDirStep PreBuild $(Objects)\n'
        else:
            # TODO: 为什么静态链接时依赖目标是一个目录？
            text += 'all: $(IntermediateDirectory) '
            if readObjectsFromFile:
                text += 'objects_file '
            #text += '$(OutputFile)\n\n'
            text += 'PostBuild\n\n'

            #text += '$(OutputFile): $(Objects)\n'
            # 添加 PreBuild
            text += '$(OutputFile): PreBuild $(Objects)\n'

        if bldConf.IsLinkerRequired():
            text += self.CreateTargets(type, bldConf)

        return text
    
    def CreateFileTargets(self, project, confToBuild):
        text = ''
        wspIns = VLWorkspaceST.Get()
        bldConf = wspIns.GetProjBuildConf(project.GetName(), confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        # 是否生成依赖文件 FIXME: 需要转为 bool 类型
        generateDependenciesFiles = cmp.GetGenerateDependeciesFile() \
                and cmp.GetDependSuffix()
        # 是否支持预处理文件 FIXME: 同上
        supportPreprocessOnlyFiles = cmp.GetSwitch('PreprocessOnly') \
                and cmp.GetPreprocessSuffix()

        absFiles = project.GetAllFiles(True, bldConf.GetName())
        relFiles = project.GetAllFiles(False, bldConf.GetName())

        text += '\n\n'
        text += '##\n'
        text += '## Objects\n'
        text += '##\n'

        cwd = project.dirName

        for index in range(len(absFiles)):
            ext = os.path.splitext(absFiles[index])[1][1:].lower()
            ft = cmp.GetCmpFileType(ext)
            if ft.kind != Compiler.CmpFileKindInvalid:
                absFile = absFiles[index]

                fileNameOnly = os.path.splitext(os.path.basename(absFile))[0]
                fullPathOnly = absFile  # 等同于绝对路径的文件名
                fullNameOnly = os.path.basename(absFile)
                compilationLine = ft.compilation_line

                objPrefix = self.DoGetTargetPrefix(absFile, cwd)

                # use UNIX style slashes
                absFile = absFile.replace('\\', '/')
                relFile = relFiles[index].replace('\\', '/')

                compilationLine = compilationLine.replace('$(FileName)', 
                                                          fileNameOnly)
                compilationLine = compilationLine.replace('$(FileFullName)', 
                                                          fullNameOnly)
                compilationLine = compilationLine.replace('$(FileFullPath)', 
                                                          fullPathOnly)
                compilationLine = compilationLine.replace('$(FilePath)', 
                                                          relFile)

                if ft.kind == Compiler.CmpFileKindResource:
                    compilationLine = compilationLine.replace(
                        '$(ObjectName)', objPrefix + fullNameOnly)
                else:
                    compilationLine = compilationLine.replace(
                        '$(ObjectName)', objPrefix + fileNameOnly)

                # ?
                compilationLine = compilationLine.replace(
                    '$(ObjectName)', objPrefix + fileNameOnly)

                compilationLine = compilationLine.replace('\\', '/')

                if ft.kind == Compiler.CmpFileKindSource:
                    objectName = ''
                    dependFile = ''
                    preprocessedFile = ''

                    isCFile = (os.path.splitext(relFile)[1] == '.c')

                    objectName += '$(IntermediateDirectory)/' + objPrefix \
                            +fileNameOnly + '$(ObjectSuffix)'
                    if generateDependenciesFiles:
                        dependFile += '$(IntermediateDirectory)/' + objPrefix \
                                + fileNameOnly + '$(DependSuffix)'
                    if supportPreprocessOnlyFiles:
                        preprocessedFile += '$(IntermediateDirectory)/' \
                                + objPrefix \
                                + fileNameOnly \
                                + '$(PreprocessSuffix)'

                    # set the file rule
                    text += objectName + ': ' + relFile + ' ' + dependFile + \
                            '\n'
                    text += '\t' + compilationLine + '\n'

                    cmpOptions = '$(CmpOptions)'
                    if isCFile:
                        cmpOptions = '$(C_CmpOptions)'

                    compilerMacro = self.DoGetCompilerMacro(relFile)
                    if generateDependenciesFiles:
                        # -MM 指示只添加非系统的头文件到目标的依赖列表
                        # -MG 忽略找不到指定的头文件错误，直接添加到依赖列表
                        # -MP 为所有依赖的头文件建立一个目标，预防删除了头文件后
                        #     再 make 的时候出现找不到头文件的错误
                        # -MT 规则的目标
                        # -MF 输出 makefile 规则的文件
                        text += dependFile + ': ' + relFile + '\n'
                        text += '\t' + '@' + compilerMacro + ' ' + cmpOptions \
                                + ' $(IncludePath) -MG -MP -MT' \
                                + objectName \
                                + ' -MF' \
                                + dependFile \
                                + ' -MM "' \
                                + absFile \
                                + '"\n\n'

                    if supportPreprocessOnlyFiles:
                        text += preprocessedFile + ': ' + relFile + '\n'
                        text += '\t' + '@' + compilerMacro + ' ' + cmpOptions \
                                + ' $(IncludePath) $(PreprocessOnlySwitch)'\
                                + ' $(OutputSwitch) ' \
                                + preprocessedFile + ' "' + absFile + '"\n\n'
                elif ft.kind == Compiler.CmpFileKindResource \
                        and bldConf.IsResCompilerRequired():
                    objectName = ''
                    objectName += '$(IntermediateDirectory)/' + objPrefix \
                            + fullNameOnly + '$(ObjectSuffix)'
                    text += objectName + ': ' + relFile + '\n'
                    text += '\t' + compilationLine + '\n'

        if generateDependenciesFiles:
            text += '\n'
            text += '-include ' + '$(IntermediateDirectory)/*$(DependSuffix)\n'

        return text
    
    def CreateCleanTargets(self, project, confToBuild):
        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                      confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        # 不允许星号删除（批量删除）
        useAsterisk = False

        absFiles = project.GetAllFiles(True, bldConf.GetName())
        relFiles = project.GetAllFiles(False, bldConf.GetName())

        text = ''

        # add clean target
        text += '##\n'
        text += '## Clean\n'
        text += '##\n'
        text += 'clean:\n'

        cwd = project.dirName

        # TODO: 区分 windows 和 linux 系统
        if not useAsterisk:
            for index in range(len(absFiles)):
                objPrefix = self.DoGetTargetPrefix(absFiles[index], cwd)
                ext = os.path.splitext(absFiles[index])[1][1:]

                ft = cmp.GetCmpFileType(ext)
                if ft.kind == Compiler.CmpFileKindSource:
                    relPath = relFiles[index].strip()

                    fileNameOnly = os.path.splitext(
                        os.path.basename(absFiles[index]))[0]
                    objectName = objPrefix + fileNameOnly + '$(ObjectSuffix)'
                    dependFile = objPrefix + fileNameOnly + '$(DependSuffix)'
                    preprocessFile = objPrefix + fileNameOnly \
                            + '$(PreprocessSuffix)'

                    text += '\t' + '$(RM) ' + '$(IntermediateDirectory)/' \
                            + objectName + '\n'
                    text += '\t' + '$(RM) ' + '$(IntermediateDirectory)/' \
                            + dependFile + '\n'
                    text += '\t' + '$(RM) ' + '$(IntermediateDirectory)/' \
                            + preprocessFile + '\n'
        else:
            text += '\t' + '$(RM) ' + '$(IntermediateDirectory)/*.*' + '\n'

        # delete the output file
        text += '\t' + '$(RM) ' + '$(OutputFile)\n'
        if Globals.IsWindowsOS():
            # Windows 下如果输出文件不是以 .exe 结尾，会被 gcc 自动加上
            # 所以要删除此文件
            text += '\t' + '$(RM) ' + '$(OutputFile).exe\n'

        # Remove the pre-compiled header
        pchFile = bldConf.GetPrecompiledHeader().strip()

        if pchFile:
            text += '\t' + '$(RM) ' + pchFile + '.gch' + '\n'


        text += '\n\n'

        return text
    
    # Override default methods defined in the builder interface
    def GetBuilderCommand(self, isCommandlineCommand):
        '''isCommandlineCommand 表示在外部调用 make -f x.mk
        否则就是在 工作区 makefile 中调用'''
        if isCommandlineCommand:
            builderCmd = Builder.GetBuilderCommand(self)
        else:
            builderCmd = '"$(MAKE)"' + ' -f'

        return builderCmd

    # private methods?
    def GenerateMakefile(self, project, confToBuild, force):
        '''此函数会跳过不必要的 Makefile 创建行为'''
        projName = project.GetName()
        configName = confToBuild

        wspIns = VLWorkspaceST.Get()

        if not confToBuild:
            matrix = VLWorkspaceST.Get().GetBuildMatrix()
            configName = matrix.GetProjectSelectedConf(
                matrix.GetSelectedConfigurationName(), projName)

        settings = project.GetSettings()
        if not settings:
            return

        # get the selected build configuration for this project
        bldConf = wspIns.GetProjBuildConf(projName, confToBuild)
        if not bldConf:
            return

        ds = Globals.DirSaver()
        os.chdir(project.dirName)

        makefile = os.path.join(project.dirName, projName + '.mk')  # 绝对路径

        # 如果已存在 makefile，且非强制，且项目和环境变量都没有修改，跳过
        if os.path.exists(makefile):
            if not force:
                # 添加判断，比较项目文件与 makefile 的时间戳，
                # 只有 makefile 比项目文件新才跳过
                mkModTime = Globals.GetFileModificationTime(makefile)
                if not project.IsModified() \
                   and mkModTime \
                   > Globals.GetFileModificationTime(project.GetFileName()):
                    # 比较 makefile 和环境变量文件的时间戳
                    if mkModTime > EnvVarSettingsST.Get().GetModificationTime():
                        return

        # generate the selected configuration for this project
        text = ''

        text += '##\n'
        text += '## Auto Generated makefile by VimLite\n'
        text += '## Do not edit this file, any manual changes will be erased\n'
        text += '##\n'

        # 输出环境变量
        # 必须首先输出, 因为内部变量可能用到了环境变量
        text += '\n'
        text += '##\n'
        text += '## User defined environment variables\n'
        text += '##\n'
        for envVar in EnvVarSettingsST.Get().GetActiveEnvVars():
            text += envVar.GetKey() + ':=' + envVar.GetValue() + '\n'
        text += '\n'

        # Create the makefile variables
        text += self.CreateConfigsVariables(project, bldConf)

        text += self.CreateListMacros(project, confToBuild)

        # create the build targets
        text += '##\n'
        text += '## Main Build Targets\n'
        text += '##\n'

        # incase project is type exe or dll, force link
        # this is to workaround bug in the generated makefiles
        # which causes the makefile to report 'nothing to be done'
        # even when a dependency was modified
        #targetName = bldConf.GetIntermediateDirectory()
        projType = settings.GetProjectType(bldConf.GetName())
        if projType == Project.EXECUTABLE or projType == Project.DYNAMIC_LIBRARY:
            targetName = 'MakeDirStep'
        else:
            targetName = '$(IntermediateDirectory)'
        text += self.CreateLinkTargets(projType, bldConf)

        # 添加 PostBuild 命令，现在的方法是直接添加到目标规则的后面，待改进
        # NOTE: 修改为单独的目标
        #text += self.CreatePostBuildEvents(bldConf)

        # In any case add the 'objects_file' target here
        # this is a special target that creates a file with the content of the 
        # $(Objects) variable (to be used with the @<file-name> option of the LD)
        #text += '\n'
        #text += 'objects_file:\n'
        #text += '\t@echo $(Objects) > $(ObjectsFileList)\n'

        text += self.CreateMakeDirsTarget(bldConf, targetName)
        # 添加 PreBuild 目标
        text += self.CreatePreBuildEvents(bldConf)
        # 添加 PostBuild 目标
        text += self.CreatePostBuildEvents(bldConf)
        # 添加预编译头目标
        text += self.CreatePreCompiledHeaderTarget(bldConf)

        #-----------------------------------------------------------
        # Create a list of targets that should be built according to
        # projects' file list
        #-----------------------------------------------------------
        text += self.CreateFileTargets(project, confToBuild)
        text += self.CreateCleanTargets(project, confToBuild)

        # 写到文件
        try:
            f = open(makefile, 'wb')
            f.write(text)
            f.close()
        except IOError:
            print makefile, 'open failed!'
            raise IOError

        # mark the project as non-modified one
        project.SetModified(False)
        return text
    
    def CreateConfigsVariables(self, project, bldConf):
        '''生成基本变量'''
        # TODO: 添加 PATH 变量
        name = bldConf.GetName()
        #name = self.NormalizeConfigName(name)

        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        #objectsFileName = project.dirName
        objectsFileName = os.path.join(project.dirName, project.GetName() + '.txt')
        text = ''
        text += '## ' + name + '\n'

        # Expand the build macros into the generated makefile
        text += "ProjectName            :=" + project.GetName() + "\n"
        text += "ConfigurationName      :=" + name + "\n"
        text += "IntermediateDirectory  :=" + bldConf.GetIntermediateDirectory() + "\n"
        text += "OutDir                 := $(IntermediateDirectory)\n"
        text += "WorkspacePath          :=\"" + Globals.NormalizePath(VLWorkspaceST.Get().dirName) + "\"\n"
        text += "ProjectPath            :=\"" + Globals.NormalizePath(project.dirName) + "\"\n"
        text += "CurrentFileName        :=\n" # TODO: Need implementation
        text += "CurrentFilePath        :=\n" # TODO: Need implementation
        text += "CurrentFileFullPath    :=\n" # TODO: Need implementation
        text += "User                   :=" + getpass.getuser() + "\n"
        text += "Date                   :=" + time.strftime('%Y-%m-%d', time.localtime()) + "\n"
        text += "CodeLitePath           :=\"" + Globals.NormalizePath(
            os.path.join(os.path.expanduser('~'), '.codelite')) + "\"\n"
        text += "LinkerName             :=" + cmp.GetTool("LinkerName") + "\n"
        text += "ArchiveTool            :=" + cmp.GetTool("ArchiveTool") + "\n"
        text += "SharedObjectLinkerName :=" + cmp.GetTool("SharedObjectLinkerName") + "\n"
        text += "ObjectSuffix           :=" + cmp.GetObjectSuffix() + "\n"
        text += "DependSuffix           :=" + cmp.GetDependSuffix() + "\n"
        text += "PreprocessSuffix       :=" + cmp.GetPreprocessSuffix() + "\n"
        text += "DebugSwitch            :=" + cmp.GetSwitch("Debug") + "\n"
        text += "IncludeSwitch          :=" + cmp.GetSwitch("Include") + "\n"
        text += "LibrarySwitch          :=" + cmp.GetSwitch("Library") + "\n"
        text += "OutputSwitch           :=" + cmp.GetSwitch("Output") + "\n"
        text += "LibraryPathSwitch      :=" + cmp.GetSwitch("LibraryPath") + "\n"
        text += "PreprocessorSwitch     :=" + cmp.GetSwitch("Preprocessor") + "\n"
        text += "SourceSwitch           :=" + cmp.GetSwitch("Source") + "\n"
        text += "CompilerName           :=" + cmp.GetTool("CompilerName") + "\n"
        text += "C_CompilerName         :=" + cmp.GetTool("C_CompilerName") + "\n"
        text += "OutputFile             :=" + (bldConf.GetOutputFileName() or 'null') + "\n"
        text += "Preprocessors          :=" + self.ParsePreprocessor(bldConf.GetPreprocessor()) + "\n"
        text += "ObjectSwitch           :=" + cmp.GetSwitch("Object") + "\n"
        text += "ArchiveOutputSwitch    :=" + cmp.GetSwitch("ArchiveOutput") + "\n"
        text += "PreprocessOnlySwitch   :=" + cmp.GetSwitch("PreprocessOnly") + "\n"
        text += "ObjectsFileList        :=\"" + Globals.NormalizePath(objectsFileName) + "\"\n"

        if Globals.IsWindowsOS():
            #text += 'MakeDirCommand         :=' + 'md' + '\n'
            text += 'MakeDirCommand         :=' + 'gmkdir -p' + '\n'
        else:
            text += 'MakeDirCommand         :=' + 'mkdir -p' + '\n'

        buildOpts = bldConf.GetCompileOptions()
        buildOpts = buildOpts.replace(';', ' ')

        cBuildOpts = bldConf.GetCCompileOptions()
        cBuildOpts = cBuildOpts.replace(';', ' ')

        text += "CmpOptions             :=" + buildOpts  + " $(Preprocessors)" + "\n"
        text += "C_CmpOptions           :=" + cBuildOpts + " $(Preprocessors)" + "\n"

        # only if resource compiler required, evaluate the resource variables
        if bldConf.IsResCompilerRequired():
            rcBuildOpts = bldConf.GetResCompileOptions()
            rcBuildOpts = rcBuildOpts.replace(';', ' ')
            text += "RcCmpOptions           :=" + rcBuildOpts + "\n"
            text += "RcCompilerName         :=" + cmp.GetTool("ResourceCompiler") + "\n"

        linkOpt = bldConf.GetLinkOptions()
        linkOpt = linkOpt.replace(';', ' ')
        text += 'LinkOptions            := ' + linkOpt + '\n'

        # add the global include path followed by the project include path
        text += "IncludePath            := " \
                + self.ParseIncludePath(cmp.GetGlobalIncludePath()) \
                + " " \
                + self.ParseIncludePath(bldConf.GetIncludePath()) + "\n"
        text += "RcIncludePath          :=" \
                + self.ParseIncludePath(bldConf.GetResCmpIncludePath()) + "\n"
        text += "Libs                   :=" \
                + self.ParseLibs(bldConf.GetLibraries()) + "\n"

        # add the global library path followed by the project library path
        text += "LibPath                :=" \
                + self.ParseLibPath(cmp.GetGlobalLibPath()) \
                + " " \
                + self.ParseLibPath(bldConf.GetLibPath()) \
                + "\n"
        text += "\n\n"

        return text
    
    def CreateMakeDirsTarget(self, bldConf, targetName):
        text = ''
        text += '\n'
        text += targetName + ':\n'
        text += '\t' + GetMakeDirCmd(bldConf) + '\n'
        #text += '\n'
        return text
    
    def CreateTargets(self, type, bldConf):
        text = ''

        # 不需要，直接在 MakeDirStep 目标里面解决
        #if Globals.IsWindowsOS():
            #text += '\t@-$(MakeDirCommand) "$(@D)"\n'
        #else:
            #text += '\t@$(MakeDirCommand) "$(@D)"\n'

        cmp = bldConf.GetCompiler()

        if type == Project.STATIC_LIBRARY:
            text += '\t' + '$(ArchiveTool) $(ArchiveOutputSwitch)$(OutputFile)'
            if cmp and cmp.GetReadObjectFilesFromList():
                text += ' @$(ObjectsFileList)\n'
            else:
                text += ' $(Objects)\n'
        elif type == Project.DYNAMIC_LIBRARY:
            text += '\t' + '$(SharedObjectLinkerName) $(OutputSwitch)$(OutputFile)'
            if cmp and cmp.GetReadObjectFilesFromList():
                text += ' @$(ObjectsFileList) '
            else:
                text += ' $(Objects) '
            text += '$(LibPath) $(Libs) $(LinkOptions)\n'
        elif type == Project.EXECUTABLE:
            text += '\t' + '$(LinkerName) $(OutputSwitch)$(OutputFile)'
            if cmp and cmp.GetReadObjectFilesFromList():
                text += ' @$(ObjectsFileList) '
            else:
                text += ' $(Objects) '
            text += '$(LibPath) $(Libs) $(LinkOptions)\n'
        return text

    def CreatePreBuildEvents(self, bldConf):
        text = ''

        # add PrePreBuild. 也即 Custom Makefile Rules，属于冗余，为了兼容，暂留
        prePreBuild = bldConf.GetPreBuildCustom().strip()
        if prePreBuild:
            text += 'PrePreBuild: ' + bldConf.GetPreBuildCustom() + '\n'

        cmds = bldConf.GetPreBuildCommands()    # BuildCommand 的列表
        text += '\n'
        text += 'PreBuild:\n'
        if cmds:
            firstEnter = True
            for i in cmds:
                if i.GetEnabled():
                    if firstEnter:
                        text += '\t@echo Executing Pre Build commands ...\n'
                        firstEnter = False
                    text += '\t' + i.GetCommand() + '\n'
            if not firstEnter:
                text += '\t@echo Done\n'
        #text += '\n'

        return text

    def CreatePostBuildEvents(self, bldConf):
        '''直接添加到输出文件目标的规则后面，不好，待改进
        2011-09-21: 修改为单独的目标
        '''
        text = ''

        cmds = bldConf.GetPostBuildCommands()
        text += '\n'
        text += 'PostBuild: $(OutputFile)\n'
        if cmds:
            firstEnter = True
            for i in cmds:
                if i.GetEnabled():
                    if firstEnter:
                        text += '\t@echo Executing Post Build commands ...\n'
                        firstEnter = False
                    text += '\t' + i.GetCommand() + '\n'
            if not firstEnter:
                text += '\t@echo Done\n'
        #text += '\n'

        return text
    
    def CreatePreCompiledHeaderTarget(self, bldConf):
        fileName = bldConf.GetPrecompiledHeader().strip()

        if not fileName:
            return ''

        text = ''
        text += '# PreCompiled Header\n'
        text += fileName + '.gch: ' + fileName + '\n'
        text += '\t' + self.DoGetCompilerMacro(fileName) + ' $(SourceSwitch) ' \
                + 'fileName' + ' $(CmpOptions) $(IncludePath)\n'
        text += '\n'
        return text
    
    def CreateCustomPreBuildEvents(self, bldConf):
        text = ''
        cmds = bldConf.GetPreBuildCommands()
        if cmds:
            firstEnter = True
            for i in cmds:
                if i.GetEnabled():
                    if firstEnter:
                        text += '\t@echo Executing Pre Build commands ...\n'
                        firstEnter = False
                    text += '\t' + i.GetCommand() + '\n'
            if not firstEnter:
                text += '\t@echo Done\n'
        return text
    
    def CreateCustomPostBuildEvents(self, bldConf):
        text = ''
        cmds = bldConf.GetPostBuildCommands()
        if cmds:
            firstEnter = True
            for i in cmds:
                if i.GetEnabled():
                    if firstEnter:
                        text += '\t@echo Executing Post Build commands ...\n'
                        firstEnter = False
                    text += '\t' + i.GetCommand() + '\n'
            if not firstEnter:
                text += '\t@echo Done\n'
        return text

    def GetCdCmd(self, path1, path2):
        '''path1 和 path2 为文件，非目录？！'''
        cmd = '@'
        if not os.path.dirname(path2):
            return cmd
        if os.path.dirname(path1) != os.path.dirname(path2):
            cmd += 'cd "' + os.path.dirname(path2) + '" && '
        return cmd
    
    def ParseIncludePath(self, paths):
        includePath = ''
        pathsList = paths.split(';')
        for i in pathsList:
            path = i.strip().replace('\\', '/')
            if not path:
                continue

            wrapper = ''
            if ' ' in path:
                wrapper = '"'

            includePath += '$(IncludeSwitch)' + wrapper + path + wrapper + ' '

        return includePath
    
    def ParseLibPath(self, paths):
        libPath = ''
        pathsList = paths.split(';')
        for i in pathsList:
            path = i.strip().replace('\\', '/')
            if not path:
                continue

            wrapper = ''
            if ' ' in path:
                wrapper = '"'

            libPath += '$(LibraryPathSwitch)' + wrapper + path + wrapper + ' '

        return libPath

    def ParseLibs(self, libs):
        slibs = ''
        libsList = libs.split(';')
        for i in libsList:
            lib = i.strip()
            # remove lib prefix
            if lib.startswith('lib'):
                lib = lib[3:]

            # remove known suffixes
            if lib.endswith('.a') or lib.endswith('.so') \
               or lib.endswith('.dylib') or lib.endswith('.dll'):
                lib = lib.rpartition('.')[0]

            if not lib:
                continue

            slibs += '$(LibrarySwitch)' + lib + ' '

        return slibs
    
    def ParsePreprocessor(self, prep):
        preprocessor = ''
        prepList = prep.split(';')
        for i in prepList:
            p = i.strip()
            if not p:
                continue
            preprocessor += '$(PreprocessorSwitch)' + p + ' '
        # if the macro contains # escape it
        # But first remove any manual escaping done by the user
        preprocessor = preprocessor.replace('\\#', '#')
        preprocessor = preprocessor.replace('#', '\\#')
        return preprocessor
    
    def HasPrebuildCommands(self, bldConf):
        cmds = bldConf.GetPreBuildCommands()
        firstEnter = True
        if cmds:
            for i in cmds:
                if i.GetEnabled:
                    if firstEnter:
                        firstEnter = False
                        break
        return not firstEnter
    
    def GetProjectMakeCommand(self, project, confToBuild, target, 
                              addCleanTarget, cleanOnly, 
                              commandLineBldTool = True):
        '''获取构建项目的命令。
        
        形如: "$(MAKE)" -f "LiteEditor.mk"'''
        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)

        makeCommand = ''
        basicMakeCommand = ''

        lMakeCommands = []

        builderCmd = self.GetBuilderCommand(commandLineBldTool)
        # 展开环境变量
        builderCmd = EnvVarSettingsST.Get().ExpandVariables(builderCmd)

        basicMakeCommand += builderCmd + ' "' + project.GetName() + '.mk"'

        if addCleanTarget:
            #makeCommand += basicMakeCommand + ' clean && '
            lMakeCommands.append('%s clean' % basicMakeCommand)

        if bldConf and not cleanOnly:
            # TODO: PrePreBuild is dirty
            prePreBuild = bldConf.GetPreBuildCustom().strip()
            preCmpHeader = bldConf.GetPrecompiledHeader().strip()

            if prePreBuild:
                #makeCommand += basicMakeCommand + ' PrePreBuild && '
                lMakeCommands.append('%s PrePreBuild' % basicMakeCommand)

            # NOTE: 不需要在工作区 Makefile 文件指定 PreBuild 目标
            #if self.HasPrebuildCommands(bldConf):
                #makeCommand += basicMakeCommand + ' PreBuild && '
                #lMakeCommands.append('%s PreBuild' % basicMakeCommand)

            if preCmpHeader:
                #makeCommand += basicMakeCommand + ' ' + preCmpHeader + '.gch' \
                        #+ ' && '
                lMakeCommands.append('%s %s.gch' % preCmpHeader)

        if not target or target == '\n':
            #makeCommand += basicMakeCommand + '\n'
            lMakeCommands.append('%s\n' % basicMakeCommand)
        else:
            #makeCommand += basicMakeCommand + ' ' + target
            lMakeCommands.append('%s %s' % (basicMakeCommand, target))

        makeCommand = ' && '.join(lMakeCommands)
        #print lMakeCommands

        return makeCommand
    
    def DoGetCompilerMacro(self, fileName):
        '''C 源文件用 '$(C_CompilerName)'，否则用 '$(CompilerName)' '''
        compilerMacro = '$(CompilerName)'
        if os.path.splitext(fileName)[1] == '.c':
            compilerMacro = '$(C_CompilerName)'
        return compilerMacro
    
    def DoGetTargetPrefix(self, fileName, cwd):
        '''为了防止放在不同目录下的同名源文件产生名字相同的目标，
        当前方法为把 (上层目录 + '_') 作为前缀添加。

        当 fileName 的目录与 cwd 不同时， 且当 fileName 包含目录层次时，
        把 fileName 文件的 (父目录 + '_') 作为前缀返回。'''
        lastDir = ''

        if os.path.dirname(fileName) == cwd:
            return ''

        lastDir = os.path.dirname(fileName)
        lastDir = os.path.basename(lastDir)
        if lastDir == '..':
            lastDir = 'up'
        elif lastDir == '.':
            lastDir = 'cur'

        if lastDir:
            lastDir += '_'

        return lastDir

