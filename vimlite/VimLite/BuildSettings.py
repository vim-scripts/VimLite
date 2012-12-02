#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''Build 设置，包含编译器和构建器
所谓编译器（compiler）就是 gcc，vc++，cobra 之类的
所谓构建器（builder）就是 gnu make，nmake 之类的'''

from Globals import Obj2Dict, Dict2Obj
import Compiler
import Builder
import Globals
import json
import os.path

CONFIG_FILE = os.path.join(Globals.VIMLITE_DIR, 'config', 'BuildSettings.jcnf')
DEFAULT_BUILDER = "GNU makefile for g++/gcc"

class BuildSettings:
    def __init__(self, d = {}):
        self.__fileName = "" # 对应的配置文件名，理论上必须是绝对路径
        self.version = 300 # 3.0.0
        self.compilers = [] # 支持的编译器列表，元素是字典
        self.builders = [] # 支持的构建器列表，元素是字典
        self.activeBuilder = DEFAULT_BUILDER # 默认构建器的名字

        #self.__compilers = [] # 元素是 Compiler 实例
        #self.__builders = [] # 元素是 Builder 实例

        if d:
            self.FromDict(d)

    def ToDict(self):
        return Obj2Dict(self)

    def FromDict(self, d):
        Dict2Obj(self, d)

    def SetFileName(self, fileName):
        self.__fileName = fileName

    def GetCompilerNameList(self):
        '''返回编译器名称列表'''
        li = []
        for cmpl in self.compilers:
            li.append(cmpl['name'])
        li.sort()
        return li

    def GetCompilerByName(self, name):
        '''返回的是实例'''
        for i in self.compilers:
            if i["name"] == name:
                return Compiler.Compiler(i)
        return None

    def SetCompilerByName(self, cmpl, name):
        '''设置编译器，例如修改了编译器的配置
        cmpl 是 Compiler 实例或者字典'''
        if isinstance(cmpl, dict):
            cmpl = Compiler.Compiler(cmpl)
        dstIdx = -1
        for idx, elm in enumerate(self.compilers):
            if elm["name"] == name:
                dstIdx = idx
                break
        if dstIdx != -1:
            self.compilers[dstIdx] = cmpl.ToDict()

    def GetBuilderNameList(self):
        li = []
        for blder in self.builders:
            li.append(blder['name'])
        li.sort()
        return li

    def GetBuilderByName(self, name):
        '''返回的是基类实例'''
        for i in self.builders:
            if i["name"] == name:
                return Builder.Builder(i)
        return None

    def SetBuilderByName(self, bder, name):
        if isinstance(bder, dict):
            bder = Builder(bder)
        dstIdx = -1
        for idx, elm in enumerate(self.builders):
            if elm["name"] == name:
                dstIdx = idx
                break
        if dstIdx != -1:
            self.builders[dstIdx] = bder.ToDict()

    def GetActiveBuilderInstance(self):
        '''获取当前激活的构建器实例'''
        return self.GetBuilderByName(self.activeBuilder)

    def SetActiveBuilder(self, bderName):
        self.activeBuilder = bderName

    def Load(self, fileName):
        try:
            f = open(fileName, "rb")
        except:
            return False

        d = json.load(f)
        f.close()
        self.FromDict(d)
        return True

    def Save(self, fileName = ""):
        if not fileName and not self.__fileName:
            return False

        if not fileName:
            fileName = self.__fileName
        try:
            dirName = os.path.dirname(fileName)
            if dirName and not os.path.exists(dirName):
                os.makedirs(dirName)
            f = open(fileName, "wb")
        except IOError:
            print "IOError:", fileName
            raise IOError
        json.dump(self.ToDict(), f, indent=4, sort_keys=True, ensure_ascii=True)
        f.close()
        return True


class BuildSettingsST:
    __ins = None

    @staticmethod
    def Get():
        if not BuildSettingsST.__ins:
            BuildSettingsST.__ins = BuildSettings()
            # 载入默认设置
            BuildSettingsST.__ins.Load(CONFIG_FILE)
            BuildSettingsST.__ins.SetFileName(CONFIG_FILE)
        return BuildSettingsST.__ins

    @staticmethod
    def Free():
        BuildSettingsST.__ins = None


# ============================================================================
def test():
    global CONFIG_FILE
    CONFIG_FILE = "BuildSettings.jcnf"
    ins = BuildSettings()
    print ins.ToDict()
    #print ins.Save("BuildSettings.jcnf")
    #ins = BuildSettingsST.Get()
    #print json.dumps(BuildSettingsST.Get().ToDict())
    print BuildSettingsST.Get().GetCompilerNameList()
    print BuildSettingsST.Get().GetBuilderNameList()

if __name__ == "__main__":
    test()
