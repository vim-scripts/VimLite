#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom
import sys
import os
import shutil
import XmlUtils
import Globals

from VLProject import VLProject
from BuildMatrix import BuildMatrix
from BuildMatrix import ConfigMappingEntry

TYPE_WORKSPACE = 0
TYPE_PROJECT = 1
TYPE_VIRTUALDIRECTORY = 2
TYPE_FILE = 3
TYPE_INVALID = -1

EXPAND_PREFIX = '~'
FOLD_PREFIX = '+'
FILE_PREFIX = '-'

WORKSPACE_FILE_SUFFIX = 'vlworkspace'
PROJECT_FILE_SUFFIX = 'vlproject'


def ConvertWspFileToNewFormat(fileName):
    ins = VLWorkspace(fileName)
    ins.ConvertToNewFileFormat()
    del ins

def Cmp(s1, s2):
    '''忽略大小写比较两个字符串'''
    return cmp(s1.lower(), s2.lower())

# 由列表生成前缀字符
# 1 表示有下一个兄弟节点， 0 表示没有，即为父节点最后的子节点
# 从项目算起，可由 list 的长度获得深度，项目的深度为 1
def MakeLevelPreStrDependList(list):
    nCount = len(list)
    string = ''
    if nCount == 0:
        return string

    if nCount == 1:
        if list[0] == 0:
            string += '`'
        else:
            string += '|'
        return string
    
    if list[0] == 0:
        string += ' '
    else:
        string += '|'

    for i in list[1:-1]:
        if i == 0:
            string += '  '
        else:
            string += ' |'

    if list[-1] == 0:
        string += ' `'
    else:
        string += ' |'

    return string

# 根据节点的标签名排序节点对象
def SortVirtualDirectoryByNode(lNode):
    dic = {}
    for i in lNode:
        dic[i.attributes['Name'].value] = i
    li = dic.keys()
    li.sort(Cmp)
#    print li
    li = [dic[i] for i in li]
    return li

# 根据节点的的文件属性值排序节点对象
def SortFileByNode(lNode):
    dic = {}
    for i in lNode:
        dic[os.path.basename(i.attributes['Name'].value)] = i
    li = dic.keys()
    li.sort(Cmp)
#    print li
    li = [dic[i] for i in li]
    return li

# 工作空间为第 1 行，第一个项目为第 2 行，而 data 索引为 0，所以固有偏移为 2
CONSTANT_OFFSET = 2

# TODO: 处理工作空间节点
# NOTE: getAttribute() 等从 xml 获取的字符串全是 unicode 字符串, 
#       需要 encode('utf-8') 转为普通字符串以供 vim 解析
class VLWorkspace:
    '''工作空间对象，保存一个工作空间的数据结构'''
    def __init__(self, fileName = ''):
        self.doc = None
        self.rootNode = None
        self.name = ''
        self.fileName = ''
        self.dirName = ''
        self.baseName = ''
        self.vimLineData = []
        # 从 vim 的行号转为 vimLineData 编号的偏移量
        self.lineOffset = CONSTANT_OFFSET
        # 保存工作空间包含的项目实例的字典，名字到实例的映射
        self.projects = {}
        self.activeProject = ''
        self.modifyTime = 0
        self.filesIndex = {} # 用于从文件名快速定位所在位置(项目，目录等)的数据
                             # {文件绝对路径: xml 节点}
        self.fname2file = {} # 用于实现切换源文件/头文件
                             # {文件名: set(文件绝对路径)}

        if fileName:
            try:
                self.doc = minidom.parse(fileName)
            except IOError:
                print 'IOError:', fileName
                raise IOError
            self.rootNode = XmlUtils.GetRoot(self.doc)
            self.name = XmlUtils.GetRoot(self.doc).getAttribute('Name')\
                    .encode('utf-8')
            self.fileName = os.path.abspath(fileName)
            self.dirName, self.baseName = os.path.split(self.fileName)
            
            self.modifyTime = Globals.GetFileModificationTime(fileName)
            
            ds = Globals.DirSaver()
            os.chdir(self.dirName)
            for i in self.rootNode.childNodes:
                if i.nodeName == 'Project':
                    name = i.getAttribute('Name').encode('utf-8')
                    path = i.getAttribute('Path').encode('utf-8')
                    active = XmlUtils.ReadBool(i, 'Active')
                    if not os.path.isfile(path):
                        print 'Can not open %s, remove from workspace.' \
                                % (path,)
                        continue
                    if name:
                        self.projects[name] = VLProject(path)
                        if active:
                            self.activeProject = name
            
            deepFlag = [1]
            tmpList = []
            tmpDict = {}
            i = 0
            for k, v in self.projects.iteritems():
                datum = {}
                datum['node'] = v.rootNode
                datum['deepFlag'] = deepFlag[:]
                datum['expand'] = 0
                datum['project'] = v
                tmpDict[k] = datum
                tmpList.append(k)
                i += 1
            
            # sort
            tmpList.sort(Cmp)
            for i in tmpList:
                self.vimLineData.append(tmpDict[i])
                
            # 修正最后的项目的 deepFlag
            if self.vimLineData:
                self.vimLineData[-1]['deepFlag'][0] = 0

            self.GenerateFilesIndex()
        else:
            # 默认的工作空间, fileName 为空
            self.doc = minidom.parseString('''\
<?xml version="1.0" encoding="utf-8"?>
<CodeLite_Workspace Name="DEFAULT_WORKSPACE" Database="">
    <BuildMatrix>
        <WorkspaceConfiguration Name="Debug" Selected="yes"/>
    </BuildMatrix>
</CodeLite_Workspace>\
''')
            self.rootNode = XmlUtils.GetRoot(self.doc)
            self.name = XmlUtils.GetRoot(self.doc).getAttribute('Name')
            self.dirName = os.getcwd()

