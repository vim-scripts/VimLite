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
                "let sCode= substitute(
                            "\omnicpp#utils#GetCode(lStartPos, lEndPos)[:-2], 
                            "\'^[;{}]', '', 'g')
                " NOTE: 不需要事先替换掉 ';{}' 了, 理论上不影响分析
                let sCode = omnicpp#utils#GetCode(lStartPos, lEndPos)
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
                    " 取最后的 cppWord, 因为经常在名字前有修饰宏
                    " eg. class WXDLLIMPEXP_SDK BuilderGnuMake;
                    let idx += 1
                    let dTmpToken = lTokens[idx]
                    while idx < nLen
                        if lTokens[idx].kind != 'cppWord'
                            let dTmpToken = lTokens[idx-1]
                            break
                        endif
                        let idx += 1
                    endwhile
                    let nScopeType = 1
                    let dCurScope.kind = 'container'
                    let dCurScope.name = dTmpToken.value
                    " 暂不支持在容器类型里使用名空间
                    "let dCurScope.namespaces = 
                    let lScopeStack = [dCurScope] + lScopeStack

                    break
                elseif dToken.kind == 'cppKeyword' && dToken.value ==# 'else'
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
                elseif dToken.kind == 'cppKeyword' 
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
                elseif dToken.kind == 'cppKeyword'
                            \&& dToken.value ==# 'extern'
                    " 忽略 'extern "C" {'
                    let sKind = get(lTokens, idx + 1, {'kind': ''}).kind
                    " 原始 Tokenizer() 没有 cppString 类型
                    if sKind == 'cppString' || sKind == 'cppOperatorPunctuator'
                        break
                    endif
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
                    if idx == len(lTokens) - 1
                    " 到达最后但是还不能确定为上面的其中一种
                    " 应该是一个无名块, 视为 other 类型
                        let dCurScope.kind = 'other'
                        let dCurScope.name = dToken.value " 这个值没用, 用于调试
                        let dCurScope.nsinfo = s:GetNamespaceInfo(
                                    \lSearchStartPos[0])
                        let lScopeStack = [dCurScope] + lScopeStack
                    endif
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
