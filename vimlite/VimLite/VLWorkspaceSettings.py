#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import pickle
import os.path

class VLWorkspaceSettings:
    '''工作空间设置'''
    # 这个设置中的头文件搜索路径和全局设置中的头文件搜索路径的关系
    INC_PATH_APPEND = 0     # 添加到全局的后面
    INC_PATH_REPLACE = 1    # 只用这个设置的
    INC_PATH_PREPEND = 2    # 添加到全局的前面
    INC_PATH_DISABLE = 3    # 只用全局设置的

    # 与上面的标志对应的字符串
    INC_PATH_FLAG_WORDS = [
        "Append",
        "Replace",
        "Prepend",
        "Disable",
    ]

    def __init__(self, fileName = ''):
        '''fileName 只在内部使用，并不会保存这个信息到硬盘文件里面'''
        if not fileName:
            self.fileName = ''
        else:
            self.fileName = os.path.abspath(fileName)
        self.includePaths = []
        self.excludePaths = []
        self.tagsTokens = [] # 宏处理符号
        self.tagsTypes = [] # 类型映射符号

        # 2012-07-19: 默认是添加到全局的后面
        self.incPathFlag = VLWorkspaceSettings.INC_PATH_APPEND

        self.envVarSetName = 'Default' # 选择的环境变量组, 默认为 'Default'

        # 2011-09-06: 批量构建数据, 保存的是"名字"到"有序的项目名称"的字典
        # 2011-09-16: 为了实现简单, 默认必须有一组空的"名字"
        self.batchBuild = {'Default': []}

        # 2012-04-22: 添加预设的 namespace 信息，
        #             因为一些恶劣的代码在头文件使用名空间
        self.nsinfo = {'nsalias': {}, 'using': {}, 'usingns': []}

        # 2012-04-22: 作为全局宏的文件
        self.macroFiles = []

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

    def GetBatchBuildList(self, name):
        if self.batchBuild.has_key(name):
            return self.batchBuild[name]
        else:
            return []

    def SetBatchBuildList(self, name, order):
        self.batchBuild[name] = order

    def GetBatchBuildNames(self):
        li = self.batchBuild.keys()
        li.sort()
        return li

    def GetUsingNamespace(self):
        return self.nsinfo['usingns']

    def SetUsingNamespace(self, usingns):
        self.nsinfo['usingns'] = usingns

    def GetMacroFiles(self):
        return self.macroFiles

    def SetMacroFiles(self, macroFiles):
        self.macroFiles = macroFiles

    def GetIncPathFlagWords(self):
        return self.INC_PATH_FLAG_WORDS

    def GetCurIncPathFlagWord(self):
        return self.INC_PATH_FLAG_WORDS[self.incPathFlag]

    def SetIncPathFlag(self, flag):
        if isinstance(flag, str):
            if flag in self.INC_PATH_FLAG_WORDS:
                self.incPathFlag = self.INC_PATH_FLAG_WORDS.index(flag)
        else: # 整数
            self.incPathFlag = flag

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
            #self.fileName = obj.fileName # 不需要保存文件名信息
            self.includePaths = obj.includePaths
            self.excludePaths = obj.excludePaths
            self.tagsTokens = obj.tagsTokens
            self.tagsTypes = obj.tagsTypes
            try:
                self.envVarSetName = obj.envVarSetName
                self.batchBuild = obj.batchBuild
                self.nsinfo = obj.nsinfo
                self.macroFiles = obj.macroFiles
                self.incPathFlag = obj.incPathFlag
            except:
                pass
            del obj
            ret = True

        return ret

    def Save(self, fileName = ''):
        if not fileName and not self.fileName:
            return False

        ret = False
        bak = self.fileName
        try:
            if not fileName:
                fileName = self.fileName
            dirName = os.path.dirname(fileName)
            if not os.path.exists(dirName):
                os.makedirs(dirName)
            f = open(fileName, 'wb')
            self.fileName = '' # 不保存文件名
            pickle.dump(self, f)
            self.fileName = bak # 恢复原始的文件名
            f.close()
            ret = True
        except IOError:
            self.fileName = bak
            print 'IOError:', fileName
            return False
        except:
            print 'Error', fileName
            self.fileName = bak
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
    #print ins.Save()
    #print ins.Load()
    print ins.includePaths
    print ins.excludePaths
    print ins.fileName
    print ins.GetIncPathFlagWords()
    print ins.GetCurIncPathFlagWord()