#===============================================================================
# 内部用接口，Do 开头
#===============================================================================

    def DoSetLineOffset(self, offset):
        '''设置索引偏移量
        
        offset 为相对于首行的偏移量，若在首行，即为 0'''
        self.lineOffset = CONSTANT_OFFSET + offset

    def DoGetTypeOfNode(self, node):
        if not node:
            return TYPE_INVALID
        
        if node.nodeName == 'CodeLite_Project':
            return TYPE_PROJECT
        elif node.nodeName == 'VirtualDirectory':
            return TYPE_VIRTUALDIRECTORY
        elif node.nodeName == 'File':
            return TYPE_FILE
        elif node.nodeName == 'CodeLite_Workspace':
            return TYPE_WORKSPACE
        else:
            return TYPE_INVALID
    
    def DoGetTypeByIndex(self, index):
        return self.DoGetTypeOfNode(self.vimLineData[index]['node'])

    def DoGetDispTextOfDatum(self, datum):
        type = self.DoGetTypeOfNode(datum['node'])
        text = ''
        
        expandText = 'x'
        if type == TYPE_FILE:
            expandText = FILE_PREFIX
        elif type == TYPE_VIRTUALDIRECTORY or type == TYPE_PROJECT:
            if datum['expand']:
                expandText = EXPAND_PREFIX
            else:
                expandText = FOLD_PREFIX
        
        text = MakeLevelPreStrDependList(datum['deepFlag']) + \
            expandText + \
            os.path.basename(datum['node'].getAttribute('Name'))
        
        return text

    def DoGetDispTextByIndex(self, index):
        return self.DoGetDispTextOfDatum(self.vimLineData[index])

    def DoIsHasNextSibling(self, index):
        return self.vimLineData[index]['deepFlag'][-1] == 1

    def DoIsHasChild(self, index):
        node = self.vimLineData[index]
        type = self.DoGetTypeByIndex(index)
        if type == TYPE_PROJECT or type == TYPE_VIRTUALDIRECTORY:
            for i in node.childNodes:
                if node.nodeName == 'File' \
                   or node.nodeName == 'VirtualDirectory':
                    return True
        else:
            return False

    def DoGetIndexByLineNum(self, lineNum):
        index = lineNum - self.lineOffset
        # FIXME: 需要兼容 workspace
        #if index < 0:
            #index = -1
        return index
    
    def DoGetLineNumByIndex(self, index):
        lineNum = index + self.lineOffset
        return lineNum
    
    def DoInsertChild(self, lineNum, datum):
        '''按照排序顺序插入子节点到相应的位置，不能插入返回 0'''
        parentType = self.GetNodeType(lineNum)
        parentIndex = self.DoGetIndexByLineNum(lineNum)
        if parentType == TYPE_FILE or parentType == TYPE_INVALID or not datum:
            return 0
        
        parentDeep = self.GetNodeDeep(lineNum)
        parent = self.GetDatumByLineNum(lineNum)
        if not self.IsNodeExpand(lineNum):
            self.Expand(lineNum)
        
        s1 = os.path.basename(datum['node'].getAttribute('Name'))
        newType = self.DoGetTypeOfNode(datum['node'])
        newDeep = parentDeep + 1
        
        # 基本方法是顺序遍历 vimLineData，
        # 一路修改 deepFlag，一路比较，如合适，即插入
        for i in range(parentIndex + 1, len(self.vimLineData)):
            curDeep = len(self.vimLineData[i]['deepFlag'])
            if curDeep > parentDeep:
                # 新节点必插在后面，所以当前节点必有兄弟节点
                self.vimLineData[i]['deepFlag'][newDeep - 1] = 1

                # 当前节点为兄弟节点的子节点，跳过
                if curDeep > newDeep:
                    continue

                s2 = os.path.basename(
                    self.vimLineData[i]['node'].getAttribute('Name'))
                if Cmp(s1.lower(), s2.lower()) > 0:
                    # 如果 datum 为 VirtualDirectory 当前位置为 File，插入之
                    if newType == TYPE_VIRTUALDIRECTORY \
                             and self.DoGetTypeByIndex(i) == TYPE_FILE:
                        # 如果插入的位置是倒数第二个位置, 需要处理
                        # 因为此循环一开始就把节点的 deepFlag 最后位置为 1 了,
                        # 这是不对的, 修正过来
                        if i + 1 >= len(self.vimLineData) \
                             or len(self.vimLineData[i+1]['deepFlag']) < newDeep:
                            self.vimLineData[i]['deepFlag'][newDeep - 1] = 0

                        datum['deepFlag'] = parent['deepFlag'][:]
                        datum['deepFlag'].append(1)
                        self.vimLineData.insert(i, datum)
                        return self.DoGetLineNumByIndex(i)
                    
                    continue
                elif Cmp(s1.lower(), s2.lower()) < 0:
                    # 如果 datum 为 File，当前位置为 VirtualDirectory，跳过之
                    if newType == TYPE_FILE \
                          and self.DoGetTypeByIndex(i) == TYPE_VIRTUALDIRECTORY:
                        continue
                    
                    # 如果插入的位置是倒数第二个位置, 需要处理
                    # 因为此循环一开始就把节点的 deepFlag 最后位置为 1 了,
                    # 这是不对的, 修正过来
                    if i + 1 >= len(self.vimLineData) \
                         or len(self.vimLineData[i+1]['deepFlag']) < newDeep:
                        self.vimLineData[i]['deepFlag'][newDeep - 1] = 0

                    # 插在中间
                    datum['deepFlag'] = parent['deepFlag'][:]
                    datum['deepFlag'].append(1)
                    self.vimLineData.insert(i, datum)
                    return self.DoGetLineNumByIndex(i)
                else:
                    # 已有相同的名字，如果相同的名字的刚好是最后的节点，
                    # 需要修正过来
                    if i + 1 >= len(self.vimLineData) \
                         or len(self.vimLineData[i+1]['deepFlag']) < newDeep:
                        self.vimLineData[i]['deepFlag'][newDeep - 1] = 0
                    return 0
            else:
                # 到达了深度不比父节点大的节点，要么是兄弟，要么是祖先的兄弟。
                # 插在父节点最后
                datum['deepFlag'] = parent['deepFlag'][:]
                datum['deepFlag'].append(0)
                self.vimLineData.insert(i, datum)
                return self.DoGetLineNumByIndex(i)
        # 父节点是显示的最后的节点或者
        # 父节点是显示的最后的节点且新数据本应插在最后。插在最后
        datum['deepFlag'] = parent['deepFlag'][:]
        datum['deepFlag'].append(0)
        self.vimLineData.insert(self.GetLastLineNum() + 1, datum)
        return self.GetLastLineNum()

    def DoInsertProject(self, lineNum, datum):
        '''按照排序顺序插入子节点到相应的位置，不能插入返回 0'''
        parentType = self.GetNodeType(lineNum)
        if parentType != TYPE_WORKSPACE or not datum:
            return 0
        
        parentDeep = self.GetNodeDeep(lineNum)
        parent = self.GetDatumByLineNum(lineNum)
        if not self.IsNodeExpand(lineNum):
            self.Expand(lineNum)

        parentIndex = -1
        parentDeep = 0
        parent = {'deepFlag' : []}
        
        s1 = os.path.basename(datum['node'].getAttribute('Name'))
        newType = self.DoGetTypeOfNode(datum['node'])
        newDeep = parentDeep + 1
        
        # 基本方法是顺序遍历 vimLineData，
        # 一路修改 deepFlag，一路比较，如合适，即插入
        for i in range(parentIndex + 1, len(self.vimLineData)):
            curDeep = len(self.vimLineData[i]['deepFlag'])
            if curDeep > parentDeep:
                # 新节点比插在后面，所以当前节点必有兄弟节点
                self.vimLineData[i]['deepFlag'][newDeep - 1] = 1

                # 当前节点为兄弟节点的子节点，跳过
                if curDeep > newDeep:
                    continue

                s2 = os.path.basename(
                    self.vimLineData[i]['node'].getAttribute('Name'))
                if Cmp(s1.lower(), s2.lower()) > 0:
                    continue
                elif Cmp(s1.lower(), s2.lower()) < 0:
                    # 插在中间
                    datum['deepFlag'] = parent['deepFlag'][:]
                    datum['deepFlag'].append(1)
                    self.vimLineData.insert(i, datum)
                    return self.DoGetLineNumByIndex(i)
                else:
                    # 已有相同的名字，如果相同的名字的刚好是最后的节点，
                    # 需要修正过来
                    if i + 1 >= len(self.vimLineData) \
                         or len(self.vimLineData[i+1]['deepFlag']) < newDeep:
                        self.vimLineData[i]['deepFlag'][newDeep - 1] = 0
                    return 0
            else:
                # 到达了深度比父节点小的节点，
                # 要么是兄弟，要么是祖先的兄弟。插在父节点最后
                datum['deepFlag'] = parent['deepFlag'][:]
                datum['deepFlag'].append(0)
                self.vimLineData.insert(i, datum)
                return self.DoGetLineNumByIndex(i)
        # 父节点是显示的最后的节点或者父节点是显示的最后的节点
        # 且新数据本应插在最后。插在最后
        datum['deepFlag'] = parent['deepFlag'][:]
        datum['deepFlag'].append(0)
        self.vimLineData.insert(self.GetLastLineNum() + 1, datum)
        return self.GetLastLineNum()

    def DoAddVdirOrFileNode(self, lineNum, nodeType, name, save = True):
        '''会自动修正 name 为正确的相对路径，返回节点添加后所在的行号。
        如无法插入，如存在同名，则返回 0'''
        index = self.DoGetIndexByLineNum(lineNum)
        type = self.GetNodeType(lineNum)
        if index < 0 or type == TYPE_FILE or type == TYPE_INVALID \
           or type == TYPE_WORKSPACE:
            return 0
        
        parentDatum = self.vimLineData[index]
        parentNode = self.vimLineData[index]['node']
        newDatum = {}
        if nodeType == TYPE_FILE:
            if not os.path.isabs(name):
                # 若非绝对路径，必须相对于项目的目录
                name = os.path.join(parentDatum['project'].dirName, name)
            # 修改 name 为相对于项目文件目录的路径
            name = os.path.relpath(os.path.abspath(name), 
                                   parentDatum['project'].dirName)
            newNode = self.doc.createElement('File')
        elif nodeType == TYPE_VIRTUALDIRECTORY:
            newNode = self.doc.createElement('VirtualDirectory')
        else:
            return 0
        
        newNode.setAttribute('Name', name)
        newDatum['node'] = newNode
        newDatum['expand'] = 0
        newDatum['project'] = parentDatum['project']

        # 更新 vimLineData
        ret = self.DoInsertChild(lineNum, newDatum)
        # 插入失败（同名冲突），返回
        if not ret:
            print 'Name Conflict'
            return ret

        parentNode.appendChild(newNode)

        if nodeType == TYPE_FILE:
            # 添加此 filesIndex
            key = os.path.abspath(
                os.path.join(parentDatum['project'].dirName, name))
            self.filesIndex[key] = newNode
            # 添加此 fname2file
            key2 = os.path.basename(key)
            if not self.fname2file.has_key(key2):
                self.fname2file[key2] = set()
            self.fname2file[key2].add(key)

        # 保存
        if save:
            newDatum['project'].Save()

        return ret

    def DoCheckNameConflict(self, parentNode, checkName):
        '''检测是否存在名字冲突，如存在返回 True，否则返回 False'''
        for node in parentNode.childNodes:
            if node.nodeType != node.ELEMENT_NODE:
                continue

            name = node.getAttribute('Name')
            if not name:
                continue

            if os.path.basename(name) == os.path.basename(checkName):
                return True
            else:
                continue
        return False


