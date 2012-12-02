#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom
import sys
import os
import XmlUtils
import Macros


class ConfigMappingEntry:
    def __init__(self, project = '', name = ''):
        self.project = project
        self.name = name

class WorkspaceConfiguration:
    def __init__(self, node = None, name = '', selected = False):
        #FIXME: selected 参数应该强制为 False，需要设置只能由 BuildMatrix 设置
        self.name = name
        self.mappingList = []       #保存 ConfigMappingEntry 的列表
        self.isSelected = selected

        if node:
            self.name = XmlUtils.ReadString(node, 'Name')
            self.isSelected = XmlUtils.ReadBool(node, 'Selected')
            for i in node.childNodes:
                if i.nodeName == 'Project':
                    projName = XmlUtils.ReadString(i, 'Name')
                    confName = XmlUtils.ReadString(i, 'ConfigName')
                    self.mappingList.append(ConfigMappingEntry(projName, confName))

    def ToXmlNode(self):
        doc = minidom.Document()
        node = doc.createElement('WorkspaceConfiguration')
        node.setAttribute('Name', self.name)
        node.setAttribute('Selected', Macros.BoolToString(self.isSelected))

        for i in self.mappingList:
            projNode = doc.createElement('Project')
            projNode.setAttribute('Name', i.project)
            projNode.setAttribute('ConfigName', i.name)
            node.appendChild(projNode)
        return node

    def Clone(self):
        return WorkspaceConfiguration(self.ToXmlNode())

    def SetSelected(self, selected):
        self.isSelected = selected

    def IsSelected(self):
        return self.isSelected

    def GetName(self):
        return self.name

    def SetName(self, name):
        self.name = name

    def GetMapping(self):
        return self.mappingList

    def SetConfigMappingList(self, mapList):
        self.mappingList = mapList

    def GetConfigMappingList(self):
        return self.mappingList

class BuildMatrix:
    def __init__(self, node = None):
        # FIXME: 应该用字典
        self.configurationList = []     #保存 WorkspaceConfiguration 的列表

        if node:
            for i in node.childNodes:
                if i.nodeName == 'WorkspaceConfiguration':
                    self.configurationList.append(WorkspaceConfiguration(i))
        else:
            #construct default empty mapping with a default build configuration
            self.configurationList.append(WorkspaceConfiguration(name = 'Debug', 
                                                                 selected = True))
            self.configurationList.append(WorkspaceConfiguration(name = 'Release', 
                                                                 selected = False))

    def ToXmlNode(self):
        doc = minidom.Document()
        node = doc.createElement('BuildMatrix')
        for i in self.configurationList:
            node.appendChild(i.ToXmlNode())
        return node

    def GetConfigurations(self):
        return self.configurationList

    def SetConfiguration(self, conf):
        self.RemoveConfiguration(conf.GetName())
        self.configurationList.append(conf)

    def RemoveConfiguration(self, configName):
        isSelected = False
        for index in range(len(self.configurationList)):
            if self.configurationList[index].GetName() == configName:
                isSelected = self.configurationList[index].IsSelected()
                del self.configurationList[index]
                break
        if isSelected:
            # 删除的是激活的，那么设置列表的第一个为激活状态
            if self.configurationList:
                self.configurationList[0].SetSelected(True)

    def GetProjectSelectedConf(self, configName, project):
        '''返回 configName 的 BuildMatrix 设置中，project 选择的构建设置'''
        for i in self.configurationList:
            if i.GetName() == configName:
                li = i.GetMapping()
                for j in li:
                    if j.project == project:
                        return j.name
                break
        return ''

    def GetSelectedConfigurationName(self):
        '''DEPRECATED'''
        for i in self.configurationList:
            if i.IsSelected():
                return i.GetName()
        return ''

    def GetSelectedConfigName(self):
        '''返回当前选择的工作区构建设置的名字'''
        for i in self.configurationList:
            if i.IsSelected():
                return i.GetName()
        return ''

    def GetProjectSelectedConfigName(self, wspConfName, projName):
        '''获取 projName 在 wspConfName 时对应的配置名字'''
        for conf in self.configurationList:
            if conf.GetName() == wspConfName:
                for m in conf.GetMapping():
                    if m.project == projName:
                        return m.name
                break
        return ''

    def SetSelectedConfigurationName(self, name):
        for i in self.configurationList:
            if i.IsSelected():
                i.SetSelected(False)
                break

        conf = self.GetConfigurationByName(name)
        if conf:
            conf.SetSelected(True)

    def GetConfigurationByName(self, name):
        for i in self.configurationList:
            if i.GetName() == name:
                return i
        return None





