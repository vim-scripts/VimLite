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

