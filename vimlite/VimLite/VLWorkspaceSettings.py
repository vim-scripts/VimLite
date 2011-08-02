#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import pickle
import os.path

class VLWorkspaceSettings:
    '''工作空间设置'''

    def __init__(self, fileName = ''):
        if not fileName:
            self.fileName = ''
        else:
            self.fileName = os.path.abspath(fileName)
        self.includePaths = []
        self.excludePaths = []
        self.tagsTokens = [] # 宏处理符号
        self.tagsTypes = [] # 类型映射符号

        self.envVarSetName = 'Default' # 选择的环境变量组, 默认为 'Default'

        # 如果指定了 fileName, 从文件载入, 不论成功与否
        self.Load()

    def SetFileName(self, fileName):
        self.fileName = fileName

    def AddTagsToken(self, tagsToken):
        self.tagsTokens.append(tagsToken)

    def RemoveTagsToken(self, index):
        try:
            del self.tagsTokens[index]
        except IndexError:
            return

    def AddTagsType(self, tagsType):
        self.tagsTypes.append(tagsType)

    def RemoveTagsType(self, index):
        try:
            del self.tagsTypes[index]
        except IndexError:
            return

    def AddIncludePath(self, path):
        self.includePaths.append(path)

    def RemoveIncludePath(self, index):
        try:
            del self.includePaths[index]
        except IndexError:
            return

    def AddExcludePath(self, path):
        self.excludePaths.append(path)

    def RemoveExcludePath(self, index):
        try:
            del self.excludePaths[index]
        except IndexError:
            return

    def GetEnvVarSetName(self):
        return self.envVarSetName

    def SetEnvVarSetName(self, envVarSetName):
        self.envVarSetName = envVarSetName

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
            self.includePaths = obj.includePaths
            self.excludePaths = obj.excludePaths
            self.tagsTokens = obj.tagsTokens
            self.tagsTypes = obj.tagsTypes
            try:
                self.envVarSetName = obj.envVarSetName
            except:
                pass
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
            ret = True
        except IOError:
            print 'IOError:', fileName
            return False

        return ret



if __name__ == '__main__':
    ins = VLWorkspaceSettings('temp.wspsettings')
    print ins.includePaths
    print ins.excludePaths
    ins.AddExcludePath('age')
    ins.AddIncludePath('aenkjle')
    print ins.includePaths
    print ins.excludePaths
    #ins.Save()
    #ins.Load()
    print ins.includePaths
    print ins.excludePaths
    print ins.fileName

