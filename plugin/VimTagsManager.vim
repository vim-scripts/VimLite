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