#===============================================================================
# 外部用接口 ===== 开始
#===============================================================================
    #===========================================================================
    # Vim 操作接口 ===== 开始
    #===========================================================================
    def SetWorkspaceLineNum(self, lineNum):
        '''设置工作空间名称在 vim 显示时所在的行号以便修正索引'''
        if lineNum < 1:
            lineNum = 1
        self.DoSetLineOffset(lineNum - 1)

    def GetDatumByLineNum(self, lineNum):
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0 or index >= len(self.vimLineData):
            return None
        else:
            return self.vimLineData[index]

    def Expand(self, lineNum):#
        '''返回展开后增加的行数'''
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return 0
        rootDatum = self.vimLineData[index]
        node = self.vimLineData[index]['node']
        type = self.DoGetTypeByIndex(index)
        
        # 已经展开，无须操作
        if rootDatum['expand']:
            return 0
        
        # 修改展开前缀
        self.vimLineData[index]['expand'] = 1
        
        vdList = []
        vdDict = {}
        fileList = []
        fileDict = {}
        if type == TYPE_VIRTUALDIRECTORY or type == TYPE_PROJECT:
            # 如果有上次的缓存，直接用缓存
            if rootDatum.has_key('children'):
                li = rootDatum['children']
                self.vimLineData[index+1:index+1] = li
                del rootDatum['children']
                return len(li)
            else:
                for i in node.childNodes:
                    if i.nodeName == 'VirtualDirectory':
                        deepFlag = rootDatum['deepFlag'][:]
                        deepFlag.append(1)
                        datum = {}
                        datum['node'] = i
                        datum['deepFlag'] = deepFlag[:]
                        datum['expand'] = 0
                        datum['project'] = rootDatum['project']
                        vdList.append(i.getAttribute('Name'))
                        vdDict[i.getAttribute('Name')] = datum
                    elif i.nodeName == 'File':
                        deepFlag = rootDatum['deepFlag'][:]
                        deepFlag.append(1)
                        datum = {}
                        datum['node'] = i
                        datum['deepFlag'] = deepFlag[:]
                        datum['expand'] = 0
                        datum['project'] = rootDatum['project']
                        fileList.append(
                            os.path.basename(i.getAttribute('Name')))
                        fileDict[
                            os.path.basename(i.getAttribute('Name'))] = datum
                li = []
                if vdList:
                    vdList.sort(Cmp)
                    for i in vdList:
                        li.append(vdDict[i])
                if fileList:
                    fileList.sort(Cmp)
                    for i in fileList:
                        li.append(fileDict[i])
                if li:
                    li[-1]['deepFlag'][-1] = 0
                self.vimLineData[index+1:index+1] = li
                return len(li)
        return 0

    def ExpandR(self, lineNum):#
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return 0
        datum = self.vimLineData[index]
        deep = len(datum['deepFlag'])
        
        count = 0
        i = lineNum
        while True:
            count += self.Expand(i)
            i += 1
            if self.GetNodeDeep(i) <= deep:
                break
        return count

    def ExpandAll(self):#
        if not self.vimLineData:
            return
        
        i = self.GetRootLineNum(1) + 1
        while True:
            self.ExpandR(i)
            next = self.GetNextSiblingLineNum(i)
            if next == i:
                break
            i = next

    def Fold(self, lineNum):
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return 0
        rootDatum = self.vimLineData[index]
        node = rootDatum['node']
        type = self.DoGetTypeByIndex(index)
        
        # 已经是 fold 状态，无须操作
        if rootDatum['expand'] == 0:
            return 0
        
        rootDatum['expand'] = 0
        
        deep = len(rootDatum['deepFlag'])
        count = 0
        for i in range(index+1, len(self.vimLineData)):
            if len(self.vimLineData[i]['deepFlag']) <= deep:
                break
            else:
                count += 1
        rootDatum['children'] = self.vimLineData[index+1:index+1+count]
        del self.vimLineData[index+1:index+1+count]
        return count
        
    def FoldR(self, lineNum):
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return 0
        rootDatum = self.vimLineData[index]
        node = rootDatum['node']
        type = self.DoGetTypeByIndex(index)
        
        # 已经是 fold 状态，无须操作
        if rootDatum['expand'] == 0:
            return 0
        
        rootDatum['expand'] = 0
        
        deep = len(rootDatum['deepFlag'])
        count = 0
        for i in range(index+1, len(self.vimLineData)):
            if len(self.vimLineData[i]['deepFlag']) <= deep:
                break
            else:
                count += 1
        del self.vimLineData[index+1:index+1+count]
        return count

    def FoldAll(self):
        if not self.vimLineData:
            return
        
        i = self.GetRootLineNum(1) + 1
        while True:
            self.FoldR(i)
            next = self.GetNextSiblingLineNum(i)
            if next == i:
                break
            i = next

    def GetRootLineNum(self, lineNum = 0):#
        '''获取根节点的行号, 参数仅仅用于保持形式, 除此以外别无他用'''
        return 1 + self.lineOffset - 2

    def GetParentLineNum(self, lineNum):#
        '''如没有，返回相同的 lineNum，项目的父节点应为工作空间，但暂未实现'''
        deep = self.GetNodeDeep(lineNum)
        if deep == 0: return lineNum
        
        if self.GetNodeType(lineNum) == TYPE_PROJECT:
            return self.GetRootLineNum(lineNum)
        
        for i in range(1, lineNum):
            j = lineNum - i
            curDeep = self.GetNodeDeep(j)
            if curDeep == deep - 1:
                return j
        
        return lineNum

    def GetNextSiblingLineNum(self, lineNum):#
        '''如没有，返回相同的 lineNum'''
        deep = self.GetNodeDeep(lineNum)
        if deep == 0: return lineNum
        
        for i in range(lineNum + 1, self.GetLastLineNum() + 1):
            curDeep = self.GetNodeDeep(i)
            if curDeep < deep:
                break
            elif curDeep == deep:
                return i
        
        return lineNum

    def GetPrevSiblingLineNum(self, lineNum):#
        '''如没有，返回相同的 lineNum'''
        deep = self.GetNodeDeep(lineNum)
        if deep == 0: return lineNum
        
        for i in range(1, lineNum):
            j = lineNum - i
            curDeep = self.GetNodeDeep(j)
            if curDeep < deep:
                break
            elif curDeep == deep:
                return j
        
        return lineNum

    def GetAllDisplayTexts(self):#
        texts = []
        texts.append(self.name)
        for i in range(len(self.vimLineData)):
            texts.append(self.DoGetDispTextByIndex(i))
        return texts

    def GetXmlNode(self, lineNum):#
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0 or index >= len(self.vimLineData):
            return None
        else:
            return self.vimLineData[index]['node']

    def GetNodeType(self, lineNum):#
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0 or index >= len(self.vimLineData):
            if lineNum == self.GetRootLineNum(lineNum):
                return TYPE_WORKSPACE
            else:
                return TYPE_INVALID
        else:
            return self.DoGetTypeOfNode(self.vimLineData[index]['node'])

    def GetNodeDeep(self, lineNum):#
        '''返回节点的深度，如 lineNum 越界，返回 0'''
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0 or index >= len(self.vimLineData):
            return 0
        else:
            return len(self.vimLineData[index]['deepFlag'])

    def IsNodeExpand(self, lineNum):
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return False
        
        if self.vimLineData[index]['expand']:
            return True
        else:
            return False

    def GetLineText(self, lineNum):
        if lineNum == self.GetRootLineNum(lineNum):
            return self.name
        
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return ''
        
        return self.DoGetDispTextByIndex(index)

    def GetLastLineNum(self):
        return self.lineOffset + len(self.vimLineData) - 1

    def GetFileByLineNum(self, lineNum, absPath = False):
        datum = self.GetDatumByLineNum(lineNum)
        if not datum or self.GetNodeType(lineNum) != TYPE_FILE:
            return ''
        
        xmlNode = datum['node']
        file = xmlNode.getAttribute('Name')
        if absPath:
            ds = Globals.DirSaver()
            os.chdir(datum['project'].dirName)
            file = os.path.abspath(file)
        return file

    def GetDispNameByLineNum(self, lineNum):
        datum = self.GetDatumByLineNum(lineNum)
        type = self.GetNodeType(lineNum)

        if type == TYPE_INVALID:
            return self.GetName()
        elif not datum:
            return ''
        
        xmlNode = datum['node']
        dispName = xmlNode.getAttribute('Name')
        return os.path.basename(dispName)

    def RenameNodeByLineNum(self, lineNum, newName):
        '''重命名节点，暂支持虚拟目录和文件'''
        datum = self.GetDatumByLineNum(lineNum)
        type = self.GetNodeType(lineNum)
        if type != TYPE_VIRTUALDIRECTORY and type != TYPE_FILE:
            return

        xmlNode = datum['node']
        project = datum['project']
        oldName = xmlNode.getAttribute('Name')
        if oldName == newName:
            return
        if self.DoCheckNameConflict(xmlNode.parentNode, newName):
            print 'Name Conflict'
            return
        if type == TYPE_FILE:
            absOldFile = self.GetFileByLineNum(lineNum, True)
            dirName = os.path.dirname(absOldFile)
            absNewFile = os.path.join(dirName, newName)
            if os.path.exists(absNewFile):
                print 'Exists a same file'
                return
            elif os.path.exists(absOldFile):
                #print absOldFile
                #print absNewFile
                os.rename(absOldFile, absNewFile)
            else:
                pass

            # 修正 filesIndex
            self.filesIndex[absNewFile] = self.filesIndex[absOldFile]
            del self.filesIndex[absOldFile]

            # 修正 fname2file
            oldKey = os.path.basename(absOldFile)
            self.fname2file[oldKey].remove(absOldFile)
            if not self.fname2file[oldKey]:
                del self.fname2file[oldKey]
            newKey = os.path.basename(absNewFile)
            if not self.fname2file.has_key(newKey):
                self.fname2file[newKey] = set()
            self.fname2file[newKey].add(absNewFile)


        xmlNode.setAttribute('Name', 
                             os.path.join(os.path.dirname(oldName), newName))
        project.Save()

        #TODO: 重新排序

    def DeleteNode(self, lineNum):
        '''返回删除的行数，也即为 Vim 显示中减少的行数。
        支持项目、虚拟目录、文件'''
        index = self.DoGetIndexByLineNum(lineNum)
        if index < 0: return 0
        
        type = self.GetNodeType(lineNum)
        if type != TYPE_VIRTUALDIRECTORY and type != TYPE_FILE \
                   and type != TYPE_PROJECT:
            return 0
        
        # 若删除的节点为父节点的最后的子节点，需特殊处理
        if not self.DoIsHasNextSibling(index):
            ln = self.GetPrevSiblingLineNum(lineNum)
            if ln != lineNum:
                # 修正上一个兄弟节点到删除节点之间的所有节点的 deepFlag
                delDeep = self.GetNodeDeep(lineNum)
                for i in range(ln, lineNum):
                    datum = self.GetDatumByLineNum(i)
                    datum['deepFlag'][delDeep - 1] = 0
        
        datum = self.GetDatumByLineNum(lineNum)
        delNode = datum['node']
        project = datum['project']
        deep = self.GetNodeDeep(lineNum)
        
        # 计算删除的行数
        delLineCount = 1
        for i in range(lineNum + 1, self.GetLastLineNum() + 1):
            if deep < self.GetNodeDeep(i):
                delLineCount += 1
            else:
                break

        if type == TYPE_FILE:
            # 删除此 filesIndex
            key = os.path.abspath(
                os.path.join(project.dirName, delNode.getAttribute('Name')))
            if self.filesIndex.has_key(key):
                del self.filesIndex[key]
            # 删除此 fname2file
            try:
                self.fname2file[os.path.basename(key)].remove(key)
            except KeyError:
                pass

        # 删除 xml 节点
        if type == TYPE_PROJECT:
            self.RemoveProject(project.name)
        else:
            delNode.parentNode.removeChild(delNode)
        
        # 删除 vimLineData 相应数据
        del self.vimLineData[ index : index + delLineCount ]
        
        # 保存改变
        if type == TYPE_PROJECT:
            self.Save()
        else:
            project.Save()
        
        return delLineCount

    def AddVirtualDirNode(self, lineNum, name):
        return self.DoAddVdirOrFileNode(lineNum, TYPE_VIRTUALDIRECTORY, name)

    def AddFileNode(self, lineNum, name):
        return self.DoAddVdirOrFileNode(lineNum, TYPE_FILE, name)

    def AddFileNodeQuickly(self, lineNum, name):
        return self.DoAddVdirOrFileNode(lineNum, TYPE_FILE, name, False)

    def SetActiveProjectByLineNum(self, lineNum):
        type = self.GetNodeType(lineNum)
        if type != TYPE_PROJECT:
            return False
        
        xmlNode = XmlUtils.FindNodeByName(
            self.rootNode, 'Project', self.activeProject)
        #可能是刚加进来，根本没有上一个已激活的项目
        if xmlNode:
            xmlNode.setAttribute('Active', 'No')
        
        datum = self.GetDatumByLineNum(lineNum)
        xmlNode = XmlUtils.FindNodeByName(
            self.rootNode, 'Project', datum['project'].name)
        self.activeProject = datum['project'].name
        xmlNode.setAttribute('Active', 'Yes')
        
        self.Save()

    #===========================================================================
    # Vim 操作接口 ===== 结束
    #===========================================================================

