#!/usr/bin/env python
# -*- encoding:utf-8 -*-


from xml.dom import minidom

import BuildSettings
import XmlUtils

class Builder:
    '''This class defines the abstract interface of a builder
    理论上可用于任何的构建工具，暂时支持 GNU make
    可访问的 *ST 系列的全局单例'''
    def __init__(self, name = '', command = '', node = None):
        '''如果提供 node，用 node 的内容覆盖'''
        self.name = ''
        self.toolPath = ''
        self.toolOptions = ''
        self.toolJobs = ''
        self.isActive = False

        # added on 2011-12-10: 替代 toolPath, toolOptions, toolJobs，为了泛用
        self.command = ''

        self.name = name
        self.command = command

        if node:
            self.LoadFromXmlNode(node)

    def LoadFromXmlNode(self, node):
        self.name = node.getAttribute('Name').encode('utf-8')
        self.toolPath = node.getAttribute('ToolPath').encode('utf-8')
        self.toolOptions = node.getAttribute('Options').encode('utf-8')
        self.toolJobs = XmlUtils.ReadString(node, 'Jobs', '1')
        self.isActive = XmlUtils.ReadBool(node, 'Active', self.isActive)

        self.command = node.getAttribute('Command').encode('utf-8')
        if not self.command:
            self.command = "%s %s" % (self.toolPath, self.toolOptions)

    def LoadFromBuilderSettings(self, bs):
        self.name = bs.name
        self.toolPath = bs.toolPath
        self.toolOptions = bs.toolOptions
        self.toolJobs = bs.toolJobs
        self.isActive = bs.isActive
        self.command = bs.command

    def ToXmlNode(self):
        node = minidom.Document().createElement('BuildSystem')
        node.setAttribute('Name', self.name)
        node.setAttribute('ToolPath', self.toolPath)
        node.setAttribute('Options', self.toolOptions)
        node.setAttribute('Jobs', self.toolJobs)

        node.setAttribute('Command', self.command)

        if self.isActive:
            node.setAttribute('Active', 'yes')
        else:
            node.setAttribute('Active', 'no')

        return node

    def GetName(self):
        return self.name

    def SetName(self, name):
        self.name = name

    def SetActive(self, active = True):
        '''set this builder as the active builder.
        It also makes sure that all other builders are set as non-active'''
        self.active = active

    def IsActive(self):
        return self.isActive

    def NormalizeConfigName(self, configName):
        '''规范化配置名字，暂时是把空格替换成下划线'''
        normalized = configName.strip()
        normalized = normalized.replace(' ', '_')
        return normalized

    # ================ API ==========================
    # The below API as default implementation, but can be
    # overrided in the derived class
    # ================ API ==========================

    def GetBuilderCommand(self):
        return self.command

    def SetBuilderCommand(self, command):
        self.command = command

    # ================ API ==========================
    # The below API must be implemented by the
    # derived class
    # ================ API ==========================

    def GetBuildCommand(self, project, confToBuild):
        pass

    def GetCleanCommand(self, project, confToBuild):
        pass

    def GetBatchBuildCommand(self, projects, confToBuild):
        '''获取批量构建的命令'''
        pass

    def GetBatchCleanCommand(self, projects, confToBuild):
        '''获取批量清理的命令'''
        pass

    def Export(self, project, confToBuild, isProjectOnly, force):
        pass

    ##-----------------------------------------------------------------
    ## Project Only API
    ##-----------------------------------------------------------------

    def GetPOBuildCommand(self, project, confToBuild):
        pass

    def GetPOCleanCommand(self, project, confToBuild):
        '''Return the command that should be executed for performing the clean
        task - for the project only (excluding dependencies'''
        pass

    def GetPORebuildCommand(self, project, confToBuild):
        pass

    def GetCompileFileCmd(self, project, confToBuild, fileName):
        '''create a command to execute for compiling single source file'''
        pass

    def GetPreprocessFileCmd(self, project, confToBuild, fileName):
        '''create a command to execute for preprocessing single source file'''
        pass


class BuilderSettings(Builder):
    '''为了避免名字混淆，继承一个 Builder 作为配置，
    此类的属性会存在 xml 文件里面'''
    pass


