#!/usr/bin/env python
# -*- coding:utf-8 -*-

from ctypes import *
import os.path

def GetCharPStr(charp):
    i = 0
    l = []
    while charp[i] != '\0':
        l.append(charp[i])
        i += 1
    return ''.join(l)

def GetLibCxxParser():
    '''通过 sys.argv[1] 传递库路径'''
    import platform
    OSName = platform.system()
    try:
        import vim
        import sys
        #print sys.argv
        library = sys.argv[1]
        return CDLL(library)
    except:
        return CDLL(os.path.expanduser("~/libCxxParser.so"))

libCxxParser = GetLibCxxParser()

CxxHWParser_Create = libCxxParser.CxxHWParser_Create
CxxHWParser_Create.restype = c_void_p
CxxHWParser_Create.argtypes = [c_char_p]

CxxHWParser_Destroy = libCxxParser.CxxHWParser_Destroy
CxxHWParser_Destroy.argtypes = [c_void_p]

CxxOmniCpp_Create = libCxxParser.CxxOmniCpp_Create
CxxOmniCpp_Create.restype = c_void_p
CxxOmniCpp_Create.argtypes = [c_void_p, c_char_p]

CxxOmniCpp_Destroy = libCxxParser.CxxOmniCpp_Destroy
CxxOmniCpp_Destroy.argtypes = [c_void_p]

CxxOmniCpp_GetSearchScopes = libCxxParser.CxxOmniCpp_GetSearchScopes
CxxOmniCpp_GetSearchScopes.restype = c_char_p
CxxOmniCpp_GetSearchScopes.argtypes = [c_void_p]

GetScopeStack = libCxxParser.GetScopeStack
GetScopeStack.restype = POINTER(c_char)
GetScopeStack.argtypes = [c_char_p]

#pParser = CxxHWParser_Create("test");
#print pParser

#pResult = CxxOmniCpp_Create(pParser, "hello");
#print pResult

#print CxxOmniCpp_GetSearchScopes(pResult)

#CxxOmniCpp_Destroy(pResult);
#pResult = None
#CxxHWParser_Destroy(pParser)
#pParser = None

if __name__ == "__main__":
    import sys
    if not sys.argv[1:]:
        print "usage: %s {file} [line]" % sys.argv[0]
        sys.exit(1)

    line = 1000000
    if sys.argv[1:]:
        fn = sys.argv[1]
        if sys.argv[2:]:
            line = int(sys.argv[2])

    f = open(fn)
    allLines = f.readlines()
    f.close()
    lines = ''.join(allLines[: line])
    #print lines
    print GetCharPStr(GetScopeStack(lines))

