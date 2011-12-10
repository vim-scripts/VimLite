" Description:  Vim syntax file for VimLite workspace buffer
" Maintainer:   fanhe <fanhed@163.com>
" License:      This file is placed in the public domain
" Create:       2011-07-19
" Last Change:  2011-07-19

" 允许装载自定义语法文件
if exists("b:current_syntax")
    finish
endif

" 树结构标志
syn match VLWTreeLead '|'
syn match VLWTreeLead '`'

" 可展开和可折叠的标志
syn match VLWClosable '\V\[|`]~'hs=s+1 contains=VLWTreeLead
syn match VLWOpenable '\V\[|`]+'hs=s+1 contains=VLWTreeLead

" 文件前缀标志
syn match VLWFilePre '[|`]-'hs=s+1 contains=VLWTreeLead

" 忽略的文件
syn match VLWIgnoredFile '[|`]#.\+'hs=s+1 contains=VLWTreeLead


" 工作空间名字只能由 [a-zA-Z_ +-] 组成
syn match VLWorkspace '^[a-zA-Z0-9_ +-]\+$'

syn match VLWProject '^[|`][+~].\+' 
            \contains=VLWOpenable,VLWClosable,VLWTreeLead

syn match VLWVirtualDirectory '\s[|`][+~].\+$'hs=s+3 
            \contains=VLWOpenable,VLWClosable,VLWTreeLead

" 帮助信息
syn match VLWFlag '\~'
syn match VLWHelpKey '" \{1,2\}[^ ]*:'hs=s+2,he=e-1
syn match VLWHelpKey '" \{1,2\}[^ ]*,'hs=s+2,he=e-1
syn match VLWHelpTitle '" .*\~'hs=s+2,he=e-1 contains=VLWFlag
syn match VLWHelp '^".*' contains=VLWHelpKey,VLWHelpTitle,VLWFlag

if exists('g:VLWorkspaceHighlightSourceFile') && g:VLWorkspaceHighlightSourceFile
    " c/c++ 源文件、头文件
    syn match VLWCSource    '\V\c\[|`]-\.\+.c\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead

    syn match VLWCHeader    '\V\c\[|`]-\.\+.h\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead

    syn match VLWCppSource  '\V\c\[|`]-\.\+.cpp\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead
    syn match VLWCppSource  '\V\c\[|`]-\.\+.c++\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead
    syn match VLWCppSource  '\V\c\[|`]-\.\+.cxx\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead
    syn match VLWCppSource  '\V\c\[|`]-\.\+.cc\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead
    syn match VLWCppHeader  '\V\c\[|`]-\.\+.hpp\$'hs=s+2 
                \contains=VLWFilePre,VLWTreeLead

    hi def link VLWCSource Function
    hi def link VLWCHeader Constant
    hi def link VLWCppSource VLWCSource
    hi def link VLWCppHeader VLWCHeader
endif

hi def link VLWorkspace PreProc
hi def link VLWProject Type
hi def link VLWVirtualDirectory Statement

hi def link VLWTreeLead Special
hi def link VLWFilePre Linenr
hi def link VLWIgnoredFile Ignore
hi def link VLWClosable VLWFilePre
hi def link VLWOpenable Title

hi def link VLWFlag Ignore
hi def link VLWHelp Comment
hi def link VLWHelpKey Identifier
hi def link VLWHelpCommand Identifier
hi def link VLWHelpTitle Title
