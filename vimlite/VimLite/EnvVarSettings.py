#!/usr/bin/env python
# -*- coding:utf-8 -*-

import pickle
import os.path

import Globals

CONFIG_FILE = os.path.join(Globals.VIMLITE_DIR, 'config', 'EnvVarSettings.conf')

class EnvVar:
    '''代表一个环境变量'''
    def __init__(self, string):
        self.key = ''
        self.value = ''
        self.string = string
        if string:
            self.key, op, self.value = string.partition('=')

    def GetKey(self):
        return self.key

    def GetValue(self):
        return self.value

    def GetString(self):
        return self.string


class EnvVarSettings:
    '''环境变量设置'''
    def __init__(self, fileName = ''):
        self.fileName = ''
        self.envVarSets = {} # 名称: 列表(元素为 EnvVar 类)
        self.activeSetName = '' # 当前激活项, 这个需要外部需要时修改
        self.mtime = 0 # 最后修改时间

        if fileName:
            self.Load(fileName)

    def SetFileName(self, fileName):
        self.fileName = fileName

    def SetActiveSetName(self, activeSetName):
        s1 = self.activeSetName
        self.activeSetName = activeSetName
        if s1 != activeSetName:
            self.Save()

    def GetActiveSetName(self):
        return self.activeSetName

    def GetActiveEnvVars(self):
        return self.GetEnvVars(self.GetActiveSetName())

    def GetEnvVars(self, setName):
        if self.envVarSets.has_key(setName):
            return self.envVarSets[setName]
        else:
            return []

    def NewEnvVarSet(self, setName):
        '''新建组, 若已存在, 不会清空已存在的组'''
        if not setName:
            return
        if not self.envVarSets.has_key(setName):
            self.envVarSets[setName] = []

    def DeleteEnvVarSet(self, setName):
        if self.envVarSets.has_key(setName):
            del self.envVarSets[setName]

    def DeleteAllEnvVarSets(self):
        self.envVarSets.clear()

    def AddEnvVar(self, setName, string):
        if self.envVarSets.has_key(setName) and string:
            self.envVarSets[setName].append(EnvVar(string))

    def ClearEnvVarSet(self, setName):
        if self.envVarSets.has_key(setName):
            del self.envVarSets[setName][:]

    def ExpandVariables(self, expr):
        if not '$' in expr:
            return expr

        result = expr
        for envVar in self.GetActiveEnvVars()[::-1]:
            result = result.replace('$(%s)' % envVar.GetKey(),
                                    envVar.GetValue())

        return result

    def GetModificationTime(self):
        return self.mtime

    def Print(self):
        for k, v in self.envVarSets.iteritems():
            print k + ':'
            for i in v:
                print '\t' + i.GetKey(), '=', i.GetValue()

    def Load(self, fileName = ''):
        if not fileName and not self.fileName:
            return False

        ret = False
        obj = None
        try:
            if not fileName:
                fileName = self.fileName
            f = open(fileName, 'rb')
            obj = pickle.load(f)
            f.close()
        except IOError:
            #print 'IOError:', fileName
            return False

        if obj:
            self.fileName = obj.fileName
            self.envVarSets = obj.envVarSets
            self.activeSetName = obj.activeSetName
            self.mtime = Globals.GetFileModificationTime(fileName)
            del obj
            ret = True

        return ret

    def Save(self, fileName = ''):
        if not fileName and not self.fileName:
            return False

        ret = False
        try:
            if not fileName:
                fileName = self.fileName
            dirName = os.path.dirname(fileName)
            if not os.path.exists(dirName):
                os.makedirs(dirName)
            f = open(fileName, 'wb')
            pickle.dump(self, f)
            f.close()
            self.mtime = Globals.GetFileModificationTime(fileName)
            ret = True
        except IOError:
            print 'IOError:', fileName
            return False

        return ret


class EnvVarSettingsST:
    __ins = None

    @staticmethod
    def Get():
        if not EnvVarSettingsST.__ins:
            EnvVarSettingsST.__ins = EnvVarSettings()
            # 创建默认设置
            if not EnvVarSettingsST.__ins.Load(CONFIG_FILE):
                # 文件不存在, 新建默认配置文件
                GenerateDefaultEnvVarSettings()
                EnvVarSettingsST.__ins.Save(CONFIG_FILE)
            EnvVarSettingsST.__ins.SetFileName(CONFIG_FILE)
        return EnvVarSettingsST.__ins

    @staticmethod
    def Free():
        del EnvVarSettingsST.__ins
        EnvVarSettingsST.__ins = None


def GenerateDefaultEnvVarSettings():
    # 预设值
    ins = EnvVarSettingsST.Get()
    ins.NewEnvVarSet('Default')
    ins.AddEnvVar('Default', 'CodeLiteDir=/usr/share/codelite')
    ins.AddEnvVar('Default', 'VimLiteDir=~/.vimlite')
    ins.SetActiveSetName('Default')


if __name__ == '__main__':
    ins = EnvVarSettingsST.Get()
    ins.DeleteAllEnvVarSets()
    ins.NewEnvVarSet('Default')
    ins.AddEnvVar('Default', 'CodeLiteDir=/usr/share/codelite')
    ins.AddEnvVar('Default', 'VimLiteDir=~/.vimlite$(abc)')
    ins.AddEnvVar('Default', 'abc=ABC')
    ins.Print()
    print ins.GetModificationTime()
    print ins.ExpandVariables("$(CodeLiteDir) + $(VimLiteDir) = $(abc)")