#===============================================================================

    #===========================================================================
    # 常规操作接口 ===== 开始
    #===========================================================================
    def GetName(self):
        return self.name

    def GetWorkspaceFileName(self):
        return self.fileName

    def GetWorkspaceFileLastModifiedTime(self):
        return Globals.GetFileModificationTime(self.fileName)

    def GetWorkspaceLastModifiedTime(self):
        return self.modifyTime
    
    def SetWorkspaceLastModifiedTime(self, modTime):
        self.modifyTime = modTime

    def GetFileLastModifiedTime(self):
        return int(os.path.getmtime(self.fileName))

    def GetActiveProjectName(self):
        return self.activeProject
    
    def SetActiveProject(self, name):
        xmlNode = XmlUtils.FindNodeByName(
            self.rootNode, 'Project', self.activeProject)
        xmlNode2 = XmlUtils.FindNodeByName(self.rootNode, 'Project', name)
        if not xmlNode2:
            return False
        
        if xmlNode:
            xmlNode.setAttribute('Active', 'No')
        
        self.activeProject = name
        xmlNode2.setAttribute('Active', 'Yes')
        self.Save()

    def GetBuildMatrix(self):
        return BuildMatrix(XmlUtils.FindFirstByTagName(self.rootNode, 
                                                       'BuildMatrix'))

    def SetBuildMatrix(self, buildMatrix):
        '''此为保存 BuildMatrix 的唯一方式！'''
        oldBm = XmlUtils.FindFirstByTagName(self.rootNode, 'BuildMatrix')
        if oldBm:
            self.rootNode.removeChild(oldBm)
        
        self.rootNode.appendChild(buildMatrix.ToXmlNode())
        self.Save()
        
        # force regeneration of makefiles for all projects
        for i in self.projects.itervalues():
            i.SetModified(True)

    def DisplayAll(self, dispLn = False, stream = sys.stdout):
        ln = 1
        if dispLn:
            stream.write('%02d ' % (ln,))
            ln += 1
        stream.write(self.name + '\n')
        for i in range(len(self.vimLineData)):
            if dispLn:
                stream.write('%02d ' % (ln,))
                ln += 1
            stream.write(self.DoGetDispTextByIndex(i) + '\n')

    def GetAllFiles(self, absPath = False):
        files = []
        for k, v in self.projects.iteritems():
            files.extend(v.GetAllFiles(absPath))
        return files

    def GenerateFilesIndex(self):
        self.filesIndex.clear()
        for k, v in self.projects.iteritems():
            self.filesIndex.update(v.GetFilesIndex())
        # 从 filesIndex 重建 fname2file
        self.fname2file.clear()
        for k in self.filesIndex.iterkeys():
            key2 = os.path.basename(k)
            if not self.fname2file.has_key(key2):
                self.fname2file[key2] = set()
            self.fname2file[key2].add(k)

    def GetProjectByFileName(self, fileName):
        '''从绝对路径的文件名中获取文件所在的项目实例'''
        if not self.filesIndex.has_key(fileName):
            return None

        node = self.filesIndex[fileName]
        parentNode = node.parentNode
        projName = ''
        while parentNode:
            if parentNode.nodeName == 'CodeLite_Project':
                projName = parentNode.getAttribute('Name')
                break
            parentNode = parentNode.parentNode

        return self.FindProjectByName(projName)

    def GetWspFilePathByFileName(self, fileName):
        '''从绝对路径的文件名中获取文件在工作空间的绝对路径
        
        从工作空间算起，如 /项目名/虚拟目录/文件显示名'''
        if not self.filesIndex.has_key(fileName):
            return ''

        node = self.filesIndex[fileName]
        parentNode = node.parentNode
        wspPathList = [os.path.basename(node.getAttribute('Name'))]
        while parentNode:
            name = parentNode.getAttribute('Name')
            if not name:
                return ''

            wspPathList.insert(0, name)
            if parentNode.nodeName == 'CodeLite_Project':
                break
            parentNode = parentNode.parentNode

        return '/' + '/'.join(wspPathList)


