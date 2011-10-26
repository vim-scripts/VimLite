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
