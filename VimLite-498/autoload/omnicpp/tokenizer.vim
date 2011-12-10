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
python << PYTHON_EOF
try:
    import CppTokenizer
except ImportError:
    import sys
    import os
    sys.path.append(os.path.expanduser('~/.vimlite/VimLite'))
    import vim
    import CppTokenizer
PYTHON_EOF
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
