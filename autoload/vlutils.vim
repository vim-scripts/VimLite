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
function! vlutils#NormalizePath(sPath) "{{{2
    if has('win32') || has('win64')
        return substitute(a:sPath, '\', '/', 'g')
    else
        return a:sPath
    endif
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
function! vlutils#GetFirstUsableWinNr() "{{{2
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
" 生成带编号菜单选择列表
" NOTE: 第一项(即li[0])不会添加编号
function! vlutils#GenerateMenuList(li) "{{{2
    let li = a:li
    let nLen = len(li)
    let lResult = []

    if nLen > 0
        call add(lResult, li[0])
        let l = len(string(nLen -1))
        let n = 1
        for str in li[1:]
            call add(lResult, printf('%*d. %s', l, n, str))
            let n += 1
        endfor
    endif

    return lResult
endfunction
"}}}
" 简单的计时器静态类
let s:TimerData = {'t1': 0, 't2': 0} "{{{1
function! vlutils#TimerStart() "{{{2
	let s:TimerData.t1 = reltime()
endfunction

function! vlutils#TimerEnd() "{{{2
	let s:TimerData.t2 = reltime()
endfunction

function! vlutils#TimerEchoMes() "{{{2
	echom string((str2float(reltimestr(s:TimerData.t2)) 
				\- str2float(reltimestr(s:TimerData.t1))))
endfunction

function! vlutils#TimerEndEcho() "{{{2
	call vlutils#TimerEnd()
	call vlutils#TimerEchoMes()
endfunction
"}}}1
" 模拟 python 的 os 和 os.path 模块
" os, os.path {{{2
let os = {}
let path = {}
let os.path = path
if has('win32') || has('win64')
    let os.extsep = '.'
    let os.sep = '\'
else
    let os.altsep = ''
    let os.extsep = '.'
    let os.sep = '/'
endif
let g:vlutils#os = os
"}}}2

" vim:fdm=marker:fen:fdl=1:et:ts=4:sw=4:sts=4:
