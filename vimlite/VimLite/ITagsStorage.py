#!/usr/bin/env python
# -*- encoding:utf-8 -*-



class ITagsStorage:
    '''ITagsStorage defined the tags storage API used by vimlite'''
    OrderNone = 0
    OrderAsc = 1
    OrderDesc = 2

    TagOk = 10
    TagExist = 11
    TagError = 12

    def __init__(self):
        self.fileName = ''
        self.singleSearchLimit = 1000
        self.maxWorkspaceTagToColour = 1000
        self.useCache = False

    def SetUseCache(self, useCache):
        self.useCache = useCache

    def GetUseCache(self):
        return self.useCache

    def GetDatabaseFileName(self):
        return self.fileName

    def SetSingleSearchLimit(self, singleSearchLimit):
        if singleSearchLimit < 0:
            singleSearchLimit = 1000
        self.singleSearchLimit = singleSearchLimit

    def GetSingleSearchLimit(self):
        return self.singleSearchLimit

    def SetMaxWorkspaceTagToColour(self, maxWorkspaceTagToColour):
        self.maxWorkspaceTagToColour = maxWorkspaceTagToColour

    def GetMaxWorkspaceTagToColour(self):
        return self.maxWorkspaceTagToColour





class StorageCacheEnabler:
    '''helper class to turn on/off storage cache flag'''
    def __init__(self, storage):
        self.storage = storage
        if self.storage:
            self.storage.SetUseCache(True)

    def __del__(self):
        if self.storage:
            self.storage.SetUseCache(False)
            self.storage = None



