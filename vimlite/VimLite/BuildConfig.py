#!/usr/bin/env python
# -*- encoding:utf-8 -*-

''' .project 文件中的 <CodeLite> | <Settings> | <Configuration>
'''

from xml.dom import minidom
import Globals
import XmlUtils
import Macros
import BuildSettings
#from Project import Project
import Project

class BuildCommand:
    '''构建命令
    
    command: 命令
    enable: 是否启用'''

    def __init__(self, command = '', enabled = False):
        self.command = command
        self.enabled = enabled

    def GetCommand(self):
        return self.command
    
    def GetEnabled(self):
        return self.enabled
    
    def SetCommand(self, command):
        self.command = command
    
    def SetEnabled(self, enabled):
        self.enabled = enabled



class BuildConfigCommon:
    '''通用构建配置'''

    def __init__(self, xmlNode = None, confType = 'Configuration'):
        '''多数变量为分号分割的字符串'''
        self.includePath = ''   # 分号分割的字符串
        self.compileOptions = ''
        self.linkOptions = ''
        self.libs = ''  # 分号分割的字符串
        self.libPath = ''   # 分号分割的字符
        self.preprocessor = ''   # 分号分割的字符
        self.resCompileOptions = ''
        self.resCompileIncludePath = ''
        self.cCompileOptions = ''
        self.confType = confType  # xml node name
        
        if xmlNode:
            # 读取编辑器设置
            compilerNode = XmlUtils.FindFirstByTagName(xmlNode, 'Compiler')
            if compilerNode:
                self.compileOptions = XmlUtils.ReadString(compilerNode, 'Options')
                self.cCompileOptions = compilerNode.getAttribute('C_Options')
                if not self.cCompileOptions:
                    self.cCompileOptions = self.compileOptions
                
                for i in compilerNode.childNodes:
                    if i.nodeName == 'IncludePath':
                        self.includePath += ';%s' % (XmlUtils.ReadString(i, 'Value'),)
                    elif i.nodeName == 'Preprocessor':
                        self.preprocessor += ';%s' % (XmlUtils.ReadString(i, 'Value'),)
                    
            # 读取链接器设置
            linkerNode = XmlUtils.FindFirstByTagName(xmlNode, 'Linker')
            if linkerNode:
                self.linkOptions = XmlUtils.ReadString(linkerNode, 'Options')
                for i in linkerNode.childNodes:
                    if i.nodeName == 'Library':
                        self.libs += ';%s' % (XmlUtils.ReadString(i, 'Value'),)
                    elif i.nodeName == 'LibraryPath':
                        self.libPath += ';%s' % (XmlUtils.ReadString(i, 'Value'),)
            
            # 读取资源编译器设置
            resCmpNode = XmlUtils.FindFirstByTagName(xmlNode, 'ResourceCompiler')
            if resCmpNode:
                self.resCompileOptions = XmlUtils.ReadString(resCmpNode, 'Options')
                for i in resCmpNode.childNodes:
                    if i.nodeName == 'IncludePath':
                        self.resCompileIncludePath += XmlUtils.ReadString(i, 'Value') + ';'
        else:
            self.includePath += '.;'
            self.libPath += '.;'
    
    def ToXmlNode(self):
        doc = minidom.Document()
        newNode = doc.createElement(self.confType)

        # 编译器节点
        compileNode = doc.createElement('Compiler')
        compileNode.setAttribute('Options', self.compileOptions)
        compileNode.setAttribute('C_Options', self.cCompileOptions)
        newNode.appendChild(compileNode)
        
        includePathList = self.includePath.split(';')
        for i in includePathList:
            if i:
                optionNode = doc.createElement('IncludePath')
                optionNode.setAttribute('Value', i)
                compileNode.appendChild(optionNode)
        
        preprocessorList = self.preprocessor.split(';')
        for i in preprocessorList:
            if i:
                prepNode = doc.createElement('Preprocessor')
                prepNode.setAttribute('Value', i)
                compileNode.appendChild(prepNode)
        
        
        # 链接器节点
        linkNode = doc.createElement('Linker')
        linkNode.setAttribute('Options', self.linkOptions)
        newNode.appendChild(linkNode)
        
        libPathList = self.libPath.split(';')
        for i in libPathList:
            if i:
                optionNode = doc.createElement('LibraryPath')
                optionNode.setAttribute('Value', i)
                linkNode.appendChild(optionNode)
        
        libsList = self.libs.split(';')
        for i in libsList:
            if i:
                optionNode = doc.createElement('Library')
                optionNode.setAttribute('Value', i)
                linkNode.appendChild(optionNode)
        
        # 资源编译器节点
        resCmpNode = doc.createElement('ResourceCompiler')
        resCmpNode.setAttribute('Options', self.resCompileOptions)
        newNode.appendChild(resCmpNode)
        
        resCompileIncludePathList = self.resCompileIncludePath.split(';')
        for i in resCompileIncludePathList:
            if i:
                optionNode = doc.createElement('IncludePath')
                optionNode.setAttribute('Value', i)
                resCmpNode.appendChild(optionNode)
        
        return newNode
    
    def GetPreprocessor(self):
        return self.preprocessor
    
    def SetPreprocessor(self, prepr):
        if type(prepr) == type([]):
            self.preprocessor = ';'.join(prepr)
        else:
            self.preprocessor = prepr
    
    def GetCompileOptions(self):
        return self.compileOptions
    
    def SetCompileOptions(self, options):
        self.compileOptions = options
    
    def GetCCompileOptions(self):
        return self.cCompileOptions
    
    def SetCCompileOptions(self, options):
        self.cCompileOptions = options
    
    def GetLinkOptions(self):
        return self.linkOptions
    
    def SetLinkOptions(self, options):
        self.linkOptions = options
    
    def GetIncludePath(self):
        return self.includePath
    
    def SetIncludePath(self, paths):
        if type(paths) == type([]):
            self.includePath = ';'.join(paths)
        else:
            self.includePath = paths
    
    def GetLibraries(self):
        return self.libs
    
    def SetLibraries(self, libs):
        if type(libs) == type([]):
            self.libs = ';'.join(libs)
        else:
            self.libs = libs
    
    def GetLibPath(self):
        return self.libPath
    
    def SetLibPath(self, paths):
        if type(paths) == type([]):
            self.libPath == ';'.join(paths)
        else:
            self.libPath = paths
    
    def GetResCompileIncludePath(self):
        return self.resCompileIncludePath

    def GetResCmpIncludePath(self):
        return self.resCompileIncludePath

    def SetResCompileIncludePath(self, paths):
        if type(paths) == type([]):
            self.resCompileIncludePath = ';'.join(paths)
        else:
            self.resCompileIncludePath = paths

    def SetResCmpIncludePath(self, paths):
        if type(paths) == type([]):
            self.resCompileIncludePath = ';'.join(paths)
        else:
            self.resCompileIncludePath = paths

    def GetResCompileOptions(self):
        return self.resCompileOptions
    
    def GetResCmpOptions(self):
        return self.resCompileOptions

    def SetResCompileOptions(self, options):
        self.resCompileOptions = options
    
    def SetResCmpOptions(self, options):
        self.resCompileOptions = options


