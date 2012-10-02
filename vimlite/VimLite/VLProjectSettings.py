#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''这个设置和 VLWorkspaceSettings 对应，不是必要的，
主要用来保存调试器断点啊之类的信息'''

import os.path
import json
import Globals

class DebuggerSettings:
    def __init__(self, d = {}):
        self.smpBps = [] # 调试器的断点，[{'file': 'xx', 'line': 99}, ...]
        if d:
            self.FromDict(d)

    def FromDict(self, d):
        Globals.Dict2Obj(self, d)

    def ToDict(self):
        return Globals.Obj2Dict(self)

class VLProjectSetting:
    '''单个项目设置，每个项目设置名对应一个这样的实例
    例如 Debug 一个，Release 一个'''
    def __init__(self, d = {}):
        self.name = ''
        self.dbgSet = DebuggerSettings()
        if d:
            self.FromDict(d)

    def FromDict(self, d):
        self.name = d.get('name', '')
        self.dbgSet = DebuggerSettings(d.get('dbgSet', {}))

    def ToDict(self):
        d = {}
        d['name'] = self.name
        d['dbgSet'] = self.dbgSet.ToDict()
        return d

    def AddBreakpoint(self, fileName, lineNumber):
        self.dbgSet.smpBps.append({'file': fileName, 'line': lineNumber})

    def GetBreakpoints(self):
        return self.dbgSet.smpBps[:]

    def SetBreakpoints(self, bps):
        self.dbgSet.smpBps = bps[:]

    def DelBreakpoints(self):
        del self.dbgSet.smpBps[:]

class VLProjectSettings:
    def __init__(self, fileName = '', d = {}):
        self.__fileName = ''
        self.settings = {} # 名字 -> VLProjectSetting()

        if fileName:
            self.__fileName = os.path.abspath(fileName)

        if d:
            self.FromDict(d)

    def FromDict(self, d):
        self.settings = {}
        for k, v in d.get('settings', {}).iteritems():
            self.settings[k] = VLProjectSetting(v)

    def ToDict(self):
        d = {}
        d['settings'] = {}
        for k, v in self.settings.iteritems():
            d['settings'][k] = v.ToDict()
        return d

    def AddBreakpoint(self, projConfName, fileName, lineNumber):
        if not self.settings.has_key(projConfName):
            self.settings[projConfName] = VLProjectSetting()
            self.settings[projConfName].name = projConfName
        return self.settings[projConfName].AddBreakpoint(fileName, lineNumber)

    def GetBreakpoints(self, projConfName):
        if not self.settings.has_key(projConfName):
            self.settings[projConfName] = VLProjectSetting()
            self.settings[projConfName].name = projConfName
        return self.settings[projConfName].GetBreakpoints()

    def SetBreakpoints(self, projConfName, bps):
        if not self.settings.has_key(projConfName):
            self.settings[projConfName] = VLProjectSetting()
            self.settings[projConfName].name = projConfName
        return self.settings[projConfName].SetBreakpoints(bps)

    def DelBreakpoints(self, projConfName):
        if not self.settings.has_key(projConfName):
            self.settings[projConfName] = VLProjectSetting()
            self.settings[projConfName].name = projConfName
        return self.settings[projConfName].DelBreakpoints()

    def Load(self, fileName):
        try:
            f = open(fileName, 'rb')
        except:
            return False
        d = json.load(f)
        f.close()
        self.FromDict(d)
        return True

    def Save(self, fileName = ''):
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
            raise
        json.dump(self.ToDict(), f, indent=4, sort_keys=True, ensure_ascii=True)
        f.close()
        return True


def test():
    ins = VLProjectSettings()
    ins.AddBreakpoint('Debug', 'main.c', 15)
    d = ins.ToDict()
    print json.dumps(d, indent=4)
    d['settings']['abc'] = {}
    ins.FromDict(d)
    ins.DelBreakpoints('Debug')
    print json.dumps(ins.ToDict(), indent=4)
    pass

if __name__ == '__main__':
    test()

