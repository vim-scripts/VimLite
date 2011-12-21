#!/usr/bin/env python
# -*- coding:utf-8 -*-

from BuildSettings import BuildSettingsST
import BuilderGnuMake


class BuilderManager(object):
    '''管理所有抽象 Builder'''
    def __init__(self):
        self.builders = {} # 保存所有 Builder 实例，{名字: 实例}

    def AddBuilder(self, builder):
        self.builders[builder.GetName()] = builder

    def GetBuilderByName(self, name):
        return self.builders.get(name)

    def GetActiveBuilder(self):
        '''从配置文件中获取'''
        activeBuilderSettings = BuildSettingsST.Get().GetActiveBuilderSettings()
        if not activeBuilderSettings:
            print "No active Builder"
            return None

        # 需要从配置文件读取必要信息
        builderIns = self.GetBuilderByName(activeBuilderSettings.GetName())
        builderIns.LoadFromBuilderSettings(activeBuilderSettings)
        return builderIns


class BuilderManagerST:
    __ins = None
    
    @staticmethod
    def Get():
        if not BuilderManagerST.__ins:
            BuilderManagerST.__ins = BuilderManager()
            # 注册可用的 Builder
            BuilderManagerST.__ins.AddBuilder(BuilderGnuMake.BuilderGnuMake())
        return BuilderManagerST.__ins

    @staticmethod
    def Free():
        BuilderManagerST.__ins = None


