" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
syntax/dbgvar.vim	[[[1
25
" Vim syntax file
" Language:	debugger variables window syntax file
" Maintainer:	<xdegaye at users dot sourceforge dot net>
" Last Change:	Oct 8 2007

if exists("b:current_syntax")
    finish
endif

syn region dbgVarChged display contained matchgroup=dbgIgnore start="={\*}"ms=s+1 end="$"
syn region dbgDeScoped display contained matchgroup=dbgIgnore start="={-}"ms=s+1 end="$"
syn region dbgVarUnChged display contained matchgroup=dbgIgnore start="={=}"ms=s+1 end="$"

syn match dbgItem display transparent "^.*$"
    \ contains=dbgVarUnChged,dbgDeScoped,dbgVarChged,dbgVarNum

syn match dbgVarNum display contained "^\s*\d\+:"he=e-1

high def link dbgVarChged   Special
high def link dbgDeScoped   Comment
high def link dbgVarNum	    Identifier
high def link dbgIgnore	    Ignore

let b:current_syntax = "dbgvar"

syntax/vlworkspace.vim	[[[1
78
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
hi def link VLWClosable VLWFilePre
hi def link VLWOpenable Title

hi def link VLWFlag Ignore
hi def link VLWHelp Comment
hi def link VLWHelpKey Identifier
hi def link VLWHelpCommand Identifier
hi def link VLWHelpTitle Title
plugin/pyclewn.vim	[[[1
17
" pyclewn run time file
" Maintainer:   <xdegaye at users dot sourceforge dot net>
"
" Configure VIM to be used with pyclewn and netbeans
"

" pyclewn version
let g:pyclewn_version = "pyclewn-1.6.py2"

" enable balloon_eval
if has("balloon_eval")
    set ballooneval
    set balloondelay=100
endif

" The 'Pyclewn' command starts pyclewn and vim netbeans interface.
command -nargs=* -complete=file Pyclewn call pyclewn#StartClewn(<f-args>)
plugin/VLWorkspace.vim	[[[1
5358
" Vim global plugin for handle workspace
" Author:   fanhe <fanhed@163.com>
" License:  This file is placed in the public domain.
" Create:   2011 Mar 18
" Change:   2011 Jun 14

if exists("g:loaded_VLWorkspace")
    finish
endif
let g:loaded_VLWorkspace = 1


if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif


"if !hasmapto('<Plug>TypecorrAdd')
"   map <unique> <Leader>a  <Plug>TypecorrAdd
"endif
"noremap <unique> <script> <Plug>TypecorrAdd  <SID>Add

"Return: 1 表示赋值为默认, 否则返回 0
function! s:InitVariable(var, value) "初始化变量仅在变量没有定义时才赋值 {{{2
    if !exists(a:var)
        let {a:var} = a:value
        return 1
    endif
    return 0
endfunction
"}}}2

call s:InitVariable("g:VLWorkspaceWinSize", 30)
call s:InitVariable("g:VLWorkspaceWinPos", "left")
call s:InitVariable("g:VLWorkspaceBufName", '==VLWorkspace==')
call s:InitVariable("g:VLWorkspaceShowLineNumbers", 0)
call s:InitVariable("g:VLWorkspaceHighlightCursorline", 1)
"若为 1，编辑项目文件时，在工作空间的光标会自动定位到对应的文件所在的行
call s:InitVariable('g:VLWorkspaceLinkToEidtor', 1)
call s:InitVariable('g:VLWorkspaceEnableMenuBarMenu', 1)
call s:InitVariable('g:VLWorkspaceEnableToolBarMenu', 1)
call s:InitVariable('g:VLWorkspaceDispWspNameInTitle', 1)
call s:InitVariable('g:VLWorkspaceSaveAllBeforeBuild', 0)
call s:InitVariable('g:VLWorkspaceEnableCscope', 1)
call s:InitVariable('g:VLWorkspaceJustConnectExistCscopeDb', 1)
call s:InitVariable('g:VLWorkspaceCscopeContainExternalHeader', 1)
call s:InitVariable('g:VLWorkspaceCreateCscopeInvertedIndex', 0)
call s:InitVariable('g:VLWorkspaceCscpoeFilesFile', '_cscope.files')
call s:InitVariable('g:VLWorkspaceCscpoeOutFile', '_cscope.out')
call s:InitVariable('g:VLWorkspaceHighlightSourceFile', 1)
call s:InitVariable('g:VLWorkspaceActiveProjectHlGroup', 'SpecialKey')

"使用 clang 补全, 否则使用 OmniCpp
call s:InitVariable("g:VLWorkspaceUseClangCC", 0)
"保存文件时自动解析文件, 仅对属于工作空间的文件有效
call s:InitVariable("g:VLWorkspaceParseFileAfterSave", 0)
"自动解析保存的文件时, 仅解析头文件
call s:InitVariable("g:VLWorkspaceNotParseSourceAfterSave", 0)
"保存调试器信息, 默认不保存, 因为暂时无法具体控制
call s:InitVariable("g:VLWDbgSaveBreakpointsInfo", 1)

"键绑定
call s:InitVariable('g:VLWShowMenuKey', '.')
call s:InitVariable('g:VLWPopupMenuKey', '<RightRelease>')
call s:InitVariable('g:VLWOpenNodeKey', 'o')
call s:InitVariable('g:VLWOpenNode2Key', 'go')
call s:InitVariable('g:VLWOpenNodeInNewTabKey', 't')
call s:InitVariable('g:VLWOpenNodeInNewTab2Key', 'T')
call s:InitVariable('g:VLWOpenNodeSplitKey', 'i')
call s:InitVariable('g:VLWOpenNodeSplit2Key', 'gi')
call s:InitVariable('g:VLWOpenNodeVSplitKey', 's')
call s:InitVariable('g:VLWOpenNodeVSplit2Key', 'gs')
call s:InitVariable('g:VLWGotoParentKey', 'p')
call s:InitVariable('g:VLWGotoRootKey', 'P')
call s:InitVariable('g:VLWGotoNextSibling', '<C-n>')
call s:InitVariable('g:VLWGotoPrevSibling', '<C-p>')
call s:InitVariable('g:VLWRefreshBufferKey', 'R')
call s:InitVariable('g:VLWToggleHelpInfo', '<F1>')

"=======================================
"标记是否已经运行
call s:InitVariable("g:VLWorkspaceHasStarted", 0)
"模板所在路径
call s:InitVariable("g:VLWorkspaceTemplatesPath", 
            \expand('$HOME') . '/.vimlite/templates/projects')
call s:InitVariable("g:VLWorkspaceDbgConfName", "VLWDbg.conf")

"工作空间文件后缀名
call s:InitVariable("g:VLWorkspaceWspFileSuffix", "vlworkspace")
"项目文件后缀名
call s:InitVariable("g:VLWorkspacePrjFileSuffix", "vlproject")


"命令导出
command! -nargs=? -complete=file VLWorkspaceOpen 
            \call <SID>InitVLWorkspace('<args>')

command! -nargs=? VLWInitCscopeDatabase 
            \call <SID>InitVLWCscopeDatabase(<f-args>)
command! -nargs=0 VLWUpdateCscopeDatabase 
            \call <SID>UpdateVLWCscopeDatabase(1)

command! -nargs=0 -bar VLWBuildActiveProject    call <SID>BuildActiveProject()
command! -nargs=0 -bar VLWCleanActiveProject    call <SID>CleanActiveProject()
command! -nargs=0 -bar VLWRunActiveProject      call <SID>RunActiveProject()
command! -nargs=0 -bar VLWBuildAndRunActiveProject 
            \call <SID>BuildAndRunActiveProject()

command! -nargs=* -complete=file VLWParseFiles  call <SID>ParseFiles(<f-args>)
command! -nargs=0 -bar VLWParseCurrentFile      call <SID>ParseCurrentFile(0)
command! -nargs=0 -bar VLWDeepParseCurrentFile  call <SID>ParseCurrentFile(1)

command! -nargs=0 -bar VLWDbgStart          call <SID>DbgStart()
command! -nargs=0 -bar VLWDbgStop           call <SID>DbgStop()
command! -nargs=0 -bar VLWDbgStepIn         call <SID>DbgStepIn()
command! -nargs=0 -bar VLWDbgNext           call <SID>DbgNext()
command! -nargs=0 -bar VLWDbgStepOut        call <SID>DbgStepOut()
command! -nargs=0 -bar VLWDbgRunToCursor    call <SID>DbgRunToCursor()
command! -nargs=0 -bar VLWDbgContinue       call <SID>DbgContinue()
command! -nargs=0 -bar VLWDbgToggleBp       call <SID>DbgToggleBreakpoint()

command! -nargs=0 -bar VLWEnvVarSetttings   call <SID>EnvVarSettings()
command! -nargs=0 -bar VLWTagsSetttings     call <SID>TagsSettings()

command! -nargs=0 -bar VLWSwapSourceHeader  call <SID>SwapSourceHeader()

command! -nargs=? -bar VLWFindFiles         call <SID>FindFiles(<q-args>)
command! -nargs=? -bar VLWFindFilesNoCase   call <SID>FindFiles(<q-args>, 1)


function! g:VLWGetAllFiles() "{{{2
    let files = []
    if g:VLWorkspaceHasStarted
        py vim.command('let files = %s' 
                    \% [i.encode('utf-8') for i in ws.VLWIns.GetAllFiles(True)])
    endif
    return files
endfunction
"}}}

"===============================================================================
"基本实用函数
"===============================================================================
"{{{1
function! s:SID() "获取脚本 ID {{{2
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

let g:VLWScriptID = s:SID()

function! s:GetSFuncRef(sFuncName) "获取局部于脚本的函数的引用 {{{2
    return function('<SNR>'.s:SID().'_'.a:sFuncName[2:])
endfunction

function! s:echow(msg) "显示警告信息 {{{2
    echohl WarningMsg | echo a:msg | echohl None
endfunction

function! s:exec(cmd) "忽略所有事件运行 cmd {{{2
    let bak_ei = &ei
    set eventignore=all
    exec a:cmd
    let &ei = bak_ei
endfunction


function! s:OpenFile(sFile, ...) "优雅地打开一个文件 {{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let bNeedResizeWspWin = (winnr('$') == 1)

    let bak_splitright = &splitright
    if g:VLWorkspaceWinPos ==? 'left'
        set splitright
    else
        set nosplitright
    endif
    call vlutils#OpenFile(sFile, bKeepCursorPos)
    let &splitright = bak_splitright

    let nWspWinNr = bufwinnr('^'.g:VLWorkspaceBufName.'$')
    if bNeedResizeWspWin && nWspWinNr != -1
        exec 'vertical' nWspWinNr 'resize' g:VLWorkspaceWinSize
    endif

    if bKeepCursorPos
        call vlutils#Exec(nWspWinNr.'wincmd w')
    endif
endfunction


function! s:OpenFileInNewTab(sFile, ...) "{{{2
    let sFile = a:sFile
    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    call vlutils#OpenFileInNewTab(sFile, bKeepCursorPos)
endfunction


function! s:OpenFileSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    call vlutils#OpenFileSplit(sFile, bKeepCursorPos)
endfunction


function! s:OpenFileVSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let bak_splitright = &splitright
    if g:VLWorkspaceWinPos ==? 'left'
        set splitright
    else
        set nosplitright
    endif

    let bNeedResizeWspWin = (winnr('$') == 1)
    if bNeedResizeWspWin
        call s:OpenFile(sFile, bKeepCursorPos)
    else
        call vlutils#OpenFileVSplit(sFile, bKeepCursorPos)
    endif

    let &splitright = bak_splitright
endfunction
"}}}1
"===============================================================================
"===============================================================================


"===============================================================================
"缓冲区与窗口操作
"===============================================================================
"{{{1
function! s:InitVLWorkspace(file) "初始化 {{{2
    let sFile = a:file

    let bNeedConvertWspFileFormat = 0
    if filereadable(sFile)
        if fnamemodify(sFile, ":e") ==? 'workspace'
            let bNeedConvertWspFileFormat = 1
        elseif fnamemodify(sFile, ":e") !=? g:VLWorkspaceWspFileSuffix
            call s:echow("Is it a valid workspace file?")
            return
        endif
    endif

    "开始
    let g:VLWorkspaceHasStarted = 1

    "文件类型自动命令
    if g:VLWorkspaceUseClangCC
        autocmd! FileType c,cpp call g:InitVLClangCodeCompletion()
    else
        autocmd! FileType c,cpp call omnicpp#complete#Init()
    endif

    if g:VLWorkspaceEnableMenuBarMenu
        "添加菜单栏菜单
        call s:InstallMenuBarMenu()
    endif

    if g:VLWorkspaceEnableToolBarMenu
        "添加工具栏菜单
        call s:InstallToolBarMenu()
    endif

    if g:VLWorkspaceLinkToEidtor
        augroup VLWorkspace
            au!
            "au WinEnter     * call <SID>LocateFile(expand('%:p'))
            "au BufWinEnter  * call <SID>LocateFile(expand('%:p'))
            au BufEnter     * call <SID>LocateFile(expand('%:p'))
        augroup end
    endif

    if !g:VLWorkspaceUseClangCC && g:VLWorkspaceParseFileAfterSave
        augroup VLWorkspace
            au BufWritePost * call <SID>Autocmd_ParseCurrentFile()
        augroup end
    endif

    augroup VLWorkspace
        au Syntax dbgvar nnoremap <buffer> 
                    \<CR> :exec "Cfoldvar " . line(".")<CR>
        au Syntax dbgvar nnoremap <buffer> 
                    \<2-LeftMouse> :exec "Cfoldvar " . line(".")<CR>
    augroup end

    "初始化所有 python 接口
    call s:InitPythonInterfaces()

    if bNeedConvertWspFileFormat
        "老格式的 workspace, 提示转换格式
        echo "This workspace file is an old format file!"
        echohl Question
        echo "Are you willing to convert all files to new format?"
        echohl WarningMsg
        echo "NOTE1: Recommend 'yes'."
        echo "NOTE2: It will not change original files."
        echo "NOTE3: It will override existing VimLite's workspace and project files."
        echohl Question
        let sAnswer = input("(y/n): ")
        echohl None
        if sAnswer =~? '^y'
            py VLWorkspace.ConvertWspFileToNewFormat(vim.eval('sFile'))
            let sFile = fnamemodify(sFile, ':r') . '.' 
                        \. g:VLWorkspaceWspFileSuffix
            redraw
            echo 'Done. Press any key to continue...'
            call getchar()
        endif
    endif

    "初始化全局变量
    py ws = VimLiteWorkspace(vim.eval('sFile'))

    if g:VLWorkspaceEnableCscope
        call s:InitVLWCscopeDatabase()
    endif

    "设置标题栏
    if g:VLWorkspaceDispWspNameInTitle
        set titlestring=%(<%{GetWspName()}>\ %)%t%(\ %M%)
                    \%(\ (%{expand(\"%:~:h\")})%)%(\ %a%)%(\ -\ %{v:servername}%)
    endif

    "用于项目设置的全局变量
    py g_projects = {}
    py g_settings = {}
    py g_bldConfs = {}
    py g_glbBldConfs = {}

    "重置帮助信息开关
    let b:bHelpInfoOn = 0

    setlocal nomodifiable
endfunction

function! GetWspName()
    py vim.command("return '%s'" % ws.VLWIns.name)
endfunction

function! s:Autocmd_ParseCurrentFile()
    if !exists('s:CACHE_INCLUDES')
        let s:CACHE_INCLUDES = {}
    endif

    let fileName = expand('%:p')
    let isWspFile = 0
    py if ws.VLWIns.filesIndex.has_key(vim.eval("fileName")): 
                \vim.command("let isWspFile = 1")
    if isWspFile
        let li = s:GetCurBufIncList()
        if has_key(s:CACHE_INCLUDES, fileName)
            if s:CACHE_INCLUDES[fileName] == li
                " 包含的头文件没有修改
                if g:VLWorkspaceNotParseSourceAfterSave 
                            \&& index(['c', 'cpp', 'cxx', 'c++', 'cc'], 
                            \expand('%:p:e')) != -1
                    "不解析当前源文件
                    return
                endif

                call s:ParseCurrentFile()
            else
                "包含的头文件已经修改, 深度解析
                let s:CACHE_INCLUDES[fileName] = li
                call s:ParseCurrentFile(1)
            endif
        else
            let s:CACHE_INCLUDES[fileName] = li
            call s:ParseCurrentFile(1)
        endif
    endif
endfunction

function! s:GetCurBufIncList() "一般包含操作都放在文件前部, 故此函数复杂度不高
    let origCursor = getpos('.')
    let result = []

    call setpos('.', [0, 1, 1, 0])
    let firstEnter = 1
    while 1
        if firstEnter
            let flag = 'Wc'
            let firstEnter = 0
        else
            let flag = 'W'
        endif
        let ret = search('\C^\s*#include\>', flag)
        if ret == 0
            break
        endif

        let inc = matchstr(getline('.'), 
                    \'\C^\s*#include\s*\zs\(<\|"\)\f\+\(>\|"\)')
        if inc !=# ''
            call add(result, inc)
        endif
    endwhile

    call setpos('.', origCursor)
    return result
endfunction


function! s:CreateVLWorkspaceWin() "创建窗口 {{{2
    "create the workspace window
    let splitMethod = g:VLWorkspaceWinPos ==? "left" ? "topleft " : "botright "
    let splitSize = g:VLWorkspaceWinSize

    if !exists('t:VLWorkspaceBufName')
        let t:VLWorkspaceBufName = g:VLWorkspaceBufName
        silent! exec splitMethod . 'vertical ' . splitSize . ' new'
        silent! exec "edit " . t:VLWorkspaceBufName
    else
        silent! exec splitMethod . 'vertical ' . splitSize . ' split'
        silent! exec "buffer " . t:VLWorkspaceBufName
    endif

    setlocal winfixwidth

    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    if g:VLWorkspaceShowLineNumbers
        setlocal nu
    else
        setlocal nonu
    endif

    "删除所有插入模式的缩写
    iabc <buffer>

    if g:VLWorkspaceHighlightCursorline
        setlocal cursorline
    endif

    setfiletype vlworkspace
endfunction


function! s:SetupKeyMappings() "设置键盘映射 {{{2
    exec 'nnoremap <silent> <buffer>' g:VLWShowMenuKey 
                \':call <SID>ShowMenu()<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWPopupMenuKey 
                \':call <SID>OnRightMouseClick()<CR>'

    nnoremap <silent> <buffer> <2-LeftMouse> :call <SID>OnMouseDoubleClick()<CR>
    nnoremap <silent> <buffer> <CR> :call <SID>OnMouseDoubleClick()<CR>

    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeKey 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeKey)<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWOpenNode2Key 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNode2Key)<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeInNewTabKey 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeInNewTabKey)<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeInNewTab2Key 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeInNewTab2Key)<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeSplitKey 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeSplitKey)<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeSplit2Key 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeSplit2Key)<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeVSplitKey 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeVSplitKey)<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWOpenNodeVSplit2Key 
                \':call <SID>OnMouseDoubleClick(g:VLWOpenNodeVSplit2Key)<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWGotoParentKey 
                \':call <SID>GotoParent()<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWGotoRootKey 
                \':call <SID>GotoRoot()<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWGotoNextSibling 
                \':call <SID>GotoNextSibling()<CR>'
    exec 'nnoremap <silent> <buffer>' g:VLWGotoPrevSibling 
                \':call <SID>GotoPrevSibling()<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWRefreshBufferKey 
                \':call <SID>RefreshBuffer()<CR>'

    exec 'nnoremap <silent> <buffer>' g:VLWToggleHelpInfo 
                \':call <SID>ToggleHelpInfo()<CR>'
endfunction


function! s:LocateFile(fileName) "{{{2
    let l:curWinNum = winnr()
    let l:winNum = bufwinnr(g:VLWorkspaceBufName)
    if l:winNum == -1
        return 1
    endif

    py vim.command("let l:path = '%s'" 
                \% ws.VLWIns.GetWspFilePathByFileName(vim.eval('a:fileName')))
    if l:path == ''
        "文件不属于工作空间, 返回
        return 2
    endif

    "当前光标所在文件即为正在编辑的文件, 直接返回
    py if ws.VLWIns.GetFileByLineNum(ws.window.cursor[0], True)
                \== vim.eval('a:fileName'): vim.command('return 3')

    if l:curWinNum != l:winNum
        call s:exec(l:winNum . 'wincmd w')
    endif

    call setpos('.', [0, 1, 1, 0])
    let l:paths = split(l:path, '/')
    let l:depth = 1
    let l:spacePerDepth = 2
    for l:name in l:paths
        let l:pattern = '^.\{' . (l:depth * l:spacePerDepth) . '}' . l:name
        "let l:pattern = '^[| ~+-]\{' .(l:depth * l:spacePerDepth). '}' . l:name
        "echo l:name
        "echom l:pattern
        if search(l:pattern, 'c') == 0
            break
        endif
        call s:ExpandNode()
        let depth += 1
    endfor

    " NOTE: search 函数居然不自动滚动窗口?!
    let topLine = line('w0')
    let botLine = line('w$')
    let curLine = line('.')
    if curLine < topLine || curLine > botLine
        normal! zz
    endif

    "if g:VLWorkspaceHighlightCursorline
        "高亮光标所在行时, 刷新有点问题, 强制刷新
        "redraw
    "endif

    if l:curWinNum != l:winNum
        call s:exec('wincmd p')
    endif

    return l:paths
endfunction


function! s:InstallMenuBarMenu() "{{{2
    anoremenu <silent> 200.10 &VimLite.Environment\ Variables\ Settings\.\.\. 
                \:call <SID>EnvVarSettings()<CR>
    "anoremenu <silent> 200.20 &VimLite.Build\ Settings\.\.\. <Nop>
    "anoremenu <silent> 200.20 &VimLite.Debugger\ Settings\.\.\. <Nop>

    if !g:VLWorkspaceUseClangCC
        anoremenu <silent> 200.20 &VimLite.Tags\ Settings\.\.\. 
                    \:call <SID>TagsSettings()<CR>
    endif
endfunction


function! s:InstallToolBarMenu() "{{{2
    "anoremenu 1.500 ToolBar.-Sep15- <Nop>
    anoremenu <silent> icon=~/.vimlite/bitmaps/build.png   1.510 
                \ToolBar.BuildActiveProject 
                \:call <SID>BuildActiveProject()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/clean.png   1.520 
                \ToolBar.CleanActiveProject 
                \:call <SID>CleanActiveProject()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/execute.png 1.530 
                \ToolBar.RunActiveProject 
                \:call <SID>RunActiveProject()<CR>
    tmenu ToolBar.BuildActiveProject    Build Active Project
    tmenu ToolBar.CleanActiveProject    Clean Active Project
    tmenu ToolBar.RunActiveProject      Run Active Project

    "调试工具栏
    anoremenu 1.600 ToolBar.-Sep16- <Nop>
    anoremenu <silent> icon=~/.vimlite/bitmaps/breakpoint.png 1.605 
                \ToolBar.DbgToggleBreakpoint 
                \:silent call <SID>DbgToggleBreakpoint()<CR>

    anoremenu 1.609 ToolBar.-Sep17- <Nop>
    anoremenu <silent> icon=~/.vimlite/bitmaps/start.gif 1.610 
                \ToolBar.DbgStart 
                \:silent call <SID>DbgStart()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/stepin.gif 1.630 
                \ToolBar.DbgStepIn 
                \:silent call <SID>DbgStepIn()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/next.gif 1.640 
                \ToolBar.DbgNext 
                \:silent call <SID>DbgNext()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/stepout.gif 1.650 
                \ToolBar.DbgStepOut 
                \:silent call <SID>DbgStepOut()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/continue.gif 1.660 
                \ToolBar.DbgContinue 
                \:silent call <SID>DbgContinue()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/runtocursor.gif 1.665 
                \ToolBar.DbgRunToCursor 
                \:silent call <SID>DbgRunToCursor()<CR>
    anoremenu <silent> icon=~/.vimlite/bitmaps/stop.gif 1.670 
                \ToolBar.DbgStop 
                \:silent call <SID>DbgStop()<CR>

    tmenu ToolBar.DbgStart              Start / Run Debugger
    tmenu ToolBar.DbgStop               Stop Debugger
    tmenu ToolBar.DbgStepIn             Step In
    tmenu ToolBar.DbgNext               Next
    tmenu ToolBar.DbgStepOut            Step Out
    tmenu ToolBar.DbgRunToCursor        Run to cursor
    tmenu ToolBar.DbgContinue           Continue

    tmenu ToolBar.DbgToggleBreakpoint   Toggle Breakpoint
endfunction


function! s:ParseCurrentFile(...) "可选参数为是否解析包含的头文件 {{{2
    let deep = 0
    if a:0 > 0
        let deep = a:1
    endif
    let curFile = expand("%:p")
    let files = [curFile]
    if deep
        py l_project = ws.VLWIns.GetProjectByFileName(vim.eval('curFile'))
        py l_searchPaths = []
        py if l_project: l_searchPaths = ws.GetProjectIncludePaths(
                    \l_project.GetName())
        py ws.ParseFiles(vim.eval('files') 
                    \+ IncludeParser.GetIncludeFiles(vim.eval('curFile'),
                    \   l_searchPaths))
        py del l_searchPaths
        py del l_project
    else
        py ws.ParseFiles(vim.eval('files'), False)
    endif
endfunction


function! s:ParseFiles(files) "{{{2
    py ws.ParseFiles(vim.eval("a:files"))
endfunction


"}}}1
"===============================================================================
"===============================================================================


"===============================================================================
"基本操作
"===============================================================================
"=================== 工作空间树操作 ===================
"{{{1
function! s:OnMouseDoubleClick(...) "{{{2
    let sKey = ''
    if a:0 > 0
        let sKey = a:1
    endif
    py ws.OnMouseDoubleClick(vim.eval("sKey"))
endfunction


function! s:OnRightMouseClick() "{{{2
    py ws.OnRightMouseClick()
endfunction


function! s:ChangeBuildConfig() "{{{2
    py ws.ChangeBuildConfig()
endfunction


function! s:ShowMenu() "显示菜单 {{{2
    py ws.ShowMenu()
endfunction


function! s:MenuOperation(menu) "菜单操作 {{{2
    "menu 作为 id, 工作空间菜单形如 'W_Create a New Project'
    py ws.MenuOperation(vim.eval('a:menu'))
endfunction


function! s:ExpandNode() "{{{2
    py ws.ExpandNode()
endfunction


function! s:FoldNode() "{{{2
    py ws.FoldNode()
endfunction


function! s:GotoParent() "{{{2
    py ws.GotoParent()
endfunction


function! s:GotoRoot() "{{{2
    py ws.GotoRoot()
endfunction


function! s:GotoNextSibling() "{{{2
    py ws.GotoNextSibling()
endfunction


function! s:GotoPrevSibling() "{{{2
    py ws.GotoPrevSibling()
endfunction


function! s:AddFileNode(lnum, name) "{{{2
    py ws.AddFileNode(vim.eval('a:lnum'), vim.eval('a:name'))
endfunction


function! s:AddFileNodes(lnum, names) "批量添加文件节点 {{{2
    py ws.AddFileNodes(vim.eval('a:lnum'), vim.eval('a:names'))
endfunction


function! s:AddVirtualDirNode(lnum, name) "{{{2
    py ws.AddVirtualDirNode(vim.eval('a:lnum'), vim.eval('a:name'))
endfunction


function! s:AddProjectNode(lnum, projFile) "{{{2
    py ws.AddProjectNode(vim.eval('a:lnum'), vim.eval('a:projFile'))
endfunction


function! s:DeleteNode() "{{{2
    py ws.DeleteNode()
endfunction


function! s:HlActiveProject() "{{{2
    py ws.HlActiveProject()
endfunction


function! s:RefreshLines(start, end) "刷新数行，不包括 end 行 {{{2
    py ws.RefreshLines(vim.eval('a:start'), vim.eval('a:end'))
endfunction


function! s:RefreshStatusLine() "{{{2
    py ws.RefreshStatusLine()
endfunction


function! s:RefreshBuffer() "{{{2
    let lOrigCursor = getpos('.')

    let bNeedDispHelp = 0
    if exists('b:bHelpInfoOn') && b:bHelpInfoOn
        let bNeedDispHelp = 1
        call s:ToggleHelpInfo()
    endif

    py ws.RefreshBuffer()

    if bNeedDispHelp
        call s:ToggleHelpInfo()
    endif

    call setpos('.', lOrigCursor)
endfunction


function! s:ToggleHelpInfo() "{{{2
    if !exists('b:bHelpInfoOn')
        let b:bHelpInfoOn = 0
    endif

    if !b:bHelpInfoOn
        let b:dOrigView = winsaveview()
    endif

    let lHelpInfo = []

    let sLine = '" ============================'
    call add(lHelpInfo, sLine)

    let sLine = '" File node mappings~'
    call add(lHelpInfo, sLine)

    let sLine = '" <2-LeftMouse>,'
    call add(lHelpInfo, sLine)
    let sLine = '" <CR>,'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeKey.': open file gracefully'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNode2Key.': preview'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeInNewTabKey.': open in new tab'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeInNewTab2Key.': open in new tab silently'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeSplitKey.': open split'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeSplit2Key.': preview split'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeVSplitKey.': open vsplit'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeVSplit2Key.': preview vsplit'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')

    let sLine = '" ----------------------------'
    call add(lHelpInfo, sLine)
    let sLine = '" Directory node mappings~'
    call add(lHelpInfo, sLine)
    let sLine = '" <2-LeftMouse>,'
    call add(lHelpInfo, sLine)
    let sLine = '" <CR>,'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeKey.': open & close node'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')

    let sLine = '" ----------------------------'
    call add(lHelpInfo, sLine)
    let sLine = '" Project node mappings~'
    call add(lHelpInfo, sLine)
    let sLine = '" <2-LeftMouse>,'
    call add(lHelpInfo, sLine)
    let sLine = '" <CR>,'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeKey.': open & close node'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')

    let sLine = '" ----------------------------'
    call add(lHelpInfo, sLine)
    let sLine = '" Workspace node mappings~'
    call add(lHelpInfo, sLine)
    let sLine = '" <2-LeftMouse>,'
    call add(lHelpInfo, sLine)
    let sLine = '" <CR>,'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWOpenNodeKey.': show build config menu'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')

    let sLine = '" ----------------------------'
    call add(lHelpInfo, sLine)
    let sLine = '" Tree navigation mappings~'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWGotoRootKey.': go to root'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWGotoParentKey.': go to parent'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWGotoNextSibling.': go to next sibling'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWGotoPrevSibling.': go to prev sibling'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')

    let sLine = '" ----------------------------'
    call add(lHelpInfo, sLine)
    let sLine = '" Other mappings~'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWPopupMenuKey.': popup menu'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWShowMenuKey.': show text menu'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWRefreshBufferKey.': refresh buffer'
    call add(lHelpInfo, sLine)
    let sLine = '" '.g:VLWToggleHelpInfo.': toggle help info'
    call add(lHelpInfo, sLine)
    call add(lHelpInfo, '')


    setlocal ma
    if b:bHelpInfoOn
        let b:bHelpInfoOn = 0
        exec 'silent! 1,'.(1+len(lHelpInfo)-1) . ' delete _'
        py ws.VLWIns.SetWorkspaceLineNum(ws.VLWIns.GetRootLineNum() - 
                    \int(vim.eval('len(lHelpInfo)')))

        if exists('b:dOrigView')
            call winrestview(b:dOrigView)
            unlet b:dOrigView
        endif
    else
        let b:bHelpInfoOn = 1
        call append(0, lHelpInfo)
        py ws.VLWIns.SetWorkspaceLineNum(ws.VLWIns.GetRootLineNum() + 
                    \int(vim.eval('len(lHelpInfo)')))
        call cursor(1, 1)
    endif
    setlocal noma
endfunction


"}}}1
"=================== 构建操作 ===================
"{{{1
function! s:BuildProject(projName) "{{{2
    "au! BufReadPost quickfix setlocal nonu nowrap | nunmap <2-LeftMouse>
    py ws.BuildProject(vim.eval('a:projName'))
endfunction

function! s:CleanProject(projName) "{{{2
    py ws.CleanProject(vim.eval('a:projName'))
endfunction

function! s:RebuildProject(projName) "{{{2
    py ws.RebuildProject(vim.eval('a:projName'))
endfunction

function! s:RunProject(projName) "{{{2
    py ws.RunProject(vim.eval('a:projName'))
endfunction

function! s:BuildActiveProject() "{{{2
    if g:VLWorkspaceHasStarted
        py ws.BuildActiveProject()
    endif
endfunction
function! s:CleanActiveProject() "{{{2
    if g:VLWorkspaceHasStarted
        py ws.CleanActiveProject()
    endif
endfunction
function! s:RunActiveProject() "{{{2
    if g:VLWorkspaceHasStarted
        py ws.RunActiveProject()
    endif
endfunction


function! s:BuildAndRunActiveProject() "{{{2
    if g:VLWorkspaceHasStarted
        py ws.BuildAndRunActiveProject()
    endif
endfunction


"}}}1
"=================== 调试操作 ===================
"{{{1
function! s:DbgToggleBreakpoint() "{{{2
    let nCurLine = line('.')
    let sCurFile = expand('%:p')

    let nSigintFlag = 0
    let nIsDelBp = 0

    let sCursorSignName = ''
    for sLine in split(g:GetCmdOutput('sign list'), "\n")
        if sLine =~# '^sign '
            if matchstr(sLine, '\Ctext==>') !=# ''
                let sCursorSignName = matchstr(sLine, '\C^sign \zs\w\+\>')
                break
            elseif matchstr(sLine, '\Ctext=') ==# ''
                " 没有文本
                let sCursorSignName = matchstr(sLine, '\C^sign \zs\w\+\>')
                break
            endif
        endif
    endfor

    let sLastDbgOutput = getbufline(bufnr('(clewn)_console'), '$')[0]
    if sLastDbgOutput !=# '(gdb) '
        " 正在运行时添加断点, 必须先中断然后添加
        Csigint
        let nSigintFlag = 1
    endif

    for sLine in split(g:GetCmdOutput('sign place buffer=' . bufnr('%')), "\n")
        if sLine =~# '^\s\+line='
            let nSignLine = str2nr(matchstr(sLine, '\Cline=\zs\d\+'))
            let sSignName = matchstr(sLine, '\Cname=\zs\w\+\>')
            if nSignLine == nCurLine && sSignName !=# sCursorSignName
                " 获取断点的编号, 按编号删除
                "let nID = str2nr(matchstr(sLine, '\Cid=\zs\d\+'))
                " 获取断点的名字, 按名字删除
                let sName = matchstr(sLine, '\Cid=\zs\w\+')
                for sLine2 in split(g:GetCmdOutput('sign list'), "\n")
                    "if matchstr(sLine2, '\C^sign ' . nID) !=# ''
                    if matchstr(sLine2, '\C^sign ' . sName) !=# ''
                        let sBpID = matchstr(sLine2, '\Ctext=\zs\d\+')
                        exec 'Cdelete ' . sBpID
                        break
                    endif
                endfor

                "exec "Cclear " . sCurFile . ":" . nSignLine
                let nIsDelBp = 1
                break
            endif
        endif
    endfor

    if !nIsDelBp
        exec "Cbreak " . sCurFile . ":" . nCurLine
    endif

    if nSigintFlag
        Ccontinue
    endif
endfunction

function! s:DbgStart() "{{{2
    " TODO: pyclewn 首次运行, pyclewn 运行中, pyclewn 一次调试完毕后
    if !has("netbeans_enabled")
        if g:VLWDbgSaveBreakpointsInfo
            let dbgProjFile = ''
            py proj = ws.VLWIns.FindProjectByName(
                        \ws.VLWIns.GetActiveProjectName())
            py if proj: vim.command("let dbgProjFile = '%s'" % os.path.join(
                        \   proj.dirName, ws.VLWIns.GetActiveProjectName() 
                        \       + '_' + vim.eval("g:VLWorkspaceDbgConfName")))
            py del proj
            if dbgProjFile !=# ''
                let g:VLWDbgProjectFile = dbgProjFile
            endif
        endif

        silent Pyclewn
        " BUG:? 运行 ws.DebugActiveProject() 前必须运行一条命令,
        " 否则出现灵异事件. 这条命令会最后才运行
        Cpwd

        if g:VLWDbgSaveBreakpointsInfo && filereadable(dbgProjFile)
            py ws.DebugActiveProject(True)
        else
            py ws.DebugActiveProject(False)
        endif
    else
        let sLastDbgOutput = getbufline(bufnr('(clewn)_console'), '$')[0]
        if sLastDbgOutput !=# '(gdb) '
            " 正在运行, 中断之, 重新运行
            Csigint
        endif
        " 为避免修改了程序参数, 需要重新设置程序参数
        py ws.DebugActiveProject(False, False)
    endif
endfunction

function! s:DbgStop() "{{{2
    if has("netbeans_enabled")
        silent Cstop
        silent nbclose
    endif
endfunction

function! s:DbgStepIn() "{{{2
    silent Cstep
endfunction

function! s:DbgNext() "{{{2
    silent Cnext
endfunction

function! s:DbgStepOut() "{{{2
    silent Cfinish
endfunction

function! s:DbgContinue() "{{{2
    silent Ccontinue
endfunction

function! s:DbgRunToCursor() "{{{2
    let nCurLine = line('.')
    let sCurFile = expand('%:p')

    let sLastDbgOutput = getbufline(bufnr('(clewn)_console'), '$')[0]
    if sLastDbgOutput !=# '(gdb) '
        " 正在运行时添加断点, 必须先中断然后添加
        Csigint
    endif

    exec "Ctbreak " . sCurFile . ":" . nCurLine
    Ccontinue
endfunction


"}}}1
"=================== 创建操作 ===================
"{{{1
function! s:CreateWorkspacePostCbk(dlg, data) "{{{2
    if a:data ==# 'True'
        "call s:RefreshBuffer()
        py ws.ReloadWorkspace()
    endif
endfunction

function! s:CreateWorkspace(...) "{{{2
    if exists('a:1')
        " Run as callback
        if a:1.type == g:VC_DIALOG
            let dialog = a:1
        else
            let dialog = a:1.owner
        endif

        let sWspName = ''
        let l:wspPath = ''
        let l:isSepPath = 0
        for i in dialog.controls
            if i.id == 0
                let sWspName = i.value
            elseif i.id == 1
                let l:wspPath = i.value
            elseif i.id == 2
                let l:isSepPath = i.value
            else
                continue
            endif
        endfor
        if sWspName != ''
            if l:isSepPath != 0
                let l:file = l:wspPath .'/'. fnamemodify(sWspName, ":r") . '/'
                            \. sWspName . '.' . g:VLWorkspaceWspFileSuffix
            else
                let l:file = l:wspPath .'/'. sWspName . '.' 
                            \. g:VLWorkspaceWspFileSuffix
            endif
        endif

        if a:1.type != g:VC_DIALOG
            call a:2.SetId(100)
            if sWspName != ''
                let a:2.label = l:file
            else
                let a:2.label = ''
            endif
            call dialog.RefreshCtlById(100)
        endif

        if a:1.type == g:VC_DIALOG && sWspName != ''
            "echo sWspName
            "echo l:file
            py ret = ws.VLWIns.CreateWorkspace(vim.eval('sWspName'), 
                        \os.path.dirname(vim.eval('l:file')))
            "py if ret: ws.LoadWspSettings()
            "py if ret: ws.OpenTagsDatabase()
            py vim.command('call dialog.ConnectPostCallback('
                        \'s:GetSFuncRef("s:CreateWorkspacePostCbk"), "%s")' 
                        \% str(ret))
        endif

        return 0
    endif

    let g:newWspDialog = g:VimDialog.New('New Workspace')

    let ctl = g:VCSingleText.New('Workspace Name:')
    call ctl.SetId(0)
    call g:newWspDialog.AddControl(ctl)
    call g:newWspDialog.AddBlankLine()
    let tmpCtl = ctl

    let ctl = g:VCSingleText.New('Workspace Path:')
    call ctl.SetValue(getcwd())
    call ctl.SetId(1)
    call g:newWspDialog.AddControl(ctl)
    call g:newWspDialog.AddBlankLine()
    let tmpCtl1 = ctl

    let ctl = g:VCCheckItem.New(
                \'Create the workspace under a seperate directory')
    call ctl.SetId(2)
    call g:newWspDialog.AddControl(ctl)
    call g:newWspDialog.AddBlankLine()
    let tmpCtl2 = ctl

    let ctl = g:VCStaticText.New('File Name:')
    call g:newWspDialog.AddControl(ctl)
    let ctl = g:VCStaticText.New('')
    let ctl.editable = 1
    call ctl.SetIndent(8)
    call ctl.SetHighlight('Special')
    call g:newWspDialog.AddControl(ctl)
    call tmpCtl.ConnectActionPostCallback(s:GetSFuncRef('s:CreateWorkspace'), ctl)
    call tmpCtl1.ConnectActionPostCallback(s:GetSFuncRef('s:CreateWorkspace'), ctl)
    call tmpCtl2.ConnectActionPostCallback(s:GetSFuncRef('s:CreateWorkspace'), ctl)

    call g:newWspDialog.DisableApply()
    call g:newWspDialog.AddFooterButtons()
    call g:newWspDialog.AddCallback(s:GetSFuncRef("s:CreateWorkspace"))
    call g:newWspDialog.Display()
endfunction

function! s:CreateProjectPostCbk(dlg, data) "{{{2
    setlocal modifiable
python << PYTHON_EOF
def CreateProjectPostCbk(ret):
    # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
    ln = ws.VLWIns.GetPrevSiblingLineNum(ret)
    if ln == ret:
        ln = ws.VLWIns.GetRootLineNum(0)

    texts = []
    for i in range(ln, ret + 1):
        texts.append(ws.VLWIns.GetLineText(i).encode('utf-8'))
    if texts:
        ws.buffer[ln - 1 : ret - 1] = texts
CreateProjectPostCbk(int(vim.eval("a:data")))
PYTHON_EOF
    setlocal nomodifiable
    call s:HlActiveProject()
endfunction

function! s:CreateProjectCategoriesCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let tblCtl = a:data
    let categories = ctl.GetValue()
    call tblCtl.DeleteAllLines()
    call tblCtl.SetSelection(1)
python << PYTHON_EOF
def CreateProjectCategoriesCbk():
    templates = GetTemplateDict(vim.eval('g:VLWorkspaceTemplatesPath'))
    key = vim.eval('categories')
    for line in templates[key]:
        vim.command("call tblCtl.AddLineByValues('%s')" % line['name'])
CreateProjectCategoriesCbk()
PYTHON_EOF
    call ctl.owner.RefreshCtl(tblCtl)
    "刷新组合框
    for i in ctl.owner.controls
        if i.id == 4
            call s:TemplatesTableCbk(tblCtl, i)
            break
        endif
    endfor
endfunction

function! s:TemplatesTableCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let comboCtl = a:data
    let name = ctl.GetLine(ctl.selection)[0]
    let categories = ''
    for i in ctl.owner.controls
        if i.id == 5
            let categories = i.GetValue()
            break
        endif
    endfor
python << PYTHON_EOF
def TemplatesTableCbk():
    templates = GetTemplateDict(vim.eval('g:VLWorkspaceTemplatesPath'))
    name = vim.eval('name')
    key = vim.eval('categories')
    for line in templates[key]:
        if line['name'] == name:
            vim.command('call comboCtl.SetValue("%s")' % line['cmpType'])
            break
TemplatesTableCbk()
PYTHON_EOF
    call ctl.owner.RefreshCtl(comboCtl)
endfunction

function! s:CreateProject(...) "{{{2
    if exists('a:1')
        " Run as callback
        if a:1.type == g:VC_DIALOG
            let dialog = a:1
        else
            let dialog = a:1.owner
        endif

        let l:projName = ''
        let l:projPath = ''
        let l:isSepPath = 0
        let l:projType = 'gnu gcc'
        let l:cmpType = 'Executable'
        let l:categories = ''
        let l:templateFile = ''
        for i in dialog.controls
            if i.id == 0
                let l:projName = i.value
            elseif i.id == 1
                let l:projPath = i.value
            elseif i.id == 2
                let l:isSepPath = i.value
            elseif i.id == 3
                let l:projType = i.value
            elseif i.id == 4
                let l:cmpType = i.value
            elseif i.id == 5
                let l:categories = i.value
            elseif i.id == 6
                let l:templateName = i.GetSelectedLine()[0]
python << PYTHON_EOF
templates = GetTemplateDict(vim.eval('g:VLWorkspaceTemplatesPath'))
key = vim.eval('l:categories')
name = vim.eval('l:templateName')
template = {}
for template  in templates[key]:
    if template['name'] == name:
        vim.command("let l:templateFile = '%s'" % template['file'])
templates.clear()
del templates, template, key, name
PYTHON_EOF
            else
                continue
            endif
        endfor
        if l:projName != ''
            if l:isSepPath != 0
                let l:file = l:projPath .'/'. fnamemodify(l:projName, ":r") .'/'
                            \. l:projName . '.' . g:VLWorkspacePrjFileSuffix
            else
                let l:file = l:projPath .'/'. l:projName . '.' 
                            \. g:VLWorkspacePrjFileSuffix
            endif
        endif

        "更新显示的文件名
        if a:1.type != g:VC_DIALOG
            if l:projName != ''
                let a:2.label = l:file
            else
                let a:2.label = ''
            endif
            call dialog.RefreshCtl(a:2)
        endif

        "开始创建项目
        if a:1.type == g:VC_DIALOG && l:projName != ''
            "echo l:projName
            "echo l:file
            "echo l:projType
            "echo l:cmpType
            "echo l:categories
            "echo l:templateFile
            py ret = ws.VLWIns.CreateProjectFromTemplate(
                        \vim.eval('l:projName'), 
                        \os.path.dirname(vim.eval('l:file')), 
                        \vim.eval('l:templateFile'), 
                        \vim.eval('l:cmpType'))
            "py ret = ws.VLWIns.CreateProject(
                        "\vim.eval('l:projName'), 
                        "\os.path.dirname(vim.eval('l:file')), 
                        "\vim.eval('l:projType'), 
                        "\vim.eval('l:cmpType'))

            " 创建失败
            py if isinstance(ret, bool) and not ret: vim.command('return 1')

            py vim.command('call dialog.ConnectPostCallback('
                        \'s:GetSFuncRef("s:CreateProjectPostCbk"), %d)' % ret)
        endif

        return 0
    endif

    let g:newProjDialog = g:VimDialog.New('New Project')

    let ctl = g:VCSingleText.New('Project Name:')
    call ctl.SetId(0)
    call g:newProjDialog.AddControl(ctl)
    call g:newProjDialog.AddBlankLine()
    let tmpCtl = ctl

    let ctl = g:VCSingleText.New('Project Path:')
    call ctl.SetValue(getcwd())

    if g:VLWorkspaceHasStarted
        py vim.command('call ctl.SetValue("%s")' % ws.VLWIns.dirName)
    endif

    call ctl.SetId(1)
    call g:newProjDialog.AddControl(ctl)
    call g:newProjDialog.AddBlankLine()
    let tmpCtl1 = ctl

    let ctl = g:VCCheckItem.New('Create the project under a seperate directory')
    call ctl.SetId(2)
    call g:newProjDialog.AddControl(ctl)
    call g:newProjDialog.AddBlankLine()
    let tmpCtl2 = ctl

    let ctl = g:VCStaticText.New('File Name:')
    call g:newProjDialog.AddControl(ctl)
    let ctl = g:VCStaticText.New('')
    let ctl.editable = 1
    call ctl.SetIndent(8)
    call ctl.SetHighlight('Special')
    call g:newProjDialog.AddControl(ctl)
    call g:newProjDialog.AddBlankLine()
    call tmpCtl.ConnectActionPostCallback(s:GetSFuncRef('s:CreateProject'), ctl)
    call tmpCtl1.ConnectActionPostCallback(s:GetSFuncRef('s:CreateProject'), ctl)
    call tmpCtl2.ConnectActionPostCallback(s:GetSFuncRef('s:CreateProject'), ctl)

    " 项目类型
    "let ctl = g:VCComboBox.New('Project Type:')
    "call ctl.SetId(3)
    "call ctl.AddItem('Static Library')
    "call ctl.AddItem('Dynamic Library')
    "call ctl.AddItem('Executable')
    "call ctl.SetValue('Executable')
    "call g:newProjDialog.AddControl(ctl)
    "call g:newProjDialog.AddBlankLine()

    " 编译器
    let ctl = g:VCComboBox.New('Compiler Type:')
    call ctl.SetId(4)
    call ctl.SetIndent(4)
    call ctl.AddItem('cobra')
    call ctl.AddItem('gnu g++')
    call ctl.AddItem('gnu gcc')
    call ctl.SetValue('gnu gcc')
    call g:newProjDialog.AddControl(ctl)
    call g:newProjDialog.AddBlankLine()

    let cmpTypeCtl = ctl

    " 模版类别
    let ctl = g:VCComboBox.New('Templates Categories:')
    call ctl.SetId(5)
    call ctl.SetIndent(4)
    call g:newProjDialog.AddControl(ctl)

    let tblCtl = g:VCTable.New('', 1)
    call tblCtl.SetId(6)
    call tblCtl.SetIndent(4)
    call tblCtl.SetColTitle(1, 'Type')
    call tblCtl.SetDispHeader(0)
    call tblCtl.SetCellEditable(0)
    call tblCtl.SetSelection(1)
    call tblCtl.SetDispButtons(0)
    call g:newProjDialog.AddControl(tblCtl)
    call ctl.ConnectActionPostCallback(
                \s:GetSFuncRef('s:CreateProjectCategoriesCbk'), tblCtl)
    call tblCtl.ConnectSelectionCallback(
                \s:GetSFuncRef('s:TemplatesTableCbk'), cmpTypeCtl)
python << PYTHON_EOF
def CreateTemplateCtls():
    templates = GetTemplateDict(vim.eval('g:VLWorkspaceTemplatesPath'))
    for key in templates.keys():
        vim.command('call ctl.AddItem("%s")' % key)
    for line in templates[templates.keys()[0]]:
        vim.command("call tblCtl.AddLineByValues('%s')" % line['name'])
CreateTemplateCtls()
PYTHON_EOF

    call g:newProjDialog.DisableApply()
    call g:newProjDialog.AddFooterButtons()
    call g:newProjDialog.AddCallback(s:GetSFuncRef("s:CreateProject"))
    call g:newProjDialog.Display()

    "第一次也需要刷新组合框
    call s:TemplatesTableCbk(tblCtl, cmpTypeCtl)
python << PYTHON_EOF
PYTHON_EOF
endfunction

"}}}1
"=================== 其他组件 ===================
"{{{1
"========== Cscope =========
function! s:InitVLWCscopeDatabase(...) "{{{2
    "初始化 cscope 数据库。文件的更新采用粗略算法，
    "只比较记录文件与 cscope.files 的时间戳而不是很详细的记录每次增删条目
    "如果 cscope.files 比工作空间和包含的所有项目都要新，无须刷新 cscope.files
    "如果 g:VLWorkspaceJustConnectExistCscopeDb 为 1，
    "仅连接已存在的数据库，其他什么都不做

    "如果传进来的第一个参数非零，强制全部初始化并刷新全部

    if !g:VLWorkspaceHasStarted || !g:VLWorkspaceEnableCscope
        return
    endif

    py l_ds = Globals.DirSaver()
    py if os.path.isdir(ws.VLWIns.dirName): os.chdir(ws.VLWIns.dirName)

    let lFiles = []
    py vim.command("let sWspName = '%s'" % ws.VLWIns.name)
    let sCsFilesFile = sWspName . g:VLWorkspaceCscpoeFilesFile
    let sCsOutFile = sWspName . g:VLWorkspaceCscpoeOutFile

    let l:force = 0
    if exists('a:1') && a:1 != 0
        let l:force = 1
    endif

    "仅连接已存在的数据库，其他什么都不做
    if g:VLWorkspaceJustConnectExistCscopeDb && !l:force
        if filereadable(sCsOutFile)
            set csto=0
            set cst
            "set nocsverb
            exec 'silent! cs kill '.sCsOutFile
            exec 'cs add '.sCsOutFile
            "set csverb
        endif
        py del l_ds
        return
    endif

python << PYTHON_EOF
def InitVLWCscopeDatabase():
    # 检查是否需要更新 cscope.files 文件
    csFilesMt = Globals.GetFileModificationTime(vim.eval('sCsFilesFile'))
    wspFileMt = ws.VLWIns.GetWorkspaceFileLastModifiedTime()
    needUpdateCsNameFile = False
    # FIXME: codelite 每次退出都会更新工作空间文件的时间戳
    if wspFileMt > csFilesMt:
        needUpdateCsNameFile = True
    else:
        for project in ws.VLWIns.projects.itervalues():
            if project.GetProjFileLastModifiedTime() > csFilesMt:
                needUpdateCsNameFile = True
                break
    if needUpdateCsNameFile or vim.eval('l:force') == '1':
        #vim.command('let lFiles = %s' 
            #% [i.encode('utf-8') for i in ws.VLWIns.GetAllFiles(True)])
        #直接 GetAllFiles 可能会出现重复的情况，直接用 filesIndex 字典键值即可
        ws.VLWIns.GenerateFilesIndex() #重建，以免任何特殊情况
        files = ws.VLWIns.filesIndex.keys()
        files.sort()
        vim.command('let lFiles = %s' % [i.encode('utf-8') for i in files])

    # TODO: 添加激活的项目的包含头文件路径选项
    # 这只关系到跳到定义处，如果实现了 ctags 数据库，就不需要
    # 比较麻烦，暂不实现
    incPaths = []
    if vim.eval('g:VLWorkspaceCscopeContainExternalHeader') != '0':
        incPaths = ws.GetWorkspaceIncludePaths()
    vim.command('let lIncludePaths = %s"' % str(incPaths))

InitVLWCscopeDatabase()
PYTHON_EOF

    "echom string(lFiles)
    if !empty(lFiles)
        call writefile(lFiles, sCsFilesFile)
    endif

    let sIncludeOpts = ''
    if !empty(lIncludePaths)
        let sIncludeOpts = '-I"' . join(lIncludePaths, '" -I"') . '"'
    endif

    if filereadable(sCsOutFile)
        "已存在，但不更新，应该由用户调用 s:UpdateVLWCscopeDatabase 来更新
        "除非为强制初始化全部
        if l:force
            if g:VLWorkspaceCreateCscopeInvertedIndex
                let sFirstOpts = '-bqkU'
            else
                let sFirstOpts = '-bkU'
            endif
            let sCmd = printf('cscope %s %s -i %s -f %s', sFirstOpts, 
                        \sIncludeOpts, sCsFilesFile, sCsOutFile)
            call system(sCmd)
        endif
    else
        if g:VLWorkspaceCreateCscopeInvertedIndex
            let sFirstOpts = '-bqk'
        else
            let sFirstOpts = '-bk'
        endif
        let sCmd = printf('cscope %s %s -i %s -f %s', sFirstOpts, 
                    \sIncludeOpts, sCsFilesFile, sCsOutFile)
        call system(sCmd)
    endif

    set csto=0
    set cst
    "set nocsverb
    exec 'silent! cs kill '. sCsOutFile
    exec 'cs add '. sCsOutFile
    "set csverb

    py del l_ds
endfunction


function! s:UpdateVLWCscopeDatabase(...) "{{{2
    "默认仅仅更新 .out 文件，如果有参数传进来且为 1，也更新 .files 文件
    "仅在已经存在能用的 .files 文件时才会更新

    if !g:VLWorkspaceHasStarted || !g:VLWorkspaceEnableCscope
        return
    endif


    py l_ds = Globals.DirSaver()
    py if os.path.isdir(ws.VLWIns.dirName): os.chdir(ws.VLWIns.dirName)

    py vim.command("let sWspName = '%s'" % ws.VLWIns.name)
    let sCsFilesFile = sWspName . g:VLWorkspaceCscpoeFilesFile
    let sCsOutFile = sWspName . g:VLWorkspaceCscpoeOutFile

    if !filereadable(sCsFilesFile)
        "没有必要文件，自动忽略
        py del l_ds
        return
    endif

    if exists('a:1') && a:1 != 0
        "如果传入参数且非零，强制刷新文件列表
        py vim.command('let lFiles = %s' 
                    \% [i.encode('utf-8') for i in ws.VLWIns.GetAllFiles(True)])
        call writefile(lFiles, sCsFilesFile)
    endif

    let lIncludePaths = []
    if g:VLWorkspaceCscopeContainExternalHeader
        py vim.command("let lIncludePaths = %s" 
                    \% str(ws.GetWorkspaceIncludePaths()))
    endif
    let sIncludeOpts = ''
    if !empty(lIncludePaths)
        let sIncludeOpts = '-I"' . join(lIncludePaths, '" -I"') . '"'
    endif

    let sFirstOpts = '-bkU'
    if g:VLWorkspaceCreateCscopeInvertedIndex
        let sFirstOpts .= 'q'
    endif
    let sCmd = printf('cscope %s %s -i %s -f %s', sFirstOpts, sIncludeOpts, 
                \sCsFilesFile, sCsOutFile)
    call system(sCmd)

    exec 'silent! cs kill '. sCsOutFile
    exec 'cs add '. sCsOutFile

    py del l_ds
endfunction

"}}}
"========== Swap Source / Header =========
function! s:SwapSourceHeader() "{{{2
    let sFile = expand("%:p")
    py ws.SwapSourceHeader(vim.eval("sFile"))
endfunction
"========== Find Files =========
function! s:FindFiles(sMatchName, ...) "{{{2
    let sMatchName = a:sMatchName
    let bNoCase = a:0 > 0 ? a:1 : 0
    if sMatchName ==# ''
        echohl Question
        let sMatchName = input("Input name to be matched:\n")
        echohl None
    endif
    py ws.FindFiles(vim.eval('sMatchName'), int(vim.eval('bNoCase')))
endfunction
"}}}1
"===============================================================================
"===============================================================================


"===============================================================================
"使用控件系统的交互操作
"===============================================================================
"=================== 环境变量设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:ID_EnvVarSettingsEnvVarSets = 100
let s:ID_EnvVarSettingsEnvVarList = 101


function! s:EnvVarSettings() "{{{2
    let dlg = s:CreateEnvVarSettingsDialog()
    call dlg.Display()
endfunction

function! s:EVS_NewSetCbk(ctl, data) "{{{2
    echohl Question
    let sNewSet = input("Enter Name:\n")
    echohl None
    if sNewSet ==# ''
        return 0
    endif

    let ctl = a:ctl
    let nSetsID = s:ID_EnvVarSettingsEnvVarSets
    let nListID = s:ID_EnvVarSettingsEnvVarList
    let dlg = ctl.owner
    let dSetsCtl = dlg.GetControlByID(nSetsID)
    let dListCtl = dlg.GetControlByID(nListID)

    if !empty(dSetsCtl)
        "检查同名
        if index(dSetsCtl.GetItems(), sNewSet) != -1
            echohl ErrorMsg
            echo printf("The same name already exists: '%s'", sNewSet)
            echohl None
            return 0
        endif

        call dSetsCtl.AddItem(sNewSet)
        call dSetsCtl.SetValue(sNewSet)
        call dlg.RefreshCtl(dSetsCtl)

        "更新 data
        let dData = dSetsCtl.GetData()
        let dData[sNewSet] = []
        "保存当前的
        let sCurSet = dListCtl.GetData()
        if has_key(dData, sCurSet)
            call filter(dData[sCurSet], 0)
            for lLine in dListCtl.table
                call add(dData[sCurSet], lLine[0])
            endfor
        endif
        call dSetsCtl.SetData(dData)

        if !empty(dListCtl)
            call dListCtl.DeleteAllLines()
            call dlg.RefreshCtl(dListCtl)

            "更新 data
            call dListCtl.SetData(sNewSet)
        endif
    endif

    return 0
endfunction

function! s:EVS_DeleteSetCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let nSetsID = s:ID_EnvVarSettingsEnvVarSets
    let nListID = s:ID_EnvVarSettingsEnvVarList
    let dlg = ctl.owner
    let dSetsCtl = dlg.GetControlByID(nSetsID)
    let dListCtl = dlg.GetControlByID(nListID)

    if empty(dSetsCtl) || dSetsCtl.GetValue() ==# 'Default'
        "不能删除默认组
        return 0
    endif

    if !empty(dSetsCtl)
        let sCurSet = dSetsCtl.GetValue()
        let data = dSetsCtl.GetData()
        if has_key(data, sCurSet)
            call remove(data, sCurSet)
        endif
        call dSetsCtl.RemoveItem(sCurSet)
        call dlg.RefreshCtl(dSetsCtl)

        if !empty(dListCtl)
            call dListCtl.DeleteAllLines()
            for sEnvVarExpr in dSetsCtl.GetData()[dSetsCtl.GetValue()]
                call dListCtl.AddLineByValues(sEnvVarExpr)
            endfor
            call dListCtl.SetData(dSetsCtl.GetValue())
            call dlg.RefreshCtl(dListCtl)
        endif
    endif

    return 0
endfunction

function! s:EVS_EditEnvVarBtnCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let editDialog = g:VimDialog.New('Edit', ctl.owner)

    let lContent = []
    for lLine in ctl.table
        call add(lContent, lLine[0])
    endfor
    let sContent = join(lContent, "\n")

    call editDialog.SetIsPopup(1)
    call editDialog.SetAsTextCtrl(1)
    call editDialog.SetTextContent(sContent)
    call editDialog.ConnectSaveCallback(
                \s:GetSFuncRef('s:EVS_EditEnvVarSaveCbk'), ctl)
    call editDialog.Display()
endfunction

function! s:EVS_EditEnvVarSaveCbk(ctl, data) "{{{2
    let ctl = a:data
    let textsList = getline(1, '$')
    call filter(textsList, 'v:val !~ "^\\s\\+$\\|^$"')
    call ctl.DeleteAllLines()
    for sText in textsList
        call ctl.AddLineByValues(sText)
        call ctl.SetSelection(1)
    endfor
    call ctl.owner.RefreshCtl(ctl)
endfunction

function! s:AddEnvVarCbk(ctl, data) "{{{2
    echohl Question
    let input = input("New Environment Variable:\n")
    echohl None
    if input != ''
        call a:ctl.AddLineByValues(input)
    endif
endfunction

function! s:EditEnvVarCbk(ctl, data) "{{{2
    let value = a:ctl.GetSelectedLine()[0]
    echohl Question
    let input = input("Edit Environment Variable:\n", value)
    echohl None
    if input != '' && input != value
        call a:ctl.SetCellValue(a:ctl.selection, 0, input)
    endif
endfunction

function! s:ChangeEditingEnvVarSetCbk(ctl, data) "{{{2
    let dSetsCtl = a:ctl
    let dListCtl = a:data
    let dData = dSetsCtl.GetData()
    let sCurSet = dListCtl.GetData()

    "更新 data
    if has_key(dData, sCurSet)
        call filter(dData[sCurSet], 0)
        for lLine in dListCtl.table
            call add(dData[sCurSet], lLine[0])
        endfor
    endif

    call dListCtl.DeleteAllLines()
    for sEnvVarExpr in dData[dSetsCtl.GetValue()]
        call dListCtl.AddLineByValues(sEnvVarExpr)
    endfor
    call dListCtl.SetData(dSetsCtl.GetValue())
    call dSetsCtl.owner.RefreshCtl(dListCtl)
endfunction

function! s:SaveEnvVarSettingsCbk(dlg, data) "{{{2
    py ins = EnvVarSettingsST.Get()
    py ins.DeleteAllEnvVarSets()
    let sCurSet = ''
    for ctl in a:dlg.controls
        if ctl.GetId() == s:ID_EnvVarSettingsEnvVarSets
            let sCurSet = ctl.GetValue()
            let dData = ctl.GetData()
            for item in items(dData)
                if sCurSet ==# item[0]
                    "跳过 data 中的 sCurSet 的数据, 应该用 table 控件的数据
                    continue
                endif
                py ins.NewEnvVarSet(vim.eval("item[0]"))
                for expr in item[1]
                    py ins.AddEnvVar(vim.eval("item[0]"), vim.eval("expr"))
                endfor
            endfor
        elseif ctl.GetId() == s:ID_EnvVarSettingsEnvVarList
            let table = ctl.table
            py ins.NewEnvVarSet(vim.eval("sCurSet"))
            py ins.ClearEnvVarSet(vim.eval("sCurSet"))
            for line in table
                py ins.AddEnvVar(vim.eval("sCurSet"), vim.eval("line[0]"))
            endfor
        endif
    endfor
    "保存
    py ins.Save()
    py del ins
endfunction

function! s:CreateEnvVarSettingsDialog() "{{{2
    let dlg = g:VimDialog.New('==Environment Variables Settings==')
    py ins = EnvVarSettingsST.Get()

    "1.EnvVarSets
    "===========================================================================
    let ctl = g:VCStaticText.New('Available Environment Sets')
    call ctl.SetIndent(4)
    call dlg.AddControl(ctl)

    let ctl = g:VCButtonLine.New('')
    call ctl.SetIndent(4)
    call ctl.AddButton('New Set...')
    call ctl.AddButton('Delete Set')
    call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:EVS_NewSetCbk'), '')
    call ctl.ConnectButtonCallback(1, s:GetSFuncRef('s:EVS_DeleteSetCbk'), '')
    call dlg.AddControl(ctl)

    let ctl = g:VCComboBox.New('')
    let dSetsCtl = ctl
    call ctl.SetId(s:ID_EnvVarSettingsEnvVarSets)
    call ctl.SetIndent(4)
    py vim.command("let lEnvVarSets = %s" % ins.envVarSets.keys())
    call sort(lEnvVarSets)
    for sEnvVarSet in lEnvVarSets
        call ctl.AddItem(sEnvVarSet)
    endfor
    call ctl.SetValue('Default')
    call dlg.AddControl(ctl)

    "2.EnvVarList
    "===========================================================================
    let ctl = g:VCTable.New('')
    let dListCtl = ctl
    call ctl.SetId(s:ID_EnvVarSettingsEnvVarList)
    call ctl.SetDispHeader(0)
    call ctl.SetIndent(4)
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:AddEnvVarCbk'), '')
    "call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EditEnvVarCbk'), '')
    call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EVS_EditEnvVarBtnCbk'), '')
    call dlg.AddControl(ctl)

    call dlg.AddBlankLine()

    call dSetsCtl.ConnectActionPostCallback(
                \s:GetSFuncRef('s:ChangeEditingEnvVarSetCbk'), dListCtl)

    call dlg.ConnectSaveCallback(s:GetSFuncRef("s:SaveEnvVarSettingsCbk"), "")

python << PYTHON_EOF
def CreateEnvVarSettingsData():
    ins = EnvVarSettingsST.Get()
    vim.command('let dData = {}')
    for setName, envVars in ins.envVarSets.iteritems():
        vim.command("let dData['%s'] = []" % setName)
        for envVar in envVars:
            vim.command("call add(dData['%s'], '%s')" 
                        \% (setName, envVar.GetString()))
CreateEnvVarSettingsData()
PYTHON_EOF

    "私有变量保存环境变量全部数据
    call dSetsCtl.SetData(dData)
    if has_key(dData, dSetsCtl.GetValue())
        for sEnvVarExpr in dData[dSetsCtl.GetValue()]
            call dListCtl.AddLineByValues(sEnvVarExpr)
        endfor
    endif
    "私有变量保存当前环境变量列表的 setName
    call dListCtl.SetData(dSetsCtl.GetValue())

    call dlg.AddFooterButtons()

    py del ins
    return dlg
endfunction
"}}}1
"=================== tags 设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:ID_TagsSettingsIncludePaths = 10
let s:ID_TagsSettingsTagsTokens = 11
let s:ID_TagsSettingsTagsTypes = 12


function! s:TagsSettings() "{{{2
    let dlg = s:CreateTagsSettingsDialog()
    call dlg.Display()
endfunction

function! s:SaveTagsSettingsCbk(dlg, data) "{{{2
    py ins = TagsSettingsST.Get()
    for ctl in a:dlg.controls
        if ctl.GetId() == s:ID_TagsSettingsIncludePaths
            let table = ctl.table
            py del ins.includePaths[:]
            for line in table
                py ins.includePaths.append(vim.eval("line[0]"))
            endfor
        elseif ctl.GetId() == s:ID_TagsSettingsTagsTokens
            py ins.tagsTokens = vim.eval("ctl.values")
        elseif ctl.GetId() == s:ID_TagsSettingsTagsTypes
            py ins.tagsTypes = vim.eval("ctl.values")
        endif
    endfor
    "保存
    py ins.Save()
    py del ins
endfunction

function! s:CreateTagsSettingsDialog() "{{{2
    let dlg = g:VimDialog.New('==Tags Settings==')
    py ins = TagsSettingsST.Get()

"===============================================================================
    "1.Include Files
    "let ctl = g:VCStaticText.New("Tags Settings")
    "call ctl.SetHighlight("Special")
    "call dlg.AddControl(ctl)
    "call dlg.AddBlankLine()

    let ctl = g:VCTable.New('Add search paths for the parser.', 1)
    call ctl.SetId(s:ID_TagsSettingsIncludePaths)
    call ctl.SetIndent(4)
    call ctl.SetDispHeader(0)
    py vim.command("let includePaths = %s" % ins.includePaths)
    for includePath in includePaths
        call ctl.AddLineByValues(includePath)
    endfor
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:AddSearchPathCbk'), '')
    call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EditSearchPathCbk'), '')
    call dlg.AddControl(ctl)
    call dlg.AddBlankLine()

    let ctl = g:VCMultiText.New("Tokens")
    call ctl.SetId(s:ID_TagsSettingsTagsTokens)
    call ctl.SetIndent(4)
    py vim.command("let tagsTokens = %s" % ins.tagsTokens)
    call ctl.SetValue(tagsTokens)
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditTextBtnCbk"), "")
    call dlg.AddControl(ctl)
    call dlg.AddBlankLine()

    let ctl = g:VCMultiText.New("Types")
    call ctl.SetId(s:ID_TagsSettingsTagsTypes)
    call ctl.SetIndent(4)
    py vim.command("let tagsTypes = %s" % ins.tagsTypes)
    call ctl.SetValue(tagsTypes)
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditTextBtnCbk"), "")
    call dlg.AddControl(ctl)
    call dlg.AddBlankLine()

    call dlg.ConnectSaveCallback(s:GetSFuncRef("s:SaveTagsSettingsCbk"), "")

    call dlg.AddFooterButtons()

    py del ins
    return dlg
endfunction
"}}}1
"=================== PCH 设置 ===================
"{{{1
function! s:GetVLWProjectCompileOpts(projName) "{{{2
    if !g:VLWorkspaceHasStarted
        return
    endif

    let l:ret = ''
python << PYTHON_EOF
def GetVLWProjectCompileOpts(projName):
    matrix = ws.VLWIns.GetBuildMatrix()
    wspSelConfName = matrix.GetSelectedConfigurationName()
    project = ws.VLWIns.FindProjectByName(projName)
    if not project:
        vim.command("echom 'no project'")
        return

    ds = Globals.DirSaver()
    try:
        os.chdir(project.dirName)
    except OSError:
        return

    projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                    project.GetName())
    bldConf = ws.VLWIns.GetProjBuildConf(project.GetName(), projSelConfName)
    if not bldConf or bldConf.IsCustomBuild():
        vim.command("echom 'no bldConf or is custom build'")
        return

    opts = []

    includePaths = bldConf.GetIncludePath()
    for i in includePaths.split(';'):
        if i:
            opts.append('-I%s' % i)

    cmpOpts = bldConf.GetCompileOptions().replace('$(shell', '$(')

    # 合并 C 和 C++ 两个编译选项
    cmpOpts += ';' + bldConf.GetCCompileOptions().replace('$(shell', '$(')

    # clang 不接受 -g3 参数
    cmpOpts = cmpOpts.replace('-g3', '-g')

    opts += cmpOpts.split(';')

    pprOpts = bldConf.GetPreprocessor()

    for i in pprOpts.split(';'):
        if i:
            opts.append('-D%s' % i)

    vim.command("let l:ret = '%s'" % ' '.join(opts).encode('utf-8'))
GetVLWProjectCompileOpts(vim.eval('a:projName'))
PYTHON_EOF
    return l:ret
endfunction

function! s:InitVLWProjectClangPCH(projName) "{{{2
    if !g:VLWorkspaceHasStarted
        return
    endif

    py ds = Globals.DirSaver()
    py project = ws.VLWIns.FindProjectByName(vim.eval('a:projName'))
    py if project and os.path.exists(project.dirName): os.chdir(project.dirName)

    py vim.command("let l:pchHeader = '%s'" 
                \% (os.path.join(project.dirName, project.name) + '_VLWPCH.h'))
    if filereadable(l:pchHeader)
        let l:cmpOpts = s:GetVLWProjectCompileOpts(a:projName)
        let b:command = 'clang -x c++-header ' . l:pchHeader . ' ' . l:cmpOpts
                    \. ' -fno-exceptions -fnext-runtime' 
                    \. ' -o ' . l:pchHeader . '.pch'
        call system(b:command)
    endif

    py del project
    py del ds
endfunction
"}}}1
"=================== Batch Build 设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:ID_BatchBuildSettingsNames = 100
let s:ID_BatchBuildSettingsOrder = 101

function! s:WspBatchBuildSettings() "{{{2
    let dlg = s:CreateBatchBuildSettingsDialog()
    call dlg.Display()
endfunction

function! s:BBS_NewSetCbk(ctl, data) "{{{2
    echohl Question
    let sNewSet = input("Enter Name:\n")
    echohl None
    if sNewSet ==# ''
        return 0
    endif

    let ctl = a:ctl
    let nSetsID = s:ID_BatchBuildSettingsNames
    let nListID = s:ID_BatchBuildSettingsOrder
    let dlg = ctl.owner
    let dSetsCtl = dlg.GetControlByID(nSetsID)
    let dListCtl = dlg.GetControlByID(nListID)

    if !empty(dSetsCtl)
        "检查同名
        if index(dSetsCtl.GetItems(), sNewSet) != -1
            echohl ErrorMsg
            echo printf("The same name already exists: '%s'", sNewSet)
            echohl None
            return 0
        endif

        call dSetsCtl.AddItem(sNewSet)
        call dSetsCtl.SetValue(sNewSet)
        call dlg.RefreshCtl(dSetsCtl)

        "更新 data
        let dData = dSetsCtl.GetData()
        let dData[sNewSet] = []
        "保存当前的
        let sCurSet = dListCtl.GetData()
        if has_key(dData, sCurSet)
            call filter(dData[sCurSet], 0)
            for lLine in dListCtl.table
                if lLine[0]
                    call add(dData[sCurSet], lLine[1])
                endif
            endfor
        endif
        call dSetsCtl.SetData(dData)

        if !empty(dListCtl)
            call dListCtl.DeleteAllLines()
            py vim.command(
                        \'let lProjectNames = %s' % ws.VLWIns.GetProjectList())
            for sProjectName in lProjectNames
                call dListCtl.AddLineByValues(0, sProjectName)
            endfor
            call dListCtl.SetData(dSetsCtl.GetValue())
            call dlg.RefreshCtl(dListCtl)
        endif
    endif

    return 0
endfunction

function! s:BBS_DeleteSetCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let nSetsID = s:ID_BatchBuildSettingsNames
    let nListID = s:ID_BatchBuildSettingsOrder
    let dlg = ctl.owner
    let dSetsCtl = dlg.GetControlByID(nSetsID)
    let dListCtl = dlg.GetControlByID(nListID)

    if empty(dSetsCtl) || dSetsCtl.GetValue() ==# 'Default'
        "不能删除默认组
        return 0
    endif

    if !empty(dSetsCtl)
        let sCurSet = dSetsCtl.GetValue()
        let data = dSetsCtl.GetData()
        if has_key(data, sCurSet)
            call remove(data, sCurSet)
        endif
        call dSetsCtl.RemoveItem(sCurSet)
        call dlg.RefreshCtl(dSetsCtl)

        " 刷新 order 列表
        call s:BBS_ChangeBatchBuildNameCbk(dSetsCtl, '')
    endif

    return 0
endfunction

function! s:BBS_ChangeBatchBuildNameCbk(ctl, data) "{{{2
    let dlg = a:ctl.owner
    let dSetsCtl = dlg.GetControlByID(s:ID_BatchBuildSettingsNames)
    let dListCtl = dlg.GetControlByID(s:ID_BatchBuildSettingsOrder)
    let dData = dSetsCtl.GetData()
    let sCurSet = dListCtl.GetData()

    "更新 data
    if has_key(dData, sCurSet)
        call filter(dData[sCurSet], 0)
        for lLine in dListCtl.table
            if lLine[0]
                call add(dData[sCurSet], lLine[1])
            endif
        endfor
    endif

    call dListCtl.DeleteAllLines()
    py vim.command('let lProjectNames = %s' % ws.VLWIns.GetProjectList())
    let lBatchBuild = dData[dSetsCtl.GetValue()]
    for sProjectName in lBatchBuild
        call dListCtl.AddLineByValues(1, sProjectName)
        " 删除另一个列表中对应的项
        let nIdx = index(lProjectNames, sProjectName)
        if nIdx != -1
            call remove(lProjectNames, nIdx)
        endif
    endfor
    for sProjectName in lProjectNames
        call dListCtl.AddLineByValues(0, sProjectName)
    endfor
    call dListCtl.SetData(dSetsCtl.GetValue())
    call dlg.RefreshCtl(dListCtl)
endfunction

function! s:BatchBuildSettingsSaveCbk(dlg, data) "{{{2
    let dSetsCtl = a:dlg.GetControlByID(s:ID_BatchBuildSettingsNames)
    let dListCtl = a:dlg.GetControlByID(s:ID_BatchBuildSettingsOrder)
    let dData = dSetsCtl.GetData()
    let sCurSet = dListCtl.GetData()

    "更新 data
    if has_key(dData, sCurSet)
        call filter(dData[sCurSet], 0)
        for lLine in dListCtl.table
            if lLine[0]
                call add(dData[sCurSet], lLine[1])
            endif
        endfor
    endif

    "直接字典间赋值
    py ws.VLWSettings.batchBuild = vim.eval("dSetsCtl.GetData()")
    py ws.VLWSettings.Save()
endfunction

function! s:CreateBatchBuildSettingsDialog() "{{{2
    let dlg = g:VimDialog.New("== Batch Build Settings ==")

    let ctl = g:VCStaticText.New('Batch Build')
    call ctl.SetIndent(4)
    call dlg.AddControl(ctl)

    " 按钮
    let ctl = g:VCButtonLine.New('')
    call ctl.SetIndent(4)
    call ctl.AddButton('New Set...')
    call ctl.AddButton('Delete Set')
    call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:BBS_NewSetCbk'), '')
    call ctl.ConnectButtonCallback(1, s:GetSFuncRef('s:BBS_DeleteSetCbk'), '')
    call dlg.AddControl(ctl)

    " 组合框
    let ctl = g:VCComboBox.New('')
    let dSetsCtl = ctl
    call ctl.SetId(s:ID_BatchBuildSettingsNames)
    call ctl.SetIndent(4)
    py vim.command("let lNames = %s" % ws.VLWSettings.GetBatchBuildNames())
    for sName in lNames
        call ctl.AddItem(sName)
    endfor
    call ctl.ConnectActionPostCallback(
                \s:GetSFuncRef('s:BBS_ChangeBatchBuildNameCbk'), '')
    call dlg.AddControl(ctl)

    " 顺序列表控件
    py vim.command('let lProjectNames = %s' % ws.VLWIns.GetProjectList())
    py vim.command('let lBatchBuild = %s' 
                \% ws.VLWSettings.GetBatchBuildList('Default'))

    let ctl = g:VCTable.New('', 2)
    let dListCtl = ctl
    call ctl.SetId(s:ID_BatchBuildSettingsOrder)
    call ctl.SetIndent(4)
    call ctl.SetDispHeader(0)
    call ctl.SetCellEditable(0)
    call ctl.DisableButton(0)
    call ctl.DisableButton(1)
    call ctl.DisableButton(2)
    call ctl.DisableButton(5)
    call ctl.SetColType(1, ctl.CT_CHECK)
    for sProjectName in lBatchBuild
        call ctl.AddLineByValues(1, sProjectName)
        " 删除另一个列表中对应的项
        let nIdx = index(lProjectNames, sProjectName)
        if nIdx != -1
            call remove(lProjectNames, nIdx)
        endif
    endfor
    for sProjectName in lProjectNames
        call ctl.AddLineByValues(0, sProjectName)
    endfor
    call dlg.AddControl(ctl)

    " 保存整个字典. 只要字典的字符串不存在单引号和转义字符(反斜杠)就不会有问题
    py vim.command("let dData = %s" % ws.VLWSettings.batchBuild)
    call dSetsCtl.SetData(dData)

    " 保存当前所属的 set 名字，在 change callback 里面有用
    call dListCtl.SetData(dSetsCtl.GetValue())

    call dlg.ConnectSaveCallback(
                \s:GetSFuncRef("s:BatchBuildSettingsSaveCbk"), '')

    call dlg.AddFooterButtons()
    return dlg
endfunction
"}}}1
"=================== 工作空间构建设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:WspConfigurationCtlID = 10
let s:BuildMatrixMappingGID = 11


function! s:WspBuildConfigManager() "{{{2
    let dlg = s:CreateWspBuildConfDialog()
    call dlg.Display()
endfunction

function! s:NewConfigCbk(dlg, data) "{{{2
    let dlg = a:dlg
    let comboCtl = a:data
    let newConfName = ''
    let copyFrom = '--None--'
    for ctl in dlg.controls
        if ctl.id == 1
            let newConfName = ctl.value
        elseif ctl.id == 2
            let copyFrom = ctl.value
        endif
    endfor

    if newConfName != ''
        if index(comboCtl.GetItems(), newConfName) != -1
            "存在同名设置
            echohl ErrorMsg
            echo "Create failed, existing a similar name."
            echohl None
            return
        endif

        let projName = comboCtl.data
        call comboCtl.InsertItem(newConfName, -2)
python << PYTHON_EOF
def NewBuildConfig(projName, newConfName, copyFrom):
    from BuildConfig import BuildConfig
    project = ws.VLWIns.FindProjectByName(projName)
    if not project:
        return

    settings = project.GetSettings()
    if copyFrom == '--None--':
        newBldConf = BuildConfig()
    else:
        newBldConf = settings.GetBuildConfiguration(copyFrom).Clone()
    newBldConf.name = newConfName
    settings.SetBuildConfiguration(newBldConf)
    project.SetSettings(settings)
    del BuildConfig
NewBuildConfig(
    vim.eval('projName'), 
    vim.eval('newConfName'), 
    vim.eval('copyFrom'))
PYTHON_EOF
    endif
endfunction

function! s:WspBCMRenameCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let comboCtl = a:data
    let projName = comboCtl.data
    if ctl.id == 3
        "重命名项目构建设置
        if ctl.selection <= 0
            return
        endif
        "重命名项目构建设置
        let line = ctl.GetLine(ctl.selection)
        let oldBcName = line[0]
        let newBcName = input("Enter New Name:\n", oldBcName)
        if newBcName != '' && newBcName != oldBcName
python << PYTHON_EOF
def RenameProjectBuildConfig(projName, oldBcName, newBcName):
    '''可能重命名失败, 当同名的配置已经存在的时候
    
    若重命名失败, 则还原显示, 什么都不做'''
    project = ws.VLWIns.FindProjectByName(projName)
    if not project or oldBcName == newBcName:
        return

    settings = project.GetSettings()
    oldBldConf = settings.GetBuildConfiguration(oldBcName)
    if not oldBldConf:
        return

    if settings.GetBuildConfiguration(newBcName):
        # 存在同名配置
        vim.command("echohl ErrorMsg")
        vim.command('echo "Rename failed, existing a similar name."')
        vim.command("echohl None")
        return

    # 修改项目文件
    settings.RemoveConfiguration(oldBcName)
    oldBldConf.SetName(newBcName)
    settings.SetBuildConfiguration(oldBldConf)
    project.SetSettings(settings)

    # 修改工作空间文件
    matrix = ws.VLWIns.GetBuildMatrix()
    for configuration in matrix.GetConfigurations():
        for mapping in configuration.GetConfigMappingList():
            if mapping.name == oldBcName:
                mapping.name = newBcName
    ws.VLWIns.SetBuildMatrix(matrix)

    # 更新当前窗口显示
    vim.command("let line[0] = newBcName")
    # 更新父窗口组合框显示
    vim.command("call comboCtl.RenameItem(oldBcName, newBcName)")
    vim.command("call comboCtl.owner.RefreshCtl(comboCtl)")

RenameProjectBuildConfig(
    vim.eval('projName'), 
    vim.eval('oldBcName'), 
    vim.eval('newBcName'))
PYTHON_EOF
        endif
    elseif ctl.id == 4
        "重命名工作空间 BuildMatrix
        if ctl.selection <= 0
            return
        endif
        let line = ctl.GetLine(ctl.selection)
        let oldConfName = line[0]
        let newConfName = input("Enter New Configuration Name:\n", oldConfName)
        if newConfName != '' && newConfName != oldConfName
python << PYTHON_EOF
def RenameWorkspaceConfiguration(oldConfName, newConfName):
    if not newConfName or newConfName == oldConfName:
        return

    matrix = ws.VLWIns.GetBuildMatrix()
    oldWspConf = matrix.GetConfigurationByName(oldConfName)

    if not oldWspConf:
        return
    if matrix.GetConfigurationByName(newConfName):
        # 存在同名配置
        vim.command("echohl ErrorMsg")
        vim.command('echo "Rename failed, existing a similar name."')
        vim.command("echohl None")
        return

    matrix.RemoveConfiguration(oldConfName)
    oldWspConf.SetName(newConfName)
    matrix.SetConfiguration(oldWspConf)
    ws.VLWIns.SetBuildMatrix(matrix)

    # 更新当前窗口表格
    vim.command("let line[0] = newConfName")
    # 更新父窗口组合框
    vim.command("call comboCtl.RenameItem(oldConfName, newConfName)")
    vim.command("call comboCtl.owner.RefreshCtl(comboCtl)")

RenameWorkspaceConfiguration(vim.eval('oldConfName'), vim.eval('newConfName'))
PYTHON_EOF
        call s:RefreshStatusLine()
        endif
    endif
endfunction

function! s:WspBCMRemoveCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let comboCtl = a:data
    let projName = comboCtl.data
    if len(ctl.table) == 1
        echohl ErrorMsg
        echo "Can not remove the last configuration."
        echohl None
        return
    endif

    if ctl.id == 3
        "删除项目的构建设置
        if ctl.selection <= 0
            return
        endif
        let line = ctl.GetLine(ctl.selection)
        let bldConfName = line[0]
        echohl WarningMsg
        let input = input("Remove configuration \""
                    \.bldConfName."\"? (y/n): ", 'y')
        echohl None
        if input == 'y'
            call ctl.DeleteLine(ctl.selection)
            let ctl.selection = 0
            "更新组合框
            call comboCtl.RemoveItem(bldConfName)
            call comboCtl.owner.RefreshCtl(comboCtl)
python << PYTHON_EOF
def RemoveProjectBuildConfig(projName, bldConfName):
    project = ws.VLWIns.FindProjectByName(projName)
    if not project:
        return

    settings = project.GetSettings()
    settings.RemoveConfiguration(bldConfName)
    project.SetSettings(settings)

    # 修正工作空间文件
    matrix = ws.VLWIns.GetBuildMatrix()
    for configuration in matrix.GetConfigurations():
        for mapping in configuration.GetConfigMappingList():
            if mapping.name == bldConfName:
                # 随便选择一个可用的补上
                mapping.name = settings.GetFirstBuildConfiguration().GetName()
    ws.VLWIns.SetBuildMatrix(matrix)

RemoveProjectBuildConfig(vim.eval('projName'), vim.eval('bldConfName'))
PYTHON_EOF
        endif
    elseif ctl.id == 4
        "删除工作空间 BuildMatrix 的 config
        if ctl.selection <= 0
            return
        endif
        let configName = ctl.GetLine(ctl.selection)[0]
        echohl WarningMsg
        let input = input("Remove workspace configuration \""
                    \.configName."\"? (y/n): ", 'y')
        echohl None
        if input == 'y'
            call ctl.DeleteLine(ctl.selection)
            let ctl.selection = 0
            "更新组合框
            call comboCtl.RemoveItem(configName)
            call comboCtl.owner.RefreshCtl(comboCtl)
python << PYTHON_EOF
def RemoveWorkspaceConfiguration(confName):
    if not confName: return
    matrix = ws.VLWIns.GetBuildMatrix()
    matrix.RemoveConfiguration(confName)
    ws.VLWIns.SetBuildMatrix(matrix)

RemoveWorkspaceConfiguration(vim.eval('configName'))
PYTHON_EOF
            " 刷新工作区的状态栏显示
            call s:RefreshStatusLine()
            " 再刷新所有项目对应的构建设置控件
            call s:WspBCMActionPostCbk(comboCtl, '*')
        endif
    endif
endfunction

function! s:WspBCMChangePreCbk(ctl, data) "{{{2
    "返回 1 表示不继续处理控件的 Action
    "目的在于保存改变前的值
    let ctl = a:ctl
    let dlg = ctl.owner
    call ctl.SetData(ctl.GetValue())

    return 0
endfunction

function! s:WspBCMActionPostCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let dlg = a:ctl.owner
    if a:ctl.id == s:WspConfigurationCtlID
    "工作空间的构建设置
        let wspSelConfName = a:ctl.GetValue()
        if wspSelConfName == '<New...>'
            echohl Question
            let input = input("\nEnter New Configuration Name:\n")
            echohl None
            let copyFrom = a:ctl.GetPrevValue()
            call a:ctl.SetValue(copyFrom)
            if input != ''
                if index(a:ctl.GetItems(), input) != -1
                    "存在同名
                    echohl ErrorMsg
                    echo "Create failed, existing a similar name."
                    echohl None
                    return 1
                endif

                call a:ctl.InsertItem(input, -2)
python << PYTHON_EOF
def NewWspConfig(newConfName, copyFrom):
    if not newConfName or not copyFrom:
        return

    matrix = ws.VLWIns.GetBuildMatrix()
    copyFromConf = matrix.GetConfigurationByName(copyFrom)
    if not copyFromConf:
        wspSelConfName = matrix.GetSelectedConfigurationName()
        newWspConf = matrix.GetConfigurationByName(wspSelConfName)
    else:
        newWspConf = copyFromConf.Clone()
    newWspConf.SetName(newConfName)
    matrix.SetConfiguration(newWspConf)
    ws.VLWIns.SetBuildMatrix(matrix)
NewWspConfig(vim.eval('input'), vim.eval('copyFrom'))
PYTHON_EOF
            endif
        elseif wspSelConfName == '<Edit...>'
            call a:ctl.SetValue(a:ctl.GetPrevValue())
            let editConfigsDlg = g:VimDialog.New(
                        \'Edit Wrokspace Configurations', dlg)
            let newCtl = g:VCTable.New('')
            call editConfigsDlg.AddControl(newCtl)
            call newCtl.SetDispHeader(0)
            call newCtl.SetId(4)
            call newCtl.ConnectBtnCallback(
                        \2, s:GetSFuncRef('s:WspBCMRenameCbk'), a:ctl)
            call newCtl.ConnectBtnCallback(
                        \1, s:GetSFuncRef('s:WspBCMRemoveCbk'), a:ctl)
            call newCtl.SetCellEditable(0)
            call newCtl.DisableButton(0)
            call newCtl.DisableButton(3)
            call newCtl.DisableButton(4)
            call newCtl.DisableButton(5)
            for item in a:ctl.GetItems()
                if item != '<New...>' && item != '<Edit...>'
                    call newCtl.AddLineByValues(item)
                endif
            endfor
            call editConfigsDlg.AddCloseButton()
            call editConfigsDlg.Display()
        else
            let bModified = dlg.GetData()
            if bModified
                echohl WarningMsg
                let sAnswer = input("Settings for workspace configuration '"
                            \. a:ctl.GetData()
                            \."' have been changed, would you like to save"
                            \." them? (y/n): ", "y")
                echohl None
                if sAnswer ==? 'y'
                    redraw
                    "保存前切换到之前的值
                    let bak_value = ctl.GetValue()
                    call ctl.SetValue(ctl.GetData())
                    silent call dlg.Save()
                    call ctl.SetValue(bak_value)
                elseif sAnswer ==? 'n'
                    "继续
                else
                    "返回
                    call ctl.SetValue(ctl.GetData())
                    return 1
                endif
            endif
            py matrix = ws.VLWIns.GetBuildMatrix()
            for ctl in dlg.controls
                if ctl.gId == s:BuildMatrixMappingGID
                    let projName = ctl.data
                    py vim.command("call ctl.SetValue('%s')" 
                                \% matrix.GetProjectSelectedConf(
                                \vim.eval("wspSelConfName"), 
                                \vim.eval("projName")))
                    "echo ctl.GetData()
                endif
                if !empty(a:data)
                    "刷新控件. WspBCMRemoveCbk() 中调用是使用
                    call dlg.RefreshCtlByGId(s:BuildMatrixMappingGID)
                endif
            endfor
            py del matrix
            if empty(a:data)
                call dlg.RefreshAll()
            endif
            "标记为未修改
            call dlg.SetData(0)
        endif
    else
    "项目的构建设置
        let value = ctl.GetValue()
        if value == '<New...>'
            call a:ctl.SetValue(a:ctl.GetPrevValue())
            let newConfDlg = g:VimDialog.New('New Configuration', dlg)
            let newCtl = g:VCSingleText.New('Configuration Name:')
            call newCtl.SetId(1)
            call newConfDlg.AddControl(newCtl)
            call newConfDlg.AddBlankLine()

            let newCtl = g:VCComboBox.New('Copy Settings From:')
            call newCtl.SetId(2)
            call newCtl.AddItem('--None--')
            for item in ctl.GetItems()
                if item != '<New...>' && item != '<Edit...>'
                    call newCtl.AddItem(item)
                endif
            endfor
            call newConfDlg.ConnectSaveCallback(s:GetSFuncRef('s:NewConfigCbk'),
                        \ctl)
            call newConfDlg.AddControl(newCtl)
            call newConfDlg.AddFooterButtons()
            call newConfDlg.Display()
        elseif value == '<Edit...>'
            call a:ctl.SetValue(a:ctl.GetPrevValue())
            let editConfigsDlg = g:VimDialog.New('Edit Configurations', dlg)
            let newCtl = g:VCTable.New('')
            call editConfigsDlg.AddControl(newCtl)
            call newCtl.SetDispHeader(0)
            call newCtl.SetId(3)
            call newCtl.ConnectBtnCallback(
                        \2, s:GetSFuncRef('s:WspBCMRenameCbk'), a:ctl)
            call newCtl.ConnectBtnCallback(
                        \1, s:GetSFuncRef('s:WspBCMRemoveCbk'), a:ctl)
            call newCtl.SetCellEditable(0)
            call newCtl.DisableButton(0)
            call newCtl.DisableButton(3)
            call newCtl.DisableButton(4)
            call newCtl.DisableButton(5)
            for item in ctl.GetItems()
                if item != '<New...>' && item != '<Edit...>'
                    call newCtl.AddLineByValues(item)
                endif
            endfor
            call editConfigsDlg.AddCloseButton()
            call editConfigsDlg.Display()
        else
            "标记为已修改
            call dlg.SetData(1)
        endif
    endif
endfunction

function! s:WspBCMSaveCbk(dlg, data) "{{{2
python << PYTHON_EOF
def WspBCMSaveCbk(matrix, wspConfName, projName, confName):
    wspConf = matrix.GetConfigurationByName(wspConfName)
    if wspConf:
        for mapping in wspConf.GetMapping():
            if mapping.project == projName:
                mapping.name = confName
                break
PYTHON_EOF
    let dlg = a:dlg
    let wspConfName = ''
    py matrix = ws.VLWIns.GetBuildMatrix()
    for ctl in dlg.controls
        if ctl.GetId() == s:WspConfigurationCtlID
            let wspConfName = ctl.GetValue()
        elseif ctl.GetGId() == s:BuildMatrixMappingGID
            let projName = ctl.GetData()
            let confName = ctl.GetValue()
            py WspBCMSaveCbk(matrix, vim.eval('wspConfName'), 
                        \vim.eval('projName'), vim.eval('confName'))
        endif
    endfor

    "保存
    py ws.VLWIns.SetBuildMatrix(matrix)
    py del matrix

    "重置为未修改
    call dlg.SetData(0)
endfunction

function! s:CreateWspBuildConfDialog() "{{{2
    let wspBCMDlg = g:VimDialog.New('==Workspace Build Configuration==')
python << PYTHON_EOF
def CreateWspBuildConfDialog():
    matrix = ws.VLWIns.GetBuildMatrix()
    wspSelConfName = matrix.GetSelectedConfigurationName()
    vim.command("let ctl = g:VCComboBox.New('Workspace Configuration:')")
    vim.command("call ctl.SetId(s:WspConfigurationCtlID)")
    vim.command("call wspBCMDlg.AddControl(ctl)")
    for wspConf in matrix.configurationList:
        vim.command("call ctl.AddItem('%s')" % wspConf.name)
    vim.command("call ctl.SetValue('%s')" % wspSelConfName)
    vim.command("call ctl.AddItem('<New...>')")
    vim.command("call ctl.AddItem('<Edit...>')")
    vim.command("call ctl.ConnectActionCallback("\
            "s:GetSFuncRef('s:WspBCMChangePreCbk'), '')")
    vim.command("call ctl.ConnectActionPostCallback("\
            "s:GetSFuncRef('s:WspBCMActionPostCbk'), '')")
    vim.command("call wspBCMDlg.AddSeparator()")
    vim.command("call wspBCMDlg.AddControl("\
            "g:VCStaticText.New('Available project configurations:'))")
    vim.command("call wspBCMDlg.AddBlankLine()")

    projectNameList = ws.VLWIns.projects.keys()
    projectNameList.sort(Globals.Cmp)
    for projName in projectNameList:
        project = ws.VLWIns.FindProjectByName(projName)
        vim.command("let ctl = g:VCComboBox.New('%s')" % projName)
        vim.command("call ctl.SetGId(s:BuildMatrixMappingGID)")
        vim.command("call ctl.SetData('%s')" % projName)
        vim.command("call ctl.SetIndent(4)")
        vim.command("call ctl.ConnectActionPostCallback("\
                "s:GetSFuncRef('s:WspBCMActionPostCbk'), '')")
        vim.command("call wspBCMDlg.AddControl(ctl)")
        for confName in project.GetSettings().configs.keys():
            vim.command("call ctl.AddItem('%s')" % confName)
        projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                        projName)
        vim.command("call ctl.SetValue('%s')" % projSelConfName)
        vim.command("call ctl.AddItem('<New...>')")
        vim.command("call ctl.AddItem('<Edit...>')")
        vim.command("call wspBCMDlg.AddBlankLine()")
CreateWspBuildConfDialog()
PYTHON_EOF
    call wspBCMDlg.SetData(0)
    call wspBCMDlg.ConnectSaveCallback(s:GetSFuncRef('s:WspBCMSaveCbk'), '')
    call wspBCMDlg.AddFooterButtons()
    return wspBCMDlg
endfunction
"}}}1
"=================== 工作空间设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:ID_WspSettingsEnvironment = 9
let s:ID_WspSettingsIncludePaths = 10
let s:ID_WspSettingsTagsTokens = 11
let s:ID_WspSettingsTagsTypes = 12


function! s:WspSettings() "{{{2
    let g:wspSettings = s:CreateWspSettingsDialog()
    call g:wspSettings.Display()
endfunction

function! s:EditTextBtnCbk(ctl, data) "{{{2
    let l:editDialog = g:VimDialog.New('Edit', a:ctl.owner)
    let content = a:ctl.GetValue()
    call l:editDialog.SetIsPopup(1)
    call l:editDialog.SetAsTextCtrl(1)
    call l:editDialog.SetTextContent(content)
    call l:editDialog.ConnectSaveCallback(
                \s:GetSFuncRef('s:EditTextSaveCbk'), a:ctl)
    call l:editDialog.Display()
endfunction

function! s:EditTextSaveCbk(dlg, data) "{{{2
    let textsList = getline(1, '$')
    call filter(textsList, 'v:val !~ "^\\s\\+$\\|^$"')
    call a:data.SetValue(textsList)
    call a:data.owner.RefreshCtl(a:data)
endfunction

function! s:SaveWspSettingsCbk(dlg, data) "{{{2
    for ctl in a:dlg.controls
        if ctl.GetId() == s:ID_WspSettingsEnvironment
            py ws.VLWSettings.SetEnvVarSetName(vim.eval("ctl.GetValue()"))
        elseif ctl.GetId() == s:ID_WspSettingsIncludePaths
            let table = ctl.table
            py del ws.VLWSettings.includePaths[:]
            for line in table
                py ws.VLWSettings.includePaths.append(vim.eval("line[0]"))
            endfor
        elseif ctl.GetId() == s:ID_WspSettingsTagsTokens
            py ws.VLWSettings.tagsTokens = vim.eval("ctl.values")
        elseif ctl.GetId() == s:ID_WspSettingsTagsTypes
            py ws.VLWSettings.tagsTypes = vim.eval("ctl.values")
        endif
    endfor
    "保存
    py ws.SaveWspSettings()
    "重新初始化 Omnicpp 类型替换字典
    py ws.InitOmnicppTypesVar()
endfunction

function! s:AddSearchPathCbk(ctl, data) "{{{2
    echohl Question
    let input = input("Add Parser Search Path:\n")
    echohl None
    if input != ''
        call a:ctl.AddLineByValues(input)
    endif
endfunction

function! s:EditSearchPathCbk(ctl, data) "{{{2
    let value = a:ctl.GetSelectedLine()[0]
    echohl Question
    let input = input("Edit Search Path:\n", value)
    echohl None
    if input != '' && input != value
        call a:ctl.SetCellValue(a:ctl.selection, 1, input)
    endif
endfunction

function! s:CreateWspSettingsDialog() "{{{2
    let wspSettingsDlg = g:VimDialog.New('==Workspace Settings==')

"===============================================================================
    "1.Environment
    let ctl = g:VCStaticText.New("Environment")
    call ctl.SetHighlight("Special")
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

    let ctl = g:VCComboBox.New('Environment sets:')
    call ctl.SetId(s:ID_WspSettingsEnvironment)
    call ctl.SetIndent(4)
    py vim.command("let lEnvVarSets = %s" 
                \% EnvVarSettingsST.Get().envVarSets.keys())
    call sort(lEnvVarSets)
    for sEnvVarSet in lEnvVarSets
        call ctl.AddItem(sEnvVarSet)
    endfor
    py vim.command("call ctl.SetValue('%s')" % 
                \ws.VLWSettings.GetEnvVarSetName())
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

"===============================================================================
    "2.Include Files
    let ctl = g:VCStaticText.New("Tags Setttings")
    call ctl.SetHighlight("Special")
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

    let ctl = g:VCTable.New('Add search paths for the parser.', 1)
    call ctl.SetId(s:ID_WspSettingsIncludePaths)
    call ctl.SetIndent(4)
    call ctl.SetDispHeader(0)
    py vim.command("let includePaths = %s" % ws.VLWSettings.includePaths)
    for includePath in includePaths
        call ctl.AddLineByValues(includePath)
    endfor
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:AddSearchPathCbk'), '')
    call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EditSearchPathCbk'), '')
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

    let ctl = g:VCMultiText.New("Tokens")
    call ctl.SetId(s:ID_WspSettingsTagsTokens)
    call ctl.SetIndent(4)
    py vim.command("let tagsTokens = %s" % ws.VLWSettings.tagsTokens)
    call ctl.SetValue(tagsTokens)
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditTextBtnCbk"), "")
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

    let ctl = g:VCMultiText.New("Types")
    call ctl.SetId(s:ID_WspSettingsTagsTypes)
    call ctl.SetIndent(4)
    py vim.command("let tagsTypes = %s" % ws.VLWSettings.tagsTypes)
    call ctl.SetValue(tagsTypes)
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditTextBtnCbk"), "")
    call wspSettingsDlg.AddControl(ctl)
    call wspSettingsDlg.AddBlankLine()

    call wspSettingsDlg.ConnectSaveCallback(
                \s:GetSFuncRef("s:SaveWspSettingsCbk"), "")

    call wspSettingsDlg.AddFooterButtons()
    return wspSettingsDlg
endfunction
"}}}1
"=================== 项目设置 ===================
"{{{1
"标识用控件 ID {{{2
let s:CommonCompilerGID = 1
let s:CommonLinkerGID = 2
let s:CommonResourcesGID = 3

let s:CustomBuildGID = 5
let s:DebugArgumentsGID = 6

let s:PreBuildTableID = 10
let s:PostBuildTableID = 11
let s:CustomBuildTableID = 12


function! s:InitProjectSettingsGlobalVars(projName, confName) "{{{2
    " 4 个用于项目设置的全局变量, 都是字典, 以项目名称为键值
    " g_projects
    " g_settings
    " g_bldConfs
    " g_glbBldConfs
python << PYTHON_EOF
projName = vim.eval('a:projName')
confName = vim.eval('a:confName')
matrix = ws.VLWIns.GetBuildMatrix()
if not confName:
    wsConfig = matrix.GetSelectedConfigurationName()
    confName = matrix.GetProjectSelectedConf(wsConfig, projName)
    del wsConfig
g_projects[projName] = ws.VLWIns.FindProjectByName(projName)
g_settings[projName] = g_projects[projName].GetSettings()
g_bldConfs[projName] = g_settings[projName].GetBuildConfiguration(confName, False)
g_glbBldConfs[projName] = g_settings[projName].GetGlobalSettings()
del matrix
del confName
del projName
PYTHON_EOF
endfunction

function! s:ActiveIfCheckCbk(ctl, data) "{{{2
    let bool = a:ctl.GetValue()
    for ctl in a:ctl.owner.controls
        if ctl.gId == a:data
            if bool
                call ctl.SetActivated(1)
            else
                call ctl.SetActivated(0)
            endif
        endif
    endfor
    call a:ctl.owner.RefreshCtlByGId(a:data)
endfunction

function! s:ActiveIfUnCheckCbk(ctl, data) "{{{2
    let bool = a:ctl.GetValue()
    for ctl in a:ctl.owner.controls
        if ctl.gId == a:data
            if !bool
                call ctl.SetActivated(1)
            else
                call ctl.SetActivated(0)
            endif
        endif
    endfor
    call a:ctl.owner.RefreshCtlByGId(a:data)
endfunction

function! s:ActiveIfCheckCbk(ctl, data) "{{{2
    let bool = a:ctl.GetValue()
    for ctl in a:ctl.owner.controls
        if ctl.gId == a:data
            if bool
                call ctl.SetActivated(1)
            else
                call ctl.SetActivated(0)
            endif
        endif
    endfor
    call a:ctl.owner.RefreshCtlByGId(a:data)
endfunction

function! s:BindPreBuildTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
    call ctl.DeleteAllLines()
python << PYTHON_EOF
def BindPreBuildTblCbk(projName):
    for i in g_bldConfs[projName].preBuildCommands:
        col1 = 0
        col2 = i.command
        if i.enabled:
            col1 = 1
        # NOTE: 字符串问题，最好的方法是用单引号引用，然后替换字符串中的单引号
        #vim.command('call ctl.AddLine([%d, "%s"])' % (col1, col2))
        vim.command("call ctl.AddLine([%d, '%s'])" 
             % (col1, col2.replace("'", "''")))
BindPreBuildTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:UpdatePreBuildTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
python << PYTHON_EOF
def UpdatePreBuildTblCbk(projName):
    table = vim.eval('ctl.table')
    from BuildConfig import BuildCommand
    del g_bldConfs[projName].preBuildCommands[:]
    for line in table:
        col1 = line[0]
        col2 = line[1]
        enabled = False
        command = col2
        if col1 == '1':
            enabled = True
        cmd = BuildCommand(command, enabled)
        g_bldConfs[projName].preBuildCommands.append(cmd)
    del BuildCommand
UpdatePreBuildTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:BindPostBuildTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
    call ctl.DeleteAllLines()
python << PYTHON_EOF
def BindPostBuildTblCbk(projName):
    for i in g_bldConfs[projName].postBuildCommands:
        col1 = 0
        col2 = i.command
        if i.enabled:
            col1 = 1
        vim.command("call ctl.AddLine([%d, '%s'])" 
             % (col1, col2.replace("'", "''")))
BindPostBuildTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:UpdatePostBuildTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
python << PYTHON_EOF
def UpdatePostBuildTblCbk(projName):
    table = vim.eval('ctl.table')
    from BuildConfig import BuildCommand
    del g_bldConfs[projName].postBuildCommands[:]
    for line in table:
        col1 = line[0]
        col2 = line[1]
        enabled = False
        command = col2
        if col1 == '1':
            enabled = True
        cmd = BuildCommand(command, enabled)
        g_bldConfs[projName].postBuildCommands.append(cmd)
    del BuildCommand
UpdatePostBuildTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:BindCustomTargetTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
    call ctl.DeleteAllLines()
python << PYTHON_EOF
def BindCustomTargetTblCbk(projName):
    # 注意处理 python 字符串转为 vim 字符串的问题
    # 如果 python 字符串中有 ' 或 " 将出现诸多问题
    # 解决方法是用 vim 的 '' 并且把 python 的字符串中的 ' 加倍
    vim.command("call ctl.AddLine(['%s', '%s'])" 
         % ('Build', 
            g_bldConfs[projName].customBuildCmd.replace("'", "''")))
    vim.command("call ctl.AddLine(['%s', '%s'])" 
         % ('Clean', 
            g_bldConfs[projName].customCleanCmd.replace("'", "''")))
    # Rebuild 命令由 Clean 和 Build 共同构成，无须指定
#    vim.command("call ctl.AddLine(['%s', '%s'])" 
#         % ('Rebuild', 
#            g_bldConfs[projName].customRebuildCmd.replace("'", "''")))
#    vim.command("call ctl.AddLine(['%s', '%s'])" 
#         % ('Compile Single File', 
#            g_bldConfs[projName].singleFileBuildCommand.replace("'", "''")))
#    vim.command("call ctl.AddLine(['%s', '%s'])" 
#         % ('Preprocess File', 
#            g_bldConfs[projName].preprocessFileCommand.replace("'", "''")))
    sortedKeys = g_bldConfs[projName].GetCustomTargets().keys()
    sortedKeys.sort()
    for k in sortedKeys:
        v = g_bldConfs[projName].GetCustomTargets()[k]
        vim.command("call ctl.AddLine(['%s', '%s'])" 
            % (k.replace("'", "''"), v.replace("'", "''")))
BindCustomTargetTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:UpdateCustomTargetTblCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let projName = a:data
python << PYTHON_EOF
def UpdateCustomTargetTblCbk(projName):
    '''无论如何, 都不会删除掉内置的目标的.
    若在配置的时候删除了, 则会保持原始值不变'''
    table = vim.eval('ctl.table')
    g_bldConfs[projName].customTargets.clear()
    for line in table:
        target = line[0]
        command = line[1]
        if target == 'Build':
            g_bldConfs[projName].customBuildCmd = command
        elif target == 'Clean':
            g_bldConfs[projName].customCleanCmd = command
        elif target == 'Rebuild':
            g_bldConfs[projName].customRebuildCmd = command
        elif target == 'Compile Single File':
            g_bldConfs[projName].singleFileBuildCommand = command
        elif target == 'Preprocess File':
            g_bldConfs[projName].preprocessFileCommand = command
        elif target:
            g_bldConfs[projName].customTargets[target] = command
UpdateCustomTargetTblCbk(vim.eval('projName'))
PYTHON_EOF
endfunction

function! s:SelProjConfCbk(ctl, data) "{{{2
    call s:InitProjectSettingsGlobalVars(a:data, a:ctl.GetValue())
    call g:psdialogs[a:data].DeepRefreshAll()
endfunction


function! s:SaveProjectSettingsCbk(dlg, data) "{{{2
    " 想要保存设置，只能调用这个函数，而不是 Project 的 Save()
    let projName = a:data
    py g_projects[vim.eval('projName')].SetSettings(
                \g_settings[vim.eval('projName')])
    "py del g_projects[vim.eval('projName')]
    "py del g_settings[vim.eval('projName')]
    "py del g_bldConfs[vim.eval('projName')]
    "py del g_glbBldConfs[vim.eval('projName')]
    return 0
endfunction

function! s:ProjectSettings(projName) "{{{2
    if !exists('g:psdialogs')
        let g:psdialogs = {}
    endif
    let dialog = s:CreateProjectSettingsDialog(a:projName)
    if !empty(dialog)
        let g:psdialogs[a:projName] = dialog
        call g:psdialogs[a:projName].Display()
    endif
endfunction

function! s:EditOptionsBtnCbk(ctl, data) "{{{2
    let editDialog = g:VimDialog.New('Edit', a:ctl.owner)
    let content = join(split(a:ctl.GetValue(), ';'), "\n")
    if content !=# ''
        let content .= "\n"
    endif
    call editDialog.SetIsPopup(1)
    call editDialog.SetAsTextCtrl(1)
    call editDialog.SetTextContent(content)
    call editDialog.ConnectSaveCallback(
                \s:GetSFuncRef('s:EditOptionsSaveCbk'), a:ctl)
    call editDialog.Display()
endfunction

function! s:EditOptionsSaveCbk(dlg, data) "{{{2
    let textsList = getline(1, '$')
    call filter(textsList, 'v:val !~ "^\\s\\+$\\|^$"')
    call a:data.SetValue(join(textsList, ';'))
    call a:data.owner.RefreshCtl(a:data)
endfunction

function! s:AddBuildTblLineCbk(ctl, data) "{{{2
    echohl Question
    let input = input("New Command:\n")
    echohl None
    if input != ''
        call a:ctl.AddLineByValues(1, input)
    endif
endfunction
function! s:EditBuildTblLineCbk(ctl, data) "{{{2
    let value = a:ctl.GetSelectedLine()[1]
    echohl Question
    let input = input("Edit Command:\n", value)
    echohl None
    if input != '' && input != value
        call a:ctl.SetCellValue(a:ctl.selection, 2, input)
    endif
endfunction

function! s:CustomBuildTblAddCbk(ctl, data) "{{{2
    let ctl = a:ctl
    echohl Question
    let input = input("New Target:\n")
    echohl None
    if input != ''
        for lLine in ctl.table
            if lLine[0] ==# input
                echohl ErrorMsg
                echo "Target '" . input . "' already exists!"
                echohl None
                return
            endif
        endfor
        call ctl.AddLineByValues(input, '')
    endif
endfunction


function! s:CustomBuildTblSelectionCbk(ctl, data) "{{{2
    let ctl = a:ctl
    let lLine = ctl.GetSelectedLine()
    if empty(lLine)
        return
    endif

    let lHoldValue = ['Build', 'Clean', 'Rebuild', 'Compile Single File', 
                \'Preprocess File']
    if index(lHoldValue, lLine[0]) != -1
        call ctl.DisableButton(1)
    else
        call ctl.EnableButton(1)
    endif
    call ctl.owner.RefreshCtl(ctl)
endfunction


function! s:GetAvailableMacrosHelpText() "{{{2
    let vimliteHelp = '===== Available Macros: =====' . "\n"

    let vimliteHelp .= "$(User)                  "
                \."Expand to logged-in user as defined by the OS" . "\n"

    let vimliteHelp .= "$(Date)                  "
                \."Expand to current date" . "\n"

    let vimliteHelp .= "$(WorkspaceName)         "
                \."Expand to the workspace name" . "\n"

    let vimliteHelp .= "$(WorkspacePath)         "
                \."Expand to the workspace path" . "\n"

    let vimliteHelp .= "$(ProjectName)           "
                \."Expand to the project name" . "\n"

    let vimliteHelp .= "$(ProjectPath)           "
                \."Expand to the project path" . "\n"

    let vimliteHelp .= "$(ConfigurationName)     "
                \."Expand to the current project selected configuration" . "\n"

    let vimliteHelp .= "$(IntermediateDirectory) "
                \."Expand to the project intermediate directory path, " . "\n"
                \.repeat(' ', 25)."as set in the project settings" . "\n"

    let vimliteHelp .= "$(OutDir)                "
                \."An alias to $(IntermediateDirectory)" . "\n"

    let vimliteHelp .= "$(ProjectFiles)          "
                \."A space delimited string containing all of the " . "\n"
                \.repeat(' ', 25)."project files "
                \."in a relative path to the project file" . "\n"

    let vimliteHelp .= "$(ProjectFilesAbs)       "
                \."A space delimited string containing all of the " . "\n"
                \.repeat(' ', 25)."project files in an absolute path" . "\n"

    let vimliteHelp .= "$(CurrentFileName)       "
                \."Expand to current file name (without extension and " . "\n"
                \.repeat(' ', 25)."path)"."\n"

    let vimliteHelp .= "$(CurrentFileExt)        "
                \."Expand to current file extension" . "\n"

    let vimliteHelp .= "$(CurrentFilePath)       "
                \."Expand to current file path" . "\n"

    let vimliteHelp .= "$(CurrentFileFullPath)   "
                \."Expand to current file full path (path and full name)" . "\n"

    let vimliteHelp .= "`expression`             "
                \."Evaluates the expression inside the backticks into a " . "\n"
                \.repeat(' ', 25)."string" . "\n"
    return vimliteHelp
endfunction


function! s:CreateProjectSettingsDialog(projName) "{{{2
    let projName = a:projName
    if len(projName) == 0
        return
    endif

    let bufName = "== ".projName." ProjectSettings =="
    if bufwinnr(bufName) != -1
        " 如果已经打开了同名的项目配置窗口, 直接跳至此窗口后结束
        " 避免打开多个同一项目设置的窗口
        call s:exec(bufwinnr(bufName) . ' wincmd w')
        return {}
    endif

    call s:InitProjectSettingsGlobalVars(projName, '')
    let l:dialog = g:VimDialog.New(bufName)
    call l:dialog.SetExtraHelpContent(s:GetAvailableMacrosHelpText())
python << PYTHON_EOF
def ProjectSettings():
    projName = vim.eval('projName')
    vim.command('let ctl = g:VCComboBox.New("Project Configuration")')
    for i in g_settings[projName].configs:
        vim.command('call ctl.AddItem("%s")' % i.encode('utf-8'))
    vim.command('call ctl.SetValue("%s")' % g_bldConfs[projName].GetName())
    vim.command(
            'call ctl.ConnectActionPostCallback(s:GetSFuncRef("s:SelProjConfCbk"), "%s")' 
            % projName)
    vim.command('call l:dialog.AddControl(ctl)')
    vim.command('call l:dialog.AddBlankLine()')
ProjectSettings()
PYTHON_EOF

"===============================================================================
    "1.Common Settings
    call l:dialog.AddSeparator()
    let ctl = g:VCStaticText.New('Common Settings')
    call ctl.SetHighlight("Special")
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "1.1.常规设置
    let ctl = g:VCStaticText.New("General")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    "1.1.1.项目类型
    let ctl = g:VCComboBox.New('Project Type:')
    call ctl.SetIndent(8)
    call ctl.AddItem('Static Library')
    call ctl.AddItem('Dynamic Library')
    call ctl.AddItem('Executable')
    call ctl.BindVariable('g_bldConfs["'.projName.'"].projectType', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "1.1.2.编译器
    let ctl = g:VCComboBox.New('Compiler:')
    call ctl.SetIndent(8)
    call ctl.AddItem('cobra')
    call ctl.AddItem('gnu g++')
    call ctl.AddItem('gnu gcc')
    call ctl.BindVariable('g_bldConfs["'.projName.'"].compilerType', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "1.1.3.过渡文件夹
    let ctl = g:VCSingleText.New("Intermediate Directory:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].intermediateDirectory', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "1.1.4.输出文件
    let ctl = g:VCSingleText.New("Output File:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].outputFile', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Program:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].command', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Working Folder:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].workingDirectory', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Program Arguments:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].commandArguments', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCCheckItem.New("Use seperate debug arguments")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].useSeparateDebugArgs', 1)
    call ctl.ConnectActionPostCallback(s:GetSFuncRef('s:ActiveIfCheckCbk'), 
                \s:DebugArgumentsGID)
    let bUseSepDbgArgs = ctl.GetValue()
    call l:dialog.AddControl(ctl)
    "call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Debug Arguments:")
    call ctl.SetGId(s:DebugArgumentsGID)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].debugArgs', 1)
    call ctl.SetActivated(bUseSepDbgArgs)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "let ctl = g:VCCheckItem.New("Pause when execution ends")
    "call ctl.SetIndent(8)
    "call ctl.BindVariable('g_bldConfs["'.projName.'"].pauseWhenExecEnds', 1)
    "call l:dialog.AddControl(ctl)
    "call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "1.2.编译器设置
    let ctl = g:VCStaticText.New("Compiler")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCCheckItem.New('Compiler is not required for this project')
    call ctl.SetIndent(8)
    call ctl.SetReverse(1)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].compilerRequired', 1)
    call ctl.ConnectActionPostCallback(s:GetSFuncRef('s:ActiveIfUnCheckCbk'), 
                \s:CommonCompilerGID)
    let enabled = !ctl.GetValue()
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCComboBox.New('Use With Global Settings:')
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.AddItem('overwrite')
    call ctl.AddItem('append')
    call ctl.AddItem('prepend')
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].buildCmpWithGlobalSettings', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("C++ Compiler Options:")
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.compileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("C Compiler Options:")
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.cCompileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Include Paths:")
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.includePath', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    let ctl = g:VCSingleText.New("Preprocessor:")
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.preprocessor', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("g:EditOptionsBtnCbk"), '')

    let ctl = g:VCSingleText.New("PCH:")
    call ctl.SetGId(s:CommonCompilerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].precompiledHeader', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "1.3.链接器设置
    let ctl = g:VCStaticText.New("Linker")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCCheckItem.New('Linker is not required for this project')
    call ctl.SetIndent(8)
    call ctl.SetReverse(1)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].linkerRequired', 1)
    call ctl.ConnectActionPostCallback(s:GetSFuncRef('s:ActiveIfUnCheckCbk'), 
                \s:CommonLinkerGID)
    let enabled = !ctl.GetValue()
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCComboBox.New('Use With Global Settings:')
    call ctl.SetGId(s:CommonLinkerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.AddItem('overwrite')
    call ctl.AddItem('append')
    call ctl.AddItem('prepend')
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].buildLnkWithGlobalSettings', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Options:")
    call ctl.SetGId(s:CommonLinkerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.linkOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Library Paths:", '')
    call ctl.SetGId(s:CommonLinkerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].commonConfig.libPath', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    let ctl = g:VCSingleText.New("Libraries:", '')
    call ctl.SetGId(s:CommonLinkerGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].commonConfig.libs', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    "---------------------------------------------------------------------------

    "1.4.资源设置
    let ctl = g:VCStaticText.New("Resources")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCCheckItem.New('Resources Compiler is not needed')
    call ctl.SetIndent(8)
    call ctl.SetReverse(1)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].isResCmpNeeded', 1)
    call ctl.ConnectActionPostCallback(s:GetSFuncRef('s:ActiveIfUnCheckCbk'), 
                \s:CommonResourcesGID)
    let enabled = !ctl.GetValue()
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCComboBox.New('Use With Global Settings:')
    call ctl.SetGId(s:CommonResourcesGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.AddItem('overwrite')
    call ctl.AddItem('append')
    call ctl.AddItem('prepend')
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].buildResWithGlobalSettings', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Compiler Options:")
    call ctl.SetGId(s:CommonResourcesGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable(
                \'g_bldConfs["'.projName.'"].commonConfig.resCompileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Include Paths:", '')
    call ctl.SetGId(s:CommonResourcesGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName
                \   .'"].commonConfig.resCompileIncludePath', 
                \1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

"===============================================================================
    "2.Pre / Post Build Commands
    call l:dialog.AddBlankLine()
    call l:dialog.AddSeparator()
    let ctl = g:VCStaticText.New('Pre / Post Build Commands')
    call ctl.SetHighlight("Special")
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "2.1.Pre Build
    let ctl = g:VCStaticText.New("Pre Build")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCTable.New('Set the commands to run in the pre build stage:', 
                \2)
    call ctl.SetId(s:PreBuildTableID)
    call ctl.SetIndent(8)
    call ctl.SetColType(1, ctl.CT_CHECK)
    call ctl.SetDispHeader(0)
    call ctl.SetBindVarCallback(s:GetSFuncRef('s:BindPreBuildTblCbk'), projName)
    call ctl.SetUpdateBindVarCallback(
                \s:GetSFuncRef('s:UpdatePreBuildTblCbk'), projName)
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:AddBuildTblLineCbk'), '')
    call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EditBuildTblLineCbk'), '')
    call ctl.BindVariable()
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "Post Build
    let ctl = g:VCStaticText.New("Post Build")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCTable.New('Set the commands to run in the post build stage:', 
                \2)
    call ctl.SetId(s:PostBuildTableID)
    call ctl.SetIndent(8)
    call ctl.SetColType(1, ctl.CT_CHECK)
    call ctl.SetDispHeader(0)
    call ctl.SetBindVarCallback(
                \s:GetSFuncRef('s:BindPostBuildTblCbk'), projName)
    call ctl.SetUpdateBindVarCallback(
                \s:GetSFuncRef('s:UpdatePostBuildTblCbk'), projName)
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:AddBuildTblLineCbk'), '')
    call ctl.ConnectBtnCallback(2, s:GetSFuncRef('s:EditBuildTblLineCbk'), '')
    call ctl.BindVariable()
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

"===============================================================================
    "3.Customize
    call l:dialog.AddBlankLine()
    call l:dialog.AddSeparator()
    let ctl = g:VCStaticText.New('Customize')
    call ctl.SetHighlight("Special")
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "Custom Build
    let ctl = g:VCStaticText.New("Custom Build")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCCheckItem.New('Enable custom build')
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].enableCustomBuild', 1)
    call ctl.ConnectActionPostCallback(s:GetSFuncRef('s:ActiveIfCheckCbk'), 
                \s:CustomBuildGID)
    let enabled = ctl.GetValue()
    call l:dialog.AddControl(ctl)
    let sep = g:VCSeparator.New('~')
    call sep.SetIndent(8)
    call l:dialog.AddControl(sep)
"    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "工作目录
    let ctl = g:VCSingleText.New('Working Directory')
    call ctl.SetGId(s:CustomBuildGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].customBuildWorkingDir', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "Custom Build
    let ctl = g:VCTable.New('', 2)
    call ctl.SetId(s:CustomBuildTableID)
    call ctl.SetGId(s:CustomBuildGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.SetColTitle(1, 'Target')
    call ctl.SetColTitle(2, 'Command')
    call ctl.SetBindVarCallback(
                \s:GetSFuncRef('s:BindCustomTargetTblCbk'), projName)
    call ctl.SetUpdateBindVarCallback(
                \s:GetSFuncRef('s:UpdateCustomTargetTblCbk'), projName)
    call ctl.BindVariable()
    call ctl.ConnectBtnCallback(0, s:GetSFuncRef('s:CustomBuildTblAddCbk'), '')
    call ctl.ConnectSelectionCallback(
                \s:GetSFuncRef('s:CustomBuildTblSelectionCbk'), '')
    call ctl.DisableButton(2)
    call ctl.DisableButton(5)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

if 0 "不明所以的东东, 暂时禁用
    let ctl = g:VCComboBox.New('Makefile Generators:')
    call ctl.SetGId(s:CustomBuildGID)
    call ctl.SetActivated(enabled)
    call ctl.AddItem('None')
    call ctl.AddItem('Other')
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].toolName', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New('Command to use for makefile generation:')
    call ctl.SetGId(s:CustomBuildGID)
    call ctl.SetActivated(enabled)
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_bldConfs["'.projName.'"].makeGenerationCommand', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
endif "暂时禁用

"===============================================================================
    "4.Global Settings
    call l:dialog.AddBlankLine()
    call l:dialog.AddSeparator()
    let ctl = g:VCStaticText.New('Global Settings')
    call ctl.SetHighlight("Special")
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    "---------------------------------------------------------------------------

    "4.1.编译器设置
    let ctl = g:VCStaticText.New("Compiler")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCSingleText.New("C++ Compiler Options:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].compileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("C Compiler Options:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].cCompileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Include Paths:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].includePath', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    let ctl = g:VCSingleText.New("Preprocessor:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].preprocessor', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    "---------------------------------------------------------------------------

    "4.2.链接器设置
    let ctl = g:VCStaticText.New("Linker")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCSingleText.New("Options:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].linkOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Library Paths:", '')
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].libPath', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    let ctl = g:VCSingleText.New("Libraries:", '')
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].libs', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

    "---------------------------------------------------------------------------

    "4.3.资源设置
    let ctl = g:VCStaticText.New("Resources")
    call ctl.SetHighlight("Identifier")
    call ctl.SetIndent(4)
    call l:dialog.AddControl(ctl)

    let ctl = g:VCSingleText.New("Compiler Options:")
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].resCompileOptions', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()

    let ctl = g:VCSingleText.New("Include Paths:", '')
    call ctl.SetIndent(8)
    call ctl.BindVariable('g_glbBldConfs["'.projName.'"].resCompileIncludePath', 1)
    call l:dialog.AddControl(ctl)
    call l:dialog.AddBlankLine()
    call ctl.ConnectButtonCallback(s:GetSFuncRef("s:EditOptionsBtnCbk"), '')

"===============================================================================

    call l:dialog.AddFooterButtons()
    call l:dialog.ConnectSaveCallback(
                \s:GetSFuncRef("s:SaveProjectSettingsCbk"), projName)
    return l:dialog
"    call l:dialog.Display()
endfunction
"}}}1
"===============================================================================
"===============================================================================


"===============================================================================
"python 接口定义
"===============================================================================
function! s:InitPythonInterfaces() "{{{2
python << PYTHON_EOF
# -*- encoding:utf-8 -*-
import sys, os, os.path
import vim

sys.path.append(os.path.expanduser('~/.vimlite/VimLite'))
import Globals
import VLWorkspace
from VLWorkspace import VLWorkspaceST
from TagsSettings import TagsSettings
from TagsSettings import TagsSettingsST
from EnvVarSettings import EnvVar
from EnvVarSettings import EnvVarSettings
from EnvVarSettings import EnvVarSettingsST
from VLWorkspaceSettings import VLWorkspaceSettings
import BuilderGnuMake
import IncludeParser


def GetTemplateDict(dir):
    from xml.dom import minidom
    from VLProject import VLProject
    ds = Globals.DirSaver()
    try:
        os.chdir(dir)
    except OSError:
        return {}
    templates = {}
    for dir in os.listdir(dir):
        #projFile = os.path.join(dir, os.path.basename(dir) + '.'
            #+ vim.eval('g:VLWorkspacePrjFileSuffix'))
        # 模版项目的后缀是 .project
        projFile = os.path.join(dir, os.path.basename(dir) + '.' + 'project')
        if os.path.isdir(dir) and os.path.isfile(projFile):
            tmpProj = VLProject(projFile)
            internalType = tmpProj.GetProjectInternalType()

            template = {}
            template['name'] = tmpProj.GetName()
            template['file'] = tmpProj.GetFileName()
            template['desc'] = tmpProj.GetDescription()
            bldConf = tmpProj.GetSettings().GetBuildConfiguration()
            template['cmpType'] = bldConf.GetCompilerType()

            if internalType:
                if not templates.has_key(internalType):
                    templates[internalType] = []
                templates[internalType].append(template)
            else:
                if not templates.has_key('Others'):
                    templates['Others'] = []
                templates['Others'].append(template)
    return templates


def GenerateMenuList(li):
    liLen = len(li)
    if liLen:
        l = len(str(liLen - 1))
        return [li[0]] + \
                [ str('%*d. %s' % (l, i, li[i])) for i in range(1, liLen) ]
    else:
        return []


def IndicateProgress(n, m):
    vim.command("echon 'Parsing files: '")
    vim.command("call g:Progress(%d, %d)" % (n, m))


class StartEdit:
    '''用于切换缓冲区可修改状态
    在需要作用的区域，必须保持一个引用！'''
    def __init__(self):
        self.bufnr = vim.eval("bufnr('%')")
        self.bak_ma = vim.eval("getbufvar(%s, '&modifiable')" % self.bufnr)
        vim.command("setlocal modifiable")
    
    def __del__(self):
        #vim.command("setlocal nomodifiable")
        vim.command("call setbufvar(%s, '&modifiable', %s)" 
            % (self.bufnr, self.bak_ma))


class VimLiteWorkspace():
    '''VimLite 工作空间对象，主要用于操作缓冲区和窗口
    
    所有操作假定已经在工作空间缓冲区'''
    def __init__(self, fileName = ''):
        self.VLWIns = VLWorkspaceST.Get() # python VLWorkspace 对象实例
        self.builder = BuilderGnuMake.BuilderGnuMake() # 构建器实例
        self.VLWSettings = VLWorkspaceSettings() # 工作空间设置实例

        vim.command("call VimTagsManagerInit()")
        self.tagsManager = vtm # 标签管理器

        # 工作空间右键菜单列表
        self.popupMenuW = [ 'Please select an operation:', 
            'Create a New Project...', 
            'Add an Existing Project...', 
            '-Sep1-', 
            'New Workspace...', 
            'Open Workspace...', 
            'Close Workspace', 
            'Reload Workspace', 
            '-Sep2-', 
            'Batch Builds', 
            '-Sep3-', 
            'Parse Workspace (Full)', 
            'Parse Workspace (Quick)', 
            '-Sep4-', 
            'Workspace Build Configuration...', 
            'Workspace Batch Build Settings...', 
            'Workspace Settings...' ]

        if vim.eval('g:VLWorkspaceUseClangCC') != '0':
            self.popupMenuW.remove('Parse Workspace (Full)')
            self.popupMenuW.remove('Parse Workspace (Quick)')
            self.popupMenuW.remove('-Sep3-')

        # 项目右键菜单列表
        self.popupMenuP = ['Please select an operation:', 
#            'Import Files From Directroy... (Unrealized)', 
            'Build', 
            'Rebuild', 
            'Clean', 
#            'Stop Build (Unrealized)', 
            '-Sep1-', 
            'Export Makefile' ,
            '-Sep2-', 
            'Set As Active', 
            '-Sep3-', 
#            'Build Order... (Unrealized)', 
#            'Re-Tag Project (Unrealized)', 
#            'Sort Items (Unrealized)', 
            'New Virtual Folder...', 
            'Import Files From Directory...', 
            '-Sep4-', 
#            'Rename Project... (Unrealized)', 
            'Remove Project', 
            '-Sep5-', 
            'Edit PCH Header For Clang...', 
            '-Sep6-', 
            'Settings...' ]

        if vim.eval('g:VLWorkspaceUseClangCC') == '0':
            self.popupMenuP.remove('Edit PCH Header For Clang...')
            self.popupMenuP.remove('-Sep6-')

        # 虚拟目录右键菜单列表
        self.popupMenuV = ['Please select an operation:', 
            'Add a New File...', 
            'Add Existing Files...', 
            'New Virtual Folder...', 
            'Import Files From Directory...', 
#            'Sort Items (Unrealized)', 
            'Rename...', 
            'Remove Virtual Folder' ]

        # 文件右键菜单列表
        self.popupMenuF = ['Please select an operation:', 
                'Open', 
#                'Compile (Unrealized)', 
#                'Preprocess (Unrealized)', 
                'Rename...', 
                'Remove' ]

        if fileName:
            self.OpenWorkspace(fileName)

        #创建窗口
        vim.command("call s:CreateVLWorkspaceWin()")
        vim.command("call s:SetupKeyMappings()")
        self.buffer = vim.current.buffer
        self.window = vim.current.window
        self.bufNum = int(vim.eval("bufnr('%')"))
        
        self.InstallPopupMenu()

        self.RefreshStatusLine()
        self.RefreshBuffer()
        self.HlActiveProject()

    def OpenWorkspace(self, fileName):
        if fileName:
            self.VLWIns.OpenWorkspace(fileName)
            self.LoadWspSettings()
            self.OpenTagsDatabase()
            self.HlActiveProject()

    def CloseWorkspace(self):
        self.VLWIns.CloseWorkspace()
        self.tagsManager.CloseDatabase()

    def ReloadWorkspace(self):
        fileName = self.VLWIns.fileName
        self.CloseWorkspace()
        self.OpenWorkspace(fileName)
        self.RefreshBuffer()

    def LoadWspSettings(self):
        if self.VLWIns.fileName:
            # 读取配置文件
            settingsFile = os.path.splitext(self.VLWIns.fileName)[0] \
                + '.wspsettings'
            self.VLWSettings.SetFileName(settingsFile)
            self.VLWSettings.Load()
            # 初始化 Omnicpp 类型替换字典
            self.InitOmnicppTypesVar()
            # 通知全局环境变量设置当前选择的组别名字
            EnvVarSettingsST.Get().SetActiveSetName(
                self.VLWSettings.GetEnvVarSetName())

    def SaveWspSettings(self):
        if self.VLWSettings.Save():
            self.LoadWspSettings()

    def OpenTagsDatabase(self):
        if self.VLWIns.fileName and vim.eval('g:VLWorkspaceUseClangCC') == '0':
            dbFileName = os.path.splitext(self.VLWIns.fileName)[0] + '.vltags'
            self.tagsManager.OpenDatabase(dbFileName)

    def InstallPopupMenu(self):
        for idx, value in enumerate(self.popupMenuW):
            if idx == 0:
                continue
            elif value[:4] == '-Sep':
                # 菜单分隔符
                vim.command("an <silent> 100.%d ]VLWorkspacePopup.%s <Nop>" 
                    % (idx * 10, value))
            else:
                vim.command("an <silent> 100.%d ]VLWorkspacePopup.%s "\
                    ":call <SID>MenuOperation('W_%s')<CR>" 
                    % (idx * 10, value.replace(' ', '\\ ').replace('.', '\\.'), 
                       value))
        for idx in range(1, len(self.popupMenuP)):
            value = self.popupMenuP[idx]
            if value[:4] == '-Sep':
                vim.command("an <silent> 100.%d ]VLWProjectPopup.%s <Nop>" 
                    % (idx * 10, value))
            else:
                vim.command("an <silent> 100.%d ]VLWProjectPopup.%s "\
                    ":call <SID>MenuOperation('P_%s')<CR>" 
                    % (idx * 10, value.replace(' ', '\\ ').replace('.', '\\.'), 
                       value))
        for idx in range(1, len(self.popupMenuV)):
            value = self.popupMenuV[idx]
            if value[:4] == '-Sep':
                vim.command("an <silent> ]VLWVirtualDirectoryPopup.%s <Nop>" 
                    % value)
            else:
                vim.command("an <silent> ]VLWVirtualDirectoryPopup.%s "\
                    ":call <SID>MenuOperation('V_%s')<CR>" 
                    % (value.replace(' ', '\\ ').replace('.', '\\.'), value))
        for idx in range(1, len(self.popupMenuF)):
            value = self.popupMenuF[idx]
            if value[:4] == '-Sep':
                vim.command("an <silent> ]VLWFilePopup.%s <Nop>" % value)
            else:
                vim.command("an <silent> ]VLWFilePopup.%s "\
                    ":call <SID>MenuOperation('F_%s')<CR>" 
                    % (value.replace(' ', '\\ ').replace('.', '\\.'), value))

    def RefreshBuffer(self):
        if not self.buffer or not self.window:
            return

        se = StartEdit()

        texts = self.VLWIns.GetAllDisplayTexts()
        self.buffer[:] = [ i.encode('utf-8') for i in texts ]
        # 重置偏移量
        self.VLWIns.SetWorkspaceLineNum(1)

    def RefreshStatusLine(self):
        string = self.VLWIns.GetName() + '[' + \
            self.VLWIns.GetBuildMatrix().GetSelectedConfigurationName() \
            + ']'
        vim.command("call setwinvar(bufwinnr(%d), '&statusline', '%s')" 
            % (self.bufNum, string))

    def InitOmnicppTypesVar(self):
        vim.command("let g:dOCppTypes = {}")
        for i in (self.VLWSettings.tagsTypes + TagsSettingsST.Get().tagsTypes):
            li = i.partition('=')
            path = vim.eval("omnicpp#utils#GetVariableType('%s').name" % li[0])
            vim.command("let g:dOCppTypes['%s'] = {}" % (path,))
            vim.command("let g:dOCppTypes['%s'].orig = '%s'" % (path, li[0]))
            vim.command("let g:dOCppTypes['%s'].repl = '%s'" % (path, li[2]))

    def GetSHSwapList(self, fileName):
        '''获取源/头文件切换列表'''
        if not fileName:
            return

        name = os.path.splitext(os.path.basename(fileName))[0]
        result = []

        if Globals.IsSourceFile(fileName):
            for ext in Globals.CPP_HEADER_EXT:
                swapFileName = name + os.path.extsep + ext
                if self.VLWIns.fname2file.has_key(swapFileName):
                    result.extend(self.VLWIns.fname2file[swapFileName])
        elif Globals.IsHeaderFile(fileName):
            for ext in Globals.CPP_SOURCE_EXT:
                swapFileName = name + os.path.extsep + ext
                if self.VLWIns.fname2file.has_key(swapFileName):
                    result.extend(self.VLWIns.fname2file[swapFileName])
        else:
            pass

        result.sort(Globals.Cmp)
        return result

    def SwapSourceHeader(self, fileName):
        '''切换源/头文件，仅对在工作区中的文件有效
        仅切换在同一项目中的文件
        
        fileName 必须是绝对路径，否则会直接返回'''
        project = self.VLWIns.GetProjectByFileName(fileName)
        if not os.path.isabs(fileName) or not project:
            return

        swapFiles = self.GetSHSwapList(fileName)
        for fn in swapFiles[:]:
            '''检查切换的两个文件是否在同一个项目'''
            if project is not self.VLWIns.GetProjectByFileName(fn):
                try:
                    swapFiles.remove(fn)
                except ValueError:
                    pass
        if not swapFiles:
            vim.command("echohl WarningMsg")
            vim.command("echo 'No matched file was found!'")
            vim.command("echohl None")
            return

        if len(swapFiles) == 1:
            vim.command("e %s" % swapFiles[0])
        else:
            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(['Please select:'] + swapFiles))
            choice = int(choice) - 1
            if choice >= 0 and choice < len(swapFiles):
                vim.command("e %s" % swapFiles[choice])

    def FindFiles(self, matchName, noCase = False):
        if not matchName:
            return

        fnames = self.VLWIns.fname2file.keys()
        fnames.sort()
        result = []
        questionList = []
        for fname in fnames:
            fname2 = fname
            matchName2 = matchName
            if noCase:
                fname2 = fname.lower()
                matchName2 = matchName.lower()
            if matchName2 in fname2:
                tmpList = []
                for absFileName in self.VLWIns.fname2file[fname]:
                    result.append(absFileName)
                    tmpList.append('%s --> %s' % (fname, absFileName))
                tmpList.sort()
                questionList.extend(tmpList)

        if not result:
            vim.command('echohl WarningMsg')
            vim.command('echo "No matched file was found!"')
            vim.command('echohl None')
            return

        try:
            # 如果按 q 退出了, 会抛出错误
            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(['Pleace select:'] + questionList))
            #echoList = GenerateMenuList(['Pleace select:'] + questionList)
            #vim.command('echo "%s"' % '\n'.join(echoList))
            #choice = vim.eval(
                #'input("Type number and <Enter> (empty cancels): ")')
            choice = int(choice) - 1
            if choice >= 0 and choice < len(questionList):
                vim.command("call s:OpenFile('%s')" % result[choice])
        except:
            pass


    #===========================================================================
    #基本操作 ===== 开始
    #===========================================================================

    def FoldNode(self):
        se = StartEdit()
        lnum = self.window.cursor[0]
        ret = self.VLWIns.Fold(lnum)
        self.buffer[lnum-1] = self.VLWIns.GetLineText(lnum).encode('utf-8')
        if ret > 0:
            del self.buffer[lnum:lnum+ret]

    def ExpandNode(self):
        se = StartEdit()
        lnum = self.window.cursor[0]
        if not self.VLWIns.IsNodeExpand(lnum):
            ret = self.VLWIns.Expand(lnum)
            texts = []
            for i in range(lnum+1, lnum+1+ret):
                texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
            self.buffer[lnum-1] = self.VLWIns.GetLineText(lnum).encode('utf-8')
            if texts != []:
                self.buffer.append(texts, lnum)

    def OnMouseDoubleClick(self, key = ''):
        lnum = self.window.cursor[0]
        nodeType = self.VLWIns.GetNodeType(lnum)
        if nodeType == VLWorkspace.TYPE_PROJECT \
             or nodeType == VLWorkspace.TYPE_VIRTUALDIRECTORY:
            if self.VLWIns.IsNodeExpand(lnum):
                self.FoldNode()
            else:
                self.ExpandNode()
        elif nodeType == VLWorkspace.TYPE_FILE:
            absFile = self.VLWIns.GetFileByLineNum(lnum, True)
            if not key or key == vim.eval("g:VLWOpenNodeKey"):
                vim.command('call s:OpenFile("%s", 0)' % absFile)
            elif key == vim.eval("g:VLWOpenNode2Key"):
                vim.command('call s:OpenFile("%s", 1)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeInNewTabKey"):
                vim.command('call s:OpenFileInNewTab("%s", 0)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeInNewTab2Key"):
                vim.command('call s:OpenFileInNewTab("%s", 1)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeSplitKey"):
                vim.command('call s:OpenFileSplit("%s", 0)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeSplit2Key"):
                vim.command('call s:OpenFileSplit("%s", 1)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeVSplitKey"):
                vim.command('call s:OpenFileVSplit("%s", 0)' % absFile)
            elif key == vim.eval("g:VLWOpenNodeVSplit2Key"):
                vim.command('call s:OpenFileVSplit("%s", 1)' % absFile)
            else:
                pass
        elif nodeType == VLWorkspace.TYPE_WORKSPACE:
            vim.command('call s:ChangeBuildConfig()')
        else:
            pass

    def OnRightMouseClick(self):
        row, col = self.window.cursor
        nodeType = self.VLWIns.GetNodeType(row)
        if nodeType == VLWorkspace.TYPE_FILE: #文件右键菜单
            vim.command("popup ]VLWFilePopup")
        elif nodeType == VLWorkspace.TYPE_VIRTUALDIRECTORY: #虚拟目录右键菜单
            vim.command("popup ]VLWVirtualDirectoryPopup")
        elif nodeType == VLWorkspace.TYPE_PROJECT: #项目右键菜单
            vim.command(
                "silent! aunmenu ]VLWProjectPopup.Custom\\ Build\\ Targets")
            project = self.VLWIns.GetDatumByLineNum(row)['project']
            projName = project.GetName()
            matrix = self.VLWIns.GetBuildMatrix()
            wspSelConfName = matrix.GetSelectedConfigurationName()
            projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                            projName)
            bldConf = self.VLWIns.GetProjBuildConf(projName, projSelConfName)
            if bldConf and bldConf.IsCustomBuild():
                targets = bldConf.GetCustomTargets().keys()
                targets.sort()
                for target in targets:
                    menuNumber = 25
                    try:
                        # BUG: Clean 为 30, 这里要 25 才能在 Clean 之后
                        menuNumber = self.popupMenuP.index('Clean') * 10 - 5
                    except ValueError:
                        pass
                    vim.command("an <silent> 100.%d ]VLWProjectPopup."
                        "Custom\\ Build\\ Targets.%s "
                        ":call <SID>MenuOperation('P_C_%s')<CR>" 
                        % (menuNumber, 
                           target.replace(' ', '\\ ').replace('.', '\\.'), 
                           target))

            vim.command("popup ]VLWProjectPopup")
        elif nodeType == VLWorkspace.TYPE_WORKSPACE: #工作空间右键菜单
            # 先删除上次添加的菜单
            vim.command("silent! aunmenu ]VLWorkspacePopup.Batch\\ Builds")
            vim.command("silent! aunmenu ]VLWorkspacePopup.Batch\\ Cleans")
            names = self.VLWSettings.GetBatchBuildNames()
            if names:
                # 添加 Batch Build 和 Batch Clean 目标
                names.sort()
                for name in names:
                    menuNumber = 75
                    try:
                        menuNumber = self.popupMenuW.index('Batch Builds')
                        menuNumber = (menuNumber - 1) * 10 - 5
                    except ValueError:
                        pass
                    name2 = name.replace(' ', '\\ ').replace('.', '\\.')
                    vim.command("an <silent> 100.%d ]VLWorkspacePopup."
                        "Batch\\ Builds.%s "
                        ":call <SID>MenuOperation('W_BB_%s')<CR>"
                        % (menuNumber, name2, name))
                    name2 = name.replace(' ', '\\ ').replace('.', '\\.')
                    vim.command("an <silent> 100.%d ]VLWorkspacePopup."
                        "Batch\\ Cleans.%s "
                        ":call <SID>MenuOperation('W_BC_%s')<CR>"
                        % (menuNumber + 1, name2, name))

            vim.command("popup ]VLWorkspacePopup")
        else:
            pass

    def ChangeBuildConfig(self):
        choices = []
        names = []
        choices.append('Pleace select the configuration:')
        names.append('')

        matrix = self.VLWIns.GetBuildMatrix()
        selConfName = matrix.GetSelectedConfigurationName()
        x = 1
        curChoice = 0
        for i in matrix.GetConfigurations():
            pad = ' '
            if i.name == selConfName:
                pad = '*'
                curChoice = x
            choices.append('%s %d. %s' 
                % (pad.encode('utf-8'), x, i.name.encode('utf-8')))
            names.append(i.name)
            x += 1

        choice = vim.eval('inputlist(%s)' % choices)
        choice = int(choice)

        if choice <= 0 or choice >= len(names) or choice == curChoice:
            return
        else:
            matrix.SetSelectedConfigurationName(names[choice])
            # NOTE: 所有有 ToXmlNode() 的类的保存方式都是通过 SetXXX 实现，
            # 而不是工作空间或项目的 Save()
            self.VLWIns.SetBuildMatrix(matrix)
            self.RefreshStatusLine()

    def GotoParent(self):
        row, col = self.window.cursor
        parentRow = self.VLWIns.GetParentLineNum(row)
        if parentRow != row:
            vim.command("mark '")
            vim.command("exec %d" % parentRow)

    def GotoRoot(self):
        row, col = self.window.cursor
        rootRow = self.VLWIns.GetRootLineNum(row)
        if rootRow != row:
            vim.command("mark '")
            vim.command("exec %d" % rootRow)

    def GotoNextSibling(self):
        row, col = self.window.cursor
        lnum = self.VLWIns.GetNextSiblingLineNum(row)
        if lnum != row:
            vim.command("mark '")
            vim.command('exec %d' % lnum)

    def GotoPrevSibling(self):
        row, col = self.window.cursor
        lnum = self.VLWIns.GetPrevSiblingLineNum(row)
        if lnum != row:
            vim.command("mark '")
            vim.command('exec %d' % lnum)

    def AddFileNode(self, row, name):
        if not name:
            return

        row = int(row)
        # 确保节点展开
        self.ExpandNode()

        se = StartEdit()
        # TODO: 同名的话，返回 0，可发出相应的警告
        ret = self.VLWIns.AddFileNode(row, name)

        # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
        ln = self.VLWIns.GetPrevSiblingLineNum(ret)
        if ln == ret:
            ln = row

        texts = []
        for i in range(ln, ret + 1):
            texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
        if texts:
            self.buffer[ln - 1 : ret - 1] = texts

    def AddFileNodes(self, row, names):
        if type(names) != type([]) or not names or not names[0]:
            return

        row = int(row)
        # 确保节点展开
        self.ExpandNode()

        se = StartEdit()
        # TODO: 同名的话，返回 0，可发出相应的警告
        for idx in range(len(names)):
            if idx == len(names) - 1:
                # 最后的，保存
                ret = self.VLWIns.AddFileNode(row, names[idx])
            else:
                ret = self.VLWIns.AddFileNodeQuickly(row, names[idx])
            # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
            ln = self.VLWIns.GetPrevSiblingLineNum(ret)
            if ln == ret:
                ln = row

            texts = []
            for i in range(ln, ret + 1):
                texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
            if texts:
                self.buffer[ln - 1 : ret - 1] = texts

    def AddVirtualDirNode(self, row, name):
        if not name:
            return

        row = int(row)
        # 确保节点展开
        self.ExpandNode()

        se = StartEdit()
        # TODO: 同名的话，返回 0，可发出相应的警告
        ret = self.VLWIns.AddVirtualDirNode(row, name)

        # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
        ln = self.VLWIns.GetPrevSiblingLineNum(ret)
        if ln == ret:
            ln = row

        # 获取 n+1 行文本，替换原来的 n 行文本，也就是新增了 1 行文本
        texts = []
        for i in range(ln, ret + 1):
            texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
        if texts:
            self.buffer[ln - 1 : ret - 1] = texts

    def AddProjectNode(self, row, projFile):
        #if not projFile.endswith('.project'):
            #return

        row = int(row)

        se = StartEdit()
        # TODO: 同名的话，返回 0，可发出相应的警告
        ret = self.VLWIns.AddProject(projFile)

        # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
        ln = self.VLWIns.GetPrevSiblingLineNum(ret)
        if ln == ret:
            ln = row

        # 获取 n+1 行文本，替换原来的 n 行文本，也就是新增了 1 行文本
        texts = []
        for i in range(ln, ret + 1):
            texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
        if texts:
            self.buffer[ln - 1 : ret - 1] = texts

        self.HlActiveProject()

    def ImportFilesFromDirectory(self, row, importDir,filters):
        self.ExpandNode()
        ret = self.VLWIns.ImportFilesFromDirectory(row, importDir, filters)
        if ret:
            # 只需刷新添加的节点的上一个兄弟节点到添加的节点之间的显示
            se = StartEdit()
            ln = self.VLWIns.GetPrevSiblingLineNum(ret)
            if ln == ret:
                ln = row
            texts = []
            for i in range(ln, ret + 1):
                texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
            if texts:
                self.buffer[ln - 1 : ret - 1] = texts

    def DeleteNode(self):
        row, col = self.window.cursor
        prevLn = self.VLWIns.GetPrevSiblingLineNum(row)  #用于刷新操作
        nextLn = self.VLWIns.GetNextSiblingLineNum(row)  #用于刷新操作
        ret = self.VLWIns.DeleteNode(row)

        se = StartEdit()
        # 如果删除的节点没有下一个兄弟节点时，应刷新上一兄弟节点的所有子节点
        # TODO: 可用判断是否拥有下一个兄弟节点函数来优化
        if nextLn == row:
            # 刷新指定的数行
            self.RefreshLines(prevLn, row)
            #texts = []
            #for i in range(prevLn, row):
            #    texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
            #self.buffer[prevLn-1:row-1] = texts

        del self.buffer[row-1:row-1+ret]
        self.HlActiveProject()

    def HlActiveProject(self):
        activeProject = self.VLWIns.activeProject
        if activeProject:
            vim.command('match %s /^[|`][+~]\zs%s$/' 
                % (vim.eval('g:VLWorkspaceActiveProjectHlGroup'), 
                    activeProject))

    def RefreshLines(self, start, end):
        '''刷新数行，不包括 end 行'''
        se = StartEdit()

        start = int(start)
        end = int(end)
        texts = []
        for i in range(start, end):
            texts.append(self.VLWIns.GetLineText(i).encode('utf-8'))
        if texts:
            self.buffer[start-1:end-1] = texts

    def DebugProject(self, projName, hasProjFile = False, firstRun = True):
        if not self.VLWIns.FindProjectByName(projName):
            return

        ds = Globals.DirSaver()

        wspSelConfName = self.VLWIns.GetBuildMatrix()\
            .GetSelectedConfigurationName()
        confToBuild = self.VLWIns.GetBuildMatrix().GetProjectSelectedConf(
            wspSelConfName, projName)
        bldConf = self.VLWIns.GetProjBuildConf(projName, confToBuild)

        try:
            os.chdir(self.VLWIns.FindProjectByName(projName).dirName)
        except OSError:
            return
        wd = Globals.ExpandAllVariables(
            bldConf.workingDirectory, self.VLWIns, projName, confToBuild, '')
        try:
            if wd:
                os.chdir(wd)
        except OSError:
            return
        #print os.getcwd()

        prog = bldConf.GetCommand()
        if bldConf.useSeparateDebugArgs:
            args = bldConf.debugArgs
        else:
            args = bldConf.commandArguments
        prog = Globals.ExpandAllVariables(prog, self.VLWIns, projName, 
            confToBuild, '')
        #print prog
        args = Globals.ExpandAllVariables(args, self.VLWIns, projName, 
            confToBuild, '')
        #print args
        if firstRun and prog:
        # 第一次运行, 只要启动 pyclewn 即可
            # BUG: 在 python 中运行以下两条命令, 会出现同名但不同缓冲区的大问题!
            # 暂时只能由外部运行 Pyclewn
            #vim.command("silent cd %s" % os.getcwd())
            #vim.command("silent Pyclewn")
            if not hasProjFile:
                # NOTE: 不能处理目录名称的第一个字符为空格的情况
                vim.command("silent Ccd %s/" % os.getcwd())
                vim.command("Cfile '%s'" % prog)
            if args:
                vim.command("Cset args %s" % args)
            #vim.command("silent cd -")
            #if not hasProjFile:
                #vim.command("Cstart")
        else:
        # 非第一次运行, 只要运行 Crun 即可
            # 为避免修改了程序参数, 需要重新设置程序参数, 即使为空, 也要设置
            vim.command("Cset args %s" % args)
            vim.command("Crun")

    def DebugActiveProject(self, hasProjFile = False, firstRun = True):
        actProjName = self.VLWIns.GetActiveProjectName()
        self.DebugProject(actProjName, hasProjFile, firstRun)

    def BuildProject(self, projName):
        ds = Globals.DirSaver()
        try:
            os.chdir(self.VLWIns.dirName)
        except OSError:
            return

        cmd = self.builder.GetBuildCommand(projName, '')

        if cmd:
            if vim.eval("g:VLWorkspaceSaveAllBeforeBuild") != '0':
                vim.command("wa")
            tempFile = vim.eval('tempname()')
            if True:
                # 强制设置成英语 locale 以便 quickfix 处理
                cmd = "LANG=en_US " + cmd
                vim.command("!%s 2>&1 | tee %s" % (cmd, tempFile))
                vim.command('cgetfile %s' % tempFile)
            else:
                os.system("gnome-terminal -t 'make' -e "\
                    "\"sh -c \\\"%s 2>&1 | tee '%s' "\
                    "&& echo ========================================"\
                    "&& echo -n This will close in 3 seconds... "\
                    "&& read -t 3 i && echo Press ENTER to continue... "\
                    "&& read i;"\
                    "vim --servername '%s' "\
                    "--remote-send '<C-\><C-n>:cgetfile %s "\
                    "| echo \\\\\\\"Readed the error file.\\\\\\\"<CR>'\\\"\" &"
                    % (cmd, tempFile, vim.eval('v:servername'), 
                       tempFile.replace(' ', '\\ ')))

    def CleanProject(self, projName):
        ds = Globals.DirSaver()
        try:
            os.chdir(self.VLWIns.dirName)
        except OSError:
            return

        cmd = self.builder.GetCleanCommand(projName, '')

        if cmd:
            # 强制设置成英语 locale 以便 quickfix 处理
            cmd = "LANG=en_US " + cmd
            tempFile = vim.eval('tempname()')
            vim.command("!%s 2>&1 | tee %s" % (cmd, tempFile))
            vim.command('cgetfile %s' % tempFile)

    def RebuildProject(self, projName):
        '''重构建项目，即先 Clean 再 Build'''
        ds = Globals.DirSaver()
        try:
            os.chdir(self.VLWIns.dirName)
        except OSError:
            return
        cmd = self.builder.GetCleanCommand(projName, '')
        if cmd:
            os.system("%s" % cmd)

        self.BuildProject(projName)

    def RunProject(self, projName):
        ds = Globals.DirSaver()

        wspSelConfName = self.VLWIns.GetBuildMatrix()\
            .GetSelectedConfigurationName()
        confToBuild = self.VLWIns.GetBuildMatrix().GetProjectSelectedConf(
            wspSelConfName, projName)
        bldConf = self.VLWIns.GetProjBuildConf(projName, confToBuild)

        try:
            os.chdir(self.VLWIns.FindProjectByName(projName).dirName)
        except OSError:
            return
        wd = Globals.ExpandAllVariables(
            bldConf.workingDirectory, self.VLWIns, projName, confToBuild, '')
        try:
            if wd:
                os.chdir(wd)
        except OSError:
            return
        #print os.getcwd()

        prog = bldConf.GetCommand()
        args = bldConf.commandArguments
        prog = Globals.ExpandAllVariables(prog, self.VLWIns, projName, 
            confToBuild, '')
        #print prog
        args = Globals.ExpandAllVariables(args, self.VLWIns, projName, 
            confToBuild, '')
        #print args
        if prog:
            envs = ''
            for envVar in EnvVarSettingsST.Get().GetActiveEnvVars():
                envs += envVar.GetString() + ' '
            #print envs
            os.system('~/.vimlite/vimlite_run "%s" '\
                '~/.vimlite/vimlite_exec %s %s %s &' % (prog, envs, prog, args))
            #os.system('~/.vimlite/vimlite_term "%s" \
            #    "/bin/sh -f $HOME/.vimlite/vimlite_exec %s %s" &' \
            #    % (prog, prog, args))

    def BuildActiveProject(self):
        actProjName = self.VLWIns.GetActiveProjectName()
        self.BuildProject(actProjName)

    def CleanActiveProject(self):
        actProjName = self.VLWIns.GetActiveProjectName()
        self.CleanProject(actProjName)

    def RunActiveProject(self):
        actProjName = self.VLWIns.GetActiveProjectName()
        self.RunProject(actProjName)

    def BuildAndRunProject(self, projName):
        self.BuildProject(projName)
        qflist = vim.eval('getqflist()')
        if qflist and qflist[-1]['text'][:5] != 'make:':
            # 构建成功
            self.RunProject(projName)

    def BuildAndRunActiveProject(self):
        actProjName = self.VLWIns.GetActiveProjectName()
        self.BuildAndRunProject(actProjName)

    def BatchBuild(self, batchBuildName, isClean = False):
        '''批量构建'''
        ds = Globals.DirSaver()
        try:
            os.chdir(self.VLWIns.dirName)
        except OSError:
            return

        buildOrder = self.VLWSettings.GetBatchBuildList(batchBuildName)
        matrix = self.VLWIns.GetBuildMatrix()
        wspSelConfName = matrix.GetSelectedConfigurationName()
        if isClean:
            cmd = self.builder.GetBatchCleanCommand(buildOrder, wspSelConfName)
        else:
            cmd = self.builder.GetBatchBuildCommand(buildOrder, wspSelConfName)

        if cmd:
            # 强制设置成英语 locale 以便 quickfix 处理
            cmd = "LANG=en_US " + cmd
            if vim.eval("g:VLWorkspaceSaveAllBeforeBuild") != '0':
                vim.command("wa")
            tempFile = vim.eval('tempname()')
            vim.command("!%s 2>&1 | tee %s" % (cmd, tempFile))
            vim.command('cgetfile %s' % tempFile)

    def ParseWorkspace(self, full = False):
        if full:
            self.tagsManager.RecreateDatabase()

        files = self.VLWIns.GetAllFiles(True)
        parseFiles = files[:]

        searchPaths = \
            TagsSettingsST.Get().includePaths + self.VLWSettings.includePaths

        if True:
            '添加编译选项指定的搜索路径'
            projIncludePaths = set()
            matrix = self.VLWIns.GetBuildMatrix()
            wspSelConfName = matrix.GetSelectedConfigurationName()
            for project in self.VLWIns.projects.itervalues():
                ds = Globals.DirSaver()
                try:
                    os.chdir(project.dirName)
                except OSError:
                    return
                projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                                project.name)
                bldConf = self.VLWIns.GetProjBuildConf(project.name, 
                                                       projSelConfName)
                if bldConf and not bldConf.IsCustomBuild():
                    tmpIncPaths = bldConf.GetIncludePath().split(';')
                    for tmpPath in tmpIncPaths:
                        if tmpPath:
                            # 需要先展开变量(宏)
                            tmpPath = Globals.ExpandAllVariables(
                                tmpPath, self.VLWIns, project.GetName(),
                                projSelConfName)
                            projIncludePaths.add(os.path.abspath(tmpPath))
            projIncludePaths = list(projIncludePaths)
            projIncludePaths.sort()
            searchPaths += projIncludePaths

        vim.command("echo 'Scanning header files need to be parsed...'")

        for f in files:
            parseFiles += IncludeParser.GetIncludeFiles(f, searchPaths)

        parseFiles = list(set(parseFiles))
        parseFiles.sort()
        self.ParseFiles(parseFiles)

    def ParseFiles(self, files, indicate = True):
        replacements = \
            TagsSettingsST.Get().tagsTokens + self.VLWSettings.tagsTokens
        if indicate:
            self.tagsManager.ParseFiles(files, replacements, IndicateProgress)
            vim.command("redraw | echo 'Done.'")
        else:
            self.tagsManager.ParseFiles(files, replacements, None)

    def GetProjectIncludePaths(self, projName, wspConfName = ''):
        '''获取指定项目指定构建设置的头文件搜索路径
        
        返回绝对路径列表'''
        project = self.VLWIns.FindProjectByName(projName)
        if not project:
            return []

        matrix = self.VLWIns.GetBuildMatrix()
        if not wspConfName:
            wspConfName = matrix.GetSelectedConfigurationName()

        result = \
            TagsSettingsST.Get().includePaths + self.VLWSettings.includePaths

        ds = Globals.DirSaver()
        try:
            os.chdir(project.dirName)
        except OSError:
            return result
        projConfName = matrix.GetProjectSelectedConf(wspConfName, project.name)
        if not projConfName:
            return result

        '添加编译选项指定的搜索路径'
        # FIXME: 无效的 projConfName 居然也返回有效的 bldConf
        bldConf = self.VLWIns.GetProjBuildConf(project.name, projConfName)
        if bldConf and not bldConf.IsCustomBuild():
            tmpIncPaths = bldConf.GetIncludePath().split(';')
            for tmpPath in tmpIncPaths:
                # 从 xml 里提取的字符串全部都是 unicode
                tmpPath = Globals.ExpandAllVariables(tmpPath, self.VLWIns,
                                                     projName, projConfName)
                result.append(os.path.abspath(tmpPath).encode('utf-8'))

        return result

    def GetActiveProjectIncludePaths(self, wspConfName = ''):
        actProjName = self.VLWIns.GetActiveProjectName()
        return self.GetProjectIncludePaths(actProjName, wspConfName)

    def GetWorkspaceIncludePaths(self, wspConfName = ''):
        incPaths = []
        for projName in ws.VLWIns.projects.keys():
            incPaths += ws.GetProjectIncludePaths(projName, wspConfName)
        guard = set()
        result = []
        # 过滤重复的项
        for path in incPaths:
            if not path in guard:
                result.append(path)
                guard.add(path)
        return result

    def ShowMenu(self):
        row, col = self.window.cursor
        nodeType = self.VLWIns.GetNodeType(row)
        if nodeType == VLWorkspace.TYPE_WORKSPACE: #工作空间右键菜单
            popupMenuW = [i for i in self.popupMenuW if i[:4] != '-Sep']

            names = self.VLWSettings.GetBatchBuildNames()
            if names:
                try:
                    idx = popupMenuW.index('Batch Builds')
                    del popupMenuW[idx]
                except ValueError:
                    idx = len(popupMenuW)
                popupMenuW.insert(idx, 'Batch Cleans ->')
                popupMenuW.insert(idx, 'Batch Builds ->')

            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(popupMenuW))
            choice = int(choice)
            if choice > 0 and choice < len(popupMenuW):
                if popupMenuW[choice].startswith('Batch Builds ->')\
                        or popupMenuW[choice].startswith('Batch Cleans ->'):
                    BBMenu = ['Please select an operation:']
                    for name in names:
                        BBMenu.append(name)
                    choice2 = vim.eval("inputlist(%s)" 
                        % GenerateMenuList(BBMenu))
                    choice2 = int(choice2)
                    if choice2 > 0 and choice2 < len(BBMenu):
                        if popupMenuW[choice].startswith('Batch Builds ->'):
                            self.MenuOperation('W_BB_%s' % BBMenu[choice2], False)
                        else:
                            self.MenuOperation('W_BC_%s' % BBMenu[choice2], False)
                else:
                    self.MenuOperation('W_' + popupMenuW[choice], False)
        elif nodeType == VLWorkspace.TYPE_PROJECT: #项目右键菜单
            popupMenuP = [i for i in self.popupMenuP if i[:4] != '-Sep']

            project = self.VLWIns.GetDatumByLineNum(row)['project']
            projName = project.GetName()
            matrix = self.VLWIns.GetBuildMatrix()
            wspSelConfName = matrix.GetSelectedConfigurationName()
            projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                            projName)
            bldConf = self.VLWIns.GetProjBuildConf(projName, projSelConfName)
            if bldConf and bldConf.IsCustomBuild():
                try:
                    idx = popupMenuP.index('Clean') + 1
                except ValueError:
                    idx = len(popupMenuP)
                targets = bldConf.GetCustomTargets().keys()
                if targets:
                    popupMenuP.insert(idx, 'Custom Build Targets ->')

            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(popupMenuP))
            choice = int(choice)
            if choice > 0 and choice < len(popupMenuP):
                menu = 'P_'
                if popupMenuP[choice].startswith('Custom Build Targets ->'):
                    targets = bldConf.GetCustomTargets().keys()
                    targets.sort()
                    if targets:
                        CBMenu = ['Please select an operation:']
                        for target in targets:
                            CBMenu.append(target)
                        choice2 = vim.eval("inputlist(%s)" 
                            % GenerateMenuList(CBMenu))
                        choice2 = int(choice2)
                        if choice2 > 0 and choice2 < len(CBMenu):
                            menu = 'P_C_' + CBMenu[choice2]
                else:
                    menu = 'P_' + popupMenuP[choice]
                self.MenuOperation(menu, False)
        elif nodeType == VLWorkspace.TYPE_VIRTUALDIRECTORY: #虚拟目录右键菜单
            popupMenuV = [i for i in self.popupMenuV if i[:4] != '-Sep']
            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(popupMenuV))
            choice = int(choice)
            if choice > 0 and choice < len(popupMenuV):
                self.MenuOperation('V_' + popupMenuV[choice], False)
        elif nodeType == VLWorkspace.TYPE_FILE: #文件右键菜单
            popupMenuF = [i for i in self.popupMenuF if i[:4] != '-Sep']
            choice = vim.eval("inputlist(%s)" 
                % GenerateMenuList(popupMenuF))
            choice = int(choice)
            if choice > 0 and choice < len(popupMenuF):
                self.MenuOperation('F_' + popupMenuF[choice], False)
        else:
            pass

    def MenuOperation(self, menu, useGui = True):
        row, col = self.window.cursor
        nodeType = self.VLWIns.GetNodeType(row)

        choice = menu[2:]
        if not choice:
            return

        if nodeType == VLWorkspace.TYPE_WORKSPACE: #工作空间右键菜单
            if choice == 'Create a New Project...':
                if self.VLWIns.name == 'DEFAULT_WORKSPACE':
                    vim.command('echohl WarningMsg')
                    vim.command('echo "Can not create new project'\
                        ' in the default workspace."')
                    vim.command('echohl None')
                else:
                    vim.command('call s:CreateProject()')
            elif choice == 'Add an Existing Project...':
                if useGui and vim.eval('has("browse")') != '0':
                    fileName = vim.eval(
                        'browse("", "Add Project", "%s", "")' 
                        % ws.VLWIns.dirName)
                else:
                    fileName = vim.eval(
                        'input("\nPlease Enter the file name:\n", '\
                        '"%s/", "file")' % (os.getcwd(),))
                if fileName:
                    self.AddProjectNode(row, fileName)
            elif choice == 'New Workspace...':
                vim.command('call s:CreateWorkspace()')
            elif choice == 'Open Workspace...':
                if useGui and vim.eval('has("browse")') != '0':
                    fileName = vim.eval(
                        'browse("", "Open Workspace", getcwd(), "")')
                else:
                    fileName = vim.eval(
                        'input("\nPlease Enter the file name:\n", '\
                        '"%s/", "file")' % (os.getcwd(),))
                if fileName:
                    self.CloseWorkspace()
                    self.OpenWorkspace(fileName)
                    self.RefreshBuffer()
                    if vim.eval('g:VLWorkspaceEnableCscope') != '0':
                        vim.command('call s:InitVLWCscopeDatabase()')
            elif choice == 'Close Workspace':
                self.CloseWorkspace()
                self.RefreshBuffer()
            elif choice == 'Reload Workspace':
                self.ReloadWorkspace()
            elif choice == 'Parse Workspace (Full)':
                self.ParseWorkspace(True)
            elif choice == 'Parse Workspace (Quick)':
                self.ParseWorkspace(False)
            elif choice == 'Workspace Build Configuration...':
                vim.command("call s:WspBuildConfigManager()")
            elif choice == 'Workspace Batch Build Settings...':
                vim.command('call s:WspBatchBuildSettings()')
            elif choice == 'Workspace Settings...':
                vim.command("call s:WspSettings()")
            elif choice.startswith('BB_'):
                # Batch Builds
                batchBuildName = choice[3:]
                self.BatchBuild(batchBuildName)
            elif choice.startswith('BC_'):
                # Batch Cleans
                batchBuildName = choice[3:]
                self.BatchBuild(batchBuildName, True)
            else:
                pass
        elif nodeType == VLWorkspace.TYPE_PROJECT: #项目右键菜单
            project = self.VLWIns.GetDatumByLineNum(row)['project']
            projName = project.GetName()
            if choice == 'Build':
                vim.command("call s:BuildProject('%s')" % projName)
            elif choice == 'Rebuild':
                vim.command("call s:RebuildProject('%s')" % projName)
            elif choice == 'Clean':
                vim.command("call s:CleanProject('%s')" % projName)
            elif choice == 'Export Makefile':
                self.builder.Export(projName, '', force = True)
            elif choice == 'Set As Active':
                self.VLWIns.SetActiveProjectByLineNum(row)
                self.HlActiveProject()
            elif choice == 'New Virtual Folder...':
                name = vim.eval(
                    'inputdialog("\nEnter the Virtual Directory Name:\n")')
                if name:
                    self.AddVirtualDirNode(row, name)
            elif choice == 'Import Files From Directory...':
                filters = '*.cpp;*.cc;*.cxx;*.h;*.hpp;*.c;*.c++;*.tcc'
                filters = vim.eval(
                    'inputdialog("\nFile extension to import '\
                    '(\\".\\" means no extension):\n", \'%s\', "None")' \
                    % filters)
                if filters == 'None':
                    return
                if useGui:
                    importDir = vim.eval('browsedir("Import Files", "%s")' 
                        % project.dirName)
                else:
                    ds = Globals.DirSaver()
                    os.chdir(project.dirName)
                    importDir = vim.eval('input("Import Files:\n", "%s", "dir")'
                        % os.getcwd())
                    if importDir:
                        importDir = importDir.rstrip(os.sep)
                    del ds
                if not importDir:
                    return
                self.ImportFilesFromDirectory(row, importDir, filters)
            elif choice == 'Remove Project':
                input = vim.eval('confirm("\nAre you sure to remove project '\
                '\\"%s\\" ?", ' '"&Yes\n&No\n&Cancel")' % projName)
                if input == '1':
                    self.DeleteNode()
            elif choice == 'Edit PCH Header For Clang...':
                vim.command("call s:OpenFile('%s')" 
                    % os.path.join(project.dirName, projName + '_VLWPCH.h'))
                vim.command("au BufWritePost <buffer> "\
                    "call s:InitVLWProjectClangPCH('%s')"
                    % projName)
            elif choice == 'Settings...':
                vim.command('call s:ProjectSettings("%s")' % projName)
            elif choice[:2] == 'C_':
                target = choice[2:]
                matrix = self.VLWIns.GetBuildMatrix()
                wspSelConfName = matrix.GetSelectedConfigurationName()
                projSelConfName = matrix.GetProjectSelectedConf(wspSelConfName, 
                                                                projName)
                bldConf = self.VLWIns.GetProjBuildConf(projName, 
                                                       projSelConfName)
                cmd = bldConf.customTargets[target]
                customBuildWd = bldConf.GetCustomBuildWorkingDir()
                # 展开变量(宏)
                customBuildWd = Globals.ExpandAllVariables(
                    customBuildWd, self.VLWIns, projName, projSelConfName)
                cmd = Globals.ExpandAllVariables(cmd, self.VLWIns, projName,
                                                 projSelConfName)
                try:
                    ds = Globals.DirSaver()
                    if customBuildWd:
                        os.chdir(customBuildWd)
                except OSError:
                    print 'Can not enter Working Directory "%s"!' \
                        % customBuildWd
                    return
                if cmd:
                    tempFile = vim.eval('tempname()')
                    vim.command("!%s 2>&1 | tee %s" % (cmd, tempFile))
                    vim.command('cgetfile %s' % tempFile)
            else:
                pass
        elif nodeType == VLWorkspace.TYPE_VIRTUALDIRECTORY: #虚拟目录右键菜单
            project = self.VLWIns.GetDatumByLineNum(row)['project']
            projName = project.GetName()
            if choice == 'Add a New File...':
                if useGui and vim.eval('has("browse")') != '0':
                    name = vim.eval('browse("", "Add a New File...", "%s", "")' 
                        % project.dirName)
                    # 若返回相对路径, 是相对于当前工作目录的相对路径
                    if name:
                        name = os.path.abspath(name)
                else:
                    name = vim.eval(
                        'inputdialog("\nEnter the File Name to be created:")')
                if name:
                    ds = Globals.DirSaver()
                    try:
                        # 若文件不存在, 创建之
                        if project.dirName:
                            os.chdir(project.dirName)
                        if not os.path.exists(name):
                            try:
                                os.makedirs(os.path.dirname(name))
                            except OSError:
                                pass
                            os.mknod(name, 0644)
                    except:
                        # 创建文件失败
                        print "Can not create the new file: '%s'" % name
                        return
                    del ds
                    self.AddFileNode(row, name)
            elif choice == 'Add Existing Files...':
                #if useGui and vim.eval('has("browse")') != '0':
                if True and vim.eval('has("browse")') != '0':
                    if vim.eval("executable('zenity')") == '1':
                        # zenity 返回的是绝对路径
                        ds = Globals.DirSaver()
                        try:
                            os.chdir(project.dirName)
                        except OSError:
                            pass
                        names = vim.eval('system(\'zenity --file-selection ' \
                                '--multiple --title="Add Existing files"\')')
                        names = names[:-1].split('|')
                        del ds
                    else:
                        names = []
                        # NOTE: 返回的也有可能是相对于当前目录而不是参数的目录的
                        #       相对路径
                        fileName = vim.eval(
                            'browse("", "Add Existing file", "%s", "")' 
                            % project.dirName)
                        if fileName:
                            names.append(os.path.abspath(fileName))
                    self.AddFileNodes(row, names)
                else:
                    vim.command('echo "\nSorry, this just unrealized."')
            elif choice == 'New Virtual Folder...':
                name = vim.eval(
                    'inputdialog("\nEnter the Virtual Directory Name:\n")')
                if name:
                    self.AddVirtualDirNode(row, name)
            elif choice == 'Import Files From Directory...':
                filters = '*.cpp;*.cc;*.cxx;*.h;*.hpp;*.c;*.c++;*.tcc'
                filters = vim.eval(
                    'inputdialog("\nFile extension to import '\
                    '(\\".\\" means no extension):\n", \'%s\', "None")' \
                    % filters)
                if filters == 'None':
                    return
                if useGui:
                    importDir = vim.eval('browsedir("Import Files", "%s")' 
                        % project.dirName)
                else:
                    ds = Globals.DirSaver()
                    os.chdir(project.dirName)
                    importDir = vim.eval('input("Import Files:\n", "%s", "dir")'
                        % os.getcwd())
                    if importDir:
                        importDir = importDir.rstrip(os.sep)
                    del ds
                if not importDir:
                    return
                self.ImportFilesFromDirectory(row, importDir, filters)
            elif choice == 'Rename...':
                oldName = self.VLWIns.GetDispNameByLineNum(row)
                newName = vim.eval('inputdialog("\nEnter new name:", "%s")' \
                    % oldName)
                if newName and newName != oldName:
                    self.VLWIns.RenameNodeByLineNum(row, newName)
                    self.RefreshLines(row, row + 1)
            elif choice == 'Remove Virtual Folder':
                input = vim.eval('confirm("\\"%s\\" and all its contents '\
                    'will be remove from the project. \nAre you sure?'\
                    '", ' '"&Yes\n&No\n&Cancel")' \
                    % self.VLWIns.GetDispNameByLineNum(row))
                if input == '1':
                    self.DeleteNode()
            else:
                pass
        elif nodeType == VLWorkspace.TYPE_FILE: #文件右键菜单
            if choice == 'Open':
                self.OnMouseDoubleClick()
            elif choice == 'Rename...':
                oldName = self.VLWIns.GetDispNameByLineNum(row)
                newName = vim.eval('inputdialog("\nEnter new name:", "%s")' 
                    % oldName)
                if newName != oldName and newName:
                    self.VLWIns.RenameNodeByLineNum(row, newName)
                    self.RefreshLines(row, row + 1)
            elif choice == 'Remove':
                input = vim.eval('confirm("\nAre you sure to remove file' \
                    ' \\"%s\\" ?", ' '"&Yes\n&No\n&Cancel")' \
                        % self.VLWIns.GetDispNameByLineNum(row))
                if input == '1':
                    self.DeleteNode()
            else:
                pass
        else:
            pass

    #===========================================================================
    #基本操作 ===== 结束
    #===========================================================================

PYTHON_EOF
endfunction


" vim:fdm=marker:fen:et:sts=4:fdl=1:
plugin/VLCalltips.vim	[[[1
302
" Description:  vim script for display function calltips
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 Jun 18
" License:      GPLv2

if exists('g:loaded_VLCalltips')
    finish
endif
let g:loaded_VLCalltips = 1

function! s:InitVariable(varName, defaultVal) "{{{2
    if !exists(a:varName)
		let {a:varName} = a:defaultVal
        return 1
    endif
    return 0
endfunction
"}}}

function! g:InitVLCalltips() "{{{1
    call s:InitVariable('g:VLCalltips_IndicateArgument', 1)
    call s:InitVariable('g:VLCalltips_EnableSyntaxTest', 0)

    call s:InitVariable('g:VLCalltips_DispCalltipsKey', '<A-p>')
    call s:InitVariable('g:VLCalltips_NextCalltipsKey', '<A-j>')
    call s:InitVariable('g:VLCalltips_PrevCalltipsKey', '<A-k>')

    "exec 'inoremap <silent> <buffer> ' . g:VLCalltips_DispCalltipsKey 
                "\. ' <C-r>=<SID>Test()<CR>'
    exec 'inoremap <silent> <buffer> ' . g:VLCalltips_NextCalltipsKey 
                \. ' <C-r>=<SID>HighlightNextCalltips()<CR>'
    exec 'inoremap <silent> <buffer> ' . g:VLCalltips_PrevCalltipsKey 
                \. ' <C-r>=<SID>HighlightPrevCalltips()<CR>'
endfunction
"}}}


let s:lCalltips = [] "保存函数原型或者原型形参信息的列表(C++ 重载)
let s:nCurIndex = 0 "当前函数原型的索引
let s:nArgIndex = 0 "当前形参索引, 0 开始

function! s:Test()
    let lLi = []
    call add(lLi, 'int printf(const char *fmt, ...)')
    call add(lLi, 'int printf(const char *fmt, int a, int b)')
    call g:DisplayCalltips(lLi, 0)

    return ''
endfunction

" 接口函数, 用于外部调用
" 可选参数若非零, 不移动光标, 即使函数没有参数
function! g:DisplayVLCalltips(lCalltips, nCurIndex, ...) "{{{2
    if empty(a:lCalltips)
        return ''
    endif

    let bKeepCursor = a:0 > 0 ? a:1 : 0

    call s:StopCalltips()
    if type(a:lCalltips) == type('')
        let s:lCalltips = [a:lCalltips]
        let s:nCurIndex = 0
    else
        let s:lCalltips = copy(a:lCalltips)
        let s:nCurIndex = a:nCurIndex
    endif

    if !empty(s:lCalltips)
        augroup DispCalltipsGroup
            au!
            au CursorMovedI <buffer> call <SID>AutoUpdateCalltips()
            au InsertLeave  <buffer> call <SID>StopCalltips()
        augroup END

        "设置必要的选项
        let s:bak_showmode = &showmode
        let s:bak_ruler = &ruler
        let s:bak_cmdheight = &cmdheight
        set noshowmode
        set noruler

        let s:nArgIndex = s:GetArgIndex()

        "如果函数无参数, 自动结束
        if !bKeepCursor && len(s:lCalltips) == 1 
                    \&& s:lCalltips[0] =~# '()\|(\s*void\s*)'
            call s:StopCalltips()
            call search(')', 'Wc')
            normal! l
        else
            call s:DisplayCalltips()
        endif
    endif

    return ''
endfunction

function! s:AutoUpdateCalltips() "{{{2
    "函数无参数，自动结束
    "if len(s:lCalltips) == 1 && s:lCalltips[0] =~# '()\|(\s*void\s*)'
        "call s:StopCalltips()
        "call search(')', 'Wc')
        "normal! l
    "endif

    "精确模式
    let nIdx = s:GetArgIndex()
    if nIdx == -2
        "不在括号内, 停止
        call s:StopCalltips()
    elseif nIdx == -1
        "没有找到函数名称, 可能在括号内输入了括号
        "TODO: 如果开始位置前于初始化时的开始位置, 必定停止
    elseif nIdx >= 0
        let s:nArgIndex = nIdx
        call s:DisplayCalltips()
    endif

    return ''
endfunction

function! s:StopCalltips() "{{{2
    call filter(s:lCalltips, 0)
    let s:nCurIndex = 0
    let s:nArgIndex = 0

    silent! au! DispCalltipsGroup
    if exists('s:bak_showmode')
        let &showmode = s:bak_showmode
        let &ruler = s:bak_ruler
        let &cmdheight = s:bak_cmdheight
        unlet s:bak_showmode
        unlet s:bak_ruler
        unlet s:bak_cmdheight

        "目的在于刷新
        echo ""
    endif
endfunction

function! s:HighlightNextCalltips() "{{{2
    let nLen = len(s:lCalltips)
    let s:nCurIndex = (s:nCurIndex + 1) % nLen
    call s:DisplayCalltips()
    return ''
endfunction

function! s:HighlightPrevCalltips() "{{{2
    let nLen = len(s:lCalltips)
    let s:nCurIndex = (s:nCurIndex - 1 + nLen) % nLen
    call s:DisplayCalltips()
    return ''
endfunction

function! s:DisplayCalltips() "{{{2
    if empty(s:lCalltips)
        return ''
    endif

    let nCalltipsCount = len(s:lCalltips)
    let sCurCalltips = s:lCalltips[s:nCurIndex]
    let nArgStartIdx = stridx(sCurCalltips, '(') + 1
    let nArgEndIdx = strridx(sCurCalltips, ')') - 1

    if !g:VLCalltips_IndicateArgument
        let sContent = sCurCalltips
                    \. ' ('. (s:nCurIndex + 1) . '/' . nCalltipsCount . ')'

        " 12 很诡异...
        let nHeight = len(sContent) / (&columns - 12) + 1
        let &cmdheight = nHeight

        echohl Type
        echo sContent[: nArgStartIdx-1]
        echohl SpecialChar
        echon sContent[nArgStartIdx : nArgEndIdx]
        echohl Type
        echon sContent[nArgEndIdx+1 :]
        echohl None

        return ''
    endif

    let nHlStartIdx = nArgStartIdx
    let i = 0
    while i < s:nArgIndex
        let nHlStartIdx = stridx(sCurCalltips, ',', nHlStartIdx)
        if nHlStartIdx != -1
            let nHlStartIdx += 1
        else
            "指定的参数超过了该函数的参数数量
            let nHlStartIdx = nArgEndIdx + 1
            break
        endif
        let i += 1
    endwhile

    let nHlStopIdx = nArgEndIdx
    let nHlStopIdx = stridx(sCurCalltips, ',', nHlStartIdx)
    if nHlStopIdx != -1
        "vim 的子串索引包括尾端，和 python 不一致！
        let nHlStopIdx -= 1
    else
        "当前参数索引是最后的参数，所以 nHlStopIdx 为 -1
        let nHlStopIdx = nArgEndIdx
    endif

    let sContent = sCurCalltips
                \. ' ('. (s:nCurIndex + 1) . '/' . nCalltipsCount . ')'

    " 12 很诡异...
    let nHeight = len(sContent) / (&columns - 12) + 1
    let &cmdheight = nHeight

    "处理可变参数
    let nVaArgIdx = match(sCurCalltips, '\V...)')
    if nVaArgIdx != -1 && nHlStartIdx > nVaArgIdx
        "存在可变参数，且参数索引到达最后了，锁定为最后的参数
        let nHlStartIdx = nVaArgIdx
    endif

    echohl Type
    echo sContent[: nHlStartIdx-1]
    echohl SpecialChar
    echon sContent[nHlStartIdx : nHlStopIdx]
    echohl Type
    echon sContent[nHlStopIdx + 1 :]
    echohl None
endfunction

function! s:GetArgIndex() "{{{2
    " 精确地确定光标所在位置所属的函数参数索引
    " 不在括号内，返回 -2，函数名为空，返回 -1

    " 确定函数括号开始的位置
    if g:VLCalltips_EnableSyntaxTest
        let sSkipExpr = 'synIDattr(synID(line("."), col("."), 0), "name") '
                    \. '=~? "string\\|character"'
    else
        let sSkipExpr = ''
    endif
    let lStartPos = searchpairpos('(', '', ')', 'nWb', sSkipExpr)
    " 如果刚好在括号内，加 'c' 参数
    let lEndPos = searchpairpos('(', '', ')', 'nWc', sSkipExpr)
    let lCurPos = [line('.'), col('.')]

    " 不在括号内
    if lStartPos[0] == 0 && lStartPos[1] == 0
        return -2
    else
        if !g:VLCalltips_IndicateArgument
            return 0
        endif
    endif

    "let lines = getline(lStartPos[0], lEndPos[0])

    " 获取函数名称和名称开始的列，暂时只处理 '(' "与函数名称同行的情况，
    " 允许之间有空格
    " TODO: 处理更复杂的情况: 1.函数名称与 ( 不在同行 2.函数名称前有逗号
    let sStartLine = getline(lStartPos[0])
    let sFuncName = matchstr(sStartLine[: lStartPos[1]-1], '\w\+\ze\s*($')
    let nFuncIdx = match(sStartLine[: lStartPos[1]-1], '\w\+\ze\s*($')

    let nArgIdx = -1
    if sFuncName != ''
        " 计算光标所在的位置所属的函数参数索引(从 0 开始)
        let nArgIdx = 0

        for nLine in range(lStartPos[0], lCurPos[0])
            let sLine = getline(nLine)
            let nStart = 0
            let nEnd = len(sLine)

            if nLine == lCurPos[0]
                " 光标所在行
                let nEnd = lCurPos[1] - 1 "(a,b|,c)
            endif

            while nStart < nEnd
                let nStart = stridx(sLine, ',', nStart)
                if nStart != -1 && nStart < nEnd
                    " 确保不是字符串里的逗号
                    if !(g:VLCalltips_EnableSyntaxTest 
                                \&& synIDattr(synID(nLine, nStart + 1, 0), 
                                \             "name") =~? 'string\|character')
                        let nArgIdx += 1
                    endif
                else
                    break
                endif
                let nStart += 1
            endwhile
        endfor
    endif

    return nArgIdx
endfunction


" vim:fdm=marker:fen:expandtab:smarttab:fdl=1:
plugin/VLClangCodeCompletion.vim	[[[1
760
" Vim global plugin for code-completion with clang
" Author:   fanhe <fanhed@163.com>
" License:  This file is placed in the public domain.
" Create:   2011 Apr 21
" Change:   2011 Jun 25

"if !has('python')
    "echo "Error: ".expand('%:p')." required vim compiled with +python"
    "finish
"endif

if exists("g:loaded_VLClangCodeCompletion")
    finish
endif
let g:loaded_VLClangCodeCompletion = 1

if !executable('clang')
    finish
endif

function! s:InitVariable(varName, defaultVal) "{{{2
    if !exists(a:varName)
		let {a:varName} = a:defaultVal
        return 1
    endif
    return 0
endfunction
"}}}

let s:CompletionType_NormalCompl = 0
let s:CompletionType_MemberCompl = 1

"autocmd FileType c,cpp call g:InitVLClangCodeCompletion()

function! g:GetClangCodeCompletionOutput() "{{{2
    let nLine = line('.')
    let nCol = col('.')
    return s:GetCodeCompletionOutput(nLine, nCol, '', '')
endfunction
"}}}

"临时启用选项函数 {{{2
function! s:SetOpts()
    let s:bak_cot = &completeopt

    if g:VLCCC_ItemSelectionMode == 0 " 不选择
        set completeopt-=menu,longest
        set completeopt+=menuone
    elseif g:VLCCC_ItemSelectionMode == 1 " 选择并插入文本
        set completeopt-=menuone,longest
        set completeopt+=menu
    elseif g:VLCCC_ItemSelectionMode == 2 " 选择但不插入文本
        set completeopt-=menu,longest
        set completeopt+=menuone
    else
        set completeopt-=menu
        set completeopt+=menuone,longest
    endif

    return ''
endfunction
function! s:RestoreOpts()
    if exists('s:bak_cot')
        let &completeopt = s:bak_cot
        unlet s:bak_cot
    else
        return ""
    endif

    let sRet = ""

    if pumvisible()
        if g:VLCCC_ItemSelectionMode == 0 " 不选择
            let sRet = "\<C-p>"
        elseif g:VLCCC_ItemSelectionMode == 1 " 选择并插入文本
            let sRet = ""
        elseif g:VLCCC_ItemSelectionMode == 2 " 选择但不插入文本
            let sRet = "\<C-p>\<Down>"
        else
            let sRet = "\<Down>"
        endif
    endif

    return sRet
endfunction
function! s:CheckIfSetOpts()
    let sLine = getline('.')
    let nCol = col('.') - 1
    "若是成员补全，添加 longest
    if sLine[nCol-2:] =~ '->' || sLine[nCol-1:] =~ '\.' 
                \|| sLine[nCol-2:] =~ '::'
        call s:SetOpts()
    endif

    return ''
endfunction
"}}}
function! s:CanComplete() "{{{2
    if (getline('.') =~ '#\s*include')
        " 写头文件，忽略
        return 0
    else
        " 检测光标所在的位置，如果在注释、双引号、浮点数时，忽略
        let nLine = line('.')
        let nCol = col('.') - 1 " 是前一列 eg. ->|
        if nCol < 1
            " TODO: 支持续行的补全
            return 0
        endif
        if g:VLCCC_EnableSyntaxTest
            let lStack = synstack(nLine, nCol)
            let lStack = empty(lStack) ? [] : lStack
            for nID in lStack
                if synIDattr(nID, 'name') 
                            \=~? 'comment\|string\|float\|character'
                    return 0
                endif
            endfor
        else
            " TODO
        endif

        return 1
    endif
endfunction
"}}}
function! s:LaunchVLClangCodeCompletion() "{{{2
    if s:CanComplete()
        return "\<C-x>\<C-o>"
    else
        return ''
    endif
endfunction
"}}}
function! s:CompleteByChar(char) "{{{2
    if a:char ==# '.'
        return a:char . s:LaunchVLClangCodeCompletion()
    elseif a:char ==# '>'
        if getline('.')[col('.') - 2] != '-'
            return a:char
        else
            return a:char . s:LaunchVLClangCodeCompletion()
        endif
    elseif a:char ==# ':'
        if getline('.')[col('.') - 2] != ':'
            return a:char
        else
            return a:char . s:LaunchVLClangCodeCompletion()
        endif
    endif
endfunction
"}}}
function! g:InitVLClangCodeCompletion() "{{{2
    setlocal omnifunc=VLClangCodeCompletion

    " MayComplete to '.'
    call s:InitVariable('g:VLCCC_MayCompleteDot', 1)

    " MayComplete to '->'
    call s:InitVariable('g:VLCCC_MayCompleteArrow', 1)

    " MayComplete to '::'
    call s:InitVariable('g:VLCCC_MayCompleteColon', 1)

    " 把回车映射为: 
    " 在补全菜单中选择并结束补全时, 若选择的是函数, 自动显示函数参数提示
    call s:InitVariable('g:VLCCC_MapReturnToDispCalltips', 1)

    " When completeopt does not contain longest option, this setting 
    " controls the behaviour of the popup menu selection 
    " when starting the completion
    "   0 = don't select first item
    "   1 = select first item (inserting it to the text)
    "   2 = select first item (without inserting it to the text)
    "   default = 2
    call s:InitVariable('g:VLCCC_ItemSelectionMode', 2)

    " 使用语法测试
    call s:InitVariable('g:VLCCC_EnableSyntaxTest', 1)

    " Clang program
    call s:InitVariable('g:VLCCC_ClangProgram', 'clang')

    " Indicate syntax error when completing
    call s:InitVariable('g:VLCCC_IndicateError', 1)


    " 初始化函数参数提示服务
    call g:InitVLCalltips()

    if g:VLCCC_MayCompleteDot
        inoremap <silent> <buffer> . 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('.')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLCCC_MayCompleteArrow
        inoremap <silent> <buffer> > 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('>')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLCCC_MayCompleteColon
        inoremap <silent> <buffer> : 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar(':')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLCCC_ItemSelectionMode > 4
        inoremap <silent> <buffer> <C-n> 
                    \<C-r>=<SID>CheckIfSetOpts()<CR>
                    \<C-r>=<SID>LaunchVLClangCodeCompletion()<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    else
        "inoremap <silent> <buffer> <C-n> 
                    "\<C-r>=<SID>SetOpts()<CR>
                    "\<C-r>=<SID>LaunchVLClangCodeCompletion()<CR>
                    "\<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLCCC_MapReturnToDispCalltips
        inoremap <silent> <expr> <buffer> <CR> pumvisible() ? 
                    \"\<C-y>\<C-r>=<SID>RequestCalltips(1)\<Cr>" : 
                    \"\<CR>"
    endif

    "显示函数 calltips 的快捷键
    exec 'inoremap <silent> <buffer> ' . g:VLCalltips_DispCalltipsKey 
                \. ' <C-r>=<SID>RequestCalltips()<CR>'
endfunction
"}}}
function! s:GetCalltips(lOutput, sFuncName) "{{{2
    let lOutput = a:lOutput
    let sFuncName = a:sFuncName

    let lCalltips = []

    for sLine in lOutput
        if sLine[:11] == 'COMPLETION: '
            let sString = sLine[12:]

            if sString !~# '^' . sFuncName . '\>'
                continue
            endif

            let nColonIdx = stridx(sString, ' : ')
            if nColonIdx != -1
                let sFuncName = sString[: nColonIdx-1]
                let sProto = sString[nColonIdx+3 :]
            else
                continue
            endif

            let sKind = s:GetKind(sProto)
            if sKind == 'f'
                call add(lCalltips, s:PruneProto(sProto))
            endif
        endif
    endfor

    return lCalltips
endfunction
"}}}
function! s:RequestCalltips(...) "{{{2
    if a:0 > 0 && a:1 "从全能补全菜单选择条目后，使用上次的输出
        let sLine = getline('.')
        let nCol = col('.')
        if sLine[nCol-3:] =~ '^()'
            normal! h
            let sFuncName = matchstr(sLine[: nCol-4], '\w\+$')

            let lCalltips = s:GetCalltips(s:lOutput, sFuncName)
            call g:DisplayVLCalltips(lCalltips, 0)
        endif
    else "普通情况，请求 calltips
        "确定函数括号开始的位置
        let lOrigCursor = getpos('.')
        let lStartPos = searchpairpos('(', '', ')', 'nWb', 
                \'synIDattr(synID(line("."), col("."), 0), "name") =~? "string"')
        "考虑刚好在括号内，加 'c' 参数
        let lEndPos = searchpairpos('(', '', ')', 'nWc', 
                \'synIDattr(synID(line("."), col("."), 0), "name") =~? "string"')
        let lCurPos = lOrigCursor[1:2]

        "不在括号内
        if lStartPos ==# [0, 0]
            return ''
        endif

        "获取函数名称和名称开始的列，只能处理 '(' "与函数名称同行的情况，
        "允许之间有空格
        let sStartLine = getline(lStartPos[0])
        let sFuncName = matchstr(sStartLine[: lStartPos[1]-1], '\w\+\ze\s*($')
        let nFuncStartIdx = match(sStartLine[: lStartPos[1]-1], '\w\+\ze\s*($')

        let lCalltips = []
        if sFuncName != ''
            "找到了函数名，开始全能补全

            "初始化 VLWorkspace 的附加参数
            let sAdditionOpts = g:GetVLWAdditionClangOpts()

            let sOutput = s:GetCodeCompletionOutput(lStartPos[0], 
                        \nFuncStartIdx+1, sAdditionOpts, '')
            let s:lOutput = split(sOutput, "\n")
            let lCalltips = s:GetCalltips(s:lOutput, sFuncName)
        endif

        call setpos('.', lOrigCursor)
        call g:DisplayVLCalltips(lCalltips, 0)
    endif

    return ''
endfunction
"}}}
function! s:GetClangVersion() "{{{2
    if !executable('clang')
        return 0.0
    endif

    return str2float(matchstr(system('clang -v'), 'version\s\zs[0-9.]\+\ze\s'))
endfunction
"}}}
function! s:GetKind(proto) "{{{2
    " v 变量
    " f 函数或方法
    " m 结构或类成员
    " t typedef
    " d #define 或宏
    if a:proto == ''
        return 't'
    endif
    let l:ret = match(a:proto, '^\[#')
    let l:params = match(a:proto, '(')
    if l:ret == -1 && l:params == -1
        return 't'
    endif
    if l:ret != -1 && l:params == -1
        return 'v'
    endif
    if l:params != -1
        return 'f'
    endif
    return 'm'
endfunction
"}}}
function! s:PruneProto(prototype) "{{{2
    " [# 属性（返回类型、修饰） #]
    let sProto = substitute(a:prototype, '[#', '', 'g')
    let sProto = substitute(sProto, '#]', ' ', 'g')

    " <# 函数参数列表 #>
    let sProto = substitute(sProto, '#>', '', 'g')
    let sProto = substitute(sProto, '<#', '', 'g')
    " {# 可选的函数参数（有默认值的参数） #}
    let sProto = substitute(sProto, '{#.*#}', '', 'g')

    "清理所有尖括号内容
    let l:tmp = sProto
    let sProto = ''
    let idx = 0
    let l:count = 0
    while l:tmp[idx] != ''
        if l:tmp[idx] == '<'
            let l:count += 1
        elseif l:tmp[idx] == '>'
            let l:count -= 1
        elseif l:count == 0
            let sProto .= l:tmp[idx]
        endif

        let idx += 1
    endwhile

    return sProto
endfunction
"}}}
function! s:SyntaxCheck(sLine) "{{{2
    let sLine = a:sLine

    if match(sLine, '\%(error\): ') == -1
        return 0
    endif

    let sPattern = '^\(.*\):\(\d*\):\(\d*\):\(\%({\d\+:\d\+-\d\+:\d\+}\)*\)'
    let sTmp = matchstr(sLine, sPattern)
    let sFName = substitute(sTmp, sPattern, '\1', '')
    let nLine = substitute(sTmp, sPattern, '\2', '')
    let nCol = substitute(sTmp, sPattern, '\3', '')
    let sErrors = substitute(sTmp, sPattern, '\4', '')

    " Highlighting the ^
    let sPat = '/\%' . nLine . 'l' . '\%' . nCol . 'c./'
    exec 'syntax match' . ' SpellBad ' . sPat

    let lRanges = split(sErrors, '}')
    for sRange in lRanges
        " Doing precise error and warning handling.
        " The highlight will be the same as clang's carets.
        let sPattern = '{\%(\d\+\):\(\d\+\)-\%(\d\+\):\(\d\+\)'
        let sTmp = matchstr(sRange, sPattern)
        let nStartCol = substitute(sTmp, sPattern, '\1', '')
        let nEndCol = substitute(sTmp, sPattern, '\2', '')
        " Highlighting the ~~~~
        let sPat = '/\%' . nLine . 'l'
                    \. '\%' . nStartCol . 'c'
                    \. '.*'
                    \. '\%' . nEndCol . 'c/'
        exec 'syntax match' . ' SpellBad ' . sPat
    endfor

    return 1
endfunction
"}}}
function! VLClangCodeCompletion(findstart, base) "{{{2
    if a:findstart
        syntax clear SpellBad
        call g:Timer.Start() "计时用

        let sLine = getline('.')
        let nStartIdx = col('.') - 1
        "普通补全
        let b:nCompletionType = s:CompletionType_NormalCompl
        let nBlankIdx = nStartIdx
        if sLine[nBlankIdx - 1] =~ '\s'
            "跳过空格， . -> :: 之间是允许空格的...
            while nBlankIdx > 0 && sLine[nBlankIdx - 1] =~ '\s'
                let nBlankIdx -= 1
            endwhile
        endif
        if sLine[nBlankIdx - 1] =~ '[(,]'
            "在括号内或者前面遇到逗号（括号内？），应该是函数 calltips
            let b:findstart = nBlankIdx
            return nBlankIdx
        endif
        "不会是函数 calltips
        while nStartIdx > 0 && sLine[nStartIdx - 1] =~ '\i'
            "跳过缩进， . -> :: 之间是允许空格的...
            let nStartIdx -= 1
        endwhile
        if sLine[nStartIdx - 2:] =~ '->' || sLine[nStartIdx - 1] == '.'
            "是成员补全
            let b:nCompletionType = s:CompletionType_MemberCompl
        endif
        let b:findstart = nStartIdx
        return nStartIdx
    endif

    "===========================================================================
    " 补全操作开始
    "===========================================================================

    let nLine = line('.') "行
    let nCol = col('.') "列
    "初始化 VLWorkspace 的附加参数
    let sAdditionOpts = g:GetVLWAdditionClangOpts()

    "返回的是列表，以后可能改为返回字符串
    let b:sOutput = s:GetCodeCompletionOutput(nLine, nCol, sAdditionOpts, '')
    let s:lOutput = split(b:sOutput, "\n")

    "调试用
    let b:lRes = []
    let b:base = a:base
    let sBase = a:base

    if sBase != ''
        "使用二分查找搜索匹配的结果，效果不明显，瓶颈在 clang
        "暂时没有处理 'Pattern'
        "let lOutput = s:DoBinarySearch(s:lOutput, 'COMPLETION: ' . sBase)
        let lOutput = s:lOutput
    else
        let lOutput = s:lOutput
    endif

    let bHasErrors = 0

    for sLine in lOutput
        "clang 输出示例:
        "一般单词: 候选单词
        "'Pattern': 为可用语法
        "'(Hidden)': 被覆盖的函数(派生类覆盖基类)
        "[# #]: 限定词(类型, 修饰)
        "<# #>: 必要形参
        "{# #}: 可选参数
        "=======================================================================
        "COMPLETION: useconds_t : useconds_t
        "COMPLETION: Pattern : using <#qualifier#>::<#name#>
        "COMPLETION: at : [#const_reference#]at(<#size_type __n#>)[# const#]
        "COMPLETION: reserve : [#void#]reserve({#<#size_type __res_arg#>#})
        "COMPLETION: GameClean (Hidden) : [#void#]MB_GAME::GameClean()
        "=======================================================================
        if sLine[:11] ==# 'COMPLETION: '
            if bHasErrors
                break
            endif

            let sString = sLine[12:]

            "Chop off anything after " : ", if present, and move it to the menu.
            let sMenu = ''
            let nColonIdx = stridx(sString, ' : ')
            if nColonIdx != -1
                let sWord = sString[:nColonIdx-1]
                let sAbbr = sWord
                let sMenu = sString[nColonIdx+3:]
            else
                let sWord = sString
                let sAbbr = sWord
                let sMenu = sString
            endif

            "处理 'Pattern'
            if sWord ==# 'Pattern'
                let sWord = matchstr(sMenu, '\w\+\>')
            endif

            " Chop off " (Hidden)", if present, and move it to the menu.
            let nHiddenIdx = stridx(sWord, " (Hidden)")
            if nHiddenIdx != -1
               let sMenu .= " (Hidden)"
               let sWord = sWord[:nHiddenIdx-1]
            endif

            "不符合要求，跳过
            if sWord !~ '^' . sBase "大小写由选项控制
                continue
            endif

            let sKind = s:GetKind(sMenu)
            if sKind ==# 't' 
                        \&& b:nCompletionType == s:CompletionType_MemberCompl
                "在成员补全中过滤掉类型定义的条目
                "continue
            endif

            if sKind ==# 'f'
                "若为函数类型，添加左括号
                let sWord .= '()'
            endif

            "let sMenu = s:PruneProto(sMenu)
        elseif sLine[:9] == 'OVERLOAD: '
            "TODO: 重载?! 2.7 版貌似没有这个东东?
            throw "OVERLOAD!"
            continue
        else
            if s:SyntaxCheck(sLine)
                let bHasErrors = 1
            endif
            continue
        endif


        let sMenu = ''
        let sLine = ''
        let dItem = {
                    \ 'word' : sWord,
                    \ 'menu' : sMenu,
                    \ 'info' : sLine,
                    \ 'kind' : sKind,
                    \ 'icase': &ignorecase,
                    \ 'dup'  : 0,
                    \}

        "一般都比较慢，所以用异步方法
        if complete_add(dItem) == 0
            "加入失败 (空字符串或者内存不足)
            break
        endif
        if complete_check()
            "搜索被中止
            break
        endif

        "调试用
        "call add(b:lRes, dItem)
    endfor

    if has('python')
        py g_ds = None
    endif

    call g:Timer.EndEchoMes()

    "return b:lRes
    return []
    "===========================================================================
    " 补全操作结束
    "===========================================================================
endfunction
"}}}
" 二分查找匹配的结果
function! s:DoBinarySearch(list, base) "{{{2
    let l:res = []

    let pat = a:base
    let listLen = len(a:list)
    let l = len(pat)
    let b:idx = s:BinaryGetIndex(a:list, pat)
    if b:idx != -1
        let min = b:idx
        let max = b:idx
        while min-1 >= 0 && a:list[min-1][: l-1] ==? pat
            let min -= 1
        endwhile
        while max+1 < listLen && a:list[max+1][: l-1] ==? pat
            let max += 1
        endwhile
        let l:res = a:list[min : max]
    endif

    return l:res
endfunction
"}}}
" 二分查找匹配的索引，-1 为无匹配
function! s:BinaryGetIndex(list, base) "{{{2
    let n1 = 0
    let n2 = len(a:list) - 1
    let l = len(a:base)
    if n1 == n2 || l == 0
        return -1
    endif

    let n = (n1 + n2) / 2
    while n2 != n1 + 1
        if a:list[n][: l-1] <? a:base
            let n1 = n
        elseif a:list[n][: l-1] >? a:base
            let n2 = n
        else
            return n
        endif
        let n = (n1 + n2) / 2
    endwhile

    "已无中间值，分别比较两端值
    if a:list[n1] ==? a:base
        return n1
    elseif a:list[n2] ==? a:base
        return n2
    else
        return -1
    endif
endfunction
"}}}
"获取当前编辑的文件指定位置的自动完成列表(原始输出)
"附加选项和预编译头选项都是完全的选项，而不仅仅是其中的一部分！
function! s:GetCodeCompletionOutput(nLine, nCol, sAdtOpts, sPchFile) "{{{2
    let nLine = a:nLine
    let nCol = a:nCol
    let sAdtOpts = a:sAdtOpts
    let sPchOpts = ''
    if a:sPchFile !=# ''
        let sPchOpts = '-include-pch ' . a:sPchFile
    endif

    if s:GetClangVersion() > 2.7
        "新版本，直接从标准输入读入，无须请求 IO，快！
        "代码取自 llvm svn

        " Build a clang commandline to do code completion on stdin.
        let sCommand = shellescape(g:VLCCC_ClangProgram)
                    \. ' -cc1 -fsyntax-only'
                    \. ' -fno-caret-diagnostics'
                    \. ' -fdiagnostics-print-source-range-info'
                    \. ' -cc1 -code-completion-at=-:' . nLine . ':' . nCol
                    \. ' -x c++ '
                    \. ' ' . sAdtOpts
                    \. ' ' . sPchOpts
                    \. ' - '

        " Copy the contents of the current buffer into a string for stdin.
        " TODO: The extra space at the end is for working around clang's
        " apparent inability to do code completion at the very end of the
        " input.
        " TODO: Is it better to feed clang the entire file instead of truncating
        " it at the current line?
        let sClangInput = join(getline(1, nLine), "\n") . " "

        " Run it!
        let sOutput = system(sCommand, sClangInput)
    endif

    return sOutput
endfunction
"}}}
function! g:GetVLWAdditionClangOpts() "{{{2
    if !has('python') || !g:VLWorkspaceHasStarted
        return ''
    endif
    let sPchFile = ''
    py g_ds = None
python << PYTHON_EOF
def GetVLWAdditionClangOpts():
    # NOTE: 这个文件内的 dir() 为空！
    #if 'ws' not in dir() or not ws:
    if not ws:
        vim.command("echom 'Why?'")
        return

    matrix = ws.VLWIns.GetBuildMatrix()
    wspSelConf = matrix.GetSelectedConfigurationName()
    fileName = vim.eval("expand('%:p')")
    project = ws.VLWIns.GetProjectByFileName(fileName)
    if not project:
        vim.command("echom 'no project'")
        return

    global g_ds
    g_ds = Globals.DirSaver()
    os.chdir(project.dirName)

    projSelConf = matrix.GetProjectSelectedConf(wspSelConf, project.GetName())
    bldConf = ws.VLWIns.GetProjBuildConf(project.GetName(), projSelConf)
    if not bldConf or bldConf.IsCustomBuild():
        vim.command("echom 'no bldConf or is custom build'")
        return

    opts = []

    includePaths = bldConf.GetIncludePath()
    for i in includePaths.split(';'):
        if i:
            opts.append('-I%s' % i)

    cmpOpts = bldConf.GetCompileOptions().replace('$(shell', '$(')

    isCFile = (os.path.splitext(fileName)[1] == '.c')
    if isCFile:
        cmpOpts = bldConf.GetCCompileOptions().replace('$(shell', '$(')

    # clang 不接受 -g3 参数
    cmpOpts = cmpOpts.replace('-g3', '-g')

    opts += cmpOpts.split(';')

    pprOpts = bldConf.GetPreprocessor()

    for i in pprOpts.split(';'):
        if i:
            opts.append('-D%s' % i)

    vim.command("let sAdditionOpts = '%s'" % ' '.join(opts).encode('utf-8'))

    vim.command("let sPchFile = '%s'" % os.path.join(
        project.dirName, project.name + '_VLWPCH.h.pch'))
GetVLWAdditionClangOpts()
PYTHON_EOF
    if filereadable(sPchFile)
        let sAdditionOpts .= ' -include-pch ' . sPchFile
    endif

    return sAdditionOpts
endfunction
"}}}
" vim:fdm=marker:fen:expandtab:smarttab:fdl=1:
plugin/VLUtils.vim	[[[1
240
" Vim script utilities for VimLite
" Last Change: 2011 Apr 11
" Maintainer: fanhe <fanhed@163.com>
" License:  This file is placed in the public domain.

if exists('g:loaded_VLUtils')
    finish
endif
let g:loaded_VLUtils = 1

"Function: g:InitVariable(varName, defaultVal) {{{2
"初始化变量
"仅在没有变量定义时才赋值
"Arg: varName: 变量名
"Arg: defaultVal: 默认值
"Return: 1 表示赋值为默认, 否则为 0
function g:InitVariable(varName, defaultVal)
    if !exists(a:varName)
        let {a:varName} = a:defaultVal
        return 1
    endif
    return 0
endfunction

"Function: g:EchoHl(msg, ...) {{{2
"高亮显示 msg，默认高亮组为 WarningMsg
function g:EchoHl(msg, ...)
    let l:hlGroup = 'WarningMsg'
    if exists('a:1')
        let l:hlGroup = a:1
    endif

    exec 'echohl ' . l:hlGroup
    echo a:msg
    echohl None
endfunction

"FUNCTION: g:Exec(cmd) {{{2
"与 exec 命令相同，但是运行时 set eventignore=all
"主要用于“安全”地运行某些命令，例如窗口跳转
function g:Exec(cmd)
    let bak = &ei
    set eventignore=all
    try
        exec a:cmd
    catch
    finally
        let &ei = bak
    endtry
endfunction

"Function: g:BufInWinCount(bufNumber) 打开指定缓冲区的窗口数目 {{{2
function g:BufInWinCount(bufNumber)
    let cnt = 0
    let winnum = 1
    while 1
        let bufnum = winbufnr(winnum)
        if bufnum < 0
            break
        endif
        if bufnum ==# a:bufNumber
            let cnt = cnt + 1
        endif
        let winnum = winnum + 1
    endwhile

    return cnt
endfunction


"FUNCTION: g:IsWindowUsable(winNumber) 判断窗口是否可用 "{{{2
function g:IsWindowUsable(winNumber)
    "如果仅有一个窗口打开，即自己是唯一窗口，怎样处理由外层决定
    "if winnr("$") == 1
        "return 0
    "endif

    "特殊窗口，如特殊缓冲类型的窗口、预览窗口
    let specialWindow = getwinvar(a:winNumber, '&buftype') != '' 
                \|| getwinvar(a:winNumber, '&previewwindow')
    if specialWindow
        return 0
    endif

    "窗口缓冲是否已修改
    let modified = getwinvar(a:winNumber, '&modified')

    "如果可允许隐藏，则无论缓冲是否修改
    if &hidden
        return 1
    endif

    "如果缓冲区没有修改，或者，已修改，但是同时有其他窗口打开着，则表示可用
    if !modified || g:BufInWinCount(winbufnr(a:winNumber)) >= 2
        return 1
    else
        return 0
    endif
endfunction


"FUNCTION: g:GetFirstUsableWindow() 获取第一个"常规"(非特殊)的窗口 {{{2
"特殊情况：特殊的缓冲区类型、预览缓冲区、已修改的缓冲并且不能隐藏
function g:GetFirstUsableWindow()
    let i = 1
    while i <= winnr("$")
        if g:IsWindowUsable(i)
            return i
        endif

        let i += 1
    endwhile
    return -1
endfunction


function g:GetMaxWidthWinNr() "{{{2
    let i = 1
    let nResult = 0
    let nMaxWidth = 0
    while i <= winnr("$")
        let nCurWidth = winwidth(i)
        if nCurWidth > nMaxWidth
            let nMaxWidth = nCurWidth
            let nResult = i
        endif
        let i += 1
    endwhile

    return nResult
endfunction


function g:GetMaxHeightWinNr() "{{{2
    let i = 1
    let nResult = 0
    let nMaxHeight = 0
    while i <= winnr("$")
        let nCurHeight = winheight(i)
        if nCurHeight > nMaxHeight
            let nMaxHeight = nCurHeight
            let nResult = i
        endif
        let i += 1
    endwhile

    return nResult
endfunction


function g:NormalizeCmdArg(arg) "{{{2
    return substitute(a:arg, ' ', '\\ ', "g")
endfunction


function s:SID() "{{{2
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function s:GetSFuncref(sFuncName) "{{{2
    return function('<SNR>'.s:SID().'_'.a:sFuncName[2:])
endfunction


let g:Timer = {'t1': 0, 't2': 0} "{{{1
function g:Timer.Start() "{{{2
    let self.t1 = reltime()
endfunction

function g:Timer.End() "{{{2
    let self.t2 = reltime()
endfunction

function g:Timer.EchoMes() "{{{2
    echom join(reltime(self.t1, self.t2), '.')
endfunction

function g:Timer.EndEchoMes() "{{{2
    call self.End()
    call self.EchoMes()
endfunction


function g:EchoSyntaxStack() "{{{2
    let names = []
    let li = synstack(line("."), col("."))
    let li = empty(li) ? [] : li
    for id in li
        "echo synIDattr(id, "name")
        call add(names, synIDattr(id, 'name'))
    endfor
    echo join(names, ', ')

    return ''
endfunction


function g:Progress(n, ...) "{{{2
    let n = a:n
    if a:0 > 0
        let m = a:1
    else
        let m = 100
    endif

    let nRange = 10
    let nRatio = n * nRange / m

    echoh Pmenu
    echon repeat(' ', nRatio)
    echoh None
    echon repeat(' ', nRange - nRatio)
    echon printf("%4d%%", n * 100 / m)
    redraw
endfunction


function g:GetCmdOutput(sCmd) "{{{2
    let bak_lang = v:lang

    " 把消息统一为英文
    exec ":lan mes en_US.UTF-8"

    try
        redir => sOutput
        silent! exec a:sCmd
    catch
        " 把错误消息设置为最后的 ':' 后的字符串?
        "let v:errmsg = substitute(v:exception, '^[^:]\+:', '', '')
    finally
        redir END
    endtry

    exec ":lan mes " . bak_lang

    return sOutput
endfunction


" vim:fdm=marker:fen:fdl=1:et:
plugin/vimdialog.vim	[[[1
3345
" Vim interactive dialog and control library.
" Author: 	fanhe <fanhed@163.com>
" License:	This file is placed in the public domain.
" Create: 	2011 Mar 21
" Change:	2011 Jun 13

function! s:InitVariable(sVarName, value) "{{{2
    if !exists(a:sVarName)
		let {a:sVarName} = a:value
        return 1
    endif
    return 0
endfunction
"}}}
function! s:SID() "{{{2
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
function! s:GetSFuncRef(sFuncName) "{{{2
    return function('<SNR>'.s:SID().'_'.a:sFuncName[2:])
endfunction
"}}}

"Function: s:exec(cmd) 忽略所有自动命令事件来运行 cmd {{{2
function! s:exec(cmd)
    let bak_ei = &ei
    set ei=all
	try
		exec a:cmd
	catch
	finally
		let &ei = bak_ei
	endtry
endfunction
"}}}

"全局变量 {{{2
call s:InitVariable("g:VimDialogActionKey", "<CR>")
call s:InitVariable("g:VimDialogRestoreValueKey", "R")
call s:InitVariable("g:VimDialogClearValueKey", "C")
call s:InitVariable("g:VimDialogSaveKey", "<C-s>")
call s:InitVariable("g:VimDialogQuitKey", "<C-x><C-x>")
call s:InitVariable("g:VimDialogSaveAndQuitKey", "<C-x><C-s>")
call s:InitVariable("g:VimDialogNextEditableCtlKey", "<C-n>")
call s:InitVariable("g:VimDialogPrevEditableCtlKey", "<C-p>")
call s:InitVariable("g:VimDialogToggleExtraHelpKey", "<F1>")


"控件的基本类型 {{{2
let g:VC_BLANKLINE = 0
let g:VC_SEPARATOR = 1
let g:VC_STATICTEXT = 2
let g:VC_SINGLETEXT = 3
let g:VC_MULTITEXT = 4
let g:VC_RADIOLIST = 5
let g:VC_CHECKLIST = 6
let g:VC_COMBOBOX = 7
let g:VC_CHECKITEM = 8
let g:VC_TABLE = 9
let g:VC_BUTTONLINE = 10

let g:VC_DIALOG = 99

let s:VC_MAXLINELEN = 78


"Class: VCBlankLine 空行类，所有控件类的基类 {{{1
let g:VCBlankLine = {}
"Function: g:VCBlankLine.New() {{{2
function! g:VCBlankLine.New()
	let newVCBlankLine = copy(self)
	let newVCBlankLine.id = -1 "控件 id
	let newVCBlankLine.gId = -1 "控件组id
	let newVCBlankLine.type = g:VC_BLANKLINE
	let newVCBlankLine.data = '' "私有数据，外部用
	let newVCBlankLine.indent = 0 "缩进，主要用于派生类
	let newVCBlankLine.editable = 0	"是否可变，若为0，除非全部刷新，否则控件不变
	let newVCBlankLine.activated = 1 "是否激活，区别高亮，若 editable 为 0，无效
	let newVCBlankLine.hiGroup = "Constant" "用于高亮
	let newVCBlankLine.owner = {}

	"用于自动命令和键绑定等的使用
	let l:i = 0
	while 1
		let l:ins = 'g:VCControlInstance_' . l:i
		if !exists(l:ins)
			let {l:ins} = newVCBlankLine
			let newVCBlankLine.interInsName = l:ins
			break
		endif
		let l:i += 1
	endwhile

	return newVCBlankLine
endfunction

function! g:VCBlankLine.GetType() "{{{2
	return self.type
endfunction

"Function: g:VCBlankLine.SetId(id) {{{2
"ID 理论上可为任何类型的值，但最好用整数
function! g:VCBlankLine.SetId(id)
	unlet self.id
	let self.id = a:id
endfunction

"Function: g:VCBlankLine.SetGId(id) {{{2
"GID 理论上可为任何类型的值，但最好用整数
function! g:VCBlankLine.SetGId(id)
	let self.gId = a:id
endfunction

"Function: g:VCBlankLine.SetData(data) {{{2
"data 可为任何类型的值
function! g:VCBlankLine.SetData(data)
	unlet self.data
	let self.data = a:data
endfunction

"Function: g:VCBlankLine.GetData() {{{2
"data 可为任何类型的值
function! g:VCBlankLine.GetData()
	return self.data
endfunction

"Function: g:VCBlankLine.SetIndent(indent) {{{2
function! g:VCBlankLine.SetIndent(indent)
	let self.indent = a:indent
endfunction

function! g:VCBlankLine.SetEditable(yesOrNo) "{{{2
	let self.editable = yesOrNo
endfunction

function! g:VCBlankLine.IsEditable() "{{{2
	return self.editable
endfunction

function! g:VCBlankLine.SetActivated(yesOrNo) "{{{2
	let self.activated = a:yesOrNo
endfunction

"Function: g:VCBlankLine.GetId() {{{2
function! g:VCBlankLine.GetId()
	return self.id
endfunction

"Function: g:VCBlankLine.GetGId() {{{2
function! g:VCBlankLine.GetGId()
	return self.gId
endfunction

function! g:VCBlankLine.GetOwner() "{{{2
	return self.owner
endfunction

"Function: g:VCBlankLine.GetDispText() {{{2
function! g:VCBlankLine.GetDispText()
"	let l:text = repeat(" ", s:VC_MAXLINELEN)
	let l:text = ""
	return  l:text
endfunction

"Function: g:VCBlankLine.SetupHighlight() 占位，设置文本高亮 {{{2
function! g:VCBlankLine.SetupHighlight()
endfunction

"Function: g:VCBlankLine.ClearHighlight() 占位，取消文本高亮 {{{2
function! g:VCBlankLine.ClearHighlight()
	if has_key(self, 'matchIds')
		for i in self.matchIds
			call matchdelete(i)
		endfor
	endif

	if hlexists('VCLabel_' . self.hiGroup)
		exec 'syn clear ' . 'VCLabel_' . self.hiGroup
	endif
endfunction

function! g:VCBlankLine.GotoNextCtl(...) "{{{2
	"跳至下一个控件, 返回零表示处理完毕
	"可选参数非零表示第一次调用
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	return 0
endfunction

function! g:VCBlankLine.GotoPrevCtl(...) "{{{2
	"跳至下一个控件, 返回零表示处理完毕
	"可选参数非零表示第一次调用
	return 0
endfunction

"Function: g:VCBlankLine.Delete() 销毁对象 {{{2
function! g:VCBlankLine.Delete()
	unlet {self.interInsName}
	call filter(self, 0)
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCSeparator 分割器类 {{{1
let g:VCSeparator = {}
"Function: g:VCSeparator.New(...) {{{2
function! g:VCSeparator.New(...)
	let newVCSeparator = copy(self)

	"继承，keep 为不覆盖新类的属性
	call extend(newVCSeparator, g:VCBlankLine.New(), "keep")

	let newVCSeparator.type = g:VC_SEPARATOR
	let newVCSeparator.editable = 0
	let newVCSeparator.hiGroup = 'PreProc'

	if exists('a:1')
		let newVCSeparator.sepChar = a:1
	else
		let newVCSeparator.sepChar = '='
	endif

	return newVCSeparator
endfunction

"Function: g:VCSeparator.GetDispText() {{{2
function! g:VCSeparator.GetDispText()
	let l:indentLen = self.indent
	let l:text = ''
"	let l:text = "\n"
	let l:text = l:text . repeat(" ", l:indentLen)
				\ . repeat(self.sepChar, s:VC_MAXLINELEN - l:indentLen)
"	let l:text = "\n"
	return  l:text
endfunction

"Function: g:VCSeparator.SetupHighlight() {{{2
function! g:VCSeparator.SetupHighlight()
	let l:pattern = '\V' . self.sepChar . '\+'
	let hiGroup = 'VCLabel_' . self.hiGroup
	exec 'syn match ' . hiGroup . ' ''' . 
				\'^' . repeat(' ', self.indent) . l:pattern . ''''
	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCStaticText 固定文本控件类 {{{1
let g:VCStaticText = {}
"Function: g:VCStaticText.New(label) {{{2
function! g:VCStaticText.New(label)
	let newVCStaticText = copy(self)

	call extend(newVCStaticText, g:VCBlankLine.New(), "keep")

	let newVCStaticText.label = a:label
	let newVCStaticText.type = g:VC_STATICTEXT
	let newVCStaticText.indent = 0
	let newVCStaticText.editable = 0
	let newVCStaticText.hiGroup = "Label"
	return newVCStaticText
endfunction

"Function: g:VCStaticText.SetHighlight(hiGroup) 设置标签文本高亮组 {{{2
function! g:VCStaticText.SetHighlight(hiGroup)
	"if !has_key(self, 'matchIds')
		"let self.matchIds = []
	"endif

	let self.hiGroup = a:hiGroup
endfunction

"Function: g:VCStaticText.GetLabel() {{{2
function! g:VCStaticText.GetLabel()
	return self.label
endfunction

"Function: g:VCStaticText.GetDispText() {{{2
function! g:VCStaticText.GetDispText()
	let s = repeat(" ", self.indent) . self.label
	return s
endfunction

"Function: g:VCStaticText.SetIndent(indent) {{{2
function! g:VCStaticText.SetIndent(indent)
	let self.indent = a:indent < 0 ? 0 : a:indent
endfunction

"Function: g:VCStaticText.SetupHighlight() {{{2
function! g:VCStaticText.SetupHighlight()
	if self.label == ''
		return
	endif

	"matchadd 消耗较大，改用语法高亮
	"if has_key(self, 'matchIds')
		"exec 'let m = matchadd("' . self.hiGroup . '", ''' 
					"\. '^\V' . repeat(' ', self.indent) . self.label. ''', -20)'
		"call add(self.matchIds, m)
	"endif

	let hiGroup = 'VCLabel_' . self.hiGroup
	exec 'syn match ' . hiGroup . ' ''' . '^\V' 
				\. repeat(' ', self.indent) . self.label . ''''
	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCSingleText 单行可编辑文本控件类，所有可编辑控件的基类 {{{1
let g:VCSingleText = {}
"Function: g:VCSingleText.New(label, ...) 可选参数为文本控件显示字符串值
function! g:VCSingleText.New(label, ...) "{{{2
	let newVCSingleText = copy(self)

	"继承？！
	let newVCSingleText.parent = g:VCStaticText.New(a:label)
"	call extend(newVCSingleText, newVCSingleText.parent, "error")
	call extend(newVCSingleText, newVCSingleText.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCSingleText, "parent")

	if exists("a:1")
		let newVCSingleText.value = a:1
		let newVCSingleText.origValue = a:1
	else
		let newVCSingleText.value = ''
	endif

	let newVCSingleText.prevValue = ''

	" 是否仅用一行显示，默认否
	let newVCSingleText.isSingleLine = 0
	" 是否回绕，只有 isSingleLine 为零时才有用
	let newVCSingleText.wrap = 1
	" label 显示占用的最小宽度，用于对齐。仅 isSingleLine 非零时才有用
	let newVCSingleText.labelDispWidth = 0

	" 绑定的变量，用于自动更新，可用 callback 定制更新方式
	let newVCSingleText.bindVar = ''
	" 用是指示自动绑定时是否 python 的变量
	let newVCSingleText.isPyVar = 0

	let newVCSingleText.type = g:VC_SINGLETEXT
	let newVCSingleText.editable = 1
	return newVCSingleText
endfunction
"}}}
"添加控件回调函数
"回调函数必须接收两个参数，控件和私有数据。值改变的时候才调用
function! g:VCSingleText.ConnectActionPostCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.actionPostCbk = a:func
	else
		let self.actionPostCbk = function(a:func)
	endif
	let self.actionPostCbkData = a:data
endfunction
"}}}
function! g:VCSingleText.HandleActionPostCallback() "{{{2
	if has_key(self, "actionPostCbk")
		call self.actionPostCbk(self, self.actionPostCbkData)
	endif
endfunction
"}}}
"用于拦截 Action, 回调函数返回 1 表示不继续处理原始的 Action 行为
function! g:VCSingleText.ConnectActionCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.actionCallback = a:func
	else
		let self.actionCallback = function(a:func)
	endif
	let self.actCbData = a:data
endfunction
"}}}
function! g:VCSingleText.HandleActionCallback() "{{{2
	if has_key(self, "actionCallback")
		return self.actionCallback(self, self.actCbData)
	else
		return 0
	endif
endfunction
"}}}
function! g:VCSingleText.ConnectButtonCallback(func, data) "按钮动作 {{{2
	if type(a:func) == type(function("tr"))
		let self.buttonCallback = a:func
	else
		let self.buttonCallback = function(a:func)
	endif
	let self.btnCbData = a:data
endfunction

function! g:VCSingleText.HandleButtonCallback() "{{{2
	if has_key(self, "buttonCallback")
		call self.buttonCallback(self, self.btnCbData)
		return 1
	else
		return 0
	endif
endfunction

"Function: g:VCSingleText.GetValue() 获取控件保存值 {{{2
function! g:VCSingleText.GetValue()
	return self.value
endfunction

"Function: g:VCSingleText.GetPrevValue() 获取控件上次的值 {{{2
function! g:VCSingleText.GetPrevValue()
	return self.prevValue
endfunction

"Function: g:VCSingleText.SetValue() 设置控件保存值 {{{2
function! g:VCSingleText.SetValue(value)
	let self.prevValue = self.value
	let self.value = a:value
	if !has_key(self, "origValue")
		let self.origValue = a:value
	endif
endfunction

"Function: g:VCSingleText.SetSingleLineFlag(yesOrNo) {{{2
function! g:VCSingleText.SetSingleLineFlag(yesOrNo)
	let self.isSingleLine = a:yesOrNo
endfunction

"Function: g:VCSingleText.SetLabelDispWidth(width) {{{2
function! g:VCSingleText.SetLabelDispWidth(width)
	let self.labelDispWidth = a:width
endfunction

"Function: g:VCSingleText.SetWrap(yesOrNo) {{{2
function! g:VCSingleText.SetWrap(yesOrNo)
	let self.wrap = a:yesOrNo
endfunction

"Function: g:VCSingleText.SetOrigValue() 设置控件原始值 {{{2
function! g:VCSingleText.SetOrigValue(value)
	let self.origValue = a:value
endfunction

"Function: g:VCSingleText.GetDispText() 获取控件显示文本 {{{2
function! g:VCSingleText.GetDispText()
	let s = ""
	let l:indentSpace = repeat(" ", self.indent)
	let l:labelLen = strdisplaywidth(self.label)
	let l:textLen = strdisplaywidth(self.value)

	"NOTE: 条件判断必须为整数，如果为字符串，会有奇怪的错误！
	if self.isSingleLine != 0
		let l:lw = l:labelLen
		let l:label = self.label . ' '	"固定加 1 空格，方便高亮
		if l:labelLen < self.labelDispWidth
			let l:lw = self.labelDispWidth
			let l:label = l:label . repeat(" ", self.labelDispWidth - l:labelLen)
		endif

		" 包括边界
		let l:textCtlLen = l:textLen + 2
		if self.indent + strdisplaywidth(l:label) + l:textLen <= s:VC_MAXLINELEN
			let l:textCtlLen = s:VC_MAXLINELEN - self.indent 
						\- strdisplaywidth(l:label)
		endif

		let s = s . l:indentSpace . repeat(' ', strdisplaywidth(l:label)) 
					\ . '+' . repeat('-', l:textCtlLen - 2) . '+' . "\n"
		let s = s . l:indentSpace . l:label . '|' . self.value 
					\ . repeat(' ', l:textCtlLen - l:textLen - 2) . '|' . "\n"
		let s = s . l:indentSpace . repeat(' ', strdisplaywidth(l:label)) 
					\ . '+' . repeat('-', l:textCtlLen - 2) . '+'
	else
		if self.label != ""
			"let s = s . l:indentSpace . self.label . "\n"
			"显示按钮，只有有指定动作时且标签非空时才显示
			let tmpS = l:indentSpace . self.label
			if has_key(self, 'buttonCallback')
				let tmpN = strdisplaywidth(tmpS)
				if tmpN <= s:VC_MAXLINELEN - len('[...]')
					let tmpS .= repeat(' ', 
								\s:VC_MAXLINELEN - tmpN - len('[...]')) 
								\. '[...]'
				else
					"如果长度超过允许值，暂时就简单地让 button 显示在最后
					let tmpS .= '[...]'
				endif
			endif
			let s .= tmpS . "\n"
		endif

		if self.wrap != 0 && self.indent + l:textLen + 2 > s:VC_MAXLINELEN
			let l:contentLen = s:VC_MAXLINELEN - self.indent - 2

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen)
						\ . "+\n"

			let i = 0
			while i < strlen(self.value)
				let l:content = strpart(self.value, i, l:contentLen)
				let l:curLen = strdisplaywidth(l:content)
				let s = s . l:indentSpace . "|" . l:content
							\ . repeat(" ", l:contentLen - l:curLen) . "|\n"
				let i += l:contentLen
			endwhile

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"
		else
			let l:contentLen = l:textLen
			if self.indent + 2 + l:textLen <= s:VC_MAXLINELEN
				let l:contentLen = s:VC_MAXLINELEN - self.indent - 2
			endif

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen)
						\ . "+\n"
			let s = s . l:indentSpace . "|" . self.value
						\ . repeat(" ", l:contentLen - l:textLen) . "|\n"
			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"
		endif
	endif

	return s
endfunction

"Function: g:VCSingleText.Action() 控件动作 {{{2
function! g:VCSingleText.Action()
	let l:ret = 0

	"检测是否按了按钮，直接通过检测语法高亮信息确定，比较慢？！
	if synIDattr(synID(line("."), col("."), 1), "name") ==? 'VCButton'
		if self.HandleButtonCallback()
			return 1
		endif
	endif

	echohl Question
	" TODO: 设置自动完成类型
	let l:value = input(self.label . "\n", self.value, "file")
	if exists("l:value") && len(l:value) != 0
		call self.SetValue(l:value)
		let l:ret = 1
	endif
	echohl None

	return l:ret
endfunction
"}}}
function! g:VCSingleText.ClearValueAction() "{{{2
	if self.HandleActionCallback()
		return 1
	endif

	call self.SetValue('')
	return 1
endfunction
"}}}
function! g:VCSingleText.RestoreValueAction() "{{{2
	if self.HandleActionCallback()
		return 1
	endif

	call self.SetValue(self.origValue)
	return 1
endfunction
"}}}
function! g:VCSingleText.SetBindVarCallback(func, data) "定制变量绑定行为 {{{2
	if type(a:func) == type(function("tr"))
		let self.bindVarCbk = a:func
	else
		let self.bindVarCbk = function(a:func)
	endif
	let self.bindVarCbkData = a:data
endfunction

"Function: g:VCSingleText.BindVariable(...) 把控件值绑定到某个变量 {{{2
function! g:VCSingleText.BindVariable(...)
	if has_key(self, 'bindVarCbk')
		call self.bindVarCbk(self, self.bindVarCbkData)
	else
		if exists('a:1')
			let self.bindVar = a:1
		endif
		if exists("a:2")
			let self.isPyVar = a:2
		endif

		if self.bindVar != ''
			if self.isPyVar && has('python')
				python import vim
				exec 'py vim.command("call self.SetValue(\"%s\")" % ' 
							\. self.bindVar . ')'
			elseif !self.isPyVar
				call self.SetValue({self.bindVar})
			endif
		endif
	endif

	let self.origValue = self.value
endfunction

"Function: g:VCSingleText.RefreshValueFromBindVar() 从绑定的变量刷新控件值 {{{2
function! g:VCSingleText.RefreshValueFromBindVar()
	call self.BindVariable()
endfunction

"Function: g:VCSingleText.SetIsPyVal(isOrNot) 用于直接帮定变量到 python 变量
function! g:VCSingleText.SetIsPyVal(isOrNot)
	let self.isPyVar = isOrNot
endfunction

function! g:VCSingleText.SetUpdateBindVarCallback(func, data) "定制绑定更新 {{{2
	if type(a:func) == type(function("tr"))
		let self.updateBindVarCbk = a:func
	else
		let self.updateBindVarCbk = function(a:func)
	endif
	let self.updateBindVarCbkData = a:data
endfunction

"Function: g:VCSingleText.UpdateBindVar() 更新绑定的变量值为控件值 {{{2
function! g:VCSingleText.UpdateBindVar()
	if has_key(self, 'updateBindVarCbk')
		call self.updateBindVarCbk(self, self.updateBindVarCbkData)
	elseif self.bindVar != ''
		if self.isPyVar != 0 && has('python')
			py import vim
			exec 'python ' . self.bindVar . ' = "' . self.value . '"'
		else
			exec "let " . self.bindVar . ' = "' . self.value . '"'
		endif
	endif
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCMultiText 多行可编辑文本控件类 "{{{1
let g:VCMultiText = {}
"Function: g:VCMultiText.New(label, ...) 可选参数为文本控件显示字符串值 {{{2
function! g:VCMultiText.New(label, ...)
	let newVCMultiText = copy(self)

	"继承自 VCSingleText
	let newVCMultiText.parent = g:VCSingleText.New(a:label)
	call extend(newVCMultiText, newVCMultiText.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCMultiText, "parent")

	let newVCMultiText.type = g:VC_MULTITEXT
	let newVCMultiText.values = []

	if exists("a:1")
		call newVCMultiText.SetValue(a:1)
	else
		let newVCMultiText.value = ''
	endif

	return newVCMultiText
endfunction

function! g:VCMultiText.GetDispText() "{{{2
	"不支持饶行功能
	let s = ""
	let l:indentSpace = repeat(" ", self.indent)

	if self.label != ""
		"显示按钮，只有有指定动作时且标签非空时才显示
		let tmpS = l:indentSpace . self.label
		if has_key(self, 'buttonCallback')
			let tmpN = strdisplaywidth(tmpS)
			if tmpN <= s:VC_MAXLINELEN - len('[...]')
				let tmpS .= repeat(' ', 
							\s:VC_MAXLINELEN - tmpN - len('[...]')) 
							\. '[...]'
			else
				"如果长度超过允许值，暂时就简单地让 button 显示在最后
				let tmpS .= '[...]'
			endif
		endif
		let s .= tmpS . "\n"
	endif

	"let texts = split(self.value, '\n', 1)
	let texts = self.values
	let l:contentLen = s:VC_MAXLINELEN - self.indent - 2
	let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+\n"
	for text in texts
		"逐行显示
		let l:textLen = strdisplaywidth(text)
		if l:textLen > l:contentLen
			"行太长, 揭短并在末尾添加 '@'
			let l:textLen = l:contentLen
			let text = text[: l:textLen-2] . "@"
		endif
		let s = s . l:indentSpace . "|" . text
					\ . repeat(" ", l:contentLen - l:textLen) . "|\n"
	endfor
	let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"

	return s
endfunction

function! g:VCMultiText.SetValue(value) "{{{2
	if type(a:value) == type([])
		let self.values = a:value
		let value = join(a:value, "\n")
	else
		let self.values = split(a:value, "\n", 1)
		let value = a:value
	endif

	call call(g:VCSingleText.SetValue, [value], self)
endfunction

function! g:VCMultiText.Action() "{{{2
	let l:ret = 0

	"检测是否按了按钮，直接通过检测语法高亮信息确定，比较慢？！
	if synIDattr(synID(line("."), col("."), 1), "name") ==? 'VCButton'
		if self.HandleButtonCallback()
			return 1
		endif
	endif

	"是否被拦截
	if self.HandleActionCallback()
		return 1
	endif

	"TODO

	return l:ret
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCComboBox 组合框选择控件类 {{{1
"若想设置选择的条目，直接调用 SetValue()
let g:VCComboBox = {}
"Function: g:VCComboBox.New(label) 可选参数为文本控件显示字符串值 {{{2
function! g:VCComboBox.New(label)
	let newVCComboBox = copy(self)

	"继承 VCSingleText
	let newVCComboBox.parent = g:VCSingleText.New(a:label)
	call extend(newVCComboBox, newVCComboBox.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCComboBox, "parent")

	let newVCComboBox.type = g:VC_COMBOBOX
	let newVCComboBox.editable = 1

	let newVCComboBox.items = []

	return newVCComboBox
endfunction

"Function: g:VCComboBox.GetDispText() 获取控件显示文本 {{{2
function! g:VCComboBox.GetDispText()
	let s = ""

	let l:textLen = strdisplaywidth(self.value)
	if l:textLen <= s:VC_MAXLINELEN - 4 - self.indent
		let l:spaceLen = s:VC_MAXLINELEN - 4 - self.indent
	else
		let l:spaceLen = l:textLen
	endif

	let l:indentSpace = repeat(" ", self.indent)

	if self.label != ""
		let s = s . l:indentSpace . self.label . "\n"
	endif

	let s = s . l:indentSpace . "+" . repeat("-", l:spaceLen)
				\ . "+-+\n"
	let s = s . l:indentSpace . "|" . self.value
				\ . repeat(" ", l:spaceLen - l:textLen) . "|v|\n"
	let s = s . l:indentSpace . "+" . repeat("-", l:spaceLen) . "+-+"

	return s
endfunction

function! g:VCComboBox.GetItems() "{{{2
	return self.items
endfunction

"Function: g:VCComboBox.AddItem(item) 添加条目 {{{2
function! g:VCComboBox.AddItem(item)
	call add(self.items, a:item)
	if !len(self.value)
		call self.SetValue(a:item)
	endif
endfunction

"Function: g:VCComboBox.RemoveItem(item) 删除指定条目 {{{2
function! g:VCComboBox.RemoveItem(item)
	let idx = index(self.items, a:item)
	if idx != -1
		call remove(self.items, idx)
		if self.GetValue() == a:item
			if !empty(self.items)
				if idx - 1 > 0
					call self.SetValue(self.items[idx - 1])
				else
					call self.SetValue(self.items[0])
				endif
			else
				call self.SetValue('')
			endif
		endif
	endif
endfunction

"Function: g:VCComboBox.InsertItem(item, idx) 在索引前插入条目 {{{2
function! g:VCComboBox.InsertItem(item, idx)
	call insert(self.items, a:item, a:idx)
	if !len(self.value)
		call self.SetValue(a:item)
	endif
endfunction

"Function: g:VCComboBox.RenameItem(oldItem, newItem) 重命名指定条目 {{{2
function! g:VCComboBox.RenameItem(oldItem, newItem)
	let oldItem = a:oldItem
	let newItem = a:newItem
	let idx = index(self.items, oldItem)
	if idx != -1
		let self.items[idx] = newItem
		if self.GetValue() == oldItem
			call self.SetValue(newItem)
		endif
	endif
endfunction

"Function: g:VCComboBox.Action() 控件动作 {{{2
function! g:VCComboBox.Action()
	let l:ret = 0
	let l:choices = []
	call add(l:choices, "Please select a choice:")
	let i = 1
	let l:index = index(self.items, self.value)

	while i - 1 < len(self.items)
		let pad = "  "
		if l:index == i - 1
			let pad = "* "
		endif
		call add(l:choices, pad . i . ". " . self.items[i - 1])
		let i += 1
	endwhile
	let l:choice = inputlist(choices)
	if exists("l:ret") && l:choice > 0 && l:choice - 1 < len(self.items)
		call self.SetValue(self.items[l:choice - 1])
		if l:choice -1 != l:index
			let l:ret = 1
		endif
	endif

	return l:ret
endfunction

function! g:VCComboBox.ClearValueAction() "{{{2
endfunction

function! g:VCComboBox.RestoreValueAction() "{{{2
endfunction

function! g:VCComboBox.SetupHighlight() "{{{2
	"调用祖先类的方法
	call call(g:VCStaticText.SetupHighlight, [], self)

	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif

	"高亮 v 箭头
"	let m = matchadd('SpecialChar', '\v\|v\|\ze[a-zA-Z0-9 ]$', -20)
	let m = matchadd('SpecialChar', '\v\|v\|\ze', -20)
	call add(self.matchIds, m)
"	let m = matchadd('SpecialChar', '\v\+\-\+\ze[a-zA-Z0-9 ]$', -20)
	let m = matchadd('SpecialChar', '\v\+\-\+\ze', -20)
	call add(self.matchIds, m)
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCCheckItem 复选条目控件类 {{{1
let g:VCCheckItem = {}
"Function: g:VCCheckItem.New(label, ...) 可选参数为文本控件显示字符串值 {{{2
function! g:VCCheckItem.New(label, ...)
	let newVCCheckItem = copy(self)

	"继承 VCSingleText
	let newVCCheckItem.parent = g:VCSingleText.New(a:label)
	call extend(newVCCheckItem, newVCCheckItem.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCCheckItem, "parent")

	if exists("a:1")
		let newVCCheckItem.value = a:1
		let newVCCheckItem.origValue = a:1
	else
		let newVCCheckItem.value = 0
	endif

	let newVCCheckItem.type = g:VC_CHECKITEM
	let newVCCheckItem.editable = 1

	"是否在显示时反转其值
	let newVCCheckItem.reverse = 0

	return newVCCheckItem
endfunction

function! g:VCCheckItem.SetReverse(yesOrNo) "{{{2
	let self.reverse = a:yesOrNo
endfunction

"Function: g:VCCheckItem.GetDispText() {{{2
function! g:VCCheckItem.GetDispText()
	let l:value = self.value

	let l:checked = "[ ] "
	if l:value != 0
		let l:checked = "[X] "
	endif
	let s = repeat(" ", self.indent) . l:checked . self.label
	return s
endfunction

"Function: g:VCCheckItem.Action() 控件动作 {{{2
function! g:VCCheckItem.Action()
	let l:ret = 1

	if self.value != 0
		call self.SetValue(0)
	else
		call self.SetValue(1)
	endif

	return l:ret
endfunction

"Function: g:VCCheckItem.BindVariable(...) 把控件值绑定到某个变量 {{{2
function! g:VCCheckItem.BindVariable(...)
	if exists("a:1")
		let self.bindVar = a:1
	endif
	if exists("a:2")
		let self.isPyVar = a:2
	endif

	if self.isPyVar && has("python")
		python import vim
		exec 'py i = ' . self.bindVar
python << EOF
if i:
	vim.command('call self.SetValue(1)')
else:
	vim.command('call self.SetValue(0)')
del i
EOF
	elseif !self.isPyVar
		call self.SetValue({self.bindVar})
	endif

	"是否反转变量值
	if self.reverse
		call self.SetValue(!self.GetValue())
	endif

	let self.origValue = self.value

	"FIXME: 关联 activated 怎样处理？
	call self.HandleActionPostCallback()
endfunction

"Function: g:VCCheckItem.UpdateBindVar() 更新绑定的变量值为控件值 {{{2
function! g:VCCheckItem.UpdateBindVar()
	let value = self.value
	if self.reverse
		let value = !value
	endif

	if self.bindVar != ''
		if self.isPyVar && has('python')
			py import vim
			if value != 0
				let pyVal = "True"	" 代表 python 的真
			else
				let pyVal = "False"	" 代表 python 的假
			endif
			exec 'python ' . self.bindVar . ' = ' . pyVal
		elseif !self.isPyVar
			exec "let " . self.bindVar . ' = "' . value . '"'
		endif
	endif
endfunction

function! g:VCCheckItem.SetupHighlight() "{{{2
	if self.label == ''
		return
	endif

	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif
	exec 'let m = matchadd("' . self.hiGroup . '", ''' 
				\. '^' . repeat(' ', self.indent) . '\[[ X]\] \zs' 
				\. self.label. ''', -20)'
	call add(self.matchIds, m)
	"FIXME: 为什么语法高亮不行？
"	let hiGroup = 'VCLabel_' . self.hiGroup
"	exec 'syn match ' . hiGroup . ' ''' . '^' . repeat(' ', self.indent) 
"				\. '\[[ X]\] \zs' . self.label . ''''
"	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"Class: VCTable 表格控件类，用于实现列表设置 "{{{1
let g:VCTable = {}
function! g:VCTable.New(label, ...) "{{{2
	let newVCTable = copy(self)

	"继承
	let newVCTable.parent = g:VCSingleText.New(a:label)
	call extend(newVCTable, newVCTable.parent, "keep")
	"暂时删除，不然影响调试
	call remove(newVCTable, "parent")

	let newVCTable.type = g:VC_TABLE

	let newVCTable.CT_TEXT = 0
	let newVCTable.CT_CHECK = 1

	"表格的列数，默认为 1
	let newVCTable.columns = 1
	if exists('a:1') && a:1 > 1
		let newVCTable.columns = a:1
	endif

	"一个表格行（列表）作为一个数据
	let newVCTable.table = []
	"页眉，记录列相关信息
	let newVCTable.header = []
	"为了统一编号，不添加进表格中
	"call add(newVCTable.table, newVCTable.header)

	let header = newVCTable.header
	for i in range(newVCTable.columns)
		let headerData = {}
		let headerData['title'] = ''
		let headerData['type'] = newVCTable.CT_TEXT
		call add(newVCTable.header, headerData)
	endfor

	"是否显示页眉，默认显示
	let newVCTable.dispHeader = 1

	"是否显示按钮，默认显示
	let newVCTable.dispButtons = 1

	"当前选择的行，如没有选择，则为 0，行数从 1 开始
	let newVCTable.selection = 0

	"是否允许直接编辑单元格，默认允许
	let newVCTable.cellEditable = 1

	"是否启用按钮，默认全部启用
	let newVCTable.btnEnabledFlag = repeat([1], 6)

	return newVCTable
endfunction

function! g:VCTable.SetDispHeader(yesOrNo) "{{{2
	let self.dispHeader = a:yesOrNo
endfunction

function! g:VCTable.SetDispButtons(yesOrNo) "{{{2
	let self.dispButtons = a:yesOrNo
endfunction

function! g:VCTable.SetSelection(selection) "{{{2
	let self.selection = a:selection
endfunction

function! g:VCTable.SetCellEditable(yesOrNo) "{{{2
	let self.cellEditable = a:yesOrNo
endfunction

function! g:VCTable.SetColTitle(col, title) "列数从 1 开始，内部从 0 开始 {{{2
	if a:col < self.columns + 1
		let self.header[a:col - 1].title = a:title
	endif
endfunction

function! g:VCTable.SetColType(col, type) "列数从 1 开始，内部从 0 开始 {{{2
	if a:col < self.columns + 1
		let self.header[a:col - 1].type = a:type
	endif
endfunction

function! g:VCTable.AddLineByValues(...) "多余的参数会被忽略 {{{2
	let i = 1
	let li = []
	while i <= a:0
		if i >= self.columns + 1
			break
		endif
		call add(li, a:{i})
		let i += 1
	endwhile

	call add(self.table, li)
endfunction

function! g:VCTable.SetCellValue(line, column, value) "{{{2
	if a:line < len(self.table) + 1 && a:column < self.columns
		let self.table[a:line-1][a:column-1] = a:value
	endif
endfunction

function! g:VCTable.GetCellValue(line, column) "{{{2
	let val = ''
	if a:line < len(self.table) + 1 && a:column < self.columns
		let val = self.table[a:line-1][a:column-1]
	endif
	return val
endfunction

function! g:VCTable.GetSelectedLine() "{{{2
	let line = []
	if self.selection > 0
		let line = self.GetLine(self.selection)
	endif
	return line
endfunction

function! g:VCTable.GetLine(lineIndex) "{{{2
	let line = []
	if a:lineIndex < 0
		let line = self.table[a:lineIndex]
	elseif a:lineIndex < len(self.table) + 1
		let line = self.table[a:lineIndex-1]
	endif
	return line
endfunction

function! g:VCTable.GetColumn(columnIndex) "{{{2
	if a:columnIndex >= self.columns + 1
		return []
	endif

	let col = []
	if a:columnIndex < 0
		let colIndex = a:columnIndex
	elseif a:columnIndex < self.columns + 1
		let colIndex = a:columnIndex - 1
	endif

	for i in self.table
		call add(col, i[colIndex])
	endfor
	return col
endfunction

function! g:VCTable.InsertLine(lineIndex, line) "{{{2
	"插入行数据到指定的行的前面，索引可比行数大 1 
	if a:lineIndex >= len(self.table) + 1 + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1 + 1
		let index = a:lineIndex - 1
	endif

	call insert(self.table, a:line, index)
endfunction

function! g:VCTable.AddLine(line) "{{{2
	call add(self.table, a:line[:self.columns-1]) "包含最后的，与 python 行为不同
endfunction

function! g:VCTable.UpdateLine(lineIndex, line) "{{{2
	if a:lineIndex >= len(self.table) + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1
		let index = a:lineIndex - 1
	endif

	let self.table[index] = a:line
endfunction

function! g:VCTable.DeleteLine(lineIndex) "{{{2
	if a:lineIndex >= len(self.table) + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1
		let index = a:lineIndex - 1
	endif

	call remove(self.table, index)
endfunction

function! g:VCTable.DeleteAllLines() "{{{2
	call filter(self.table, 0)
	call self.SetSelection(0)
endfunction

function! g:VCTable.TransposeLines(lineIndex1, lineIndex2) "{{{2
	let line1 = self.GetLine(a:lineIndex1)
	let line2 = self.GetLine(a:lineIndex2)

	"暂不做合法性检查，应该有外层检查
"	if line1 != [] && line2 != []
	if 1
		call self.UpdateLine(a:lineIndex1, line2)
		call self.UpdateLine(a:lineIndex2, line1)
	endif
endfunction

"Function: g:VCTable.RefreshValueFromBindVar() 从绑定的变量刷新控件值 {{{2
function! g:VCTable.RefreshValueFromBindVar()
	let self.choice = 0
	call call(g:VCSingleText.RefreshValueFromBindVar, [], self)
endfunction

function! g:VCTable.GetDispText() "{{{2
	"不允许回绕，而且，显示不全时，强行截断
	"列宽至少为1，不能为0
	let s = ''

	let off = 0 "表格第一行与空间起始行的偏移行数

	let indent = 2
	if self.indent > indent
		let indent = self.indent
	endif

	"显示标签
	if self.label != ''
		let s = s . self.label . "\n"
		let off += 1
	endif

	"显示操作按钮
	if self.dispButtons
		let disableBorder = '@'
		let buttonLabels = ['Add... ', 'Remove ', 'Edit...', 
					\'  Up   ', ' Down  ', 'Clr All']
		let tmpIdx = 0
		let tmpLen = len(buttonLabels)
		while tmpIdx < tmpLen
			if self.btnEnabledFlag[tmpIdx]
				let buttonLabels[tmpIdx] = '['.buttonLabels[tmpIdx].']'
			else
				let buttonLabels[tmpIdx] = disableBorder 
							\. buttonLabels[tmpIdx] . disableBorder
			endif
			let tmpIdx += 1
		endwhile
		let s .= join(buttonLabels, ' ') . "\n"
		"let s = s . "[Add... ] [Remove ] [Edit...] " 
					"\. "[  Up   ] [ Down  ] [Clr All]\n"
		let off += 1
	endif

	let tblCtlLen = s:VC_MAXLINELEN - indent

	let s = s . '+' . repeat('-', tblCtlLen - 2) . '+' . "\n"
	let off += 1

	let avrWidth = (tblCtlLen - self.columns - 1) / self.columns
	let colWidths = repeat([avrWidth], self.columns)
	"余数算进最后列的宽度
	let colWidths[-1] = (tblCtlLen - self.columns - 1) 
				\- avrWidth * (self.columns - 1)

	"根据类型调整宽度
	for index in range(self.columns)
		if self.header[index].type == self.CT_CHECK
			if index + 1 < self.columns 
						\&& self.header[index + 1].type != self.CT_CHECK
				let colWidths[index + 1] += colWidths[index] - 3
				let colWidths[index] = 3
			elseif index - 1 > 0 
						\&& self.header[index - 1].type != self.CT_CHECK
				let colWidths[index - 1] += colWidths[index] - 3
				let colWidths[index] = 3
			else
				"不变
			endif
		endif
	endfor

	"TODO: 需要一个成员
	let self.colWidths = colWidths

	"添加页眉
	if self.dispHeader
		let s = s . '|'

		let colContents = []
		let index = 0
		while index < self.columns
			if strdisplaywidth(self.header[index].title) <= colWidths[index]
				let content = self.header[index].title . repeat(' ', 
							\colWidths[index] 
							\- strdisplaywidth(self.header[index].title))
			else
				let content = strpart(self.header[index].title, 0, 
							\colWidths[index] - 1) . '@'
			endif
			call add(colContents, content)
			let index += 1
		endwhile

		for i in colContents
			let s = s . i . '|'
		endfor
		let s = s . "\n"
		let off += 1

		let index = 0
		let s = s . '|'
		while index < self.columns
			let l:tmp = '+'
			if index == self.columns - 1
				let l:tmp = '|'
			endif
			let s = s . repeat('-', colWidths[index]) . l:tmp
			let index += 1
		endwhile
		let s = s . "\n"
		let off += 1
	endif

	"显示表格内容
	for line in self.table
		"显示每行
		let s = s . '|'

		let colContents = []
		let index = 0
		while index < self.columns
			"显示一行的每个单元格
			if self.header[index].type == self.CT_CHECK
				"单元格类型为 CT_CHECK，并且标准化该单元格的变量以防意外
				if index < len(line) && line[index] != 0
					let content = '[X]'
					let line[index] = 1
				else
					let content = '[ ]'
					let line[index] = 0
				endif
			else
				if index >= len(line)
					"列内容为空
					let content = repeat(' ', colWidths[index])
					"填充空内容，以便索引
					call add(line, '')
				elseif strdisplaywidth(line[index]) <= colWidths[index]
					"空间足够显示
					let content = line[index] . repeat(' ', 
								\colWidths[index] - strdisplaywidth(line[index]))
				else
					"空间不足显示
					let content = strpart(line[index], 0, 
								\colWidths[index] - 1) . '@'
				endif
			endif
			call add(colContents, content)
			let index += 1
		endwhile

		for i in colContents
			let s = s . i . '|'
		endfor

		let s = s . "\n"
	endfor

	let s = s . '+' . repeat('-', tblCtlLen - 2) . '+'

	"添加缩进
"	let s = join(map(split(s, "\n"), 'repeat(" ", indent) . v:val'), "\n")

	let texts = split(s, "\n")
	"选择的行在 texts 中的索引
	let selLineIndex = (off - 1 + self.selection)

	for index in range(len(texts))
		let pad = repeat(' ', indent)
		if index == selLineIndex && self.selection
			"到达了选择的索引，且确有选择某行，添加选择标志
			let pad = repeat(' ', indent - 2) . '>>'
		endif
		let texts[index] = pad . texts[index]
	endfor

	let s = join(texts, "\n")

	return s
endfunction

function! g:VCTable.SetupHighlight() "{{{2
	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif

	"if self.dispButtons
		"let m = matchadd('StatusLine', '\V[\s\zs\.\{-1,}\ze\s]', -20)
		"call add(self.matchIds, m)
	"endif

	"let m = matchadd('SpecialKey', '\V@\ze|')
	"call add(self.matchIds, m)

	let indent = self.indent > 2 ? self.indent : 2
	if self.label != ''
		let hiGroup = 'VCLabel_' . self.hiGroup
		exec 'syn match ' . hiGroup . ' ''' . '^\V' 
					\. repeat(' ', indent) . self.label. ''''
		exec 'hi link ' . hiGroup . ' ' . self.hiGroup
	endif
endfunction

function! g:VCTable.DisableButton(btnId) "{{{2
	let self.btnEnabledFlag[a:btnId] = 0
endfunction

function! g:VCTable.EnableButton(btnId) "{{{2
	let self.btnEnabledFlag[a:btnId] = 1
endfunction

function! g:VCTable.Action(...) "可选参数指示是否 clear 操作 {{{2
	let l:ret = 0

	"是否 ClearAction
	let bIsClearAction = 0
	if a:0 > 0
		if a:1 ==? 'clear'
			let bIsClearAction = 1
		endif
	endif

	let curLn = line('.')
	let curCn = virtcol('.')

	let indent = self.indent > 2 ? self.indent : 2
	if self.label != ''
		let matchStr = '^\V' . repeat(' ', indent) . self.label
	else
		if self.dispButtons
			"let matchStr = '^\V' . repeat(' ', indent) . '[Add... ]'
			let matchStr = '^\V' . repeat(' ', indent) . '\[^+|]Add... '
		else
			"FIXME: 若在最后一行，off 为 0
			let matchStr = '^\V' . repeat(' ', indent) . '+-\+'
		endif
	endif

	let sLn = curLn

	for i in range(0, curLn)
		let line = getline(curLn - i)
		if match(line, matchStr) != -1
			let sLn = curLn - i
			break
		endif
	endfor
"	echo sLn

	let off = curLn - sLn

	let isInBtnLine = 0
	if self.dispButtons
		if self.label != '' && off == 1
			let isInBtnLine = 1
		elseif self.label == '' && off == 0
			let isInBtnLine = 1
		else
			let isInBtnLine = 0
		endif
		"echo isInBtnLine
	endif

	"可能点击了按钮，处理之
	if isInBtnLine
		let l:ret = self._ButtonAction()
	endif

"	echo off

	"若不显示按钮行，修正 off
	if !self.dispButtons && off > 0
		let off += 1
	endif

	"获取所在的表格行数，0 表示不在表格数据中，大于 0 则表示在索引中（从 1 开始）
	if self.dispHeader
		if self.label != '' && off > 4
			let lineIndex = off - 4
		elseif self.label == '' && off > 3
			let lineIndex = off - 3
		else
			let lineIndex = 0
		endif
	else
		if self.label != '' && off > 2
			let lineIndex = off - 2
		elseif self.label == '' && off > 1
			let lineIndex = off - 1
		else
			let lineIndex = 0
		endif
	endif

	"处理最后行
	if lineIndex >= len(self.table) + 1
		let lineIndex = 0
	endif

"	echo lineIndex

	"更改选择的行，需要刷新
	if lineIndex > 0
		if self.selection != lineIndex
			let self.selection = lineIndex
			let l:ret = 1
			if has_key(self, 'selectionCallback')
				call self.selectionCallback(self, self.selectionCallbackData)
			endif
		endif

		"编辑单元格
		let realCn = curCn - indent "从 1 开始
		let cellStartCol = 2
		for index in range(self.columns)
			"查询光标所在的单元格
			let min = cellStartCol
			let max = cellStartCol + self.colWidths[index]

			if realCn < min
				break
			endif

			if realCn < max
				"echo index
				if self.header[index].type == self.CT_CHECK
					"如果点击了多选框，切换
					let tmpLine = self.GetLine(lineIndex)
					if tmpLine[index]
						let tmpLine[index] = 0
					else
						let tmpLine[index] = 1
					endif
					let l:ret = 1
				elseif self.cellEditable
					let tmpLine = self.GetLine(lineIndex)
					if bIsClearAction
						let tmpLine[index] = ''
						let l:ret = 1
					else
						echohl Question
						let input = input("Edit:\n", tmpLine[index])
						echohl None
						if input != '' && input != tmpLine[index]
							let tmpLine[index] = input
							let l:ret = 1
						endif
					endif
				endif
				break
			else
				let cellStartCol += self.colWidths[index] + 1
			endif
		endfor
	endif

	return l:ret
endfunction

function! g:VCTable.ClearValueAction() "{{{2
	return self.Action('clear')
endfunction

function! g:VCTable._ButtonAction() "{{{2
	let ret = 0

	let btnWidth = 10
	let curCn = virtcol('.')
	let indent = self.indent > 2 ? self.indent : 2

	let realCn = curCn - indent

	if realCn > 0
		"按了某个按钮，处理之
		let btnIndex = (realCn - 1) / btnWidth

		if realCn % btnWidth == 0
			"刚好在按钮之间的空隙，忽略
			return 0
		endif

		if btnIndex >= len(self.btnEnabledFlag) 
					\|| !self.btnEnabledFlag[btnIndex]
			"索引越界或者禁用了此 button，则什么都不做
			return 0
		endif

		if btnIndex >= 1 && btnIndex <= 4 && !self.selection
			"中间四个按钮必须要选择了才能生效
			return 0
		endif

		"动作已经被拦截
		if has_key(self, 'btnCallbacks') 
					\&& type(self.btnCallbacks[btnIndex]) == type(function('tr'))
			call self.btnCallbacks[btnIndex](self, self.btnCbData[btnIndex])
			return 1
		endif

		if btnIndex == 0
"			echo 'Add'
			let input = input("Add:\n", '[]')
			if input != '' && type(eval(input)) == type([])
				call self.AddLine(eval(input))
				let ret = 1
			endif
		elseif btnIndex == 1
"			echo 'remove'
			if self.selection
				call self.DeleteLine(self.selection)
				if self.selection >= len(self.table) + 1
					let self.selection = 0
				endif
				let ret = 1
			endif
		elseif btnIndex == 2
"			echo 'edit'
			if self.selection
				let line = self.GetLine(self.selection)
				let result = input("Edit:\n", string(line))
				if result != '' && type(eval(result)) == type([])
					call self.UpdateLine(self.selection, eval(result))
					let ret = 1
				endif
			endif
		elseif btnIndex == 3
"			echo 'up'
			if self.selection > 1
				call self.TransposeLines(self.selection, self.selection - 1)
				let self.selection -= 1
				let ret = 1
			endif
		elseif btnIndex == 4
"			echo 'down'
			if self.selection && self.selection < len(self.table) + 1 - 1
				call self.TransposeLines(self.selection, self.selection + 1)
				let self.selection += 1
				let ret = 1
			endif
		elseif btnIndex == 5
"			echo 'clr all'
			call self.DeleteAllLines()
			let self.selection = 0
			let ret = 1
		else
"			echo 'over'
		endif
	endif

	return ret
endfunction

function! g:VCTable.ConnectBtnCallback(btnId, func, data) "{{{2
	if !has_key(self, 'btnCallbacks')
		let self.btnCallbacks = repeat([''], 6)
		let self.btnCbData = repeat([''], 6)
	endif

	"如果传进来的 func 参数直接是函数引用的话，直接赋值
	if type(a:func) == type(function("tr"))
		let self.btnCallbacks[a:btnId] = a:func
	else
		let self.btnCallbacks[a:btnId] = function(a:func)
	endif
	let self.btnCbData[a:btnId] = a:data
endfunction

function! g:VCTable.ConnectSelectionCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.selectionCallback = a:func
	else
		let self.selectionCallback = function(a:func)
	endif
	let self.selectionCallbackData = a:data
endfunction

"----- Test -----
function! g:TestVCTable() "{{{2
	let g:dlg = g:VimDialog.New('VCTable Test')
	let g:ctl = g:VCTable.New('VCTable', 3)
"	let g:ctl = g:VCTable.New('', 3)
	call g:ctl.SetColTitle(1, 'col1')
	call g:ctl.SetColTitle(2, 'col2')
	call g:ctl.SetColTitle(3, 'col3')
	call g:ctl.SetColTitle(4, 'col4')
	call g:ctl.AddLine(['a', 'b', 'c', 'd'])
	call g:ctl.AddLineByValues('z', 'y', 'x', 'w')
	call g:ctl.AddLineByValues('1', '2', '3')
	call g:ctl.AddLine(['10', '20', '30'])
	call g:ctl.SetCellValue(2, 2, 'X')
"	echo g:ctl.header
"	echo g:ctl.table
"	echo g:ctl.GetDispText()
"	call g:ctl.SetDispHeader(0)
	call g:dlg.AddControl(g:ctl)
	"call g:dlg.Display()
endfunction

function! g:TestVCTable2() "{{{2
	let g:dlg = g:VimDialog.New('VCTable Test')
	let g:ctl = g:VCTable.New('VCTable', 2)
"	let g:ctl = g:VCTable.New('', 3)
	call g:ctl.SetColType(1, g:ctl.CT_CHECK)
	call g:ctl.SetColTitle(1, 'col1')
	call g:ctl.SetColTitle(2, 'col2')
	call g:ctl.SetColTitle(3, 'col3')
	call g:ctl.SetColTitle(4, 'col4')
	call g:ctl.AddLine(['a', 'b', 'c', 'd'])
	call g:ctl.AddLineByValues('z', 'y', 'x', 'w')
	call g:ctl.AddLineByValues('1', '2', '3')
	call g:ctl.AddLine(['10', '20', '30'])
	call g:ctl.SetCellValue(2, 2, 'X')
"	echo g:ctl.header
"	echo g:ctl.table
"	echo g:ctl.GetDispText()
"	call g:ctl.SetDispHeader(0)
	call g:ctl.ConnectBtnCallback(0, 'TestCtlCallback', 'hello')
	call g:dlg.AddControl(g:ctl)
	call g:dlg.Display()
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"Class: VCButtonLine 按钮控件类，用于实现按钮 "{{{1
let g:VCButtonLine = {}
function! g:VCButtonLine.New(label, ...) "{{{2
	let new = copy(self)

	"继承
	let new.parent = g:VCSingleText.New(a:label)
	call extend(new, new.parent, "keep")
	"暂时删除，不然影响调试
	call remove(new, "parent")

	let new.type = g:VC_BUTTONLINE

	let new.buttons = [] "按钮列表, 按钮为一个字典 
						 "{'label': '', 'id': -1, 'enable': 1}

	return new
endfunction

function! g:VCButtonLine.AddButton(sLabel, ...) "{{{2
	let sLabel = a:sLabel
	let nID = -1
	if a:0 > 0
		let nID = a:1
	endif

	if strdisplaywidth(sLabel) < 2
		"按钮文字字符数至少要 2
		let sLabel .= repeat(' ', 2 - strdisplaywidth(sLabel))
	endif

	let button = {'label': sLabel, 'id': nID, 'enable': 1}
	call add(self.buttons, button)
endfunction

function! g:VCButtonLine.RemoveButton(nBtnIdx) "{{{2
	try
		call remove(self.buttons, a:nBtnIdx)
	catch
	endtry
endfunction

function! g:VCButtonLine.ConnectButtonCallback(nBtnIdx, func, data) "{{{2
	try
		if type(a:func) == type('')
			let self.buttons[a:nBtnIdx].callback = function(a:func)
		else
			let self.buttons[a:nBtnIdx].callback = a:func
		endif
		let self.buttons[a:nBtnIdx].callbackData = a:data
	catch
	endtry
endfunction

function! g:VCButtonLine.EnableButton(nBtnIdx) "{{{2
	try
		let self.buttons[a:nBtnIdx].enable = 1
	catch
	endtry
endfunction

function! g:VCButtonLine.DisableButton(nBtnIdx) "{{{2
	try
		let self.buttons[a:nBtnIdx].enable = 0
	catch
	endtry
endfunction

function! g:VCButtonLine.GetDispText() "{{{2
	let s = ''
	let sIndent = repeat(' ', self.indent)

	let s .= sIndent
	let bFirstEnter = 1
	for button in self.buttons
		let sL = '['
		let sR = ']'
		if !button.enable
			let sL = '@'
			let sR = '@'
		endif
		if bFirstEnter
			let bFirstEnter = 0
			let s .= sL . button.label . sR
		else
			let s .= ' ' . sL . button.label . sR
		endif
	endfor

	return s
endfunction

function! g:VCButtonLine.Action() "{{{2
	let nRet = 0

	let nCurCol = virtcol('.')
	let nIndent = self.indent

	let nRealCol = nCurCol - nIndent
	if nRealCol <= 0
		return nRet
	endif

	let idx = 0
	let bPressed = 0
	let nMin = 0
	let nMax = 0
	while idx < len(self.buttons)
		let button = self.buttons[idx]
		let nMax = nMin + strdisplaywidth('['.button.label.']')
		if nRealCol <= nMax && nRealCol > nMin
			let bPressed = 1
			break
		endif

		let nMin = nMax + 1
		let idx += 1
	endwhile

	if bPressed && self.buttons[idx].enable
		let nRet = 1
		if has_key(self.buttons[idx], 'callback')
			let nRet = self.buttons[idx].callback(
						\self, self.buttons[idx].callbackData)
		endif
	endif

	return nRet
endfunction

function! g:VCButtonLine.ClearValueAction() "{{{2
endfunction

function! g:VCButtonLine.RestoreValueAction() "{{{2
endfunction

function! g:VCButtonLine.GotoNextCtl(...) "{{{2
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	if bFirstEnter
		return 1
	else
		let lOrigPos = getpos('.')
		normal! f[
		if getpos('.') == lOrigPos
			return 0
		else
			return 1
		endif
	endif
endfunction

function! g:VCButtonLine.GotoPrevCtl(...) "{{{2
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	if bFirstEnter
		normal! $F[
		return 1
	else
		let lOrigPos = getpos('.')
		normal! F[
		if getpos('.') == lOrigPos
			return 0
		else
			return 1
		endif
	endif
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"{{{ 控件索引键值
let g:VimDialogCtlKeyBit = 2
"剔除 '\'，以免影响正则匹配
let g:VimDialogCtlKeyChars = '`1234567890-=qwertyuiop[]asdfghjkl;''zxcvbnm,./'.
			\'~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>? '
let g:VimDialogCtlKeys = split(g:VimDialogCtlKeyChars, '\zs')
"}}}

"Class: VimDialog 对话框类，显示与管理所有控件 {{{1
let g:VimDialog = {}
"Function: g:VimDialog.New(name, ...) 第二个可选参数为父对话框 {{{2
function! g:VimDialog.New(name, ...)
	let newVimDialog = copy(self)
	let newVimDialog.name = a:name
	let newVimDialog.splitSize = 30
	let newVimDialog.winPos = "left"
	let newVimDialog.controls = []
	let newVimDialog.showLineNum = 0
	let newVimDialog.highlightCurLine = 0 "默认关闭，否则影响按钮高亮
	let newVimDialog.type = g:VC_DIALOG
	let newVimDialog.data = '' "私有数据

	let newVimDialog.bufNum = -1

	"判定是否分割窗口
	let newVimDialog.splitOpen = 0

	"if exists("a:1") && type(a:1) == type([])
		"for ctl in a:1
			"call newVimDialog.AddControl(ctl)
		"endfor
	"endif

	"用于控件回调函数请求全部刷新用
	let newVimDialog.requestRefreshAll = 0
	let newVimDialog.requestDeepRefreshAll = 0

	let newVimDialog.isPopup = 0
	let newVimDialog.lockParent = 0 "打开子窗口时是否锁定父窗口
	let newVimDialog.lock = 0 "若非零，所有动作被禁用
	let newVimDialog.parentDlg = {} "父窗口实例
	let newVimDialog.childDlgs = [] "子窗口实例列表

	let newVimDialog.disableApply = 0

	"若为 1，则窗口为一个可编辑的普通文本，用于实现文本控件
	"这会忽略所有本窗口包含的其他控件
	let newVimDialog.asTextCtrl = 0
	let newVimDialog.textContent = ''

	if exists('a:1') && type(a:1) == type({}) && !empty(a:1)
		let newVimDialog.parentDlg = a:1
		let newVimDialog.isPopup = 1
		let newVimDialog.lockParent = 1
		call newVimDialog.parentDlg.AddChildDialog(newVimDialog)
	endif

	let newVimDialog.isModified = 0 "是否已修改设置. 采用近似算法

	"用于自动命令和键绑定等的使用
	let i = 0
	while 1
		let l:ins = 'g:VimDialogInstance_' . i
		if !exists(l:ins)
			let {l:ins} = newVimDialog
			let newVimDialog.interInsName = l:ins
			break
		endif
		let i += 1
	endwhile

	let newVimDialog.extraHelpContent = '' "额外的帮助信息内容
	let newVimDialog._showExtraHelp = 0 "显示额外帮助信息的标志，用于切换

	"索引控件对象用
	let newVimDialog.ctlKeys = []

	"键值为 ctlKey，的字典，保存非激活的控件的matchId
	let newVimDialog._inactiveCtlMatchId = {}

	return newVimDialog
endfunction

function! g:VimDialog.SetData(data) "{{{2
	unlet self.data
	let self.data = a:data
endfunction

function! g:VimDialog.GetData() "{{{2
	return self.data
endfunction

function! g:VimDialog.DisableApply() "{{{2
	let self.disableApply = 1
endfunction

function! g:VimDialog.AddChildDialog(child) "添加子对话框 {{{2
	call add(self.childDlgs, a:child)
endfunction

function! g:VimDialog.RemoveChildDialog(child) "删除子对话框 {{{2
	for i in range(len(self.childDlgs))
		if self.childDlgs[i] is a:child
			call remove(self.childDlgs, i)
		endif
	endfor
endfunction

function! g:VimDialog.SetSplitOpen(yesOrNo) "{{{2
	let self.splitOpen = a:yesOrNo
endfunction

function! g:VimDialog.SetIsPopup(yesOrNo) "{{{2
	let self.isPopup = a:yesOrNo
endfunction

function! g:VimDialog.SetAsTextCtrl(yesOrNo) "{{{2
	let self.asTextCtrl = a:yesOrNo
endfunction

function! g:VimDialog.SetTextContent(text) "{{{2
	let self.textContent = a:text
endfunction

function! g:VimDialog.SetExtraHelpContent(text) "{{{2
	let self.extraHelpContent = a:text
endfunction

function! g:VimDialog.SetModified(yesOrNo) "{{{2
	let self.isModified = a:yesOrNo
endfunction

function! g:VimDialog.IsModified() "{{{2
	return self.isModified
endfunction

function! g:VimDialog._GetAKey() "{{{2
	if empty(self.ctlKeys)
		let self._ctlIdIndex = 0
		let self._ctlIdCount = 1
		let self._ctlIdCountPerGroup = len(g:VimDialogCtlKeys)
		let self._key2Id = {}
		let i = 0
		while i < g:VimDialogCtlKeyBit
			call add(self.ctlKeys, copy(g:VimDialogCtlKeys))
			let self._ctlIdCount = self._ctlIdCount * self._ctlIdCountPerGroup
			let i += 1
		endwhile
	endif

	if self._ctlIdIndex >= self._ctlIdCount
		throw "Too more controls"
	else
		"先简单实现...
		if g:VimDialogCtlKeyBit == 2
			let index0 = self._ctlIdIndex / self._ctlIdCountPerGroup
			let index1 = self._ctlIdIndex % self._ctlIdCountPerGroup
			let key = self.ctlKeys[0][index0] . self.ctlKeys[1][index1]
			let self._key2Id[key] = self._ctlIdIndex
			let self._ctlIdIndex += 1
			return key
		endif
	endif
endfunction

function! g:VimDialog._GetCtlKeyByLnum(lnum)
	let l:line = getline(a:lnum)
	return l:line[len(l:line) - g:VimDialogCtlKeyBit : ]
endfunction

"创建用于显示窗口
function! g:VimDialog._CreateWin() "{{{2
    "create the dialog window
    let splitLocation = self.winPos ==# "left" ? "topleft " : "botright "
    let splitSize = self.splitSize

	"用于关闭时返回原来的窗口
	let self.origWinNum = winnr()
	"用于关闭时返回，当窗口编号已改变时用
	let self.origBufNum = bufnr('%')

    if !has_key(self, "bufName")
		"第一次调用本实例的显示函数

        let self.bufName = self.name
		"NOTE: 处理空格。凡是用于命令行的，都要注意空格！
		let l:bufName = substitute(self.bufName, ' ', '\\ ', "g")
		let winNum = g:GetFirstUsableWindow()

		"先跳至将要编辑的窗口
		if self.isPopup
			"Popup 类型的窗口为无名缓冲
			exec (winheight(0)-2).'new'
		elseif self.splitOpen
			let maxWidthWinNr = g:GetMaxWidthWinNr()
			call g:Exec(maxWidthWinNr . ' wincmd w')
			new
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		elseif winNum == -1 || (winnr('$') == 1 && winNum == -1)
			if bufwinnr(self.bufName) != -1
				"存在与要创建的缓冲同名的缓冲, 跳至那个缓冲然后结束
				call g:Exec(bufwinnr(self.bufName) . ' wincmd w')
				return 1
			endif

			let maxWidthWinNr = g:GetMaxWidthWinNr()
			call g:Exec(maxWidthWinNr . ' wincmd w')
			new
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		else
			"替换缓冲区
			if bufwinnr(self.bufName) != -1
				"存在与要创建的缓冲同名的缓冲, 跳至那个缓冲然后结束
				call g:Exec(bufwinnr(self.bufName) . ' wincmd w')
				return 1
			endif

			"NOTE: 当仅有一个无名缓冲区时，会把无名缓冲区完全替换掉
			call g:Exec(winNum . ' wincmd w')
			let self.rpmBufNum = bufnr('%')		"用于关闭时切换回来
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		endif
    else
		"重复调用本实例显示函数

		if bufwinnr(self.bufNum) != -1
			"已在某窗口打开着，直接跳至窗口
			call s:exec(bufwinnr(self.bufNum) . " wincmd w")
			return
		else
			"已在 buffer 列表中，但是没有打开，则切换
			let l:bufName = substitute(self.bufName, ' ', '\\ ', "g")
			let winNum = g:GetFirstUsableWindow()
			if self.splitOpen || winNum == -1 
						\|| (winnr('$') == 1 && winNum == -1)
				silent! exec 'sbuffer ' . l:bufName
			else
				call g:Exec(winNum . ' wincmd w')
				let self.rpmBufNum = bufnr('%')		"用于关闭时切换回来
				silent! exec "buffer " . l:bufName
			endif
		endif
    endif

    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell

	setlocal bufhidden=wipe "关闭窗口后直接删除缓冲
	"关闭窗口后自删
	exec 'autocmd BufWinLeave <buffer> call '.self.interInsName.'._ForceQuit()'
	"if self.isPopup
		"setlocal bufhidden=wipe "关闭窗口后直接删除缓冲
		""关闭窗口后自删
		"exec 'autocmd BufWinLeave <buffer> call '.self.interInsName.'.Delete()'
	"else
		"setlocal bufhidden=hide
	"endif
    if self.showLineNum
        setlocal nu
    else
        setlocal nonu
    endif

    "删除所有插入模式的缩写
    iabc <buffer>

	"高亮光标所在行
	if self.highlightCurLine
		setlocal cursorline
	else
		setlocal nocursorline
	endif

    "设置状态栏
	call self._RefreshStatusLine()

    "设置键盘映射
	call self.SetupKeyMappings()

    setfiletype vimdialog

	let self.bufNum = bufnr('%')
endfunction

function! g:VimDialog._RefreshStatusLine() "{{{2
	let modFlag = ''
	if self.isModified
		let modFlag = '\ [+]'
	endif

    "设置状态栏
    exec "setlocal statusline=" . substitute(self.bufName, ' ', '\\ ', "g") 
				\. modFlag

	if self.asTextCtrl
		let statusStr = getwinvar(winnr(), '&statusline') 
					\. ' - ' .g:VimDialogSaveAndQuitKey. ':Save and Quit; '
					\. g:VimDialogQuitKey . ':Quit without Save'
		call setwinvar(winnr(), '&statusline', statusStr)
	endif
endfunction

function! g:VimDialog.GetControlByID(nID) "从 ID 获取控件 {{{2
	for ctl in self.controls
		if ctl.GetId() == a:nID
			return ctl
		endif
	endfor

	return {}
endfunction

"Function: g:VimDialog.GetControlByLnum(lnum) 从行号直接获取控件对象 {{{2
function! g:VimDialog.GetControlByLnum(lnum)
	let l:key = self._GetCtlKeyByLnum(a:lnum)
	if has_key(self.controlsDict, l:key)
		return self.controlsDict[l:key]
	else
		return {}
	endif
endfunction

"添加控件到对话框，对于这个简单的对话实现，显示的顺序就是添加的顺序
"Function: g:VimDialog.AddControl(control) {{{2
function! g:VimDialog.AddControl(control)
	let a:control.owner = self
	call add(self.controls, a:control)
endfunction

"Function: g:VimDialog.Display() 显示全部控件，可重入 {{{2
function! g:VimDialog.Display()
	if self.lockParent && !empty(self.parentDlg)
		let self.parentDlg.lock = 1
	endif

	"调用此函数后自动把光标放到对应的窗口里, 接着可直接操作当前窗口修改其内容
	if self._CreateWin()
		"跳到了复用的窗口, 直接结束
		call self.Delete()
		return
	endif

	setlocal ma
	exec "silent 1," . line("$") . " delete _"

	let bak = @a
	let @a = ""
	
	" 为了可重入
	let self.ctlKeys = []

	if self.asTextCtrl
		if self.textContent != ''
			let @a .= self.textContent
			silent! put! a
			if self.textContent[-1:-1] !=# "\n"
				"处理多出来的空行, 只有当字符串最后的字符为非换行时才需要
				exec "silent " . line("$") . "," . line("$") . " delete _"
			endif
		endif

		normal! G
		setlocal ma
	else
		"设置语法高亮
		if has("syntax") && exists("g:syntax_on")
			call self.SetupSyntaxHighlight()
		endif

		let self.controlsDict = {}
		for i in self.controls
			if i.IsEditable()
				let l:key = self._GetAKey()
				let self.controlsDict[l:key] = i
			else
				let l:key = repeat(' ', g:VimDialogCtlKeyBit)
			endif
			let l:s = substitute(i.GetDispText(), "\n", l:key . "\n", "g")
			let @a = @a . l:s . l:key . "\n"

			call self._HandleCtlActivated(i, l:key)
		endfor

		silent! put a
		silent 1,1delete _

		call self.DisplayHelp()

		setlocal noma
	endif

	let @a = bak
endfunction

function! g:VimDialog.Refresh() "刷新显示 {{{2
	call self.Display()
endfunction

function! g:VimDialog.RefreshAll() "此函数只支持从回调函数中调用 {{{2
	let self.requestRefreshAll = 1
endfunction

function! g:VimDialog._RefreshAll() "{{{2
	call self.Display()
endfunction

function! g:VimDialog.DeepRefreshAll(...) "{{{2
	let self.requestDeepRefreshAll = 1
endfunction

function! g:VimDialog._DeepRefreshAll() "{{{2
	for i in self.controls
		if has_key(i, "RefreshValueFromBindVar")
			call i.RefreshValueFromBindVar()
		endif
	endfor

	call self.Display()
endfunction

function! g:VimDialog.DisplayHelp() "{{{2
	let l:winnr = bufwinnr(self.bufNum)
	if l:winnr != -1
        call s:exec(l:winnr . " wincmd w")
		let texts = []

		let text = '"'
		let text = text . g:VimDialogActionKey . ': Change Text; '
		let text = text . g:VimDialogRestoreValueKey . ': Restore Text; '
		let text = text . g:VimDialogClearValueKey . ': Clear Text '
		call add(texts, text)

		let text = '"'
		if !self.isPopup && !self.disableApply
			let text = text . g:VimDialogSaveKey . ': Save All; '
		endif
		let text = text . g:VimDialogSaveAndQuitKey . ': Save And Quit; '
		let text = text . g:VimDialogQuitKey . ': Quit Without Save '
		call add(texts, text)

		let text = '"'
		let text .= g:VimDialogToggleExtraHelpKey . ': Toggle Extra Help; '
		if !self.asTextCtrl
			let text .= g:VimDialogNextEditableCtlKey . ': Goto Next Control; '
			let text .= g:VimDialogPrevEditableCtlKey . ': Goto Prev Control '
		endif
		call add(texts, text)

		call add(texts, '')

		setlocal ma
		call append(0, texts)
		setlocal noma

		"设置语法高亮
		if has("syntax") && exists("g:syntax_on")
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogActionKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogRestoreValueKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogClearValueKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogSaveKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogSaveAndQuitKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogQuitKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogToggleExtraHelpKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogNextEditableCtlKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogPrevEditableCtlKey . "\\ze:'"
			hi def link VimDialogHotKey Identifier
			syn match Comment '\v^".*$' contains=VimDialogHotKey
		endif
	endif
endfunction
"}}}
function! g:VimDialog.Action(...) "响应动作 {{{2
	if self.lock
		return
	endif

	let sType = 'action'
	if a:0 > 0
		let sType = a:1
	endif

	let nLn = line('.')
	let ctl = self.GetControlByLnum(nLn)
	if len(ctl) != 0 && has_key(ctl, "Action") && ctl.activated
		let bSkipAction = 0
		if has_key(ctl, 'HandleActionCallback') && ctl.HandleActionCallback()
			let bSkipAction = 1
		endif
		if !bSkipAction
			if sType ==? 'restore'
				let nRet = ctl.RestoreValueAction()
			elseif sType ==? 'clear'
				let nRet = ctl.ClearValueAction()
			else
				let nRet = ctl.Action()
			endif
			if nRet
				if has_key(ctl, 'HandleActionPostCallback')
					call ctl.HandleActionPostCallback()
				endif

				"支持在控件的 Action 中删除窗口
				if !empty(self)
					call self.RefreshCtlByLnum(nLn)
					"let self.isModified = 1
					"call self._RefreshStatusLine()
				endif
			endif
		endif
	endif

	if !empty(self)
		let save_cursor = getpos(".") "用于恢复光标位置
		if self.requestDeepRefreshAll
			let self.isModified = 0
			let self.requestDeepRefreshAll = 0
			call self._DeepRefreshAll()
		elseif self.requestRefreshAll
			let self.requestRefreshAll = 0
			call self._RefreshAll()
		endif
		call setpos('.', save_cursor) "恢复光标位置
	endif
endfunction

function! g:VimDialog.RestoreCtlValue() "{{{2
	call self.Action('restore')
endfunction

function! g:VimDialog.ClearCtlValue() "{{{2
	call self.Action('clear')
endfunction

function! g:VimDialog.RefreshCtl(ctl) "刷新指定实例 {{{2
	for ctl in self.controls
		if ctl is a:ctl
			let bak = ctl.id
			let ctl.id = -10000
			call self.RefreshCtlById(-10000)
			let ctl.id = bak
		endif
	endfor
endfunction

function! g:VimDialog.RefreshCtlById(id) "{{{2
	let l:winnr = bufwinnr(self.bufNum)
	let l:origWin = winnr()
    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec(l:winnr . " wincmd w")
    endif

	for i in range(1, line('$') + 1)
		let ctl = self.GetControlByLnum(i)
		if ctl != {} && ctl.GetId() == a:id
			call self.RefreshCtlByLnum(i)
			break
		endif
	endfor

    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec("wincmd p")
    endif
endfunction

function! g:VimDialog.RefreshCtlByGId(gId) "{{{2
	for ctl in self.controls
		if ctl.GetGId() == a:gId
			call self.RefreshCtl(ctl)
		endif
	endfor
endfunction

"刷新控件显示
"Function: g:VimDialog.RefreshCtlByLnum(lnum) {{{2
function! g:VimDialog.RefreshCtlByLnum(lnum)
	let l:winnr = bufwinnr(self.bufNum)
	let l:origWin = winnr()
    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec(l:winnr . " wincmd w")
    endif

	let save_cursor = getpos(".") "用于恢复光标位置

	if a:lnum == '.'
		let nLn = line('.')
	else
		let nLn = a:lnum
	endif
	let l:ctlKey = self._GetCtlKeyByLnum(nLn)
	if l:ctlKey == ''
		return
	endif
"	echo l:ctlKey

	let l:ctlSln = nLn
	let l:ctlEln = nLn
	for i in range(1, nLn)
		let l:curKey = self._GetCtlKeyByLnum(nLn - i)
"		echo l:curKey
		if l:curKey != ctlKey
			break
		endif
		let l:ctlSln = nLn - i
	endfor
	for i in range(nLn + 1, line('$'))
		let l:curKey = self._GetCtlKeyByLnum(i)
"		echo l:curKey
		if l:curKey != ctlKey
			break
		endif
		let l:ctlEln = i
	endfor
"	echo l:ctlSln
"	echo l:ctlEln

	setlocal ma
	" 刷新控件显示
	let ctl = self.GetControlByLnum(nLn)
	if ctl == {}
		return
	endif
	let l:text = ctl.GetDispText()
	let l:texts = split(l:text, "\n")
	call map(l:texts, 'v:val . l:ctlKey')

	" 保持最小的增删行，防止画面晃动
	let l:dispLc = l:ctlEln - l:ctlSln + 1
	if len(l:texts) > l:dispLc
		let l:dc = len(l:texts) - l:dispLc
		call append(ctlSln, range(l:dc))
	elseif len(l:texts) < l:dispLc
		let l:dc = l:dispLc - len(l:texts)
		"NOTE: 对于 delete 的范围，不能直接用表达式，必须是直接数字！
		let l:endLn = l:ctlSln + l:dc - 1
		exec "silent " . l:ctlSln . "," . l:endLn . "delete _"
	endif

	call setline(l:ctlSln, l:texts)

	"处理激活
	call self._HandleCtlActivated(ctl, ctlKey)

"	exec l:ctlSln . "," . l:ctlEln . "delete _"
"	let bak = @a
"	let @a = l:text
"	silent! put! a
"	let @a = bak
	setlocal noma

	"恢复光标位置
	call setpos('.', save_cursor)

    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec("wincmd p")
    endif
endfunction

function! g:VimDialog._HandleCtlActivated(ctl, ctlKey) "处理控件激活显示 {{{2
	if !a:ctl.activated
		if has_key(self._inactiveCtlMatchId, a:ctlKey)
			exec 'syn clear ' . self._inactiveCtlMatchId[a:ctlKey]

			"call matchdelete(self._inactiveCtlMatchId[a:ctlKey])
			"call remove(self._inactiveCtlMatchId, a:ctlKey)
		endif
		let groupName = 'InActive_' . self._key2Id[a:ctlKey]
		let texts = split(a:ctl.GetDispText(), '\n')
		for text in texts
			"NOTE: 在正则表达式中 ' 是用 \ 来转义的
			let text = escape(text, "'")
			exec "syn match " . groupName . ' ''\V'.text.'\ze'.a:ctlKey.'\$'''
		endfor
		exec 'hi link ' . groupName . ' Ignore'
		let self._inactiveCtlMatchId[a:ctlKey] = groupName

		"let matchId = matchadd('Ignore', '\V\.\+\ze'.a:ctlKey.'\$', -19)
		"let self._inactiveCtlMatchId[a:ctlKey] = matchId
	else
		if has_key(self._inactiveCtlMatchId, a:ctlKey)
			exec 'syn clear ' . self._inactiveCtlMatchId[a:ctlKey]

			"call matchdelete(self._inactiveCtlMatchId[a:ctlKey])
			"call remove(self._inactiveCtlMatchId, a:ctlKey)
		endif
	endif
endfunction

function! g:VimDialog._ClearCtlActivatedHl()
	for k in keys(self._inactiveCtlMatchId)
		exec 'syn clear ' . self._inactiveCtlMatchId[k]
	endfor
	call filter(self._inactiveCtlMatchId, 0)
endfunction

function! g:VimDialog.AddSeparator()
	call self.AddControl(g:VCSeparator.New())
endfunction

function! g:VimDialog.AddBlankLine()
	call self.AddControl(g:VCBlankLine.New())
endfunction

"Function: g:VimDialog.SetupKeyMappings() 设置默认键盘映射 {{{2
function! g:VimDialog.SetupKeyMappings()
	let l:ins = self.interInsName

	"开始设置映射
	if !self.asTextCtrl
		exec "nnoremap <silent> <buffer> " . g:VimDialogActionKey . 
					\" :call ".l:ins.".Action()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogRestoreValueKey . 
					\" :call ".l:ins.".RestoreCtlValue()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogClearValueKey . 
					\" :call ".l:ins.".ClearCtlValue()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogNextEditableCtlKey . 
					\" :call ".l:ins.".GotoNextEdiableCtl()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogPrevEditableCtlKey . 
					\" :call ".l:ins.".GotoPrevEdiableCtl()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogToggleExtraHelpKey . 
					\" :call ".l:ins.".ToggleExtraHelp()<Cr>"
	endif

	if !self.isPopup && !self.disableApply
		exec "nnoremap <silent> <buffer> " . g:VimDialogSaveKey . 
					\" :call ".l:ins.".Save()<Cr>"
	endif

	exec "nnoremap <silent> <buffer> " . g:VimDialogSaveAndQuitKey . 
				\" :call ".l:ins.".SaveAndQuit()<Cr>"
	exec "nnoremap <silent> <buffer> " . g:VimDialogQuitKey . 
				\" :call ".l:ins.".ConfirmQuit()<Cr>"

	if !self.asTextCtrl
		"鼠标
		exec "nnoremap <silent> <buffer> " . "<2-LeftMouse>" . 
					\" :call ".l:ins.".Action()<Cr>"
	endif
endfunction

function! g:VimDialog.Close() "{{{2
    "let bak = &ei
    "set eventignore+=BufWinLeave "暂时屏蔽自删动作的自动命令
	let l:winnr = bufwinnr(self.bufNum)
    if l:winnr != -1
		call s:exec(l:winnr . " wincmd w")
		if has_key(self, 'rpmBufNum')
			"若替换的是无名缓冲区，这个没有效果
			exec 'buffer ' . self.rpmBufNum
		else
			"用的是分割出来的窗口
			silent! close
		endif
		if bufexists(self.bufNum)
			"当是替换模式，且替换了无名缓冲区，那么切换的时候无效果，需手动删除
			exec 'bwipeout ' . self.bufNum
		endif
		call s:exec(self.origWinNum . " wincmd w")
    endif
    "let &ei = bak
endfunction

function! g:VimDialog.Save() "{{{2
	if self.lock
		return
	endif

	for i in self.controls
		if has_key(i, "UpdateBindVar")
			call i.UpdateBindVar()
		endif
	endfor

	if has_key(self, 'saveCallback')
		call self.saveCallback(self, self.saveCallbackData)
	endif

	echohl PreProc
	if exists("*strftime")
		echo "All have been saved at "
		echohl Special
		echon strftime("%c")
	else
		echo "All have been saved."
	endif
	echohl None
endfunction

function! g:VimDialog.Delete() "{{{2
	if self.lock
		return
	endif

	unlet {self.interInsName}
	call filter(self, 0)
endfunction

function! g:VimDialog.SaveAndQuit() "{{{2
	if self.lock
		return
	endif

	call self.Save()
	if has_key(self, "callback") "DEPRECATE!
		let l:ret = self.callback(self)
		if l:ret
			"echoerr "callback error"
			return
		endif
	endif
	call self.Quit()
endfunction

function! g:VimDialog.Quit() "{{{2
	if self.lock
		return
	endif

	"删除自删的自动命令, 因为已经不需要了, 这个函数肯定能删除
	autocmd! BufWinLeave <buffer>

	if self.lockParent && !empty(self.parentDlg)
		let self.parentDlg.lock = 0
	endif

	if has_key(self, 'preCallback')
		call self.preCallback(self, self.preCallbackData)
	endif

	for dlg in self.childDlgs
		call dlg.Quit()
	endfor
	if !empty(self.parentDlg)
		call self.parentDlg.RemoveChildDialog(self)
	endif
	call self.Close()

	if has_key(self, 'postCallback')
		call self.postCallback(self, self.postCallbackData)
	endif

	call self.Delete()
endfunction

function! g:VimDialog._ForceQuit() "{{{2
	let self.lock = 0
	call self.Quit()
endfunction

function! g:VimDialog.ConfirmQuit() "{{{2
	if self.lock
		return
	endif

	if self.IsModified() || self.asTextCtrl
		echohl WarningMsg
		let ret = input("Are you sure to quit without save? (y/n): ", 'y')
		if ret ==? 'y'
			call self.Quit()
		endif
		echohl None
	else
		call self.Quit()
	endif
endfunction

"回调函数必须返回 0 以示成功，否则始终不会关闭窗口
"现在这个回调函数只在 SaveAndQuit 的时候调用
function! g:VimDialog.AddCallback(func) "DEPRECATE {{{2
	if type(a:func) == type(function("tr"))
		let self.callback = a:func
	else
		let self.callback = function(a:func)
	endif
endfunction

function! g:VimDialog.ConnectPreCallback(func, data) "关闭窗口前 {{{2
	if type(a:func) == type(function("tr"))
		let self.preCallback = a:func
	else
		let self.preCallback = function(a:func)
	endif
	let self.preCallbackData = a:data
endfunction

function! g:VimDialog.ConnectPostCallback(func, data) "关闭窗口后 {{{2
	if type(a:func) == type(function("tr"))
		let self.postCallback = a:func
	else
		let self.postCallback = function(a:func)
	endif
	let self.postCallbackData = a:data
endfunction

function! g:VimDialog.ConnectSaveCallback(func, data) "保存设置时 {{{2
	if type(a:func) == type(function("tr"))
		let self.saveCallback = a:func
	else
		let self.saveCallback = function(a:func)
	endif
	let self.saveCallbackData = a:data
endfunction

"Function: g:VimDialog.SetupSyntaxHighlight() 设置语法高亮 {{{2
function! g:VimDialog.SetupSyntaxHighlight()
	"只高亮最基本的框架

	"先清除
	call self._ClearCtlActivatedHl()
	syntax clear

	let sufPat = '\v.{' . g:VimDialogCtlKeyBit . '}$'

	"文本框
	syn match VCTextControl '\v\|'
	exec "syn match VCTextControl '".'\v^\s*\+\-+\+\ze'.sufPat."'"
	"表格头与内容的分割线
	exec "syn match VCTextControl '".'\v^\s*\|\-[-+]+\|\ze'.sufPat."'"

	"组合框
	exec "syn match VCComboBoxCtl '".'\v^\s*\+\-+\+\-\+\ze'.sufPat."'"

	"复选控件
	syn match VCCheckCtl '\v\[\zsX\ze\]'

	"通用按钮，按钮字符数至少是 2，为了和复选框区别
	syn match VCButton '\V[\.\{-2,}]'

	"字符串过长时的提示符号
	syn match VCExtend '\V@\ze|'

	if version >= 703
		exec "syn match VCTypeCahr '".sufPat."' conceal"
		hi def link VCTypeCahr Conceal
		set concealcursor=nvc
		set conceallevel=2
	else
		exec "syn match VCTypeCahr '".sufPat."'"
		hi def link VCTypeCahr Ignore
	endif

	hi def link VCTextControl Comment
	hi def link VCComboBoxCtl VCTextControl
	hi def link VCCheckCtl Character
	hi def link VCButton StatusLine
	hi def link VCExtend SpecialKey

	"高亮控件自身的需要的高亮
	for i in self.controls
		call i.SetupHighlight()
	endfor
endfunction

function! g:VimDialog.GotoNextEdiableCtl() "{{{2
	let origRow = line('.')
	let origCtl = self.GetControlByLnum(origRow)

	if !empty(origCtl) && origCtl.GotoNextCtl()
	"控件自身还有空控件没有跳转完毕
		return
	endif

	for row in range(origRow, line('$'))
		let ctl = self.GetControlByLnum(row)
		if !empty(ctl) && ctl isnot origCtl && ctl.IsEditable()
			exec row
			call ctl.GotoNextCtl(1)
			break
		endif
	endfor
endfunction

function! g:VimDialog.GotoPrevEdiableCtl() "{{{2
	let origRow = line('.')
	let origCtl = self.GetControlByLnum(origRow)

	if !empty(origCtl) && origCtl.GotoPrevCtl()
		return
	endif

	for row in range(origRow, 1, -1)
		let ctl = self.GetControlByLnum(row)
		if !empty(ctl) && ctl isnot origCtl && ctl.IsEditable()
			"需要定位到首行
			for row2 in range(row, 1, -1)
				let ctl2 = self.GetControlByLnum(row2)
				if ctl2 isnot ctl
					let row = row2 + 1
					break
				endif
			endfor

			exec row
			call ctl.GotoPrevCtl(1)
			break
		endif
	endfor
endfunction

function! g:VimDialog.ToggleExtraHelp() "{{{2
	if self.lock || self.extraHelpContent == ''
		return
	endif

	setlocal ma
	if self._showExtraHelp
		let self._showExtraHelp = 0
		"删除额外帮助信息
		let extraHelpLineCount = len(split(self.extraHelpContent, '\n'))
		exec 'silent! 4,'. (4 + extraHelpLineCount - 1) .'delete _'
		"恢复原始视图
		if has_key(self, '_saveView')
			call winrestview(self._saveView)
			call remove(self, '_saveView')
		endif
	else
		let self._showExtraHelp = 1
		"保存原始视图
		let self._saveView = winsaveview()
		"显示额外帮助信息
		let contentList = split(self.extraHelpContent, '\n')
		call map(contentList, '"\" " . v:val')
		call append(3, contentList)
		"定位到帮助信息开始处
		call cursor(4, 1)
	endif
	setlocal noma
endfunction
"}}}
"Apply, Cancel, OK 按钮回调函数 {{{2
function! s:_ApplyCbk(ctl, ...)
	call a:ctl.owner.Save()
endfunction
function! s:_CancelCbk(ctl, ...)
	call a:ctl.owner.Quit()
endfunction
function! s:_OKCbk(ctl, ...)
	call a:ctl.owner.SaveAndQuit()
endfunction
"}}}
function! g:VimDialog.AddFooterButtons() "{{{2
	call self.AddBlankLine()
	call self.AddSeparator()

	let ctl = g:VCButtonLine.New('')

	let lButtonLabel = ['Apply ', 'Cancel', '  OK  ']
	let nLen = 0
	for sLabel in lButtonLabel
		let nLen += strdisplaywidth(sLabel) + 2
	endfor
	if len(lButtonLabel)
		let nLen += len(lButtonLabel) - 1
	endif

	call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	call ctl.AddButton(lButtonLabel[0])
	call ctl.AddButton(lButtonLabel[1])
	call ctl.AddButton(lButtonLabel[2])
	call self.AddControl(ctl)

	call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:_ApplyCbk'), '')
	call ctl.ConnectButtonCallback(1, s:GetSFuncRef('s:_CancelCbk'), '')
	call ctl.ConnectButtonCallback(2, s:GetSFuncRef('s:_OKCbk'), '')

	if self.isPopup || self.disableApply
		call ctl.RemoveButton(0)
		call remove(lButtonLabel, 0)

		let nLen = 0
		for sLabel in lButtonLabel
			let nLen += strdisplaywidth(sLabel) + 2
		endfor
		if len(lButtonLabel)
			let nLen += len(lButtonLabel) - 1
		endif
		call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	endif
endfunction
"}}}
function! g:VimDialog.AddCloseButton() "{{{2
	call self.AddBlankLine()
	call self.AddSeparator()

	let ctl = g:VCButtonLine.New('')

	let lButtonLabel = ['Close']
	let nLen = 0
	for sLabel in lButtonLabel
		let nLen += strdisplaywidth(sLabel) + 2
	endfor
	if len(lButtonLabel)
		let nLen += len(lButtonLabel) - 1
	endif

	call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	call ctl.AddButton(lButtonLabel[0])
	call self.AddControl(ctl)
	call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:_CancelCbk'), '')
endfunction
"}}}
function! g:VimDialog.ReplacedBy(dlgIns) "用于替换，暂不可用 {{{2
	call self.Delete()
	call extend(self, a:dlgIns, 'force')
	call self.Display()
endfunction

"===============================================================================
"		测试
"===============================================================================

"Function: g:VimDialogTest() {{{2
function! g:VimDialogTest()
	let g:vimdialog = g:VimDialog.New("VimDialogTest")
	let g:str = ""

	let g:vdst = g:VCStaticText.New("vdst")
	call g:vimdialog.AddControl(g:vdst)

"	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 60))
	let g:ctl = g:VCSingleText.New("单行文本控件")
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件")
	call g:ctl.BindVariable("g:str")
	call g:ctl.SetIndent(8)
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 84))
	call g:ctl.SetActivated(0)
	call g:ctl.ConnectActionCallback('TestCtlCallback', 'Action!')
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 84))
	call g:ctl.SetIndent(4)
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCMultiText.New("多行文本控件", repeat('=', 84) . "\nA\n\nB\nC\nE\nD\nF\nG")
	call g:ctl.SetIndent(4)
	call g:ctl.ConnectButtonCallback('TestCtlCallback', 'button')
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCButtonLine.New('')
	call g:ctl.SetIndent(4)
	call g:ctl.AddButton('abc')
	call g:ctl.AddButton('xyz')
	call g:ctl.DisableButton(0)
	call g:ctl.ConnectButtonCallback(1, 'TestCtlCallback', 'ButtonLine')
	call g:vimdialog.AddControl(g:ctl)

	let ctl = g:VCButtonLine.New('')
	call ctl.SetIndent(26)
	call ctl.AddButton('Apply ')
	call ctl.AddButton('Cancel')
	call ctl.AddButton('  OK  ')
	call g:vimdialog.AddControl(ctl)

	call g:vimdialog.AddFooterButtons()

	call g:vimdialog.AddSeparator()
	call g:vimdialog.AddCallback("TestCallback")

	call g:vimdialog.SetIsPopup(1)

	"call g:vimdialog.SetAsTextCtrl(1)
	"call g:vimdialog.SetTextContent("a\nb\nc\nd\ne")
	
	call g:vimdialog.Display()
endfunction


function! g:VimDialogTest2() "{{{2
	return
	let li = []
	let g:confSrc = 'Scorce Files'
	let g:confOptions = '$(shell wx-config --cxxflags --debug=no --unicode=yes);-O2;$(shell pkg-config --cflags gtk+-2.0);-Wall;-fno-strict-aliasing'

	let g:ctl1 = g:VCSingleText.New("g:confSrc")
	let g:ctl2 = g:VCSingleText.New("Options")

	call add(li, g:ctl1)
	call add(li, g:VCSeparator.New())
"	call add(li, g:VCBlankLine.New())
	call add(li, g:ctl2)
	" NOTE: 已不支持此方法
	let g:ins = g:VimDialog.New("__VIMDIALOGTEST2__", li)

"	call g:ins.AddControl(g:ctl1)
"	call g:ins.AddSeparator()
"	call g:ins.AddControl(g:ctl2)

	call g:ctl1.BindVariable("g:confSrc")
	call g:ctl2.BindVariable("g:confOptions")

	call g:ctl1.SetSingleLineFlag(1)
	call g:ctl1.SetLabelDispWidth(20)
	call g:ctl1.SetIndent(8)
"	call g:ctl2.SetSingleLineFlag(1)
	call g:ctl2.SetLabelDispWidth(20)
	call g:ctl2.SetIndent(8)

"	py pyv = "abcdefghijklmn"
"	call g:ctl2.BindVariable("pyv", 1)

	call g:ins.Display()
endfunction


function! TestCallback(arg)
	echo "I am a callback"
	echo a:arg.name
	return 0
endfunction

function! TestCtlCallback(ctl, data)
	echo "I am a callback"
	echo a:ctl.GetValue()
	echo a:data

	return 1
endfunction

function! g:ProjectSettingsTest() "{{{2
	let g:psdialog = g:VimDialog.New("--ProjectSettings--")

	let vimliteHelp = '===== Available Macros: =====' . "\n"
	let vimliteHelp .= "$(ProjectPath)           "
				\."Expand to the project path" . "\n"

	let vimliteHelp .= "$(WorkspacePath)         "
				\."Expand to the workspace path" . "\n"

	let vimliteHelp .= "$(ProjectName)           "
				\."Expand to the project name" . "\n"

	let vimliteHelp .= "$(IntermediateDirectory) "
				\."Expand to the project intermediate directory path, " . "\n"
				\.repeat(' ', 25)."as set in the project settings" . "\n"

	let vimliteHelp .= "$(ConfigurationName)     "
				\."Expand to the current project selected configuration" . "\n"

	let vimliteHelp .= "$(OutDir)                "
				\."An alias to $(IntermediateDirectory)" . "\n"

	let vimliteHelp .= "$(CurrentFileName)       "
				\."Expand to current file name (without extension and " . "\n"
				\.repeat(' ', 25)."path)"."\n"

	let vimliteHelp .= "$(CurrentFilePath)       "
				\."Expand to current file path" . "\n"

	let vimliteHelp .= "$(CurrentFileFullPath)   "
				\."Expand to current file full path (path and full name)" . "\n"

	let vimliteHelp .= "$(User)                  "
				\."Expand to logged-in user as defined by the OS" . "\n"

	let vimliteHelp .= "$(Date)                  "
				\."Expand to current date" . "\n"

	let vimliteHelp .= "$(ProjectFiles)          "
				\."A space delimited string containing all of the " . "\n"
				\.repeat(' ', 25)."project files "
				\."in a relative path to the project file" . "\n"

	let vimliteHelp .= "$(ProjectFilesAbs)       "
				\."A space delimited string containing all of the " . "\n"
				\.repeat(' ', 25)."project files in an absolute path" . "\n"

	let vimliteHelp .= "`expression`             "
				\."Evaluates the expression inside the backticks into a " . "\n"
				\.repeat(' ', 25)."string" . "\n"

	call g:psdialog.SetExtraHelpContent(vimliteHelp)

"===============================================================================
"常规设置
	let ctl = g:VCStaticText.New("General")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("Output File:", 
				\"$(IntermediateDirectory)/$(ProjectName)")
	call ctl.SetIndent(8)
	call ctl.ConnectButtonCallback('TestCtlCallback', 'button')
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Intermediate Folder:", './Debug')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Program:", './$(ProjectName)')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Program Arguments:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

"===============================================================================
"编译器设置
	let ctl = g:VCStaticText.New("Compiler")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("C++ Compiler Options:", "-Wall;-g3")
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("C Compiler Options:", 
				\'-Wall;-g3;$(shell pkg-config --cflags gtk+-2.0)')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Include Paths:", '.')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Preprocessor:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

"===============================================================================
"链接器设置
	let ctl = g:VCStaticText.New("Linker")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("Options:", "$(shell pkg-config --libs gtk+-2.0)")
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Library Paths:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Libraries:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

"	let ctl = g:VCComboBox.New("Combo Box:")
	let ctl = g:VCComboBox.New("")
	call ctl.SetIndent(8)
	call ctl.AddItem("a")
	call ctl.AddItem("b")
	call ctl.AddItem("c")
	call ctl.AddItem("d")
	call ctl.AddItem("e")
	call ctl.AddItem("f")
	call ctl.ConnectActionPostCallback("TestCtlCallback", "Hello")
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCCheckItem.New("是否启用？", 1)
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

	call g:TestVCTable()
	let ctl = g:ctl
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

"===============================================================================

"	call g:psdialog.SetSplitOpen(1)
	call g:psdialog.Display()
endfunction

" vim:fdm=marker:fen:fdl=1:ts=4
plugin/VimTagsManager.vim	[[[1
147
" Vim script utilities for VimLite
" Last Change: 2011 May 10
" Maintainer: fanhe <fanhed@163.com>
" License:  GPLv2

if exists('g:loaded_VimTagsManager')
    finish
endif
let g:loaded_VimTagsManager = 1

let s:start = 0

command! -nargs=* -complete=file VTMParseFiles call g:VTMParseFiles(<f-args>)


function s:InitVariable(varName, defaultVal) "{{{2
    if !exists(a:varName)
		let {a:varName} = a:defaultVal
        return 1
    endif
    return 0
endfunction
"}}}

"call s:InitVariable('g:VimTagsManager_DbFile', 
            "\'~/Desktop/VimLite/CtagsDatabase/TestTags3.db')
call s:InitVariable('g:VimTagsManager_DbFile', 
            \'VimLiteTags.db')

call s:InitVariable('g:VimTagsManager_SrcDir', 
            \'~/.vimlite/omnicpp')

let s:hasStarted = 0

function! g:GetTagsByScopeAndKind(scope, kind) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByScopeAndKind(
                \vim.eval('a:scope'), vim.eval('a:kind')))
    return tags
endfunction


function! g:GetTagsByScopesAndKinds(scopes, kinds) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByScopesAndKinds(
                \vim.eval('a:scopes'), vim.eval('a:kinds')))
    return tags
endfunction


function! g:GetTagsByScopeAndName(scope, name) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByScopeAndName(
                \vim.eval('a:scope'), vim.eval('a:name')))
    return tags
endfunction


function! g:GetTagsByScopesAndName(scopes, name) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByScopeAndName(
                \vim.eval('a:scopes'), vim.eval('a:name')))
    return tags
endfunction

function! g:GetOrderedTagsByScopesAndName(scopes, name) "{{{2
    py vim.command("let tags = %s" % vtm.GetOrderedTagsByScopesAndName(
                \vim.eval('a:scopes'), vim.eval('a:name')))
    return tags
endfunction

function! g:GetTagsByPath(path) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByPath(vim.eval('a:path')))
    return tags
endfunction

function! g:GetTagsByKindAndPath(kind, path) "{{{2
    py vim.command("let tags = %s" % vtm.GetTagsByKindAndPath(
                \vim.eval('a:kind'), vim.eval('a:path')))
    return tags
endfunction

function! g:VTMParseFiles(...) "{{{2
    if exists('s:hasConnected')
        if !s:hasConnected
            py vtm.OpenDatabase(vim.eval('s:absDbFile'))
        endif
    else
        echohl WarningMsg
        echo 'VimTagsManager has not yet started!'
        echohl None
        return
    endif

    "若传进来的第一个参数为列表, 仅解析此列表
    if a:0 > 0
        if type(a:1) == type([])
            py vtm.ParseFiles(vim.eval('a:1'))
            return
        endif
    endif

    py vtm.ParseFiles(vim.eval('a:000'))
endfunction


function! g:VTMOpenDatabase(dbFile) "{{{2
    if !s:hasStarted
        call VimTagsManagerInit()
    endif

    py vtm.OpenDatabase(os.path.expanduser(vim.eval('a:dbFile')))
endfunction


function! VimTagsManagerInit() "{{{1
    if s:hasStarted
        return
    else
        let s:hasStarted = 1
    endif

python << PYTHON_EOF
# -*- encoding:utf-8 -*-
import sys, os, os.path
import vim

sys.path.extend([os.path.expanduser(vim.eval('g:VimTagsManager_SrcDir'))])
from VimTagsManager import VimTagsManager
PYTHON_EOF

    py vtm = VimTagsManager()
    if filereadable(g:VimTagsManager_DbFile)
        " 若已存在数据库文件, 直接打开之
        let s:hasConnected = 1
        py vtm.OpenDatabase(
                    \os.path.expanduser(vim.eval('g:VimTagsManager_DbFile')))
    else
        " 没有存在的数据库文件, 暂时连接内存数据库
        " 当请求 ParseFiles() 时才新建硬盘的数据库
        let s:hasConnected = 0
        py vim.command("let s:absDbFile = '%s'" 
                    \% os.path.abspath(
                    \os.path.expanduser(vim.eval('g:VimTagsManager_DbFile'))))
        " 连接内存数据库
        py vtm.OpenDatabase(':memory:')
    endif
endfunction


" vim:fdm=marker:fen:expandtab:smarttab:fdl=1:
doc/VimLite.txt	[[[1
608
*VimLite.txt*              An IDE inspired by CodeLite

                   _   _______ _   _____   _________________~
                  | | / /_  _// | /, / /  /_  _/_  __/ ____/~
                  | |/ / / / / ,|// / /    / /  / / / __/   ~
                  | / /_/ /_/ /|_/ / /____/ /_ / / / /___   ~
                  |__/_____/_/  /_/_____/____//_/ /_____/   ~

                            VimLite User Manual
==============================================================================
CONTENTS                                *VimLite-Contents*

1. Introduction                         |VimLite-Introduction|
2. Download                             |VimLite-Download|
3. Prerequisites                        |VimLite-Prerequisites|
4. Project Manager                      |VimLite-ProjectManager|
    4.1. KeyMappings                    |VimLite-ProjectManager-KeyMappings|
    4.2. Commands                       |VimLite-ProjectManager-Commands|
    4.3. Cscope                         |VimLite-ProjectManager-Cscope|
5. Code Completion                      |VimLite-CodeCompletion|
    5.1. OmniCpp                        |VimLite-CodeCompletion-OmniCpp|
        5.1.1. Commands                 |VimLite-CodeCompletion-OmniCpp-Cmds|
        5.1.2. Macros Handling          |VimLite-CodeCompletion-OmniCpp-Macros|
        5.1.3. Limitation               |VimLite-CodeCompletion-OmniCpp-Limit|
    5.2. Clang                          |VimLite-CodeCompletion-Clang|
6. Debugger                             |VimLite-Debugger|
7. Options                              |VimLite-Options|
    7.1. Project Manager Options        |VimLite-Options-ProjectManager|
    7.2. Calltips Options               |VimLite-Options-Calltips|
    7.3. OmniCpp Options                |VimLite-Options-OmniCpp|
    7.4. Clang Options                  |VimLite-Options-Clang|
    7.5. Debugger Options               |VimLite-Options-Debugger|

==============================================================================
1. Introduction                         *VimLite-Introduction*

VimLite is a C/C++ IDE.

VimLite consists mainly of the following three modules:

    * Project Manager:                  The project manager module is 
                                        compatible with CodeLite. It auto
                                        generates makefile for you.

    * Code Completion:                  An enhanced OmniCpp plugin and a clang 
                                        code completion plugin.

                                        OmniCpp support the following 
                                        completion: namespace, structure, 
                                        class member, using, using namespace, 
                                        class template, stl, etc.

                                        Clang code completion supports all but 
                                        is slower than OmniCpp.

    * Debugger Integration:             Gdb integration, by pyclewn. 

==============================================================================
2. Download                             *VimLite-Download*

The latest release of VimLite can be found from this url:

    http://www.vim.org/scripts/script.php?script_id=3647

And VimLite in google code can be found from this url:

    http://code.google.com/p/vimlite/

==============================================================================
3. Prerequisites                        *VimLite-Prerequisites*

VimLite depends following software: >
    python
    python-lxml
    gcc
    make
    gdb
    cscope
<
On ubuntu 10.04, just run: >
    sudo apt-get install python python-lxml build-essential gdb cscope
<
Make sure your vim compile with this features: >
    +python
    +netbeans_intg
<
And make sure you have these settings in your vimrc file: >
    set nocp
    filetype plugin on
    syntax on
<
==============================================================================
4. Project Manager                      *VimLite-ProjectManager*

Workspaces and Projects~

One workspace holds a number of projects, for instance, various pieces of a
large design. Create a workspace by selecting "New Workspace..." on workspace
popup menu (The popup menu when the cursor in workspace line).

A project is one piece of a large design within that workspace. Create a
project by selecting 'Create a New Project' on workspace popup menu. Please
create a worksapce before do this.

For instance, one project might be a DLL, another project could be a static
library, and yet another project could be a GUI design which would be
eventually integrated together in one workspace to be released as a piece of
software. All these projects could be part of one workspace.

The project itself contains all information it needs to produce its own output
piece of the overall software.

Also, a project contains no information about the workspace, and thus one
project can be part of multiple workspaces. The workspace holds pointers to
the projects which are members of that workspace.

The workspace information file is <workspace-name>.workspace.

The project information file is <project-name>.project.

Configurations~

Each project has at least two build configurations: Debug and Release. In
practice you can have many more configurations. You can select what
configuration the project is using by selecting 'Settings' on project popup
menu.

This information is global among all the projects in the workspace and so is
kept in the workspace information file. This means all projects be in the same
configuration in a workspace.


NOTE: Almost all commands are listed in popup menu, please help info around.

------------------------------------------------------------------------------
4.1. KeyMappings                        *VimLite-ProjectManager-KeyMappings*

Press <F1> in workspace buffer for quick help information.

    Key             Description                     Option~
------------------------------------------------------------------------------
    <2-LeftMouse>   Fold / expand node          
    <CR>            Same as <2-LeftMouse>
    o               Same as <2-LeftMouse>           |g:VLWOpenNodeKey|
    go              Preview file                    |g:VLWOpenNode2Key|
    t               Open file in new tab            |g:VLWOpenNodeInNewTabKey|
    T               Open file in new tab silently   |g:VLWOpenNodeInNewTab2Key|
    i               Open file split                 |g:VLWOpenNodeSplitKey|
    gi              Preview file split              |g:VLWOpenNodeSplit2Key|
    s               Open file vsplit                |g:VLWOpenNodeVSplitKey|
    gs              Preview file vsplit             |g:VLWOpenNodeVSplit2Key|
    P               Go to root node                 |g:VLWGotoRootKey|
    p               Go to parent node               |g:VLWGotoParentKey|
    <C-n>           Go to next sibling node         |g:VLWGotoPrevSibling|
    <C-p>           Go to prev sibling node         |g:VLWGotoNextSibling|
    .               Show text menu                  |g:VLWShowMenuKey|
    <RightRelease>  Popup gui menu                  |g:VLWPopupMenuKey|
    R               Refresh buffer                  |g:VLWRefreshBufferKey|
    <F1>            Toggle quick help info          |g:VLWToggleHelpInfo|
------------------------------------------------------------------------------
                                        *g:VLWOpenNodeKey*
If workspace node is selected, a build config menu will be shown. >
    let g:VLWOpenNodeKey = 'o'
<
                                        *g:VLWOpenNode2Key*
>
    let g:VLWOpenNode2Key = 'go'
<
                                        *g:VLWOpenNodeInNewTabKey*
>
    let g:VLWOpenNodeInNewTabKey = 't'
<
                                        *g:VLWOpenNodeInNewTab2Key*
>
    let g:VLWOpenNodeInNewTab2Key = 'T'
<
                                        *g:VLWOpenNodeSplitKey*
>
    let g:VLWOpenNodeSplitKey = 'i'
<
                                        *g:VLWOpenNodeSplit2Key*
>
    let g:VLWOpenNodeSplit2Key = 'gi'
<
                                        *g:VLWOpenNodeVSplitKey*
>
    let g:VLWOpenNodeVSplitKey = 's'
<
                                        *g:VLWOpenNodeVSplit2Key*
>
    let g:VLWOpenNodeVSplit2Key = 'gs'
<
                                        *g:VLWGotoParentKey*
>
    let g:VLWGotoParentKey = 'p'
<
                                        *g:VLWGotoRootKey*
>
    let g:VLWGotoRootKey = 'P'
<
                                        *g:VLWGotoNextSibling*
>
    let g:VLWGotoNextSibling = '<C-n>'
<
                                        *g:VLWGotoPrevSibling*
>
    let g:VLWGotoPrevSibling = '<C-p>'
<
                                        *g:VLWRefreshBufferKey*
>
    let g:VLWRefreshBufferKey = 'R'
<
                                        *g:VLWShowMenuKey*
The key to popup general menu. >
    let g:VLWShowMenuKey = '.'
<
                                        *g:VLWPopupMenuKey*
The key to popup gui menu, this default value probably does not work. >
    let g:VLWPopupMenuKey = '<RightRelease>'
<
                                        *g:VLWToggleHelpInfo*
>
    let g:VLWToggleHelpInfo = '<F1>'

------------------------------------------------------------------------------
4.2. Commands                           *VimLite-ProjectManager-Commands*

    VLWorkspaceOpen [workspace_file]    Open a workspace file or default
                                        workspace.

    VLWBuildActiveProject               Build active projcet.

    VLWCleanActiveProject               Clean active project.

    VLWRunActiveProject                 Run active project.

    VLWBuildAndRunActiveProject         Build active project and run if build
                                        successfully.

    VLWSwapSourceHeader                 Toggle editing source and header

    VLWFindFiles [name]                 Find workspace files

    VLWFindFilesNoCase [name]           Find workspace files with no case
                                        sensitive

------------------------------------------------------------------------------
4.3. Cscope                             *VimLite-ProjectManager-Cscope*

VimLite uses cscope database to achieve some features, such as jump to
definition, jump to declaration, search workspace files, etc.
Run ':h cscope' for more info.

Commands:~

    VLWInitCscopeDatabase [1]           Initialize cscope database. If
                                        argument is not 0, VimLite will
                                        generate database forcibly.

    VLWUpdateCscopeDatabase             Update database. Only be valided when
                                        has been connected to the workspace
                                        cscope database.


==============================================================================
5. Code Completion                      *VimLite-CodeCompletion*

Popup menu format: ~
>
    +------------------------+
    |method1()  f  +  MyClass|
    |_member1   m  +  MyClass|
    |_member2   m  #  MyClass|
    |_member3   m  -  MyClass|
    +------------------------+
        ^       ^  ^     ^
       (1)     (2)(3)   (4)
<
(1) Name of the symbol, when a match ends with '()' it's a function.

(2) Kind of the symbol, possible kinds are: >
    * c = classes
    * d = macro definitions
    * e = enumerators (values inside an enumeration)
    * f = function definitions
    * g = enumeration names
    * m = class, struct, and union members
    * n = namespaces
    * p = function prototypes
    * s = structure names
    * t = typedefs
    * u = union names
    * v = variable definitions
    * x = using types

(3) Access, possible values are: >
    * + = public
    * # = protected
    * - = private
Note: Enumerators have no access information

(4) Parent scope where the symbol is defined.
Note: If the parent scope is '<global>' it's a global symbol.
Note: Anonymous scope may starts with "__anon".


Global Scope Completion~

The global scope completion allows you to complete global symbols for the base 
you are currently typing. The base can start with '::' or not.
Note: Global scope completion only works with a non empty base, if you run a
completion just after a '::' the completion will fail. The reason is that if
there is no base to complete the script will try to display all the tags in
the database. For small project it could be not a problem but for others you
may wait 5 minutes or more for a result.

eg1: >
    pthread_cr<C-x><C-o>    =>      pthread_create
<
Where pthread_create is a global function.
eg2: >
    ::globa<C-x><C-o>       =>     ::global_func()
                                    +----------------+
                                    |global_func()  f|
                                    |global_var1    v|
                                    |global_var2    v|
                                    +----------------+
<
Where global_var1, global_var2 and global_func are global symbols
eg3: >
    ::<C-x><C-o>            =>      [NO MATCH]
<
No match because a global completion from an empty base is not allowed.


Member Completion~

You can complete members of a container(class, struct, namespace, enum).
VimLite Code Completion will auto popup complete menu when you type ':' or '.'
or '>'. Of cause you can use <C-x><C-o> to start completing.

eg: >
    MyNamespace::<C-x><C-o>
                +--------------------------------+
                |E_ENUM0            e MyNamespace|
                |E_ENUM1            e MyNamespace|
                |E_ENUM2            e MyNamespace|
                |MyClass            c MyNamespace|
                |MyEnum             g MyNamespace|
                |MyStruct           s MyNamespace|
                |MyUnion            u MyNamespace|
                |SubNamespace       n MyNamespace|
                |doSomething(       f MyNamespace|
                |myVar              v MyNamespace|
                |something_t        t MyNamespace|
                +--------------------------------+

------------------------------------------------------------------------------
5.1. OmniCpp                            *VimLite-CodeCompletion-OmniCpp*

OmniCpp needs a tags database to support completion, you need parse the
workspace before starting code completion. Put the cursor on workspace line
in VLWorkspace buffer window, popup the menu, select "Parse Workspace (Quick)".

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
5.1.1. Commands                         *VimLite-CodeCompletion-OmniCpp-Cmds*

    VLWParseFiles <file1> <file2> ...   Parse files.

    VLWParseCurrentFile                 Parse current editing file.
                                        NOTE: You ought to save current file
                                        before run this command.

    VLWDeepParseCurrentFile             Parse current editing file and the
                                        files it includes.
                                        NOTE: You ought to save current file
                                        before run this command.

    VLWEnvVarSetttings                  Open 'Environment Variables Setting'
                                        dialog.

    VLWTagsSetttings                    Open 'Tags Setting' dialog.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
5.1.2. Macros Handling                  *VimLite-CodeCompletion-OmniCpp-Macros*

List in 'VimLite -> TagsSettings -> Tokens' are to be pre-processed by OmniCpp
parser. Usually, you would like to add new token which confuse the parse.
Read the following url for help:
    http://www.codelite.org/LiteEditor/MacrosHandling101

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
5.1.3. Limitation                       *VimLite-CodeCompletion-OmniCpp-Limit*

OmniCpp is not a C/C++ compiler, so...
Some C++ features are not supported, some implemented features may not work
properly in some conditions. They are multiple reasons like a lack of
information in the database, performance issues and so on...

Here is a list for whiches are not supported:~
1. Does not support local variables completion, use <C-x><C-n> instead.
2. Does not support using [namespace] statement in included files. This
   behavior is not recommended.
3. Does not support friend. Solution is just displaying all class members.
4. Does not support complex typedef. Solution is configuring corresponding
   type replacement. eg: >
   typedef typename _Alloc::template rebind<value_type>::other _Pair_alloc_type;
5. Does not support overload functions with different return types.
6. Does not support function template.
7. Does not support '.' and '->' overload for performance considerations. 

------------------------------------------------------------------------------
5.1. Clang                              *VimLite-CodeCompletion-Clang*

You can set g:VLWorkspaceUseClangCC to 1 to enable clang code completion. >
    let g:VLWorkspaceUseClangCC = 1

Clang code completion will auto work, but need the current build configuration
of the project is not a custom build. VimLite need version of clang >= 2.9
to work.

On ubuntu 10.04, you can download the deb package here:
    http://code.google.com/p/vimlite/downloads/list

==============================================================================
6. Debugger                             *VimLite-Debugger*

VimLite integrate pyclewn in it.
Start to debug the active projcet, just press the icon in toolbar or run: >
    :VLWDbgStart
<
NOTE: You must start degger before setting a breakpoint.

------------------------------------------------------------------------------
6.1. Commands                           *VimLite-Debugger-Commands*

    VLWDbgStart                         Start debugger.

    VLWDbgStop                          Stop debugger.

    VLWDbgStepIn                        Step in.

    VLWDbgNext                          Next.

    VLWDbgStepOut                       Step out.

    VLWDbgContinue                      Continue

    VLWDbgToggleBp                      Toggle breakpoint of the cursor line.

Please run ':h pyclewn' for more commands.~

==============================================================================
7. Options                              *VimLite-Options*

Right hand side is the default value, you can modify other values for the same
type. If type of the right hand side value is integer, 0 for False, non-zero
for True. 

------------------------------------------------------------------------------
7.1. Project Manager Options            *VimLite-Options-ProjectManager*

Workspace window width. >
    let g:VLWorkspaceWinSize = 30

Set the wrokspace buffer name. >
    let g:VLWorkspaceBufName = '==VLWorkspace=='

Highlight the workspace buffer cursor line. >
    let g:VLWrokspaceHighlightCursorline = 1

If not 0, when the curser put on one source file buffer, the cursor of
worksapce buffer's cursor will go the the corresponding source file line. >
    let g:VLWorkspaceLinkToEidtor = 1

Will install a menu named 'VimLite'. >
    let g:VLWorkspaceEnableMenuBarMenu = 1

Will install some toolbar icons. >
    let g:VLWorkspaceEnableToolBarMenu = 1

Enable cscope, if this variable is 0, all about cscope features will be not
worked. >
    let g:VLWorkspaceEnableCscope = 1

If not 0, VimLite will not initiative to create cscope database, but only
connect an existing db. >
    let g:VLWorkspaceJustConnectExistCscopeDb = 1

If not 0, VimLite will pass all project's include search paths to cscope, so
cscope will generate a datebase which contains all headers. >
    let g:VLWorkspaceCscopeContainExternalHeader = 1

Enable fast symbol lookup via an inverted index. This option causes cscope to
create 2 more files ('<name>.in.out'' and '<name>.po.out') in addition to the
normal database. This allows a faster symbol search algorithm that provides
noticeably faster lookup performance for large projects. >
    let g:VLWorkspaceCreateCscopeInvertedIndex = 0

Highlight the .h/.hpp and .c/.cpp file. >
    let g:VLWorkspaceHighlightSourceFile = 1

Insert worksapce name into title. >
    let g:VLWorkspaceDispWspNameInTitle = 1

Auto save all modified files before build projects. >
    let g:VLWorkspaceSaveAllBeforeBuild = 0

Use Clang code completion instead of OmniCpp which based on modified ctags. >
    let g:VLWorkspaceUseClangCC = 0

The active project highlight group name. >
    let g:VLWorkspaceActiveProjectHlGroup = 'SpecialKey'

Auto parse the editing file when save it. 
Only work for files belong to workspace. >
    let g:VLWorkspaceParseFileAfterSave = 0

Do not auto parse the editing file if it is a source file (*.cpp, *.c). >
    let g:VLWorkspaceNotParseSourceAfterSave = 0

------------------------------------------------------------------------------
7.2. Calltips Options                   *VimLite-Options-Calltips*

The key to trigger function calltips. >
    let g:VLCalltips_DispCalltipsKey = '<A-p>'

The key to display the next calltips. >
    let g:VLCalltips_NextCalltipsKey = '<A-j>'

The key to display the prev calltips. >
    let g:VLCalltips_PrevCalltipsKey = '<A-k>'

Enable indicating which function argument is being edited. If you feel this
feature is slow, you may set it to 0. >
    let g:VLCalltips_IndicateArgument = 1

Enable syntax testing. As well known, syntax testing in vim is very slow, if
function calltips in your vim crash your speed, you may not set this to 1. >
    let g:VLCalltips_EnableSyntaxTest = 0

------------------------------------------------------------------------------
7.3. OmniCpp Options                    *VimLite-Options-OmniCpp*

Auto trigger code completion when input '.' (dot). >
    let g:VLOmniCpp_MayCompleteDot = 1

Auto trigger code completion when input '>' (right arrow). >
    let g:VLOmniCpp_MayCompleteArrow = 1

Auto trigger code completion when input ':' (colon). >
    let g:VLOmniCpp_MayCompleteColon = 1

When completeopt does not contain longest option, this setting controls the
behaviour of the popup menu selection.
  * 0 -> don't select first item.
  * 1 -> select first item (inserting it to the text).
  * 2 -> select first item (without inserting it to the text). >
    let g:VLOmniCpp_ItemSelectionMode = 2

Map <CR> (return) key to auto trigger function calltips after select a
function item in the code completion popup menu. >
    let g:VLOmniCpp_MapReturnToDispCalltips = 1

Use python code which can improve the completing speed. >
    let g:VLOmniCpp_UsePython = 1

------------------------------------------------------------------------------
7.4. Clang Options                      *VimLite-Options-Clang*

Clang program. >
    let g:VLCCC_ClangProgram = 'clang'

Enable syntax check for C/C++ when trigger code completion. >
    let g:VLCCC_IndicateError = 1

Auto trigger code completion when input '.' (dot). >
    let g:VLCCC_MayCompleteDot = 1

Auto trigger code completion when input '>' (right arrow). >
    let g:VLCCC_MayCompleteArrow = 1

Auto trigger code completion when input ':' (colon). >
    let g:VLCCC_MayCompleteColon = 1

When completeopt does not contain longest option, this setting controls the
behaviour of the popup menu selection.
  * 0 -> don't select first item.
  * 1 -> select first item (inserting it to the text).
  * 2 -> select first item (without inserting it to the text). >
    let g:VLCCC_ItemSelectionMode = 2

Map <CR> (return) key to auto trigger function calltips after select a
function item in the code completion popup menu. >
    let g:VLCCC_MapReturnToDispCalltips = 1

------------------------------------------------------------------------------
7.5. Debugger Options                   *VimLite-Options-Debugger*

The frame sign background color, can be #xxxxxx format. >
    let g:VLWDbgFrameSignBackground = 'DarkMagenta'

Save breakpoints info in a file. Currently, this feature does not work well,
so you may want to disable this feature. >
    let g:VLWDbgSaveBreakpointsInfo = 1

------------------------------------------------------------------------------
vim:tw=78:ft=help:norl:et:ts=4:sw=4:sts=4
doc/pyclewn.txt	[[[1
1516
*pyclewn.txt*                                   Last change: 2011 June 14


                            PYCLEWN USER MANUAL

The Pyclewn user guide                              *pyclewn*

1. Introduction                                     |pyclewn-intro|
2. Starting pyclewn                                 |:Pyclewn|
3. Options                                          |pyclewn-options|
4. Using pyclewn                                    |pyclewn-using|
5. Gdb                                              |pyclewn-gdb|
6. Pdb                                              |pyclewn-pdb|
7. Windows                                          |pyclewn-windows|
8. Key mappings                                     |pyclewn-mappings|
9. Watched variables                                |pyclewn-variable|
10. Extending pyclewn                               |pyclewn-extending|


==============================================================================
1. Introduction                                     *pyclewn-intro*


Pyclewn is a python program that allows the use of vim as a front end to a
debugger. Pyclewn supports the gdb and the pdb debuggers. Pyclewn uses the
netbeans protocol to control vim.

The debugger output is redirected to a vim window, the|pyclewn-console|. The
debugger commands are mapped to vim user-defined commands with a common letter
prefix (the default is the|C|letter), and with vim command completion
available on the commands and their first argument.

On unix when running gvim, the controlling terminal of the program to debug is
the terminal used to launch pyclewn. Any other terminal can be used when the
debugger allows it, for example after using the ``attach`` or ``tty`` gdb
commands or using the ``--tty`` option with pdb.

On Windows, gdb pops up a console attached to the program to debug.


Pyclewn currently supports the following debuggers:

    * gdb:      version 6.2.1 and above,
                pyclewn uses the gdb MI interface

    * pdb:      the Python debugger

    * simple:   a fake debugger implemented in python to test pyclewn
                internals


Pyclewn provides the following features:
---------------------------------------

* A debugger command can be mapped in vim to a key sequence using vim key
  mappings. This allows, for example, to set/clear a breakpoint or print a
  variable value at the current cursor or mouse position by just hitting a
  key.

* A sequence of gdb commands can be run from a vim script when the
 |async-option|is set. This may be useful in a key mapping.

* Breakpoints and the line in the current frame are highlighted in the source
  code. Disabled breakpoints are noted with a different highlighting color.
  Pyclewn automatically finds the source file for the breakpoint if it exists,
  and tells vim to load and display the file and highlight the line.

* The value of an expression or variable is displayed in a balloon in gvim
  when the mouse pointer is hovering over the selected expression or the
  variable.

* Similarly to gdb, one may attach to a running python process with the pdb
  debugger, interrupt the process, manage a debugging session and terminate
  the debugging session by detaching from the process. A new debugging session
  may be conducted later on this same process, possibly from another Vim
  instance.

* An expression can be watched in a vim window. The expression value is
  updated and highlighted whenever it has changed. When the expression is a
  structure or class instance, it can be expanded (resp. folded) to show
  (resp. hide) its members and their values. This feature is only available
  with gdb.

* The|project-command|saves the current gdb settings to a project file that
  may be sourced later by the gdb "source" command. These settings are the
  working directory, the debuggee program file name, the program arguments and
  the breakpoints. The sourcing and saving of the project file can be
  automated to occur on each gdb startup and termination, whith the
 |project-file|command line option. The ``project`` command is currently only
  available with gdb.

* Vim command completion on the commands and their first argument.


The remaining sections of this manual are:
-----------------------------------------

    2.|:Pyclewn|explains how to start pyclewn.

    3.|pyclewn-options|lists pyclewn options and their usage.

    4.|pyclewn-using|explains how to use the pyclewn features common to all
       supported debuggers

    5.|pyclewn-gdb|details the topics relevant to pyclewn and the gdb
       debugger.

    6.|pyclewn-pdb|details the topics relevant to pyclewn and the pdb
       debugger.

    7.|pyclewn-windows|describes what is specific to pyclewn on Windows.

    8.|pyclewn-mappings|lists the pyclewn key mappings and how to use them.

    9.|pyclewn-variable|explains how to use the variable debugger window with
    gdb.

    10.|pyclewn-extending|explains how to implement a new debugger in pyclewn

==============================================================================
2. Starting pyclewn                                 *:Pyclewn*


Start pyclewn from vim:
-----------------------
The|:Pyclewn|vim command requires at least vim 7.3. To start pyclewn with the
gdb debugger: >

    :Pyclewn

To start pyclewn with the pdb debugger: >

    :Pyclewn pdb [scriptname]

Next, the gdb debugger is started by running a debugger command from vim
command line. For example, load foobar with the gdb command "file" and start
gbd by typing on the vim command line: >

    :Cfile foobar

To just start gdb with a command that does not have any effect: >

    :Cecho

To terminate pyclewn and the vim netbeans interface, run the following
command: >

    :nbclose

To know if the netbeans interface is connected, run the following command: >

    :echo has("netbeans_enabled")

The|:Pyclewn|command is provided by the vim plugin installed as the
"pyclewn.vim" file in vim plugin directory. Pyclewn command line arguments and
connection details may be set with the "pyclewn_args" and the
"pyclewn_connection" vim global variables. For further customization you can
edit the "pyclewn.vim" file in vim autoload directory.

The|:Pyclewn|command does the following:

    * spawn pyclewn
    * start the vim netbeans interface and connect it to pyclewn
    * source a script automatically generated by pyclewn containing utility
      functions and the debugger commands as vim commands


Start the pyclewn process:
--------------------------

Pyclewn with the gdb debugger is simply started as: >

    pyclewn

On Windows, pyclewn is started with a Desktop shortcut that runs pyclewn.bat.
The pyclewn.bat file is located in the Scripts directory of the python
distribution.


==============================================================================
3. Options                                          *pyclewn-options*


The pyclewn options can be set:

    * on pyclewn command line

    * in the "pyclewn_args" and the "pyclewn_connection" vim global
      variables when starting pyclewn with the|:Pyclewn|command

    * as the keyword parameters of the pdb function


options:
  --version                   show program's version number and exit
  -h, --help                  show this help message and exit
  -s, --simple                select the simple debugger
  --pdb                       select 'pdb', the python debugger
  --run                       allow the debuggee to run after the pdb() call
                              (default 'False')
  --tty=TTY                   use TTY for input/output by the python script
                              being debugged (default '/dev/null')
  -g PARAM_LIST, --gdb=PARAM_LIST
                              select the gdb application (the default), with a
                              mandatory, possibly empty, PARAM_LIST
  -d, --daemon                run as a daemon (default 'False')
  -p PGM, --pgm=PGM           set the debugger program to PGM
  -a ARGS, --args=ARGS        set the debugger program arguments to ARGS
  -e EDITOR, --editor=EDITOR  set the Vim program to EDITOR;
                              Vim is not spawned by pyclewn when this
                              parameter is set to an empty string
  -c ARGS, --cargs=ARGS       set the Vim program arguments to ARGS
  -w LOCATION, --window=LOCATION
                              open the debugger console window at LOCATION
                              which may be one of (top, bottom, left,
                              right), the default is top
  -m LNUM, --maxlines=LNUM    set the maximum number of lines of the debugger
                              console window to LNUM (default 10000 lines)
  -x PREFIX, --prefix=PREFIX  set the commands prefix to PREFIX (default|C|)
  -b COLORS, --background=COLORS
                              COLORS is a comma separated list of the three
                              colors of the breakpoint enabled, breakpoint
                              disabled and frame sign background colors, in
                              this order (default 'Cyan,Green,Magenta')
  -n CONN, --netbeans=CONN    set netBeans connection parameters to CONN with
                              CONN as 'host[:port[:passwd]]', (the default is
                              ':3219:changeme' where the empty host represents
                              INADDR_ANY)
  -l LEVEL, --level=LEVEL     set the log level to LEVEL: critical, error,
                              warning, info, debug or nbdebug (default error)
  -f FILE, --file=FILE        set the log file name to FILE


The full description of pyclewn options follows:
------------------------------------------------

--version           Show program's version number and exit.

-h
--help              Show this help message and exit.

-s
--simple            Select the simple debugger. In that case, the --pgm and
                    --args options are meaningless. The simple debugger is
                    documented in debugger/simple.py, in the source
                    distribution.

--pdb               Select 'pdb', the python debugger.

--run               By default the python debuggee is stopped at the first
                    statement after the call to pdb(). Enabling this option
                    allows the debuggee to run after the call to pdb().

--tty={TTY}         Use TTY for input/output by the python script being
                    debugged. The default is "/dev/null".

-g {PARAM_LIST}
--gdb={PARAM_LIST}  Select the gdb debugger (the default). The default value
                    of the "pgm" option is "gdb". The PARAM_LIST option
                    parameter is a comma separated list of parameters and is
                    mandatory when the option is present. So, to run gdb with
                    no specific parameter, the following commands are
                    equivalent: >

                        pyclewn
                        pyclewn -g ""
                        pyclewn --gdb=
.
                    There are three optional parameters:

                        * the "async" keyword sets the|async-option|
                        * the "nodereference" keyword, see|gdb-balloon|.
                        * the project file name sets the|project-file|

                    The project file name can be an absolute pathname, a
                    relative pathname starting with '.' or a home relative
                    pathname starting with '~'. The directory of the project
                    file name must be an existing directory.
                    For example on unix: >

                        pyclewn --gdb=async,./project_name

-d
--daemon            Run as a daemon (default 'False'): on unix, pyclewn is
                    detached from the terminal from where it has been
                    launched, which means that this terminal cannot be used as
                    a controlling terminal for the program to debug, and
                    cannot be used for printing the pyclewn logs as well.
                    On Windows, this option hides the pyclewn Windows console
                    and it is set on the shortcut that is installed on the
                    Desktop.

-p {PGM}
--pgm={PGM}         Set the debugger program to PGM. PGM must be in one of the
                    directories listed in the PATH environment variable.

-a {ARGS}
--args={ARGS}       Set the debugger program arguments to ARGS. These
                    arguments may be double quoted. For example, start gdb
                    with the program foobar and "this is foobar argument" as
                    foobar's argument: >

                    pyclewn -a '--args foobar "this is foobar argument"'

-e {EDITOR}
--editor={EDITOR}   Set the editor program to EDITOR. EDITOR must be in one
                    of the directories listed in the PATH environment
                    variable, or the full pathname to vim or gvim executable.
                    When this command line option is not set, pyclewn uses the
                    value of the EDITOR environment variable, and if this
                    environment variable is not set either, then pyclewn
                    defaults to using "gvim" as the name of the program to
                    spawn.

-c {ARGS}
--cargs={ARGS}      Set the editor program arguments to ARGS, possibly double
                    quoted (same as option --args).

-w {LOCATION}
--window={LOCATION} The debugger console window pops up at LOCATION, which may
                    be one of top, bottom, left, right or none. The default is
                    top.  In the left or right case, the window pops up on the
                    left (resp. right) if there is only one window currently
                    displayed, otherwise the debugger window is opened at the
                    default top. When LOCATION is none, the automatic display
                    of the console is disabled.

-m {LNUM}
--maxlines={LNUM}   Set the maximum number of lines of the debugger console
                    window to LNUM (default 10000 lines). When the number of
                    lines in the buffer reaches LNUM, 10% of LNUM first lines
                    are deleted from the buffer.

-x {PREFIX}
--prefix={PREFIX}   Set the user defined vim commands prefix to PREFIX
                    (default|C|). The prefix may be more than one letter
                    long. The first letter must be upper case.

-b {COLORS}
--background={COLORS}
                    COLORS is a comma separated list of the three colors of
                    the breakpoint enabled, breakpoint disabled and frame sign
                    background colors, in this order (default
                    'Cyan,Green,Magenta'). The color names are case sensitive.
                    See|highlight-ctermbg|for the list of the valid color
                    names.

                    This option has no effect when vim version is vim72 or
                    older.

-n {CONN}
--netbeans={CONN}   Set netBeans connection parameters to CONN with CONN as
                    'host[:port[:passwd]]', (the default is ':3219:changeme'
                    where the empty host represents INADDR_ANY). Pyclewn
                    listens on host:port, with host being a name or the IP
                    address of one of the local network interfaces in standard
                    dot notation. These parameters must match those used by
                    vim for the connection to succeed.

-l {LEVEL}
--level={LEVEL}     Set the log level to LEVEL: critical, error, warning, info,
                    debug or nbdebug (default critical). Level nbdebug is very
                    verbose and logs all the netbeans pdu as well as all the
                    debug traces. Critical error messages are printed on
                    stderr. No logging is done on stderr (including critical
                    error messages) when the "--level" option is set to
                    something else than "critical" and the "--file" option is
                    set.

-f {FILE}
--file={FILE}       Set the log file name to FILE.


On unix, when the 'CLEWN_PIPES' environment variable is set, pyclewn uses
pipes instead of a pseudo tty to communicate with gdb and emulates the select
event loop with threads. When the 'CLEWN_POPEN' environment variable is set,
pyclewn uses pipes instead of a pseudo tty but continues using the select
event loop. These variables are mainly used for regression testing.

==============================================================================
4. Using pyclewn                            *pyclewn-using* *pyclewn-console*


Console:
--------
The debugger output is redirected to a vim window: the console.

The console window pops up whenever a|Ccommand|is entered on vim command line
or a key mapped by pyclewn is hit. This behavior may be disabled by setting to
`none` the `window`|pyclewn-options|and may be useful when using Vim tabs and
wanting to keep the console in a tab of its own. In this case, the cursor
position in the console is not updated by pyclewn, so you need to set manually
the cursor at the bottom of the console, the first time you open
(clewn)_console.

The initial console window height is set with the vim option 'previewheight'
that defaults to 12 lines.


Commands:                                           *Ccommand* *C*
---------
The prefix letter|C|is the default vim command prefix used to map debugger
commands to vim user-defined commands. These commands are called|Ccommand|in
this manual. The prefix can be changed with a command line option.

A debugger command can be entered on vim command line with the|C|prefix. It is
also possible to enter the command as the first argument of the|C|command. In
the following example with gdb, both methods are equivalent: >

    :Cfile /path/to/foobar
    :C file /path/to/foobar

The first method provides completion on the file name while the second one
does not.

The second method is useful when the command is a user defined command in the
debugger (user defined commands built by <define> in gdb), and therefore not a
vim command. It is also needed for gdb command names that cannot be mapped to
a vim command because vim does not accept non alphanumeric characters within
command names (for example <core-file> in gdb).

To get help on the pyclewn commands, use Chelp.

Pyclewn commands can be mapped to keys, or called within a Vim script or a
menu.

Note:
The gdb debugger cannot handle requests asynchronously, so the
|async-option|must be set, when mapping a key to a sequence of commands.
With this option set, one can build for example the following mapping: >

    :map <F8> :Cfile /path/to/foobar <Bar> Cbreak main <Bar> Crun <CR>

Note:
Quotes and backslashes must be escaped on vim command line. For example, to
print foo with a string literal as first argument to the foo function: >

    :Cprint foo(\"foobar\", 1)

And to do the same thing with the string including a new line: >

    :Cprint foo(\"foobar\\n\", 1)


Completion:
-----------
Command line completion in vim is usually done using the <Tab> key (set by the
'wildchar' option). To get the list of all valid completion matches, type
CTRL-D. For example, to list all the debugger commands (assuming the
default|C|prefix is being used): >

    :C<C-D>

See also the 'wildmenu' option. With this option, the possible matches are
shown just above the command line and can be selected with the arrow keys.

The first argument completion of a|Ccommand|may be done on a file name or on a
list. For example with gdb, the following command lists all the gdb help
items: >

    :Chelp <C-D>

The first argument completion of the|C|command is the list of all the debugger
commands. For example, to list all the debugger commands (note the space after
the|C|): >

    :C <C-D>


Command line search:
--------------------
Use the powerful command line search capabilities of the Vim command line.
For example, you want to type again, possibly after a little editing, one of
the commands previously entered: >

    :Cprint (*(foo*)0x0123ABCD)->next->next->part1->something_else.aaa

You can get rapidly to this command by using the Vim command line window
|cmdline-window|: >

    :<CTRL-F>
    /something_else
    <CR>

or from normal mode >
    q:
    /something_else
    <CR>


Vim in a terminal
-----------------
The debuggee output is redirected to '/dev/null' when the name of the program
is "vim" or "vi". One must use the "set inferior-tty" gdb command to redirect
the debuggee output to a terminal.

Do not use the "--daemon" command line option when running vim in a console.


Balloon:
--------
A variable is evaluated by the debugger and displayed in a balloon in gvim,
when the mouse pointer is hovering over the the variable. To get the
evaluation of an expression, first select the expression in visual mode in the
source code and point the mouse over the selected expression. To disable this
feature, set the vim option 'noballooneval'.

==============================================================================
5. Gdb                                              *pyclewn-gdb*


When gdb is started, it automatically executes commands from its init file,
normally called '.gdbinit'. See the gdb documentation.


Debuggee standard input and output:
-----------------------------------
On Windows, gdb pops up a console attached to the program to debug.

                                                    *inferior_tty*

On unix, when starting pyclewn from a terminal and using gvim, pyclewn creates
a pseudo terminal that is the the controlling terminal of the program to
debug. Programs debugged by gdb, including those based on curses and termios
such as vim, run in this terminal. A <Ctl-C> typed in the terminal interrupts
the debuggee.

When pyclewn is started from vim with the|:Pyclewn|command, there is no
terminal associated with pyclewn. Use instead the "inferior_tty.py" script
installed with pyclewn to get the same functionality. This script creates a
pseudo terminal to be used as the controlling terminal of the process debugged
by gdb. For example, to debug vim (not gvim) and start the debugging session
at vim's main function.  From pyclewn, spawn an xterm terminal and launch
"inferior_tty.py" in this terminal: >

    :Cfile /path/to/vim
    :Cshell setsid xterm -e inferior_tty.py &

"inferior_tty.py" prints the name of the pseudo terminal to be used by gdb and
the two gdb commands needed to configure properly gdb with this terminal. Copy
and paste these two commands in vim command line: >

    :Cset inferior-tty /dev/pts/nn
    :Cset environment TERM = xterm

Then start the debugging session of vim and stop at vim main(): >

    :Cstart

Note:
* <setsid> is necessary to prevent gdb from killing the xterm process when a
  <Ctl-C> is typed from gdb to interrupt the debuggee. This is not needed when
  the terminal emulator is not started from gdb.


                                                    *async-option*
Async option:
-------------
The gdb event loop is not asynchronous in most configurations, which means
that gdb cannot handle a command while the previous one is being processed and
discards it.
When gdb is run with the|async-option|set, pyclewn queues the commands in a
fifo and send a command to gdb, only when gdb is ready to process the command.
This allows the key mappings of a sequence of gdb commands. To set the
|async-option|, see|pyclewn-options|.


                                                    *gdb-keys*
List of the gdb default key mappings:
-------------------------------------
These keys are mapped after the|Cmapkeys|vim command is run.

        CTRL-Z  send an interrupt to gdb and the program it is running (unix
                only)
        B       info breakpoints
        L       info locals
        A       info args
        S       step
        CTRL-N  next: next source line, skipping all function calls
        F       finish
        R       run
        Q       quit
        C       continue
        W       where
        X       foldvar
        CTRL-U  up: go up one frame
        CTRL-D  down: go down one frame

cursor position: ~
        CTRL-B  set a breakpoint on the line where the cursor is located
        CTRL-E  clear all breakpoints on the line where the cursor is located

mouse pointer position: ~
        CTRL-P  print the value of the variable defined by the mouse pointer
                position
        CTRL-X  print the value that is referenced by the address whose
                value is that of the variable defined by the mouse pointer
                position


                                                    *$cdir*
Source path:
-----------
Pyclewn automatically locates the source file with the help of gdb, by using
the debugging information stored in the file that is being debugged. This is
useful when the program to debug is the result of multiple compilation units
located in different directories.


                                                    *Csymcompletion*
Symbols completion:
-------------------
The gdb <break> and <clear> commands are set initially with file name
completion. This can be changed to completion matching the symbols of the
program being debugged, after running the|Csymcompletion|command. This is a
pyclewn command.

To minimize the number of loaded symbols and to avoid fetching the shared
libraries symbols, run the Csymcompletion command after the file is loaded
with the gdb <file> command, and before the program is run.

Note: The <break> and <clear> filename completion is not the same as gdb file
name completion for these two commands. Gdb uses the symbols found in the
program file to debug, while pyclewn uses only the file system.


                                                    *gdb-balloon*
Balloon evaluation:
-------------------
The gdb <whatis> command is used by pyclewn to get the type of the variable or
the type of the selected expression that is being hovered over by the mouse.
When it is a pointer to data, the pointer is dereferenced and its value
displayed in the vim balloon. The paramater of the "--gdb" option named
"nodereference" disables this feature: the balloon prints the pointer address
value.


                                            *project-command* *project-file*
Project file:
-------------
The pyclewn|project-command|name is "project". This command saves the current
gdb settings to a project file that may be sourced later by the gdb "source"
command.

These settings are:
    * current working directory
    * debuggee program file name
    * program arguments
    * all the breakpoints (at most one breakpoint per source line is saved)

The argument of the|project-command|is the pathname of the project file.
For example: >

    :Cproject /path/to/project

When the "--gdb" option is set with a project filename (see|pyclewn-options|),
the project file is automatically sourced when a a gdb session is started, and
the project file is automatically saved when the gdb session or vim session,
is terminated.

Note: When gdb sources the project file and cannot set a breakpoint because,
for example, it was set in a shared library that was loaded at the time the
project file was saved, gdb ignores silently the breakpoint (see gdb help on
"set breakpoint pending").


Limitations:
------------
The <define> command is not allowed. To build gdb user-defined commands in
pyclewn, edit the commands in a temporary file with vim, and load the
commands into gdb by using the gdb <source> command on this file.

The <commands> command is not allowed. To give a breakpoint a series of
commands to execute when the debuggee stops due to that breakpoint, edit the
commands in a temporary file with vim, and load the commands into gdb by using
the gdb <source> command on this file.

When pyclewn cannot setup a pseudo tty to communicate with gdb, pyclewn falls
back to pipes. In this case, the Csigint command does not work as gdb does not
handle interrupts over a pipe. Instead, one must send a SIGINT signal to the
debuggee in order to interrupt the debuggee while it is running. This can be
done from Vim with the command: >

    :!kill -SIGINT $(pgrep debuggee_process_name)

On Windows, it is not possible to interrupt gdb with the Csigint command, but
you can type <Ctl-C> in the console to interrupt the debuggee.

When setting breakpoints on an overloaded method, pyclewn bypasses the gdb
prompt for the multiple choice and sets automatically all breakpoints.

In order to set a pending breakpoint (for example in a shared library that has
not yet been loaded by gdb), you must explicitly set the breakpoint pending
mode to "on", with the command: >

    :Cset breakpoint pending on

After a "detach" gdb command, the frame sign remains highlighted because
gdb/mi considers the frame as still valid.

When answering "Abort" to a dialog after pyclewn attempts to edit a buffer and
set a breakpoint in a file already opened within another Vim session, the
breakpoint is set in gdb, but not highlighted in the corresponding buffer.
However, it is possible to|bwipeout|a buffer at any time, and load it again in
order to restore the correct highlighting of all the breakpoints in the
buffer.


Pyclewn commands:
-----------------
The|Ccommand|list includes all the gdb commands and some pyclewn specific
commands that are listed here:

    *|Ccwindow|       opens a vim quickfix window holding the list of the
                      breakpoints with their current state; the quickfix
                      window allows moving directly to any breakpoint
                      (requires the vim|+quickfix|feature)

    *|Cdbgvar|       add a watched variable or expression to the
                    (clewn)_dbgvar buffer

    *|Cdelvar|       delete a watched variable from the (clewn)_dbgvar buffer

    * Cdumprepr      print on the console pyclewn internal structures that
                     may be used for debugging pyclewn

    *|Cfoldvar|      collapse/expand the members of a watched structure or
                     class instance

    * Chelp          print on the console, help on the pyclewn specific
                     commands (those on this list) in addition to the help on
                     the debugger commands

    *|Cmapkeys|      map pyclewn keys

    *|Cproject|      save the current gdb settings to a project file

    *|Csetfmtvar|    set the output format of the value of a watched variable

    * Csigint        send a <C-C> character to the debugger to interrupt the
                     running program that is being debugged; only with gdb,
                     and when pyclewn and gdb communicate over a pseudo
                     terminal, which means on unix but not on Windows;
                     on Windows, to interrupt the debuggee, one must type
                     <C-C> in the console that is popped by gdb on debuggee
                     start up

    *|Csymcompletion|populate the break and clear commands with symbols
                     completion (only with gdb)

    * Cunmapkeys     unmap the pyclewn keys, this vim command does not invoke
                     pyclewn


List of illegal gdb commands:
-----------------------------
The following gdb commands cannot be run from pyclewn:

        commands
        complete
        define
        edit
        end
        set annotate
        set confirm
        set height
        set width
        shell

==============================================================================
6. Pdb                                              *pyclewn-pdb*


One may either start a python script and debug it, or attach to a running
python process. In both cases, once the debugging session is terminated, the
":Cdetach" or ":Cquit" command closes the netbeans session, but does not
terminate the debuggee. To kill the debuggee, use the following command at the
pdb prompt: >

    :C import sys; sys.exit(1)


Start a python script and debug it:
-----------------------------------
To debug a python script named "scriptname", run the vim command (arg1, arg2,
... being the scriptname command line arguments): >

    :Pyclewn pdb scriptname arg1 arg2 ...

One may also debug the python script being edited in vim as the current buffer
conveniently with: >

    :Pyclewn pdb %:p

To redirect the debuggee output to another tty, use the "tty" option and set
the "pyclewn_args" vim global variable before starting the script. For
example: >

    :let g:pyclewn_args="--tty=/dev/pts/4"


Attach to a python process and debug it: >
----------------------------------------
To debug a python process after having attached to it, first insert the
following statement in the debuggee source code before starting it: >

    import clewn.vim as vim; vim.pdb()

By default, the debuggee is stopped at the first statement following the call
to vim.pdb(). To let the debuggee run instead, then use the "run" option: >

    import clewn.vim as vim; vim.pdb(run=True)

Next, attach to the process and start the debugging session by running the vim
command: >

    :Pyclewn pdb

Note:
When the pyclewn installation has been made following the "home scheme" (see
INSTALL) and in order to have python find the clewn package, one must set the
PYTHONPATH environment variable to include the python home library pathname.
For example with bash, run the script as: >

 PYTHONPATH=$HOME/lib/python python script_pathname


Pdb commands:
-------------
The commands "interrupt", "detach" and "threadstack" are new pdb commands and
are the only commands that are available at the "[running...]" prompt when the
debuggee is running. Use the "help" command (and completion on the first
argument of the help command) to get help on each command.

The following list describes the pdb commands that are new or behave
differently from the pdb commands of the Python standard library:

                                                    *Cinterrupt*
interrupt
    This command interrupts the debuggee and is available from the
    "[running...]" prompt.
    The debuggee cannot be interrupted when blocked in a python C call, for
    example in a blocking I/O read. One need to use the gdb debugger in that
    case. Note that the "threadstack" command is useful to find out why the
    debuggee cannot be interrupted.

                                                    *Cdetach*
detach
    This command terminates the debugging session by closing the netbeans
    socket. The debuggee is free to run and does not stop at the breakpoints.
    To start another debugging session, run the command: >

        :Pyclewn pdb

.   The breakpoints becomes effective again when the new session starts up.
    Available from the "[running...]" prompt and from the pdb prompt.

                                                    *Cquit*
quit
    This command terminates the debugging session by closing the netbeans
    socket, and removes the python trace function. The pyclewn thread in
    charge of handling netbeans connection terminates and it is not possible
    anymore to debug the process. Since there is no trace function, the
    breakpoints are ineffective and the process performance is not impaired
    anymore by the debugging overhead.

                                                    *Cthreadstack*
threadstack
    The command uses the sys._current_frames() function from the standard
    library to print a stack of the frames for all the threads.
    The function sys._current_frames() is available since python 2.5.
    Available from the "[running...]" prompt and from the pdb prompt.

                                                    *Cclear*
clear
    This command is the same as the Python standard library "clear" command,
    except it requires at least one parameter and therefore, it is not
    possible to clear all the breakpoints in one shot with the "clear" command
    without parameters.

the prefix alone:
    There is no "!" pdb command as in the Python standard library since Vim
    does not allow this character in a command name. However, the equivalent
    way to execute a python statement in the context of the current frame is
    with the command prefix alone, for example: >

        :C global list_options; list_options = ['-l']
        :C import sys; sys.exit(1)

.   The first word of the statement must not be a pdb command and will be
    expanded if it is an alias.

    Notes: Changes in the "locals" dictionary of the current frame are lost
    when the frame is changed with the "up" or "down" command.  This is a
    "pdb" Python bug, see http://bugs.python.org/issue9633.  The changes are
    not lost when the "step" command is run before the "up" or "down" command.

not implemented:
    The following pdb commands are not implemented: "list", "commands".


                                                    *pdb-pdbrc*
The initialisation file .pdbrc:
-------------------------------
This file is read at initialisation and its commands are executed on startup.
See the pdb python documentation for the location of this file. Breakpoints
can be set through this file, or aliases may be defined. One useful alias
entered in the file would be for example: >

    alias kill import sys; sys.exit(1)

So that the debuggee may be killed with the command: >

    :C kill


                                                    *pdb-keys*
List of the pdb default key mappings:
-------------------------------------
These keys are mapped after the|Cmapkeys|vim command is run.

        CTRL-Z  interrupt the pdb process
        B       list all breaks, including for each breakpoint, the number of
                times that breakpoint has been hit, the current ignore count,
                and the associated condition if any
        A       print the argument list of the current function
        S       step
        CTRL-N  next: next source line, skipping all function calls
        R       continue execution until the current function returns
        C       continue
        W       where
        CTRL-U  up: go up one frame
        CTRL-D  down: go down one frame

cursor position: ~
        CTRL-B  set a breakpoint on the line where the cursor is located
        CTRL-E  clear all breakpoints on the line where the cursor is located

mouse pointer position: ~
        CTRL-P  print the value of the selected expression defined by the
                mouse pointer position


Pyclewn commands:
-----------------
The|Ccommand|list includes pdb commands and some pyclewn specific commands
that are listed here:

    * Cdumprepr      print on the console pyclewn internal structures that
                     may be used for debugging pyclewn

    *|Cmapkeys|      map pyclewn keys

    * Cunmapkeys     unmap the pyclewn keys, this vim command does not invoke
                     pyclewn


Troubleshooting:
----------------
* Pyclewn error messages can be logged in a file with the "--file" option.
  When starting the debuggee from vim, use the "pyclewn_args" vim global
  variable before starting the script: >

    :let g:pyclewn_args="--file=/path/to/logfile"

When attaching to a python process, use the corresponding keyword argument: >

    import clewn.vim as vim; vim.pdb(file='/path/to/logfile')


* To conduct two debugging sessions simultaneously (for example when debugging
  pyclewn with pyclewn), change the netbeans socket port with the
  "pyclewn_connection" vim global variable before starting the script: >

    :let g:pyclewn_connection="localhost:3220:foo"

And change the corresponding keyword argument: >

    import clewn.vim as vim; vim.pdb(netbeans='localhost:3220:foo')


Limitations:
------------
When the debuggee is running multiple threads, the current I/O redirection
scheme implemented by pyclewn may cause those non-debugged threads to write to
the clewn console instead of sys.stdout. Note that this may be fixed in a
later pyclewn release, by using the stdout redirection introduced by the "pdb"
package in python 2.5.

==============================================================================
7. Windows                                          *pyclewn-windows*


Installation:
-------------
See http://pyclewn.wiki.sourceforge.net/install for installing pyclewn on
Windows.

If pyclewn does not start once installed, edit the desktop shortcut and add
"-l debug -f \path\to\logfile.txt" to the command line. Check the content of
logfile.txt.

When pyclewn stops with the following error in the logfile:

    gdb  CRITICAL cannot start gdb as "C:\msys\mingw\bin\gdb.exe"

This means you have to update the shortcut command line with the correct path
to gdb.


Interrupt the debuggee:
-----------------------
Gdb is started with the "console-new" gdb variable set to on. When you start
the debuggee, gdb pops up the console attached to the debuggee. You can type
<Ctl-C> in the console to interrupt the debuggee.

If this console bothers you, run the following gdb command: >

  :Cset new-console off


Escape quotes:
--------------
The following is true as well for pyclewn on unix, but since pathnames
containing space characters are common on Windows, it may be useful to recall
that quotes must be escaped on Vim command line.
For example one could write: >

    :Cfile \"\path with space\to\foobar.exe\"

==============================================================================
8. Key mappings                                     *pyclewn-mappings*


All|Ccommand|can be mapped to vim keys using the vim|:map-commands|.
For example, to set a breakpoint at the current cursor position: >

    :map <F8> :exe "Cbreak " . expand("%:p") . ":" . line(".")<CR>

Or to print the value of the variable under the cursor: >

    :map <F8> :exe "Cprint " . expand("<cword>") <CR>


                                                    *Cmapkeys*
Pyclewn key mappings:
---------------------
This section describes another mapping mechanism where pyclewn maps vim keys
by reading a configuration file. This is done when the|Cmapkeys|vim command is
run. The pyclewn keys mapping is mostly useful for the pyclewn casual user.
When the configuration file cannot be found, pyclewn sets the default key
mappings. See|gdb-keys|for the list of default key mappings for gdb
and|pdb-keys|for the list of default key mappings for pdb.

Please note that pyclewn relies on the vim|balloon-eval|feature to get the
text under the mouse position when expanding the ${text} macro. This feature
is not available with vim console. So in this case you must build your own
key mapping as in the above example.

The configuration file is named .pyclewn_keys.{debugger}, where debugger is
the name of the debugger. The default placement for this file is
$CLEWNDIR/.pyclewn_keys.{debugger}, or $HOME/.pyclewn_keys.{debugger}.

To customize pyclewn key mappings copy the configurations files found in the
distribution to the proper directory: >

    cp runtime/.pyclewn_keys.gdb        $CLEWNDIR

or >

    cp runtime/.pyclewn_keys.gdb        $HOME

The comments in the configuration file explain how to customize the key
mappings.

On Windows, the .pyclewn_keys.{debugger} configuration files are found in the
directory $VIM\vimfiles\macros. The value of $VIM can be obtained by running
the following command in Vim: >

    :echo $VIM

Copy these files to the $CLEWNDIR or $HOME directory, and customize the key
mappings.

==============================================================================
9. Watched variables                                *pyclewn-variable*


The Watched Variables feature is available with the gdb debugger. The vim
watched variables buffer is named "(clewn)_dbgvar".

                                                    *Cdbgvar*
The|Cdbgvar|command is used to create a gdb watched variable in the variables
buffer from any valid expression. A valid expression is an expression that is
valid in the current frame.
The argument of the|Cdbgvar|pyclewn command is the expression to be watched.
For example, to create a watched variable for the expression "len - max":
>
    :Cdbgvar len - max

Upon creation, the watched variable is given a name by gdb, for example:
<var1>.
The watched variables buffer, "(clewn)_dbgvar", is created upon creation of
the first watched variable. It is created but not displayed in a window.
To display "(clewn)_dbgvar" just after the creation of the first variable: >
    :e #
or >
    CTL-^

Use the following command to find the number N of the "(clewn)_dbgvar"
buffer: >
    :ls

Knowing N, the following commands display the "(clewn)_dbgvar" buffer: >
    :Nb
or >
    N CTL-^

To split the current window and display "(clewn)_dbgvar": >
    :Nsb
.

                                                    *Cfoldvar*
When the watched variable is a structure or class instance, it can be expanded
with the|Cfoldvar|pyclewn command to display all its members and their values
as children watched variables.
The argument of the|Cfoldvar|command is the line number of the watched
variable to expand, in the watched variable window.
For example: >

    :Cfoldvar 1

The|Cfoldvar|command is meant to be used in a key mapping. This is the 'X' key
when using pyclewn key mappings, or one can use the following mapping:
>
    :map <F8> :exe "Cfoldvar " . line(".")<CR>

The watched variable can also be collapsed with the|Cfoldvar|command.


                                                    *Cdelvar*
A gdb watched variable can be deleted with the|Cdelvar|pyclewn command.
The argument of the|Cdelvar|command is the name of the variable as given by
gdb upon creation.
For example: >

    :Cdelvar var1

When the watched variable is a structure or class instance and it has been
expanded, all its children are also deleted.


                                                    *Csetfmtvar*
Set the output format of the value of the watched variable <name>
to be <format>: >

    :Csetfmtvar <name> <format>

Parameter <name> is the gdb/mi name of the watched variable or one of its
children.
Parameter <format> is one of the strings in the following list:

    {binary | decimal | hexadecimal | octal | natural}

The "natural" format is the default format chosen automatically based on the
variable type (like "decimal" for an int, "hexadecimal" for pointers, etc.).
For a variable with children, the format is set only on the variable itself,
and the children are not affected.

Note: The setting of the format of a child watched variable is lost after
folding one of its parents (because the child is actually not watched anymore
by gdb after the folding).


Highlighting:
-------------
When the value of a watched variable has changed, it is highlighted with the
"Special" highlight group.

When a watched variable becomes out of scope, it is highlighted with the
"Comment" highlight group.

The foreground and background colors used by these highlight groups are setup
by the|:colorscheme|currently in use.

==============================================================================
10. Extending pyclewn                                *pyclewn-extending*


NAME
    debugger

FILE
    clewn/debugger.py

DESCRIPTION
    This module provides the basic infrastructure for using Vim as a
    front-end to a debugger.

    The basic idea behind this infrastructure is to subclass the 'Debugger'
    abstract class, list all the debugger commands and implement the
    processing of these commands in 'cmd_<command_name>' methods in the
    subclass. When the method is not implemented, the processing of the
    command is dispatched to the 'default_cmd_processing' method. These
    methods may call the 'Debugger' API methods to control Vim. For example,
    'add_bp' may be called to set a breakpoint in a buffer in Vim, or
    'console_print' may be called to write the output of a command in the
    Vim debugger console.

    The 'Debugger' subclass is made available to the user after adding an
    option to the 'parse_options' method in the 'Vim' class, see vim.py.

    The 'Simple' class in simple.py provides a simple example of a fake
    debugger front-end.

CLASSES
    __builtin__.object
        Debugger

    class Debugger(__builtin__.object)
     |  Abstract base class for pyclewn debuggers.
     |
     |  The debugger commands received through netbeans 'keyAtPos' events
     |  are dispatched to methods whose name starts with the 'cmd_' prefix.
     |
     |  The signature of the cmd_<command_name> methods are:
     |
     |      cmd_<command_name>(self, str cmd, str args)
     |          cmd: the command name
     |          args: the arguments of the command
     |
     |  The '__init__' method of the subclass must call the '__init__'
     |  method of 'Debugger' as its first statement and forward the method
     |  parameters as an opaque list. The __init__ method must update the
     |  'cmds' and 'mapkeys' dict attributes with its own commands and key
     |  mappings.
     |
     |  Instance attributes:
     |      cmds: dict
     |          The debugger command names are the keys. The values are the
     |          sequence of available completions on the command first
     |          argument. The sequence is possibly empty, meaning no
     |          completion. When the value is not a sequence (for example
     |          None), this indicates file name completion.
     |      mapkeys: dict
     |          Key names are the dictionary keys. See the 'keyCommand'
     |          event in Vim netbeans documentation for the definition of a
     |          key name. The values are a tuple made of two strings
     |          (command, comment):
     |              'command' is the debugger command mapped to this key
     |              'comment' is an optional comment
     |          One can use template substitution on 'command', see the file
     |          runtime/.pyclewn_keys.template for a description of this
     |          feature.
     |      options: optparse.Values
     |          The pyclewn command line parameters.
     |      started: boolean
     |          True when the debugger is started.
     |      closed: boolean
     |          True when the debugger is closed.
     |      pyclewn_cmds: dict
     |          The subset of 'cmds' that are pyclewn specific commands.
     |      __nbsock: netbeans.Netbeans
     |          The netbeans asynchat socket.
     |      _jobs: list
     |          list of pending jobs to run on a timer event in the
     |          dispatch loop
     |      _jobs_enabled: bool
     |          process enqueued jobs when True
     |      _last_balloon: str
     |          The last balloonText event received.
     |      _prompt_str: str
     |          The prompt printed on the console.
     |      _consbuffered: boolean
     |          True when output to the vim debugger console is buffered
     |
     |  Methods defined here:
     |
     |  __init__(self, options)
     |      Initialize instance variables and the prompt.
     |
     |  __str__(self)
     |      Return the string representation.
     |
     |  add_bp(self, bp_id, pathname, lnum)
     |      Add a breakpoint to a Vim buffer at lnum.
     |
     |      Load the buffer in Vim and set an highlighted sign at 'lnum'.
     |
     |      Method parameters:
     |          bp_id: object
     |              The debugger breakpoint id.
     |          pathname: str
     |              The absolute pathname to the Vim buffer.
     |          lnum: int
     |              The line number in the Vim buffer.
     |
     |  balloon_text(self, text)
     |      Process a netbeans balloonText event.
     |
     |      Used when 'ballooneval' is set and the mouse pointer rests on
     |      some text for a moment.
     |
     |      Method parameter:
     |          text: str
     |              The text under the mouse pointer.
     |
     |  close(self)
     |      Close the debugger and remove all signs in Vim.
     |
     |  cmd_dumprepr(self, *args)
     |      Print debugging information on netbeans and the debugger.
     |
     |  cmd_help(self, *args)
     |      Print help on all pyclewn commands in the Vim debugger
     |      console.
     |
     |  cmd_mapkeys(self, *args)
     |      Map the pyclewn keys.
     |
     |  cmd_unmapkeys(self, *args)
     |      Unmap the pyclewn keys.
     |
     |      This is actually a Vim command and it does not involve pyclewn.
     |
     |  console_print(self, format, *args)
     |      Print a format string and its arguments to the console.
     |
     |      Method parameters:
     |          format: str
     |              The message format string.
     |          args: str
     |              The arguments which are merged into 'format' using the
     |              python string formatting operator.
     |
     |  debugger_background_jobs = _newf(self, *args, **kwargs)
     |      The decorated method.
     |
     |  default_cmd_processing(self, cmd, args)
     |      Fall back method for commands not handled by a 'cmd_<name>'
     |      method.
     |
     |      This method must be implemented in a subclass.
     |
     |      Method parameters:
     |          cmd: str
     |              The command name.
     |          args: str
     |              The arguments of the command.
     |
     |  delete_all(self, pathname=None, lnum=None)
     |      Delete all the breakpoints in a Vim buffer or in all buffers.
     |
     |      Delete all the breakpoints in a Vim buffer at 'lnum'.
     |      Delete all the breakpoints in a Vim buffer when 'lnum' is None.
     |      Delete all the breakpoints in all the buffers when 'pathname' is
     |      None.
     |
     |      Method parameters:
     |          pathname: str
     |              The absolute pathname to the Vim buffer.
     |          lnum: int
     |              The line number in the Vim buffer.
     |
     |  delete_bp(self, bp_id)
     |      Delete a breakpoint.
     |
     |      The breakpoint must have been already set in a Vim buffer with
     |      'add_bp'.
     |
     |      Method parameter:
     |          bp_id: object
     |              The debugger breakpoint id.
     |
     |  get_console(self)
     |      Return the console.
     |  
     |  get_lnum_list(self, pathname)
     |      Return a list of line numbers of all enabled breakpoints in a
     |      Vim buffer.
     |
     |      A line number may be duplicated in the list.
     |      This is used by Simple and may not be useful to other debuggers.
     |
     |      Method parameter:
     |          pathname: str
     |              The absolute pathname to the Vim buffer.
     |
     |  netbeans_detach(self)
     |      Close the netbeans session.
     |  
     |  post_cmd(self, cmd, args)
     |      The method called after each invocation of a 'cmd_<name>'
     |      method.
     |
     |      This method must be implemented in a subclass.
     |
     |      Method parameters:
     |          cmd: str
     |              The command name.
     |          args: str
     |              The arguments of the command.
     |
     |  pre_cmd(self, cmd, args)
     |      The method called before each invocation of a 'cmd_<name>'
     |      method.
     |
     |      This method must be implemented in a subclass.
     |
     |      Method parameters:
     |          cmd: str
     |              The command name.
     |          args: str
     |              The arguments of the command.
     |
     |  print_prompt = prompt(self)
     |  
     |  prompt(self)
     |      Print the prompt in the Vim debugger console.
     |
     |  remove_all(self)
     |      Remove all annotations.
     |      
     |      Vim signs are unplaced.
     |      Annotations are not deleted.
     |  
     |  set_nbsock(self, nbsock)
     |      Set the netbeans socket.
     |  
     |  show_balloon(self, text)
     |      Show 'text' in the Vim balloon.
     |
     |      Method parameter:
     |          text: str
     |              The text to show in the balloon.
     |
     |  show_frame(self, pathname=None, lnum=1)
     |      Show the frame highlighted sign in a Vim buffer.
     |
     |      The frame sign is unique.
     |      Remove the frame sign when 'pathname' is None.
     |
     |      Method parameters:
     |          pathname: str
     |              The absolute pathname to the Vim buffer.
     |          lnum: int
     |              The line number in the Vim buffer.
     |
     |  switch_map(self, map)
     |      Attach nbsock to another asyncore map.
     |  
     |  timer(self, callme, delta)
     |      Schedule the 'callme' job at 'delta' time from now.
     |
     |      The timer granularity is LOOP_TIMEOUT, so it does not make sense
     |      to request a 'delta' time less than LOOP_TIMEOUT.
     |
     |      Method parameters:
     |          callme: callable
     |              the job being scheduled
     |          delta: float
     |              time interval
     |
     |  update_bp(self, bp_id, disabled=False)
     |      Update the enable/disable state of a breakpoint.
     |
     |      The breakpoint must have been already set in a Vim buffer with
     |      'add_bp'.
     |      Return True when successful.
     |
     |      Method parameters:
     |          bp_id: object
     |              The debugger breakpoint id.
     |          disabled: bool
     |              When True, set the breakpoint as disabled.
     |
     |  update_dbgvarbuf(self, getdata, dirty, lnum=None)
     |      Update the variables buffer in Vim.
     |
     |      Update the variables buffer in Vim when one the following
     |      conditions is
     |      True:
     |          * 'dirty' is True
     |          * the content of the Vim variables buffer and the content of
     |            pyclewn 'dbgvarbuf' are not consistent after an error in the
     |            netbeans protocol occured
     |      Set the Vim cursor at 'lnum' after the buffer has been updated.
     |
     |      Method parameters:
     |          getdata: callable
     |              A callable that returns the content of the variables
     |              buffer as a string.
     |          dirty: bool
     |              When True, force updating the buffer.
     |          lnum: int
     |              The line number in the Vim buffer.
     |
     |  vim_script_custom(self, prefix)
     |      Return debugger specific Vim statements as a string.
     |
     |      A Vim script is run on Vim start-up, for example to define all
     |      the debugger commands in Vim. This method may be overriden to
     |      add some debugger specific Vim statements or functions to this
     |      script.
     |
     |      Method parameter:
     |          prefix: str
     |              The prefix used for the debugger commands in Vim.
     |

FUNCTIONS
    restart_timer(timeout)
        Decorator to re-schedule the method at 'timeout', after it has run.

==============================================================================
vim:tw=78:ts=8:ft=help:norl:et:cole=0
after/syntax/qf.vim	[[[1
21
" Vim after syntax file
" Language:     Quickfix window
" Maintainer:   fanhe <fanhed@163.org>
" Create:       2011-07-04

setlocal nowrap

" A bunch of useful C keywords
syn match   qfFileName  "^[^|]*" nextgroup=qfSeparator
syn match   qfSeparator "|" nextgroup=qfLineNr contained
syn match   qfLineNr    "[^|]*|\s*"he=e-2 contained nextgroup=qfError,qfWarning
syn match   qfError     "error:.\+" contained
syn match   qfError     "undefined reference to .\+" contained
syn match   qfWarning   "warning:.\+" contained

" The default highlighting.
hi def link qfFileName  Directory
hi def link qfLineNr    LineNr
hi def link qfError     Error
hi def link qfWarning   WarningMsg

autoload/vlutils.vim	[[[1
304
" Description:  Common function utilities
" Maintainer:   fanhe <fanhed@163.com>
" License:      GPLv2
" Create:       2011-07-15
" Last Change:  2011-07-15

" 初始化变量, 仅在没有变量定义时才赋值
" Param1: sVarName - 变量名, 必须是可作为标识符的字符串
" Param2: defaultVal - 默认值, 可为任何类型
" Return: 1 表示赋值为默认, 否则为 0
function! vlutils#InitVariable(sVarName, defaultVal) "{{{2
    if !exists(a:sVarName)
        let {a:sVarName} = a:defaultVal
        return 1
    endif
    return 0
endfunction
"}}}
" 与 exec 命令相同，但是运行时 set eventignore=all
" 主要用于“安全”地运行某些命令，例如窗口跳转
function! vlutils#Exec(sCmd) "{{{2
    try
        exec 'noautocmd' a:sCmd
    catch
    endtry
endfunction
"}}}
function! vlutils#NormalizeCmdArg(sCmd) "{{{2
    return escape(a:sCmd, ' ')
endfunction
"}}}
" 打开指定缓冲区的窗口数目
function! vlutils#BufInWinCount(nBufNr) "{{{2
    let nCount = 0
    let nWinNr = 1
    while 1
        let nWinBufNr = winbufnr(nWinNr)
        if nWinBufNr < 0
            break
        endif
        if nWinBufNr ==# a:nBufNr
            let nCount += 1
        endif
        let nWinNr += 1
    endwhile

    return nCount
endfunction
"}}}
" 判断窗口是否可用
" 可用 - 即可用其他窗口替换本窗口而不会令本窗口的内容消失
function! vlutils#IsWindowUsable(nWinNr) "{{{2
    let nWinNr = a:nWinNr
	" 特殊窗口，如特殊缓冲类型的窗口、预览窗口
    let bIsSpecialWindow = getwinvar(nWinNr, '&buftype') !=# ''
                \|| getwinvar(nWinNr, '&previewwindow')
    if bIsSpecialWindow
        return 0
    endif

	" 窗口缓冲是否已修改
    let bModified = getwinvar(nWinNr, '&modified')

	" 如果可允许隐藏，则无论缓冲是否修改
    if &hidden
        return 1
    endif

	" 如果缓冲区没有修改，或者，已修改，但是同时有其他窗口打开着，则表示可用
	if !bModified || vlutils#BufInWinCount(winbufnr(nWinNr)) >= 2
		return 1
	else
		return 0
	endif
endfunction
"}}}
" 获取第一个"可用"(常规, 非特殊)的窗口
" 特殊: 特殊的缓冲区类型、预览缓冲区、已修改的缓冲并且不能隐藏
" Return: 窗口编号 - -1 表示没有可用的窗口
function vlutils#GetFirstUsableWinNr() "{{{2
    let i = 1
    while i <= winnr("$")
		if vlutils#IsWindowUsable(i)
			return i
		endif

        let i += 1
    endwhile
    return -1
endfunction
"}}}
" 获取宽度最大的窗口编号
function! vlutils#GetMaxWidthWinNr() "{{{2
	let i = 1
	let nResult = 0
	let nMaxWidth = 0
	while i <= winnr("$")
		let nCurWidth = winwidth(i)
		if nCurWidth > nMaxWidth
			let nMaxWidth = nCurWidth
			let nResult = i
		endif
		let i += 1
	endwhile

	return nResult
endfunction
"}}}
" 获取高度最大的窗口编号
function! vlutils#GetMaxHeightWinNr() "{{{2
	let i = 1
	let nResult = 0
	let nMaxHeight = 0
	while i <= winnr("$")
		let nCurHeight = winheight(i)
		if nCurHeight > nMaxHeight
			let nMaxHeight = nCurHeight
			let nResult = i
		endif
		let i += 1
	endwhile

	return nResult
endfunction
"}}}
" '优雅地'打开一个文件, 在需要的时候会分割窗口
" 水平分割和垂直分割的具体方式由 'splitbelow' 和 'splitright' 选项控制
" vlutils#OpenFile... 系列函数的分割都是这样控制的
" 只有一个窗口时会垂直分割窗口, 否则是水平分割
" 规则:
" 1. 需要打开的文件已经在某个窗口打开, 跳至那个窗口, 结束
" 2. 如果上一个窗口(wincmd p)可用, 用此窗口打开文件, 结束
" 3. 如果没有可用的窗口, 且窗口数为 1, 垂直分割打开
" 4. 如果没有可用的窗口, 且窗口数多于 1, 跳至宽度最大的窗口水平分割打开
function! vlutils#OpenFile(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    " 跳回原始窗口的算法
    " 1. 先保存此窗口的编号, 再保存此窗口对应的缓冲的编号
    " 2. 打开文件后, 检查保存的窗口是否对应原来的缓冲编号, 如果对应, 跳回,
    "    否则, 继续算法
    " 3. 查找到对应保存的缓冲编号的窗口, 若返回有效编号, 跳回, 否则, 不操作
    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    let nBufWinNr = bufwinnr('^' . sFile . '$')
    if nBufWinNr != -1
        " 文件已经在某个窗口中打开, 直接跳至那个窗口
        exec nBufWinNr 'wincmd w'
    else
        " 文件没有在某个窗口中打开
        let nPrevWinNr = winnr('#')
        if !vlutils#IsWindowUsable(nPrevWinNr)
            if vlutils#GetFirstUsableWinNr() == -1
                " 上一个窗口不可用并且没有可用的窗口, 需要分割窗口
                if winnr('$') == 1
                    " 窗口总数为 1, 垂直分割
                    " TODO: 分割方式应该可控制...
                    exec 'vsplit' vlutils#NormalizeCmdArg(sFile)
                else
                    "有多个窗口, 找一个宽度最大的窗口然后水平分割窗口
                    let nMaxWidthWinNr = vlutils#GetMaxWidthWinNr()
                    call vlutils#Exec(nMaxWidthWinNr . 'wincmd w')
                    exec 'split ' . vlutils#NormalizeCmdArg(sFile)
                endif
            else
                call vlutils#Exec(vlutils#GetFirstUsableWinNr() . "wincmd w")
                exec 'edit' vlutils#NormalizeCmdArg(sFile)
            endif
        else
            call vlutils#Exec('wincmd p')
            exec 'edit' vlutils#NormalizeCmdArg(sFile)
        endif
    endif

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#Exec(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#Exec(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" 在新的标签页中打开文件
" OptParam: 默认 0, 1 表示不切换到新标签那里, 即保持光标在原始位置
function! vlutils#OpenFileInNewTab(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nCurTabNr = tabpagenr()

    exec 'tabedit' vlutils#NormalizeCmdArg(sFile)

    if bKeepCursorPos
        " 跳回原来的标签
        " 为什么用 ':tabnext' 也可以? 理应用 ':tab'
        exec 'tabnext' nCurTabNr
    endif
endfunction
"}}}
" '优雅地'水平分割打开文件
function! vlutils#OpenFileSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    " 跳到宽度最大的窗口再水平分割
    call vlutils#Exec(vlutils#GetMaxWidthWinNr() . 'wincmd w')
    exec 'split' vlutils#NormalizeCmdArg(sFile)

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#Exec(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#Exec(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" '优雅地'垂直分割打开文件
function! vlutils#OpenFileVSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    " 跳到宽度最大的窗口再水平分割
    call vlutils#Exec(vlutils#GetMaxHeightWinNr() . 'wincmd w')
    exec 'vsplit' vlutils#NormalizeCmdArg(sFile)

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#Exec(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#Exec(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" 简单的计时器静态类
" NOTE: 这个类第一次调用时不能直接调用方法, 无奈
let vlutils#Timer = {'t1': 0, 't2': 0} "{{{1
function! vlutils#Timer.Start() "{{{2
	let self.t1 = reltime()
endfunction

function! vlutils#Timer.End() "{{{2
	let self.t2 = reltime()
endfunction

function! vlutils#Timer.EchoMes() "{{{2
	echom string((str2float(reltimestr(self.t2)) 
				\- str2float(reltimestr(self.t1))))
endfunction

function! vlutils#Timer.EndEcho() "{{{2
	call self.End()
	call self.EchoMes()
endfunction
"}}}1

" vim:fdm=marker:fen:fdl=1:et:ts=4:sw=4:sts=4:
autoload/omnicpp/resolvers.vim	[[[1
2171
" Description:  Omnicpp completion resolving functions
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 15
" License:      GPLv2

" 基本数据结构
"
" TypeInfo, 字典
" {
" 'name':   <name>
" 'til':    <template instantiated list>
" 'types':  [<single type>, ...]
" }

" VarInfo, 字典
" {
" 'kind': <'container'|'variable'|'function'|'cast'|'unknown'>
" 'name': <name>
" 'tag': <tag>
" 'typeinfo': <TypeInfo>
" }

" PrmtInfo(模版参数, 函数参数) 字典
" {
" 'kind': <'typename'|'class'|Non Type>
" 'name': <parameter name>
" 'default': <default value>
" }
function! s:StripString(s) "{{{2
    let s = substitute(a:s, '^\s\+', '', 'g')
    let s = substitute(s, '\s\+$', '', 'g')
    return s
endfunc
"}}}
function! s:NewPrmtInfo() "{{{2
    return {'kind': '', 'name': '', 'default': ''}
endfunc
"}}}
function! s:NewTypeInfo() "{{{2
    return {'name': '', 'til': [], 'types': []}
endfunc
"}}}
function! s:NewOmniScope() "{{{2
    return {'kind': 'unknown', 'name': '', 'til': []}
endfunc
"}}}
" 获取全能补全请求前的语句的 OmniScopeStack
" 以下情况一律先清理所有不必要的括号, 清理 [], 把 C++ 的 cast 转为 C 形式
" case01. A::B C::D::|
" case02. A::B()->C().|    orig: A::B::C(" a(\")z ", '(').|
" case03. A::B().C->|
" case04. A->B().|
" case05. A->B.|
" case06. Z Y = ((A*)B)->C.|
" case07. (A*)B()->C.|
" case08. static_cast<A*>(B)->C.|      -> 处理成标准 C 的形式 ((A*)B)->C.|
" case09. A(B.C()->|)
"
" case10. ::A->|
" case11. A(::B.|)
" case12. (A**)::B.|
"
" Return: OmniInfo
" OmniInfo
" {
" 'omniss': <OmniSS>
" 'precast': <this|<global>|precast>
" }
"
" 列表 OmniSS, 每个条目为 OmniScope
" 'til' 一般在 'kind' 为 'container' 时才有效
" OmniScope
" {
" 'kind': <'container'|'variable'|'function'|'cast'|'unknown'>
" 'name': <name>    <- 必然是单元类型 eg. A<a,b,c>
" 'til' : <template initialization list>
" 'tag' : {}        <- 在解析的时候添加
" 'typeinfo': {}    <- 在解析的时候添加
" }
"
" 如 case3, [{'kind': 'container', 'name': 'A'},
"            {'kind': 'function', 'name': 'B'},
"            {'kind': 'variable', 'name': 'C'}]
" 如 case6, [{'kind': 'variable', 'name': 'B'},
"            {'kind': 'variable', 'name': 'C'}]
"
" 判断 cast 的开始: 1. )单词, 2. )(
" 判断 precast: 从 )( 匹配的结束位置寻找匹配的 ), 如果匹配的 ')' 右边也为 ')'
" 判断 postcast: 从 )( 匹配的结束位置寻找匹配的 ), 如果匹配的 ')' 右边不为 ')'
" TODO: 
" 1. A<B>::C<D, E>::F g; g.|
" 2. A<B>::C<D, E>::F.g.| (g 为静态变量)
"
" 1 的方法, 需要记住整条路径每个作用域的 til
" 2 的方法, OmniInfo 增加 til 域
function! omnicpp#resolvers#GetOmniInfo(...) "{{{2
    if a:0 > 0
        if type(a:1) == type('')
            let lTokens = omnicpp#tokenizer#Tokenize(
                        \omnicpp#utils#SimplifyCodeForOmni(a:1))
        elseif type(a:1) == type([])
            let lTokens = a:1
        else
            return []
        endif
    else
        let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor(1)
    endif

    let lRevTokens = reverse(lTokens[:])

    let lOmniSS = []
    " 'til' 对应于 'precast' 的值
    let dOmniInfo = {'omniss': [], 'precast': '', 'til': []}

    " 反向遍历分析
    let idx = 0
    let nLen = len(lRevTokens)

    " 0 -> 期望操作符 ('->', '.', '::')
    " 1 -> 期望单词 ( A|:: )
    " 2 -> 期望左括号 ( A(|). )
    let nState = 0

    " 只有四种需要分辨的符号
    " 1. 作用域或成员操作符 ('::', '.', '->')
    " 2. 单词
    " 3. 左括号
    " 4. 右括号
    let dPrevToken = {'kind': '', 'value': ''}
    let til = [] " 保存最近一次分析的 til
    while idx < nLen
        let dToken = lRevTokens[idx]

        if dToken.kind == 'cppOperatorPunctuator' 
                    \&& dToken.value =~ '->\|::\|\.'
            if nState == 0
                " 期望操作符, 遇到操作符
                " 切换状态
                let nState = 1 " 期望单词
            elseif nState == 1
                " 期望单词, 遇到操作符
                " 语法错误
                echom 'syntax error: ' . dToken.value
                let lOmniSS = []
                break
            elseif nState == 2
                " 括号状态都已经私自处理完, 这里不再需要了
            endif
        elseif dToken.kind == 'cppWord' 
                    \|| (dToken.kind == 'cppKeyword' && dToken.value ==# 'this')
            if nState == 0
                " 期望操作符, 遇到单词
                " 结束. eg A::B C::|
                "             ^
                break
            elseif nState == 1
                " 成功获取一个单词
                let dOmniScope = s:NewOmniScope()
                let dOmniScope.name = dToken.value
                if dPrevToken.value == '::'
                    let dOmniScope.kind = 'container'
                    let dOmniScope.til = til
                    let til = []
                elseif dPrevToken.value =~# '->\|\.'
                    let dOmniScope.kind = 'variable'
                else
                endif

                " 切换至期望操作符
                let nState = 0

                if dOmniScope.name ==# 'this'
                    let dOmniInfo.precast = 'this'
                else
                    let lOmniSS = [dOmniScope] + lOmniSS
                endif
            elseif nState == 2
                " 括号状态都已经私自处理完, 这里不再需要了
            endif
        elseif dToken.kind == 'cppOperatorPunctuator' && dToken.value == '('
            " eg1: A(B.C()->|)
            "      ^
            " eg2: A(::B.C()->|)
            "      ^
            if dPrevToken.kind == 'cppOperatorPunctuator' 
                        \&& dPrevToken.value == '::'
                let dOmniInfo.precast = '<global>'
            endif
            " 结束
            break
        elseif dToken.kind == 'cppOperatorPunctuator' && dToken.value == ')'
            if nState == 0
                " 期待操作符
                " 遇到右括号
                " 必定是一个 postcast
                " 无须处理, 直接完成
                " eg. (A*)B->|
                "        ^
                break
            elseif nState == 1
                " 期待单词
                " 遇到右括号
                " 可能是 precast 或者 postcast((A)::B.|) 或者是一个函数
                "                                ^
                " 判定是否函数
                if lRevTokens[idx+1].value == '(' 
                            \&& lRevTokens[idx+2].kind == 'cppWord'
                    " 是函数
                    let dOmniScope = s:NewOmniScope()
                    let dOmniScope.kind = 'function'
                    let dOmniScope.name = lRevTokens[idx+2].value
                    let lOmniSS = [dOmniScope] + lOmniSS

                    let idx = idx + 2
                    let dToken = lRevTokens[idx]
                    " 切换至期待操作符
                    let nState = 0
                elseif (lRevTokens[idx+1].kind == 'cppWord' 
                            \|| lRevTokens[idx+1].value ==# ')')
                            \   && dPrevToken.value != '::'
                    " 是一个 precast
                    " eg. ((A*)B.b)->C.|
                    "            ^|
                    " eg. ((A*)B.b())->C.|
                    "              ^|
                    " eg. static_cast<A *>(B.b())->C.|
                    "                          ^|

                    " 先添加变量 scope
                    let dOmniScope = s:NewOmniScope()
                    let dOmniScope.kind = 'variable'
                    "let dOmniScope.name = lRevTokens[idx+1].value
                    let dOmniScope.name = "CODE" " 无需名字
                    let lOmniSS = [dOmniScope] + lOmniSS

                    " 直接处理完 precast. eg. ((A*)B)|
                    " 寻找匹配的左括号的位置
                    let j = idx + 1
                    let tmp = 1
                    while j < nLen
                        let dTmpToken = lRevTokens[j]
                        if dTmpToken.value == ')'
                            let tmp += 1
                        elseif dTmpToken.value == '('
                            let tmp -= 1
                            if tmp == 0
                                break
                            endif
                        endif
                        let j += 1
                    endwhile

                    "let j -= 1
                    if lRevTokens[j-1].value ==# '('
                        " 传统的类型转换
                        " 获取需要解析变量类型的 tokens
                        let k = j - 2
                        let tmp = 1
                        while k >= 0
                            let dTmpToken = lRevTokens[k]
                            if dTmpToken.value == ')'
                                let tmp -= 1
                                if tmp == 0
                                    break
                                endif
                            elseif dTmpToken.value == '('
                                let tmp += 1
                            endif
                            let k -= 1
                        endwhile

                        let dTmpTypeInfo = omnicpp#utils#GetVariableType(
                                    \reverse(lRevTokens[k+1 : j-2]))
                        let dOmniInfo.precast = dTmpTypeInfo.name
                        let dOmniInfo.til = dTmpTypeInfo.til
                        " 应该保存整个 typeinfo 备用
                        let dOmniInfo.pretypeinfo = dTmpTypeInfo
                    elseif (j + 1) < nLen && lRevTokens[j+1].value ==# '>'
                        " C++ 形式的类型转换
                        " 获取需要解析变量类型的 tokens
                        let k = j + 2
                        let tmp = 1
                        while k < nLen
                            let dTmpToken = lRevTokens[k]
                            if dTmpToken.value == '>'
                                let tmp += 1
                            elseif dTmpToken.value == '<'
                                let tmp -= 1
                                if tmp == 0
                                    break
                                endif
                            endif
                            let k += 1
                        endwhile

                        let dTmpTypeInfo = omnicpp#utils#GetVariableType(
                                    \reverse(lRevTokens[j+1 : k+1]))
                        let dOmniInfo.precast = dTmpTypeInfo.name
                        let dOmniInfo.til = dTmpTypeInfo.til
                        " 应该保存整个 typeinfo 备用
                        let dOmniInfo.pretypeinfo = dTmpTypeInfo
                    else
                        echom 'syntax error: ' . dToken.value
                        let lOmniSS = []
                        break
                    endif


                    " 处理完毕
                    break
                elseif dPrevToken.kind == 'cppOperatorPunctuator' 
                            \&& dPrevToken.value == '::'
                    " postcast
                    " eg. (A**)::B.|
                    "         |^^
                    let dOmniInfo.precast = '<global>'
                    break
                else
                    echom 'syntax error: ' . dToken.value
                    let lOmniSS = []
                    break
                endif
            elseif nState == 2
                " 括号状态都已经私自处理完, 这里不再需要了
            endif
        elseif dToken.kind == 'cppOperatorPunctuator' && dToken.value == ']'
            " Option: 可以在处理前剔除所有 []
            " 处理数组下标
            " eg. A[B][C[D]].|
            if nState == 1 "期待单词时遇到 ']'
                " 跳到匹配的 '['
                let j = idx + 1
                let tmp = 1
                while j < nLen
                    let dTmpToken = lRevTokens[j]
                    if dTmpToken.value == ']'
                        let tmp += 1
                    elseif dTmpToken.value == '['
                        let tmp -= 1
                        if tmp == 0
                            break
                        endif
                    endif
                    let j += 1
                endwhile
                let dToken = dPrevToken " 保持 dPrevToken
                let idx = j
            else
                echom 'syntax error: ' . dToken.value
                let lOmniSS = []
                break
            endif
        elseif dToken.kind == 'cppOperatorPunctuator' && dToken.value == '>'
            " 处理模板实例化
            " eg. A<B, C>::|
            if nState == 0 " 期待操作符时遇到 '>'
                " eg. if ( 1 > A.| )
                " 结束
                break
            elseif nState == 1 " 期待单词时遇到 '>'
                " 跳到匹配的 '<'
                let j = idx + 1
                let tmp = 1
                while j < nLen
                    let dTmpToken = lRevTokens[j]
                    if dTmpToken.value == '>'
                        let tmp += 1
                    elseif dTmpToken.value == '<'
                        let tmp -= 1
                        if tmp == 0
                            break
                        endif
                    endif
                    let j += 1
                endwhile

                " 分析 til
                let lTmpTokens = reverse(lRevTokens[idx : j+1])
                let til = omnicpp#utils#GetVariableType(lTmpTokens).til

                let dToken = dPrevToken " 保持 dPrevToken
                let idx = j
            else
                echom 'syntax error: ' . dToken.value
                let lOmniSS = []
                break
            endif
        else
            " 遇到了其他字符, 结束. 前面判断的结果多数情况下是有用
            if !empty(dPrevToken) && dPrevToken.kind == 'cppOperatorPunctuator' 
                        \&& dPrevToken.value == '::'
                let dOmniInfo.precast = '<global>'
            endif

            " 检查是否 new 语法. eg. new A::B|
            if dToken.kind == 'cppKeyword' && dToken.value ==# 'new'
                let dOmniInfo.new = 1
            endif

            break
        endif

        let dPrevToken = dToken
        let idx += 1
    endwhile

    " eg. ::A->|
    if !empty(dPrevToken) && dPrevToken.kind == 'cppOperatorPunctuator' 
                \&& dPrevToken.value == '::'
        let dOmniInfo.precast = '<global>'
    endif

    let dOmniInfo.omniss = lOmniSS
    return dOmniInfo
endfunc
"}}}
" 从 scope 和 name 组合生成 path, 处理烦人的 '<global>'
function! s:GenPath(sScope, sName) "{{{2
    if a:sScope != '<global>'
        return a:sScope . '::' . a:sName
    else
        return a:sName
    endif
endfunc
"}}}
" Return: ScopeInfo
" {
" 'function': [],       <- 函数作用域, 一般只用名空间信息
" 'container': [],      <- 容器的作用域列表, 包括名空间
" 'global': []          <- 全局(文件)的作用域列表, 包括名空间
" }
" NOTE: 理论上可能会有嵌套名空间的情况, 但是为了简化, 不允许使用嵌套名空间
"       eg. using namespace A; using namespace B; -> A::B::C <-> C
function! omnicpp#resolvers#ResolveScopeStack(lScopeStack) "{{{2
    let dResult = {'function': [], 'container': [], 'global': []}
    let lFunctionScopes = []
    let lContainerScopes = []
    let lGlobalScopes = []

    let lCtnPartScp = []

    let g:dOCppNSAlias = {} " 名空间别名 {'abc': 'std'}
    let g:dOCppUsing = {} " using. eg. {'cout': 'std::out', 'cin': 'std::cin'}

    let nSSLen = len(a:lScopeStack)
    let idx = 0
    while idx < nSSLen
        let dScope = a:lScopeStack[idx]
        if dScope.kind == 'file'
            call add(lGlobalScopes, '<global>')
            call extend(g:dOCppNSAlias, dScope.nsinfo.nsalias)
            call extend(g:dOCppUsing, dScope.nsinfo.using)
            call extend(lGlobalScopes, dScope.nsinfo.usingns)
        elseif dScope.kind == 'container'
            call add(lCtnPartScp, dScope.name)
            call extend(g:dOCppNSAlias, dScope.nsinfo.nsalias)
            call extend(g:dOCppUsing, dScope.nsinfo.using)
            call extend(lContainerScopes, dScope.nsinfo.usingns)
        elseif dScope.kind == 'function'
            " 仅收集 nsinfo
            call extend(g:dOCppNSAlias, dScope.nsinfo.nsalias)
            call extend(g:dOCppUsing, dScope.nsinfo.using)
            call extend(lFunctionScopes, dScope.nsinfo.usingns)
        elseif dScope.kind == 'other'
            " 仅收集 nsinfo
            while idx < nSSLen
                let dScope = a:lScopeStack[idx]
                call extend(g:dOCppNSAlias, dScope.nsinfo.nsalias)
                call extend(g:dOCppUsing, dScope.nsinfo.using)
                " TODO: 应该加到哪里
                call extend(lFunctionScopes, dScope.nsinfo.usingns)
                let idx += 1
            endwhile
            break
        endif

        let idx += 1
    endwhile

    let idx = 0
    while idx < len(lCtnPartScp)
        " 处理嵌套类
        " eg.
        " void A::B::C::D()
        " {
        "     |
        " }
        " ['A', 'B', 'C'] -> ['A', 'A::B', 'A::B::C']
        " ['A', 'A::B', 'A::B::C'] 中的每个元素也必须展开其基类
        let sCtn = join(lCtnPartScp[:idx], '::')
        " 展开继承(typedef?)的类
        " TODO: 如果 A 是一个 typedef 呢?
        " TODO: 删除 omnicpp#resolvers#ResolveTag() 函数
        let lEpdScp = s:ExpandClassScope(sCtn)
        let lContainerScopes = lEpdScp + lContainerScopes

        let idx += 1
    endwhile

    let dResult.function = lFunctionScopes
    let dResult.container = lContainerScopes
    let dResult.global = lGlobalScopes

    return dResult
endfunc
"}}}
" 解析 OmniInfo, 返回用于获取 tags 的 omniTagScopes
function! omnicpp#resolvers#ResolveOmniInfo(lScopeStack, dOmniInfo) "{{{2
    if empty(a:lScopeStack) 
                \|| (empty(a:dOmniInfo.omniss) && a:dOmniInfo.precast ==# '')
        return []
    endif

    let lResult = []
    let dOmniInfo = a:dOmniInfo
    let lOmniSS = dOmniInfo.omniss

    let dScopeInfo = omnicpp#resolvers#ResolveScopeStack(a:lScopeStack)

    let lTagScopes = dScopeInfo.container + dScopeInfo.global 
                \+ dScopeInfo.function
    let lSearchScopes = lTagScopes[:]
    let lMemberStack = lOmniSS[:]

    " 预处理, 主要针对 this-> 和 cast
    if dOmniInfo.precast !=# ''
        " 生成 SearchScopes
        let dNewOmniScope = s:NewOmniScope()

        if dOmniInfo.precast ==# 'this'
            " 亦即把 this-> 替换成 MyCls::
            let dNewOmniScope.name = lSearchScopes[0]
            " precast 为 this 的时候, 直接从 <global> 搜索
            " 因为已把 this 替换为绝对路径的容器. 
            " 即使是嵌套容器的情形, 也能正常工作
            " 或者, 作为另外一个解决方案, 直接在这里解析完毕
            " void A::B()
            " {
            "     this->|
            " }
            let lSearchScopes = dScopeInfo.global
            let dNewOmniScope.kind = 'container'
            let lMemberStack = [dNewOmniScope] + lOmniSS[0:]
        elseif dOmniInfo.precast ==# '<global>'
            " 仅搜索全局作用域以及在全局作用域中的 using namespace
            let lSearchScopes = dScopeInfo.global
        else
            let dNewOmniScope.name = dOmniInfo.precast
            let dNewOmniScope.kind = 'container'
            if has_key(dOmniInfo, 'pretypeinfo')
                let dNewOmniScope.pretypeinfo = dOmniInfo.pretypeinfo
            endif
            let lMemberStack = [dNewOmniScope] + lOmniSS[1:]
        endif
    endif

    let lResult = omnicpp#resolvers#ResolveOmniScopeStack(
                \lSearchScopes, lMemberStack, dScopeInfo)

    return lResult
endfunc
"}}}
" 递归解析补全请求的补全 scope
" 返回用于获取 tags 的 TagScopes
" NOTE: 不支持嵌套定义的模版类, 也不打算支持, 因诸多原因.
" 基本算法:
" 1) 预处理第一个非容器成员(变量, 函数), 使第一个成员变为容器
" 2) 处理 MemberStack 时, 第一个是变量或者函数或者经过类型替换后, 重头开始
" 3) 解析变量和函数的时候, 需要搜索变量和函数的 path 中的每段 scope
" 4) 每解析一次都要检查是否存在类型替换
" 5) 重复 2), 3), 4)
function! omnicpp#resolvers#ResolveOmniScopeStack(
            \lSearchScopes, lMemberStack, dScopeInfo) "{{{2
    " 每次解析变量的 TypeInfo 时, 应该添加此变量的作用域到此类型的搜索域
    " eg.
    " namespace A
    " {
    "     class B {
    "     };
    "
    "     class C {
    "         B b;
    "     };
    " }
    " b 变量的 TypeInfo {'name': 'B', 'til': []}
    " 搜索变量 B 时需要添加 b 的 scope 的所有可能情况, A::B -> ['A::C', 'A']
    let lSearchScopes = a:lSearchScopes
    let dScopeInfo = a:dScopeInfo
    let lOrigScopes = dScopeInfo.container + dScopeInfo.global 
                \+ dScopeInfo.function

    " dMember = {'kind': x, 'name': y, 'til': z, 'tag': A, 'typeinfo': B}
    " kind:     类型
    " name:     名字, 必为单元类型
    " til:      name 对应的 til, 原始信息, 不可信, 不可改
    " tag:      对应的 tag, 与 typeinfo 相对应
    " typeinfo: 对应的 typeinfo, 必须是全局路径的, 不能是局部路径.
    "           这个变量是非常重要的数据, 作为很多处理的依据
    "           typeinfo 需要 tag.pah 和前面的 dMember 来最终确认
    "           其中前面的 dMember
    "           任何情况下, 解析当前的符号时, 只需要上一个符号的 typeinfo
    "           即可完成所有任务(如嵌套模版类)
    "           所以, 最终目标是只需要获取当前的 typeinfo 即可

    let lMemberStack = a:lMemberStack
    let idx = 0
    let bNeedExpandUsing = 1 " 是否需要考虑 using 指令
    let dTypeInfo = s:NewTypeInfo() " 一般用于保存变量局部类型信息
    while idx < len(lMemberStack)
        let dMember = lMemberStack[idx]
        " 当前搜索用名称, member 的类型不是 'container', 需要解析
        " sCurName 可以为单元类型(std) 也可为复合类型(map::iterator)
        let sCurName = dMember.name

        let dMember.typeinfo = s:NewTypeInfo()

        if dMember.kind == 'container'
            let sCurName = dMember.name

            if idx == 0 && bNeedExpandUsing
                " 起点容器需要展开名空间信息
                let sTmpName = s:ExpandUsingAndNSAlias(dMember.name)
                if dMember.name !=# sTmpName
                    " 展开了 using, 需要重建 typeinfo
                    " eg.
                    " using A::B;
                    " B<C,D> b;
                    "
                    " Original: B<C,D>
                    " Reuslt:   A::B<C,D>
                    let sCode = sTmpName
                    if !empty(dMember.til)
                        let sCode .= '< ' . join(dMember.til, ', ') . ' >'
                    endif
                    let dTypeInfo = omnicpp#utils#GetVariableType(sCode)
                    let sCurName = dTypeInfo.name
                endif
            endif
        elseif dMember.kind == 'variable'
            if idx == 0
                let lSearchScopes = lOrigScopes
                " 第一次进入, 因为 ctags 不支持局部变量, 
                " 所以如果起点为变量时, 需要分析是否在当前局部作用域内定义了
                let dTypeInfo = omnicpp#resolvers#ResolveFirstVariable(
                            \lSearchScopes, dMember.name)

                if len(dTypeInfo.types) > 1
                " 复合类型, 重新开始
                    let sCode = omnicpp#utils#GenCodeFromTypeInfo(dTypeInfo)
                    " 解析完毕的类型必然是容器, 所以附加 '::'
                    let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                                \sCode . '::')
                    if dTmpOmniInfo.precast ==# '<global>'
                    " 可能带 '::' 前缀
                        let lOrigScopes = dScopeInfo.global
                        let lSearchScopes = lOrigScopes
                    endif
                    " 替换当前 dMember
                    call remove(lMemberStack, idx)
                    call extend(lMemberStack, dTmpOmniInfo.omniss, 0)
                else
                " 非复合类型, 也可能是解析失败
                    " 修正当前 dMember
                    let lMemberStack[idx].kind = 'container'
                    let lMemberStack[idx].name = dTypeInfo.name
                    let lMemberStack[idx].til = dTypeInfo.til
                endif

                " 重头再来, 会从容器开始
                let idx = 0
                let bNeedExpandUsing = 1
                continue
            else
                " 常规处理
                let dTmpTag = s:GetFirstMatchTag(lSearchScopes, dMember.name)

                if !empty(dTmpTag)
                    let szDecl = dTmpTag.cmd
                    let dTypeInfo = s:GetVariableTypeInfo(szDecl[2:-3], 
                                \dTmpTag.name)
                    let dMember.typeinfo = dTypeInfo
                    let dMember.tag = dTmpTag

                    try
                        let dOrigTypeInfo = copy(dMember.typeinfo)
                        let sCurName = omnicpp#resolvers#ResolveTemplate(
                                    \dMember, lMemberStack[idx-1])
                        "if dOrigTypeInfo != dMember.typeinfo
                        if dOrigTypeInfo.name !=# dMember.typeinfo.name
                            " 处理了模版替换, 需要重头再来
                            let sCode = omnicpp#utils#GenCodeFromTypeInfo(
                                        \dMember.typeinfo)
                            " 解析完毕的类型必然是容器, 所以附加 '::'
                            let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                                        \sCode . '::')
                            " 替换 dMember
                            call remove(lMemberStack, 0, idx)
                            call extend(lMemberStack, dTmpOmniInfo.omniss, 0)

                            " TODO: 是否需要添加局部搜索域?
                            let lSearchScopes = lOrigScopes
                            if dTmpOmniInfo.precast ==# '<global>'
                            " 可能带 '::' 前缀
                                let lOrigScopes = dScopeInfo.global
                                let lSearchScopes = lOrigScopes
                            endif

                            " 重头再来
                            let idx = 0
                            let bNeedExpandUsing = 1
                            continue
                        endif
                    catch
                        " 语法错误
                        let lSearchScopes = []
                        break
                    endtry

                    " 变量的情况, 需要添加变量的 path 的所有途经的 scope
                    " eg. std::map::iterator = iterator -> std::map, std
                    " TODO: 是否需要添加上 lOrigScopes ?
                    " 若是模版变量, 应该需要添加 lOrigScopes
                    " 因为可能在声明的时候用到了 using
                    " eg.
                    " using namespace std;
                    " map<string, int> foo;
                    call extend(
                                \lSearchScopes, 
                                \s:ExpandSearchScopeStatckFromScope(dTmpTag.scope), 
                                \0)
                endif
            endif
        elseif dMember.kind == 'function'
            if idx == 0
                " 若为起点, 特殊处理
                " 先处理名空间问题
                let dMember.name = s:ExpandUsingAndNSAlias(dMember.name)
                let dTmpTag = s:GetFirstMatchTag(lSearchScopes, dMember.name)
                if empty(dTmpTag)
                    let lSearchScopes = []
                    break
                endif

                " 添加局部搜索域
                call extend(
                            \lSearchScopes, 
                            \s:ExpandSearchScopeStatckFromScope(dTmpTag.scope), 
                            \0)

                let dTypeInfo = s:GetVariableTypeInfoFromQualifiers(
                            \dTmpTag.qualifiers)

                let sCode = omnicpp#utils#GenCodeFromTypeInfo(dTypeInfo)
                " 解析完毕的类型必然是容器, 所以附加 '::'
                let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                            \sCode . '::')
                " 可能带 '::' 前缀
                if dTmpOmniInfo.precast ==# '<global>'
                    let lOrigScopes = dScopeInfo.global
                    let lSearchScopes = lOrigScopes
                endif
                " 替换当前 dMember
                call remove(lMemberStack, idx)
                call extend(lMemberStack, dTmpOmniInfo.omniss, 0)

                " 重头再来
                let idx = 0
                let bNeedExpandUsing = 0 " 函数的返回不能依赖 using
                continue
            else
                let dTmpTag = s:GetFirstMatchTag(lSearchScopes, dMember.name)
                if empty(dTmpTag)
                    let lSearchScopes = []
                    break
                endif

                " NOTE: 从 qualifiers 提取的 typeinfo 不是全局路径
                let dTypeInfo = s:GetVariableTypeInfoFromQualifiers(
                            \dTmpTag.qualifiers)

                let dMember.typeinfo = dTypeInfo
                let dMember.tag = dTmpTag
                try
                    "let sCurName = omnicpp#resolvers#ResolveTemplate(
                                "\dMember, lMemberStack[idx-1])
                    let dOrigTypeInfo = copy(dMember.typeinfo)
                    let sCurName = omnicpp#resolvers#ResolveTemplate(
                                \dMember, lMemberStack[idx-1])
                    "if dOrigTypeInfo != dMember.typeinfo
                    if dOrigTypeInfo.name !=# dMember.typeinfo.name
                        " 处理了模版替换, 需要重头再来
                        let sCode = omnicpp#utils#GenCodeFromTypeInfo(
                                    \dMember.typeinfo)
                        " 解析完毕的类型必然是容器, 所以附加 '::'
                        let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                                    \sCode . '::')
                        " 替换 dMember
                        call remove(lMemberStack, 0, idx)
                        call extend(lMemberStack, dTmpOmniInfo.omniss, 0)

                        " TODO: 是否需要添加局部搜索域?
                        let lSearchScopes = lOrigScopes
                        if dTmpOmniInfo.precast ==# '<global>'
                        " 可能带 '::' 前缀
                            let lOrigScopes = dScopeInfo.global
                            let lSearchScopes = lOrigScopes
                        endif

                        " 重头再来
                        let idx = 0
                        let bNeedExpandUsing = 1
                        continue
                    endif
                catch
                    " 语法错误
                    let lSearchScopes = []
                    break
                endtry

                " 函数的情况, 需要添加函数的 path 的所有途经的 scope
                " 即原始 Scopes + 函数 path 途经的 Scopes
                " NOTE: 不需要添加 lOrigScopes
                call extend(
                            \lSearchScopes, 
                            \s:ExpandSearchScopeStatckFromScope(dTmpTag.scope), 
                            \0)
            endif
        endif

        "=======================================================================

        " lSearchScopes 的展开已经完成, 剔除重复的搜索域
        call omnicpp#utils#FilterListSameElement(lSearchScopes)
        let dCurTag = s:GetFirstMatchTag(lSearchScopes, sCurName)
        if empty(dCurTag)
            let lSearchScopes = []
            break
        endif

        let dMember.tag = dCurTag

        " 从 dCurTag 和 上一个的 typeinfo.types 的 til 生成当前的 typeinfo
        " NOTE: 此 typeinfo 必须为全局路径
        let dTypeInfo = omnicpp#utils#GetVariableType(dCurTag.path)
        let dTypeInfo.types[-1].til = dMember.til[:]
        let dTypeInfo.til = dTypeInfo.types[-1].til
        let dMember.typeinfo = dTypeInfo
        if idx > 0
            let dPrevTypeInfo = lMemberStack[idx-1].typeinfo
            " 最里层的 til 为 dMember.til
            let dTypeInfo.types[-1].til = dMember.til[:]
            let nTmpIdx = 0
            for dTmpUnitType in dPrevTypeInfo.types
                let dTypeInfo.types[nTmpIdx].til = dTmpUnitType.til
                let nTmpIdx += 1
            endfor
            let dTypeInfo.til = dTypeInfo.types[-1].til
            let dMember.typeinfo = dTypeInfo
        endif

        " 解析 tag 前处理一次类型替换
        let dReplTypeInfo = s:ResolveTypeReplacement(dMember.typeinfo)
        if !empty(dReplTypeInfo)
        " 替换成功了, 需要重新整理 lMemberStack
            let sCode = omnicpp#utils#GenCodeFromTypeInfo(dReplTypeInfo)
            " 解析完毕的类型必然是容器, 所以附加 '::'
            let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                        \sCode . '::')
            " 可能带 '::' 前缀
            if dTmpOmniInfo.precast ==# '<global>'
                let lOrigScopes = dScopeInfo.global
                let lSearchScopes = lOrigScopes
            endif
            " 替换当前 dMember
            call remove(lMemberStack, 0, idx)
            call extend(lMemberStack, dTmpOmniInfo.omniss, 0)

            " 重头再来
            let idx = 0
            let bNeedExpandUsing = 0 " 类型替换不能依赖 using
            let lSearchScopes = lOrigScopes
            continue
        endif

        let lSearchScopes = s:GetTopLevelSearchScopesFromTag(
                    \dMember.tag, dScopeInfo, dMember.typeinfo)

        " 可能修改了 tag(例如 typedef), 需要再一次检查类型替换
        let dReplTypeInfo = s:ResolveTypeReplacement(dMember.typeinfo)
        if !empty(dReplTypeInfo)
        " 替换成功了, 需要重新整理 lMemberStack
            let sCode = omnicpp#utils#GenCodeFromTypeInfo(dReplTypeInfo)
            " 解析完毕的类型必然是容器, 所以附加 '::'
            let dTmpOmniInfo = omnicpp#resolvers#GetOmniInfo(
                        \sCode . '::')
            " 可能带 '::' 前缀
            if dTmpOmniInfo.precast ==# '<global>'
                let lOrigScopes = dScopeInfo.global
                let lSearchScopes = lOrigScopes
            endif
            " 替换当前 dMember
            call remove(lMemberStack, 0, idx)
            call extend(lMemberStack, dTmpOmniInfo.omniss, 0)

            " 重头再来
            let idx = 0
            let bNeedExpandUsing = 0 " 类型替换不能依赖 using
            let lSearchScopes = lOrigScopes
            continue
        endif

        let idx += 1
    endwhile

    return lSearchScopes
endfunc
"}}}
" 处理类型替换
" Param1: sTypeName, 当前需要替换的类型名, 绝对路径. eg. std::map::iterator
" Param2: dCtnTag, 需要处理的类型所属容器的 tag
" Param3: lCtnTil, 需要处理的类型所属容器的模板初始化列表
" Return: 替换后的类型信息 TypeInfo
" 这个替换不完善, 只对以下情况有效
" eg. std::map::iterator=pair<_Key, _Tp>
" 替换的类型中的模板初始化列表对应原始类型的 scope 的模板初始化列表
" 对于更复杂的情况, 不予支持
function! s:ResolveFirstVariableTypeReplacement(
            \sTypeName, dCtnTag, lCtnTil) "{{{2
    let sTypeName = a:sTypeName
    let dCtnTag = a:dCtnTag
    let lCtnTil = a:lCtnTil
    let dResult = {}
    " 处理硬替换类型
    if sTypeName !=# '' && has_key(g:dOCppTypes, sTypeName)
        let sReplacement = g:dOCppTypes[sTypeName].repl
        let dReplTypeInfo = s:GetVariableTypeInfo(sReplacement, '')

        if !empty(dReplTypeInfo.til)
            " 处理模版, 根据当前成员所属容器的声明列表和实例化列表修正 til
            " eg.
            " template <typename A, typename B> class C {
            "     typedef Z Y;
            " }
            " C<a, b>::Y
            " Types:    C::Y =  X<B, A>
            " Result:   C::Y -> X<b, a>
            let lPrmtInfo = 
                        \s:GetTemplatePrmtInfoList(dCtnTag.qualifiers)
            let dTmpMap = {}
            for nTmpIdx in range(len(lCtnTil))
                let dTmpMap[lPrmtInfo[nTmpIdx].name] = lCtnTil[nTmpIdx]
            endfor
            for nTmpIdx in range(len(dReplTypeInfo.til))
                let dReplTilTI = omnicpp#utils#GetVariableType(
                            \dReplTypeInfo.til[nTmpIdx])
                if has_key(dTmpMap, dReplTilTI.name)
                    let dReplTypeInfo.til[nTmpIdx] = 
                                \dTmpMap[dReplTilTI.name]
                endif
            endfor
        else
            " 无模版的变量替换
            let lPrmtInfo = 
                        \s:GetTemplatePrmtInfoList(dCtnTag.qualifiers)
            let dTmpMap = {}
            for nTmpIdx in range(len(lCtnTil))
                let dTmpMap[lPrmtInfo[nTmpIdx].name] = lCtnTil[nTmpIdx]
            endfor
            if has_key(dTmpMap, dReplTypeInfo.name)
                let dReplTypeInfo.name = 
                            \s:StripString(dTmpMap[dReplTypeInfo.name])
            endif
        endif

        let dResult = dReplTypeInfo
    endif

    return dResult
endfunc
"}}}
" 处理类型替换, 全功能, 支持嵌套的模版类
" Param1: dTypeInfo, 原始类型的类型信息, 对应类型替换等式左式
" Return: 替换后的类型信息 TypeInfo ({'name': 'std::pair', 'til': ['A', 'B']})
" eg. std::map<A,B>::iterator=std::pair<A,B>
" 暂时只支持一次模版类, 暂不支持嵌套的模版类
" 所以, 只有一种可能, 就是容器为模版类
" NOTE: 替换式的右式仅可以使用左式中在尖括号中的符号(类型),
"       不能使用左式中不在尖括号的符号(类型), 不然将会非常复杂
" eg. A<a,b>::B<c,d>::C=X<a,d>::Y   (a,b,c,d 不应该重复, 否则后果自负)
function! s:ResolveTypeReplacement(dTypeInfo) "{{{2
    let dTypeInfo = a:dTypeInfo
    let sTypeName = dTypeInfo.name
    let dResult = {}
    " 处理类型替换
    if sTypeName !=# '' && has_key(g:dOCppTypes, sTypeName)
        let dOrigTypeInfo = omnicpp#utils#GetVariableType(
                    \g:dOCppTypes[sTypeName].orig)
        let sReplacement = g:dOCppTypes[sTypeName].repl
        let dReplTypeInfo = omnicpp#utils#GetVariableType(sReplacement)

        " 先做左式到实际模版初始化类型的映射
        let dLeft2RealMap = {}
        let i = 0
        while i < len(dOrigTypeInfo.types)
            let j = 0
            while j < len(dOrigTypeInfo.types[i].til)
                let sUnitType = s:StripString(dOrigTypeInfo.types[i].til[j])
                try
                    let dLeft2RealMap[sUnitType] = dTypeInfo.types[i].til[j]
                catch
                    " dTypeInfo 缺少必要的类型
                    let dLeft2RealMap[sUnitType] = 'ERROR'
                endtry
                let j += 1
            endwhile
            let i += 1
        endwhile

        " 替换右式的普通类型
        let i = 0
        let li = []
        while i < len(dReplTypeInfo.types)
            let sKey = dReplTypeInfo.types[i].name
            if has_key(dLeft2RealMap, sKey)
                let dReplTypeInfo.types[i].name = dLeft2RealMap[sKey]
            endif
            call add(li, dReplTypeInfo.types[i].name)
            let i += 1
        endwhile
        " 替换完毕后, 整理 dReplTypeInfo.name
        let dReplTypeInfo.name = substitute(join(li, '::'), '^<global>', '', '')

        " 替换右式的模版初始化类型
        let i = 0
        while i < len(dReplTypeInfo.types)
            let j = 0
            while j < len(dReplTypeInfo.types[i].til)
                let sKey = s:StripString(dReplTypeInfo.types[i].til[j])
                if has_key(dLeft2RealMap, sKey)
                    let dReplTypeInfo.types[i].til[j] = dLeft2RealMap[sKey]
                endif
                let j += 1
            endwhile
            let i += 1
        endwhile
        " 替换完毕后, 整理 dReplTypeInfo.til
        let dReplTypeInfo.til = dReplTypeInfo.types[-1].til

        let dResult = dReplTypeInfo
    endif

    return dResult
endfunc
"}}}
" 展开搜索域, 深度优先
" eg. ['A::B', 'C::D::E', 'F'] -> 
"     ['A::B', 'A', '<global>', 'C::D::E', 'C::D', 'C', 'F']
function! s:ExpandSearchScopes(lSearchScopes) "{{{2
    let lSearchScopes = a:lSearchScopes
    let lResult = []
    let dGuard = {}
    for lSearchScope in lSearchScopes
        let lSearchScopesStack = s:GetSearchScopeStackFromPath(lSearchScope)
        for sSearchScope in lSearchScopesStack
            if !has_key(dGuard, sSearchScope)
                call add(lResult, sSearchScope)
                let dGuard[sSearchScope] = 1
            endif
        endfor
    endfor

    return lResult
endfunc
"}}}
" 展开类包含的需要搜索的多个 Scope. eg. A -> ['A', 'B', 'C']
function! s:ExpandClassScope(sTagScope) "{{{2
    let sTagScope = a:sTagScope
    let lResult = [sTagScope]

    if sTagScope != '<global>'
        let lTags = g:GetTagsByPath(sTagScope)
        if !empty(lTags)
            let dTag = lTags[0]
            let lResult = omnicpp#resolvers#ResolveTag(dTag)
        endif
    endif

    return lResult
endfunc
"}}}
" 把作用域路径展开为搜索域栈, 返回的搜索域栈的栈顶包括作为参数输入的路径
" eg. A::B::C -> ['A::B::C', 'A::B', 'A', '<global>']
function! s:GetSearchScopeStackFromPath(sPath) "{{{2
    let sPath = a:sPath
    let lResult = []
    if sPath ==# ''
        let lResult = []
    elseif sPath ==# '<global>'
        let lResult = ['<global>']
    else
        let lScopes = split(sPath, '::')
        call insert(lResult, '<global>')
        for idx in range(len(lScopes))
            if idx == 0
                call insert(lResult, lScopes[idx])
            else
                call insert(lResult, lResult[0] . '::' . lScopes[idx])
            endif
        endfor
    endif

    return lResult
endfunc
"}}}
function! s:GetTemplatePrmtInfo(sDecl) "{{{2
    let bak_ic = &ic
    set noic

    let sDecl = s:StripString(a:sDecl)
    let dPrmtInfo = s:NewPrmtInfo()
    if sDecl =~# '^typename\|^class'
        " 类型参数
        let dPrmtInfo.kind = matchstr(sDecl, '^\w\+')
        if sDecl =~# '='
            " 有默认值
            let dPrmtInfo.name = matchstr(sDecl, '\w\+\ze\s*=')
            let dPrmtInfo.default = matchstr(sDecl, '=\s*\zs\S\+\ze$')
        else
            " 无默认值
            let dPrmtInfo.name = matchstr(sDecl, '\w\+$')
        endif
    else
        " 非类型参数
        let dPrmtInfo.kind = matchstr(sDecl, '^\S\+\ze[*& ]\+\w\+')
        if sDecl =~# '='
            " 有默认值
            let dPrmtInfo.name = matchstr(sDecl, '\w\+\ze\s*=')
            let dPrmtInfo.default = matchstr(sDecl, '=\s*\zs\S\+\ze$')
        else
            " 无默认值
            let dPrmtInfo.name = matchstr(sDecl, '\w\+$')
        endif
    endif

    let &ic = bak_ic
    return dPrmtInfo
endfunc
"}}}
function! s:GetTemplatePrmtInfoList(sQualifiers) "{{{2
    let sQualifiers = a:sQualifiers
    if sQualifiers == ''
        return []
    endif

    let lResult = []

    let idx = 0
    let nNestDepth = 0
    let nLen = len(sQualifiers)
    let nSubStart = 0
    while idx < nLen
        let c = sQualifiers[idx]
        if c == '<'
            let nNestDepth += 1
            if nNestDepth == 1
                let nSubStart = idx + 1
            endif
        elseif c == '>'
            let nNestDepth -= 1
            if nNestDepth == 0
                let sText = sQualifiers[nSubStart : idx - 1]
                let dPrmtInfo = s:GetTemplatePrmtInfo(sText)
                call add(lResult, dPrmtInfo)
                break
            endif
        elseif c == ','
            if nNestDepth == 1
                let sText = sQualifiers[nSubStart : idx - 1]
                let dPrmtInfo = s:GetTemplatePrmtInfo(sText)
                call add(lResult, dPrmtInfo)
                let nSubStart = idx + 1
            endif
        endif

        let idx += 1
    endwhile

    return lResult
endfunc
"}}}
" Param: sInstDecl 为实例化声明. eg. A<B, C<D>, E> Z;
" Return:   模版实例化列表
function! s:GetTemplateInstList(sInstDecl) "{{{2
    let s = a:sInstDecl
    let til = []

    let idx = 0
    let nCount = 0
    let s1 = 0
    while idx < len(s)
        let c = s[idx]
        if c == '<'
            let nCount += 1
            if nCount == 1
                let s1 = idx + 1
            endif
        elseif c == '>'
            let nCount -= 1
            if nCount == 0
                let sArg = s:StripString(s[s1 : idx-1])
                if sArg != ''
                    call add(til, sArg)
                endif
                break
            endif
        elseif c == ','
            if nCount == 1
                let sArg = s:StripString(s[s1 : idx-1])
                if sArg != ''
                    call add(til, sArg)
                endif
                let s1 = idx + 1
            endif
        endif

        let idx += 1
    endwhile

    return til
endfunc
"}}}
" Return: 与 TypeInfo 一致的字典
"         eg. [{'name': 'A', 'til': ['B', 'C<D>']}, {'name': 'B', 'til': []}]
function! s:GetInheritsInfoList(sInherits) "{{{2
    let sInherits = a:sInherits
    if sInherits == ''
        return []
    endif

    let lResult = []

    let idx = 0
    let nNestDepth = 0
    let nLen = len(sInherits)
    let nSubStart = 0
    while idx < nLen
        let c = sInherits[idx]
        if c == '<'
            let nNestDepth += 1
        elseif c == '>'
            let nNestDepth -= 1
        elseif c == ','
            if nNestDepth == 0
                let sText = sInherits[nSubStart : idx - 1]
                let dInfo = {}
                let dInfo.name = matchstr(sText, '^\s*\zs\w\+\ze\s*<\?')
                let dInfo.til = s:GetTemplateInstList(sText)
                call add(lResult, dInfo)
                let nSubStart = idx + 1
            endif
        endif

        let idx += 1
    endwhile

    let sText = sInherits[nSubStart : idx - 1]
    let dInfo = {}
    let dInfo.name = matchstr(sText, '^\s*\zs\w\+\ze\s*<\?')
    let dInfo.til = s:GetTemplateInstList(sText)
    call add(lResult, dInfo)
    let nSubStart = idx + 1

    return lResult
endfunc
"}}}
" 在数个 TagScope 中获取第一个匹配的 tag
" 可选参数为需要匹配的类型. eg. s:GetFirstMatchTag(lTagScopes, 'A', 'c', 's')
function! s:GetFirstMatchTag(lTagScopes, sName, ...) "{{{2
    if a:sName == ''
        return {}
    endif

    let dTag = {}
    for sScope in a:lTagScopes
        let sPath = s:GenPath(sScope, a:sName)
        let lTags = g:GetTagsByPath(sPath)
        if !empty(lTags)
            if empty(a:000)
                let dTag = lTags[0]
                if (dTag.parent ==# dTag.name || '~'.dTag.parent ==# dTag.name) 
                            \&& dTag.kind =~# 'f\|p'
                    " 跳过构造和析构函数的 tag, 因为构造函数是不能继续补全的
                    " eg. A::A, A::~A
                    continue
                else
                    break
                endif
            else
                " 处理要求的匹配类型
                let bFound = 0
                for dTmpTag in lTags
                    if index(a:000, dTmpTag.kind) >= 0
                        let dTag = dTmpTag
                        let bFound = 1
                        break
                    endif
                endfor

                if bFound
                    break
                endif
            endif
        endif
    endfor
    return dTag
endfunc
"}}}
" 从声明中获取变量的类型
" eg. A<B, C<D> > -> {'name': 'A', 'til': ['B', 'C<D>']}
" Return: TypeInfo
function! s:GetVariableTypeInfo(sDecl, sVar) "{{{2
    let dTypeInfo = s:NewTypeInfo()
    let bak_ic = &ic
    set noic

    " FIXME: python 的字典转为 vim 字典时, \t 全部丢失
    let sDecl = substitute(a:sDecl, '\\t', ' ', 'g')
    let sVar = a:sVar

    let dTypeInfo = omnicpp#utils#GetVariableType(sDecl, sVar)

    let &ic = bak_ic
    return dTypeInfo
endfunc
"}}}
" 从限定词中解析变量类型
function! s:GetVariableTypeInfoFromQualifiers(sQualifiers) "{{{2
    return s:GetVariableTypeInfo(a:sQualifiers, '')
endfunc
"}}}
" 剔除配对的字符里面(包括配对的字符)的内容
" 可选参数为深度, 从 1 开始, 默认为 1
function! s:StripPair(sString, sPairL, sPairR, ...) "{{{2
    let sString = a:sString
    let sPairL = a:sPairL
    let sPairR = a:sPairR
    let nDeep = 1
    if a:0 > 0
        let nDeep = a:1
    endif

    if nDeep <= 0
        return sString
    endif

    let sResult = ''

    let idx = 0
    let nLen = len(sString)
    let nCount = 0
    let nSubStart = 0
    while idx < nLen
        let c = sString[idx]
        if c == sPairL
            let nCount += 1
            if nCount == nDeep && nSubStart != -1
                let sResult .= sString[nSubStart : idx - 1]
                let nSubStart = -1
            endif
        elseif c == sPairR
            let nCount -= 1
            if nCount == nDeep - 1
                let nSubStart = idx + 1
            endif
        endif
        let idx += 1
    endwhile

    if nSubStart != -1
        let sResult .= sString[nSubStart : -1]
    endif

    return sResult
endfunc
"}}}
" 解析 tag 的 typeref 和 inherits
" NOTE1: dTag 和 可选参数都可能修改而作为输出
" NOTE2: 近解析出最临近的搜索域, 不展开次邻近等的搜索域
" 可选参数为 TypeInfo, 作为输出, 会修改, 用于类型为模版类的情形
" NOTE3: 仅需修改派生类的类型信息作为输出,
"        因为基类的类型定义会在模版解析(ResolveTemplate())的时候处理,
"        模版解析时近需要派生类的标签和类型信息
" Return: 与 tag.path 同作用域的 scope 列表
function! omnicpp#resolvers#ResolveTag(dTag, ...) "{{{2
    let lTagScopes = []
    let dTag = a:dTag

    if empty(dTag)
        return lTagScopes
    endif

    if a:0 > 0
        let dTypeInfo = a:1
    else
        let dTypeInfo = s:NewTypeInfo()
    endif

    let lInherits = []

    " NOTE: 限于 ctags 的能力, 很多 C++ 的类型定义都没有 'typeref' 域
    " 这两个属性不会同时存在?! 'typeref' 比 'inherits' 优先?!
    while has_key(dTag, 'typeref') || dTag.kind ==# 't'
        if has_key(dTag, 'typeref')
            let lTyperef = split(dTag.typeref, '\w\zs:\ze\w')
            let sKind = lTyperef[0]
            let sPath = lTyperef[1]
            " TODO: 如果是无名容器(eg. MyNs::__anon1), 直接添加到 TagScopes,
            " 因为不会存在无名容器的 path
            let lTags = g:GetTagsByKindAndPath(sKind, sPath)
            if empty(lTags)
                break
            else
                let dTag = lTags[0]
            endif
        else
            " eg. typedef basic_string<char> string;
            " 从模式中提取类型信息
            let sDecl = matchstr(dTag.cmd[2:-3], '\Ctypedef\s\+\zs.\+')
            let sDecl = matchstr(sDecl, '\C.\{-1,}\ze\s\+\<' . dTag.name . '\>')
            let dTmpTypeInfo = s:GetVariableTypeInfo(sDecl, dTag.name)

            " 修正 TypeInfo
            let dTypeInfo.name = dTmpTypeInfo.name
            let dTypeInfo.til = dTmpTypeInfo.til

            " 生成搜索域
            " eg. 'path': 'A::B::C'
            " SearchScopes = ['A::B', 'A', '<global>']
            let lPaths = split(dTag.path, '::')[:-2]
            let lTmpSearchScopes = ['<global>']
            for nTmpIdx in range(len(lPaths))
                if nTmpIdx == 0
                    call insert(lTmpSearchScopes, lPaths[nTmpIdx])
                else
                    call insert(lTmpSearchScopes, 
                                \lTmpSearchScopes[0] . lPaths[nTmpIdx])
                endif
            endfor

            let dTmpTag = s:GetFirstMatchTag(
                        \lTmpSearchScopes, dTmpTypeInfo.name)
            if empty(dTmpTag)
                break
            else
                "let dTag = dTmpTag
                " 同时修正 Tag
                call filter(dTag, 0)
                call extend(dTag, dTmpTag)
            endif
        endif
    endwhile

    let lTagScopes += [dTag.path]

    if has_key(dTag, 'inherits')
        let lInherits += split(s:StripPair(dTag.inherits, '<', '>'), ',')
    endif

    for parent in lInherits
        " NOTE: 无需处理模版类的继承, 因为会在 ResolveTemplate() 中处理
        let lSearchScopeStack = s:GetSearchScopeStackFromPath(dTag.scope)
        let dTmpTag = s:GetFirstMatchTag(lSearchScopeStack, parent, 'c', 's')
        if !empty(dTmpTag)
            let lTagScopes += omnicpp#resolvers#ResolveTag(dTmpTag)
        endif
    endfor

    return lTagScopes
endfunc
"}}}
" 解析 tag 的 typeref 和 inherits, 从而获取顶层搜索域
" 可选参数为 TypeInfo, 作为输出, 会修改, 用于类型为模版类的情形
" Return: 与 tag.path 同作用域的 scope 列表
" NOTE1: dTag 和 可选参数都可能修改而作为输出
" NOTE2: 仅解析出最邻近的搜索域, 不展开次邻近等的搜索域, 主要作为搜索成员用
" NOTE3: 仅需修改派生类的类型信息作为输出,
"        因为基类的类型定义会在模版解析(ResolveTemplate())的时候处理,
"        模版解析时仅需要派生类的标签和类型信息
function! s:GetTopLevelSearchScopesFromTag(dTag, dScopeInfo, ...) "{{{2
    if a:0 > 0
        let dTypeInfo = a:1
    else
        let dTypeInfo = s:NewTypeInfo()
    endif

    let lResult = s:GetTopLevelSearchScopesFromTagR(a:dTag, a:dScopeInfo, dTypeInfo)

    return lResult
endfunc
"}}}
function! s:GetTopLevelSearchScopesFromTagR(dTag, dScopeInfo, ...) "{{{2
    let lSearchScopes = []
    let dTag = a:dTag
    let dScopeInfo = a:dScopeInfo

    if empty(dTag)
        return lSearchScopes
    endif

    if a:0 > 0
        let dTypeInfo = a:1
    else
        let dTypeInfo = s:NewTypeInfo()
    endif

    let lInherits = []

    let dTmpTypeInfo = s:ResolveTypedef(dTag, dScopeInfo)
    if !empty(dTmpTypeInfo)
        call filter(dTypeInfo, 0)
        call extend(dTypeInfo, dTmpTypeInfo)
    endif

    " 需要展开后的搜索域
    " NOTE: 会存在多余的 <global>
    let lSearchScopes += [dTag.path]

    if has_key(dTag, 'inherits')
        let lInherits += split(s:StripPair(dTag.inherits, '<', '>'), ',')
    endif

    for parent in lInherits
        " NOTE: 无需处理模版类的继承, 因为会在 ResolveTemplate() 中处理
        let lSearchScopeStack = s:ExpandSearchScopeStatckFromScope(dTag.scope)
        let dTmpTag = s:GetFirstMatchTag(lSearchScopeStack, parent, 'c', 's')
        if !empty(dTmpTag)
            " 为了避免重复的 <global>, 先删除这一层的 <global>
            let nIdx = index(lSearchScopes, '<global>')
            if nIdx != -1
                call remove(lSearchScopes, nIdx)
            endif
            let lSearchScopes += s:GetTopLevelSearchScopesFromTagR(
                        \dTmpTag, dScopeInfo)
        endif
    endfor

    return lSearchScopes
endfunc
"}}}
" 在指定的 SearchScopes 中解析补全中的第一个变量的具体类型
" Return: TypeInfo
function! omnicpp#resolvers#ResolveFirstVariable(lSearchScopes, sVariable) "{{{2
    " 1. 首先在局部作用域中查找声明
    " 2. 如果查找成功, 直接返回, 否则再在 SearchScopes 中查找声明
    let dTypeInfo = omnicpp#resolvers#SearchLocalDecl(a:sVariable)
    let sVarType = dTypeInfo.name

    if sVarType != ''
        " 局部变量, 必须展开 using 和名空间别名
        let dTypeInfo.name = s:ExpandUsingAndNSAlias(dTypeInfo.name)
    else
        " 没有在局部作用域到找到此变量的声明
        " 在作用域栈中搜索
        let dTag = s:GetFirstMatchTag(a:lSearchScopes, a:sVariable)
        if !empty(dTag)
            let sDecl = dTag.cmd
            let dTypeInfo = s:GetVariableTypeInfo(sDecl[2:-3], dTag.name)
            if has_key(dTag, 'class')
                " 变量是类中的成员, 需要解析模版
                let lTags = g:GetTagsByPath(a:lSearchScopes[0])
                if !empty(lTags)
                    let dCtnTag = lTags[0]
                    call omnicpp#resolvers#DoResolveTemplate(
                                \dCtnTag, [], dTag.parent, dTypeInfo)
                endif
            endif
        endif
    endif

    return dTypeInfo
endfunc
"}}}
" 展开 using 和名空间别名
function! s:ExpandUsingAndNSAlias(sName) "{{{2
    let sVarType = a:sName
    if sVarType == ''
        return ''
    endif

    " 处理 using
    if has_key(g:dOCppUsing, sVarType)
        let sVarType = g:dOCppUsing[sVarType]
    endif

    " 可能嵌套. namespace A = B::C; using A::Z;
    let sFirstWord = split(sVarType, '::')[0]
    while has_key(g:dOCppNSAlias, sFirstWord)
        let sVarType = join(
                    \[g:dOCppNSAlias[sFirstWord]] + split(sVarType, '::')[1:], 
                    \'::')
        let sFirstWord = split(sVarType, '::')[0]
    endwhile

    return sVarType
endfunc
"}}}
" 解析模版
" Param1: 当前变量信息
" Param2: 包含 Param1 成员的容器变量信息
" Return: 解析完成的 TB (typename) 的具体值(实例化后的类型名), 非绝对路径
function! omnicpp#resolvers#ResolveTemplate(dCurVarInfo, dCtnVarInfo) "{{{2
    " 同时处理类内的模版补全
    " 如果在类内要求补全模版, 因为没有 til, 所以需要检查 til
    let dCurVarInfo = a:dCurVarInfo
    let dCtnVarInfo = a:dCtnVarInfo
    let lInstList = a:dCtnVarInfo.typeinfo.til

    let nResult = 0

    if !has_key(dCurVarInfo.tag, 'class') && !has_key(dCurVarInfo.tag, 'struct')
        " 不是容器成员, 理论上可以立即返回空字符串
        " 但是考虑到 ctags 对嵌入到无名容器的容器解析有误, 还是返回原始名字为佳
        "return ''
        return dCurVarInfo.typeinfo.name
    endif

    let nResult = omnicpp#resolvers#DoResolveTemplate(
                \dCtnVarInfo.tag, lInstList, 
                \dCurVarInfo.tag.parent, dCurVarInfo.typeinfo)

    return dCurVarInfo.typeinfo.name
endfunc
"}}}
" 递归解析继承树的模版
" 在 dClassTag 类中查找 sMatchClass 类的类型 sTypeName
" eg.
" A<B, C> foo; foo.b.|
" A         -> dClassTag = {...}
" A         -> sMatchClass = 'A' (如果没有基类的话)
" <B, C>    -> lInstList = ['B', 'C']
" b         -> dTypeInfo = {'name': 'B', 'til': ...} (作为输出, 可能整个都修改)
" Return: 0 表示未完成, 1 表示完成
function! omnicpp#resolvers#DoResolveTemplate(
            \dClassTag, lInstList, sMatchClass, dTypeInfo) "{{{2
    let dClassTag = a:dClassTag
    let lInstList = a:lInstList
    let sMatchClass = a:sMatchClass
    let dTypeInfo = a:dTypeInfo

    let bak_ic = &ic
    set noic

    " 当前解析的类的模版声明参数表
    let lPrmtInfo = s:GetTemplatePrmtInfoList(dClassTag.qualifiers)
    " 如果模版实例化列表为空(例如在类中补全), 用声明列表代替
    if empty(lInstList)
        for dPrmtInfo in lPrmtInfo
            if dPrmtInfo.default != ''
                call add(lInstList, dPrmtInfo.default)
            else
                call add(lInstList, dPrmtInfo.name)
            endif
        endfor
    endif

    let nResult = 0

    if dClassTag.name == sMatchClass
        " 找到了需要找的类
        " 开始替换
        " 直接文本替换
        if empty(dTypeInfo.til)
            " 变量不是模版类
            let idx = 0
            while idx < len(lPrmtInfo)
                let dPrmtInfo = lPrmtInfo[idx]
                if dTypeInfo.name == dPrmtInfo.name
                    if idx < len(lInstList)
                        "let dTypeInfo.name = lInstList[idx]
                        " 修改整个 TypeInfo
                        call filter(dTypeInfo, 0)
                        call extend(dTypeInfo, 
                                    \s:GetVariableTypeInfo(lInstList[idx], ''))
                    else
                        " 再检查是否有默认参数, 否则肯定语法错误
                        if dPrmtInfo.default != ''
                            let dTypeInfo.name = dPrmtInfo.default
                        else
                            let &ic = bak_ic
                            throw 'C++ Syntax Error'
                        endif
                    endif
                    " 已经找到, 无论如何都要 break
                    break
                endif
                let idx += 1
            endwhile
        else
            " 变量是模版类, 需逐个替换模版实例化参数
            " TODO: 不应该嵌套替换, 应该分离出 token, 替换, 然后用空格合成,
            " 开销较大
            let idx = 0
            while idx < len(dTypeInfo.til)
                let idx2 = 0
                while idx2 < len(lPrmtInfo)
                    let dPrmtInfo = lPrmtInfo[idx2]
                    if idx2 < len(lInstList)
                        let sNewVaue = lInstList[idx2]
                    else
                        " 检查默认值
                        if dPrmtInfo.default != ''
                            let sNewVaue = dPrmtInfo.default
                        else
                            let &ic = bak_ic
                            throw 'C++ Syntax Error'
                        endif
                    endif
                    let dTypeInfo.til[idx] = substitute(
                                \dTypeInfo.til[idx], 
                                \'\<'.dPrmtInfo.name.'\>', 
                                \sNewVaue, 
                                \'g')

                    let idx2 += 1
                endwhile

                let idx += 1
            endwhile
        endif
        let nResult = 1 " 解析完毕
    else
        if !has_key(dClassTag, 'inherits')
            " 查找失败
            let nResult = 0
        else
            " TODO: 如果继承的类是类型定义 eg. typedef A<B, C> D;
            " 需要先解析完成类型定义
            let sInherits = dClassTag.inherits
            let lInheritsInfoList = 
                        \s:GetInheritsInfoList(dClassTag.inherits)
            " 深度优先搜索
            for dInheritsInfo in lInheritsInfoList
                " TODO: 先搜索最邻近作用域
                let lTags = g:GetTagsByPath(dInheritsInfo.name)
                if empty(lTags)
                    " 应该有语法错误或者 tags 数据库不是最新
                    let nResult = 0
                    break
                endif

                let dInheritsTag = lTags[0]
                " 逐个替换 dInheritsInfo.til 的项目
                if empty(dInheritsInfo.til)
                    " 非模版类, 直接替换类型名文本
                    let idx = 0
                    while idx < len(lPrmtInfo)
                        let dPrmtInfo = lPrmtInfo[idx]
                        if dInheritsInfo.name == dPrmtInfo.name
                            if idx < len(lInstList)
                                let dInheritsInfo.name = lInstList[idx]
                            else
                                " 检查默认参数
                                if dPrmtInfo.default != ''
                                    let dInheritsInfo.name = dPrmtInfo.name
                                else
                                    let &ic = bak_ic
                                    throw 'C++ Syntax Error'
                                endif
                            endif
                            " 已经找到, 无论如何都要 break
                            break
                        endif
                        let idx += 1
                    endwhile
                else
                    " 模版类, 逐个处理模版实例化参数
                    let idx = 0
                    while idx < len(dInheritsInfo.til)
                        let idx2 = 0
                        while idx2 < len(lPrmtInfo)
                            let dPrmtInfo = lPrmtInfo[idx2]
                            if idx2 < len(lInstList)
                                let sNewVaue = lInstList[idx2]
                            else
                                " 检查默认值
                                if dPrmtInfo.default != ''
                                    let sNewVaue = dPrmtInfo.default
                                else
                                    let &ic = bak_ic
                                    throw 'C++ Syntax Error'
                                endif
                            endif
                            let dInheritsInfo.til[idx] = substitute(
                                        \dInheritsInfo.til[idx], 
                                        \'\<'.dPrmtInfo.name.'\>', 
                                        \sNewVaue, 
                                        \'g')

                            let idx2 += 1
                        endwhile

                        let idx += 1
                    endwhile
                endif

                let nRet = omnicpp#resolvers#DoResolveTemplate(dInheritsTag, 
                            \dInheritsInfo.til, sMatchClass, dTypeInfo)
                if nRet
                    " 已解决
                    let nResult = nRet
                    break
                endif
            endfor
        endif
    endif

    let &ic = bak_ic
    return nResult
endfunc
"}}}
" 比较两个光标位置 
function! s:CmpPos(lPos1, lPos2) "{{{2
    let lPos1 = a:lPos1
    let lPos2 = a:lPos2
    if lPos1[0] > lPos2[0]
        return 1
    elseif lPos1[0] < lPos2[0]
        return -1
    else
        if lPos1[1] > lPos2[1]
            return 1
        elseif lPos1[1] < lPos2[1]
            return -1
        else
            return 0
        endif
    endif
endfunc
"}}}
" 获取向上搜索局部变量的停止位置, 同时是也是向下搜索的开始位置
" Note: 如果光标不在任何 '局部' 作用域中, 即为全局作用域, 返回 [0, 0]
"       全局作用域不应调用此函数
" eg.
" class A {
"     char foo;
"     class B {
"         void F()
"         {
"             long foo;
"         }
"         short foo;
"         void Func(int foo)
"         {
"             foo = 0;|
"         }
"     };
" };
" TODO: 处理 extern "C" {
function! s:GetStopPosForLocalDeclSearch(...) "{{{2
    let lOrigCursor = getpos('.')
    let lOrigPos = lOrigCursor[1:2]
    let lStopPos = lOrigPos
    let lCurPos = lOrigPos

    if exists('g:lOCppScopeStack')
        let lScopeStack = g:lOCppScopeStack
    else
        let lScopeStack = omnicpp#scopes#GetScopeStack()
    endif
    " 从作用域栈顶部开始, 一直向上搜索块开始位置
    " 直至遇到非 'other' 类型的作用域,
    for dScope in reverse(lScopeStack)
        let lCurBlkStaPos = omnicpp#scopes#GetCurBlockStartPos(1)
        if lCurBlkStaPos == [0, 0]
            " 到达这里, 肯定有语法错误, 或者是全局作用域
            let lStopPos = [0, 0]
            break
        endif

        if dScope.kind != 'other'
            break
        endif
    endfor

    if lStopPos != [0, 0]
        let lStopPos = omnicpp#utils#GetCurStatementStartPos(1)
    endif

    if a:0 > 0 && a:1
    else
        call setpos('.', lOrigCursor)
    endif

    return lStopPos
endfunc
"}}}
" Search a local declaration
" Return: TypeInfo
" 搜索局部变量的声明类型. 
" TODO: 这个函数很慢! 需要优化. 需要变量分析的场合的速度比不需要的场合的慢 3 倍!
function! omnicpp#resolvers#SearchLocalDecl(sVariable) "{{{2
    let dTypeInfo = s:NewTypeInfo()
    let lOrigCursor = getpos('.')
    let lOrigPos = lOrigCursor[1:2]

    let bak_ic = &ignorecase
    set noignorecase

    " TODO: 这个函数比较慢
    let lStopPos = s:GetStopPosForLocalDeclSearch(0)
    let lCurPos = getpos('.')[1:2]
    while lCurPos != [0, 0]
        " 1. 往下搜索不超过起始位置的同名符号, 解析 tokens
        " 2. 若为无效的声明, 重复, 否则结束
        let lCurPos = searchpos('\C\<'. a:sVariable .'\>', 'Wb')

        " TODO: 这两个函数很慢. 禁用的话无法排除其他块中同名变量的干扰
        " 原因是, 前面或者后面嵌套的大括号太多, 想办法优化
        if 0
            if s:CmpPos(omnicpp#scopes#GetCurBlockStartPos(), lStopPos) > 0 
                        \&& s:CmpPos(omnicpp#scopes#GetCurBlockEndPos(), 
                        \            lOrigPos) < 0
                " 肯定进入了其他的 {} 块
                continue
            endif
        endif

        if lCurPos != [0, 0] && s:CmpPos(lCurPos, lStopPos) > 0
            " TODO: 验证是否有效的声明
            " 搜索 foo 声明行应该为 Foo foo;
            " TestCase:
            " mc.foo();
            " Foo foo;
            " foo;

            let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor()

            " 上述情形, tokens 最后项的类型只能为
            " C++ 关键词或单词
            " * 或 & 后 > 操作符(eg. void *p; int &n; vector<int> x;)
            " 若为操作符, 则只可以是 '&', '*', '>', ','
            " eg. std::map<int, int> a, &b, c, **d;
            " 预检查
            if !empty(lTokens)
                " 暂时的方案是, 判断最后的 token, 若为以下操作符, 必然不是声明
                " ., ->, (, =, -, +, &&, ||
                "if lTokens[-1].kind == 'cppOperatorPunctuator' 
                            "\&& lTokens[-1].value =~# 
                            "\   '\V.\|->\|(\|=\|-\|+\|&&\|||'
                let lValidValue = ['*', '&', '>', ',']
                if lTokens[-1].kind == 'cppOperatorPunctuator' 
                            \&& index(lValidValue, lTokens[-1].value) == -1
                    " 无效的声明, 继续
                    continue
                elseif lTokens[-1].kind == 'cppOperatorPunctuator' 
                            \&& index(lValidValue, lTokens[-1].value) != -1
                    " 即使最后的操作符合法, 还需要检查次后的字符, 如果为 '=',
                    " 必定是无效的声明
                    " eg1. A a = *b->c;
                    " eg2. A a = &b.c;
                    if len(lTokens) >= 2 && lTokens[-2].value ==# '='
                        " 无效的声明
                        continue
                    endif
                else
                    " 为合法的变量声明
                endif
            else
                " tokens 为空, 无效声明, 跳过
                continue
            endif

            " 排除在注释或字符串中的情形
            " 比较慢, 暂时禁用
            "if g:VLOmniCpp_EnableSyntaxTest
                "if omnicpp#utils#IsCursorInCommentOrString()
                    "continue
                "endif
            "endif

            " 解析声明
            let dTypeInfo = omnicpp#utils#GetVariableType(lTokens, a:sVariable)
            if dTypeInfo.name !=# ''
                break
            endif
        else
            " 搜索失败
            break
        endif
    endwhile

    call setpos('.', lOrigCursor)
    let &ignorecase = bak_ic

    return dTypeInfo
endfunc
"}}}
" 把作用域展开为搜索域栈
" eg. A::B::C -> ['A::B::C', 'A::B', 'A', '<global>']
function! s:ExpandSearchScopeStatckFromScope(sScope) "{{{2
    let sScope = a:sScope
    let lResult = []
    if sScope ==# ''
        let lResult = []
    elseif sScope ==# '<global>'
        let lResult = ['<global>']
    else
        let lScopes = split(sScope, '::')
        call insert(lResult, '<global>')
        for idx in range(len(lScopes))
            if idx == 0
                call insert(lResult, lScopes[idx])
            else
                call insert(lResult, lResult[0] . '::' . lScopes[idx])
            endif
        endfor
    endif

    return lResult
endfunc
"}}}
function! s:ExpandSearchScopeStatckFromScopeNoGlobal(sScope) "{{{2
    let lResult = s:ExpandSearchScopeStatckFromScope(a:sScope)
    let nIdx = index(lResult, '<global>')
    if nIdx != -1
        call remove(lResult, nIdx)
    endif

    return lResult
endfunc
"}}}
" 解析 typedef, 在符号可能是一个 typedef 的场合都应该调用此函数
" 给出符号的 tag 和 原始的搜索域, 直接解析出最终需要的符号的 tag 和 typeinfo
" Param1: dTag, 符号的标签, 会作为输出修改
" Param2: dScopeInfo, 原始的 ScopeInfo, 主要用到它的 global 域
" Return: 如果处理过 typedef, 返回非空的 TypeInfo, 否则返回空字典
" NOTE: 暂时无法支持在 typedef 中出现模版参数中的类型
" eg.
" template <typename T1> class Foo {
"     public:
"         typedef T1 Key;
"
"     Key m_key;
" };
" NOTE: 这种情况无法找到 T1 的 tag
" Result: m_key -> T1
function! s:ResolveTypedef(dTag, dScopeInfo) "{{{2
    let dTag = a:dTag
    let dScopeInfo = a:dScopeInfo
    let lOrigScopes = dScopeInfo.container + dScopeInfo.global 
                \+ dScopeInfo.function

    let dResult = {}
    if empty(dTag)
        return {}
    endif

    " NOTE: 限于 ctags 的能力, 很多 C++ 的类型定义都没有 'typeref' 域
    while has_key(dTag, 'typeref') || dTag.kind ==# 't'
        if has_key(dTag, 'typeref')
            " FIXME: ctags 的 bug, 会错误地把变量声明视为有 typeref 声明
            " 尝试的解决方案, 搜索 '}', 若没有, 则为错误的 tag
            " eg. struct st { int a; } st1;
            if dTag.cmd[2:-3] !~# '}'
                call remove(dTag, 'typeref')
                " 继续
                continue
            endif

            let lTyperef = split(dTag.typeref, '\w\zs:\ze\w')
            let sKind = lTyperef[0]
            let sPath = lTyperef[1]

            " NOTE: 如果是无名容器(eg. MyNs::__anon1), 直接添加到 TagScopes,
            "       因为不会存在无名容器的 path
            " 变量可能是无名容器的成员, 如果是无名容器成员,
            " 直接设置 SearchScopes 然后跳过这一步
            " 因为不会存在无名容器的 path
            " eg.
            " typedef struct St { Cls a; } ST;
            " ST st;
            " st.a.|
            "
            " st -> ST -> St -> a -> Cls ->
            " ====================
            " typedef struct { Cls a; } ST;
            " ST st;
            " st.a.|
            "
            " st -> ST -> __anon1 (没有 __anon1 的 tag) -> a -> Cls ->
            if sPath =~# '__anon\d\+$'
                " 如果是无名容器, s:GetFirstMatchTag() 必返回空字典
                " 所以在此构造无名容器的 tag
                let dTmpTag = copy(dTag)
                call remove(dTmpTag, 'typeref')
                let dTmpTag.name = matchstr(sPath, '__anon\d\+$')
                let dTmpTag.kind = sKind[0] " 类型是单字母, 这里一般为 's'
                let dTmpTag.path = sPath
                if sPath =~# '::'
                    let dTmpTag.scope = join(split(sPath, '::')[: -2], '::')
                else
                    let dTmpTag.scope = '<global>'
                endif
            else
                let dTmpTag = s:GetFirstMatchTag(lOrigScopes, sPath, sKind[0])
            endif

            if empty(dTmpTag)
                break
            else
                call filter(dTag, 0)
                call extend(dTag, dTmpTag)

                " 有 typeref, 直接从 path 提取 TypeInfo
                let dResult = omnicpp#utils#GetVariableType(dTag.path)
            endif
        else
            " eg. typedef basic_string<char> string;
            " 从模式中提取类型信息
            let sDecl = matchstr(dTag.cmd[2:-3], '\Ctypedef\s\+\zs.\+')
            let sDecl = matchstr(sDecl, '\C.\{-1,}\ze\s\+\<' . dTag.name . '\>')
            " NOTE: 这里得到的可能是复合类型, 第一个作用域可能是嵌套的 typedef
            "       应该尝试展开第一个作用域的符号, 只可能在第一个作用域有嵌套
            " eg.
            " typedef A::B AA;
            " typedef AA::BB AAA;
            " Reuslt: AAA -> A::B::BB
            let dTmpTypeInfo = s:GetVariableTypeInfo(sDecl, dTag.name)

            if len(dTmpTypeInfo.types) >= 1
                " 第一个作用域可能也是一个 typedef, 尝试嵌套解析
                " 一般情况下, 只需在局部搜索域中搜索即可
                let lTmpSearchScopes = 
                            \s:ExpandSearchScopeStatckFromScope(dTag.scope)
                let dTmpTag = s:GetFirstMatchTag(
                            \lTmpSearchScopes, dTmpTypeInfo.types[0].name)
                let dTmpTypeInfo2 = s:ResolveTypedef(dTmpTag, dScopeInfo)
                if !empty(dTmpTypeInfo2)
                    call omnicpp#utils#StripLeftTypes(dTmpTypeInfo, 1)
                    let dTmpTypeInfo = omnicpp#utils#JoinTypeInfo(
                                \dTmpTypeInfo2, dTmpTypeInfo)
                endif
            endif

            " 生成搜索域
            let lLocalSearchScopes = 
                        \s:ExpandSearchScopeStatckFromScopeNoGlobal(dTag.scope)
            let lTmpSearchScopes = lLocalSearchScopes + lOrigScopes

            let dTmpTag = 
                        \s:GetFirstMatchTag(lTmpSearchScopes, dTmpTypeInfo.name)
            if empty(dTmpTag)
                break
            else
                call filter(dTag, 0)
                call extend(dTag, dTmpTag)

                call filter(dResult, 0)
                call extend(dResult, dTmpTypeInfo)
            endif
        endif
    endwhile

    return dResult
endfunc
"}}}
function! omnicpp#resolvers#Load() "{{{2
endfunc
"}}}
" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/complete.vim	[[[1
711
" Description:  Omni completion script for resolve namespace
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 14
" License:      GPLv2

"临时启用选项函数 {{{2
function! s:SetOpts()
    let s:bak_cot = &completeopt

    if g:VLOmniCpp_ItemSelectionMode == 0 " 不选择
        set completeopt-=menu,longest
        set completeopt+=menuone
    elseif g:VLOmniCpp_ItemSelectionMode == 1 " 选择并插入文本
        set completeopt-=menuone,longest
        set completeopt+=menu
    elseif g:VLOmniCpp_ItemSelectionMode == 2 " 选择但不插入文本
        set completeopt-=menu,longest
        set completeopt+=menuone
    else
        set completeopt-=menu
        set completeopt+=menuone,longest
    endif

    return ''
endfunction
function! s:RestoreOpts()
    if exists('s:bak_cot')
        let &completeopt = s:bak_cot
        unlet s:bak_cot
    else
        return ""
    endif

    let sRet = ""

    if pumvisible()
        if g:VLOmniCpp_ItemSelectionMode == 0 " 不选择
            let sRet = "\<C-p>"
        elseif g:VLOmniCpp_ItemSelectionMode == 1 " 选择并插入文本
            let sRet = ""
        elseif g:VLOmniCpp_ItemSelectionMode == 2 " 选择但不插入文本
            let sRet = "\<C-p>\<Down>"
        else
            let sRet = "\<Down>"
        endif
    endif

    return sRet
endfunction
function! s:CheckIfSetOpts()
    let sLine = getline('.')
    let nCol = col('.') - 1
    "若是成员补全，添加 longest
    if sLine[nCol-2:] =~ '->' || sLine[nCol-1:] =~ '\.' 
                \|| sLine[nCol-2:] =~ '::'
        call s:SetOpts()
    endif

    return ''
endfunction
"}}}
function! s:CanComplete() "{{{2
    if (getline('.') =~ '#\s*include')
        " 写头文件，忽略
        return 0
    else
        " 检测光标所在的位置，如果在注释、双引号、浮点数时，忽略
        let nLine = line('.')
        let nCol = col('.') - 1 " 是前一列 eg. ->|
        if nCol < 1
            " TODO: 支持续行的补全
            return 0
        endif
        if g:VLOmniCpp_EnableSyntaxTest
            let lStack = synstack(nLine, nCol)
            let lStack = empty(lStack) ? [] : lStack
            for nID in lStack
                if synIDattr(nID, 'name') 
                            \=~? 'comment\|string\|number\|float\|character'
                    return 0
                endif
            endfor
        else
            " TODO
        endif

        return 1
    endif
endfunction
"}}}
function! s:LaunchOmniCppCompletion() "{{{2
    if s:CanComplete()
        return "\<C-x>\<C-o>"
    else
        return ''
    endif
endfunction
"}}}
function! s:CompleteByChar(sChar) "{{{2
    if a:sChar ==# '.'
        return a:sChar . s:LaunchOmniCppCompletion()
    elseif a:sChar ==# '>'
        if getline('.')[col('.') - 2] != '-'
            return a:sChar
        else
            return a:sChar . s:LaunchOmniCppCompletion()
        endif
    elseif a:sChar ==# ':'
        if getline('.')[col('.') - 2] != ':'
            return a:sChar
        else
            return a:sChar . s:LaunchOmniCppCompletion()
        endif
    endif
endfunction
"}}}
function! omnicpp#complete#Init() "{{{2
    if !exists('g:VLWorkspaceHasStarted') || !g:VLWorkspaceHasStarted
        " 仅支持在 VimLite 中使用
        return ''
    endif

    " 初始化数据库
    call VimTagsManagerInit()

    " 初始化函数 Calltips 服务
    call g:InitVLCalltips()
    exec 'inoremap <silent> <buffer> ' . g:VLCalltips_DispCalltipsKey 
                \. ' <C-r>=<SID>RequestCalltips()<CR>'

    " 初始化设置
    call omnicpp#settings#Init()

    "setlocal completefunc=
    setlocal omnifunc=omnicpp#complete#Complete

    " TODO: 不应该使用全局变量
    let g:dOCppNSAlias = {} " 名空间别名 {'abc': 'std'}
    let g:dOCppUsing = {} " using. eg. {'cout': 'std::out', 'cin': 'std::cin'}

    " 硬替换类型, 补全前修改为合适的值
    if !exists('g:dOCppTypes')
        let g:dOCppTypes = {}
    endif

    if g:VLOmniCpp_MayCompleteDot
        inoremap <silent> <buffer> . 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('.')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLOmniCpp_MayCompleteArrow
        inoremap <silent> <buffer> > 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('>')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLOmniCpp_MayCompleteColon
        inoremap <silent> <buffer> : 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar(':')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    inoremap <script> <Plug>SmartComplete 
                \<C-r>=<SID>CheckIfSetOpts()<CR>
                \<C-r>=<SID>LaunchOmniCppCompletion()<CR>
                \<C-r>=<SID>RestoreOpts()<CR>

    "显示函数 calltips 的快捷键
    if g:VLOmniCpp_MapReturnToDispCalltips
        inoremap <silent> <expr> <buffer> <CR> pumvisible() ? 
                    \"\<C-y>\<C-r>=<SID>RequestCalltips(1)\<Cr>" : 
                    \"\<CR>"
    endif

    if g:VLOmniCpp_ItemSelectionMode > 4
        imap <silent> <buffer> <C-n> <Plug>SmartComplete
    else
        "inoremap <silent> <buffer> <C-n> 
                    "\<C-r>=<SID>SetOpts()<CR>
                    "\<C-r>=<SID>LaunchOmniCppCompletion()<CR>
                    "\<C-r>=<SID>RestoreOpts()<CR>
    endif
endfunction
"}}}
function! s:RequestCalltips(...) " 可选参数标识是否刚在补全后发出请求 {{{2
    " 从全能补全菜单选择条目后，使用上次的输出
    if a:0 > 0 && a:1
        let sLine = getline('.')
        let nCol = col('.')
        if sLine[nCol-3:] =~ '^()'
            let sFuncName = matchstr(sLine[: nCol-4], '\~\?\w\+$')
            if sFuncName[0] !=# '~'
                normal! h
                let lCalltips = s:GetCalltips(s:lTags, sFuncName)
                call g:DisplayVLCalltips(lCalltips, 0)
            endif
        endif

        return ''
    endif

    " 普通情况，请求 calltips
    " 确定函数括号开始的位置
    let lOrigCursor = getpos('.')
    " 返回 1 则跳过此匹配. 手册有误, 说返回 0 就跳过!
    if g:VLOmniCpp_EnableSyntaxTest
        " 跳过字符串中和注释中的匹配
        let sSkipExpr = 'synIDattr(synID(line("."), col("."), 0), "name") '
                    \. '=~? "character\\|string\\|comment"'
    else
        " 空则不跳过任何匹配
        let sSkipExpr = ''
    endif
    " 括号开始位置
    let lStartPos = searchpairpos('(', '', ')', 'nWb', sSkipExpr)
    "考虑刚好在括号内，加 'c' 参数
    let lEndPos = searchpairpos('(', '', ')', 'nWc', sSkipExpr)
    let lCurPos = lOrigCursor[1:2]

    "不在括号内
    if lStartPos == [0, 0]
        return ''
    endif

    let bImpossible = 0 " 不可能是 A<B> a(|);
    let bForceNew = 0   " 强制视为 new A<B>(|);

    "获取函数名称和名称开始的列，只能处理 '(' "与函数名称同行的情况，
    "允许之间有空格
    let sStartLine = getline(lStartPos[0])
    call cursor(lStartPos)
    let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor()
    if empty(lTokens)
        return ''
    endif
    if lTokens[-1].value ==# '>'
        let bImpossible = 1
        let idx = 2
        let nLen = len(lTokens)
        let nDeep = 1
        while idx <= nLen
            let dToken = lTokens[-idx]
            if dToken.value ==# '>'
                let nDeep += 1
            elseif dToken.value ==# '<'
                let nDeep -= 1
            endif
            if nDeep == 0
                break
            endif
            let idx += 1
        endwhile
        let lTokens = lTokens[: -idx - 1]
    endif
    if empty(lTokens)
        return ''
    endif
    let sFuncName = lTokens[-1].value
    try
        if lTokens[-2].value ==# '~'
            let bImpossible = 1
            let sFuncName = '~' . sFuncName
        endif
    catch
    endtry
    let lFuncNameSPos = searchpos('\V' . sFuncName, 'bWn')
    let lFuncNameEPos = lFuncNameSPos[:]
    let lFuncNameEPos[1] += len(sFuncName)
    if lFuncNameSPos == [0, 0]
        return ''
    endif

    if !bImpossible
        " 检查是否 A<B> a(|); 形式
        try
            let bTest1 = 0 " 条件一:
            let bTest2 = 0 " 条件二:
            if lTokens[-1].kind == 'cppWord'
                let bTest1 = 1
            endif

            let lTmp = lTokens[:-2]
            if lTmp[-1].value ==# '>'
                " 剔除中间的 <>
                " eg. A<B> a(|);
                "      ^^^
                let bImpossible = 1
                let idx = 2
                let nLen = len(lTmp)
                let nDeep = 1
                while idx <= nLen
                    let dToken = lTmp[-idx]
                    if dToken.value ==# '>'
                        let nDeep += 1
                    elseif dToken.value ==# '<'
                        let nDeep -= 1
                    endif
                    if nDeep == 0
                        break
                    endif
                    let idx += 1
                endwhile
                let lTokens = lTmp[: -idx - 1] + [lTokens[-1]]
            endif

            if lTokens[-2].kind == 'cppWord'
                let bTest2 = 1
                call remove(lTokens, -1)
            endif

            if bTest1 && bTest2
                " 满足条件, 构造成 new A<B>(|)
                let bForceNew = 1
                let sFuncName = lTokens[-1].value
                let lFuncNameSPos = searchpos(sFuncName, 'bWn')
                let lFuncNameEPos = lFuncNameSPos[:]
                let lFuncNameEPos[1] += len(sFuncName)
            endif
        catch
        endtry
    endif

    let lCalltips = []
    if sFuncName != '' && sFuncName[0] !=# '~'
        "找到了函数名，开始全能补全
        call cursor(lFuncNameEPos)
        let nStartCol = omnicpp#complete#Complete(1, '')
        call cursor(lFuncNameSPos)

        " 用于支持 new CLS(|) 和 CLS cls(|) 形式的 calltips
        let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
        if has_key(dOmniInfo, 'new') || bForceNew
            " eg. A::B *c = new A::B(|);
            let dToken1 = {'kind': 'cppWord', 'value': sFuncName}
            let dToken2 = {'kind': 'cppOperatorPunctuator', 'value': '::'}
            call add(s:lTokens, dToken1)
            call add(s:lTokens, dToken2)
            " 必定是成员补全
            let s:nCompletionType = s:CompletionType_MemberCompl
            " TODO: 如果 sFuncName 是一个 typedef, 需要展开
            " std::string::basic_string<char>(|)
        endif

        " NOTE: 这里已经能够支持在容器内基类的构造函数的 Calltips
        "       应该是搜索域的原因(刚好有基类的搜索域?)
        " eg. class B : A { A(|) }
        let lTags = omnicpp#complete#Complete(0, sFuncName)
        let lCalltips = s:GetCalltips(lTags, sFuncName)

        " 如果在类变量初始化列表中, 要支持变量的构造函数初始化
        if empty(lCalltips) 
                    \&& match(omnicpp#utils#GetCurStatementBeforeCursor(), 
                    \         ')\s*:') != -1
            " 确定在类变量初始化列表中
            let lScopeStack = omnicpp#scopes#GetScopeStack()
            let dScopeInfo = omnicpp#resolvers#ResolveScopeStack(lScopeStack)
            let lSearchScopes = dScopeInfo.container + dScopeInfo.global 
                        \+ dScopeInfo.function
            let dTypeInfo = omnicpp#resolvers#ResolveFirstVariable(
                        \lSearchScopes, sFuncName)
            if !empty(dTypeInfo)
                " 修正 s:lTokens 来欺骗 omnicpp#complete#Complete()
                let lTmpTokens = omnicpp#tokenizer#Tokenize(
                            \dTypeInfo.name . '::')
                call extend(s:lTokens, lTmpTokens)

                " 修正补全类型来欺骗 omnicpp#complete#Complete()
                let s:nCompletionType = s:CompletionType_MemberCompl

                let lTags = omnicpp#complete#Complete(0, dTypeInfo.name)
                let lCalltips = s:GetCalltips(lTags, dTypeInfo.name)
            endif
        endif
    endif

    call setpos('.', lOrigCursor)
    call g:DisplayVLCalltips(lCalltips, 0, 1)

    return ''
endfunction
"}}}
function! s:GetCalltips(lTags, sFuncName) "{{{2
    let lTags = a:lTags
    let sFuncName = a:sFuncName

    let lCalltips = []
    for dTag in lTags
        if dTag.name ==# sFuncName 
            " 如果声明和定义分开, 只取声明的 tag
            " ctags 中, 解析类方法定义的时候是没有访问控制信息的
            " 1. 原型
            " 2. C 中的函数(kind == 'f', !has_key(dTag, 'class'))
            " 3. C++ 中的内联成员函数
            if dTag.kind ==# 'p' 
                        \|| (dTag.kind ==# 'f' && !has_key(dTag, 'class'))
                        \|| (dTag.kind ==# 'f' && has_key(dTag, 'class') 
                        \    && has_key(dTag, 'access'))
                let sName = dTag.path
                " 首先尝试在模式中查找限定词, 
                " 若查找失败才用 tag 中的 qualifiers 域, 因为这个域的解析不完善
                " FIXME: python 的字典转为 vim 字典时, \t 全部丢失
                let sQualifiers = substitute(dTag.cmd[2:-3], '\\t', ' ', 'g')
                let sQualifiers = matchstr(sQualifiers, 
                            \'\C\s*\zs[^;]\{-}\ze' . sFuncName)
                if sQualifiers ==# ''
                    let sQualifiers = dTag.qualifiers . ' '
                endif
                if sQualifiers =~# '::\s*$'
                    let sName = sFuncName
                endif
                call add(lCalltips, printf("%s%s%s", sQualifiers, 
                            \              sName, dTag.signature))
            elseif dTag.kind ==# 'd' && has_key(dTag, 'signature')
                " 处理函数形式的宏
                call add(lCalltips, dTag.name . dTag.signature)
            endif
        endif
    endfor

    return lCalltips
endfunction
"}}}
" 作用域内符号补全, 即无任何限定作用域
" eg. prin|
let s:CompletionType_NormalCompl = 0
" 作用域内变量成员补全 ('::', '->', '.')
" eg. std::st|
let s:CompletionType_MemberCompl = 1
" 用于标识补全类型
let s:nCompletionType = s:CompletionType_NormalCompl
" 用于 omnifunc 第一阶段与第二阶段通讯, 指示禁止补全
let s:bDoNotComplete = 0
" 用于区分是否作用域操作符的成员补全
" 仅在 '作用域内变量成员补全' 时有用
let s:bIsScopeOperation = 0
" 当前语句的 token 列表
let s:lCurentStatement = []
" omnifunc
function! omnicpp#complete#Complete(findstart, base) "{{{2
    if a:findstart
        let s:nCompletionType = s:CompletionType_NormalCompl
        let s:bDoNotComplete = 0
        let s:bIsScopeOperation = 0
        "call g:Timer.Start() "计时用

        let nStartIdx = col('.') - 1
        let sLine = getline('.')[: nStartIdx-1]

        " 跳过光标在注释和字符串中的补全请求
        if omnicpp#utils#IsCursorInCommentOrString()
            " BUG: 返回 -1 仍然进入下一阶段
            let s:bDoNotComplete = 1
            return -1
        endif

        " 基于 tokens 的预分析
        let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor(1)
        let s:lTokens = lTokens
        let b:lTokens = s:lTokens
        if empty(lTokens)
            " (1) 无预输入的作用域内符号补全不支持, 因为可能太多符号
            let s:bDoNotComplete = 1
            return -1
        endif

        if lTokens[-1].kind == 'cppKeyword' || lTokens[-1].kind == 'cppWord'
            " 肯定是有预输入的补全, 至于是不是成员补全需要进一步分析
            let s:lTokens = lTokens[:-2]
            let b:lTokens = s:lTokens

            if  sLine[-1:-1] =~# '\s' || sLine[-1:-1] ==# ''
                " 有预输入, 但是光标不邻接单词, 不能补全
                let s:bDoNotComplete = 1
                return -1
            endif

            if len(lTokens) >= 2 && lTokens[-2].value =~# '\.\|->\|::'
                if lTokens[-2].value ==# '::'
                    let s:bIsScopeOperation = 1
                else
                    let s:bIsScopeOperation = 0
                endif
                " (3) 有预输入的成员补全
                let s:nCompletionType = s:CompletionType_MemberCompl
            else
                " (2) 有预输入的作用域内符号补全
                let s:nCompletionType = s:CompletionType_NormalCompl
            endif

            let nRet = searchpos('\C' . lTokens[-1].value, 'Wbn')[1]
            let b:fs = nRet
            " BUG: 居然要减一才工作
            return nRet - 1
        elseif lTokens[-1].value =~# '\.\|->\|::'
            " (4) 无预输入的成员补全
            let s:nCompletionType = s:CompletionType_MemberCompl
            if lTokens[-1].value ==# '::'
                let s:bIsScopeOperation = 1
            else
                let s:bIsScopeOperation = 0
            endif

            let b:fs = col('.')
            return col('.')
        else
            let s:bDoNotComplete = 1
            return -1
        endif
    endif

    let lResult = []

    if s:bDoNotComplete
        let s:bDoNotComplete = 0
        return lResult
    endif

    let sBase = a:base
    let b:base = a:base
    let b:findstart = col('.')

    let lScopeStack = omnicpp#scopes#GetScopeStack()
    " 设置全局变量, 用于 GetStopPosForLocalDeclSearch() 里面使用...
    let g:lOCppScopeStack = lScopeStack 
    "let lSimpleSS = omnicpp#complete#SimplifyScopeStack(lScopeStack)
    let lSearchScopes = []
    let lTags = []

    if s:nCompletionType == s:CompletionType_NormalCompl
        " (1) 作用域内非成员补全模式

        let dScopeInfo = omnicpp#resolvers#ResolveScopeStack(lScopeStack)
        let lSearchScopes = dScopeInfo.container + dScopeInfo.global 
                    \+ dScopeInfo.function
    else
        " (2) 作用域内成员补全模式

        let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
        if empty(dOmniInfo.omniss) && dOmniInfo.precast ==# '<global>'
                    \&& sBase ==# ''
            " 禁用全局全符号补全, 因为会卡
            return []
        endif

        let lSearchScopes = omnicpp#resolvers#ResolveOmniInfo(
                    \lScopeStack, dOmniInfo)
        "let b:dOmniInfo = dOmniInfo
    endif

    if !empty(lSearchScopes)
        " NOTE: lTags 列表的上限一般情况下是 1000, 所以会发现有时候符号不全
        "let lTags = g:GetTagsByScopesAndName(lSearchScopes, sBase)
        let lTags = g:GetOrderedTagsByScopesAndName(lSearchScopes, sBase)
        if !s:bIsScopeOperation 
                    \&& s:nCompletionType == s:CompletionType_MemberCompl
            " 过滤类型定义, 结构, 类
            call map(lTags, 's:ExtendTagToPopupMenuItem(v:val, "t", "s", "c")')
        else
            call map(lTags, 's:ExtendTagToPopupMenuItem(v:val)')
        endif
    endif

    " 添加 using 声明和名空间别名的名字
    if s:nCompletionType == s:CompletionType_NormalCompl
        for sName in keys(g:dOCppUsing)
            if sName =~ '^' . sBase
                let dItem = {}
                let dItem.word = sName
                let dItem.abbr = sName
                let dItem.menu = '  <using>'
                let dItem.kind = 'x'
                let dItem.icase = &ic
                let dItem.dup = 0
                call add(lTags, dItem)
            endif
        endfor

        for sName in keys(g:dOCppNSAlias)
            if sName =~ '^' . sBase
                let dItem = {}
                let dItem.word = sName
                let dItem.abbr = sName
                let dItem.menu = '  <nsalias>'
                let dItem.kind = 'n'
                let dItem.icase = &ic
                let dItem.dup = 0
                call add(lTags, dItem)
            endif
        endfor
    endif

    let lResult = lTags
    let s:lTags = lTags

    " 调试用
    "let b:lSearchScopes = lSearchScopes
    "let b:lTags = lTags

    unlet g:lOCppScopeStack
    "call g:Timer.EndEchoMes() " 计时用

    return lResult
endfunc
"}}}
" 简化 ScopeStack, scope.kind 为 'other' 的合并进前一个 scope
" 返回的是副本
function! omnicpp#complete#SimplifyScopeStack(lScopeStack) "{{{2
    let lResult = []
    for dScope in a:lScopeStack
        if dScope.kind == 'other'
            let dPrevScope = lResult[-1]
            let dPrevScope.namespaces += dScope.namespaces
            let dPrevScope.includes += dScope.namespaces
        else
            call add(lResult, copy(dScope))
        endif
    endfor

    return lResult
endfunc
"}}}
" Extend a tag entry to a popup entry
" 从 tag 字典生成补全字典(用于补全条目), 并把结果存在 tag 字典中(key 不重复?)
" 可选参数控制需要过滤的类型
function! s:ExtendTagToPopupMenuItem(dTag, ...) "{{{2
    let dTag = a:dTag
    let lFilterKinds = a:000

    " 过滤特定的类型
    if index(lFilterKinds, dTag.kind) >= 0
        return dTag
    endif

    if dTag.kind == 'f' && has_key(dTag, 'class') && !has_key(dTag, 'access')
        " 如此 tag 为类的成员函数, 类型为函数, 且没有访问控制信息, 跳过
        " 防止没有访问控制信息的类成员函数条目覆盖带访问控制信息的成员函数原型的
        return dTag
    endif

    " Add the access
    let sMenu = ''
    let dAccessChar = {'public': '+','protected': '#','private': '-'}
    if 1
        if has_key(dTag, 'access') && has_key(dAccessChar, dTag.access)
            let sMenu = sMenu.dAccessChar[dTag.access]
        else
            let sMenu = sMenu." "
        endif
    endif

    " Formating optional menu string we extract the scope information
    let sName = dTag.name
    let sWord = sName
    let sAbbr = sName

    if 1
        let sMenu = sMenu . ' ' . dTag.parent
    endif

    " Formating information for the preview window
    if index(['f', 'p'], dTag.kind[0]) >= 0
        if 0 && has_key(dTag, 'signature')
            let sAbbr .= dTag.signature
        else
            let sWord .= '()'
            let sAbbr .= '()'
        endif
    endif

    " 把函数形式的宏视为函数
    if dTag.kind[0] ==# 'd'
        let sString = substitute(dTag.cmd[2:-3], '\\t', ' ', 'g')
        let sSignature = matchstr(sString, dTag.name . '\zs(.\{-1,})\ze')
        if sSignature !=# ''
            let dTag.signature = sSignature
            let sWord .= '()'
            let sAbbr .= '()'
        endif
    endif

    let sInfo = ''

    " If a function is a ctor we add a new key in the tag
    " 构造函数处理, 以及友元处理
    "if index(['f', 'p'], dTag.kind[0]) >= 0
        "if match(sName, '^\~') < 0 && a:szTypeName =~ '\C\<'.sName.'$'
            " It's a ctor
            "let dTag['ctor'] = 1
        "elseif has_key(dTag, 'access') && dTag.access == 'friend'
            " Friend function
            "let dTag['friendfunc'] = 1
        "endif
    "endif

    " Extending the tag item to a popup item
    let dTag['word']     = sWord
    let dTag['abbr']     = sAbbr
    let dTag['menu']     = sMenu
    let dTag['info']     = sInfo
    let dTag['icase']    = &ignorecase
    let dTag['dup']      = 0
    "let dTag['dup'] = (s:hasPreviewWindow 
                "\&& index(['f', 'p', 'm'], dTag.kind[0]) >= 0)
    return dTag
endfunc
"}}}
" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/utils.vim	[[[1
730
" Description:  Omni completion utils script
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 11
" License:      GPLv2


" Expression used to ignore comments
" Note: this expression drop drastically the performance
"let omnicpp#utils#sCommentSkipExpr = 
            "\"synIDattr(synID(line('.'), col('.'), 0), 'name') "
            "\"=~? 'comment\\|string\\|character'"
" This one is faster but not really good for C comments
" 匹配了以下字符串后则认为在注释中, 近似测试
" //, /*, */
" BUG: 不知道为什么, 下面的表达式无法工作
"let omnicpp#utils#sCommentSkipExpr = "getline('.') =~# '\\V//\\|/*\\|*/'"
let omnicpp#utils#sCommentSkipExpr = 'omnicpp#utils#CommentSkipChecker()'

function! omnicpp#utils#CommentSkipChecker() "{{{2
    let sLine = getline('.')
    let nCol = col('.')

    " 简单地检查是否注释
    "if sLine =~# '\V^\s*//'
        "return 0
    "endif

    if nCol == 1
        return 0
    else
        let sStr = sLine[nCol-2 : nCol]
        if sStr ==# "'{'" || sStr ==# "'}'"
            return 1
        else
            return 0
        endif
    endif
endfunc
"}}}

let s:dCppBuiltinTypes = {
            \'bool': 1, 
            \'char': 1, 
            \'double': 1, 
            \'float': 1, 
            \'int': 1, 
            \'long': 1, 
            \'short': 1, 
            \'signed': 1, 
            \'unsigned': 1, 
            \'void': 1, 
            \'wchar_t': 1, 
            \'short int': 1, 
            \'long long': 1, 
            \'long double': 1, 
            \'long long int': 1, 
            \}

" 比较两个光标位置 
function! omnicpp#utils#CmpPos(pos1, pos2) "{{{2
    let pos1 = a:pos1
    let pos2 = a:pos2
    if pos1[0] > pos2[0]
        return 1
    elseif pos1[0] < pos2[0]
        return -1
    else
        if pos1[1] > pos2[1]
            return 1
        elseif pos1[1] < pos2[1]
            return -1
        else
            return 0
        endif
    endif
endfunc
"}}}
" 获取当前语句的开始位置, 若当前语句为空, 返回 [0, 0]
" Note: 
"   1. 当前语句的开始位置可能是预处理的行或者字符串或者注释
"      若想剔除预处理的行, 可在获取代码的时候过滤掉
"   2. 返回的位置可能在原始位置的后面, 需要调用者检查
function! omnicpp#utils#GetCurStatementStartPos(...) "{{{2
    let origCursor = getpos('.')
    let origPos = origCursor[1:2]

    let result = [0, 0]

    while searchpos('[;{}]\|\%^', 'bW') != [0, 0]
        if omnicpp#utils#IsCursorInCommentOrString()
            continue
        else
            break
        endif
    endwhile

    if getpos('.')[1:2] == [1, 1] " 到达文件头的话, 接受光标所在位置的匹配
        let result = searchpos('[^ \t]', 'Wc')
    else
        let result = searchpos('[^ \t]', 'W')
    endif

    if a:0 > 0 && a:1
        " 如果传入参数且非零, 移动光标
    else
        call setpos('.', origCursor)
    endif

    return result
endfunc
"}}}
" Get code without comments and with empty strings
" szSingleLine must not have carriage return
" 获取行字符串中的有效 C/C++ 代码, 双引号中的字符串会被清空
" 要求字符串中不能有换行符, 亦即只能处理单行的字符串
" TODO: 清理 # 预处理
function! omnicpp#utils#GetCodeFromLine(szSingleLine) "{{{2

    " 清理预处理
    if match(a:szSingleLine, '^\s*#') >= 0
        return ''
    endif

    " We set all strings to empty strings, it's safer for 
    " the next of the process
    " TODO: '"\"", foo, "foo"'
    " 方法是替换不匹配 \" 的 " 的最小长度的匹配
    let szResult = substitute(a:szSingleLine, '".*"', '""', 'g')

    " Removing C++ comments, we can use the pattern ".*" because
    " we are modifying a line
    let szResult = substitute(szResult, '\/\/.*', '', 'g')

    " Now we have the entire code in one line and we can remove C comments
    if !g:VLOmniCpp_UsePython
        let szResult = s:RemoveCComments(szResult)
    endif

    return szResult
endfunc
"}}}
" Remove C comments on a line
function! s:RemoveCComments(szLine) "{{{2
    let result = a:szLine

    " We have to match the first '/*' and first '*/'
    let startCmt = match(result, '\/\*')
    let endCmt = match(result, '\*\/')
    while startCmt != -1 && endCmt != -1 && startCmt < endCmt
        if startCmt > 0
            let result = result[ : startCmt-1 ] . result[ endCmt+2 : ]
        else
            " Case where '/*' is at the start of the line
            let result = result[ endCmt+2 : ]
        endif
        let startCmt = match(result, '\/\*')
        let endCmt = match(result, '\*\/')
    endwhile
    return result
endfunc
"}}}
" Get a c++ code from current buffer from [lineStart, colStart] to 
" [lineEnd, colEnd] without c++ and c comments, without end of line
" and with empty strings if any
" @return a string
function! omnicpp#utils#GetCode(posStart, posEnd) "{{{2
    "TODO: 处理反斜杠续行
    let posStart = a:posStart
    let posEnd = a:posEnd
    if a:posStart[0] > a:posEnd[0]
        let posStart = a:posEnd
        let posEnd = a:posStart
    elseif a:posStart[0] == a:posEnd[0] && a:posStart[1] > a:posEnd[1]
        let posStart = a:posEnd
        let posEnd = a:posStart
    endif

    " Getting the lines
    let lines = getline(posStart[0], posEnd[0])
    let lenLines = len(lines)

    " Formatting the result
    let result = ''
    if lenLines == 1
        let sStart = posStart[1] - 1
        let sEnd = posEnd[1] - 1
        let line = lines[0]
        let lenLastLine = strlen(line)
        let sEnd = (sEnd > lenLastLine) ? lenLastLine : sEnd
        if sStart >= 0
            let result = omnicpp#utils#GetCodeFromLine(line[ sStart : sEnd ])
        endif
    elseif lenLines > 1
        let sStart = posStart[1] - 1
        let sEnd = posEnd[1] - 1
        let lenLastLine = strlen(lines[-1])
        let sEnd = (sEnd > lenLastLine)?lenLastLine : sEnd
        if sStart >= 0
            let lines[0] = lines[0][ sStart : ]
            let lines[-1] = lines[-1][ : sEnd ]
            for aLine in lines
                let result = result . omnicpp#utils#GetCodeFromLine(aLine)." "
            endfor
            let result = result[:-2]
        endif
    endif

    " Now we have the entire code in one line and we can remove C comments
    if !g:VLOmniCpp_UsePython
        let result = s:RemoveCComments(result)
    endif

    return result
endfunc
"}}}
"{{{2
function! omnicpp#utils#GetCodeLines(lStartPos, lEndPos)
    let lStartPos = a:lStartPos
    let lEndPos = a:lEndPos
    let lLines = getline(lStartPos[0], lEndPos[0])

    if empty(lLines)
        return []
    endif

    if lStartPos[0] == lEndPos[0]
        let lLines[0] = lLines[0][lStartPos[1] : lEndPos[1]-1]
    else
        let lLines[0] = lLines[0][lStartPos[1] :]
        let lLines[-1] = lLines[-1][: lEndPos[1]-1]
    endif

    return lLines
endfunc
"}}}
" Check if the cursor is in comment or string
" 根据语法检测光标是否在注释或字符串中或 include 预处理中
function! omnicpp#utils#IsCursorInCommentOrString() "{{{2
    " FIXME: case. |"abc" . 判定为在字符串中
    let lStack = synstack(line('.'), col('.'))
    let lStack = empty(lStack) ? [] : lStack
    for nID in lStack
        if synIDattr(nID, 'name') =~? 'comment\|string\|character'
            return 1
        endif
    endfor
    return 0
endfunc
"}}}
" Tokenize the current instruction until the cursor position.
" Param:    可选参数为附加字符串, 或控制是否简化代码为 omni 分析用 tokens
" Return:   list of tokens
function! omnicpp#utils#TokenizeStatementBeforeCursor(...) "{{{2
    let szAppendText = ''
    let bSimplify = 0
    if a:0 > 0 && type(a:1) == type('')
        let szAppendText = a:1
    elseif a:0 > 0 && type(a:1) == type(0)
        let bSimplify = a:1
    endif

    " TODO: 排除注释和字符串中的匹配
    let startPos = searchpos('[;{}]\|\%^', 'bWn')
    let curPos = getpos('.')[1:2]
    " We don't want the character under the cursor
    let column = curPos[1] - 1
    let curPos[1] = column
    " Note: [1:] 剔除了上一条语句的结束符
    if curPos[1] < 1
        let curPos[1] = 1
        " 当光标在第一列的时候, 会包含第一列的字符. 剔除之.
        let szCode = omnicpp#utils#GetCode(startPos, curPos)[1:-2] . szAppendText
    else
        let szCode = omnicpp#utils#GetCode(startPos, curPos)[1:] . szAppendText
    endif
    " 若使用 python 实现的 omnicpp#tokenizer#Tokenize(), 无须预处理
    if bSimplify && !g:VLOmniCpp_UsePython
        let szCode = omnicpp#utils#SimplifyCodeForOmni(szCode)
    endif
    return omnicpp#tokenizer#Tokenize(szCode)
endfunc
"}}}
function! omnicpp#utils#GetCurStatementBeforeCursor(...) "{{{
    let bSimplify = 0
    if a:0 > 0
        let bSimplify = a:1
    endif

    let curPos = getpos('.')[1:2]
    let startPos = omnicpp#utils#GetCurStatementStartPos()
    " 不包括光标下的字符
    let szCode = omnicpp#utils#GetCode(startPos, curPos)[:-2]
    " 若使用 python 实现的 omnicpp#tokenizer#Tokenize(), 无须预处理
    if bSimplify && !g:VLOmniCpp_UsePython
        let szCode = omnicpp#utils#SimplifyCodeForOmni(szCode)
    endif

    return szCode
endfunc
"}}}
" 简化 omni 补全请求代码, 效率不是太高
" eg1. A::B("\"")->C(" a(\")z ", ')'). -> A::B()->C().
" eg2. ((A*)(B))->C. -> ((A*)B)->C.
" cg3. static_cast<A*>(B)->C. -> (A*)B->C.
" egx. A::B(C.D(), ((E*)F->G)). -> A::B().
function! omnicpp#utils#SimplifyCodeForOmni(sOmniCode) "{{{2
    let s = a:sOmniCode
    
    " 1. 清理函数函数
    let s = s:StripFuncArgs(s)
    " 2. 把 C++ 的 cast 转为 标准 C 的 cast
    "    %s/\%(static_cast\|dynamic_cast\)\s*<\(.\+\)>(\(\w\+\))/((\1)\2)/gc
    "let s = substitute(
                "\s, 
                "\'\C\%(static_cast\|dynamic_cast\|reinterpret_cast' 
                "\    .'\|const_cast\)\s*<\(.\+\)>(\(\w\+\))', 
                "\'((\1)\2)', 
                "\'g')
    " 逐字符处理 C++ 的 cast
    " 3. 清理多余的括号, 不会检查匹配的情况. eg. ((A*)((B))) -> ((A*)B)
    " TODO: 需要更准确
    "let s = substitute(s, '\W\zs(\+\(\w\+\))\+\ze', '\1', 'g')

    return s
endfunc
"}}}
" 剔除所有函数参数, 仅保留一个括号
function! s:StripFuncArgs(szOmniCode) "{{{2
    let s = a:szOmniCode

    " 1. 清理引号内的 \" , 因为正则貌似是不能直接匹配 ("\"")
    "let s = substitute(s, '\\"', '', 'g')
    " 2. 清理双引号的内容, 否则双引号内的括号会干扰括号替换
    "let s = substitute(s, '".\{-}"', '', 'g')
    " 1.2. 清理双引号内的内容, 替换成仅双引号
    let s = substitute(s, '"\([^"]\|\\\@<="\)*"', '""', 'g')
    " 3. 清理 '(' 和 ')', 避免干扰
    " 也可直接替换成标准的单个 char, 如 'x'
    let s = substitute(s, "'('\\|')'", '', 'g')

    let szResult = ''
    let nStart = 0
    while nStart < len(s) && nStart != -1
        let nEnd = matchend(s, '\w\s*(', nStart)
        if nEnd != -1
            let szResult .= s[nStart : nEnd - 1]

            let nStart = nEnd
            let nCount = 1
            " 开始寻找匹配的 ) 的位置
            for i in range(nStart, len(s) - 1)

                let c = s[i]

                if c == '('
                    let nCount += 1
                elseif c == ')'
                    let nCount -= 1
                endif

                if nCount == 0
                    let nStart = i + 1
                    let szResult .= ')'
                    break
                endif
            endfor

        else
            let szResult .= s[nStart :]
            break
        endif
    endwhile

    return szResult
endfunc
"}}}
" 从 dTypeInfo 的 types 字段填充 dTypeInfo.name 和 dTypeInfo.til
function omnicpp#utils#FillTypeInfoByTypesField(dTypeInfo) "{{{2
    let dTypeInfo = a:dTypeInfo

    if empty(dTypeInfo)
        return
    endif

    let li = []
    for dUnitType in dTypeInfo.types
        call add(li, dUnitType.name)
    endfor

    let dTypeInfo.name = substitute(join(li, '::'), '^<global>', '', '')
    try
        let dTypeInfo.til = dTypeInfo.types[-1].til
    catch
        let dTypeInfo.til = []
    endtry
endfunc
"}}}
" 从一条语句中获取变量信息, 无法判断是否非法声明
" eg1. const MyClass&
" eg2. const map < int, int >&
" eg3. MyNs::MyClass
" eg4. ::MyClass**
" eg5. MyClass a, *b = NULL, c[1] = {};
" eg6. A<B>::C::D<E, F>::G g;
" eg7. hello(MyClass1 a, MyClass2* b
" eg8. Label: A a;
function! omnicpp#utils#GetVariableType(sDecl, ...) "{{{2
    if type(a:sDecl) == type('')
        let lTokens = omnicpp#tokenizer#Tokenize(a:sDecl)
    else
        let lTokens = a:sDecl
    endif

    let sVarName = ''
    if a:0 > 0
        let sVarName = a:1
    endif

    let dTypeInfo = {'name': '', 'til': [], 'types': []}

    let idx = 0
    let nState = 0
    " 0 -> 期望 '::' 和 单词, 作为解析的起点. eg1. |::A eg2. |A::B
    " 1 -> 期望 单词. eg. A::|B
    " 2 -> 期望 '::'. eg. A|::B 也可能是 A|<B>::C
    while idx < len(lTokens)
        let dCurToken = lTokens[idx]
        if nState == 0
            if dCurToken.value ==# '::'
                " eg. ::A a
                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = '<global>'
                call add(dTypeInfo.types, dSingleType)

                let nState = 1
            elseif dCurToken.kind == 'cppWord'
                if dCurToken.value ==# sVarName
                    " 遇到同名的, 检查前一个 token, 若不是 'struct' 之类的, 
                    " 肯定不是有效的声明, 肯定在之前已经定义了, 结束
                    if idx - 1 >= 0 && index(['struct', 'union', 'enum'], 
                                \            lTokens[idx-1].value) != -1
                        " 有效的声明, 不做任何事
                    else
                        break
                    endif
                endif

                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = dCurToken.value
                call add(dTypeInfo.types, dSingleType)

                let nState = 2
            elseif dCurToken.kind == 'cppKeyword'
                if has_key(s:dCppBuiltinTypes, dCurToken.value)
                    let dTypeInfo.name .= dCurToken.value

                    " unsigned *
                    if dCurToken.value ==# 'unsigned' && idx + 1 < len(lTokens)
                        let idx += 1
                        let dCurToken = lTokens[idx]
                        if dCurToken.kind == 'cppKeyword' 
                                    \&& has_key(s:dCppBuiltinTypes, 
                                    \           dCurToken.value)
                            let dTypeInfo.name .= ' ' . dCurToken.value
                        endif
                    endif

                    " short int
                    " long long
                    " long long int
                    " long double
                    if dCurToken.value ==# 'long'
                        let idx = idx + 1
                        while idx < len(lTokens)
                            if lTokens[idx].value =~# 'long\|int\|double'
                                let dTypeInfo.name .= 
                                            \' ' . lTokens[idx].value
                            else
                                let idx -= 1
                                break
                            endif
                            let idx += 1
                        endwhile
                    elseif dCurToken.value ==# 'short'
                        if idx + 1 < len(lTokens) 
                                    \&& lTokens[idx+1].value ==# 'int'
                            let dTypeInfo.name .= 
                                        \' ' . lTokens[idx+1].value
                            let idx = idx + 1
                        endif
                    endif

                    let dSingleType = {'name': '', 'til': []}
                    let dSingleType.name = dTypeInfo.name
                    call add(dTypeInfo.types, dSingleType)

                    " 内置类型, 可能结束, 需要检查此语法是否有函数
                    let nState = 2
                endif
            elseif dCurToken.value ==# '('
                " 可能是一个 cast, 需要跳至匹配的 ')' 之后的位置
                " eg. (A *)&B;
                " 也可能是 for ( A a
                if idx - 1 >= 0 && lTokens[idx-1].value ==# 'for'
                    " for ( A a
                else
                    let nTmpIdx = idx
                    let nTmpCount = 0
                    while nTmpIdx < len(lTokens)
                        let dTmpToken = lTokens[nTmpIdx]
                        if dTmpToken.value ==# '('
                            let nTmpCount += 1
                        elseif dTmpToken.value ==# ')'
                            let nTmpCount -= 1
                            if nTmpCount == 0
                                break
                            endif
                        endif
                        let nTmpIdx += 1
                    endwhile

                    let idx = nTmpIdx
                endif
            endif
        elseif nState == 1
            if dCurToken.kind == 'cppWord'
                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = dCurToken.value
                call add(dTypeInfo.types, dSingleType)

                let nState = 2
            else
                " 有语法错误?
                " eg. A::| *
                break
            endif
        elseif nState == 2
            if dCurToken.value ==# '::'
                let dTypeInfo.name .= dCurToken.value
                let nState = 1
            elseif dCurToken.value ==# '<'
                " 上一个解析完毕的标识符是模版类
                let nTmpIdx = idx
                let nTmpCount = 0
                let sUnitType = ''
                while nTmpIdx < len(lTokens)
                    let dTmpToken = lTokens[nTmpIdx]
                    if dTmpToken.value ==# '<'
                        let nTmpCount += 1
                        if nTmpCount == 1
                            let sUnitType = ''
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    elseif dTmpToken.value ==# '>'
                        let nTmpCount -= 1
                        if nTmpCount == 0
                            call add(dTypeInfo.types[-1].til, sUnitType)
                            break
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    elseif dTmpToken.value ==# ','
                        if nTmpCount == 1
                            call add(dTypeInfo.types[-1].til, sUnitType)
                            let sUnitType = ''
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    else
                        " 会有比较多多余的空格
                        let sUnitType .= ' ' . dTmpToken.value
                    endif
                    let nTmpIdx += 1
                endwhile

                let idx = nTmpIdx
            elseif dCurToken.value ==# '('
                " 处理函数形参中的变量声明
                " 之前分析的是函数, 重新再来
                let dTypeInfo = {'name': '', 'til': [], 'types': []}
                let nState = 0

                let nRestartIdx = idx + 1
                let nTmpIdx = nRestartIdx
                let nTmpCount = 0 " 记录 '<' 的数量
                while sVarName !=# '' && nTmpIdx < len(lTokens)
                    let dTmpToken = lTokens[nTmpIdx]
                    if dTmpToken.value ==# '<'
                        let nTmpCount += 1
                    elseif dTmpToken.value ==# '>'
                        let nTmpCount -= 1
                    " NOTE: Tokenize 函数有 bug, '"",' 和 "''," 作为单个 token
                    elseif dTmpToken.value ==# ','
                                \|| dTmpToken.value ==# '"",' 
                                \|| dTmpToken.value ==# "'',"
                        if nTmpCount == 0
                            let nRestartIdx = nTmpIdx + 1
                        endif
                    elseif dTmpToken.kind == 'cppWord' 
                                \&& dTmpToken.value ==# sVarName
                        break
                    endif
                    let nTmpIdx += 1
                endwhile

                let idx = nRestartIdx
                continue
            else
                " 期望 '::', 遇到了其他东东
                if dCurToken.value ==# ':'
                    " 遇到标签, 重新开始
                    " eg. Label: A a;
                    let dTypeInfo = {'name': '', 'til': [], 'types': []}
                else
                    " 检查是否有函数
                    " eg. int |A(B b, C c)
                    let nTmpIdx = idx + 1
                    let nHasFunc = 0
                    while nTmpIdx < len(lTokens)
                        let dTmpToken = lTokens[nTmpIdx]
                        if dTmpToken.value ==# '(' 
                            " 有函数, 进入函数处理入口
                            let idx = nTmpIdx
                            let nHasFunc = 1
                            break
                        endif
                        let nTmpIdx += 1
                    endwhile

                    if nHasFunc
                        continue
                    else
                        break
                    endif
                endif
            endif
        endif

        let idx += 1
    endwhile

    if len(dTypeInfo.types)
        let dTypeInfo.til = dTypeInfo.types[-1].til
    endif

    return dTypeInfo
endfunc
"}}}
" 从 TypeInfo 生成类型代码字符串
function! omnicpp#utils#GenCodeFromTypeInfo(dTypeInfo) "{{{2
    let dTypeInfo = a:dTypeInfo
    let sResult = ''
    if empty(dTypeInfo)
        return sResult
    endif

    let lUnitTypes = []

    for dSingleType in dTypeInfo.types
        let sUnitType = dSingleType.name
        if !empty(dSingleType.til)
            let sUnitType .= '< ' . join(dSingleType.til, ',') . ' >'
        endif
        call add(lUnitTypes, sUnitType)
    endfor

    let sResult = join(lUnitTypes, '::')

    " 剔除 <global>
    " eg. <global>::std::map<A,B> -> ::std::map<A,B>
    let sResult = substitute(sResult, '^<global>', '', '')

    return sResult
endfunc
"}}}
function! omnicpp#utils#JoinTypeInfo(...) "{{{2
    let dResult = {}
    let lNames = []
    let lTypes = []
    for dTypeInfo in a:000
        if dTypeInfo.name !=# ''
            call add(lNames, dTypeInfo.name)
        endif
        call extend(lTypes, dTypeInfo.types)
    endfor

    let dResult.name = join(lNames, '::')
    let dResult.types = lTypes
    let dResult.til = dResult.types[-1].til
    return dResult
endfunc
"}}}
" 剔除 TypeInfo 左则指定数量的单元类型(作用域)
" NOTE: 直接修改传入的参数 'dTypeInfo'
function! omnicpp#utils#StripLeftTypes(dTypeInfo, nCount) "{{{2
    let dTypeInfo = a:dTypeInfo
    let nCount = a:nCount
    if !empty(dTypeInfo)
        call remove(dTypeInfo.types, 0, nCount - 1)
    endif

    call omnicpp#utils#FillTypeInfoByTypesField(dTypeInfo)
endfunc
"}}}
" 剔除列表相同的元素, 删除后出现的所有重复元素
function! omnicpp#utils#FilterListSameElement(lList) "{{{2
    let lList = a:lList

    let nLen = len(lList)
    let nIdx = 0
    let dGuard = {}
    while nIdx < nLen
        let element = lList[nIdx]
        if !has_key(dGuard, element)
            let dGuard[element] = 1
        else
            call remove(lList, nIdx)
            let nLen -= 1
            continue
        endif

        let nIdx += 1
    endwhile
endfunc
"}}}
" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/scopes.vim	[[[1
408
" Description:  Omni completion script for resolve namespace
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 13
" License:      GPLv2

" Note1: 只解析当前文件的全局名空间和当前局部作用域的名空间, 不解析包含的文件的
"        因为, 不应该在包含的文件使用名空间
" Note2: 只支持在函数中(局部作用域)和文件中(全局作用域)使用名空间
" Note3: 只能解析具备良好风格习惯的代码, 因为始终不是编译器, 
"        即使有能力解析, 但是代价也会变大, 速度会下降

" Scope 数据结构
" {
" 'kind':       <'file'|'container'|'function'|'other'>, 
" 'name':       <scope name>, 
" 'nsinfo':     <NSInfo>, 
" 'includes':   [<header1>, <header2>, ...]
" }
"
" 'kind' 的 'container' 意即 'namespace'|'class'|'struct'|'union'
" 'kind' 为 'file' 时, 'name' 为当前文件名(绝对路径).
" 'includes' 的列表项均为绝对路径. 一般只有在 'kind' 为 'file' 时才可能为非空.

" ScopeStack 数据结构
" [<scope1>, <scope2>, ...]
"
" 首元素 scope 的 'kind' 必为 'file', 亦即, 首元素必为全局作用域
" 若视为栈的话, 底部为首元素, 顶部为尾元素

" 新建 scope 数据结构
function! s:NewScope() "{{{2
    return {
                \'kind': '', 
                \'name': '', 
                \'nsinfo': {'usingns': [], 'using': {}, 'nsalias': {}}, 
                \'includes': []}
endfunc
"}}}

" 返回当前作用域栈
function! omnicpp#scopes#GetScopeStack() "{{{2
    " 一路往上搜索 {} 块, 分析 { 前的语句, 从而确定块的信息, 添加到结果的开头
    " 如此重复

    " We store the cursor position because searchpairpos() moves the cursor
    let lOrigCursor = getpos('.')
    let lEndPos = lOrigCursor[1:2]
    let lScopeStack = []

    " 名空间搜索的开始位置
    let lSearchStartPos = lEndPos[:]

    " 标识是否第一次进入
    let bFirstEnter = 1

    " 往上分析每个 {} 块, 以生成作用域栈
    while lEndPos != [0, 0]
        if bFirstEnter
            " 处理正在类初始化列表的位置的情况
            let bFirstEnter = 0
            let sCurStatement = omnicpp#utils#GetCurStatementBeforeCursor()
            if match(sCurStatement, ')\s*:') != -1
                " 在类初始化列表的位置, 把位置放到初始化开始(':')的前面
                let lEndPos = searchpos(':', 'bW')
            else
                " {} 块的 { 位置
                let lEndPos = searchpairpos('{', '', '}', 'bW', 
                            \g:omnicpp#utils#sCommentSkipExpr)
            endif
        else
            " {} 块的 { 位置
            let lEndPos = searchpairpos('{', '', '}', 'bW', 
                        \g:omnicpp#utils#sCommentSkipExpr)
        endif

        " 单独处理 for ( A; B; C ) 的情形
        let lTmpCursor = getpos('.')
        " for ( A; B; C ) 或 for ( A; B; C ) {
        "               ^                  ^
        let lTmpPos = searchpos(')\s*$\|)\s*{\s*$', 'Wb')
        " 只考虑 ) 和 { 相隔不超过一行
        if lTmpPos != [0, 0] && lTmpCursor[1] - lTmpPos[0] <= 1
            let sSkipExpr = ''
            "if g:VLOmniCpp_EnableSyntaxTest
                "let sSkipExpr = 
                            "\'synIDattr(synID(line("."), col("."), 0), "name") '
                            "\. '=~? "string\\|character\\|comment"'
            "else
                "let sSkipExpr = ''
            "endif
            call searchpair('(', '', ')', 'bW', sSkipExpr)
            if getline('.')[:col('.')-1] =~# 'for\s*($'
                " 找到了 for
                let dCurScope = s:NewScope()
                let dCurScope.kind = 'other'
                let dCurScope.name = 'for'
                let lScopeStack = [dCurScope] + lScopeStack

                let lSearchStartPos = lEndPos[:]
                call setpos('.', lTmpCursor)
                continue
            endif
        endif
        call setpos('.', lTmpCursor)

        " FIXME: 无法获取 for 作用域. eg. for( A; B; C ) | { }
        let sReStartPos = '[;{}]\|\%^'
		"搜索 {} 块前的语句的开始位置, 用于获取之间的文本以分析
        let lStartPos = searchpairpos(sReStartPos, '', '{', 'bWn', 
                    \g:omnicpp#utils#sCommentSkipExpr)

        " If the file starts with a comment so the lStartPos can be [0,0]
        " we change it to [1,1]
        " 如果搜索失败, 定位光标至开始处
        " FIXME: 以下情况, 获取了两个包含文件的行
        " #include <stdio.h>
        " #include <stdlib.h>
        " class MyClass |{
        if lStartPos == [0, 0]
            let lStartPos = [1, 1]
        endif

        " Get lines backward from cursor position to last ; or { or }
        " or when we are at the beginning of the file.
        if lEndPos != [0, 0]
            " We remove the last character which is a '{'
            " We also remove starting { or } or ; if exists
			" 获取 {} 块前的一条有效语句代码并剔除前面和后面的多余字符
			" 结果 eg. '   int main(int argc, char **argv)'
            if exists('g:VLOmniCpp_UsePython') && g:VLOmniCpp_UsePython
                let lLines = omnicpp#utils#GetCodeLines(lStartPos, lEndPos)
                let g:lLines = lLines
                let lTokens = omnicpp#tokenizer#TokenizeLines(lLines)
            else
                let sCode= substitute(
                            \omnicpp#utils#GetCode(lStartPos, lEndPos)[:-2], 
                            \'^[;{}]', '', 'g')
                let lTokens = omnicpp#tokenizer#Tokenize(sCode)
            endif
            let dCurScope = s:NewScope()

            let nLen = len(lTokens)
            let nScopeType = 0 " 0 表示无名块类别
            let idx = 0
            while idx < nLen
                let dToken = lTokens[idx]

                " 首先查找能确定类别的关键字符
                " 1. 容器类别 'namespace|class|struct|union'. eg. class A
                " 2. 作用域类别 '::'. eg. A B::C::D(E)
                " 3. 函数类别 '('. eg. A B(C)
                if dToken.kind == 'cppKeyword' 
                            \&& index(['namespace', 'class', 'struct', 'union'],
                            \   dToken.value) >= 0
                    " 容器类别
                    let nScopeType = 1
                    let dCurScope.kind = 'container'
                    let dCurScope.name = lTokens[idx+1].value
                    " 暂不支持在容器类型里使用名空间
                    "let dCurScope.namespaces = 
                    let lScopeStack = [dCurScope] + lScopeStack

                    break
                elseif  dToken.kind == 'cppKeyword' && dToken.value ==# 'else'
                    " else 条件语句
                    " eg1. else {
                    " eg2. else if {
                    let dCurScope = s:NewScope()
                    let dCurScope.kind = 'other'
                    let dCurScope.name = dToken.value
                    let dCurScope.nsinfo = s:GetNamespaceInfo(
                                \lSearchStartPos[0])
                    let lScopeStack = [dCurScope] + lScopeStack
                    break
                elseif  dToken.kind == 'cppKeyword' 
                            \&& dToken.value =~# 'case\|default'
                    " case 条件语句
                    " eg1. case 1: {
                    " eg2. default: {
                    let dCurScope = s:NewScope()
                    let dCurScope.kind = 'other'
                    let dCurScope.name = dToken.value
                    let dCurScope.nsinfo = s:GetNamespaceInfo(
                                \lSearchStartPos[0])
                    let lScopeStack = [dCurScope] + lScopeStack
                    break
                elseif dToken.kind == 'cppOperatorPunctuator' 
                            \&& dToken.value == '::'
                    " 作用域类别
                    let nScopeType = 2
                    let lTmpScopeStack = []

                    " FIXME: 不能处理释构函数 eg. A::~A()
                    " 现在会把析构函数解析为构造函数
                    " 由于现在基于 ctags 的 parser, 会无视函数作用域,
                    " 所以暂时工作正常

                    " 无法分辨类型到底是 namespace 还是 class
                    let dCurScope.kind = 'container'
                    let dCurScope.name = lTokens[idx-1].value
                    let lTmpScopeStack = lTmpScopeStack + [dCurScope]

                    " 继续分析
                    " 方法都是遇到操作符('::', '(')后确定前一个 token 的类别
                    let j = idx + 1
                    while j < nLen
                        let dToken = lTokens[j]
                        if dToken.kind == 'cppOperatorPunctuator' 
                                    \&& dToken.value == '('

                            let dCurScope = s:NewScope()
                            if lTokens[j-1].kind == 'cppKeyword'
                                " eg. if (), while (), switch () ...
                                let dCurScope.kind = 'other'
                            else
                                let dCurScope.kind = 'function'
                            endif
                            "let dCurScope.kind = 'function'
                            let dCurScope.name = lTokens[j-1].value
                            let dCurScope.nsinfo = s:GetNamespaceInfo(
                                        \lSearchStartPos[0])
                            " 添加方法与外部的循环是不同的
                            let lTmpScopeStack =  lTmpScopeStack + [dCurScope]

                            " 到了函数参数或条件判断位置, 已经完成
                            break
                        endif

                        if dToken.kind == 'cppOperatorPunctuator' 
                                    \&& dToken.value == '::'
                            let dCurScope = s:NewScope()
                            let dCurScope.kind = 'container'
                            let dCurScope.name = lTokens[j-1].value
                            " 添加方法与外部的循环是不同的
                            let lTmpScopeStack =  lTmpScopeStack + [dCurScope]
                        endif

                        let j += 1
                    endwhile

                    let lScopeStack = lTmpScopeStack + lScopeStack

                    break
                elseif dToken.kind == 'cppOperatorPunctuator' 
                            \&& dToken.value == '('
                    " 函数或条件类别
                    let nScopeType = 3
                    if lTokens[idx-1].kind == 'cppKeyword'
                        let dCurScope.kind = 'other'
                    else
                        let dCurScope.kind = 'function'
                    endif
                    let dCurScope.name = lTokens[idx-1].value
                    " Note: nsinfo 属性暂时只支持在函数中和文件中存在
                    let dCurScope.nsinfo = s:GetNamespaceInfo(
                                \lSearchStartPos[0])
                    let lScopeStack = [dCurScope] + lScopeStack

                    break
                else
                    " TODO
                    " 可能是一个无名块, 默认应该视为 other 类型
                endif

                let idx += 1
            endwhile
        endif

        let lSearchStartPos = lEndPos[:]
    endwhile

    let dGlobalScope = s:NewScope()
    let dGlobalScope.kind = 'file'
    let dGlobalScope.name = expand('%:p')
    let dGlobalScope.nsinfo = s:GetNamespaceInfo(getpos('.')[1], 1)
    "let dGlobalScope.includes = omnicpp#includes#GetIncludeFiles()
    let lScopeStack = [dGlobalScope] + lScopeStack

    " Setting the cursor to the original position
    call setpos('.', lOrigCursor)

    return lScopeStack
endfunc
"}}}
" 可选参数非零, 搜索全局作用域
function! s:GetNamespaceInfo(nStopLine, ...) "{{{2
    let nStopLine = a:nStopLine
    let dNSInfo = {'using': [], 'usingns': [], 'nsalias': {}}

    let bGlobal = 0
    if a:0 > 0
        let bGlobal = a:1
    endif

    let lOrigCursor = getpos('.')
    exec nStopLine
    call setpos('.', [0, nStopLine, col('$'), 0])

    if bGlobal
        let nStartLine = 1
    else
        let nStartLine = omnicpp#scopes#GetCurBlockStartPos()[0]
    endif

    call setpos('.', lOrigCursor)

    return s:DoGetNamespaceInfo(nStartLine, nStopLine, bGlobal)
endfunc
"}}}
" 获取 nStartLine 到 nStopLine 之间(包括 nStopLine)的名空间信息
" 仅处理风格良好的写法, 例如一行一个指令.
" 可选参数非零, 搜索全局作用域
" Return: NSInfo 字典
" {
" 'nsalias': {}     <- namespace alias
" 'using': {}       <- using 语句
" 'usingns': []     <- using namespace
" }
function! s:DoGetNamespaceInfo(nStartLine, nStopLine, ...) "{{{2
    let dNSInfo = {'usingns': [], 'using': {}, 'nsalias': {}}
    let lOrigCursor = getpos('.')

    let bGlobal = 0
    if a:0 > 0
        let bGlobal = a:1
    endif

    call setpos('.', [0, a:nStartLine, 1, 0])
    let lCurPos = [a:nStartLine, 1]
    let bFirstEnter = 1
    while 1
        if bFirstEnter
            let bFirstEnter = 0
            let sFlag = 'Wc'
        else
            let sFlag = 'W'
        endif
        if bGlobal
            let sRE = '\C^using\s\+\|^\s*namespace\s\+'
        else
            let sRE = '\C^\s*using\s\+\|^\s*namespace\s\+'
        endif
        let lCurPos = searchpos(sRE, sFlag, a:nStopLine)

        if lCurPos != [0, 0]
            let sLine = getline('.')
            if sLine =~# '^\s*using'
                if sLine =~# 'namespace'
                    " using namespace
                    let sUsingNS = matchstr(sLine, 
                                \'\Cusing\s\+namespace\s\+\zs[a-zA-Z0-9_:]\+')
                    call add(dNSInfo.usingns, sUsingNS)
                else
                    " using
                    let sUsing = matchstr(sLine, 
                                \'\Cusing\s\+\zs[a-zA-Z0-9_:]\+')
                    let sUsingKey = matchstr(sUsing, '::\zs\w\+$')
                    if sUsingKey != ''
                        let dNSInfo.using[sUsingKey] = sUsing
                    endif
                endif
            else
                " 名空间别名
                let sNSAliasKey = matchstr(sLine, '\w\+\ze\s*=')
                let sNSAliasValue = matchstr(sLine, '=\s*\zs[a-zA-Z0-9_:]\+')
                if sNSAliasKey != ''
                    let dNSInfo.nsalias[sNSAliasKey] = sNSAliasValue
                endif
            endif
        else
            break
        endif
    endwhile

    call setpos('.', lOrigCursor)
    return dNSInfo
endfunc
"}}}
" 返回当前 {} 块的开始位置
" 若传入参数且非 0, 会移动光标至开始位置
" 若不在 {} 块中, 返回 [0, 0]
function! omnicpp#scopes#GetCurBlockStartPos(...) "{{{2
    if a:0 > 0 && a:1
        let sFlag = 'bW'
    else
        let sFlag = 'bWn'
    endif
    let lStartPos = searchpairpos('{', '', '}', sFlag, 
                \g:omnicpp#utils#sCommentSkipExpr)
    return lStartPos
endfunc
"}}}
" 返回当前 {} 块的结束位置
" 若传入参数且非 0, 会移动光标至开始位置
" 若不在 {} 块中, 返回 [0, 0]
function! omnicpp#scopes#GetCurBlockEndPos(...) "{{{2
    if a:0 > 0 && a:1
        let sFlag = 'W'
    else
        let sFlag = 'Wn'
    endif
    let lStartPos = searchpairpos('{', '', '}', sFlag, 
                \g:omnicpp#utils#sCommentSkipExpr)
    return lStartPos
endfunc
"}}}

" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/settings.vim	[[[1
52
" Description:  Omnicpp completion init settings
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 15
" License:      GPLv2

"Return: 1 表示赋值为默认, 否则返回 0
function! s:InitVariable(var, value) "{{{2
    if !exists(a:var)
        let {a:var} = a:value
        return 1
    endif
    return 0
endfunction
"}}}2

function! omnicpp#settings#Init() "{{{1
    " Show all class members (static, public, protected and private)
    call s:InitVariable('g:VLOmniCpp_ShowAllClassMember', 0)

    " Show the access symbol (+,#,-)
    call s:InitVariable('g:VLOmniCpp_ShowAccessSymbol', 1)

    " MayComplete to '.'
    call s:InitVariable('g:VLOmniCpp_MayCompleteDot', 1)

    " MayComplete to '->'
    call s:InitVariable('g:VLOmniCpp_MayCompleteArrow', 1)

    " MayComplete to '::'
    call s:InitVariable('g:VLOmniCpp_MayCompleteColon', 1)

    " 启用语法测试(速度相当慢), 若感觉太慢, 可关闭, 代价是补全分析正确率下降
    call s:InitVariable('g:VLOmniCpp_EnableSyntaxTest', 1)

    " 把回车映射为: 
    " 在补全菜单中选择并结束补全时, 若选择的是函数, 自动显示函数参数提示
    call s:InitVariable('g:VLOmniCpp_MapReturnToDispCalltips', 1)

    " When completeopt does not contain longest option, this setting 
    " controls the behaviour of the popup menu selection 
    " when starting the completion
    "   0 = don't select first item
    "   1 = select first item (inserting it to the text)
    "   2 = select first item (without inserting it to the text)
    "   default = 2
    call s:InitVariable('g:VLOmniCpp_ItemSelectionMode', 2)

    " 尽量使用 python
    call s:InitVariable('g:VLOmniCpp_UsePython', 1)
endfunc

" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/tokenizer.vim	[[[1
148
" Description:  Omnicpp completion tokenizer
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 11
" License:      GPLv2

" TODO: Generic behaviour for Tokenize()

" C++ 的关键词列表
" From the C++ BNF
let s:cppKeyword = ['asm', 'auto', 'bool', 'break', 'case', 'catch', 'char', 
            \'class', 'const', 'const_cast', 'continue', 'default', 'delete', 
            \'do', 'double', 'dynamic_cast', 'else', 'enum', 'explicit', 
            \'export', 'extern', 'false', 'float', 'for', 'friend', 'goto', 
            \'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new', 
            \'operator', 'private', 'protected', 'public', 'register', 
            \'reinterpret_cast', 'return', 'short', 'signed', 'sizeof', 
            \'static', 'static_cast', 'struct', 'switch', 'template', 'this', 
            \'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union', 
            \'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t', 
            \'while', 'and', 'and_eq', 'bitand', 'bitor', 'compl', 'not', 
            \'not_eq', 'or', 'or_eq', 'xor', 'xor_eq']

" 用于匹配 C++ 关键词的正则表达式
let s:reCppKeyword = '\C\<'.join(s:cppKeyword, '\>\|\<').'\>'

" The order of items in this list is very important because we use this list to 
" build a regular expression (see below) for tokenization
" C++ 操作符和标点符号列表, 顺序非常重要, 因为这用于生成用于标记化的正则表达式
let s:cppOperatorPunctuator = ['->*', '->', '--', '-=', '-', '!=', '!', '##', 
            \'#', '%:%:', '%=', '%>', '%:', '%', '&&', '&=', '&', '(', ')', 
            \'*=', '*', ',', '...', '.*', '.', '/=', '/', '::', ':>', ':', 
            \';', '?', '[', ']', '^=', '^', '{', '||', '|=', '|', '}', '~', 
            \'++', '+=', '+', '<<=', '<%', '<:', '<<', '<=', '<', '==', '=', 
            \'>>=', '>>', '>=', '>']

" We build the regexp for the tokenizer
" 用于标记化的正则表达式
let s:reCComment = '\/\*\|\*\/'
let s:reCppComment = '\/\/'
let s:reComment = s:reCComment.'\|'.s:reCppComment
let s:reCppOperatorOrPunctuator = escape(
            \join(s:cppOperatorPunctuator, '\|'), '*./^~[]')

try
    call omnicpp#settings#Init()
catch
    " 默认使用 python
    let g:VLOmniCpp_UsePython = 1
endtry

if exists('g:VLOmniCpp_UsePython') && g:VLOmniCpp_UsePython
"py import sys
"py sys.path.append(os.path.expanduser('~/.vimlite/VimLite'))
"py import vim
py import CppTokenizer
"===============================================================================
" 用 python 的正则表达式速度快很多
function! omnicpp#tokenizer#Tokenize(sCode)
    py vim.command("return %s" % CppTokenizer.Tokenize(vim.eval('a:sCode')))
endfunc

function! omnicpp#tokenizer#TokenizeLines(lLines)
    py vim.command("return %s" % CppTokenizer.TokenizeLines(vim.eval('a:lLines')))
endfunc
else
"===============================================================================
" Tokenize a c++ code
" a token is dictionary where keys are:
"   -   kind    = cppKeyword|cppWord|cppOperatorPunctuator|cComment|
"                 cppComment|cppDigit|unknown
"   -   value   = <text>
"   Note: a cppWord is any word that is not a cpp keyword
"   Note: 不能解析的, 被忽略. 中文会解析错误.
"   TODO: 处理注释中的非 ascii 码.
"         理论上应该把代码的字符串, 注释剔除完再 token 化
function! omnicpp#tokenizer#Tokenize(szCode) "{{{2
    let result = []

    " The regexp to find a token, a token is a keyword, word or
    " c++ operator or punctuator. To work properly we have to put 
    " spaces and tabs to our regexp.
    let reTokenSearch = '\(\w\+\)\|\s\+\|'.s:reComment.'\|'
                \.s:reCppOperatorOrPunctuator
    " eg: 'using namespace std;'
    "      ^    ^
    "  start=0 end=5
    let startPos = 0
    let endPos = matchend(a:szCode, reTokenSearch)
    let len = endPos - startPos
    while endPos != -1
        " eg: 'using namespace std;'
        "      ^    ^
        "  start=0 end=5
        "  token = 'using'
        " We also remove space and tabs
        let token = substitute(strpart(a:szCode, startPos, len), '\s', '', 'g')

        " eg: 'using namespace std;'
        "           ^         ^
        "       start=5     end=15
        let startPos = endPos
        let endPos = matchend(a:szCode, reTokenSearch, startPos)
        let len = endPos - startPos

        " It the token is empty we continue
        if token == ''
            continue
        endif

        " Building the token
        let resultToken = {'kind' : 'unknown', 'value' : token}

        " Classify the token
        if token =~ '^\d\+'
            " It's a digit
            let resultToken.kind = 'cppDigit'
        elseif token =~'^\w\+$'
            " It's a word
            let resultToken.kind = 'cppWord'

            " But maybe it's a c++ keyword
            if match(token, s:reCppKeyword) >= 0
                let resultToken.kind = 'cppKeyword'
            endif
        else
            if match(token, s:reComment) >= 0
                if index(['/*','*/'],token) >= 0
                    let resultToken.kind = 'cComment'
                else
                    let resultToken.kind = 'cppComment'
                endif
            else
                " It's an operator
                let resultToken.kind = 'cppOperatorPunctuator'
            endif
        endif

        " We have our token, let's add it to the result list
        call extend(result, [resultToken])
    endwhile

    return result
endfunc
"}}}
endif


" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/omnicpp/includes.vim	[[[1
242
" Description:  Omni completion script for resolve incldue files
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 13
" License:      GPLv2

" Note: 若需添加自定义的头文件搜索路径, 设置 &path 变量(:h 'path')

" TODO: 不适用 vim 的选项变量. 缺点, 不能 set += 
" gcc -v -x c++ /dev/null -fsyntax-only
" /usr/include/c++/4.4
" /usr/include/c++/4.4/i486-linux-gnu
" /usr/include/c++/4.4/backward
" /usr/local/include
" /usr/lib/gcc/i486-linux-gnu/4.4.3/include
" /usr/lib/gcc/i486-linux-gnu/4.4.3/include-fixed
" /usr/include/i486-linux-gnu
" /usr/include
let g:Omnicpp_IncludeSearchPaths = &path


"{{{2 内部用变量
" 文件包含列表缓存, 格式为 {<filePath> : <incList>}
" <incList> = {'include': <filePath>, 'pos': <pos>}
let s:CACHE_INCLUDES = {}
" 文件修改时间缓存, 格式为 {<filePath> : <mtime>}
let s:CACHE_FILEMTIME = {}

let s:rePreprocIncludePart = '\C^\s*#\s*include\s*'
let s:reIncludeFilePart = '\(<\|"\)\(\f\|\s\)\+\(>\|"\)'
let s:rePreprocIncludeFile = s:rePreprocIncludePart . s:reIncludeFilePart

"}}}
" 返回当前缓冲区包含的文件列表(嵌套解析)
" 具体路径根据 &path 变量的值而定
function! omnicpp#includes#GetIncludeFiles() "{{{2
    " 用字典键值保存结果以防止重复
    let includeGuard = {}
    let includeResult = [] " 另外的用于保存结果的列表, 有点, 保持顺序
    let szCurFilePath = expand('%:p')
    call s:DoGetIncludeFiles(szCurFilePath, includeGuard, includeResult)

    " 第一项为当前文件, 删除之
    call remove(includeResult, 0)
    " 也需要处理缓存
    if has_key(s:CACHE_INCLUDES, szCurFilePath)
        call remove(s:CACHE_INCLUDES, szCurFilePath)
        call remove(s:CACHE_FILEMTIME, szCurFilePath)
    endif
    let b:CACHE_INCLUDES = s:CACHE_INCLUDES
    let b:CACHE_FILEMTIME = s:CACHE_FILEMTIME

    return includeResult
endfunc


function! s:DoGetIncludeFiles(szFilePath, includeGuard, includeResult) "{{{2
    let includeGuard = a:includeGuard
    let includeResult = a:includeResult
    let szFilePath = omnicpp#includes#ResolveFilePath(a:szFilePath)
    if has_key(includeGuard, szFilePath)
        return
    else
        " includeGuard 的键值也就是解析完成的包含文件
        let includeGuard[szFilePath] = 1
        " includeResult 为结果, 不会重复, 保持包含的顺序
        call add(includeResult, szFilePath)
    endif

    let incList = omnicpp#includes#GetIncludeList(a:szFilePath)
    for inc in incList
        call s:DoGetIncludeFiles(inc.include, includeGuard, includeResult)
    endfor
endfunc


" Resolve the path of the file according to the &path variable
" 根据 &path 变量扩展文件路径
" 返回绝对路径
function! omnicpp#includes#ResolveFilePath(szFile) "{{{2
    let result = ''
    let listPath = split(globpath(&path, a:szFile), "\n")
    if len(listPath)
        let result = fnamemodify(listPath[0], ':p')
    endif
    " fnamemodify() 貌似已经执行了路径简化
    "return fnamemodify(simplify(result), ':p')
    return result
endfunc


" Get the include list of a file
" Note: 没有找到的头文件不会返回
" Param1: 空为表示获取当前缓冲区, 否则为获取指定文件
function! omnicpp#includes#GetIncludeList(...) "{{{2
    if a:0 > 0
        return s:GetIncludeListFromFile(a:1)
    else
        return s:GetIncludeListFromCurrentBuffer()
    endif
endfunc


" Get the include list from the current buffer
function! s:GetIncludeListFromCurrentBuffer() "{{{2
    let listIncludes = []
    let originalPos = getpos('.')

    call setpos('.', [0, 1, 1, 0])
    let curPos = [1,1]
    let alreadyInclude = {} " 键值保存包含的文件. 防止重复.
    while curPos != [0,0]
        let curPos = searchpos('\C\('.s:rePreprocIncludeFile.'\)', 'W')
        if curPos != [0,0]
            let szLine = getline('.')
            let startPos = curPos[1]
            let endPos = matchend(szLine, s:reIncludeFilePart, startPos-1)
            if endPos!=-1
                let szInclusion = szLine[startPos-1:endPos-1]
                let szIncludeFile = substitute(
                            \szInclusion, 
                            \'\('.s:rePreprocIncludePart.'\)\|[<>""]', '', 'g')
                let szResolvedInclude = 
                            \omnicpp#includes#ResolveFilePath(szIncludeFile)

                " Protection over self inclusion
                " 防止循环包含, 并且令列表中的项不重复
                if szResolvedInclude != '' 
                            \&& szResolvedInclude 
                            \   != omnicpp#includes#ResolveFilePath(getreg('%'))
                    let includePos = curPos
                    if !has_key(alreadyInclude, szResolvedInclude)
                        call extend(listIncludes, 
                                    \[{'pos' : includePos, 
                                    \   'include' : szResolvedInclude}])
                        let alreadyInclude[szResolvedInclude] = 1
                    endif
                endif
            endif
        endif
    endwhile

    call setpos('.', originalPos)
    return listIncludes
endfunc


" Get the include list from a file
function! s:GetIncludeListFromFile(szFilePath) "{{{2
    let listIncludes = []
    if a:szFilePath == ''
        return listIncludes
    endif

    let szAbsFilePath = fnamemodify(a:szFilePath, ':p')

    if has_key(s:CACHE_INCLUDES, szAbsFilePath)
        " 比较时间戳, 如果磁盘的文件修改时间不比缓存的新, 直接从缓存获取
        if getftime(szAbsFilePath) 
                    \<= s:CACHE_FILEMTIME[szAbsFilePath]
            return copy(s:CACHE_INCLUDES[szAbsFilePath])
        endif
    endif

    " 保持两个字典的键值同步
    let s:CACHE_INCLUDES[szAbsFilePath] = []
    let s:CACHE_FILEMTIME[szAbsFilePath] = getftime(szAbsFilePath)

    let szFixedPath = escape(szAbsFilePath, ' %#')
    execute 'silent! lvimgrep /\C\('.s:rePreprocIncludeFile.'\)/gj '.szFixedPath

    let listQuickFix = getloclist(0)
    let alreadyInclude = {}
    for qf in listQuickFix
        let szLine = qf.text
        let startPos = qf.col
        let endPos = matchend(szLine, s:reIncludeFilePart, startPos-1)
        if endPos!=-1
            let szInclusion = szLine[startPos-1:endPos-1]
            let szIncludeFile = substitute(
                        \szInclusion, 
                        \'\('.s:rePreprocIncludePart.'\)\|[<>""]', '', 'g')
            let szResolvedInclude 
                        \= omnicpp#includes#ResolveFilePath(szIncludeFile)
            
            " Protection over self inclusion
            " 防止循环包含, 并且令列表中的项不重复
            if szResolvedInclude != '' && szResolvedInclude != szAbsFilePath
                let includePos = [qf.lnum, qf.col]
                if !has_key(alreadyInclude, szResolvedInclude)
                    call extend(listIncludes, 
                                \[{'pos' : includePos, 
                                \   'include' : szResolvedInclude}])
                    let alreadyInclude[szResolvedInclude] = 1
                endif
            endif
        endif
    endfor

    " 缓存结果
    let s:CACHE_INCLUDES[szAbsFilePath] = listIncludes

    return copy(listIncludes)
endfunc


function! omnicpp#includes#ClearCache() "清空缓存, 用于强制更新全部 {{{2
    " 一般用在修改 &path 或者 getcwd() 后
    call filter(s:CACHE_INCLUDES, 0)
    call filter(s:CACHE_FILEMTIME, 0)
endfunc


" 返回当前缓冲区包含的文件(包括嵌套的, 忽略不存在的)
" For debug purpose
function! omnicpp#includes#Display() "{{{2
    let szPathBuffer = omnicpp#includes#ResolveFilePath(getreg('%'))
    call s:DisplayIncludeTree(szPathBuffer, 0)
endfunc


" For debug purpose
function! s:DisplayIncludeTree(szFilePath, indent, ...) "{{{2
    let includeGuard = {}
    if a:0 >0
        let includeGuard = a:1
    endif
    let szFilePath = omnicpp#includes#ResolveFilePath(a:szFilePath)
    if has_key(includeGuard, szFilePath)
        return
    else
        let includeGuard[szFilePath] = 1
    endif

    let szIndent = repeat('    ', a:indent)
    echom szIndent . a:szFilePath
    let incList = omnicpp#includes#GetIncludeList(a:szFilePath)
    for inc in incList
        call s:DisplayIncludeTree(inc.include, a:indent+1, includeGuard)
    endfor
endfunc

" vim:fdm=marker:fen:et:sts=4:fdl=1:
autoload/pyclewn.vim	[[[1
231
" pyclewn run time file
" Maintainer:   <xdegaye at users dot sourceforge dot net>
"
" Configure VIM to be used with pyclewn and netbeans
"
if exists("s:did_pyclewn")
    finish
endif
let s:did_pyclewn = 1

let s:start_err = "Error: pyclewn failed to start, "
let s:start_err .= "run the 'pyclewn' program to get the cause of the problem."

" The following variables define how pyclewn is started when
" the ':Pyclewn' vim command is run.
" They may be changed to match your preferences.

let s:pgm = fnamemodify("~/.vimlite/bin/pyclewn", ":p")

if !exists('g:VLWDbgFrameSignBackground')
	let g:VLWDbgFrameSignBackground = 'DarkMagenta'
endif

if !exists('g:VLWDbgProjectFile')
	let g:VLWDbgProjectFile = ''
endif

if exists("pyclewn_args")
  let s:args = pyclewn_args
else
  let s:args = "--window=top --maxlines=10000 --foreground=Cyan,Green,none "
			  \. "--background=none,none," . g:VLWDbgFrameSignBackground . " "
			  \. "--frametext=''"
endif

if exists("pyclewn_connection")
  let s:connection = pyclewn_connection
else
  let s:connection = "localhost:3219:changeme"
endif

" Uncomment the following line to print full traces in a file named 'logfile'
" for debugging purpose.
" let s:args .= " --level=nbdebug --file=logfile"

" The 'Pyclewn' command starts pyclewn and vim netbeans interface.
let s:fixed = "--daemon --editor= --netbeans=" . s:connection . " --cargs="

" Run the 'Cinterrupt' command to open the console
function s:start_pdb(args)
    let argl = split(a:args)
    if index(argl, "--pdb") != -1
        " find the prefix
        let prefix = "C"
        let idx = index(argl, "-x")
        if idx == -1
            let idx = index(argl, "--prefix")
            if idx == -1
                for item in argl
                    if stridx(item, "--prefix") == 0
                        let pos = stridx(item, "=")
                        if pos != -1
                            let prefix = strpart(item, pos + 1)
                        endif
                    endif
                endfor
            endif
        endif

        if idx != -1 && len(argl) > idx + 1
            let prefix = argl[idx + 1]
        endif

        " hack to prevent Vim being stuck in the command line with '--More--'
        echohl WarningMsg
        echo "About to run the 'interrupt' command."
        call inputsave()
        call input("Press the <Enter> key to continue.")
        call inputrestore()
        echohl None
        exe prefix . "interrupt"
    endif
endfunction

" Check wether pyclewn successfully wrote the script file
function s:pyclewn_ready(filename)
    let l:cnt = 1
    let l:max = 20
    echohl WarningMsg
    while l:cnt < l:max
        echon "."
        let l:cnt = l:cnt + 1
        if filereadable(a:filename)
            break
        endif
        sleep 200m
    endwhile
    echohl None
    if l:cnt == l:max
        throw s:start_err
    endif
    call s:info("The pyclewn process has been started successfully.\n")
endfunction

" Start pyclewn and vim netbeans interface.
function s:start(args)
    if !exists(":nbstart")
        throw "Error: the ':nbstart' vim command does not exist."
    endif
    if has("netbeans_enabled")
        throw "Error: netbeans is already enabled and connected."
    endif
    if !executable(s:pgm)
        throw "Error: '" . s:pgm . "' cannot be found or is not an executable."
    endif
    let l:tmpfile = tempname()

    " remove console and dbgvar buffers from previous session
    if bufexists("(clewn)_console")
        bwipeout (clewn)_console
    endif
    if bufexists("(clewn)_dbgvar")
        bwipeout (clewn)_dbgvar
    endif

	let sProjFileOpt = ''
	if g:VLWDbgProjectFile !=# ''
		let sProjFileOpt = ',' . shellescape(g:VLWDbgProjectFile)
	endif

    " start pyclewn and netbeans
    call s:info("Starting pyclewn, please wait...\n")
	let b:cmd = "silent !" . s:pgm . " " . a:args . " " . s:fixed . l:tmpfile . " &"
	if 0
		exe "silent !" . s:pgm . " " . a:args . " " . s:fixed . l:tmpfile . " &"
	else
		let sTerminal = 'xterm'
		let sTitleSw = '-T'
		if executable('gnome-terminal')
			let sTerminal = 'gnome-terminal'
			let sTitleSw = '-t'
		endif
python << PYTHON_EOF
import subprocess
import vim
pyclewnPopen = subprocess.Popen(
	[vim.eval("sTerminal"), 
	 vim.eval("sTitleSw"), 
	 'Pyclewn', 
	 '-e', 
	 "sh -c 'LC_ALL=en_US.UTF-8 VIM_SERVERNAME='%s'"\
	 " %s %s --gdb=async%s --netbeans=%s --cargs=%s'" \
	     % (vim.eval('v:servername'), vim.eval('s:pgm'), vim.eval('a:args'), 
		    vim.eval('sProjFileOpt'), vim.eval('s:connection'), 
			vim.eval('l:tmpfile'))])
PYTHON_EOF
	endif
    call s:info("'pyclewn' has been started.\n")
    call s:info("Running nbstart, <C-C> to interrupt.\n")
    call s:pyclewn_ready(l:tmpfile)
    exe "nbstart :" . s:connection

    " source vim script
    if has("netbeans_enabled")
        if !filereadable(l:tmpfile)
            nbclose
            throw s:start_err
        endif
        " the pyclewn generated vim script is sourced only once
        if ! exists("s:source_once")
            let s:source_once = 1
            exe "source " . l:tmpfile
        endif
        call s:info("The netbeans socket is connected.\n")
        call s:start_pdb(a:args)
    else
        throw "Error: the netbeans socket could not be connected."
    endif
endfunction

function pyclewn#StartClewn(...)
    " command to start pdb: Pyclewn pdb foo.py arg1 arg2 ....
    let l:args = s:args
    if a:0 != 0
        if has("gui_win32")
            call s:error("The Pyclewn command on Windows does not accept arguments.")
            return
        endif
        if a:1 == "pdb"
            if a:0 == 2 && filereadable(a:2) == 0
                call s:error("File '" . a:2 . "' is not readable.")
                return
            endif
            let l:args .= " --pdb"
            if a:0 > 1
                let l:args .= " --args \"" . join(a:000[1:], ' ') . "\""
            endif
        else
            call s:error("Invalid optional first argument: must be 'pdb'.")
            return
        endif
    endif

    try
        call s:start(l:args)
    catch /.*/
        call s:info("The 'Pyclewn' command has been aborted.\n")
        call s:error(v:exception)
        " vim console screen is garbled, redraw the screen
        if !has("gui_running")
            redraw!
        endif
        " clear the command line
        echo "\n"
    endtry
endfunction

function s:info(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

function s:error(msg)
    echohl ErrorMsg
    echo a:msg
    call inputsave()
    call input("Press the <Enter> key to continue.")
    call inputrestore()
    echohl None
endfunction
