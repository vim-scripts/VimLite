#!/usr/bin/env python
# -*- encoding:utf-8 -*-


class FileEntry:
    def __init__(self):
        self.id = -1
        self.file = ''
        self.lastRetaggedTimestamp = 0 # 可用当前时间初始化

    def SetFile(self, file):
        self.file = file

    def SetLastRetaggedTimestamp(self, lastRetaggedTimestamp):
        self.lastRetaggedTimestamp = lastRetaggedTimestamp

    def GetFile(self):
        return self.file

    def GetLastRetaggedTimestamp(self):
        return self.lastRetaggedTimestamp

    def SetId(self, id):
        self.id = id

    def GetId(self):
        return self.id


