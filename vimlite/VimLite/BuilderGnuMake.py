#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import os
import os.path
import time
import Globals
import Macros

import Compiler

from Builder import Builder
from VLWorkspace import VLWorkspaceST
from BuildSettings import BuildSettingsST
from Project import Project

def GetMakeDirCmd(bldConf, relPath = ''):
    intermediateDirectory = bldConf.GetIntermediateDirectory()
    relativePath = relPath

    intermediateDirectory = intermediateDirectory.replace('\\', '/').strip()
    if intermediateDirectory.startswith('./') and relativePath == './':
        relativePath = ''

    if intermediateDirectory.startswith('./') and relativePath:
        intermediateDirectory = intermediateDirectory[2:]

    text = ''
    # TODO: 区分操作系统
    text += '@test -d ' + relativePath + intermediateDirectory \
            + ' || $(MakeDirCommand) ' + relativePath + intermediateDirectory

    return text


class BuilderGnuMake(Builder):
    '''GnuMake 的 Buidler'''
    def __init__(self, name = 'GNU makefile for g++/gcc', buildTool = 'make', 
                 buildToolOptions = '-f'):
        Builder.__init__(self, name, buildTool, buildToolOptions)
    
    def Export(self, projName, confToBuild, isProjectOnly = False, 
               force = False, errMsg = []):
        '''导出工作空间 makefile，如果没有指定 confToBuild，
        则导出工作空间当前选择的构建设置。
        
        绝大多数情况下，可不指定 confToBuild。'''
        if not projName:
            return False
        
        project = VLWorkspaceST.Get().FindProjectByName(projName)
        if not project:
            print '%s not found' % (projName,)
            return False
        
        bldConfName = confToBuild

        if not confToBuild:
            # 没有指定构建的配置，从 BuildMatrix 获取默认值
            bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, '')
            if not bldConf:
                print 'Cant find build configuration for project "%s"' \
                        % (projName,)
                return False
            bldConfName = bldConf.GetName()
        
        deps = project.GetDependencies(bldConfName)     # 获取依赖的项目名称列表
        removeList = []
        if not isProjectOnly:
            # 先检查依赖的项目是否都存在，现在的处理是简单地忽略
            # make sure that all dependencies exists
            for i in deps:
                dependProj = VLWorkspaceST.Get().FindProjectByName(i)
                if not dependProj:
                    # Missing dependencies project, just ignore
                    print 'Can not find project:', i
                    # TODO: 添加移除选择
        
        wspMakefile = VLWorkspaceST.Get().GetName() + '_wsp.mk'
        # 转为绝对路径
        wspMakefile = os.path.join(VLWorkspaceST.Get().dirName, wspMakefile)
        wspFile = VLWorkspaceST.Get().GetWorkspaceFileName()

        text = ''
        
        text += '.PHONY: clean All\n\n'
        text += 'All:\n'
        
        # iterate over the dependencies projects and generate makefile
        buildTool = self.GetBuildToolCommand(False)
        # TODO: 展开环境变量
        #buildTool = EnvironmentConfig::Instance().ExpandVariables(buildTool, True)
        
        #replace all Windows like slashes to POSIX
        buildTool = buildTool.replace('\\', '/')
        
        # generate the makefile for the selected workspace configuration
        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        wspSelConfName = matrix.GetSelectedConfigurationName()
        
        if not isProjectOnly:
            for i in deps:
                isCustom = False
                dependProj = VLWorkspaceST.Get().FindProjectByName(i)
                if not dependProj:
                    continue
                
                dependProjSelConfName = matrix.GetProjectSelectedConf(
                    wspSelConfName, dependProj.GetName())
                dependProjBldConf = VLWorkspaceST.Get().GetProjBuildConf(
                    dependProj.GetName(), dependProjSelConfName)
                
                if dependProjBldConf and dependProjBldConf.IsCustomBuild():
                    isCustom = True

                # incase we manually specified the configuration to be built, 
                # set the project as modified, so on next attempt to build it, 
                # CodeLite will sync the configuration
                # 手动指定构建配置名称，强制重建 makefile，但是这种情况很少出现
                if confToBuild:
                    dependProj.SetModified(True)

                # 构建前缀显示
                text += '\t@echo ' + Macros.BUILD_PROJECT_PREFIX \
                        + dependProj.GetName() + ' - ' + dependProjSelConfName \
                        + ' ]----------\n'

                relProjFile = os.path.relpath(dependProj.GetFileName(), 
                                              os.path.dirname(wspFile))

                if isCustom:
                    text += self.CreateCustomPreBuildEvents(dependProjBldConf)

                    customWd = dependProjBldConf.GetCustomBuildWorkingDir()
                    buildCmd = dependProjBldConf.GetCustomBuildCmd()
                    customWdCmd = ''

                    # 为 customWd 和 buildCmd 展开所有变量
                    customWd = Globals.ExpandAllVariables(
                        customWd, VLWorkspaceST.Get(), dependProj.GetName(), 
                        dependProjBldConf.GetName(), '')
                    buildCmd = Globals.ExpandAllVariables(
                        buildCmd, VLWorkspaceST.Get(), dependProj.GetName(), 
                        dependProjBldConf.GetName(), '')

                    buildCmd = buildCmd.strip()

                    if not buildCmd:
                        buildCmd += '@echo Project has no custom build command!'

                    # 如果提供自定义命令的工作目录，用之，否则使用项目默认的
                    customWd = customWd.strip()
                    if customWd:
                        customWdCmd += '@cd "' + Globals.ExpandAllVariables(
                            customWd, VLWorkspaceST.Get(), 
                            dependProj.GetName(), '', '') + '" && '
                    else:
                        customWdCmd += self.GetCdCmd(wspFile, relProjFile)

                    text += '\t' + customWdCmd + buildCmd + '\n'
                    text += self.CreateCustomPostBuildEvents(dependProjBldConf)
                else:
                    # generate the dependency project makefile
                    self.GenerateMakefile(dependProj, dependProjSelConfName, \
                                          confToBuild and True or force)
                    text += '\t' + self.GetCdCmd(wspFile, relProjFile)
                    text += self.GetProjectMakeCommand(dependProj, confToBuild,\
                                                       '\n', False, False, False)

        # Generate makefile for the project itself
        self.GenerateMakefile(project, confToBuild, 
                              confToBuild and True or force)

        # incase we manually specified the configuration to be built, 
        # set the project as modified, so on next attempt to build it, 
        # CodeLite will sync the configuration
        if confToBuild:
            project.SetModified(True)

        projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                        projName)
        if isProjectOnly and confToBuild:
            # incase we use to generate a 'Project Only' makefile,
            # we allow the caller to override the selected configuration 
            # with 'confToBuild' parameter
            projSelConfName = confToBuild

        text += '\t@echo ' + Macros.BUILD_PROJECT_PREFIX + projName + ' - ' \
                + projSelConfName + ' ]----------\n'

        relProjFile = os.path.relpath(project.GetFileName(), 
                                      os.path.dirname(wspFile))
        text += '\t' + self.GetCdCmd(wspFile, relProjFile)
        text += self.GetProjectMakeCommand(project, projSelConfName, '\n',
                                          False, False, False)

        # create the clean target
        text += 'clean:\n'
        if not isProjectOnly:
            for i in deps:
                isCustom = False
                dependProjSelConfName = matrix.GetProjectSelectedConf(
                    wspSelConfName, i)
                dependProj = VLWorkspaceST.Get().FindProjectByName(i)
                if not dependProj:
                    continue

                text += '\t@echo ' + Macros.CLEAN_PROJECT_PREFIX \
                        + dependProj.GetName() + ' - ' + dependProjSelConfName \
                        + ' ]----------\n'

                relProjFile = os.path.relpath(dependProj.GetFileName(), 
                                              os.path.dirname(wspFile))

                dependProjBldConf = VLWorkspaceST.Get().GetProjBuildConf(
                    dependProj.GetName(), dependProjSelConfName)
                if dependProjBldConf and dependProjBldConf.IsCustomBuild():
                    isCustom = True

                if not isCustom:
                    text += '\t' + self.GetCdCmd(wspFile, relProjFile) \
                            + buildTool + ' "' + dependProj.GetName() \
                            + '.mk" clean\n'
                else:
                    customWd = dependProjBldConf.GetCustomBuildWorkingDir()
                    cleanCmd = dependProjBldConf.GetCustomCleanCmd()

                    # 为 customWd 和 buildCmd 展开所有变量
                    customWd = Globals.ExpandAllVariables(
                        customWd, VLWorkspaceST.Get(), dependProj.GetName(), 
                        dependProjBldConf.GetName(), '')
                    buildCmd = Globals.ExpandAllVariables(
                        buildCmd, VLWorkspaceST.Get(), dependProj.GetName(), 
                        dependProjBldConf.GetName(), '')

                    customWdCmd = ''

                    cleanCmd = cleanCmd.strip()
                    if not cleanCmd:
                        cleanCmd += '@echo Project has no custom clean command!'

                    customWd = customWd.strip()
                    if customWd:
                        customWdCmd += '@cd "' + Globals.ExpandAllVariables(
                            customWd, VLWorkspaceST.Get(), 
                            dependProj.GetName(), '', '') + '" && '
                    else:
                        customWdCmd += self.GetCdCmd(wspFile, relProjFile)
                    text += '\t' + customWdCmd + cleanCmd + '\n'

        projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, projName)
        if isProjectOnly and confToBuild:
            # incase we use to generate a 'Project Only' makefile,
            # we allow the caller to override the selected configuration with 
            # 'confToBuild' parameter
            projSelConfName = confToBuild

        relProjFile = os.path.relpath(project.GetFileName(), 
                                      os.path.dirname(wspFile))
        text += '\t@echo ' + Macros.CLEAN_PROJECT_PREFIX + projName + ' - ' \
                + projSelConfName + ' ]----------\n'
        text += '\t' + self.GetCdCmd(wspFile, relProjFile) + buildTool \
                + ' "' + project.GetName() + '.mk" clean\n'

        # dump the content to file
        try:
            f = open(wspMakefile, 'wb')
            f.write(text)
            f.close()
        except IOError:
            print wspMakefile, 'open failed!'
            raise IOError

        return text

    def GetBuildCommand(self, projName, confToBuild):
        cmd = ''
        bldConf = VLWorkspaceST.Get().GetProjBuildConf(projName, confToBuild)
        if not bldConf:
            print projName, 'have not any build config'
            return ''

        self.Export(projName, confToBuild, False, False)

        matrix = VLWorkspaceST.Get().GetBuildMatrix()
        buildTool = self.GetBuildToolCommand(True)
        # TODO: 展开环境变量
        #buildTool = 

        # Fix: replace all Windows like slashes to POSIX
        buildTool = buildTool.replace('\\', '/')

        type = self.NormalizeConfigName(matrix.GetSelectedConfigurationName())
        cmd += buildTool + ' "' + VLWorkspaceST.Get().GetName() + '_wsp.mk"'

        return cmd
    
    def GetCleanCommand(self, projName, confToBuild):
        return self.GetBuildCommand(projName, confToBuild) + ' clean'
    
    def GetSingleFileCmd(self, projName, confToBuild, fileName):
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

        # TODO: 展开环境变量 target

        cmd = self.GetProjectMakeCommand(project, confToBuild, target, False, 
                                        False)
        # TODO: 展开环境变量 cmd

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
        buildTool = self.GetBuildToolCommand(True)

        # Fix: replace all Windows like slashes to POSIX
        buildTool = buildTool.replace('\\', '/')

        # create the target
        target = ''
        fn = fileName

        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)
        
        objNamePrefix = self.DoGetTargetPrefix(fn, project.dirName)
        target += bldConf.GetIntermediateDirectory() + '/' + objNamePrefix \
                + os.path.splitext(os.path.basename(fn))[0] \
                + cmp.GetPreprocessSuffix()
        # TODO: 展开环境变量 target

        cmd = self.GetProjectMakeCommand(project, confToBuild, target, False, 
                                        False)
        # TODO: 展开环境变量 cmd

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
        files = project.GetAllFiles()
        text = ''
        text += 'Srcs='

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        relPath = ''

        return text
    
    def CreateObjectList(self, project, confToBuild):
        files = project.GetAllFiles(True)   # 绝对路径
        text = ''
        text += 'Objects='

        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)
        cmpType = bldConf.GetCompilerType()
        cmp = BuildSettingsST.Get().GetCompiler(cmpType)

        cwd = os.getcwd()

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

            if ft.kind == Compiler.CmpFileKindResource:
                text += '$(IntermediateDirectory)/' + objPrefix \
                        + os.path.dirname(i) \
                        + '$(ObjectSuffix) '
            else:
                # 源文件
                text += '$(IntermediateDirectory)/' + objPrefix \
                        + os.path.splitext(os.path.basename(i))[0] \
                        + '$(ObjectSuffix) '

            text += '\\\n\t'

        if text.endswith('\\\n\t'):
            text = text.rstrip('\\\n\t')
        text += '\n\n'

        return text
    
    def CreateLinkTargets(self, type, bldConf):
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
            text += '$(OutputFile)\n\n'

            text += '$(OutputFile): makeDirStep $(Objects)\n'
        else:
            text += 'all: $(IntermediateDirectory) '
            if readObjectsFromFile:
                text += 'objects_file '
            text += '$(OutputFile)\n\n'
            text += '$(OutputFile): $(Objects)\n'

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

        absFiles = project.GetAllFiles(True)
        relFiles = project.GetAllFiles(False)

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

                # use UNIX style slashes
                absFile = absFile.replace('\\', '/')
                relFile = relFiles[index].replace('\\', '/')

                objPrefix = self.DoGetTargetPrefix(absFile, cwd)

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

        absFiles = project.GetAllFiles(True)
        relFiles = project.GetAllFiles(False)

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

        # Remove the pre-compiled header
        pchFile = bldConf.GetPrecompiledHeader().strip()

        if pchFile:
            text += '\t' + '$(RM) ' + pchFile + '.gch' + '\n'


        text += '\n\n'

        return text
    
    # Override default methods defined in the builder interface
    def GetBuildToolCommand(self, isCommandlineCommand):
        '''isCommandlineCommand 表示是否开多线程构建？'''
        # TODO: 区分操作系统
        if isCommandlineCommand:
            jobs = Builder.GetBuildToolJobs(self)
            if jobs == 'unlimited':
                jobsCmd = '-j '
            else:
                jobsCmd = '-j ' + jobs + ' '

            buildTool = self.GetBuildToolName()
        else:
            jobsCmd = ''
            buildTool = '$(MAKE)'

        return '"' + buildTool + '" ' + jobsCmd + self.GetBuildToolOptions()

    # private methods?
    def GenerateMakefile(self, project, confToBuild, force):
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

        # 如果已存在 makefile，且非强制，且项目没有修改，跳过
        if os.path.exists(makefile):
            if not force:
                # 添加判断，比较项目文件与 makefile 的时间戳，
                # 只有 makefile 比项目文件新才跳过
                if not project.IsModified() \
                   and Globals.GetFileModificationTime(makefile) \
                   > Globals.GetFileModificationTime(project.GetFileName()):
                    return

        # generate the selected configuration for this project
        text = ''

        text += '##\n'
        text += '## Auto Generated makefile by VimLite\n'
        text += '## Do not edit this file, any manual changes will be erased\n'
        text += '##\n'

        # Create the makefile variables
        text += self.CreateConfigsVariables(project, bldConf)

        # TODO: copy environment variables to the makefile. 暂不需要
        #text += '##\n'
        #text += '## User defined environment variableîs\n'
        #text ++ '##\n'
        # TODO: 输出环境变量。暂不需要

        text += self.CreateListMacros(project, confToBuild)

        # create the build targets
        text += '##\n'
        text += '## Main Build Targets\n'
        text += '##\n'

        # incase project is type exe or dll, force link
        # this is to workaround bug in the generated makefiles
        # which causes the makefile to report 'nothing to be done'
        # even when a dependency was modified
        targetName = bldConf.GetIntermediateDirectory()
        projType = settings.GetProjectType(bldConf.GetName())
        if projType == Project.EXECUTABLE or projType == Project.DYNAMIC_LIBRARY:
            targetName = 'makeDirStep'
        text += self.CreateLinkTargets(projType, bldConf)

        # TODO: 添加 PostBuild 命令，现在的方法是直接添加到目标规则的后面，待改进
        text += self.CreatePostBuildEvents(bldConf)

        # In any case add the 'objects_file' target here
        # this is a special target that creates a file with the content of the 
        # $(Objects) variable (to be used with the @<file-name> option of the LD)
        #text += '\n'
        #text += 'objects_file:\n'
        #text += '\t@echo $(Objects) > $(ObjectsFileList)\n'

        text += self.CreateMakeDirsTarget(bldConf, targetName)
        # 添加 PreBuild 目标
        text += self.CreatePreBuildEvents(bldConf)
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
        name = bldConf.GetName()
        name = self.NormalizeConfigName(name)

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
        text += "WorkspacePath          := \"" + VLWorkspaceST.Get().dirName + "\"\n"
        text += "ProjectPath            := \"" + project.dirName + "\"\n"
        text += "CurrentFileName        :=\n" # TODO: Need implementation
        text += "CurrentFilePath        :=\n" # TODO: Need implementation
        text += "CurrentFileFullPath    :=\n" # TODO: Need implementation
        text += "User                   :=" + os.environ['USER'] + "\n"
        text += "Date                   :=" + time.strftime('%Y-%m-%d', time.localtime()) + "\n"
        text += "CodeLitePath           :=\"" + os.environ['HOME'] + '/.codelite' + "\"\n"
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
        text += "OutputFile             :=" + bldConf.GetOutputFileName() + "\n"
        text += "Preprocessors          :=" + self.ParsePreprocessor(bldConf.GetPreprocessor()) + "\n"
        text += "ObjectSwitch           :=" + cmp.GetSwitch("Object") + "\n"
        text += "ArchiveOutputSwitch    :=" + cmp.GetSwitch("ArchiveOutput") + "\n"
        text += "PreprocessOnlySwitch   :=" + cmp.GetSwitch("PreprocessOnly") + "\n"
        text += "ObjectsFileList        :=\"" + objectsFileName + "\"\n"

        # TODO: 区分操作系统
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
        return text
    
    def CreateTargets(self, type, bldConf):
        text = ''
        text += '\t@$(MakeDirCommand) $(@D)\n'
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
        #name = bldConf.GetName()
        #name = self.NormalizeConfigName(name)

        text = ''

        # add PrePreBuild. 也即 Custom Makefile Rules，属于冗余，为了兼容，暂留
        prePreBuild = bldConf.GetPreBuildCustom().strip()
        if prePreBuild:
            text += 'PrePreBuild: ' + bldConf.GetPreBuildCustom() + '\n'

        cmds = bldConf.GetPreBuildCommands()    # BuildCommand 的列表
        if cmds:
            text += '\n'
            firstEnter = True
            text += 'PreBuild:\n'
            for i in cmds:
                if i.GetEnabled():
                    if firstEnter:
                        text += '\t@echo Executing Pre Build commands ...\n'
                        firstEnter = False
                    text += '\t' + i.GetCommand() + '\n'
            if not firstEnter:
                text += '\t@echo Done\n'

        return text

    def CreatePostBuildEvents(self, bldConf):
        '''直接添加到输出文件目标的规则后面，不好，待改进'''
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
    
    def CreateCustomPostBuildEvents(self, bldConf, text):
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
    
    # 2
    def GetProjectMakeCommand(self, project, confToBuild, target, 
                              addCleanTarget, cleanOnly, 
                              commandLineBldTool = True):
        '''获取构建项目的命令。
        
        形如："$(MAKE)" -f "LiteEditor.mk" PrePreBuild \
                && "$(MAKE)" -f "LiteEditor.mk" PreBuild \
                && "$(MAKE)" -f "LiteEditor.mk"'''
        bldConf = VLWorkspaceST.Get().GetProjBuildConf(project.GetName(), 
                                                       confToBuild)

        makeCommand = ''
        basicMakeCommand = ''

        buildTool = self.GetBuildToolCommand(commandLineBldTool)
        # TODO: 展开环境变量

        basicMakeCommand += buildTool + ' "' + project.GetName() + '.mk"'

        if addCleanTarget:
            makeCommand += basicMakeCommand + ' clean && '

        if bldConf and not cleanOnly:
            prePreBuild = bldConf.GetPreBuildCustom().strip()
            preCmpHeader = bldConf.GetPrecompiledHeader().strip()

            if prePreBuild:
                makeCommand += basicMakeCommand + ' PrePreBuild && '

            if self.HasPrebuildCommands(bldConf):
                makeCommand += basicMakeCommand + ' PreBuild && '

            if preCmpHeader:
                makeCommand += basicMakeCommand + ' ' + preCmpHeader + '.gch' \
                        + ' && '
        if not target or target == '\n':
            makeCommand += basicMakeCommand + '\n'
        else:
            makeCommand += basicMakeCommand + ' ' + target
        return makeCommand
    
    def DoGetCompilerMacro(self, fileName):
        '''源文件为 c 源文件用 '$(C_CompilerName)'，否则用 '$(CompilerName)' '''
        compilerMacro = '$(CompilerName)'
        if os.path.splitext(fileName)[1] == '.c':
            compilerMacro = '$(C_CompilerName)'
        return compilerMacro
    
    def DoGetTargetPrefix(self, fileName, cwd):
        '''为了防止放在不同目录下的同名源文件产生名字相同的目标，
        当前方法为把 (上层目录 + '_') 作为前缀添加。

        当 fileName 的目录与 cwd 不同时， 且当 fileName 包含目录层次时，
        把 fileName 文件的 (上层目录 + '_') 作为前缀返回。'''
        lastDir = ''

        if os.path.dirname(fileName) == cwd:
            return ''

        if os.sep in fileName:
            lastDir = os.path.dirname(fileName).rpartition(os.sep)[2]

            if lastDir == '..':
                lastDir = 'up'
            elif lastDir == '.':
                lastDir = 'cur'

            if lastDir:
                lastDir += '_'
        return lastDir

