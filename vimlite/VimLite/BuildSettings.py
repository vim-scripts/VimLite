#!/usr/bin/env python
# -*- encoding:utf-8 -*-

'''构建设置(Build Settings), 全局设置, 用于设定可用的编译器'''

import os.path

from xml.dom import minidom
import XmlUtils
import Compiler
import Builder
import Globals

CONFIG_FILE = os.path.join(Globals.VIMLITE_DIR, 'config', 'BuildSettings.xml')

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
            print 'Not equal version'
            pass
        self.fileName = os.path.abspath(fileName)

    def Save(self, fileName = ''):
        '''保存到文件'''
        if not fileName and not self.fileName:
            return

        try:
            if not fileName:
                fileName = self.fileName
            dirName = os.path.dirname(fileName)
            if not os.path.exists(dirName):
                os.makedirs(dirName)
            f = open(fileName, 'wb')
        except IOError:
            print 'IOError:', fileName
            raise IOError
        #f.write(self.doc.toxml('utf-8'))
        f.write(XmlUtils.ToPrettyXmlString(self.doc))
        f.close()

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
                # 为了保持原来的顺序
                node.replaceChild(cmp.ToXmlNode(), oldCmp)
            else:
                # 添加到最后
                node.appendChild(cmp.ToXmlNode())
        else:
            # 配置文件中没有 'Compilers' 节点，则新建一个并添加本本编译器
            node = minidom.Document().createElement('Compilers')
            self.doc.firstChild.appendChild(node)
            node.appendChild(cmp.ToXmlNode())

        self.Save()
    
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
            self.Save()
    
    def SetBuilderSettings(self, bd):
        '''会自动覆盖同名的 BuilderSettings'''
        node = XmlUtils.FindNodeByName(self.doc.firstChild, 'BuildSystem',
                                       bd.name)
        if node:
            node.parentNode.replaceChild(bd.ToXmlNode(), node)
        else:
            self.doc.firstChild.appendChild(bd.ToXmlNode())
        
        # Save
        self.Save()

    def GetBuilderSettingsByName(self, name):
        node = XmlUtils.FindNodeByName(
            XmlUtils.GetRoot(self.doc), 'BuildSystem', name)
        if node:
            return Builder.BuilderSettings(node = node)
        return None

    def GetActiveBuilderSettings(self):
        name = 'GNU makefile for g++/gcc'
        
        for i in XmlUtils.GetRoot(self.doc).childNodes:
            if i.nodeName == 'BuildSystem':
                if i.getAttribute('Active').lower() == 'yes':
                    name = i.getAttribute('Name')
                    break

        return self.GetBuilderSettingsByName(name)


class BuildSettingsST:
    __ins = None
    
    @staticmethod
    def Get():
        if not BuildSettingsST.__ins:
            BuildSettingsST.__ins = BuildSettings()
            # 载入默认设置
            BuildSettingsST.__ins.Load('2.1.0', CONFIG_FILE)
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
    CONFIG_FILE = os.path.expanduser('~/.vimlite/config/BuildSettings.xml')
    unittest.main()

