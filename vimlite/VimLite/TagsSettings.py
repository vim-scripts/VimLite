#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import pickle
import os.path

CONFIG_FILE = os.path.expanduser('~/.vimlite/config/TagsSettings.conf')

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

        # 如果指定了 fileName, 从文件载入, 不论成功与否
        self.Load()

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
                print TagsSettingsST.__ins.Save(CONFIG_FILE)
            TagsSettingsST.__ins.SetFileName(CONFIG_FILE)
        return TagsSettingsST.__ins

    @staticmethod
    def Free():
        TagsSettingsST.__ins = None



def GetGccIncludeSearchPaths():
    start = False
    result = []
    for line in os.popen('gcc -v -x c++ /dev/null -fsyntax-only 2>&1'):
        if line == '#include <...> search starts here:\n':
            start = True
            continue
        elif line == 'End of search list.\n':
            break

        if start:
            result.append(line.strip())

    return result


def GenerateDefaultTagsSettings():
    # 预设值
    defaultIncludePaths = GetGccIncludeSearchPaths()
    defaultTagsTokens = [
        "EXPORT", 
        "WXDLLIMPEXP_CORE", 
        "WXDLLIMPEXP_BASE", 
        "WXDLLIMPEXP_XML", 
        "WXDLLIMPEXP_XRC", 
        "WXDLLIMPEXP_ADV", 
        "WXDLLIMPEXP_AUI", 
        "WXDLLIMPEXP_CL", 
        "WXDLLIMPEXP_LE_SDK", 
        "WXDLLIMPEXP_SQLITE3", 
        "WXDLLIMPEXP_SCI", 
        "WXMAKINGDLL", 
        "WXUSINGDLL", 
        "_CRTIMP", 
        "__CRT_INLINE", 
        "__cdecl", 
        "__stdcall", 
        "WXDLLEXPORT", 
        "WXDLLIMPORT", 
        "__MINGW_ATTRIB_PURE", 
        "__MINGW_ATTRIB_MALLOC", 
        "__GOMP_NOTHROW", 
        "wxT", 
        "SCI_SCOPE(%0)=%0", 
        "WINBASEAPI", 
        "WINAPI", 
        "__nonnull", 
        "wxTopLevelWindowNative=wxTopLevelWindowGTK", 
        "wxWindow=wxWindowGTK", 
        "wxWindowNative=wxWindowBase", 
        "wxStatusBar=wxStatusBarBase", 
        "BEGIN_DECLARE_EVENT_TYPES()=enum {", 
        "END_DECLARE_EVENT_TYPES()=};", 
        "DECLARE_EVENT_TYPE", 
        "DECLARE_EXPORTED_EVENT_TYPE", 
        "WXUNUSED(%0)=%0", 
        "wxDEPRECATED(%0)=%0", 
        "_T", 
        "ATTRIBUTE_PRINTF_1", 
        "ATTRIBUTE_PRINTF_2", 
        "WXDLLIMPEXP_FWD_BASE", 
        "WXDLLIMPEXP_FWD_CORE", 
        "DLLIMPORT", 
        "DECLARE_INSTANCE_TYPE", 
        "emit", 
        "Q_OBJECT", 
        "Q_PACKED", 
        "Q_GADGET", 
        "QT_BEGIN_HEADER", 
        "QT_END_HEADER", 
        "Q_REQUIRED_RESULT", 
        "Q_INLINE_TEMPLATE", 
        "Q_OUTOFLINE_TEMPLATE", 
        "_GLIBCXX_BEGIN_NAMESPACE(%0)=namespace %0{", 
        "_GLIBCXX_END_NAMESPACE=}", 
        "_GLIBCXX_BEGIN_NESTED_NAMESPACE(%0, %1)=namespace %0{", 
        "_GLIBCXX_END_NESTED_NAMESPACE=}", 
        "_GLIBCXX_STD=std", 
        "__const=const", 
        "__restrict", 
        "__THROW", 
        "__wur", 
        "_STD_BEGIN=namespace std{", 
        "_STD_END=}", 
        "__CLRCALL_OR_CDECL", 
        "_CRTIMP2_PURE", 
        "__BEGIN_NAMESPACE_STD", 
        "__END_NAMESPACE_STD", 
        "__attribute_malloc__", 
    ]
    defaultTagsTypes = [
        "std::vector::reference=_Tp", 
        "std::vector::const_reference=_Tp", 
        "std::vector::iterator=_Tp", 
        "std::vector::const_iterator=_Tp", 
        "std::queue::reference=_Tp", 
        "std::queue::const_reference=_Tp", 
        "std::set::const_iterator=_Key", 
        "std::set::iterator=_Key", 
        "std::deque::reference=_Tp", 
        "std::deque::const_reference=_Tp", 
        "std::map::iterator=pair<_Key, _Tp>", 
        "std::map::const_iterator=pair<_Key,_Tp>", 
        "std::multimap::iterator=pair<_Key,_Tp>", 
        "std::multimap::const_iterator=pair<_Key,_Tp>", 
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

