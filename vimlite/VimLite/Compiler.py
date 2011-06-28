#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom
import Macros
import XmlUtils

CmpFileKindInvalid = -1
CmpFileKindSource = 0
CmpFileKindResource = 1

class CmpFileTypeInfo:
    def __init__(self):
        self.extension = ''
        self.compilation_line = ''
        self.kind = 0

class CmpCmdLineOption:
    def __init__(self):
        self.name = ''
        self.help = ''

class CmpInfoPattern:
    def __init__(self):
        self.pattern = ''
        self.lineNumberIndex = ''
        self.fileNameIndex = ''

class Compiler:
    
    def __init__(self, node = None):
        self.name = ''
        self.switches = {}
        self.fileTypes = {}
        self.compilerOptions = {}
        self.linkerOptions = {}
        self.objectSuffix = ''
        self.dependSuffix = ''
        self.preprocessSuffix = ''
        
        self.errorPatterns = []
        self.warningPatterns = []
        
        self.tools = {}
        self.globalIncludePath = ''
        self.globalLibPath = ''
        self.pathVariable = ''
        self.generateDependeciesFile = False
        self.readObjectFilesFromList = False
        
        # ensure all relevant entries exist in switches dict
        self.switches["Include"]             = ''
        self.switches["Debug"]               = ''
        self.switches["Preprocessor"]        = ''
        self.switches["Library"]             = ''
        self.switches["LibraryPath"]         = ''
        self.switches["Source"]              = ''
        self.switches["Output"]              = ''
        self.switches["Object"]              = ''
        self.switches["ArchiveOutput"]       = ''
        self.switches["PreprocessOnly"]      = ''
        
        # ensure all relevant entries exist in tools dict
        self.tools["LinkerName"]             = ''
        self.tools["SharedObjectLinkerName"] = ''
        self.tools["CompilerName"]           = ''
        self.tools["C_CompilerName"]         = ''
        self.tools["ArchiveTool"]            = ''
        self.tools["ResourceCompiler"]       = ''
        
        self.fileTypes.clear()
        if node:
            #print 'reading'
            #print node.toxml()
            #print '-' * 80
            self.name = XmlUtils.ReadString(node, 'Name')
            if not node.hasAttribute('GenerateDependenciesFiles'):
                if self.name == 'gnu g++' or self.name == 'gnu gcc':
                    self.generateDependeciesFile = True
                else:
                    self.generateDependeciesFile = False
            else:
                self.generateDependeciesFile = XmlUtils.ReadBool(node, 'GenerateDependenciesFiles')
            
            if node.hasAttribute('ReadObjectsListFromFile'):
                self.readObjectFilesFromList = False
            else:
                self.readObjectFilesFromList = XmlUtils.ReadBool(node, 'ReadObjectsListFromFile')
            
            for i in node.childNodes:
                if i.nodeName == 'Switch':
                    self.switches[XmlUtils.ReadString(i, 'Name')] = XmlUtils.ReadString(i, 'Value')
                elif i.nodeName == 'Tool':
                    self.tools[XmlUtils.ReadString(i, 'Name')] = XmlUtils.ReadString(i, 'Value')
                elif i.nodeName == 'Option':
                    name = XmlUtils.ReadString(i, 'Name')
                    if name == 'ObjectSuffix':
                        self.objectSuffix = XmlUtils.ReadString(i, 'Value')
                    elif name == 'DependSuffix':
                        self.dependSuffix = XmlUtils.ReadString(i, 'Value')
                    elif name == 'PreprocessSuffix':
                        self.preprocessSuffix = XmlUtils.ReadString(i, 'Value')
                elif i.nodeName == 'File':
                    ft = CmpFileTypeInfo()
                    ft.compilation_line = XmlUtils.ReadString(i, 'CompilationLine')
                    ft.extension = XmlUtils.ReadString(i, 'Extension').lower()
                    
                    kind = CmpFileKindSource
                    if XmlUtils.ReadLong(i, 'Kind', kind) == CmpFileKindSource:
                        ft.kind = CmpFileKindSource
                    else:
                        ft.kind = CmpFileKindResource
                    self.fileTypes[ft.extension] = ft
                elif i.nodeName == 'Pattern':
                    if XmlUtils.ReadString(i, 'Name') == 'Error':
                        errPattern = CmpInfoPattern()
                        errPattern.fileNameIndex = XmlUtils.ReadString(i, 'FileNameIndex')
                        errPattern.lineNumberIndex = XmlUtils.ReadString(i, 'LineNumberIndex')
                        errPattern.pattern = XmlUtils.GetNodeContent(i)
                        self.errorPatterns.append(errPattern)
                    elif XmlUtils.ReadString(i, 'Name') == 'Warning':
                        warnPattern = CmpInfoPattern()
                        warnPattern.fileNameIndex = XmlUtils.ReadString(i, 'FileNameIndex')
                        warnPattern.lineNumberIndex = XmlUtils.ReadString(i, 'LineNumberIndex')
                        warnPattern.pattern = XmlUtils.GetNodeContent(i)
                        self.warningPatterns.append(warnPattern)
                elif i.nodeName == 'GlobalIncludePath':
                    self.globalIncludePath = XmlUtils.GetNodeContent(i)
                elif i.nodeName == 'GlobalLibPath':
                    self.globalLibPath = XmlUtils.GetNodeContent(i)
                elif i.nodeName == 'PathVariable':
                    self.pathVariable = XmlUtils.GetNodeContent(i)
                elif i.nodeName == 'CompilerOption':
                    cmpOption = CmpCmdLineOption()
                    cmpOption.name = XmlUtils.ReadString(i, 'Name')
                    cmpOption.help = XmlUtils.GetNodeContent(i)
                    self.compilerOptions[cmpOption.name] = cmpOption
                elif i.nodeName == 'LinkerOption':
                    lnkOption = CmpCmdLineOption()
                    lnkOption.name = XmlUtils.ReadString(i, 'Name')
                    lnkOption.help = XmlUtils.GetNodeContent(i)
                    self.linkerOptions[lnkOption.name] = lnkOption
        else:
            # create a default compiler: g++
            self.name                       = 'gnu g++'
            self.switches["Include"]        = "-I"
            self.switches["Debug"]          = "-g "
            self.switches["Preprocessor"]   = "-D"
            self.switches["Library"]        = "-l"
            self.switches["LibraryPath"]    = "-L"
            self.switches["Source"]         = "-c "
            self.switches["Output"]         = "-o "
            self.switches["Object"]         = "-o "
            self.switches["ArchiveOutput"]  = " "
            self.switches["PreprocessOnly"] = "-E"
            self.objectSuffix               = ".o"
            self.preprocessSuffix           = ".i"
            
            pattern = CmpInfoPattern()
            pattern.pattern = "^([^ ][a-zA-Z:]{0,2}[ a-zA-Z\\.0-9_/\\+\\-]+ *)(:)([0-9]*)([:0-9]*)(: )((fatal error)|(error)|(undefined reference))"
            pattern.fileNameIndex = '1'
            pattern.lineNumberIndex = '3'
            self.errorPatterns.append(pattern)
            
            pattern = CmpInfoPattern()
            pattern.pattern = "([a-zA-Z:]{0,2}[ a-zA-Z\\.0-9_/\\+\\-]+ *)(:)([0-9]+ *)(:)([0-9:]*)?( warning)"
            pattern.fileNameIndex = '1'
            pattern.lineNumberIndex = '3'
            self.warningPatterns.append(pattern)

            self.tools["LinkerName"]             = "g++"
            self.tools["SharedObjectLinkerName"] = "g++ -shared -fPIC"
            self.tools["CompilerName"]           = "g++"
            self.tools["C_CompilerName"]         = "gcc"
            self.tools["ArchiveTool"]            = "ar rcu"
            self.tools["ResourceCompiler"]       = "windres"
            self.globalIncludePath               = ''
            self.globalLibPath                   = ''
            self.pathVariable                    = ''
            self.generateDependeciesFile         = False
            self.readObjectFilesFromList         = False
        
        if self.generateDependeciesFile and not self.dependSuffix:
            self.dependSuffix = self.objectSuffix + '.d'
        
        if self.switches['PreprocessOnly'] and not self.preprocessSuffix:
            self.preprocessSuffix = self.objectSuffix + '.i'
            
        if not self.fileTypes:
            self.AddCmpFileType("cpp", CmpFileKindSource, "$(CompilerName) $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("cxx", CmpFileKindSource, "$(CompilerName) $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("c++", CmpFileKindSource, "$(CompilerName) $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("c",   CmpFileKindSource, "$(C_CompilerName) $(SourceSwitch) \"$(FileFullPath)\" $(C_CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("cc",  CmpFileKindSource, "$(CompilerName) $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("m",   CmpFileKindSource, "$(CompilerName) -x objective-c $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("mm",  CmpFileKindSource, "$(CompilerName) -x objective-c++ $(SourceSwitch) \"$(FileFullPath)\" $(CmpOptions) $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(IncludePath)");
            self.AddCmpFileType("rc",  CmpFileKindResource, "$(RcCompilerName) -i \"$(FileFullPath)\" $(RcCmpOptions)   $(ObjectSwitch)$(IntermediateDirectory)/$(ObjectName)$(ObjectSuffix) $(RcIncludePath)");
    
    def AddCmpFileType(self, extension, type, compile_line):
        ft = CmpFileTypeInfo()
        ft.extension = extension.lower()
        ft.compile_line = compile_line
        ft.kind = type
        self.fileTypes[extension] = ft

    def GetCmpFileType(self, extension):
        if self.fileTypes.has_key(extension.lower()):
            return self.fileTypes[extension.lower()]
        else:
            ft = CmpFileTypeInfo()
            ft.kind = CmpFileKindInvalid
            return ft

    def GetReadObjectFilesFromList(self):
        return self.readObjectFilesFromList

    def GetTool(self, name):
        if not self.tools.has_key(name):
            if name == 'C_CompilerName':
                return self.GetTool('CompilerName')
            else:
                return ''
        if name == 'C_CompilerName' and not self.tools[name]:
            return self.GetTool(name)
        return self.tools[name]

    def GetSwitch(self, name):
        if self.switches.has_key(name):
            return self.switches[name]
        else:
            return ''

    def GetGlobalIncludePath(self):
        return self.globalIncludePath

    def GetGlobalLibPath(self):
        return self.globalLibPath

    def GetGenerateDependeciesFile(self):
        return self.generateDependeciesFile

    def GetObjectSuffix(self):
        return self.objectSuffix

    def GetDependSuffix(self):
        return self.dependSuffix

    def GetPreprocessSuffix(self):
        return self.preprocessSuffix
    
    def ToXmlNode(self):
        doc = minidom.Document()
        node = doc.createElement('Compiler')
        node.setAttribute('Name', self.name)
        node.setAttribute('GenerateDependenciesFiles', Macros.BoolToString(self.generateDependeciesFile))
        node.setAttribute('ReadObjectsListFromFile', Macros.BoolToString(self.readObjectFilesFromList))
        
        for k, v in self.switches.items():
            child = doc.createElement('Switch')
            child.setAttribute('Name', k)
            child.setAttribute('Value', v)
            node.appendChild(child)
        
        for k, v in self.tools.items():
            child = doc.createElement('Tool')
            child.setAttribute('Name', k)
            child.setAttribute('Value', v)
            node.appendChild(child)
            
        for k, v in self.fileTypes.items():
            child = doc.createElement('File')
            child.setAttribute('Extension', v.extension)
            child.setAttribute('CompilationLine', v.compilation_line)
            child.setAttribute('Kind', str(v.kind))
            node.appendChild(child)
        
        optionsNode = doc.createElement('Option')
        optionsNode.setAttribute('Name', 'ObjectSuffix')
        optionsNode.setAttribute('Value', self.objectSuffix)
        node.appendChild(optionsNode)
        
        optionsNode = doc.createElement('Option')
        optionsNode.setAttribute('Name', 'DependSuffix')
        optionsNode.setAttribute('Value', self.dependSuffix)
        node.appendChild(optionsNode)
        
        optionsNode = doc.createElement('Option')
        optionsNode.setAttribute('Name', 'PreprocessSuffix')
        optionsNode.setAttribute('Value', self.preprocessSuffix)
        node.appendChild(optionsNode)
        
        # add patterns
        for i in self.errorPatterns:
            errorNode = doc.createElement('Pattern')
            errorNode.setAttribute('Name', 'Error')
            errorNode.setAttribute('FileNameIndex', i.fileNameIndex)
            errorNode.setAttribute('LineNumberIndex', i.lineNumberIndex)
            XmlUtils.SetNodeContent(errorNode, i.pattern)
            node.appendChild(errorNode)
        
        for i in self.warningPatterns:
            warningNode = doc.createElement('Pattern')
            warningNode.setAttribute('Name', 'Warning')
            warningNode.setAttribute('FileNameIndex', i.fileNameIndex)
            warningNode.setAttribute('LineNumberIndex', i.lineNumberIndex)
            XmlUtils.SetNodeContent(warningNode, i.pattern)
            node.appendChild(warningNode)
        
        globalIncludePathNode = doc.createElement('GlobalIncludePath')
        XmlUtils.SetNodeContent(globalIncludePathNode, self.globalIncludePath)
        node.appendChild(globalIncludePathNode)
        
        globalLibPathNode = doc.createElement('GlobalLibPath')
        XmlUtils.SetNodeContent(globalLibPathNode, self.globalLibPath)
        node.appendChild(globalLibPathNode)
        
        pathVariableNode = doc.createElement('PathVariable')
        XmlUtils.SetNodeContent(pathVariableNode, self.pathVariable)
        node.appendChild(pathVariableNode)
        
        # Add compiler options
        for k, v in self.compilerOptions.items():
            cmpOptNode = doc.createElement('CompilerOption')
            cmpOptNode.setAttribute('Name', v.name)
            XmlUtils.SetNodeContent(cmpOptNode, v.help)
            node.appendChild(cmpOptNode)
        
        # Add linker options
        for k, v in self.linkerOptions.items():
            lnkOptNode = doc.createElement('LinkerOption')
            lnkOptNode.setAttribute('Name', v.name)
            XmlUtils.SetNodeContent(lnkOptNode, v.help)
            node.appendChild(lnkOptNode)
        
        return node

    
if __name__ == '__main__':
    doc = minidom.parse('Compiler_test.xml')
    cmp = Compiler(doc.firstChild.childNodes[1])
    print cmp.ToXmlNode().toprettyxml()
    
