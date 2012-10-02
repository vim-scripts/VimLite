#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''构建器对象'''

from Globals import Obj2Dict, Dict2Obj

class Builder:
    '''构建器基类'''
    def __init__(self, d = {}):
        self.name = "" # 名称
        self.command = "" # 命令，这个命令会交给 shell 解析，所以可以是任何命令

        if d:
            self.FromDict(d)

    def ToDict(self):
        return Obj2Dict(self)

    def FromDict(self, d):
        Dict2Obj(self, d)

    # ================ API ==========================
    # The below API must be implemented by the
    # derived class
    # ================ API ==========================

    def Export(self, projName, wspConfName = '', force = False):
        '''导出 Makefile 的接口，这个不算通用接口吧？！'''
        assert False

    def GetPrepFileCmd(self, projName, fileName, wspConfName = ''):
        '''create a command to execute for preprocessing single source file'''
        assert False

    def GetCmplFileCmd(self, projName, fileName, wspConfName = ''):
        '''create a command to execute for compiling single source file'''
        assert False

    def GetBuildCommand(self, projName, wspConfName = ''):
        assert False

    def GetCleanCommand(self, projName, wspConfName = ''):
        assert False

    def GetBatchBuildCommand(self, projNames, wspConfName = ''):
        '''获取批量构建的命令'''
        assert False

    def GetBatchCleanCommand(self, projNames, wspConfName = ''):
        '''获取批量清理的命令'''
        assert False