class BuildConfig:
    '''构建配置'''
    OVERWRITE_GLOBAL_SETTINGS = 'overwrite'
    APPEND_TO_GLOBAL_SETTINGS = 'append'
    PREPEND_GLOBAL_SETTINGS = 'prepend'
    
    def __init__(self, xmlNode = None):
        '''麻烦，直接访问变量修改'''
        self.commonConfig = BuildConfigCommon(xmlNode)
        self.name = ''
        self.preBuildCommands = []
        self.postBuildCommands = []
        self.compilerRequired = True
        self.linkerRequired = True
        self.enableCustomBuild = False
        self.outputFile = ''
        self.intermediateDirectory = ''
        self.command = ''
        self.commandArguments = ''
        self.workingDirectory = ''
        self.compilerType = ''
        # 虽然写着是 project type，但是每个构建设置都有自己独立的类型
        self.projectType = ''       
        self.customBuildCmd = ''
        self.customCleanCmd = ''
        self.customRebuildCmd = ''
        self.isResCmpNeeded = False
        self.debuggerType = ''
        self.customPostBuildRule = ''
        self.customPreBuildRule = ''
        self.customBuildWorkingDir = ''
        self.pauseWhenExecEnds = True
        self.toolName = ''
        self.makeGenerationCommand = ''
        self.singleFileBuildCommand = ''
        self.preprocessFileCommand = ''
        self.debuggerStartupCmds = ''
        self.debuggerPostRemoteConnectCmds = ''
        self.isDbgRemoteTarget = False
        self.dbgHostName = ''
        self.dbgHostPort = ''
        self.customTargets = {}
        self.debuggerPath = ''
        self.buildCmpWithGlobalSettings = ''
        self.buildLnkWithGlobalSettings = ''
        self.buildResWithGlobalSettings = ''
        self.precompiledHeader = ''
        self.envVarSet = ''
        self.dbgEnvSet = ''
        self.useSeparateDebugArgs = False
        self.debugArgs = ''

        if xmlNode:
            self.name = XmlUtils.ReadString(xmlNode, 'Name')
            self.compilerType = XmlUtils.ReadString(xmlNode, 'CompilerType')
            self.debuggerType = XmlUtils.ReadString(xmlNode, 'DebuggerType')
            self.projectType = XmlUtils.ReadString(xmlNode, 'Type')
            self.buildCmpWithGlobalSettings = XmlUtils.ReadString(xmlNode, 'BuildCmpWithGlobalSettings', BuildConfig.APPEND_TO_GLOBAL_SETTINGS)
            self.buildLnkWithGlobalSettings = XmlUtils.ReadString(xmlNode, 'BuildLnkWithGlobalSettings', BuildConfig.APPEND_TO_GLOBAL_SETTINGS)
            self.buildResWithGlobalSettings = XmlUtils.ReadString(xmlNode, 'BuildResWithGlobalSettings', BuildConfig.APPEND_TO_GLOBAL_SETTINGS)
            
            compileNode = XmlUtils.FindFirstByTagName(xmlNode, 'Compiler')
            if compileNode:
                self.compilerRequired = XmlUtils.ReadBool(compileNode, 'Required', True)
                self.precompiledHeader = XmlUtils.ReadString(compileNode, 'PreCompiledHeader')
            
            linkerNode = XmlUtils.FindFirstByTagName(xmlNode, 'Linker')
            if linkerNode:
                self.linkerRequired = XmlUtils.ReadBool(linkerNode, 'Required', True)
            
            resCmpNode = XmlUtils.FindFirstByTagName(xmlNode, 'ResourceCompiler')
            if resCmpNode:
                self.isResCmpNeeded = XmlUtils.ReadBool(resCmpNode, 'Required', True)
            
            debuggerNode = XmlUtils.FindFirstByTagName(xmlNode, 'Debugger')
            self.isDbgRemoteTarget = False
            
            if debuggerNode:
                self.isDbgRemoteTarget = XmlUtils.ReadBool(debuggerNode, 'IsRemote')
                self.dbgHostName = XmlUtils.ReadString(debuggerNode, 'RemoteHostName')
                self.dbgHostPort = XmlUtils.ReadString(debuggerNode, 'RemoteHostPort')
                self.debuggerPath = XmlUtils.ReadString(debuggerNode, 'DebuggerPath')
                
                for i in debuggerNode.childNodes:
                    if i.nodeName == 'StartupCommands':
                        self.debuggerStartupCmds = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'PostConnectCommands':
                        self.debuggerPostRemoteConnectCmds = XmlUtils.GetNodeContent(i)
            
            # read the prebuild commands
            preBuildNode = XmlUtils.FindFirstByTagName(xmlNode, 'PreBuild')
            if preBuildNode:
                for i in preBuildNode.childNodes:
                    if i.nodeName == 'Command':
                        enabled = XmlUtils.ReadBool(i, 'Enabled')
                        cmd = BuildCommand(XmlUtils.GetNodeContent(i), enabled)
                        self.preBuildCommands.append(cmd)
            
            # read the postbuild commands
            postBuildNode = XmlUtils.FindFirstByTagName(xmlNode, 'PostBuild')
            if postBuildNode:
                for i in postBuildNode.childNodes:
                    if i.nodeName == 'Command':
                        enabled = XmlUtils.ReadBool(i, 'Enabled')
                        cmd = BuildCommand(XmlUtils.GetNodeContent(i), enabled)
                        self.postBuildCommands.append(cmd)
            
            self.envVarSet = Macros.USE_WORKSPACE_ENV_VAR_SET
            self.dbgEnvSet = Macros.USE_GLOBAL_SETTINGS
            
            # read the environment page
            envNode = XmlUtils.FindFirstByTagName(xmlNode, 'Environment')
            if envNode:
                self.envVarSet = XmlUtils.ReadString(envNode, 'EnvVarSetName')
                self.dbgEnvSet = XmlUtils.ReadString(envNode, 'DbgSetName')
            
            customBuildNode = XmlUtils.FindFirstByTagName(xmlNode, 'CustomBuild')
            if customBuildNode:
                self.enableCustomBuild = XmlUtils.ReadBool(customBuildNode, 'Enabled', False)
                for i in customBuildNode.childNodes:
                    if i.nodeName == 'BuildCommand':
                        self.customBuildCmd = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'CleanCommand':
                        self.customCleanCmd = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'RebuildCommand':
                        self.customRebuildCmd = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'SingleFileCommand':
                        self.singleFileBuildCommand = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'PreprocessFileCommand':
                        self.preprocessFileCommand = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'WorkingDirectory':
                        self.customBuildWorkingDir = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'ThirdPartyToolName':
                        self.toolName = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'MakefileGenerationCommand':
                        self.makeGenerationCommand = XmlUtils.GetNodeContent(i)
                    elif i.nodeName == 'Target':
                        tgtName = i.getAttribute('Name')
                        tgtCmd = XmlUtils.GetNodeContent(i)
                        if tgtName:
                            self.customTargets[tgtName] = tgtCmd
            else:
                self.enableCustomBuild = False
            
            # read pre and post build rules
            customPreBuildNode = XmlUtils.FindFirstByTagName(xmlNode, 'AdditionalRules')
            if customPreBuildNode:
                for i in customPreBuildNode.childNodes:
                    if i.nodeName == 'CustomPreBuild':
                        self.customPreBuildRule = XmlUtils.GetNodeContent(i)
                        self.customPreBuildRule = self.customPreBuildRule.strip()
                    elif i.nodeName == 'CustomPostBuild':
                        self.customPostBuildRule = XmlUtils.GetNodeContent(i)
                        self.customPostBuildRule = self.customPostBuildRule.strip()
            
            generalNode = XmlUtils.FindFirstByTagName(xmlNode, 'General')
            if generalNode:
                self.outputFile = XmlUtils.ReadString(generalNode, 'OutputFile')
                self.intermediateDirectory = XmlUtils.ReadString(generalNode, 'IntermediateDirectory', '.')
                self.command = XmlUtils.ReadString(generalNode, 'Command')
                self.commandArguments = XmlUtils.ReadString(generalNode, 'CommandArguments')
                self.workingDirectory = XmlUtils.ReadString(generalNode, 'WorkingDirectory')
                self.pauseWhenExecEnds = XmlUtils.ReadBool(generalNode, 'PauseExecWhenProcTerminates', True)
                self.useSeparateDebugArgs = XmlUtils.ReadBool(generalNode, 'UseSeparateDebugArgs', False)
                self.debugArgs = XmlUtils.ReadString(generalNode, 'DebugArguments')
            
        else:
            # create default project settings
            self.commonConfig.SetCCompileOptions('-g;-Wall')
            self.commonConfig.SetCompileOptions('-g;-Wall')
            self.commonConfig.SetLinkOptions('-O0')
            self.commonConfig.SetLibPath('.;Debug')
            
            self.name = 'Debug'
            self.compilerRequired = True
            self.linkerRequired = True
            self.intermediateDirectory = './Debug'
            self.workingDirectory = './Debug'
            self.projectType = Project.Project.EXECUTABLE
            self.enableCustomBuild = False
            self.customBuildCmd = ''
            self.customCleanCmd = ''
            self.isResCmpNeeded = False
            self.customPreBuildRule = ''
            self.customPostBuildRule = ''
            self.makeGenerationCommand = ''
            self.toolName = ''
            self.singleFileBuildCommand = ''
            self.preprocessFileCommand = ''
            self.debuggerStartupCmds = ''
            self.debuggerPostRemoteConnectCmds = ''
            self.isDbgRemoteTarget = False
            self.debugArgs = ''
            
            self.envVarSet = '<Use Workspace Settings>'
            self.dbgEnvSet = '<Use Global Settings>'

            # 获取第一个编译器设置作为默认，故若想修改默认编译器，修改默认配置文件
            compiler = BuildSettings.BuildSettingsST.Get()\
                    .GetFirstCompiler()
            if compiler:
                self.compilerType = compiler.name
            
            # TODO: DebuggerMgr 暂不支持
            self.debuggerType = 'GNU gdb debugger'

            self.buildCmpWithGlobalSettings = BuildConfig.APPEND_TO_GLOBAL_SETTINGS
            self.buildLnkWithGlobalSettings = BuildConfig.APPEND_TO_GLOBAL_SETTINGS
            self.buildResWithGlobalSettings = BuildConfig.APPEND_TO_GLOBAL_SETTINGS

    def Clone(self):
        node = self.ToXmlNode()
        cloned = BuildConfig(node)
        return cloned

    def ToXmlNode(self):
        # Create the common nodes
        node = self.commonConfig.ToXmlNode()
        
        node.setAttribute('Name', self.name)
        node.setAttribute('CompilerType', self.compilerType)
        node.setAttribute('DebuggerType', self.debuggerType)
        node.setAttribute('Type', self.projectType)
        node.setAttribute('BuildCmpWithGlobalSettings', self.buildCmpWithGlobalSettings)
        node.setAttribute('BuildLnkWithGlobalSettings', self.buildLnkWithGlobalSettings)
        node.setAttribute('BuildResWithGlobalSettings', self.buildResWithGlobalSettings)
        
        compilerNode = XmlUtils.FindFirstByTagName(node, 'Compiler')
        if compilerNode:
            compilerNode.setAttribute('Required', Macros.BoolToString(self.compilerRequired))
            compilerNode.setAttribute('PreCompiledHeader', self.precompiledHeader)
        
        linkerNode = XmlUtils.FindFirstByTagName(node, 'Linker')
        if linkerNode:
            linkerNode.setAttribute('Required', Macros.BoolToString(self.linkerRequired))
        
        resCmpNode = XmlUtils.FindFirstByTagName(node, 'ResourceCompiler')
        if resCmpNode:
            resCmpNode.setAttribute('Required', Macros.BoolToString(self.isResCmpNeeded))
            
        generalNode = minidom.Document().createElement('General')
        generalNode.setAttribute('OutputFile', self.outputFile)
        generalNode.setAttribute('IntermediateDirectory', self.intermediateDirectory)
        generalNode.setAttribute('Command', self.command)
        generalNode.setAttribute('CommandArguments', self.commandArguments)
        generalNode.setAttribute('UseSeparateDebugArgs', Macros.BoolToString(self.useSeparateDebugArgs))
        generalNode.setAttribute('DebugArguments', self.debugArgs)
        generalNode.setAttribute('WorkingDirectory', self.workingDirectory)
        generalNode.setAttribute('PauseExecWhenProcTerminates', Macros.BoolToString(self.pauseWhenExecEnds))
        node.appendChild(generalNode)
        
        debuggerNode = minidom.Document().createElement('Debugger')
        debuggerNode.setAttribute('IsRemote', Macros.BoolToString(self.isDbgRemoteTarget))
        debuggerNode.setAttribute('RemoteHostName', self.dbgHostName)
        debuggerNode.setAttribute('RemoteHostPort', self.dbgHostPort)
        debuggerNode.setAttribute('DebuggerPath', self.debuggerPath)
        # node.appendChild(debuggerNode) #?
        
        envNode = minidom.Document().createElement('Environment')
        envNode.setAttribute('EnvVarSetName', self.envVarSet)
        envNode.setAttribute('DbgSetName', self.dbgEnvSet)
        node.appendChild(envNode)
        
        dbgStartupCommands = minidom.Document().createElement('StartupCommands')
        XmlUtils.SetNodeContent(dbgStartupCommands, self.debuggerStartupCmds)
        dbgPostCommands = minidom.Document().createElement('PostConnectCommands')
        XmlUtils.SetNodeContent(dbgPostCommands, self.debuggerPostRemoteConnectCmds)
        
        debuggerNode.appendChild(dbgStartupCommands)
        debuggerNode.appendChild(dbgPostCommands)
        node.appendChild(debuggerNode)
        
        dom = minidom.Document()
        # Add prebuild commands
        preBuildNode = dom.createElement('PreBuild')
        node.appendChild(preBuildNode)
        for i in self.preBuildCommands:
            commandNode = dom.createElement('Command')
            commandNode.setAttribute('Enabled', Macros.BoolToString(i.enabled))
            XmlUtils.SetNodeContent(commandNode, i.command)
            preBuildNode.appendChild(commandNode)
        
        # Add postbuild commands
        postBuildNode = dom.createElement('PostBuild')
        node.appendChild(postBuildNode)
        for i in self.postBuildCommands:
            commandNode = dom.createElement('Command')
            commandNode.setAttribute('Enabled', Macros.BoolToString(i.enabled))
            XmlUtils.SetNodeContent(commandNode, i.command)
            postBuildNode.appendChild(commandNode)
        
        # Add custom build commands
        customBuildNode = dom.createElement('CustomBuild')
        node.appendChild(customBuildNode)
        customBuildNode.setAttribute('Enabled', Macros.BoolToString(self.enableCustomBuild))
        
        # Add the working directory of the cutstom build
        customBuildWDNode = dom.createElement('WorkingDirectory')
        XmlUtils.SetNodeContent(customBuildWDNode, self.customBuildWorkingDir)
        customBuildNode.appendChild(customBuildWDNode)
        
        toolName = dom.createElement('ThirdPartyToolName')
        XmlUtils.SetNodeContent(toolName, self.toolName)
        customBuildNode.appendChild(toolName)
        
        # add the makefile generation command
        makeGenCmd = dom.createElement('MakefileGenerationCommand')
        XmlUtils.SetNodeContent(makeGenCmd, self.makeGenerationCommand)
        customBuildNode.appendChild(makeGenCmd)
        
        singleFileCmd = dom.createElement('SingleFileCommand')
        XmlUtils.SetNodeContent(singleFileCmd, self.singleFileBuildCommand)
        customBuildNode.appendChild(singleFileCmd)
        
        preprocFileCmd = dom.createElement('PreprocessFileCommand')
        XmlUtils.SetNodeContent(preprocFileCmd, self.preprocessFileCommand)
        customBuildNode.appendChild(preprocFileCmd)
        
        # add build and clean commands
        bldCmd = dom.createElement('BuildCommand')
        XmlUtils.SetNodeContent(bldCmd, self.customBuildCmd)
        customBuildNode.appendChild(bldCmd)
        
        clnCmd = dom.createElement('CleanCommand')
        XmlUtils.SetNodeContent(clnCmd, self.customCleanCmd)
        customBuildNode.appendChild(clnCmd)
        
        rebldCmd = dom.createElement('RebuildCommand')
        XmlUtils.SetNodeContent(rebldCmd, self.customRebuildCmd)
        customBuildNode.appendChild(rebldCmd)
        
        # add all 'Targets'
        for k, v in self.customTargets.items():
            customTgtNode = dom.createElement('Target')
            customTgtNode.setAttribute('Name', k)
            XmlUtils.SetNodeContent(customTgtNode, v)
            customBuildNode.appendChild(customTgtNode)
        
        # add the additional rules
        addtionalCmdsNode = dom.createElement('AdditionalRules')
        node.appendChild(addtionalCmdsNode)
        
        preCmd = dom.createElement('CustomPreBuild')
        XmlUtils.SetNodeContent(preCmd, self.customPreBuildRule)
        addtionalCmdsNode.appendChild(preCmd)
        
        postCmd = dom.createElement('CustomPostBuild')
        XmlUtils.SetNodeContent(postCmd, self.customPostBuildRule)
        addtionalCmdsNode.appendChild(postCmd)
        
        return node

    # 为了兼容性，还是写了 setter 和 getter...
    def GetPreprocessor(self):
        return self.commonConfig.GetPreprocessor()
    def SetPreprocessor(self, pre):
        self.commonConfig.SetPreprocessor(pre)
    
    def GetCompilerType(self):
        return self.compilerType
    
    def GetCompiler(self):
        return BuildSettings.BuildSettingsST.Get().GetCompiler(self.compilerType)
    
    def SetDebugArgs(self, debugArgs):
        self.debugArgs = debugArgs
    
    def SetUseSeparateDebugArgs(self, useSeparateDebugArgs):
        self.useSeparateDebugArgs = useSeparateDebugArgs
    
    def GetDebugArgs(self):
        return self.debugArgs
    
    def GetUseSeparateDebugArgs(self):
        return self.useSeparateDebugArgs
    
    def SetCompilerType(self, cmpType):
        self.compilerType = cmpType
    
    def GetDebuggerType(self):
        return self.debuggerType
    
    def SetDebuggerType(self, type):
        self.debuggerType = type
    
    def GetIncludePath(self):
        return self.commonConfig.GetIncludePath()
    
    def GetCompileOptions(self):
        return self.commonConfig.GetCompileOptions()
    
    def GetCCompileOptions(self):
        return self.commonConfig.GetCCompileOptions()
    
    def GetLinkOptions(self):
        return self.commonConfig.GetLinkOptions()
    
    def GetLibraries(self):
        return self.commonConfig.GetLibraries()
    
    def GetLibPath(self):
        return self.commonConfig.GetLibPath()
    
    def GetPreBuildCommands(self):
        return self.preBuildCommands
    
    def GetPostBuildCommands(self):
        return self.postBuildCommands
    
    def GetName(self):
        return self.name
    
    def IsCompilerRequired(self):
        return self.compilerRequired
    
    def IsLinkerRequired(self):
        return self.linkerRequired
    
    def GetOutputFileName(self):
        return Globals.NormalizePath(self.outputFile)
    
    def GetIntermediateDirectory(self):
        return Globals.NormalizePath(self.intermediateDirectory)
    
    def GetCommand(self):
        return self.command
    
    def GetCommandArguments(self):
        return self.commandArguments
    
    def GetWorkingDirectory(self):
        return Globals.NormalizePath(self.workingDirectory)
    
    def IsCustomBuild(self):
        return self.enableCustomBuild
    
    def GetCustomBuildCmd(self):
        return self.customBuildCmd
    
    def GetCustomCleanCmd(self):
        return self.customCleanCmd
    
    def GetCustomRebuildCmd(self):
        return self.customRebuildCmd
    
    def SetIncludePath(self, paths):
        self.commonConfig.SetIncludePath(paths)
    
    def SetLibraries(self, libs):
        self.commonConfig.SetLibraries(libs)
    
    def SetLibPath(self, path):
        self.commonConfig.SetLibPath(path)
    
    def SetCompileOptions(self, opts):
        self.commonConfig.SetCompileOptions(opts)
    
    def SetCCompileOptions(self, opts):
        self.commonConfig.SetCCompileOptions(opts)
    
    def SetLinkOptions(self, opts):
        self.commonConfig.SetLinkOptions(opts)
    
    def SetPreBuildCommands(self, cmds):
        self.preBuildCommands = cmds
    
    def SetPostBuildCommands(self, cmds):
        self.postBuildCommands = cmds
    
    def SetLibraries(self, libs):
        self.commonConfig.SetLibraries(libs)
    
    def SetLibPath(self, paths):
        self.commonConfig.SetLibPath(paths)
    
    def SetName(self, name):
        self.name = name
    
    def SetCompilerRequired(self, required):
        self.compilerRequired = required
    
    def SetLinkerRequired(self, required):
        self.linkerRequired = required
    
    def SetOutputFileName(self, name):
        self.outputFile = name
    
    def SetIntermediateDirectory(self, dir):
        self.intermediateDirectory = dir
    
    def SetCommand(self, cmd):
        self.command = cmd
    
    def SetCommandArguments(self, cmdArgs):
        self.commandArguments = cmdArgs
    
    def SetWorkingDirectory(self, dir):
        self.workingDirectory = dir
    
    def SetCustomBuildCmd(self, cmd):
        self.customBuildCmd = cmd
    
    def SetCustomCleanCmd(self, cmd):
        self.customCleanCmd = cmd
    
    def SetCustomRebuildCmd(self, cmd):
        self.customRebuildCmd = cmd

    def EnableCustomBuild(self, enable):
        self.enableCustomBuild = enable
    
    def SetResCompilerRequired(self, required):
        self.isResCmpNeeded = required
    
    def IsResCompilerRequired(self):
        return self.isResCmpNeeded
    
    def SetResCompileIncludePath(self, paths):
        self.commonConfig.SetResCompileIncludePath(paths)

    def GetResCompileIncludePath(self):
        return self.commonConfig.GetResCompileIncludePath()

    # 为了兼容性
    def SetResCmpIncludePath(self, paths):
        self.commonConfig.SetResCompileIncludePath(paths)

    # 为了兼容性
    def GetResCmpIncludePath(self):
        return self.commonConfig.GetResCompileIncludePath()

    def SetResCmpOptions(self, opts):
        self.commonConfig.SetResCmpOptions(opts)
    def SetResCompileOptions(self, opts):
        self.commonConfig.SetResCompileOptions(opts)

    def GetResCmpOptions(self):
        return self.commonConfig.GetResCmpOptions()
    def GetResCompileOptions(self):
        return self.commonConfig.GetResCompileOptions()

    # special custom rules
    def GetPreBuildCustom(self):
        return self.customPreBuildRule
    
    def GetPostBuildCustom(self):
        return self.customPostBuildRule
    
    def SetPreBuildCustom(self, rule):
        self.customPreBuildRule = rule
        
    def SetPostBuildCustom(self, rule):
        self.customPostBuildRule = rule

    def SetCustomBuildWorkingDir(self, customBuildWorkingDir):
        self.customBuildWorkingDir = customBuildWorkingDir
    
    def GetCustomBuildWorkingDir(self):
        return self.customBuildWorkingDir
    
    def SetPauseWhenExecEnds(self, pauseWhenExecEnds):
        self.pauseWhenExecEnds = pauseWhenExecEnds
    
    def GetPauseWhenExecEnds(self):
        return self.pauseWhenExecEnds
    
    def SetMakeGenerationCommand(self, makeGenerationCommand):
        self.makeGenerationCommand = makeGenerationCommand
    
    def SetToolName(self, toolName):
        self.toolName = toolName
    
    def GetMakeGenerationCommand(self):
        return self.makeGenerationCommand
    
    def GetToolName(self):
        return self.toolName
    
    def SetSingleFileBuildCommand(self, cmd):
        self.singleFileBuildCommand = cmd
    
    def GetSingleFileBuildCommand(self):
        return self.singleFileBuildCommand
    
    def SetPreprocessFileCommand(self, cmd):
        self.preprocessFileCommand = cmd
    
    def GetPreprocessFileCommand(self):
        return self.preprocessFileCommand
    
    def GetProjectType(self):
        return self.projectType
    
    def SetProjectType(self, type):
        self.projectType = type
    
    def SetDebuggerStartupCmds(self, cmds):
        self.debuggerStartupCmds = cmds
    
    def GetDebuggerStartupCmds(self):
        return self.debuggerStartupCmds
    
    def SetIsDbgRemoteTarget(self, isDbgRemoteTarget):
        self.isDbgRemoteTarget = isDbgRemoteTarget
    
    def GetIsDbgRemoteTarget(self):
        return self.isDbgRemoteTarget
    
    def SetDbgHostName(self, hostName):
        self.dbgHostPort = hostName
    
    def SetDbgHostPort(self, port):
        self.dbgHostPort = port
    
    def GetDbgHostName(self):
        return self.dbgHostName
    
    def GetDbgHostPort(self):
        return self.dbgHostPort
    
    def SetCustomTargets(self, customTargets):
        self.customTargets = customTargets
    
    def GetCustomTargets(self):
        return self.customTargets
    
    def SetDebuggerPath(self, path):
        self.debuggerPath = path
    
    def GetDebuggerPath(self):
        return self.debuggerPath
    
    def SetDebuggerPostRemoteConnectCmds(self, cmds):
        self.debuggerPostRemoteConnectCmds = cmds
    
    def GetDebuggerPostRemoteConnectCmds(self):
        return self.debuggerPostRemoteConnectCmds
    
    def GetBuildCmpWithGlobalSettings(self):
        return self.buildCmpWithGlobalSettings
    
    def SetBuildCmpWithGlobalSettings(self, buildType):
        self.buildCmpWithGlobalSettings = buildType
    
    def GetBuildLnkWithGlobalSettings(self):
        return self.buildLnkWithGlobalSettings
    
    def SetBuildLnkWithGlobalSettings(self, buildType):
        self.buildLnkWithGlobalSettings = buildType
    
    def GetBuildResWithGlobalSettings(self):
        return self.buildResWithGlobalSettings
    
    def SetBuildResWithGlobalSettings(self, buildType):
        self.buildResWithGlobalSettings = buildType
    
    def GetCommonConfiguration(self):
        return self.commonConfig
    
    def SetPrecompiledHeader(self, precompiledHeader):
        self.precompiledHeader = precompiledHeader
    
    def GetPrecompiledHeader(self):
        return self.precompiledHeader
    
    def SetDbgEnvSet(self, dbgEnvSet):
        self.dbgEnvSet = dbgEnvSet
    
    def SetEnvVarSet(self, envVarSet):
        self.envVarSet = envVarSet
    
    def GetDbgEnvSet(self):
        return self.dbgEnvSet
    
    def GetEnvVarSet(self):
        return self.envVarSet
    
    


if __name__ == '__main__':
    print 'hello'





















