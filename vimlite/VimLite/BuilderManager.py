#!/usr/bin/env python
# -*- coding:utf-8 -*-

from BuildSettings import BuildSettingsST
import BuilderGnuMake


class BuilderManager(object):
    '''管理所有抽象 Builder'''
    def __init__(self):
        self.builders = {} # 保存所有 Builder 实例，{名字: 实例}

    def AddBuilder(self, builder):
        self.builders[builder.name] = builder

    def GetBuilderByName(self, name):
        return self.builders.get(name)

    def GetActiveBuilderInstance(self):
        '''从配置文件中获取'''
        blder = BuildSettingsST.Get().GetActiveBuilderInstance()
        if not blder:
            print "No active Builder"
            return None

        # 理论上基类的配置是适用于所有派生类的
        return BuilderGnuMake.BuilderGnuMake(blder.ToDict())


class BuilderManagerST:
    __ins = None
    
    @staticmethod
    def Get():
        if not BuilderManagerST.__ins:
            BuilderManagerST.__ins = BuilderManager()
            # 注册可用的 Builder 抽象类
            # 所有设置是默认值，需要从配置文件读取设置值
            BuilderManagerST.__ins.AddBuilder(BuilderGnuMake.BuilderGnuMake())
        return BuilderManagerST.__ins

    @staticmethod
    def Free():
        BuilderManagerST.__ins = None