#=====
    def CreateWorkspace(self, name, path):
        # If we have an open workspace, close it
        if self.rootNode:
            self.Save()

        if not name:
            print 'Invalid workspace name'
            return False

        # Create new
        self.fileName = os.path.abspath(os.path.join(path, name + os.extsep 
                                                     + WORKSPACE_FILE_SUFFIX))

        #ds = Globals.DirSaver()
        #os.chdir(path)
        dbFileName = './' + name + '.tags'
        # TagsManagerST.Get().OpenDatabase(dbFileName)

        self.doc = minidom.Document()
        self.rootNode = self.doc.createElement('CodeLite_Workspace')
        self.doc.appendChild(self.rootNode)
        self.rootNode.setAttribute('Name', name)
        self.rootNode.setAttribute('Database', dbFileName)

        self.Save()
        self.__init__(self.fileName)
        # create an empty build matrix
        self.SetBuildMatrix(BuildMatrix())
        return True

    def OpenWorkspace(self, fileName):
        self.__init__(fileName)

    def CloseWorkspace(self):
        if self.rootNode:
            self.Save()
            self.__init__()

    def ReloadWorkspace(self):
        self.OpenWorkspace(self.fileName)

    def CreateProject(self, name, path, type, cmpType = '', 
                      addToBuildMatrix = True):
        if not self.rootNode:
            print 'No workspace open'
            return False

        if self.projects.has_key(name):
            print 'A project with the same name already exists in the '\
                    'workspace!'
            return False

        project = VLProject()
        project.Create(name, '', path, type)
        self.projects[name] = project

        if cmpType:
            settings = project.GetSettings()
            settings.GetBuildConfiguration().SetCompilerType(cmpType)
            project.SetSettings(settings)

        node = self.doc.createElement('Project')
        node.setAttribute('Name', name)
        
        # make the project path to be relative to the workspace
        projFile = os.path.join(path, name + os.extsep + PROJECT_FILE_SUFFIX)
        relFile = os.path.relpath(os.path.abspath(projFile), self.dirName)
        node.setAttribute('Path', relFile)
        
        self.rootNode.appendChild(node)

        if len(self.projects) == 1:
            self.SetActiveProject(project.GetName())

        self.Save()
        if addToBuildMatrix:
            self.AddProjectToBuildMatrix(project)

        datum = {}
        datum['node'] = XmlUtils.GetRoot(project.doc)
        datum['expand'] = 0
        datum['project'] = project
        return self.DoInsertProject(self.GetRootLineNum(0), datum)

    def CreateProjectFromTemplate(self, name, path, templateFile, cmpType = ''):
        '''从模版创建项目，若 cmpType 未指定，使用模版默认值'''
        if not self.rootNode:
            print 'No workspace open'
            return False

        if self.projects.has_key(name):
            print 'A project with the same name already exists in the '\
                    'workspace!'
            return False

        if os.path.exists(path) and not os.path.isdir(path):
            print 'Invalid Path'
            return False

        projFile = os.path.join(path, name + os.extsep + PROJECT_FILE_SUFFIX)
        if os.path.exists(projFile):
            print 'The target project file already exists on the disk, '\
                    'just add the project to workspace instead.'
            return False

        if not os.path.exists(path):
            os.makedirs(path)
        shutil.copy(templateFile, projFile)

        project = VLProject()
        project.Load(templateFile)

        for srcFile in project.GetAllFiles(True):
            # TODO; 如果有嵌套的文件夹呢？
            templateDir = os.path.dirname(templateFile)
            relSrcFile = os.path.relpath(srcFile, templateDir)
            dstFile = os.path.join(path, relSrcFile)
            # 只有目标文件不存在时才复制, 否则使用已存在的文件
            if not os.path.exists(dstFile):
                shutil.copy(srcFile, dstFile)
        project.SetName(name)
        project.fileName = projFile
        if cmpType:
            settings = project.GetSettings()
            settings.GetBuildConfiguration().SetCompilerType(cmpType)
            project.SetSettings(settings)
        project.Save()

        del project
        return self.AddProject(projFile)

    def GetStringProperty(self, propName):
        if not self.rootNode:
            print 'No workspace open'
            return ''
        
        return self.rootNode.getAttribute(propName)

    def FindProjectByName(self, projName):
        '''返回 VLProject 实例'''
        if self.projects.has_key(projName):
            return self.projects[projName]
        else:
            return None

    def GetProjectList(self):
        '''返回工作空间包含的项目的名称列表'''
        li = self.projects.keys()
        li.sort(Cmp)
        return li

    def AddProject(self, projFile):
        if not self.rootNode or not os.path.isfile(projFile):
            print 'No workspace open or file does not exist!'
            return False
        
        project = VLProject()
        project.Load(projFile)
        
        # 项目名称区分大小写
        if not self.projects.has_key(project.GetName()):
            # No project could be find, add it to the workspace
            self.projects[project.GetName()] = project
            relFile = os.path.relpath(project.fileName, self.dirName)
            node = self.doc.createElement('Project')
            node.setAttribute('Name', project.GetName())
            node.setAttribute('Path', relFile)
            node.setAttribute(
                'Active', len(self.projects) == 1 and 'Yes' or 'No')

            self.rootNode.appendChild(node)
            self.Save()
            self.AddProjectToBuildMatrix(project)

            # 仅有一个项目时，自动成为激活项目
            if len(self.projects) == 1:
                self.SetActiveProject(project.GetName())

            # 更新 filesIndex
            projectFilesIndex = project.GetFilesIndex()
            self.filesIndex.update(projectFilesIndex)
            # 更新 fname2file
            for k in projectFilesIndex.iterkeys():
                key2 = os.path.basename(k)
                if not self.fname2file.has_key(key2):
                    self.fname2file[key2] = set()
                self.fname2file[key2].add(k)

            # 更新 vimLineData
            datum = {}
            datum['node'] = XmlUtils.GetRoot(project.doc)
            datum['expand'] = 0
            datum['project'] = project
            return self.DoInsertProject(self.GetRootLineNum(0), datum)
        else:
            print "A project with a similar name " \
                    "'%s' already exists in the workspace" % (project.GetName(),)
            return False

    def RemoveProject(self, name):
        '''仅仅在 .workspace 文件中清除，不操作项目依赖，改为 Export 时忽略'''
        project = self.FindProjectByName(name)
        if not project:
            return False
        
        # remove the associated build configuration with this project
        self.RemoveProjectFromBuildMatrix(project)
        
        del self.projects[project.GetName()]
        
        # update the xml file
        for i in self.rootNode.childNodes:
            if i.nodeName == 'Project' and i.getAttribute('Name') == name:
                if i.getAttribute('Active').lower() == 'Yes'.lower():
                    # the removed project was active
                    # select new project to be active
                    if self.projects:
                        self.SetActiveProject(self.GetProjectList()[0])
                self.rootNode.removeChild(i)
                break

        # FIXME: 可不删除，而是添加的时候覆盖，生成 makefile 的时候忽略
        # go over the dependencies list of each project and remove the project
        #for i in self.projects.itervalues():
        #    #
        #    settings = i.GetSettings()
        #    if settings:
        #        configs = []
        #        for j in settings.configs.itervalues():
        #            configs.append(j.GetName())
        #
        #    # update each configuration of this project
        #    for k in configs:
        #        deps = i.GetDependencies(k)
        #        try:
        #            index = deps.index(name)
        #        except ValueError:
        #            pass
        #        else:
        #            del deps[index]
        #        
        #        # update the configuration
        #        i.SetDependencies(deps, k)
        
        self.Save()
        return True

    def GetProjBuildConf(self, projectName, confName = ''):
        '''获取名称为 projectName 的项目构建设置实例。可方便地直接获取项目设置。
        此函数获取的是构建设置的副本！主要用于创建 makefile'''
        matrix = self.GetBuildMatrix()
        projConf = confName
        
        # 如果 confName 为空，从 BuildMatrix 中获取默认的值
        if not projConf:
            wsConfig = matrix.GetSelectedConfigurationName()
            projConf = matrix.GetProjectSelectedConf(wsConfig, projectName)
        
        project = self.FindProjectByName(projectName)
        if project:
            settings = project.GetSettings()
            if settings:
                # 获取副本，用于构建
                return settings.GetBuildConfiguration(projConf, True)
        return None

    def AddProjectToBuildMatrix(self, project):
        if not project:
            return
        
        # 获取当先的工作空间构建设置
        matrix = self.GetBuildMatrix()
        selConfName = matrix.GetSelectedConfigurationName()
        
        wspList = matrix.GetConfigurations()
        # 遍历所有 BuildMatrix 设置，分别添加 project 的构建设置进去
        for i in wspList:
            # 获取 WorkspaceConfiguration 的列表（顺序不重要）
            prjList = i.GetMapping()
            wspCnfName = i.GetName()
            
            settings = project.GetSettings()
            if not settings.configs:
                # the project does not have any settings, 
                # create new one and add it
                # 凡是有 ToXmlNode 方法的类的保存方法都是添加到有 doc 属性的类中
                project.SetSettings(settings)
                settings = project.GetSettings()
                prjBldConf = settings.configs(settings.configs.keys()[0])
                matchConf = prjBldConf
            else:
                prjBldConf = settings.configs[settings.configs.keys()[0]]
                matchConf = prjBldConf
                
                # try to locate the best match to add to the workspace
                # 尝试寻找 Configuration 名字和 WorkspaceConfiguration 的名字
                # 相同的添加进去
                for k, v in settings.configs.iteritems():
                    if wspCnfName == v.GetName():
                        matchConf = v
                        break
            
            entry = ConfigMappingEntry(project.GetName(), matchConf.GetName())
            prjList.append(entry)
            # prjList 为引用，可不需设置
            #i.SetConfigMappingList(prjList)
            # i 也为引用，可不需设置
            #matrix.SetConfiguration(i)
        
        # and set the configuration name.
        matrix.SetSelectedConfigurationName(selConfName)
        self.SetBuildMatrix(matrix)
    
    def RemoveProjectFromBuildMatrix(self, project):
        matrix = self.GetBuildMatrix()
        selConfName = matrix.GetSelectedConfigurationName()

        wspList = matrix.GetConfigurations()
        for i in wspList:
            prjList = i.GetMapping()
            for j in prjList:
                if j.project == project.GetName():
                    prjList.remove(j)
                    break

        matrix.SetSelectedConfigurationName(selConfName)
        self.SetBuildMatrix(matrix)

