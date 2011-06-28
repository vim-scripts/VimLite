#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import BuildSettings

class Builder:
    '''this class defines the interface of a build system
    
    理论上可用于任何的构建工具，暂时支持 gnumake'''
    def __init__(self, name, buildTool, buildToolOptions):
        self.name = name
        self.buildTool = buildTool
        self.buildToolOptions = buildToolOptions
        self.buildToolJobs = ''
        self.isActive = False
        
        # override values from configuration file
        config = BuildSettings.BuildSettingsST.Get().GetBuilderConfig(self.name)
        if config:
            self.buildTool = config.toolPath
            self.buildToolOptions = config.toolOptions
            self.buildToolJobs = config.toolJobs
            self.isActive = config.isActive
        else:
            self.isActive = (self.name == 'GNU makefile for g++/gcc')
        
    def SetBuildTool(self, buildTool):
        self.buildTool = buildTool
    
    def SetBuildToolOptions(self, buildToolOptions):
        self.buildToolOptions = buildToolOptions
    
    def SetBuildToolJobs(self, buildToolJobs):
        self.buildToolJobs = buildToolJobs
    
    def NormalizeConfigName(self, configName):
        normalized = configName.strip()
        normalized = normalized.replace(' ', '_')
        return normalized
    
    def GetName(self):
        return self.name

    # ================ API ==========================
    # The below API as default implementation, but can be
    # overrided in the derived class
    # ================ API ==========================

    def SetActive(self):
        '''set this builder as the active builder.
        It also makes sure that all other builders are set as non-active'''
        # TODO: BuilderManager
        pass
    
    def IsActive(self):
        return self.isActive
    
    def GetBuildToolCommand(self, isCommandLineCmd):
        return self.buildTool
    
    def GetBuildToolName(self):
        return self.buildTool
    
    def GetBuildToolOptions(self):
        return self.buildToolOptions
    
    def GetBuildToolJobs(self):
        return self.buildToolJobs

    # ================ API ==========================
    # The below API must be implemented by the
    # derived class
    # ================ API ==========================

    def Export(self, project, confToBuild, isProjectOnly, force, errMsg):
        pass
    
    def GetCleanCommand(self, project, confToBuild):
        pass
    
    def GetBuildCommand(self, project, confToBuild):
        pass
    
    ##-----------------------------------------------------------------
    ## Project Only API
    ##-----------------------------------------------------------------
        
    def GetPOCleanCommand(self, project, confToBuild):
        '''Return the command that should be executed for performing the clean
        task - for the project only (excluding dependencies'''
        pass
    
    def GetPOBuildCommand(self, project, confToBuild):
        pass
    
    def GetSingleFileCmd(self, project, confToBuild, fileName):
        '''create a command to execute for compiling single source file'''
        pass
    
    def GetPreprocessFileCmd(self, project, confToBuild, fileName):
        '''create a command to execute for preprocessing single source file'''
        pass
    
    def GetPORebuildCommand(self, project, confToBuild):
        pass
    
    
    
    
    
    
    
    
    
    
    
