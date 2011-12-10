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
