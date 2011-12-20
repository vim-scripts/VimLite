#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import sys
import os.path
import threading
import re
import time
from clang import cindex
from clang.cindex import CursorKind
from clang.cindex import TranslationUnit

# 当前文件（缓冲区）的编译选项，即使获取，为了效率，这个变量必须为列表
#lUserOpts = vim.eval('b:VIM_ClangUserOpts')

# TranslationUnit.codeComplete() -> CodeCompletionResults
# iter(CodeCompletionResults).next() -> CodeCompletionResult
# CodeCompletionResult.string -> CompletionString
# iter(CompletionString).next -> CompletionChunk
# CompletionChunk.spelling -> text needed by vim

sys.path.append(os.path.dirname(__file__))

def GetTypedText(iCompletionString):
    '''strings 是 CompletionString 实例，迭代后是 CompletionChunk 的实例'''
    li = filter(lambda x: x.isKindTypedText(), iCompletionString)
    if li:
        return li[0].spelling
    else:
        return ''

def GetResultType(iCompletionString):
    li = filter(lambda x: x.isKindResultType(), iCompletionString)
    if li:
        return li[0].spelling
    else:
        return ''

def GetQuickFixItem(diagnostic):
    # Some diagnostics have no file, e.g. "too many errors emitted, stopping now"
    if diagnostic.location.file:
        sFileName = os.path.normpath(diagnostic.location.file.name)
    else:
        sFileName = ''

    if diagnostic.severity == diagnostic.Ignored:
        sType = 'I'
    elif diagnostic.severity == diagnostic.Note:
        sType = 'I'
    elif diagnostic.severity == diagnostic.Warning:
        sType = 'W'
    elif diagnostic.severity == diagnostic.Error:
        sType = 'E'
    elif diagnostic.severity == diagnostic.Fatal:
        sType = 'E'
    else:
        return None

    return {'filename': sFileName,
            'lnum': diagnostic.location.line,
            'col': diagnostic.location.column,
            'text': diagnostic.spelling,
            'type': sType}


def GetCalltipsFromCCResults(sFuncName, iCCResults):
    lCalltips = []

    # 理论上，这里基本上过滤完毕
    results = filter(lambda x: GetTypedText(x.string) == sFuncName,
                     iCCResults.results)
    for result in results:
        #kind = result.kind
        iCompletionString = result.string

        sCalltips = ' '.join([i.spelling for i in iCompletionString])

        #sCalltips = ''
        #sTypedText = ''

        #bSkip = False

        # 如果是函数的话，就添加 calltips 作为info
        #if kind in (CursorKind.CXX_METHOD, CursorKind.DESTRUCTOR,
                    #CursorKind.CONSTRUCTOR, CursorKind.FUNCTION_DECL):
        #for chunk in iCompletionString:
            # NOTE: chunk 不一定有 TypedText
            #if chunk.isKindTypedText():
                #sTypedText = chunk.spelling
                #if sTypedText != sFuncName:
                    #bSkip = True
                    #break

            #sCalltips += '%s ' % chunk.spelling

        #if bSkip:
            #continue

        #print iCompletionString
        if sCalltips:
            lCalltips.append(sCalltips)

    return lCalltips


def GetCalltipsFromFilteredResults(sFuncName, results):
    lCalltips = []

    # 理论上，这里基本上过滤完毕
    results = filter(lambda x: GetTypedText(x.string) == sFuncName, results)
    for result in results:
        iCompletionString = result.string

        sCalltips = ' '.join([i.spelling for i in iCompletionString])

        if sCalltips:
            lCalltips.append(sCalltips)

    return lCalltips


class UpdateTUThread(threading.Thread):
    def __init__(self, sFileName, lArgs, lUnsavedFiles, index, tus,
                 bReparse = False, bRebuild = False):
        '''
        bReparse 更新 tu，是 tu.reparse()
        bRebuild 重建 tu，是 index.parse()，当编译选项修改之后就需要重建 tu
        bRebuild 为真时，无视 bRebuild 的真假
        '''
        threading.Thread.__init__(self)
        self.lock = threading.Lock()
        self.sFileName = sFileName
        self.lArgs = lArgs
        self.lUnsavedFiles = lUnsavedFiles
        self.bReparse = bReparse # 到底什么时候才需要 tu.reparse() ？
        self.bRebuild = bRebuild

        self.index = index
        self.tus = tus # 引用外部的，会直接修改
        self.tu = None

    def run(self):
        tu = None
        self.lock.acquire()

        #if True:
        try:
            if not self.bRebuild and self.sFileName in self.tus:
            # 仅当非重建翻译单元时
                tu = self.tus[self.sFileName]
                if self.bReparse:
                    tu.reparse(self.lUnsavedFiles)
            else:
                # 新建翻译单元
                # 为了效率，nFlags 是必需的
                nFlags = TranslationUnit.PrecompiledPreamble \
                        | TranslationUnit.CXXPrecompiledPreamble
                nFlags |= TranslationUnit.DetailedPreprocessingRecord
                #nFlags |= TranslationUnit.Incomplete
                #nFlags |= TranslationUnit.CacheCompletionResults
                tu = self.index.parse(self.sFileName,
                                      self.lArgs,
                                      self.lUnsavedFiles,
                                      nFlags)
                if tu:
                    # Reparse to initialize the PCH cache for auto completion.
                    # This should be done by index.parse(), however it is not.
                    # So we need to reparse ourselves.
                    # 初始化的时候，直接通过 reparse 生成一次 PCH
                    # index.parse() 的时候并不会生成 PCH
                    tu.reparse(self.lUnsavedFiles)
                    self.tus[self.sFileName] = tu
                else:
                    print 'cindex.Index parse %s failed. arguments are: "%s"' \
                            % (self.sFileName, ' '.join(self.lArgs))
        except:
            print "UpdateTUThread() failed"

        self.tu = tu
        self.lock.release()


class VIMClangCCIndex(object):
    '''对应单个 cindex.Index'''
    def __init__(self):
        self.index = cindex.Index.create(False)
        self.tus = {} # {文件名绝对路径: tu, [, ...]}，不能直接修改
        self.lArgs = [] # 传给 clang 的参数列表 ['-D_DEBUG', ...]
        self.cacheCCResults = None # 最近一次的结果
        self.cacheResults = []

        self.updateThread = threading.Thread()
        self.updateThread.start()

        # 标识编译参数最后修改的时间
        self.fArgsMTime = time.time()

    def SetArgs(self, lArgs):
        self.lArgs = lArgs
        self.fArgsMTime = time.time()

    def GetArgs(self):
        return self.lArgs

    def SetParseArgs(self, lArgs):
        return self.SetArgs(lArgs)

    def GetParseArgs(self):
        return self.GetArgs()

    def GetArgsMTime(self):
        return self.fArgsMTime

    def AsyncUpdateTranslationUnit(self, sAbsFileName, lUnsavedFiles = [],
                                   bReparse = False, bRebuild = False):
        '''异步更新指定文件的翻译单元，如果没有对应的 tu，新建
        
        lUnsavedFiles = [(sName, file/str) [, ...]]
        '''
        # 同时只能有一个异步更新，如果请求多个，会阻塞
        # TODO: 做成更新队列
        try:
            self.updateThread.join()
        except RuntimeError:
            pass

        self.updateThread = UpdateTUThread(sAbsFileName,
                                           self.lArgs,
                                           lUnsavedFiles,
                                           self.index,
                                           self.tus,
                                           bReparse,
                                           bRebuild)
        self.updateThread.start()

    def UpdateTranslationUnit(self, sAbsFileName, lUnsavedFiles = [],
                              bReparse = False, bRebuild = False):
        '''同步更新翻译单元'''
        self.AsyncUpdateTranslationUnit(sAbsFileName, lUnsavedFiles,
                                        bReparse, bRebuild)
        self.JoinUpdateThread()

    def IsUpdateThreadAlive(self):
        return self.updateThread.isAlive()

    def JoinUpdateThread(self, timeout=None):
        return self.updateThread.join(timeout)

    def GetCurrentTranslationUnit(self, sAbsFileName, lUnsavedFiles = [],
                                  bReparse = False):
        '''获取指定参数的最新的翻译单元，获取翻译单元的唯一接口'''
        self.UpdateTranslationUnit(sAbsFileName, lUnsavedFiles, bReparse)
        self.recentTU = self.updateThread.tu
        return self.recentTU

    def GetTUCodeCompleteResults(self, sFileName, nLine, nCol,
                                 lUnsavedFiles = [], nFlags = 0):
        '''获取翻译单元的代码补全结果'''
        tu = self.GetCurrentTranslationUnit(sFileName, lUnsavedFiles, False)
        if not tu:
            return None

        ccr = tu.codeComplete(sFileName, nLine, nCol, lUnsavedFiles, nFlags)
        self.cacheCCResults = ccr
        return ccr

    def GetVimCodeCompleteResults(self, sFileName, nLine, nCol,
                                  lUnsavedFiles = [],
                                  sBase = '',
                                  bIgnoreCase = True,
                                  nFlags = 0):
        '''获取 vim 用的代码补全的结果'''
        ccr = self.GetTUCodeCompleteResults(sFileName, nLine, nCol,
                                            lUnsavedFiles, nFlags)
        lVimResults = []
        if bIgnoreCase:
            icase = 1
        else:
            icase = 0

        results = ccr.results

        # 如果要求匹配部分字符串，先过滤一次
        if sBase:
            print sBase
            if bIgnoreCase:
                patBase = re.compile('^' + sBase, re.IGNORECASE)
            else:
                patBase = re.compile('^' + sBase)
            results = filter(lambda x: patBase.match(GetTypedText(x.string)),
                             results)

        self.cacheResults = results

        for result in results:
            dVimResult = {}

            # 当前补全项目的类型
            kind = result.kind

            iCompletionString = result.string

            sMenu = ''
            sTypedText = ''

            # 如果是函数的话，就添加 calltips 作为info
            if kind in (CursorKind.CXX_METHOD, CursorKind.DESTRUCTOR,
                        CursorKind.CONSTRUCTOR, CursorKind.FUNCTION_DECL):
                #for chunk in iCompletionString:
                    #if chunk.isKindTypedText():
                        #sTypedText = chunk.spelling + '()'
                    #sMenu += '%s ' % chunk.spelling
                sTypedText = GetTypedText(iCompletionString) + '()'
                sMenu += GetResultType(iCompletionString)
            else:
                sTypedText = GetTypedText(iCompletionString)
                sMenu += GetResultType(iCompletionString)

            dVimResult['word'] = sTypedText
            #dVimResult['abbr'] = sTypedText
            dVimResult['menu'] = Availabilitys.get(
                str(iCompletionString.availability), 'X')
            #dVimResult['info'] = iCompletionString
            #dVimResult['info'] = sMenu
            dVimResult['menu'] += ' ' + sMenu
            dVimResult['kind'] = kinds[result.cursorKind]
            dVimResult['icase'] = icase
            dVimResult['dup'] = 0

            lVimResults.append(dVimResult)

        return lVimResults

    def GetCalltipsFromCacheCCResults(self, sFuncName):
        return GetCalltipsFromCCResults(sFuncName, self.cacheCCResults)

    def GetCalltipsFromCacheFilteredResults(self, sFuncName):
        return GetCalltipsFromFilteredResults(sFuncName, self.cacheResults)

    def GetVimQucikFixListFromRecentTU(self):
        tu = self.updateThread.tu
        if tu:
            return filter(None, map(GetQuickFixItem, tu.diagnostics))
        else:
            return []

    def GetSymbolDeclarationLocation(self, sFileName, nLine, nCol,
                                     lUnsavedFiles = [], bReparse = False):
        '''返回字典，若获取失败，返回空字典'''
        tu = self.GetCurrentTranslationUnit(sFileName, lUnsavedFiles, bReparse)
        if not tu:
            return {}
        cursor = tu.getCursor(
            tu.getLocation(tu.getFile(sFileName), nLine, nCol))
        if not cursor:
            return {}
        declCursor = cursor.get_referenced()
        if declCursor:
            #return (declCursor.location.file.name, declCursor.location.line,
                    #declCursor.location.column, declCursor.location.offset)
            return {'filename': declCursor.location.file.name,
                    'line': declCursor.location.line,
                    'column': declCursor.location.column,
                    'offset': declCursor.location.offset}
        else:
            return {}

    def GetSymbolDefinitionLocation(self, sFileName, nLine, nCol,
                                     lUnsavedFiles = [], bReparse = False):
        tu = self.GetCurrentTranslationUnit(sFileName, lUnsavedFiles, bReparse)
        if not tu:
            return {}
        cursor = tu.getCursor(
            tu.getLocation(tu.getFile(sFileName), nLine, nCol))
        if not cursor:
            return {}
        declCursor = cursor.get_definition()
        if declCursor:
            #return (declCursor.location.file.name, declCursor.location.line,
                    #declCursor.location.column, declCursor.location.offset)
            return {'filename': declCursor.location.file.name,
                    'line': declCursor.location.line,
                    'column': declCursor.location.column,
                    'offset': declCursor.location.offset}
        else:
            return {}


Availabilitys = {
    "Available" : '+',
    "Deprecated": '!',
    "NotAvailable": 'x',
    "NotAccessible": '-'}


# CodeCompletionResult.cursorKind -> vim 补全结果类型的字典
kinds = {                                                                      \
# Declarations                                                                 \
 1 : 't',  # CXCursor_UnexposedDecl (A declaration whose specific kind is not  \
           # exposed via this interface)                                       \
 2 : 't',  # CXCursor_StructDecl (A C or C++ struct)                           \
 3 : 't',  # CXCursor_UnionDecl (A C or C++ union)                             \
 4 : 't',  # CXCursor_ClassDecl (A C++ class)                                  \
 5 : 't',  # CXCursor_EnumDecl (An enumeration)                                \
 6 : 'm',  # CXCursor_FieldDecl (A field (in C) or non-static data member      \
           # (in C++) in a struct, union, or C++ class)                        \
 7 : 'e',  # CXCursor_EnumConstantDecl (An enumerator constant)                \
 8 : 'f',  # CXCursor_FunctionDecl (A function)                                \
 9 : 'v',  # CXCursor_VarDecl (A variable)                                     \
10 : 'a',  # CXCursor_ParmDecl (A function or method parameter)                \
11 : '11', # CXCursor_ObjCInterfaceDecl (An Objective-C @interface)            \
12 : '12', # CXCursor_ObjCCategoryDecl (An Objective-C @interface for a        \
           # category)                                                         \
13 : '13', # CXCursor_ObjCProtocolDecl (An Objective-C @protocol declaration)  \
14 : '14', # CXCursor_ObjCPropertyDecl (An Objective-C @property declaration)  \
15 : '15', # CXCursor_ObjCIvarDecl (An Objective-C instance variable)          \
16 : '16', # CXCursor_ObjCInstanceMethodDecl (An Objective-C instance method)  \
17 : '17', # CXCursor_ObjCClassMethodDecl (An Objective-C class method)        \
18 : '18', # CXCursor_ObjCImplementationDec (An Objective-C @implementation)   \
19 : '19', # CXCursor_ObjCCategoryImplDecll (An Objective-C @implementation    \
           # for a category)                                                   \
20 : 't',  # CXCursor_TypedefDecl (A typedef)                                  \
21 : 'f',  # CXCursor_CXXMethod (A C++ class method)                           \
22 : 'n',  # CXCursor_Namespace (A C++ namespace)                              \
23 : '23', # CXCursor_LinkageSpec (A linkage specification, e.g. 'extern "C"') \
24 : '+',  # CXCursor_Constructor (A C++ constructor)                          \
25 : '~',  # CXCursor_Destructor (A C++ destructor)                            \
26 : '26', # CXCursor_ConversionFunction (A C++ conversion function)           \
27 : 'a',  # CXCursor_TemplateTypeParameter (A C++ template type parameter)    \
28 : 'a',  # CXCursor_NonTypeTemplateParameter (A C++ non-type template        \
           # parameter)                                                        \
29 : 'a',  # CXCursor_TemplateTemplateParameter (A C++ template template       \
           # parameter)                                                        \
30 : 'f',  # CXCursor_FunctionTemplate (A C++ function template)               \
31 : 'p',  # CXCursor_ClassTemplate (A C++ class template)                     \
32 : '32', # CXCursor_ClassTemplatePartialSpecialization (A C++ class template \
           # partial specialization)                                           \
33 : 'n',  # CXCursor_NamespaceAlias (A C++ namespace alias declaration)       \
34 : '34', # CXCursor_UsingDirective (A C++ using directive)                   \
35 : '35', # CXCursor_UsingDeclaration (A using declaration)                   \
                                                                               \
# References                                                                   \
40 : '40', # CXCursor_ObjCSuperClassRef                                        \
41 : '41', # CXCursor_ObjCProtocolRef                                          \
42 : '42', # CXCursor_ObjCClassRef                                             \
43 : '43', # CXCursor_TypeRef                                                  \
44 : '44', # CXCursor_CXXBaseSpecifier                                         \
45 : '45', # CXCursor_TemplateRef (A reference to a class template, function   \
           # template, template template parameter, or class template partial  \
           # specialization)                                                   \
46 : '46', # CXCursor_NamespaceRef (A reference to a namespace or namespace    \
           # alias)                                                            \
47 : '47', # CXCursor_MemberRef (A reference to a member of a struct, union,   \
           # or class that occurs in some non-expression context, e.g., a      \
           # designated initializer)                                           \
48 : '48', # CXCursor_LabelRef (A reference to a labeled statement)            \
49 : '49', # CXCursor_OverloadedDeclRef (A reference to a set of overloaded    \
           # functions or function templates that has not yet been resolved to \
           # a specific function or function template)                         \
                                                                               \
# Error conditions                                                             \
#70 : '70', # CXCursor_FirstInvalid                                            \
70 : '70',  # CXCursor_InvalidFile                                             \
71 : '71',  # CXCursor_NoDeclFound                                             \
72 : 'u',   # CXCursor_NotImplemented                                          \
73 : '73',  # CXCursor_InvalidCode                                             \
                                                                               \
# Expressions                                                                  \
100 : '100',  # CXCursor_UnexposedExpr (An expression whose specific kind is   \
              # not exposed via this interface)                                \
101 : '101',  # CXCursor_DeclRefExpr (An expression that refers to some value  \
              # declaration, such as a function, varible, or enumerator)       \
102 : '102',  # CXCursor_MemberRefExpr (An expression that refers to a member  \
              # of a struct, union, class, Objective-C class, etc)             \
103 : '103',  # CXCursor_CallExpr (An expression that calls a function)        \
104 : '104',  # CXCursor_ObjCMessageExpr (An expression that sends a message   \
              # to an Objective-C object or class)                             \
105 : '105',  # CXCursor_BlockExpr (An expression that represents a block      \
              # literal)                                                       \
                                                                               \
# Statements                                                                   \
200 : '200',  # CXCursor_UnexposedStmt (A statement whose specific kind is not \
              # exposed via this interface)                                    \
201 : '201',  # CXCursor_LabelStmt (A labelled statement in a function)        \
                                                                               \
# Translation unit                                                             \
300 : '300',  # CXCursor_TranslationUnit (Cursor that represents the           \
              # translation unit itself)                                       \
                                                                               \
# Attributes                                                                   \
400 : '400',  # CXCursor_UnexposedAttr (An attribute whose specific kind is    \
              # not exposed via this interface)                                \
401 : '401',  # CXCursor_IBActionAttr                                          \
402 : '402',  # CXCursor_IBOutletAttr                                          \
403 : '403',  # CXCursor_IBOutletCollectionAttr                                \
                                                                               \
# Preprocessing                                                                \
500 : '500', # CXCursor_PreprocessingDirective                                 \
501 : 'd',   # CXCursor_MacroDefinition                                        \
502 : '502', # CXCursor_MacroInstantiation                                     \
503 : '503'  # CXCursor_InclusionDirective                                     \
}


def test():
    if len(sys.argv) < 4:
        print "Usage: %s filename line column" % sys.argv[0]
        return

    sFileName = sys.argv[1]
    nLine = int(sys.argv[2])
    nColumn = int(sys.argv[3])
    lArgs = sys.argv[4:]

    ins = VIMClangCCIndex()
    ins.SetParseArgs(lArgs)

    print "Ready"
    start = time.time()
    ins.AsyncUpdateTranslationUnit(sFileName)
    ins.JoinUpdateThread()
    print 'First parsing elapsed: %f' % (time.time() - start)
    print ins.tus

    print '=' * 40
    start = time.time()
    tu = ins.GetCurrentTranslationUnit(sFileName, bReparse = True)
    print 'First reparsing elapsed: %f' % (time.time() - start)
    start = time.time()
    tu = ins.GetCurrentTranslationUnit(sFileName, bReparse = True)
    print 'Second reparsing elapsed: %f' % (time.time() - start)
    print '=' * 40

    print '=' * 40
    start = time.time()
    ccr = ins.GetTUCodeCompleteResults(sFileName, nLine, nColumn)
    print 'First code completion elapsed: %f' % (time.time() - start)
    start = time.time()
    ccr = ins.GetTUCodeCompleteResults(sFileName, nLine, nColumn)
    print 'Second code completion elapsed: %f' % (time.time() - start)
    print '=' * 40

    print ins.GetSymbolDeclarationLocation(sFileName, nLine, nColumn)
    print ins.GetSymbolDefinitionLocation(sFileName, nLine, nColumn)
    return

    ccr = ins.GetTUCodeCompleteResults(sFileName, nLine, nColumn)
    print ins.GetCalltipsFromCacheCCResults('operator=')
    if not ins:
        print 'GetTUCodeCompleteResults() failed'
    else:
        for result in ccr.results:
            print '%s: %s' % (result.kind, result)

    print '=' * 40

    start = time.time()
    vimccr = ins.GetVimCodeCompleteResults(sFileName, nLine, nColumn)
    print 'Get vim code completion elapsed: %f' % (time.time() - start)
    for i in vimccr:
        print i

    print '-' * 40
    for i in ins.GetVimQucikFixListFromRecentTU():
        print i


if __name__ == '__main__':
    test()