#=====
    
    def Save(self, fileName = ''):
        '''保存 .workspace 文件，如果是默认工作空间，不保存'''
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

    def SaveAll(self, fileName = ''):
        '''保存 .workspace 文件以及所有项目的 .project 文件，
        如果是默认工作空间，不保存'''
        if not fileName and not self.fileName:
            return

        self.Save(fileName)

        for i in self.projects.itervalues():
            i.Save()

    def ConvertToNewFileFormat(self):
        if not self.fileName:
            return

        # 修改工作区文件中关于项目路径的文本
        for i in self.rootNode.childNodes:
            if i.nodeName == 'Project':
                path = i.getAttribute('Path').encode('utf-8')
                newPath = os.path.splitext(path)[0] + os.extsep \
                        + PROJECT_FILE_SUFFIX
                i.setAttribute('Path', newPath)

        newFileName = os.path.splitext(self.fileName)[0] + os.extsep \
                + WORKSPACE_FILE_SUFFIX
        self.Save(newFileName)

        for i in self.projects.itervalues():
            newFileName = os.path.splitext(i.fileName)[0] + os.extsep \
                    + PROJECT_FILE_SUFFIX
            i.Save(newFileName)


    
    #===========================================================================
    # 常规操作接口 ===== 结束
    #===========================================================================


