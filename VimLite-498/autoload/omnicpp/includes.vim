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
