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

    " 跳转至符号声明处的快捷键
    call s:InitVariable('g:VLOmniCpp_GotoDeclarationKey', '<C-p>')

    " 跳转至符号实现处的快捷键
    call s:InitVariable('g:VLOmniCpp_GotoImplementationKey', '<C-]>')
endfunc

" vim:fdm=marker:fen:et:sts=4:fdl=1:
