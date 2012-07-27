#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import pickle
import os.path

import Globals

CONFIG_FILE = os.path.join(Globals.VIMLITE_DIR, 'config', 'TagsSettings.conf')

class TagsSettings:
    '''tags 设置'''

    def __init__(self, fileName = ''):
        if not fileName:
            self.fileName = ''
        else:
            self.fileName = os.path.abspath(fileName)
        self.includePaths = []
        self.excludePaths = []
        self.tagsTokens = [] # 宏处理符号
        self.tagsTypes = [] # 类型映射符号

        # 如果指定了 fileName, 从文件载入
        if fileName:
            self.Load(fileName)

    def SetFileName(self, fileName):
        self.fileName = fileName

    def AddTagsToken(self, tagsToken):
        self.tagsTokens.append(tagsToken)

    def RemoveTagsToken(self, index):
        try:
            del self.tagsTokens[index]
        except IndexError:
            return

    def AddTagsType(self, tagsType):
        self.tagsTypes.append(tagsType)

    def RemoveTagsType(self, index):
        try:
            del self.tagsTypes[index]
        except IndexError:
            return

    def AddIncludePath(self, path):
        self.includePaths.append(path)

    def RemoveIncludePath(self, index):
        try:
            del self.includePaths[index]
        except IndexError:
            return

    def AddExcludePath(self, path):
        self.excludePaths.append(path)

    def RemoveExcludePath(self, index):
        try:
            del self.excludePaths[index]
        except IndexError:
            return

    def Load(self, fileName = ''):
        if not fileName and not self.fileName:
            return False

        ret = False
        obj = None
        try:
            if not fileName:
                fileName = self.fileName
            f = open(fileName, 'rb')
            obj = pickle.load(f)
            f.close()
        except IOError:
            #print 'IOError:', fileName
            return False

        if obj:
            self.fileName = obj.fileName
            self.includePaths = obj.includePaths
            self.excludePaths = obj.excludePaths
            self.tagsTokens = obj.tagsTokens
            self.tagsTypes = obj.tagsTypes
            del obj
            ret = True

        return ret

    def Save(self, fileName = ''):
        if not fileName and not self.fileName:
            return False

        ret = False
        try:
            if not fileName:
                fileName = self.fileName
            dirName = os.path.dirname(fileName)
            if not os.path.exists(dirName):
                os.makedirs(dirName)
            f = open(fileName, 'wb')
            pickle.dump(self, f)
            f.close()
            ret = True
        except IOError:
            print 'IOError:', fileName
            return False

        return ret


class TagsSettingsST:
    __ins = None

    @staticmethod
    def Get():
        if not TagsSettingsST.__ins:
            TagsSettingsST.__ins = TagsSettings()
            # 载入默认设置
            if not TagsSettingsST.__ins.Load(CONFIG_FILE):
                # 文件不存在, 新建默认设置文件
                GenerateDefaultTagsSettings()
                TagsSettingsST.__ins.Save(CONFIG_FILE)
            TagsSettingsST.__ins.SetFileName(CONFIG_FILE)
        return TagsSettingsST.__ins

    @staticmethod
    def Free():
        del TagsSettingsST.__ins
        TagsSettingsST.__ins = None



def GetGccIncludeSearchPaths():
    start = False
    result = []

    #cmd = 'gcc -v -x c++ /dev/null -fsyntax-only 2>&1'
    cmd = 'echo "" | gcc -v -x c++ - -fsyntax-only 2>&1'

    for line in os.popen(cmd):
        #if line == '#include <...> search starts here:\n':
        if line.startswith('#include <...>'):
            start = True
            continue
        #elif line == 'End of search list.\n':
        if start and not line.startswith(' '):
            break

        if start:
            if Globals.IsWindowsOS():
                result.append(os.path.realpath(line.strip()))
            else:
                result.append(line.strip())

    return result


def GenerateDefaultTagsSettings():
    # 预设值
    defaultIncludePaths = GetGccIncludeSearchPaths()
    defaultTagsTokens = [
        '#define EXPORT',
        '#define WXDLLIMPEXP_CORE',
        '#define WXDLLIMPEXP_BASE',
        '#define WXDLLIMPEXP_XML',
        '#define WXDLLIMPEXP_XRC',
        '#define WXDLLIMPEXP_ADV',
        '#define WXDLLIMPEXP_AUI',
        '#define WXDLLIMPEXP_CL',
        '#define WXDLLIMPEXP_LE_SDK',
        '#define WXDLLIMPEXP_SQLITE3',
        '#define WXDLLIMPEXP_SCI',
        '#define WXMAKINGDLL',
        '#define WXUSINGDLL',
        '#define _CRTIMP',
        '#define __CRT_INLINE',
        '#define __cdecl',
        '#define __stdcall',
        '#define WXDLLEXPORT',
        '#define WXDLLIMPORT',
        '#define __MINGW_ATTRIB_PURE',
        '#define __MINGW_ATTRIB_MALLOC',
        '#define __GOMP_NOTHROW',
        '#define SCI_SCOPE(x) x',
        '#define WINBASEAPI',
        '#define WINAPI',
        '#define __nonnull',
        '#define wxTopLevelWindowNative wxTopLevelWindowGTK',
        '#define wxWindow wxWindowGTK',
        '#define wxWindowNative wxWindowBase',
        '#define wxStatusBar wxStatusBarBase',
        '#define BEGIN_DECLARE_EVENT_TYPES() enum {',
        '#define END_DECLARE_EVENT_TYPES() };',
        '#define DECLARE_EVENT_TYPE',
        '#define DECLARE_EXPORTED_EVENT_TYPE',
        '#define WXUNUSED(x) x',
        '#define wxDEPRECATED(x) x',
        '#define ATTRIBUTE_PRINTF_1',
        '#define ATTRIBUTE_PRINTF_2',
        '#define WXDLLIMPEXP_FWD_BASE',
        '#define WXDLLIMPEXP_FWD_CORE',
        '#define DLLIMPORT',
        '#define DECLARE_INSTANCE_TYPE',
        '#define emit',
        '#define Q_OBJECT',
        '#define Q_PACKED',
        '#define Q_GADGET',
        '#define QT_BEGIN_HEADER',
        '#define QT_END_HEADER',
        '#define Q_REQUIRED_RESULT',
        '#define Q_INLINE_TEMPLATE',
        '#define Q_OUTOFLINE_TEMPLATE',
        '#define _GLIBCXX_BEGIN_NAMESPACE(x) namespace x {',
        '#define _GLIBCXX_END_NAMESPACE }',
        '#define _GLIBCXX_BEGIN_NESTED_NAMESPACE(x, y) namespace x {',
        '#define _GLIBCXX_END_NESTED_NAMESPACE }',
        '#define _GLIBCXX_STD std',
        '#define __const const',
        '#define __restrict',
        '#define __THROW',
        '#define __wur',
        '#define _STD_BEGIN namespace std {',
        '#define _STD_END }',
        '#define __CLRCALL_OR_CDECL',
        '#define _CRTIMP2_PURE',
        '#define __BEGIN_NAMESPACE_STD',
        '#define __END_NAMESPACE_STD',
        '#define __attribute_malloc__',
        '#define __attribute_pure__',
        '#define _GLIBCXX_BEGIN_NAMESPACE_CONTAINER',
        '#define _GLIBCXX_END_NAMESPACE_CONTAINER',
        '#define _GLIBCXX_VISIBILITY(x)',
        '#define __cplusplus 1',
    ]
    defaultTagsTypes = [
        "std::vector<A>::reference=A",
        "std::vector<A>::const_reference=A",
        "std::vector<A>::iterator=A",
        "std::vector<A>::const_iterator=A",
        "std::list<A>::iterator=A",
        "std::list<A>::const_iterator=A",
        "std::queue<A>::reference=A",
        "std::queue<A>::const_reference=A",
        "std::set<A>::const_iterator=A",
        "std::set<A>::iterator=A",
        "std::deque<A>::reference=A",
        "std::deque<A>::const_reference=A",
        "std::map<A,B>::iterator=std::pair<A,B>",
        "std::map<A,B>::const_iterator=std::pair<A,B>",
        "std::multimap<A,B>::iterator=std::pair<A,B>",
        "std::multimap<A,B>::const_iterator=std::pair<A,B>",
    ]
    ins = TagsSettingsST.Get()
    ins.includePaths = defaultIncludePaths
    ins.tagsTokens = defaultTagsTokens
    ins.tagsTypes = defaultTagsTypes


if __name__ == '__main__':
    ins = TagsSettingsST.Get()
    print ins.fileName
    print '\n'.join(ins.includePaths)
    print '\n'.join(ins.tagsTokens)
    print '\n'.join(ins.tagsTypes)

