#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom
import XmlUtils

class BuilderConfig:
    '''代表一个构建系统'''
    def __init__(self, node = None):
        self.name = ''
        self.toolPath = ''
        self.toolOptions = ''
        self.toolJobs = ''
        self.isActive = False
        
        if node:
            self.name = XmlUtils.ReadString(node, 'Name')
            self.toolPath = XmlUtils.ReadString(node, 'ToolPath')
            self.toolOptions = XmlUtils.ReadString(node, 'Options')
            self.toolJobs = XmlUtils.ReadString(node, 'Jobs', '1')
            self.isActive = XmlUtils.ReadBool(node, 'Active', self.isActive)
        
    def SetIsActive(self, isActive):
        self.isActive = isActive
    
    def GetIsActive(self):
        return self.isActive
    
    def ToXmlNode(self):
        node = minidom.Document().createElement('BuildSystem')
        node.setAttribute('Name', self.name)
        node.setAttribute('ToolPath', self.toolPath)
        node.setAttribute('Options', self.toolOptions)
        node.setAttribute('Jobs', self.toolJobs)
        
        if self.isActive:
            node.setAttribute('Active', 'yes')
        else:
            node.setAttribute('Active', 'no')
        
        return node

if __name__ == '__main__':
    xmlStr = '''<BuildSystem Name="GNU makefile for g++/gcc" ToolPath="make" Options="-f" Jobs="4" Active="yes"/>'''
    xmlStr2 = '''<BuildSystem Name="GNU makefile onestep build" ToolPath="make" Options="-f" Jobs="1" Active="no"/>'''
    doc = minidom.parseString(xmlStr)
    #print doc.firstChild.toxml()
    doc2 = minidom.parseString(xmlStr2)
    #print doc.toxml()
    
    bs = BuilderConfig(doc2.firstChild)
    print bs.ToXmlNode().toxml()
    