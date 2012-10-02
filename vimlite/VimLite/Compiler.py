#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''编译器对象，很简单的设计'''

from Globals import Obj2Dict, Dict2Obj
import json

class Compiler:
    def __init__(self, d = {}):
        ''''''
        self.name = ''
        self.version = 300
        #self.cCompiler = ''
        #self.cxxCompiler = ''
        #self.linker = ''
        #self.archiver = ''

        # 编译命令
        self.cCmpCmd = ''
        self.cxxCmpCmd = ''
        # 预处理命令
        self.cPrpCmd = ''
        self.cxxPrpCmd = ''
        # 依赖生成命令
        self.cDepGenCmd = ''
        self.cxxDepGenCmd = ''
        # 二进制链接命令
        self.linkCmd = ''
        # 静态库生成命令
        self.arGenCmd = ''
        # 动态库生成命令
        self.soGenCmd = ''

        # 对象文件后缀
        self.objExt = ''
        # 依赖文件后缀
        self.depExt = ''
        # 预处理文件后缀
        self.prpExt = ''

        # 'PATH' 环境变量，当使用多个编译器版本的时候，就靠这个变量来分辨的了
        self.PATH = ''
        # 环境设置命令，主要用来支持 vc 编译器
        self.envSetupCmd = ''
        # 这个编译器指定的头文件包含路径，分号 ';' 分割
        self.includePaths = ''
        # 这个编译器指定的库文件搜索路径，分号 ';' 分割
        self.libraryPaths = ''

        # 一些必要的模式
        self.incPat = '' # -I$(Dir)
        self.macPat = '' # -D$(Mac)
        self.lipPat = '' # -L$(Lip)
        self.libPat = '' # -l$(lib)

        if d:
            self.FromDict(d)

    def ToDict(self):
        '''把对象转为字典，用于保存之类的'''
        return Obj2Dict(self)

    def FromDict(self, d):
        '''从字典的内容修改自身，例如读取配置的时候'''
        Dict2Obj(self, d)

    def LoadFromJson(self, fileName):
        if not fileName:
            return False

        try:
            f = open(fileName, "rb")
        except:
            return False

        d = json.load(f)
        f.close()
        self.FromDict(d)
        return True


    def SaveAsJson(self, fileName):
        if not fileName:
            return False

        try:
            f = open(fileName, "wb")
        except:
            return False

        d = self.ToDict()
        json.dump(d, f, indent=4, sort_keys=True, ensure_ascii=True)
        f.close()
        return True


if __name__ == '__main__':
    cmpl = Compiler()
    #cmpl.name = 'gnu gcc'
    #cmpl.cCompiler = 'gcc'
    #cmpl.SaveAsJson('test.json')
    #del cmpl
    #cmpl = Compiler()
    #cmpl.LoadFromJson('test.json')
    #print cmpl.name
    #print cmpl.cCompiler
    print json.dumps(cmpl.ToDict(), indent=4, sort_keys=True)

