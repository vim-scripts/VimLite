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
