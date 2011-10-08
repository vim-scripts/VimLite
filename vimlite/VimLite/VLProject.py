#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom
import sys
import os
import XmlUtils
import Globals

from Project import Project


class VLProject(Project):
    '''VimLite 的 Project 类'''
    def __init__(self, fileName = ''):
        Project.__init__(self, fileName)

    def GetTypeByIndex(self, index):
        return self.GetTypeOfNode(self.vimLineData[index]['node'])

    def GetDispTextByIndex(self, index):
        type = self.GetTypeByIndex(index)
        text = ''
        
        if type == TYPE_FILE:
            expandText = FILE_PREFIX
        elif type == TYPE_VIRTUALDIRECTORY or type == TYPE_PROJECT:
            if self.vimLineData[index]['expand']:
                expandText = EXPAND_PREFIX
            else:
                expandText = FOLD_PREFIX
        
        text = MakeLevelPreStrDependList(self.vimLineData[index]['deepFlag']) + \
            expandText + \
            os.path.basename(self.vimLineData[index]['node'].getAttribute('Name'))
        
        return text

    def GetFilesIndex(self):
        ds = Globals.DirSaver()
        os.chdir(self.dirName)
        return self.GetFilesIndexOfNodes(self.rootNode)

    def GetFilesIndexOfNodes(self, node):
        if not node:
            return {}
        
        filesIndex = {}
        for i in node.childNodes:
            if i.nodeName == 'File':
                fileName = i.getAttribute('Name').encode('utf-8')
                fileName = os.path.abspath(fileName)
                filesIndex[fileName] = i
            # 递归遍历所有文件
            if i.hasChildNodes():
                filesIndex.update(self.GetFilesIndexOfNodes(i))
        return filesIndex


if __name__ == '__main__':
    #ins = VLProject('Test/LiteEditor.project.orig')
    ins = VLProject()
    ins.Create('JustTest', '', 'Jjj/sdd/gnekg', 'execute')
    print ins.name
    print os.name