#===============================================================================
# 外部用接口 ===== 结束
#===============================================================================


class VLWorkspaceST:
    __ins = None
    
    @staticmethod
    def Get():
        if not VLWorkspaceST.__ins:
            VLWorkspaceST.__ins = VLWorkspace()
        return VLWorkspaceST.__ins

    @staticmethod
    def Free():
        VLWorkspaceST.__ins = None



#===============================================================================

if __name__ == '__main__':
    import BuilderGnuMake
    bd = BuilderGnuMake.BuilderGnuMake()
    ws = VLWorkspaceST.Get()
    ws.OpenWorkspace(sys.argv[1])
    #print ws.activeProject
    #print ws.vimLineData
    #print ws.projects
    #print ws.modifyTime
    #print ws.name
    #print ws.DoGetDispTextByIndex(0)
    #print ws.DoGetDispTextByIndex(1)
    ws.DisplayAll(True)
    print '-'*80
    #print ws.filesIndex
    print ws.GetProjectByFileName(
        '/home/eph/Desktop/VimLite/WorkspaceMgr/Test/C++/CTest/main.c')
    #bd.Export(ws.GetDatumByLineNum(9)['project'].name, '')
    #ws.SetActiveProjectByLineNum(2)
    #ws.Expand(2)
    #ws.Expand(3)
    #ws.Expand(11)
    #ws.Fold(2)
    #ws.DisplayAll(True)
    #print '-'*80
    #ws.Expand(2)
    #ws.DisplayAll(True)
    #print '-'*80
#    ws.Expand(3)
    #ws.DisplayAll(True)
    #ws.Expand(5)
    #ws.Expand(6)
    #ws.Expand(7)
    #ws.DisplayAll(True)
    #ws.Fold(2)
    #ws.DisplayAll(True)
    #ws.Expand(2)
    #ws.DisplayAll(True)

    #print '-' * 80
    #print os.getcwd()
#    print '\n'.join(ws.GetAllDisplayTexts())
#    print ws.GetAllDisplayTexts()

