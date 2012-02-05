#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import os

##-----------------------------------------------------
## Constants
##-----------------------------------------------------

clCMD_NEW = "<New...>"
clCMD_EDIT = "<Edit...>"
# clCMD_DELETE = "<Delete...>"  #Unused

# constant message
BUILD_START_MSG             = "----------Build Started--------\n"
BUILD_END_MSG               = "----------Build Ended----------\n"
BUILD_PROJECT_PREFIX        = "----------Building project:[ "
CLEAN_PROJECT_PREFIX        = "----------Cleaning project:[ "
SEARCH_IN_WORKSPACE         = "Entire Workspace"
SEARCH_IN_PROJECT           = "Active Project"
SEARCH_IN_CURR_FILE_PROJECT = "Current File's Project"
SEARCH_IN_CURRENT_FILE      = "Current File"

USE_WORKSPACE_ENV_VAR_SET   = "<Use Defaults>"
USE_GLOBAL_SETTINGS         = "<Use Defaults>"

# TODO
TERMINAL_CMD = ""

PATH_SEP = os.sep


def IsSourceFile(ext):
    return ext == 'cpp' or ext == 'cxx' or ext == 'c' or ext == 'c++' or ext == 'cc'


def BoolToString(bool):
    if bool:
        return 'yes'
    else:
        return 'no'

