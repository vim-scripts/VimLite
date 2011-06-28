#!/usr/bin/env python
# -*- encoding:utf-8 -*-

'''构建设置(Build Settings), 全局设置, 用于设定可用的编译器'''

import os.path

from xml.dom import minidom
import XmlUtils
import Compiler
import BuildSystem

CONFIG_FILE = os.path.expanduser('~/.vimlite/config/BuildSettings.xml')

class BuildSettingsCookie:
    '''用以确保可重入的结构，暂不需要'''
    
    def __init__(self):
        self.childXmlNode = None
        self.parentXmlNode = None


class BuildSettings:
    '''the build system configuration'''
    
    def __init__(self):
        self.doc = minidom.Document()
        self.fileName = ''
        
        self.curCmpNode = None      # 用于迭代的，没有线程安全
    
    def Load(self, version, xmlFile = ''):        
        if not xmlFile:
            fileName = 'build_settings.xml'
        else:
            fileName = xmlFile
        
        self.doc = minidom.parse(fileName)
        xmlVersion = self.doc.firstChild.getAttribute('Version')
        if xmlVersion != version:
            # TODO: GetDefaultCopy
            #print 'Not equal version'
            pass
        self.fileName = os.path.abspath(fileName)

    def GetCompilerNode(self, name):
        cmpsNode = XmlUtils.FindFirstByTagName(self.doc.firstChild, 'Compilers')
        if cmpsNode:
            if not name:
                # return the first compiler
                return XmlUtils.FindFirstByTagName(cmpsNode, 'Compiler')
            else:
                return XmlUtils.FindNodeByName(cmpsNode, 'Compiler', name)
        return None
    
    def SetCompiler(self, cmp):
        node = XmlUtils.FindFirstByTagName(self.doc.firstChild, 'Compilers')
        if node:
            oldCmp = None
            for i in node.childNodes:
                if i.nodeName == 'Compiler' \
                   and XmlUtils.ReadString(i, 'Name') == cmp.name:
                    oldCmp = i
                    break
            
            if oldCmp:
                node.removeChild(oldCmp)
            node.appendChild(cmp.ToXmlNode())
        else:
            node = minidom.Document().createElement('Compilers')
            self.doc.firstChild.appendChild(node)
            node.appendChild(cmp.ToXmlNode())
        try:
            f = open(self.fileName, 'wb')
        except IOError:
            print self.fileName, 'write failed!'
            raise IOError
        f.write(self.doc.toprettyxml(encoding = 'utf-8'))
        f.close()
    
    def GetCompiler(self, name):
        return Compiler.Compiler(self.GetCompilerNode(name))
    
    def GetFirstCompiler(self):
        cmps = XmlUtils.FindFirstByTagName(self.doc.firstChild, 'Compilers')
        if cmps:
            for i in cmps.childNodes:
                if i.nodeName == 'Compiler':
                    self.curCmpNode = i
                    return Compiler.Compiler(self.curCmpNode)
        return None
    
    def GetNextCompiler(self):
        node = self.curCmpNode.nextSibling
        while node:
            if node.nodeName == 'Compiler':
                self.curCmpNode = node
                return Compiler.Compiler(self.curCmpNode)
            node = node.nextSibling
        return None
    
    def IsCompilerExist(self, name):
        node = self.GetCompilerNode(name)
        return node != None
    
    def DeleteCompiler(self, name):
        node = self.GetCompilerNode(name)
        if node:
            node.parentNode.removeChild(node)
            try:
                f = open(self.fileName, 'wb')
            except IOError:
                print self.fileName, 'write failed!'
                raise IOError
            f.write(self.doc.toprettyxml(encoding = 'utf-8'))
            f.close()
    
    def SetBuildSystem(self, bs):
        '''BuildSystem 貌似是 BuilderConfig 的别名'''
        node = XmlUtils.FindNodeByName(self.firstChild, 'BuildSystem', bs.name)
        if node:
            node.parentNode.removeChild(node)
            
        self.doc.firstChild.appendChild(bs.ToXmlNode())
        
        # Save
        try:
            f = open(self.fileName, 'wb')
        except IOError:
            print self.fileName, 'write failed!'
            raise IOError
        f.write(self.doc.toprettyxml(encoding = 'utf-8'))
        f.close()
    
    def SetBuilderConfig(self, bc):
        self.SetBuildSystem(bc)
    
    def GetBuilderConfig(self, name):
        node = XmlUtils.FindNodeByName(
            XmlUtils.GetRoot(self.doc), 'BuildSystem', name)
        if node:
            return BuildSystem.BuilderConfig(node)
        return None
        
    
    def SaveBuilderConfig(self, builder):
        '''builder 是 Builder（一个通用基类），转为 BuilderConfig 后保存'''
        # update configuration file, why copy?
        bs = BuildSystem.BuilderConfig()
        bs.name = builder.name
        bs.toolPath = builder.toolPath
        bs.toolOptions = builder.toolOptions
        bs.toolJobs = builder.toolJobs
        bs.isActive = builder.isActive
        self.SetBuildSystem(bs)
    
    def GetSelectedBuildSystem(self):
        active = 'GNU makefile for g++/gcc'
        
        for i in XmlUtils.GetRoot(self.doc).childNodes:
            if i.nodeName == 'BuildSystem':
                if i.getAttribute('Active').lower() == 'yes':
                    active = i.getAttribute('Name')
                    break
        return active


class BuildSettingsST:
    __ins = None
    
    @staticmethod
    def Get():
        if not BuildSettingsST.__ins:
            BuildSettingsST.__ins = BuildSettings()
            # 载入默认设置
            BuildSettingsST.__ins.Load('2.0.7', CONFIG_FILE)
        return BuildSettingsST.__ins

    @staticmethod
    def Free():
        BuildSettingsST.__ins = None


#===============================================================================
# 简单的单元测试，可移动到其他文件
#===============================================================================

import unittest

class testThis(unittest.TestCase):
    def setUp(self):
        pass

    def testInit(self):
        ins = BuildSettingsST.Get()
        print ins.fileName
        #print ins.doc.toxml()
        #print ins.GetCompilerNode('gnu gcc').toprettyxml()
        print '-' * 80
        #print ins.GetCompiler('gnu gcc').ToXmlNode().toprettyxml()
        print ins.GetFirstCompiler().name
        print ins.GetNextCompiler().name
        print ins.GetFirstCompiler().name
        print ins.GetNextCompiler().name
        print ins.GetNextCompiler().name
        
        print ins.IsCompilerExist('gnu gcc')
        print ins.IsCompilerExist('gnu gccc')
        pass


if __name__ == '__main__':
    unittest.main()





