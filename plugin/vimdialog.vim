" Vim interactive dialog and control library.
" Author: 	fanhe <fanhed@163.com>
" License:	This file is placed in the public domain.
" Create: 	2011 Mar 21
" Change:	2011 Jun 13

function! s:InitVariable(sVarName, value) "{{{2
    if !exists(a:sVarName)
		let {a:sVarName} = a:value
        return 1
    endif
    return 0
endfunction
"}}}
function! s:SID() "{{{2
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
function! s:GetSFuncRef(sFuncName) "{{{2
    return function('<SNR>'.s:SID().'_'.a:sFuncName[2:])
endfunction
"}}}

"Function: s:exec(cmd) 忽略所有自动命令事件来运行 cmd {{{2
function! s:exec(cmd)
    let bak_ei = &ei
    set ei=all
	try
		exec a:cmd
	catch
	finally
		let &ei = bak_ei
	endtry
endfunction
"}}}

"全局变量 {{{2
call s:InitVariable("g:VimDialogActionKey", "<CR>")
call s:InitVariable("g:VimDialogRestoreValueKey", "R")
call s:InitVariable("g:VimDialogClearValueKey", "C")
call s:InitVariable("g:VimDialogSaveKey", "<C-s>")
call s:InitVariable("g:VimDialogQuitKey", "<C-x><C-x>")
call s:InitVariable("g:VimDialogSaveAndQuitKey", "<C-x><C-s>")
call s:InitVariable("g:VimDialogNextEditableCtlKey", "<C-n>")
call s:InitVariable("g:VimDialogPrevEditableCtlKey", "<C-p>")
call s:InitVariable("g:VimDialogToggleExtraHelpKey", "<F1>")


"控件的基本类型 {{{2
let g:VC_BLANKLINE = 0
let g:VC_SEPARATOR = 1
let g:VC_STATICTEXT = 2
let g:VC_SINGLETEXT = 3
let g:VC_MULTITEXT = 4
let g:VC_RADIOLIST = 5
let g:VC_CHECKLIST = 6
let g:VC_COMBOBOX = 7
let g:VC_CHECKITEM = 8
let g:VC_TABLE = 9
let g:VC_BUTTONLINE = 10

let g:VC_DIALOG = 99

let s:VC_MAXLINELEN = 78


"Class: VCBlankLine 空行类，所有控件类的基类 {{{1
let g:VCBlankLine = {}
"Function: g:VCBlankLine.New() {{{2
function! g:VCBlankLine.New()
	let newVCBlankLine = copy(self)
	let newVCBlankLine.id = -1 "控件 id
	let newVCBlankLine.gId = -1 "控件组id
	let newVCBlankLine.type = g:VC_BLANKLINE
	let newVCBlankLine.data = '' "私有数据，外部用
	let newVCBlankLine.indent = 0 "缩进，主要用于派生类
	let newVCBlankLine.editable = 0	"是否可变，若为0，除非全部刷新，否则控件不变
	let newVCBlankLine.activated = 1 "是否激活，区别高亮，若 editable 为 0，无效
	let newVCBlankLine.hiGroup = "Constant" "用于高亮
	let newVCBlankLine.owner = {}

	"用于自动命令和键绑定等的使用
	let l:i = 0
	while 1
		let l:ins = 'g:VCControlInstance_' . l:i
		if !exists(l:ins)
			let {l:ins} = newVCBlankLine
			let newVCBlankLine.interInsName = l:ins
			break
		endif
		let l:i += 1
	endwhile

	return newVCBlankLine
endfunction

function! g:VCBlankLine.GetType() "{{{2
	return self.type
endfunction

"Function: g:VCBlankLine.SetId(id) {{{2
"ID 理论上可为任何类型的值，但最好用整数
function! g:VCBlankLine.SetId(id)
	unlet self.id
	let self.id = a:id
endfunction

"Function: g:VCBlankLine.SetGId(id) {{{2
"GID 理论上可为任何类型的值，但最好用整数
function! g:VCBlankLine.SetGId(id)
	let self.gId = a:id
endfunction

"Function: g:VCBlankLine.SetData(data) {{{2
"data 可为任何类型的值
function! g:VCBlankLine.SetData(data)
	unlet self.data
	let self.data = a:data
endfunction

"Function: g:VCBlankLine.GetData() {{{2
"data 可为任何类型的值
function! g:VCBlankLine.GetData()
	return self.data
endfunction

"Function: g:VCBlankLine.SetIndent(indent) {{{2
function! g:VCBlankLine.SetIndent(indent)
	let self.indent = a:indent
endfunction

function! g:VCBlankLine.SetEditable(yesOrNo) "{{{2
	let self.editable = yesOrNo
endfunction

function! g:VCBlankLine.IsEditable() "{{{2
	return self.editable
endfunction

function! g:VCBlankLine.SetActivated(yesOrNo) "{{{2
	let self.activated = a:yesOrNo
endfunction

"Function: g:VCBlankLine.GetId() {{{2
function! g:VCBlankLine.GetId()
	return self.id
endfunction

"Function: g:VCBlankLine.GetGId() {{{2
function! g:VCBlankLine.GetGId()
	return self.gId
endfunction

function! g:VCBlankLine.GetOwner() "{{{2
	return self.owner
endfunction

"Function: g:VCBlankLine.GetDispText() {{{2
function! g:VCBlankLine.GetDispText()
"	let l:text = repeat(" ", s:VC_MAXLINELEN)
	let l:text = ""
	return  l:text
endfunction

"Function: g:VCBlankLine.SetupHighlight() 占位，设置文本高亮 {{{2
function! g:VCBlankLine.SetupHighlight()
endfunction

"Function: g:VCBlankLine.ClearHighlight() 占位，取消文本高亮 {{{2
function! g:VCBlankLine.ClearHighlight()
	if has_key(self, 'matchIds')
		for i in self.matchIds
			call matchdelete(i)
		endfor
	endif

	if hlexists('VCLabel_' . self.hiGroup)
		exec 'syn clear ' . 'VCLabel_' . self.hiGroup
	endif
endfunction

function! g:VCBlankLine.GotoNextCtl(...) "{{{2
	"跳至下一个控件, 返回零表示处理完毕
	"可选参数非零表示第一次调用
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	return 0
endfunction

function! g:VCBlankLine.GotoPrevCtl(...) "{{{2
	"跳至下一个控件, 返回零表示处理完毕
	"可选参数非零表示第一次调用
	return 0
endfunction

"Function: g:VCBlankLine.Delete() 销毁对象 {{{2
function! g:VCBlankLine.Delete()
	unlet {self.interInsName}
	call filter(self, 0)
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCSeparator 分割器类 {{{1
let g:VCSeparator = {}
"Function: g:VCSeparator.New(...) {{{2
function! g:VCSeparator.New(...)
	let newVCSeparator = copy(self)

	"继承，keep 为不覆盖新类的属性
	call extend(newVCSeparator, g:VCBlankLine.New(), "keep")

	let newVCSeparator.type = g:VC_SEPARATOR
	let newVCSeparator.editable = 0
	let newVCSeparator.hiGroup = 'PreProc'

	if exists('a:1')
		let newVCSeparator.sepChar = a:1
	else
		let newVCSeparator.sepChar = '='
	endif

	return newVCSeparator
endfunction

"Function: g:VCSeparator.GetDispText() {{{2
function! g:VCSeparator.GetDispText()
	let l:indentLen = self.indent
	let l:text = ''
"	let l:text = "\n"
	let l:text = l:text . repeat(" ", l:indentLen)
				\ . repeat(self.sepChar, s:VC_MAXLINELEN - l:indentLen)
"	let l:text = "\n"
	return  l:text
endfunction

"Function: g:VCSeparator.SetupHighlight() {{{2
function! g:VCSeparator.SetupHighlight()
	let l:pattern = '\V' . self.sepChar . '\+'
	let hiGroup = 'VCLabel_' . self.hiGroup
	exec 'syn match ' . hiGroup . ' ''' . 
				\'^' . repeat(' ', self.indent) . l:pattern . ''''
	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCStaticText 固定文本控件类 {{{1
let g:VCStaticText = {}
"Function: g:VCStaticText.New(label) {{{2
function! g:VCStaticText.New(label)
	let newVCStaticText = copy(self)

	call extend(newVCStaticText, g:VCBlankLine.New(), "keep")

	let newVCStaticText.label = a:label
	let newVCStaticText.type = g:VC_STATICTEXT
	let newVCStaticText.indent = 0
	let newVCStaticText.editable = 0
	let newVCStaticText.hiGroup = "Label"
	return newVCStaticText
endfunction

"Function: g:VCStaticText.SetHighlight(hiGroup) 设置标签文本高亮组 {{{2
function! g:VCStaticText.SetHighlight(hiGroup)
	"if !has_key(self, 'matchIds')
		"let self.matchIds = []
	"endif

	let self.hiGroup = a:hiGroup
endfunction

"Function: g:VCStaticText.GetLabel() {{{2
function! g:VCStaticText.GetLabel()
	return self.label
endfunction

"Function: g:VCStaticText.GetDispText() {{{2
function! g:VCStaticText.GetDispText()
	let s = repeat(" ", self.indent) . self.label
	return s
endfunction

"Function: g:VCStaticText.SetIndent(indent) {{{2
function! g:VCStaticText.SetIndent(indent)
	let self.indent = a:indent < 0 ? 0 : a:indent
endfunction

"Function: g:VCStaticText.SetupHighlight() {{{2
function! g:VCStaticText.SetupHighlight()
	if self.label == ''
		return
	endif

	"matchadd 消耗较大，改用语法高亮
	"if has_key(self, 'matchIds')
		"exec 'let m = matchadd("' . self.hiGroup . '", ''' 
					"\. '^\V' . repeat(' ', self.indent) . self.label. ''', -20)'
		"call add(self.matchIds, m)
	"endif

	let hiGroup = 'VCLabel_' . self.hiGroup
	exec 'syn match ' . hiGroup . ' ''' . '^\V' 
				\. repeat(' ', self.indent) . self.label . ''''
	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCSingleText 单行可编辑文本控件类，所有可编辑控件的基类 {{{1
let g:VCSingleText = {}
"Function: g:VCSingleText.New(label, ...) 可选参数为文本控件显示字符串值
function! g:VCSingleText.New(label, ...) "{{{2
	let newVCSingleText = copy(self)

	"继承？！
	let newVCSingleText.parent = g:VCStaticText.New(a:label)
"	call extend(newVCSingleText, newVCSingleText.parent, "error")
	call extend(newVCSingleText, newVCSingleText.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCSingleText, "parent")

	if exists("a:1")
		let newVCSingleText.value = a:1
		let newVCSingleText.origValue = a:1
	else
		let newVCSingleText.value = ''
	endif

	let newVCSingleText.prevValue = ''

	" 是否仅用一行显示，默认否
	let newVCSingleText.isSingleLine = 0
	" 是否回绕，只有 isSingleLine 为零时才有用
	let newVCSingleText.wrap = 1
	" label 显示占用的最小宽度，用于对齐。仅 isSingleLine 非零时才有用
	let newVCSingleText.labelDispWidth = 0

	" 绑定的变量，用于自动更新，可用 callback 定制更新方式
	let newVCSingleText.bindVar = ''
	" 用是指示自动绑定时是否 python 的变量
	let newVCSingleText.isPyVar = 0

	let newVCSingleText.type = g:VC_SINGLETEXT
	let newVCSingleText.editable = 1
	return newVCSingleText
endfunction
"}}}
"添加控件回调函数
"回调函数必须接收两个参数，控件和私有数据。值改变的时候才调用
function! g:VCSingleText.ConnectActionPostCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.actionPostCbk = a:func
	else
		let self.actionPostCbk = function(a:func)
	endif
	let self.actionPostCbkData = a:data
endfunction
"}}}
function! g:VCSingleText.HandleActionPostCallback() "{{{2
	if has_key(self, "actionPostCbk")
		call self.actionPostCbk(self, self.actionPostCbkData)
	endif
endfunction
"}}}
"用于拦截 Action, 回调函数返回 1 表示不继续处理原始的 Action 行为
function! g:VCSingleText.ConnectActionCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.actionCallback = a:func
	else
		let self.actionCallback = function(a:func)
	endif
	let self.actCbData = a:data
endfunction
"}}}
function! g:VCSingleText.HandleActionCallback() "{{{2
	if has_key(self, "actionCallback")
		return self.actionCallback(self, self.actCbData)
	else
		return 0
	endif
endfunction
"}}}
function! g:VCSingleText.ConnectButtonCallback(func, data) "按钮动作 {{{2
	if type(a:func) == type(function("tr"))
		let self.buttonCallback = a:func
	else
		let self.buttonCallback = function(a:func)
	endif
	let self.btnCbData = a:data
endfunction

function! g:VCSingleText.HandleButtonCallback() "{{{2
	if has_key(self, "buttonCallback")
		call self.buttonCallback(self, self.btnCbData)
		return 1
	else
		return 0
	endif
endfunction

"Function: g:VCSingleText.GetValue() 获取控件保存值 {{{2
function! g:VCSingleText.GetValue()
	return self.value
endfunction

"Function: g:VCSingleText.GetPrevValue() 获取控件上次的值 {{{2
function! g:VCSingleText.GetPrevValue()
	return self.prevValue
endfunction

"Function: g:VCSingleText.SetValue() 设置控件保存值 {{{2
function! g:VCSingleText.SetValue(value)
	let self.prevValue = self.value
	let self.value = a:value
	if !has_key(self, "origValue")
		let self.origValue = a:value
	endif
endfunction

"Function: g:VCSingleText.SetSingleLineFlag(yesOrNo) {{{2
function! g:VCSingleText.SetSingleLineFlag(yesOrNo)
	let self.isSingleLine = a:yesOrNo
endfunction

"Function: g:VCSingleText.SetLabelDispWidth(width) {{{2
function! g:VCSingleText.SetLabelDispWidth(width)
	let self.labelDispWidth = a:width
endfunction

"Function: g:VCSingleText.SetWrap(yesOrNo) {{{2
function! g:VCSingleText.SetWrap(yesOrNo)
	let self.wrap = a:yesOrNo
endfunction

"Function: g:VCSingleText.SetOrigValue() 设置控件原始值 {{{2
function! g:VCSingleText.SetOrigValue(value)
	let self.origValue = a:value
endfunction

"Function: g:VCSingleText.GetDispText() 获取控件显示文本 {{{2
function! g:VCSingleText.GetDispText()
	let s = ""
	let l:indentSpace = repeat(" ", self.indent)
	let l:labelLen = strdisplaywidth(self.label)
	let l:textLen = strdisplaywidth(self.value)

	"NOTE: 条件判断必须为整数，如果为字符串，会有奇怪的错误！
	if self.isSingleLine != 0
		let l:lw = l:labelLen
		let l:label = self.label . ' '	"固定加 1 空格，方便高亮
		if l:labelLen < self.labelDispWidth
			let l:lw = self.labelDispWidth
			let l:label = l:label . repeat(" ", self.labelDispWidth - l:labelLen)
		endif

		" 包括边界
		let l:textCtlLen = l:textLen + 2
		if self.indent + strdisplaywidth(l:label) + l:textLen <= s:VC_MAXLINELEN
			let l:textCtlLen = s:VC_MAXLINELEN - self.indent 
						\- strdisplaywidth(l:label)
		endif

		let s = s . l:indentSpace . repeat(' ', strdisplaywidth(l:label)) 
					\ . '+' . repeat('-', l:textCtlLen - 2) . '+' . "\n"
		let s = s . l:indentSpace . l:label . '|' . self.value 
					\ . repeat(' ', l:textCtlLen - l:textLen - 2) . '|' . "\n"
		let s = s . l:indentSpace . repeat(' ', strdisplaywidth(l:label)) 
					\ . '+' . repeat('-', l:textCtlLen - 2) . '+'
	else
		if self.label != ""
			"let s = s . l:indentSpace . self.label . "\n"
			"显示按钮，只有有指定动作时且标签非空时才显示
			let tmpS = l:indentSpace . self.label
			if has_key(self, 'buttonCallback')
				let tmpN = strdisplaywidth(tmpS)
				if tmpN <= s:VC_MAXLINELEN - len('[...]')
					let tmpS .= repeat(' ', 
								\s:VC_MAXLINELEN - tmpN - len('[...]')) 
								\. '[...]'
				else
					"如果长度超过允许值，暂时就简单地让 button 显示在最后
					let tmpS .= '[...]'
				endif
			endif
			let s .= tmpS . "\n"
		endif

		if self.wrap != 0 && self.indent + l:textLen + 2 > s:VC_MAXLINELEN
			let l:contentLen = s:VC_MAXLINELEN - self.indent - 2

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen)
						\ . "+\n"

			let i = 0
			while i < strlen(self.value)
				let l:content = strpart(self.value, i, l:contentLen)
				let l:curLen = strdisplaywidth(l:content)
				let s = s . l:indentSpace . "|" . l:content
							\ . repeat(" ", l:contentLen - l:curLen) . "|\n"
				let i += l:contentLen
			endwhile

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"
		else
			let l:contentLen = l:textLen
			if self.indent + 2 + l:textLen <= s:VC_MAXLINELEN
				let l:contentLen = s:VC_MAXLINELEN - self.indent - 2
			endif

			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen)
						\ . "+\n"
			let s = s . l:indentSpace . "|" . self.value
						\ . repeat(" ", l:contentLen - l:textLen) . "|\n"
			let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"
		endif
	endif

	return s
endfunction

"Function: g:VCSingleText.Action() 控件动作 {{{2
function! g:VCSingleText.Action()
	let l:ret = 0

	"检测是否按了按钮，直接通过检测语法高亮信息确定，比较慢？！
	if synIDattr(synID(line("."), col("."), 1), "name") ==? 'VCButton'
		if self.HandleButtonCallback()
			return 1
		endif
	endif

	echohl Question
	" TODO: 设置自动完成类型
	let l:value = input(self.label . "\n", self.value, "file")
	if exists("l:value") && len(l:value) != 0
		call self.SetValue(l:value)
		let l:ret = 1
	endif
	echohl None

	return l:ret
endfunction
"}}}
function! g:VCSingleText.ClearValueAction() "{{{2
	if self.HandleActionCallback()
		return 1
	endif

	call self.SetValue('')
	return 1
endfunction
"}}}
function! g:VCSingleText.RestoreValueAction() "{{{2
	if self.HandleActionCallback()
		return 1
	endif

	call self.SetValue(self.origValue)
	return 1
endfunction
"}}}
function! g:VCSingleText.SetBindVarCallback(func, data) "定制变量绑定行为 {{{2
	if type(a:func) == type(function("tr"))
		let self.bindVarCbk = a:func
	else
		let self.bindVarCbk = function(a:func)
	endif
	let self.bindVarCbkData = a:data
endfunction

"Function: g:VCSingleText.BindVariable(...) 把控件值绑定到某个变量 {{{2
function! g:VCSingleText.BindVariable(...)
	if has_key(self, 'bindVarCbk')
		call self.bindVarCbk(self, self.bindVarCbkData)
	else
		if exists('a:1')
			let self.bindVar = a:1
		endif
		if exists("a:2")
			let self.isPyVar = a:2
		endif

		if self.bindVar != ''
			if self.isPyVar && has('python')
				python import vim
				exec 'py vim.command("call self.SetValue(\"%s\")" % ' 
							\. self.bindVar . ')'
			elseif !self.isPyVar
				call self.SetValue({self.bindVar})
			endif
		endif
	endif

	let self.origValue = self.value
endfunction

"Function: g:VCSingleText.RefreshValueFromBindVar() 从绑定的变量刷新控件值 {{{2
function! g:VCSingleText.RefreshValueFromBindVar()
	call self.BindVariable()
endfunction

"Function: g:VCSingleText.SetIsPyVal(isOrNot) 用于直接帮定变量到 python 变量
function! g:VCSingleText.SetIsPyVal(isOrNot)
	let self.isPyVar = isOrNot
endfunction

function! g:VCSingleText.SetUpdateBindVarCallback(func, data) "定制绑定更新 {{{2
	if type(a:func) == type(function("tr"))
		let self.updateBindVarCbk = a:func
	else
		let self.updateBindVarCbk = function(a:func)
	endif
	let self.updateBindVarCbkData = a:data
endfunction

"Function: g:VCSingleText.UpdateBindVar() 更新绑定的变量值为控件值 {{{2
function! g:VCSingleText.UpdateBindVar()
	if has_key(self, 'updateBindVarCbk')
		call self.updateBindVarCbk(self, self.updateBindVarCbkData)
	elseif self.bindVar != ''
		if self.isPyVar != 0 && has('python')
			py import vim
			exec 'python ' . self.bindVar . ' = "' . self.value . '"'
		else
			exec "let " . self.bindVar . ' = "' . self.value . '"'
		endif
	endif
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCMultiText 多行可编辑文本控件类 "{{{1
let g:VCMultiText = {}
"Function: g:VCMultiText.New(label, ...) 可选参数为文本控件显示字符串值 {{{2
function! g:VCMultiText.New(label, ...)
	let newVCMultiText = copy(self)

	"继承自 VCSingleText
	let newVCMultiText.parent = g:VCSingleText.New(a:label)
	call extend(newVCMultiText, newVCMultiText.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCMultiText, "parent")

	let newVCMultiText.type = g:VC_MULTITEXT
	let newVCMultiText.values = []

	if exists("a:1")
		call newVCMultiText.SetValue(a:1)
	else
		let newVCMultiText.value = ''
	endif

	return newVCMultiText
endfunction

function! g:VCMultiText.GetDispText() "{{{2
	"不支持饶行功能
	let s = ""
	let l:indentSpace = repeat(" ", self.indent)

	if self.label != ""
		"显示按钮，只有有指定动作时且标签非空时才显示
		let tmpS = l:indentSpace . self.label
		if has_key(self, 'buttonCallback')
			let tmpN = strdisplaywidth(tmpS)
			if tmpN <= s:VC_MAXLINELEN - len('[...]')
				let tmpS .= repeat(' ', 
							\s:VC_MAXLINELEN - tmpN - len('[...]')) 
							\. '[...]'
			else
				"如果长度超过允许值，暂时就简单地让 button 显示在最后
				let tmpS .= '[...]'
			endif
		endif
		let s .= tmpS . "\n"
	endif

	"let texts = split(self.value, '\n', 1)
	let texts = self.values
	let l:contentLen = s:VC_MAXLINELEN - self.indent - 2
	let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+\n"
	for text in texts
		"逐行显示
		let l:textLen = strdisplaywidth(text)
		if l:textLen > l:contentLen
			"行太长, 揭短并在末尾添加 '@'
			let l:textLen = l:contentLen
			let text = text[: l:textLen-2] . "@"
		endif
		let s = s . l:indentSpace . "|" . text
					\ . repeat(" ", l:contentLen - l:textLen) . "|\n"
	endfor
	let s = s . l:indentSpace . "+" . repeat("-", l:contentLen) . "+"

	return s
endfunction

function! g:VCMultiText.SetValue(value) "{{{2
	if type(a:value) == type([])
		let self.values = a:value
		let value = join(a:value, "\n")
	else
		let self.values = split(a:value, "\n", 1)
		let value = a:value
	endif

	call call(g:VCSingleText.SetValue, [value], self)
endfunction

function! g:VCMultiText.Action() "{{{2
	let l:ret = 0

	"检测是否按了按钮，直接通过检测语法高亮信息确定，比较慢？！
	if synIDattr(synID(line("."), col("."), 1), "name") ==? 'VCButton'
		if self.HandleButtonCallback()
			return 1
		endif
	endif

	"是否被拦截
	if self.HandleActionCallback()
		return 1
	endif

	"TODO

	return l:ret
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCComboBox 组合框选择控件类 {{{1
"若想设置选择的条目，直接调用 SetValue()
let g:VCComboBox = {}
"Function: g:VCComboBox.New(label) 可选参数为文本控件显示字符串值 {{{2
function! g:VCComboBox.New(label)
	let newVCComboBox = copy(self)

	"继承 VCSingleText
	let newVCComboBox.parent = g:VCSingleText.New(a:label)
	call extend(newVCComboBox, newVCComboBox.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCComboBox, "parent")

	let newVCComboBox.type = g:VC_COMBOBOX
	let newVCComboBox.editable = 1

	let newVCComboBox.items = []

	return newVCComboBox
endfunction

"Function: g:VCComboBox.GetDispText() 获取控件显示文本 {{{2
function! g:VCComboBox.GetDispText()
	let s = ""

	let l:textLen = strdisplaywidth(self.value)
	if l:textLen <= s:VC_MAXLINELEN - 4 - self.indent
		let l:spaceLen = s:VC_MAXLINELEN - 4 - self.indent
	else
		let l:spaceLen = l:textLen
	endif

	let l:indentSpace = repeat(" ", self.indent)

	if self.label != ""
		let s = s . l:indentSpace . self.label . "\n"
	endif

	let s = s . l:indentSpace . "+" . repeat("-", l:spaceLen)
				\ . "+-+\n"
	let s = s . l:indentSpace . "|" . self.value
				\ . repeat(" ", l:spaceLen - l:textLen) . "|v|\n"
	let s = s . l:indentSpace . "+" . repeat("-", l:spaceLen) . "+-+"

	return s
endfunction

function! g:VCComboBox.GetItems() "{{{2
	return self.items
endfunction

"Function: g:VCComboBox.AddItem(item) 添加条目 {{{2
function! g:VCComboBox.AddItem(item)
	call add(self.items, a:item)
	if !len(self.value)
		call self.SetValue(a:item)
	endif
endfunction

"Function: g:VCComboBox.RemoveItem(item) 删除指定条目 {{{2
function! g:VCComboBox.RemoveItem(item)
	let idx = index(self.items, a:item)
	if idx != -1
		call remove(self.items, idx)
		if self.GetValue() == a:item
			if !empty(self.items)
				if idx - 1 > 0
					call self.SetValue(self.items[idx - 1])
				else
					call self.SetValue(self.items[0])
				endif
			else
				call self.SetValue('')
			endif
		endif
	endif
endfunction

"Function: g:VCComboBox.InsertItem(item, idx) 在索引前插入条目 {{{2
function! g:VCComboBox.InsertItem(item, idx)
	call insert(self.items, a:item, a:idx)
	if !len(self.value)
		call self.SetValue(a:item)
	endif
endfunction

"Function: g:VCComboBox.RenameItem(oldItem, newItem) 重命名指定条目 {{{2
function! g:VCComboBox.RenameItem(oldItem, newItem)
	let oldItem = a:oldItem
	let newItem = a:newItem
	let idx = index(self.items, oldItem)
	if idx != -1
		let self.items[idx] = newItem
		if self.GetValue() == oldItem
			call self.SetValue(newItem)
		endif
	endif
endfunction

"Function: g:VCComboBox.Action() 控件动作 {{{2
function! g:VCComboBox.Action()
	let l:ret = 0
	let l:choices = []
	call add(l:choices, "Please select a choice:")
	let i = 1
	let l:index = index(self.items, self.value)

	while i - 1 < len(self.items)
		let pad = "  "
		if l:index == i - 1
			let pad = "* "
		endif
		call add(l:choices, pad . i . ". " . self.items[i - 1])
		let i += 1
	endwhile
	let l:choice = inputlist(choices)
	if exists("l:ret") && l:choice > 0 && l:choice - 1 < len(self.items)
		call self.SetValue(self.items[l:choice - 1])
		if l:choice -1 != l:index
			let l:ret = 1
		endif
	endif

	return l:ret
endfunction

function! g:VCComboBox.ClearValueAction() "{{{2
endfunction

function! g:VCComboBox.RestoreValueAction() "{{{2
endfunction

function! g:VCComboBox.SetupHighlight() "{{{2
	"调用祖先类的方法
	call call(g:VCStaticText.SetupHighlight, [], self)

	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif

	"高亮 v 箭头
"	let m = matchadd('SpecialChar', '\v\|v\|\ze[a-zA-Z0-9 ]$', -20)
	let m = matchadd('SpecialChar', '\v\|v\|\ze', -20)
	call add(self.matchIds, m)
"	let m = matchadd('SpecialChar', '\v\+\-\+\ze[a-zA-Z0-9 ]$', -20)
	let m = matchadd('SpecialChar', '\v\+\-\+\ze', -20)
	call add(self.matchIds, m)
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================

"Class: VCCheckItem 复选条目控件类 {{{1
let g:VCCheckItem = {}
"Function: g:VCCheckItem.New(label, ...) 可选参数为文本控件显示字符串值 {{{2
function! g:VCCheckItem.New(label, ...)
	let newVCCheckItem = copy(self)

	"继承 VCSingleText
	let newVCCheckItem.parent = g:VCSingleText.New(a:label)
	call extend(newVCCheckItem, newVCCheckItem.parent, "keep")

	"暂时删除，不然影响调试
	call remove(newVCCheckItem, "parent")

	if exists("a:1")
		let newVCCheckItem.value = a:1
		let newVCCheckItem.origValue = a:1
	else
		let newVCCheckItem.value = 0
	endif

	let newVCCheckItem.type = g:VC_CHECKITEM
	let newVCCheckItem.editable = 1

	"是否在显示时反转其值
	let newVCCheckItem.reverse = 0

	return newVCCheckItem
endfunction

function! g:VCCheckItem.SetReverse(yesOrNo) "{{{2
	let self.reverse = a:yesOrNo
endfunction

"Function: g:VCCheckItem.GetDispText() {{{2
function! g:VCCheckItem.GetDispText()
	let l:value = self.value

	let l:checked = "[ ] "
	if l:value != 0
		let l:checked = "[X] "
	endif
	let s = repeat(" ", self.indent) . l:checked . self.label
	return s
endfunction

"Function: g:VCCheckItem.Action() 控件动作 {{{2
function! g:VCCheckItem.Action()
	let l:ret = 1

	if self.value != 0
		call self.SetValue(0)
	else
		call self.SetValue(1)
	endif

	return l:ret
endfunction

"Function: g:VCCheckItem.BindVariable(...) 把控件值绑定到某个变量 {{{2
function! g:VCCheckItem.BindVariable(...)
	if exists("a:1")
		let self.bindVar = a:1
	endif
	if exists("a:2")
		let self.isPyVar = a:2
	endif

	if self.isPyVar && has("python")
		python import vim
		exec 'py i = ' . self.bindVar
python << EOF
if i:
	vim.command('call self.SetValue(1)')
else:
	vim.command('call self.SetValue(0)')
del i
EOF
	elseif !self.isPyVar
		call self.SetValue({self.bindVar})
	endif

	"是否反转变量值
	if self.reverse
		call self.SetValue(!self.GetValue())
	endif

	let self.origValue = self.value

	"FIXME: 关联 activated 怎样处理？
	call self.HandleActionPostCallback()
endfunction

"Function: g:VCCheckItem.UpdateBindVar() 更新绑定的变量值为控件值 {{{2
function! g:VCCheckItem.UpdateBindVar()
	let value = self.value
	if self.reverse
		let value = !value
	endif

	if self.bindVar != ''
		if self.isPyVar && has('python')
			py import vim
			if value != 0
				let pyVal = "True"	" 代表 python 的真
			else
				let pyVal = "False"	" 代表 python 的假
			endif
			exec 'python ' . self.bindVar . ' = ' . pyVal
		elseif !self.isPyVar
			exec "let " . self.bindVar . ' = "' . value . '"'
		endif
	endif
endfunction

function! g:VCCheckItem.SetupHighlight() "{{{2
	if self.label == ''
		return
	endif

	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif
	exec 'let m = matchadd("' . self.hiGroup . '", ''' 
				\. '^' . repeat(' ', self.indent) . '\[[ X]\] \zs' 
				\. self.label. ''', -20)'
	call add(self.matchIds, m)
	"FIXME: 为什么语法高亮不行？
"	let hiGroup = 'VCLabel_' . self.hiGroup
"	exec 'syn match ' . hiGroup . ' ''' . '^' . repeat(' ', self.indent) 
"				\. '\[[ X]\] \zs' . self.label . ''''
"	exec 'hi link ' . hiGroup . ' ' . self.hiGroup
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"Class: VCTable 表格控件类，用于实现列表设置 "{{{1
let g:VCTable = {}
function! g:VCTable.New(label, ...) "{{{2
	let newVCTable = copy(self)

	"继承
	let newVCTable.parent = g:VCSingleText.New(a:label)
	call extend(newVCTable, newVCTable.parent, "keep")
	"暂时删除，不然影响调试
	call remove(newVCTable, "parent")

	let newVCTable.type = g:VC_TABLE

	let newVCTable.CT_TEXT = 0
	let newVCTable.CT_CHECK = 1

	"表格的列数，默认为 1
	let newVCTable.columns = 1
	if exists('a:1') && a:1 > 1
		let newVCTable.columns = a:1
	endif

	"一个表格行（列表）作为一个数据
	let newVCTable.table = []
	"页眉，记录列相关信息
	let newVCTable.header = []
	"为了统一编号，不添加进表格中
	"call add(newVCTable.table, newVCTable.header)

	let header = newVCTable.header
	for i in range(newVCTable.columns)
		let headerData = {}
		let headerData['title'] = ''
		let headerData['type'] = newVCTable.CT_TEXT
		call add(newVCTable.header, headerData)
	endfor

	"是否显示页眉，默认显示
	let newVCTable.dispHeader = 1

	"是否显示按钮，默认显示
	let newVCTable.dispButtons = 1

	"当前选择的行，如没有选择，则为 0，行数从 1 开始
	let newVCTable.selection = 0

	"是否允许直接编辑单元格，默认允许
	let newVCTable.cellEditable = 1

	"是否启用按钮，默认全部启用
	let newVCTable.btnEnabledFlag = repeat([1], 6)

	return newVCTable
endfunction

function! g:VCTable.SetDispHeader(yesOrNo) "{{{2
	let self.dispHeader = a:yesOrNo
endfunction

function! g:VCTable.SetDispButtons(yesOrNo) "{{{2
	let self.dispButtons = a:yesOrNo
endfunction

function! g:VCTable.SetSelection(selection) "{{{2
	let self.selection = a:selection
endfunction

function! g:VCTable.SetCellEditable(yesOrNo) "{{{2
	let self.cellEditable = a:yesOrNo
endfunction

function! g:VCTable.SetColTitle(col, title) "列数从 1 开始，内部从 0 开始 {{{2
	if a:col < self.columns + 1
		let self.header[a:col - 1].title = a:title
	endif
endfunction

function! g:VCTable.SetColType(col, type) "列数从 1 开始，内部从 0 开始 {{{2
	if a:col < self.columns + 1
		let self.header[a:col - 1].type = a:type
	endif
endfunction

function! g:VCTable.AddLineByValues(...) "多余的参数会被忽略 {{{2
	let i = 1
	let li = []
	while i <= a:0
		if i >= self.columns + 1
			break
		endif
		call add(li, a:{i})
		let i += 1
	endwhile

	call add(self.table, li)
endfunction

function! g:VCTable.SetCellValue(line, column, value) "{{{2
	if a:line < len(self.table) + 1 && a:column < self.columns
		let self.table[a:line-1][a:column-1] = a:value
	endif
endfunction

function! g:VCTable.GetCellValue(line, column) "{{{2
	let val = ''
	if a:line < len(self.table) + 1 && a:column < self.columns
		let val = self.table[a:line-1][a:column-1]
	endif
	return val
endfunction

function! g:VCTable.GetSelectedLine() "{{{2
	let line = []
	if self.selection > 0
		let line = self.GetLine(self.selection)
	endif
	return line
endfunction

function! g:VCTable.GetLine(lineIndex) "{{{2
	let line = []
	if a:lineIndex < 0
		let line = self.table[a:lineIndex]
	elseif a:lineIndex < len(self.table) + 1
		let line = self.table[a:lineIndex-1]
	endif
	return line
endfunction

function! g:VCTable.GetColumn(columnIndex) "{{{2
	if a:columnIndex >= self.columns + 1
		return []
	endif

	let col = []
	if a:columnIndex < 0
		let colIndex = a:columnIndex
	elseif a:columnIndex < self.columns + 1
		let colIndex = a:columnIndex - 1
	endif

	for i in self.table
		call add(col, i[colIndex])
	endfor
	return col
endfunction

function! g:VCTable.InsertLine(lineIndex, line) "{{{2
	"插入行数据到指定的行的前面，索引可比行数大 1 
	if a:lineIndex >= len(self.table) + 1 + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1 + 1
		let index = a:lineIndex - 1
	endif

	call insert(self.table, a:line, index)
endfunction

function! g:VCTable.AddLine(line) "{{{2
	call add(self.table, a:line[:self.columns-1]) "包含最后的，与 python 行为不同
endfunction

function! g:VCTable.UpdateLine(lineIndex, line) "{{{2
	if a:lineIndex >= len(self.table) + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1
		let index = a:lineIndex - 1
	endif

	let self.table[index] = a:line
endfunction

function! g:VCTable.DeleteLine(lineIndex) "{{{2
	if a:lineIndex >= len(self.table) + 1
		return
	endif

	let index = a:lineIndex
	if a:lineIndex > 0 && a:lineIndex < len(self.table) + 1
		let index = a:lineIndex - 1
	endif

	call remove(self.table, index)
endfunction

function! g:VCTable.DeleteAllLines() "{{{2
	call filter(self.table, 0)
	call self.SetSelection(0)
endfunction

function! g:VCTable.TransposeLines(lineIndex1, lineIndex2) "{{{2
	let line1 = self.GetLine(a:lineIndex1)
	let line2 = self.GetLine(a:lineIndex2)

	"暂不做合法性检查，应该有外层检查
"	if line1 != [] && line2 != []
	if 1
		call self.UpdateLine(a:lineIndex1, line2)
		call self.UpdateLine(a:lineIndex2, line1)
	endif
endfunction

"Function: g:VCTable.RefreshValueFromBindVar() 从绑定的变量刷新控件值 {{{2
function! g:VCTable.RefreshValueFromBindVar()
	let self.choice = 0
	call call(g:VCSingleText.RefreshValueFromBindVar, [], self)
endfunction

function! g:VCTable.GetDispText() "{{{2
	"不允许回绕，而且，显示不全时，强行截断
	"列宽至少为1，不能为0
	let s = ''

	let off = 0 "表格第一行与空间起始行的偏移行数

	let indent = 2
	if self.indent > indent
		let indent = self.indent
	endif

	"显示标签
	if self.label != ''
		let s = s . self.label . "\n"
		let off += 1
	endif

	"显示操作按钮
	if self.dispButtons
		let disableBorder = '@'
		let buttonLabels = ['Add... ', 'Remove ', 'Edit...', 
					\'  Up   ', ' Down  ', 'Clr All']
		let tmpIdx = 0
		let tmpLen = len(buttonLabels)
		while tmpIdx < tmpLen
			if self.btnEnabledFlag[tmpIdx]
				let buttonLabels[tmpIdx] = '['.buttonLabels[tmpIdx].']'
			else
				let buttonLabels[tmpIdx] = disableBorder 
							\. buttonLabels[tmpIdx] . disableBorder
			endif
			let tmpIdx += 1
		endwhile
		let s .= join(buttonLabels, ' ') . "\n"
		"let s = s . "[Add... ] [Remove ] [Edit...] " 
					"\. "[  Up   ] [ Down  ] [Clr All]\n"
		let off += 1
	endif

	let tblCtlLen = s:VC_MAXLINELEN - indent

	let s = s . '+' . repeat('-', tblCtlLen - 2) . '+' . "\n"
	let off += 1

	let avrWidth = (tblCtlLen - self.columns - 1) / self.columns
	let colWidths = repeat([avrWidth], self.columns)
	"余数算进最后列的宽度
	let colWidths[-1] = (tblCtlLen - self.columns - 1) 
				\- avrWidth * (self.columns - 1)

	"根据类型调整宽度
	for index in range(self.columns)
		if self.header[index].type == self.CT_CHECK
			if index + 1 < self.columns 
						\&& self.header[index + 1].type != self.CT_CHECK
				let colWidths[index + 1] += colWidths[index] - 3
				let colWidths[index] = 3
			elseif index - 1 > 0 
						\&& self.header[index - 1].type != self.CT_CHECK
				let colWidths[index - 1] += colWidths[index] - 3
				let colWidths[index] = 3
			else
				"不变
			endif
		endif
	endfor

	"TODO: 需要一个成员
	let self.colWidths = colWidths

	"添加页眉
	if self.dispHeader
		let s = s . '|'

		let colContents = []
		let index = 0
		while index < self.columns
			if strdisplaywidth(self.header[index].title) <= colWidths[index]
				let content = self.header[index].title . repeat(' ', 
							\colWidths[index] 
							\- strdisplaywidth(self.header[index].title))
			else
				let content = strpart(self.header[index].title, 0, 
							\colWidths[index] - 1) . '@'
			endif
			call add(colContents, content)
			let index += 1
		endwhile

		for i in colContents
			let s = s . i . '|'
		endfor
		let s = s . "\n"
		let off += 1

		let index = 0
		let s = s . '|'
		while index < self.columns
			let l:tmp = '+'
			if index == self.columns - 1
				let l:tmp = '|'
			endif
			let s = s . repeat('-', colWidths[index]) . l:tmp
			let index += 1
		endwhile
		let s = s . "\n"
		let off += 1
	endif

	"显示表格内容
	for line in self.table
		"显示每行
		let s = s . '|'

		let colContents = []
		let index = 0
		while index < self.columns
			"显示一行的每个单元格
			if self.header[index].type == self.CT_CHECK
				"单元格类型为 CT_CHECK，并且标准化该单元格的变量以防意外
				if index < len(line) && line[index] != 0
					let content = '[X]'
					let line[index] = 1
				else
					let content = '[ ]'
					let line[index] = 0
				endif
			else
				if index >= len(line)
					"列内容为空
					let content = repeat(' ', colWidths[index])
					"填充空内容，以便索引
					call add(line, '')
				elseif strdisplaywidth(line[index]) <= colWidths[index]
					"空间足够显示
					let content = line[index] . repeat(' ', 
								\colWidths[index] - strdisplaywidth(line[index]))
				else
					"空间不足显示
					let content = strpart(line[index], 0, 
								\colWidths[index] - 1) . '@'
				endif
			endif
			call add(colContents, content)
			let index += 1
		endwhile

		for i in colContents
			let s = s . i . '|'
		endfor

		let s = s . "\n"
	endfor

	let s = s . '+' . repeat('-', tblCtlLen - 2) . '+'

	"添加缩进
"	let s = join(map(split(s, "\n"), 'repeat(" ", indent) . v:val'), "\n")

	let texts = split(s, "\n")
	"选择的行在 texts 中的索引
	let selLineIndex = (off - 1 + self.selection)

	for index in range(len(texts))
		let pad = repeat(' ', indent)
		if index == selLineIndex && self.selection
			"到达了选择的索引，且确有选择某行，添加选择标志
			let pad = repeat(' ', indent - 2) . '>>'
		endif
		let texts[index] = pad . texts[index]
	endfor

	let s = join(texts, "\n")

	return s
endfunction

function! g:VCTable.SetupHighlight() "{{{2
	if !has_key(self, 'matchIds')
		let self.matchIds = []
	endif

	"if self.dispButtons
		"let m = matchadd('StatusLine', '\V[\s\zs\.\{-1,}\ze\s]', -20)
		"call add(self.matchIds, m)
	"endif

	"let m = matchadd('SpecialKey', '\V@\ze|')
	"call add(self.matchIds, m)

	let indent = self.indent > 2 ? self.indent : 2
	if self.label != ''
		let hiGroup = 'VCLabel_' . self.hiGroup
		exec 'syn match ' . hiGroup . ' ''' . '^\V' 
					\. repeat(' ', indent) . self.label. ''''
		exec 'hi link ' . hiGroup . ' ' . self.hiGroup
	endif
endfunction

function! g:VCTable.DisableButton(btnId) "{{{2
	let self.btnEnabledFlag[a:btnId] = 0
endfunction

function! g:VCTable.EnableButton(btnId) "{{{2
	let self.btnEnabledFlag[a:btnId] = 1
endfunction

function! g:VCTable.Action(...) "可选参数指示是否 clear 操作 {{{2
	let l:ret = 0

	"是否 ClearAction
	let bIsClearAction = 0
	if a:0 > 0
		if a:1 ==? 'clear'
			let bIsClearAction = 1
		endif
	endif

	let curLn = line('.')
	let curCn = virtcol('.')

	let indent = self.indent > 2 ? self.indent : 2
	if self.label != ''
		let matchStr = '^\V' . repeat(' ', indent) . self.label
	else
		if self.dispButtons
			"let matchStr = '^\V' . repeat(' ', indent) . '[Add... ]'
			let matchStr = '^\V' . repeat(' ', indent) . '\[^+|]Add... '
		else
			"FIXME: 若在最后一行，off 为 0
			let matchStr = '^\V' . repeat(' ', indent) . '+-\+'
		endif
	endif

	let sLn = curLn

	for i in range(0, curLn)
		let line = getline(curLn - i)
		if match(line, matchStr) != -1
			let sLn = curLn - i
			break
		endif
	endfor
"	echo sLn

	let off = curLn - sLn

	let isInBtnLine = 0
	if self.dispButtons
		if self.label != '' && off == 1
			let isInBtnLine = 1
		elseif self.label == '' && off == 0
			let isInBtnLine = 1
		else
			let isInBtnLine = 0
		endif
		"echo isInBtnLine
	endif

	"可能点击了按钮，处理之
	if isInBtnLine
		let l:ret = self._ButtonAction()
	endif

"	echo off

	"若不显示按钮行，修正 off
	if !self.dispButtons && off > 0
		let off += 1
	endif

	"获取所在的表格行数，0 表示不在表格数据中，大于 0 则表示在索引中（从 1 开始）
	if self.dispHeader
		if self.label != '' && off > 4
			let lineIndex = off - 4
		elseif self.label == '' && off > 3
			let lineIndex = off - 3
		else
			let lineIndex = 0
		endif
	else
		if self.label != '' && off > 2
			let lineIndex = off - 2
		elseif self.label == '' && off > 1
			let lineIndex = off - 1
		else
			let lineIndex = 0
		endif
	endif

	"处理最后行
	if lineIndex >= len(self.table) + 1
		let lineIndex = 0
	endif

"	echo lineIndex

	"更改选择的行，需要刷新
	if lineIndex > 0
		if self.selection != lineIndex
			let self.selection = lineIndex
			let l:ret = 1
			if has_key(self, 'selectionCallback')
				call self.selectionCallback(self, self.selectionCallbackData)
			endif
		endif

		"编辑单元格
		let realCn = curCn - indent "从 1 开始
		let cellStartCol = 2
		for index in range(self.columns)
			"查询光标所在的单元格
			let min = cellStartCol
			let max = cellStartCol + self.colWidths[index]

			if realCn < min
				break
			endif

			if realCn < max
				"echo index
				if self.header[index].type == self.CT_CHECK
					"如果点击了多选框，切换
					let tmpLine = self.GetLine(lineIndex)
					if tmpLine[index]
						let tmpLine[index] = 0
					else
						let tmpLine[index] = 1
					endif
					let l:ret = 1
				elseif self.cellEditable
					let tmpLine = self.GetLine(lineIndex)
					if bIsClearAction
						let tmpLine[index] = ''
						let l:ret = 1
					else
						echohl Question
						let input = input("Edit:\n", tmpLine[index])
						echohl None
						if input != '' && input != tmpLine[index]
							let tmpLine[index] = input
							let l:ret = 1
						endif
					endif
				endif
				break
			else
				let cellStartCol += self.colWidths[index] + 1
			endif
		endfor
	endif

	return l:ret
endfunction

function! g:VCTable.ClearValueAction() "{{{2
	return self.Action('clear')
endfunction

function! g:VCTable._ButtonAction() "{{{2
	let ret = 0

	let btnWidth = 10
	let curCn = virtcol('.')
	let indent = self.indent > 2 ? self.indent : 2

	let realCn = curCn - indent

	if realCn > 0
		"按了某个按钮，处理之
		let btnIndex = (realCn - 1) / btnWidth

		if realCn % btnWidth == 0
			"刚好在按钮之间的空隙，忽略
			return 0
		endif

		if btnIndex >= len(self.btnEnabledFlag) 
					\|| !self.btnEnabledFlag[btnIndex]
			"索引越界或者禁用了此 button，则什么都不做
			return 0
		endif

		if btnIndex >= 1 && btnIndex <= 4 && !self.selection
			"中间四个按钮必须要选择了才能生效
			return 0
		endif

		"动作已经被拦截
		if has_key(self, 'btnCallbacks') 
					\&& type(self.btnCallbacks[btnIndex]) == type(function('tr'))
			call self.btnCallbacks[btnIndex](self, self.btnCbData[btnIndex])
			return 1
		endif

		if btnIndex == 0
"			echo 'Add'
			let input = input("Add:\n", '[]')
			if input != '' && type(eval(input)) == type([])
				call self.AddLine(eval(input))
				let ret = 1
			endif
		elseif btnIndex == 1
"			echo 'remove'
			if self.selection
				call self.DeleteLine(self.selection)
				if self.selection >= len(self.table) + 1
					let self.selection = 0
				endif
				let ret = 1
			endif
		elseif btnIndex == 2
"			echo 'edit'
			if self.selection
				let line = self.GetLine(self.selection)
				let result = input("Edit:\n", string(line))
				if result != '' && type(eval(result)) == type([])
					call self.UpdateLine(self.selection, eval(result))
					let ret = 1
				endif
			endif
		elseif btnIndex == 3
"			echo 'up'
			if self.selection > 1
				call self.TransposeLines(self.selection, self.selection - 1)
				let self.selection -= 1
				let ret = 1
			endif
		elseif btnIndex == 4
"			echo 'down'
			if self.selection && self.selection < len(self.table) + 1 - 1
				call self.TransposeLines(self.selection, self.selection + 1)
				let self.selection += 1
				let ret = 1
			endif
		elseif btnIndex == 5
"			echo 'clr all'
			call self.DeleteAllLines()
			let self.selection = 0
			let ret = 1
		else
"			echo 'over'
		endif
	endif

	return ret
endfunction

function! g:VCTable.ConnectBtnCallback(btnId, func, data) "{{{2
	if !has_key(self, 'btnCallbacks')
		let self.btnCallbacks = repeat([''], 6)
		let self.btnCbData = repeat([''], 6)
	endif

	"如果传进来的 func 参数直接是函数引用的话，直接赋值
	if type(a:func) == type(function("tr"))
		let self.btnCallbacks[a:btnId] = a:func
	else
		let self.btnCallbacks[a:btnId] = function(a:func)
	endif
	let self.btnCbData[a:btnId] = a:data
endfunction

function! g:VCTable.ConnectSelectionCallback(func, data) "{{{2
	if type(a:func) == type(function("tr"))
		let self.selectionCallback = a:func
	else
		let self.selectionCallback = function(a:func)
	endif
	let self.selectionCallbackData = a:data
endfunction

"----- Test -----
function! g:TestVCTable() "{{{2
	let g:dlg = g:VimDialog.New('VCTable Test')
	let g:ctl = g:VCTable.New('VCTable', 3)
"	let g:ctl = g:VCTable.New('', 3)
	call g:ctl.SetColTitle(1, 'col1')
	call g:ctl.SetColTitle(2, 'col2')
	call g:ctl.SetColTitle(3, 'col3')
	call g:ctl.SetColTitle(4, 'col4')
	call g:ctl.AddLine(['a', 'b', 'c', 'd'])
	call g:ctl.AddLineByValues('z', 'y', 'x', 'w')
	call g:ctl.AddLineByValues('1', '2', '3')
	call g:ctl.AddLine(['10', '20', '30'])
	call g:ctl.SetCellValue(2, 2, 'X')
"	echo g:ctl.header
"	echo g:ctl.table
"	echo g:ctl.GetDispText()
"	call g:ctl.SetDispHeader(0)
	call g:dlg.AddControl(g:ctl)
	"call g:dlg.Display()
endfunction

function! g:TestVCTable2() "{{{2
	let g:dlg = g:VimDialog.New('VCTable Test')
	let g:ctl = g:VCTable.New('VCTable', 2)
"	let g:ctl = g:VCTable.New('', 3)
	call g:ctl.SetColType(1, g:ctl.CT_CHECK)
	call g:ctl.SetColTitle(1, 'col1')
	call g:ctl.SetColTitle(2, 'col2')
	call g:ctl.SetColTitle(3, 'col3')
	call g:ctl.SetColTitle(4, 'col4')
	call g:ctl.AddLine(['a', 'b', 'c', 'd'])
	call g:ctl.AddLineByValues('z', 'y', 'x', 'w')
	call g:ctl.AddLineByValues('1', '2', '3')
	call g:ctl.AddLine(['10', '20', '30'])
	call g:ctl.SetCellValue(2, 2, 'X')
"	echo g:ctl.header
"	echo g:ctl.table
"	echo g:ctl.GetDispText()
"	call g:ctl.SetDispHeader(0)
	call g:ctl.ConnectBtnCallback(0, 'TestCtlCallback', 'hello')
	call g:dlg.AddControl(g:ctl)
	call g:dlg.Display()
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"Class: VCButtonLine 按钮控件类，用于实现按钮 "{{{1
let g:VCButtonLine = {}
function! g:VCButtonLine.New(label, ...) "{{{2
	let new = copy(self)

	"继承
	let new.parent = g:VCSingleText.New(a:label)
	call extend(new, new.parent, "keep")
	"暂时删除，不然影响调试
	call remove(new, "parent")

	let new.type = g:VC_BUTTONLINE

	let new.buttons = [] "按钮列表, 按钮为一个字典 
						 "{'label': '', 'id': -1, 'enable': 1}

	return new
endfunction

function! g:VCButtonLine.AddButton(sLabel, ...) "{{{2
	let sLabel = a:sLabel
	let nID = -1
	if a:0 > 0
		let nID = a:1
	endif

	if strdisplaywidth(sLabel) < 2
		"按钮文字字符数至少要 2
		let sLabel .= repeat(' ', 2 - strdisplaywidth(sLabel))
	endif

	let button = {'label': sLabel, 'id': nID, 'enable': 1}
	call add(self.buttons, button)
endfunction

function! g:VCButtonLine.RemoveButton(nBtnIdx) "{{{2
	try
		call remove(self.buttons, a:nBtnIdx)
	catch
	endtry
endfunction

function! g:VCButtonLine.ConnectButtonCallback(nBtnIdx, func, data) "{{{2
	try
		if type(a:func) == type('')
			let self.buttons[a:nBtnIdx].callback = function(a:func)
		else
			let self.buttons[a:nBtnIdx].callback = a:func
		endif
		let self.buttons[a:nBtnIdx].callbackData = a:data
	catch
	endtry
endfunction

function! g:VCButtonLine.EnableButton(nBtnIdx) "{{{2
	try
		let self.buttons[a:nBtnIdx].enable = 1
	catch
	endtry
endfunction

function! g:VCButtonLine.DisableButton(nBtnIdx) "{{{2
	try
		let self.buttons[a:nBtnIdx].enable = 0
	catch
	endtry
endfunction

function! g:VCButtonLine.GetDispText() "{{{2
	let s = ''
	let sIndent = repeat(' ', self.indent)

	let s .= sIndent
	let bFirstEnter = 1
	for button in self.buttons
		let sL = '['
		let sR = ']'
		if !button.enable
			let sL = '@'
			let sR = '@'
		endif
		if bFirstEnter
			let bFirstEnter = 0
			let s .= sL . button.label . sR
		else
			let s .= ' ' . sL . button.label . sR
		endif
	endfor

	return s
endfunction

function! g:VCButtonLine.Action() "{{{2
	let nRet = 0

	let nCurCol = virtcol('.')
	let nIndent = self.indent

	let nRealCol = nCurCol - nIndent
	if nRealCol <= 0
		return nRet
	endif

	let idx = 0
	let bPressed = 0
	let nMin = 0
	let nMax = 0
	while idx < len(self.buttons)
		let button = self.buttons[idx]
		let nMax = nMin + strdisplaywidth('['.button.label.']')
		if nRealCol <= nMax && nRealCol > nMin
			let bPressed = 1
			break
		endif

		let nMin = nMax + 1
		let idx += 1
	endwhile

	if bPressed && self.buttons[idx].enable
		let nRet = 1
		if has_key(self.buttons[idx], 'callback')
			let nRet = self.buttons[idx].callback(
						\self, self.buttons[idx].callbackData)
		endif
	endif

	return nRet
endfunction

function! g:VCButtonLine.ClearValueAction() "{{{2
endfunction

function! g:VCButtonLine.RestoreValueAction() "{{{2
endfunction

function! g:VCButtonLine.GotoNextCtl(...) "{{{2
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	if bFirstEnter
		return 1
	else
		let lOrigPos = getpos('.')
		normal! f[
		if getpos('.') == lOrigPos
			return 0
		else
			return 1
		endif
	endif
endfunction

function! g:VCButtonLine.GotoPrevCtl(...) "{{{2
	let bFirstEnter = a:0 > 0 ? a:1 : 0
	if bFirstEnter
		normal! $F[
		return 1
	else
		let lOrigPos = getpos('.')
		normal! F[
		if getpos('.') == lOrigPos
			return 0
		else
			return 1
		endif
	endif
endfunction

"===============================================================================
"-------------------------------------------------------------------------------
"===============================================================================


"{{{ 控件索引键值
let g:VimDialogCtlKeyBit = 2
"剔除 '\'，以免影响正则匹配
let g:VimDialogCtlKeyChars = '`1234567890-=qwertyuiop[]asdfghjkl;''zxcvbnm,./'.
			\'~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>? '
let g:VimDialogCtlKeys = split(g:VimDialogCtlKeyChars, '\zs')
"}}}

"Class: VimDialog 对话框类，显示与管理所有控件 {{{1
let g:VimDialog = {}
"Function: g:VimDialog.New(name, ...) 第二个可选参数为父对话框 {{{2
function! g:VimDialog.New(name, ...)
	let newVimDialog = copy(self)
	let newVimDialog.name = a:name
	let newVimDialog.splitSize = 30
	let newVimDialog.winPos = "left"
	let newVimDialog.controls = []
	let newVimDialog.showLineNum = 0
	let newVimDialog.highlightCurLine = 0 "默认关闭，否则影响按钮高亮
	let newVimDialog.type = g:VC_DIALOG
	let newVimDialog.data = '' "私有数据

	let newVimDialog.bufNum = -1

	"判定是否分割窗口
	let newVimDialog.splitOpen = 0

	"if exists("a:1") && type(a:1) == type([])
		"for ctl in a:1
			"call newVimDialog.AddControl(ctl)
		"endfor
	"endif

	"用于控件回调函数请求全部刷新用
	let newVimDialog.requestRefreshAll = 0
	let newVimDialog.requestDeepRefreshAll = 0

	let newVimDialog.isPopup = 0
	let newVimDialog.lockParent = 0 "打开子窗口时是否锁定父窗口
	let newVimDialog.lock = 0 "若非零，所有动作被禁用
	let newVimDialog.parentDlg = {} "父窗口实例
	let newVimDialog.childDlgs = [] "子窗口实例列表

	let newVimDialog.disableApply = 0

	"若为 1，则窗口为一个可编辑的普通文本，用于实现文本控件
	"这会忽略所有本窗口包含的其他控件
	let newVimDialog.asTextCtrl = 0
	let newVimDialog.textContent = ''

	if exists('a:1') && type(a:1) == type({}) && !empty(a:1)
		let newVimDialog.parentDlg = a:1
		let newVimDialog.isPopup = 1
		let newVimDialog.lockParent = 1
		call newVimDialog.parentDlg.AddChildDialog(newVimDialog)
	endif

	let newVimDialog.isModified = 0 "是否已修改设置. 采用近似算法

	"用于自动命令和键绑定等的使用
	let i = 0
	while 1
		let l:ins = 'g:VimDialogInstance_' . i
		if !exists(l:ins)
			let {l:ins} = newVimDialog
			let newVimDialog.interInsName = l:ins
			break
		endif
		let i += 1
	endwhile

	let newVimDialog.extraHelpContent = '' "额外的帮助信息内容
	let newVimDialog._showExtraHelp = 0 "显示额外帮助信息的标志，用于切换

	"索引控件对象用
	let newVimDialog.ctlKeys = []

	"键值为 ctlKey，的字典，保存非激活的控件的matchId
	let newVimDialog._inactiveCtlMatchId = {}

	return newVimDialog
endfunction

function! g:VimDialog.SetData(data) "{{{2
	unlet self.data
	let self.data = a:data
endfunction

function! g:VimDialog.GetData() "{{{2
	return self.data
endfunction

function! g:VimDialog.DisableApply() "{{{2
	let self.disableApply = 1
endfunction

function! g:VimDialog.AddChildDialog(child) "添加子对话框 {{{2
	call add(self.childDlgs, a:child)
endfunction

function! g:VimDialog.RemoveChildDialog(child) "删除子对话框 {{{2
	for i in range(len(self.childDlgs))
		if self.childDlgs[i] is a:child
			call remove(self.childDlgs, i)
		endif
	endfor
endfunction

function! g:VimDialog.SetSplitOpen(yesOrNo) "{{{2
	let self.splitOpen = a:yesOrNo
endfunction

function! g:VimDialog.SetIsPopup(yesOrNo) "{{{2
	let self.isPopup = a:yesOrNo
endfunction

function! g:VimDialog.SetAsTextCtrl(yesOrNo) "{{{2
	let self.asTextCtrl = a:yesOrNo
endfunction

function! g:VimDialog.SetTextContent(text) "{{{2
	let self.textContent = a:text
endfunction

function! g:VimDialog.SetExtraHelpContent(text) "{{{2
	let self.extraHelpContent = a:text
endfunction

function! g:VimDialog.SetModified(yesOrNo) "{{{2
	let self.isModified = a:yesOrNo
endfunction

function! g:VimDialog.IsModified() "{{{2
	return self.isModified
endfunction

function! g:VimDialog._GetAKey() "{{{2
	if empty(self.ctlKeys)
		let self._ctlIdIndex = 0
		let self._ctlIdCount = 1
		let self._ctlIdCountPerGroup = len(g:VimDialogCtlKeys)
		let self._key2Id = {}
		let i = 0
		while i < g:VimDialogCtlKeyBit
			call add(self.ctlKeys, copy(g:VimDialogCtlKeys))
			let self._ctlIdCount = self._ctlIdCount * self._ctlIdCountPerGroup
			let i += 1
		endwhile
	endif

	if self._ctlIdIndex >= self._ctlIdCount
		throw "Too more controls"
	else
		"先简单实现...
		if g:VimDialogCtlKeyBit == 2
			let index0 = self._ctlIdIndex / self._ctlIdCountPerGroup
			let index1 = self._ctlIdIndex % self._ctlIdCountPerGroup
			let key = self.ctlKeys[0][index0] . self.ctlKeys[1][index1]
			let self._key2Id[key] = self._ctlIdIndex
			let self._ctlIdIndex += 1
			return key
		endif
	endif
endfunction

function! g:VimDialog._GetCtlKeyByLnum(lnum)
	let l:line = getline(a:lnum)
	return l:line[len(l:line) - g:VimDialogCtlKeyBit : ]
endfunction

"创建用于显示窗口
function! g:VimDialog._CreateWin() "{{{2
    "create the dialog window
    let splitLocation = self.winPos ==# "left" ? "topleft " : "botright "
    let splitSize = self.splitSize

	"用于关闭时返回原来的窗口
	let self.origWinNum = winnr()
	"用于关闭时返回，当窗口编号已改变时用
	let self.origBufNum = bufnr('%')

    if !has_key(self, "bufName")
		"第一次调用本实例的显示函数

        let self.bufName = self.name
		"NOTE: 处理空格。凡是用于命令行的，都要注意空格！
		let l:bufName = substitute(self.bufName, ' ', '\\ ', "g")
		let winNum = g:GetFirstUsableWindow()

		"先跳至将要编辑的窗口
		if self.isPopup
			"Popup 类型的窗口为无名缓冲
			exec (winheight(0)-2).'new'
		elseif self.splitOpen
			let maxWidthWinNr = g:GetMaxWidthWinNr()
			call g:Exec(maxWidthWinNr . ' wincmd w')
			new
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		elseif winNum == -1 || (winnr('$') == 1 && winNum == -1)
			if bufwinnr(self.bufName) != -1
				"存在与要创建的缓冲同名的缓冲, 跳至那个缓冲然后结束
				call g:Exec(bufwinnr(self.bufName) . ' wincmd w')
				return 1
			endif

			let maxWidthWinNr = g:GetMaxWidthWinNr()
			call g:Exec(maxWidthWinNr . ' wincmd w')
			new
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		else
			"替换缓冲区
			if bufwinnr(self.bufName) != -1
				"存在与要创建的缓冲同名的缓冲, 跳至那个缓冲然后结束
				call g:Exec(bufwinnr(self.bufName) . ' wincmd w')
				return 1
			endif

			"NOTE: 当仅有一个无名缓冲区时，会把无名缓冲区完全替换掉
			call g:Exec(winNum . ' wincmd w')
			let self.rpmBufNum = bufnr('%')		"用于关闭时切换回来
			"求好方案更改缓冲区的名称，这样的实现会关联本地的文件...
			silent! exec "edit " . l:bufName
		endif
    else
		"重复调用本实例显示函数

		if bufwinnr(self.bufNum) != -1
			"已在某窗口打开着，直接跳至窗口
			call s:exec(bufwinnr(self.bufNum) . " wincmd w")
			return
		else
			"已在 buffer 列表中，但是没有打开，则切换
			let l:bufName = substitute(self.bufName, ' ', '\\ ', "g")
			let winNum = g:GetFirstUsableWindow()
			if self.splitOpen || winNum == -1 
						\|| (winnr('$') == 1 && winNum == -1)
				silent! exec 'sbuffer ' . l:bufName
			else
				call g:Exec(winNum . ' wincmd w')
				let self.rpmBufNum = bufnr('%')		"用于关闭时切换回来
				silent! exec "buffer " . l:bufName
			endif
		endif
    endif

    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell

	setlocal bufhidden=wipe "关闭窗口后直接删除缓冲
	"关闭窗口后自删
	exec 'autocmd BufWinLeave <buffer> call '.self.interInsName.'._ForceQuit()'
	"if self.isPopup
		"setlocal bufhidden=wipe "关闭窗口后直接删除缓冲
		""关闭窗口后自删
		"exec 'autocmd BufWinLeave <buffer> call '.self.interInsName.'.Delete()'
	"else
		"setlocal bufhidden=hide
	"endif
    if self.showLineNum
        setlocal nu
    else
        setlocal nonu
    endif

    "删除所有插入模式的缩写
    iabc <buffer>

	"高亮光标所在行
	if self.highlightCurLine
		setlocal cursorline
	else
		setlocal nocursorline
	endif

    "设置状态栏
	call self._RefreshStatusLine()

    "设置键盘映射
	call self.SetupKeyMappings()

    setfiletype vimdialog

	let self.bufNum = bufnr('%')
endfunction

function! g:VimDialog._RefreshStatusLine() "{{{2
	let modFlag = ''
	if self.isModified
		let modFlag = '\ [+]'
	endif

    "设置状态栏
    exec "setlocal statusline=" . substitute(self.bufName, ' ', '\\ ', "g") 
				\. modFlag

	if self.asTextCtrl
		let statusStr = getwinvar(winnr(), '&statusline') 
					\. ' - ' .g:VimDialogSaveAndQuitKey. ':Save and Quit; '
					\. g:VimDialogQuitKey . ':Quit without Save'
		call setwinvar(winnr(), '&statusline', statusStr)
	endif
endfunction

function! g:VimDialog.GetControlByID(nID) "从 ID 获取控件 {{{2
	for ctl in self.controls
		if ctl.GetId() == a:nID
			return ctl
		endif
	endfor

	return {}
endfunction

"Function: g:VimDialog.GetControlByLnum(lnum) 从行号直接获取控件对象 {{{2
function! g:VimDialog.GetControlByLnum(lnum)
	let l:key = self._GetCtlKeyByLnum(a:lnum)
	if has_key(self.controlsDict, l:key)
		return self.controlsDict[l:key]
	else
		return {}
	endif
endfunction

"添加控件到对话框，对于这个简单的对话实现，显示的顺序就是添加的顺序
"Function: g:VimDialog.AddControl(control) {{{2
function! g:VimDialog.AddControl(control)
	let a:control.owner = self
	call add(self.controls, a:control)
endfunction

"Function: g:VimDialog.Display() 显示全部控件，可重入 {{{2
function! g:VimDialog.Display()
	if self.lockParent && !empty(self.parentDlg)
		let self.parentDlg.lock = 1
	endif

	"调用此函数后自动把光标放到对应的窗口里, 接着可直接操作当前窗口修改其内容
	if self._CreateWin()
		"跳到了复用的窗口, 直接结束
		call self.Delete()
		return
	endif

	setlocal ma
	exec "silent 1," . line("$") . " delete _"

	let bak = @a
	let @a = ""
	
	" 为了可重入
	let self.ctlKeys = []

	if self.asTextCtrl
		if self.textContent != ''
			let @a .= self.textContent
			silent! put! a
			if self.textContent[-1:-1] !=# "\n"
				"处理多出来的空行, 只有当字符串最后的字符为非换行时才需要
				exec "silent " . line("$") . "," . line("$") . " delete _"
			endif
		endif

		normal! G
		setlocal ma
	else
		"设置语法高亮
		if has("syntax") && exists("g:syntax_on")
			call self.SetupSyntaxHighlight()
		endif

		let self.controlsDict = {}
		for i in self.controls
			if i.IsEditable()
				let l:key = self._GetAKey()
				let self.controlsDict[l:key] = i
			else
				let l:key = repeat(' ', g:VimDialogCtlKeyBit)
			endif
			let l:s = substitute(i.GetDispText(), "\n", l:key . "\n", "g")
			let @a = @a . l:s . l:key . "\n"

			call self._HandleCtlActivated(i, l:key)
		endfor

		silent! put a
		silent 1,1delete _

		call self.DisplayHelp()

		setlocal noma
	endif

	let @a = bak
endfunction

function! g:VimDialog.Refresh() "刷新显示 {{{2
	call self.Display()
endfunction

function! g:VimDialog.RefreshAll() "此函数只支持从回调函数中调用 {{{2
	let self.requestRefreshAll = 1
endfunction

function! g:VimDialog._RefreshAll() "{{{2
	call self.Display()
endfunction

function! g:VimDialog.DeepRefreshAll(...) "{{{2
	let self.requestDeepRefreshAll = 1
endfunction

function! g:VimDialog._DeepRefreshAll() "{{{2
	for i in self.controls
		if has_key(i, "RefreshValueFromBindVar")
			call i.RefreshValueFromBindVar()
		endif
	endfor

	call self.Display()
endfunction

function! g:VimDialog.DisplayHelp() "{{{2
	let l:winnr = bufwinnr(self.bufNum)
	if l:winnr != -1
        call s:exec(l:winnr . " wincmd w")
		let texts = []

		let text = '"'
		let text = text . g:VimDialogActionKey . ': Change Text; '
		let text = text . g:VimDialogRestoreValueKey . ': Restore Text; '
		let text = text . g:VimDialogClearValueKey . ': Clear Text '
		call add(texts, text)

		let text = '"'
		if !self.isPopup && !self.disableApply
			let text = text . g:VimDialogSaveKey . ': Save All; '
		endif
		let text = text . g:VimDialogSaveAndQuitKey . ': Save And Quit; '
		let text = text . g:VimDialogQuitKey . ': Quit Without Save '
		call add(texts, text)

		let text = '"'
		let text .= g:VimDialogToggleExtraHelpKey . ': Toggle Extra Help; '
		if !self.asTextCtrl
			let text .= g:VimDialogNextEditableCtlKey . ': Goto Next Control; '
			let text .= g:VimDialogPrevEditableCtlKey . ': Goto Prev Control '
		endif
		call add(texts, text)

		call add(texts, '')

		setlocal ma
		call append(0, texts)
		setlocal noma

		"设置语法高亮
		if has("syntax") && exists("g:syntax_on")
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogActionKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogRestoreValueKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogClearValueKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogSaveKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogSaveAndQuitKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogQuitKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogToggleExtraHelpKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogNextEditableCtlKey . "\\ze:'"
			exec "syn match VimDialogHotKey '\\%<4l" . 
						\g:VimDialogPrevEditableCtlKey . "\\ze:'"
			hi def link VimDialogHotKey Identifier
			syn match Comment '\v^".*$' contains=VimDialogHotKey
		endif
	endif
endfunction
"}}}
function! g:VimDialog.Action(...) "响应动作 {{{2
	if self.lock
		return
	endif

	let sType = 'action'
	if a:0 > 0
		let sType = a:1
	endif

	let nLn = line('.')
	let ctl = self.GetControlByLnum(nLn)
	if len(ctl) != 0 && has_key(ctl, "Action") && ctl.activated
		let bSkipAction = 0
		if has_key(ctl, 'HandleActionCallback') && ctl.HandleActionCallback()
			let bSkipAction = 1
		endif
		if !bSkipAction
			if sType ==? 'restore'
				let nRet = ctl.RestoreValueAction()
			elseif sType ==? 'clear'
				let nRet = ctl.ClearValueAction()
			else
				let nRet = ctl.Action()
			endif
			if nRet
				if has_key(ctl, 'HandleActionPostCallback')
					call ctl.HandleActionPostCallback()
				endif

				"支持在控件的 Action 中删除窗口
				if !empty(self)
					call self.RefreshCtlByLnum(nLn)
					"let self.isModified = 1
					"call self._RefreshStatusLine()
				endif
			endif
		endif
	endif

	if !empty(self)
		let save_cursor = getpos(".") "用于恢复光标位置
		if self.requestDeepRefreshAll
			let self.isModified = 0
			let self.requestDeepRefreshAll = 0
			call self._DeepRefreshAll()
		elseif self.requestRefreshAll
			let self.requestRefreshAll = 0
			call self._RefreshAll()
		endif
		call setpos('.', save_cursor) "恢复光标位置
	endif
endfunction

function! g:VimDialog.RestoreCtlValue() "{{{2
	call self.Action('restore')
endfunction

function! g:VimDialog.ClearCtlValue() "{{{2
	call self.Action('clear')
endfunction

function! g:VimDialog.RefreshCtl(ctl) "刷新指定实例 {{{2
	for ctl in self.controls
		if ctl is a:ctl
			let bak = ctl.id
			let ctl.id = -10000
			call self.RefreshCtlById(-10000)
			let ctl.id = bak
		endif
	endfor
endfunction

function! g:VimDialog.RefreshCtlById(id) "{{{2
	let l:winnr = bufwinnr(self.bufNum)
	let l:origWin = winnr()
    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec(l:winnr . " wincmd w")
    endif

	for i in range(1, line('$') + 1)
		let ctl = self.GetControlByLnum(i)
		if ctl != {} && ctl.GetId() == a:id
			call self.RefreshCtlByLnum(i)
			break
		endif
	endfor

    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec("wincmd p")
    endif
endfunction

function! g:VimDialog.RefreshCtlByGId(gId) "{{{2
	for ctl in self.controls
		if ctl.GetGId() == a:gId
			call self.RefreshCtl(ctl)
		endif
	endfor
endfunction

"刷新控件显示
"Function: g:VimDialog.RefreshCtlByLnum(lnum) {{{2
function! g:VimDialog.RefreshCtlByLnum(lnum)
	let l:winnr = bufwinnr(self.bufNum)
	let l:origWin = winnr()
    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec(l:winnr . " wincmd w")
    endif

	let save_cursor = getpos(".") "用于恢复光标位置

	if a:lnum == '.'
		let nLn = line('.')
	else
		let nLn = a:lnum
	endif
	let l:ctlKey = self._GetCtlKeyByLnum(nLn)
	if l:ctlKey == ''
		return
	endif
"	echo l:ctlKey

	let l:ctlSln = nLn
	let l:ctlEln = nLn
	for i in range(1, nLn)
		let l:curKey = self._GetCtlKeyByLnum(nLn - i)
"		echo l:curKey
		if l:curKey != ctlKey
			break
		endif
		let l:ctlSln = nLn - i
	endfor
	for i in range(nLn + 1, line('$'))
		let l:curKey = self._GetCtlKeyByLnum(i)
"		echo l:curKey
		if l:curKey != ctlKey
			break
		endif
		let l:ctlEln = i
	endfor
"	echo l:ctlSln
"	echo l:ctlEln

	setlocal ma
	" 刷新控件显示
	let ctl = self.GetControlByLnum(nLn)
	if ctl == {}
		return
	endif
	let l:text = ctl.GetDispText()
	let l:texts = split(l:text, "\n")
	call map(l:texts, 'v:val . l:ctlKey')

	" 保持最小的增删行，防止画面晃动
	let l:dispLc = l:ctlEln - l:ctlSln + 1
	if len(l:texts) > l:dispLc
		let l:dc = len(l:texts) - l:dispLc
		call append(ctlSln, range(l:dc))
	elseif len(l:texts) < l:dispLc
		let l:dc = l:dispLc - len(l:texts)
		"NOTE: 对于 delete 的范围，不能直接用表达式，必须是直接数字！
		let l:endLn = l:ctlSln + l:dc - 1
		exec "silent " . l:ctlSln . "," . l:endLn . "delete _"
	endif

	call setline(l:ctlSln, l:texts)

	"处理激活
	call self._HandleCtlActivated(ctl, ctlKey)

"	exec l:ctlSln . "," . l:ctlEln . "delete _"
"	let bak = @a
"	let @a = l:text
"	silent! put! a
"	let @a = bak
	setlocal noma

	"恢复光标位置
	call setpos('.', save_cursor)

    if l:winnr != -1 && l:winnr != l:origWin
		call s:exec("wincmd p")
    endif
endfunction

function! g:VimDialog._HandleCtlActivated(ctl, ctlKey) "处理控件激活显示 {{{2
	if !a:ctl.activated
		if has_key(self._inactiveCtlMatchId, a:ctlKey)
			exec 'syn clear ' . self._inactiveCtlMatchId[a:ctlKey]

			"call matchdelete(self._inactiveCtlMatchId[a:ctlKey])
			"call remove(self._inactiveCtlMatchId, a:ctlKey)
		endif
		let groupName = 'InActive_' . self._key2Id[a:ctlKey]
		let texts = split(a:ctl.GetDispText(), '\n')
		for text in texts
			"NOTE: 在正则表达式中 ' 是用 \ 来转义的
			let text = escape(text, "'")
			exec "syn match " . groupName . ' ''\V'.text.'\ze'.a:ctlKey.'\$'''
		endfor
		exec 'hi link ' . groupName . ' Ignore'
		let self._inactiveCtlMatchId[a:ctlKey] = groupName

		"let matchId = matchadd('Ignore', '\V\.\+\ze'.a:ctlKey.'\$', -19)
		"let self._inactiveCtlMatchId[a:ctlKey] = matchId
	else
		if has_key(self._inactiveCtlMatchId, a:ctlKey)
			exec 'syn clear ' . self._inactiveCtlMatchId[a:ctlKey]

			"call matchdelete(self._inactiveCtlMatchId[a:ctlKey])
			"call remove(self._inactiveCtlMatchId, a:ctlKey)
		endif
	endif
endfunction

function! g:VimDialog._ClearCtlActivatedHl()
	for k in keys(self._inactiveCtlMatchId)
		exec 'syn clear ' . self._inactiveCtlMatchId[k]
	endfor
	call filter(self._inactiveCtlMatchId, 0)
endfunction

function! g:VimDialog.AddSeparator()
	call self.AddControl(g:VCSeparator.New())
endfunction

function! g:VimDialog.AddBlankLine()
	call self.AddControl(g:VCBlankLine.New())
endfunction

"Function: g:VimDialog.SetupKeyMappings() 设置默认键盘映射 {{{2
function! g:VimDialog.SetupKeyMappings()
	let l:ins = self.interInsName

	"开始设置映射
	if !self.asTextCtrl
		exec "nnoremap <silent> <buffer> " . g:VimDialogActionKey . 
					\" :call ".l:ins.".Action()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogRestoreValueKey . 
					\" :call ".l:ins.".RestoreCtlValue()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogClearValueKey . 
					\" :call ".l:ins.".ClearCtlValue()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogNextEditableCtlKey . 
					\" :call ".l:ins.".GotoNextEdiableCtl()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogPrevEditableCtlKey . 
					\" :call ".l:ins.".GotoPrevEdiableCtl()<Cr>"
		exec "nnoremap <silent> <buffer> " . g:VimDialogToggleExtraHelpKey . 
					\" :call ".l:ins.".ToggleExtraHelp()<Cr>"
	endif

	if !self.isPopup && !self.disableApply
		exec "nnoremap <silent> <buffer> " . g:VimDialogSaveKey . 
					\" :call ".l:ins.".Save()<Cr>"
	endif

	exec "nnoremap <silent> <buffer> " . g:VimDialogSaveAndQuitKey . 
				\" :call ".l:ins.".SaveAndQuit()<Cr>"
	exec "nnoremap <silent> <buffer> " . g:VimDialogQuitKey . 
				\" :call ".l:ins.".ConfirmQuit()<Cr>"

	if !self.asTextCtrl
		"鼠标
		exec "nnoremap <silent> <buffer> " . "<2-LeftMouse>" . 
					\" :call ".l:ins.".Action()<Cr>"
	endif
endfunction

function! g:VimDialog.Close() "{{{2
    "let bak = &ei
    "set eventignore+=BufWinLeave "暂时屏蔽自删动作的自动命令
	let l:winnr = bufwinnr(self.bufNum)
    if l:winnr != -1
		call s:exec(l:winnr . " wincmd w")
		if has_key(self, 'rpmBufNum')
			"若替换的是无名缓冲区，这个没有效果
			exec 'buffer ' . self.rpmBufNum
		else
			"用的是分割出来的窗口
			silent! close
		endif
		if bufexists(self.bufNum)
			"当是替换模式，且替换了无名缓冲区，那么切换的时候无效果，需手动删除
			exec 'bwipeout ' . self.bufNum
		endif
		call s:exec(self.origWinNum . " wincmd w")
    endif
    "let &ei = bak
endfunction

function! g:VimDialog.Save() "{{{2
	if self.lock
		return
	endif

	for i in self.controls
		if has_key(i, "UpdateBindVar")
			call i.UpdateBindVar()
		endif
	endfor

	if has_key(self, 'saveCallback')
		call self.saveCallback(self, self.saveCallbackData)
	endif

	echohl PreProc
	if exists("*strftime")
		echo "All have been saved at "
		echohl Special
		echon strftime("%c")
	else
		echo "All have been saved."
	endif
	echohl None
endfunction

function! g:VimDialog.Delete() "{{{2
	if self.lock
		return
	endif

	unlet {self.interInsName}
	call filter(self, 0)
endfunction

function! g:VimDialog.SaveAndQuit() "{{{2
	if self.lock
		return
	endif

	call self.Save()
	if has_key(self, "callback") "DEPRECATE!
		let l:ret = self.callback(self)
		if l:ret
			"echoerr "callback error"
			return
		endif
	endif
	call self.Quit()
endfunction

function! g:VimDialog.Quit() "{{{2
	if self.lock
		return
	endif

	"删除自删的自动命令, 因为已经不需要了, 这个函数肯定能删除
	autocmd! BufWinLeave <buffer>

	if self.lockParent && !empty(self.parentDlg)
		let self.parentDlg.lock = 0
	endif

	if has_key(self, 'preCallback')
		call self.preCallback(self, self.preCallbackData)
	endif

	for dlg in self.childDlgs
		call dlg.Quit()
	endfor
	if !empty(self.parentDlg)
		call self.parentDlg.RemoveChildDialog(self)
	endif
	call self.Close()

	if has_key(self, 'postCallback')
		call self.postCallback(self, self.postCallbackData)
	endif

	call self.Delete()
endfunction

function! g:VimDialog._ForceQuit() "{{{2
	let self.lock = 0
	call self.Quit()
endfunction

function! g:VimDialog.ConfirmQuit() "{{{2
	if self.lock
		return
	endif

	if self.IsModified() || self.asTextCtrl
		echohl WarningMsg
		let ret = input("Are you sure to quit without save? (y/n): ", 'y')
		if ret ==? 'y'
			call self.Quit()
		endif
		echohl None
	else
		call self.Quit()
	endif
endfunction

"回调函数必须返回 0 以示成功，否则始终不会关闭窗口
"现在这个回调函数只在 SaveAndQuit 的时候调用
function! g:VimDialog.AddCallback(func) "DEPRECATE {{{2
	if type(a:func) == type(function("tr"))
		let self.callback = a:func
	else
		let self.callback = function(a:func)
	endif
endfunction

function! g:VimDialog.ConnectPreCallback(func, data) "关闭窗口前 {{{2
	if type(a:func) == type(function("tr"))
		let self.preCallback = a:func
	else
		let self.preCallback = function(a:func)
	endif
	let self.preCallbackData = a:data
endfunction

function! g:VimDialog.ConnectPostCallback(func, data) "关闭窗口后 {{{2
	if type(a:func) == type(function("tr"))
		let self.postCallback = a:func
	else
		let self.postCallback = function(a:func)
	endif
	let self.postCallbackData = a:data
endfunction

function! g:VimDialog.ConnectSaveCallback(func, data) "保存设置时 {{{2
	if type(a:func) == type(function("tr"))
		let self.saveCallback = a:func
	else
		let self.saveCallback = function(a:func)
	endif
	let self.saveCallbackData = a:data
endfunction

"Function: g:VimDialog.SetupSyntaxHighlight() 设置语法高亮 {{{2
function! g:VimDialog.SetupSyntaxHighlight()
	"只高亮最基本的框架

	"先清除
	call self._ClearCtlActivatedHl()
	syntax clear

	let sufPat = '\v.{' . g:VimDialogCtlKeyBit . '}$'

	"文本框
	syn match VCTextControl '\v\|'
	exec "syn match VCTextControl '".'\v^\s*\+\-+\+\ze'.sufPat."'"
	"表格头与内容的分割线
	exec "syn match VCTextControl '".'\v^\s*\|\-[-+]+\|\ze'.sufPat."'"

	"组合框
	exec "syn match VCComboBoxCtl '".'\v^\s*\+\-+\+\-\+\ze'.sufPat."'"

	"复选控件
	syn match VCCheckCtl '\v\[\zsX\ze\]'

	"通用按钮，按钮字符数至少是 2，为了和复选框区别
	syn match VCButton '\V[\.\{-2,}]'

	"字符串过长时的提示符号
	syn match VCExtend '\V@\ze|'

	if version >= 703
		exec "syn match VCTypeCahr '".sufPat."' conceal"
		hi def link VCTypeCahr Conceal
		set concealcursor=nvc
		set conceallevel=2
	else
		exec "syn match VCTypeCahr '".sufPat."'"
		hi def link VCTypeCahr Ignore
	endif

	hi def link VCTextControl Comment
	hi def link VCComboBoxCtl VCTextControl
	hi def link VCCheckCtl Character
	hi def link VCButton StatusLine
	hi def link VCExtend SpecialKey

	"高亮控件自身的需要的高亮
	for i in self.controls
		call i.SetupHighlight()
	endfor
endfunction

function! g:VimDialog.GotoNextEdiableCtl() "{{{2
	let origRow = line('.')
	let origCtl = self.GetControlByLnum(origRow)

	if !empty(origCtl) && origCtl.GotoNextCtl()
	"控件自身还有空控件没有跳转完毕
		return
	endif

	for row in range(origRow, line('$'))
		let ctl = self.GetControlByLnum(row)
		if !empty(ctl) && ctl isnot origCtl && ctl.IsEditable()
			exec row
			call ctl.GotoNextCtl(1)
			break
		endif
	endfor
endfunction

function! g:VimDialog.GotoPrevEdiableCtl() "{{{2
	let origRow = line('.')
	let origCtl = self.GetControlByLnum(origRow)

	if !empty(origCtl) && origCtl.GotoPrevCtl()
		return
	endif

	for row in range(origRow, 1, -1)
		let ctl = self.GetControlByLnum(row)
		if !empty(ctl) && ctl isnot origCtl && ctl.IsEditable()
			"需要定位到首行
			for row2 in range(row, 1, -1)
				let ctl2 = self.GetControlByLnum(row2)
				if ctl2 isnot ctl
					let row = row2 + 1
					break
				endif
			endfor

			exec row
			call ctl.GotoPrevCtl(1)
			break
		endif
	endfor
endfunction

function! g:VimDialog.ToggleExtraHelp() "{{{2
	if self.lock || self.extraHelpContent == ''
		return
	endif

	setlocal ma
	if self._showExtraHelp
		let self._showExtraHelp = 0
		"删除额外帮助信息
		let extraHelpLineCount = len(split(self.extraHelpContent, '\n'))
		exec 'silent! 4,'. (4 + extraHelpLineCount - 1) .'delete _'
		"恢复原始视图
		if has_key(self, '_saveView')
			call winrestview(self._saveView)
			call remove(self, '_saveView')
		endif
	else
		let self._showExtraHelp = 1
		"保存原始视图
		let self._saveView = winsaveview()
		"显示额外帮助信息
		let contentList = split(self.extraHelpContent, '\n')
		call map(contentList, '"\" " . v:val')
		call append(3, contentList)
		"定位到帮助信息开始处
		call cursor(4, 1)
	endif
	setlocal noma
endfunction
"}}}
"Apply, Cancel, OK 按钮回调函数 {{{2
function! s:_ApplyCbk(ctl, ...)
	call a:ctl.owner.Save()
endfunction
function! s:_CancelCbk(ctl, ...)
	call a:ctl.owner.Quit()
endfunction
function! s:_OKCbk(ctl, ...)
	call a:ctl.owner.SaveAndQuit()
endfunction
"}}}
function! g:VimDialog.AddFooterButtons() "{{{2
	call self.AddBlankLine()
	call self.AddSeparator()

	let ctl = g:VCButtonLine.New('')

	let lButtonLabel = ['Apply ', 'Cancel', '  OK  ']
	let nLen = 0
	for sLabel in lButtonLabel
		let nLen += strdisplaywidth(sLabel) + 2
	endfor
	if len(lButtonLabel)
		let nLen += len(lButtonLabel) - 1
	endif

	call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	call ctl.AddButton(lButtonLabel[0])
	call ctl.AddButton(lButtonLabel[1])
	call ctl.AddButton(lButtonLabel[2])
	call self.AddControl(ctl)

	call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:_ApplyCbk'), '')
	call ctl.ConnectButtonCallback(1, s:GetSFuncRef('s:_CancelCbk'), '')
	call ctl.ConnectButtonCallback(2, s:GetSFuncRef('s:_OKCbk'), '')

	if self.isPopup || self.disableApply
		call ctl.RemoveButton(0)
		call remove(lButtonLabel, 0)

		let nLen = 0
		for sLabel in lButtonLabel
			let nLen += strdisplaywidth(sLabel) + 2
		endfor
		if len(lButtonLabel)
			let nLen += len(lButtonLabel) - 1
		endif
		call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	endif
endfunction
"}}}
function! g:VimDialog.AddCloseButton() "{{{2
	call self.AddBlankLine()
	call self.AddSeparator()

	let ctl = g:VCButtonLine.New('')

	let lButtonLabel = ['Close']
	let nLen = 0
	for sLabel in lButtonLabel
		let nLen += strdisplaywidth(sLabel) + 2
	endfor
	if len(lButtonLabel)
		let nLen += len(lButtonLabel) - 1
	endif

	call ctl.SetIndent((s:VC_MAXLINELEN - nLen) / 2)
	call ctl.AddButton(lButtonLabel[0])
	call self.AddControl(ctl)
	call ctl.ConnectButtonCallback(0, s:GetSFuncRef('s:_CancelCbk'), '')
endfunction
"}}}
function! g:VimDialog.ReplacedBy(dlgIns) "用于替换，暂不可用 {{{2
	call self.Delete()
	call extend(self, a:dlgIns, 'force')
	call self.Display()
endfunction

"===============================================================================
"		测试
"===============================================================================

"Function: g:VimDialogTest() {{{2
function! g:VimDialogTest()
	let g:vimdialog = g:VimDialog.New("VimDialogTest")
	let g:str = ""

	let g:vdst = g:VCStaticText.New("vdst")
	call g:vimdialog.AddControl(g:vdst)

"	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 60))
	let g:ctl = g:VCSingleText.New("单行文本控件")
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件")
	call g:ctl.BindVariable("g:str")
	call g:ctl.SetIndent(8)
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 84))
	call g:ctl.SetActivated(0)
	call g:ctl.ConnectActionCallback('TestCtlCallback', 'Action!')
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCSingleText.New("单行文本控件", repeat('=', 84))
	call g:ctl.SetIndent(4)
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCMultiText.New("多行文本控件", repeat('=', 84) . "\nA\n\nB\nC\nE\nD\nF\nG")
	call g:ctl.SetIndent(4)
	call g:ctl.ConnectButtonCallback('TestCtlCallback', 'button')
	call g:vimdialog.AddControl(g:ctl)

	let g:ctl = g:VCButtonLine.New('')
	call g:ctl.SetIndent(4)
	call g:ctl.AddButton('abc')
	call g:ctl.AddButton('xyz')
	call g:ctl.DisableButton(0)
	call g:ctl.ConnectButtonCallback(1, 'TestCtlCallback', 'ButtonLine')
	call g:vimdialog.AddControl(g:ctl)

	let ctl = g:VCButtonLine.New('')
	call ctl.SetIndent(26)
	call ctl.AddButton('Apply ')
	call ctl.AddButton('Cancel')
	call ctl.AddButton('  OK  ')
	call g:vimdialog.AddControl(ctl)

	call g:vimdialog.AddFooterButtons()

	call g:vimdialog.AddSeparator()
	call g:vimdialog.AddCallback("TestCallback")

	call g:vimdialog.SetIsPopup(1)

	"call g:vimdialog.SetAsTextCtrl(1)
	"call g:vimdialog.SetTextContent("a\nb\nc\nd\ne")
	
	call g:vimdialog.Display()
endfunction


function! g:VimDialogTest2() "{{{2
	return
	let li = []
	let g:confSrc = 'Scorce Files'
	let g:confOptions = '$(shell wx-config --cxxflags --debug=no --unicode=yes);-O2;$(shell pkg-config --cflags gtk+-2.0);-Wall;-fno-strict-aliasing'

	let g:ctl1 = g:VCSingleText.New("g:confSrc")
	let g:ctl2 = g:VCSingleText.New("Options")

	call add(li, g:ctl1)
	call add(li, g:VCSeparator.New())
"	call add(li, g:VCBlankLine.New())
	call add(li, g:ctl2)
	" NOTE: 已不支持此方法
	let g:ins = g:VimDialog.New("__VIMDIALOGTEST2__", li)

"	call g:ins.AddControl(g:ctl1)
"	call g:ins.AddSeparator()
"	call g:ins.AddControl(g:ctl2)

	call g:ctl1.BindVariable("g:confSrc")
	call g:ctl2.BindVariable("g:confOptions")

	call g:ctl1.SetSingleLineFlag(1)
	call g:ctl1.SetLabelDispWidth(20)
	call g:ctl1.SetIndent(8)
"	call g:ctl2.SetSingleLineFlag(1)
	call g:ctl2.SetLabelDispWidth(20)
	call g:ctl2.SetIndent(8)

"	py pyv = "abcdefghijklmn"
"	call g:ctl2.BindVariable("pyv", 1)

	call g:ins.Display()
endfunction


function! TestCallback(arg)
	echo "I am a callback"
	echo a:arg.name
	return 0
endfunction

function! TestCtlCallback(ctl, data)
	echo "I am a callback"
	echo a:ctl.GetValue()
	echo a:data

	return 1
endfunction

function! g:ProjectSettingsTest() "{{{2
	let g:psdialog = g:VimDialog.New("--ProjectSettings--")

	let vimliteHelp = '===== Available Macros: =====' . "\n"
	let vimliteHelp .= "$(ProjectPath)           "
				\."Expand to the project path" . "\n"

	let vimliteHelp .= "$(WorkspacePath)         "
				\."Expand to the workspace path" . "\n"

	let vimliteHelp .= "$(ProjectName)           "
				\."Expand to the project name" . "\n"

	let vimliteHelp .= "$(IntermediateDirectory) "
				\."Expand to the project intermediate directory path, " . "\n"
				\.repeat(' ', 25)."as set in the project settings" . "\n"

	let vimliteHelp .= "$(ConfigurationName)     "
				\."Expand to the current project selected configuration" . "\n"

	let vimliteHelp .= "$(OutDir)                "
				\."An alias to $(IntermediateDirectory)" . "\n"

	let vimliteHelp .= "$(CurrentFileName)       "
				\."Expand to current file name (without extension and " . "\n"
				\.repeat(' ', 25)."path)"."\n"

	let vimliteHelp .= "$(CurrentFilePath)       "
				\."Expand to current file path" . "\n"

	let vimliteHelp .= "$(CurrentFileFullPath)   "
				\."Expand to current file full path (path and full name)" . "\n"

	let vimliteHelp .= "$(User)                  "
				\."Expand to logged-in user as defined by the OS" . "\n"

	let vimliteHelp .= "$(Date)                  "
				\."Expand to current date" . "\n"

	let vimliteHelp .= "$(ProjectFiles)          "
				\."A space delimited string containing all of the " . "\n"
				\.repeat(' ', 25)."project files "
				\."in a relative path to the project file" . "\n"

	let vimliteHelp .= "$(ProjectFilesAbs)       "
				\."A space delimited string containing all of the " . "\n"
				\.repeat(' ', 25)."project files in an absolute path" . "\n"

	let vimliteHelp .= "`expression`             "
				\."Evaluates the expression inside the backticks into a " . "\n"
				\.repeat(' ', 25)."string" . "\n"

	call g:psdialog.SetExtraHelpContent(vimliteHelp)

"===============================================================================
"常规设置
	let ctl = g:VCStaticText.New("General")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("Output File:", 
				\"$(IntermediateDirectory)/$(ProjectName)")
	call ctl.SetIndent(8)
	call ctl.ConnectButtonCallback('TestCtlCallback', 'button')
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Intermediate Folder:", './Debug')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Program:", './$(ProjectName)')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Program Arguments:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

"===============================================================================
"编译器设置
	let ctl = g:VCStaticText.New("Compiler")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("C++ Compiler Options:", "-Wall;-g3")
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("C Compiler Options:", 
				\'-Wall;-g3;$(shell pkg-config --cflags gtk+-2.0)')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Include Paths:", '.')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Preprocessor:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

"===============================================================================
"链接器设置
	let ctl = g:VCStaticText.New("Linker")
	call ctl.SetHighlight("Identifier")
	call g:psdialog.AddControl(ctl)

	let ctl = g:VCSingleText.New("Options:", "$(shell pkg-config --libs gtk+-2.0)")
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Library Paths:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCSingleText.New("Libraries:", '')
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

"	let ctl = g:VCComboBox.New("Combo Box:")
	let ctl = g:VCComboBox.New("")
	call ctl.SetIndent(8)
	call ctl.AddItem("a")
	call ctl.AddItem("b")
	call ctl.AddItem("c")
	call ctl.AddItem("d")
	call ctl.AddItem("e")
	call ctl.AddItem("f")
	call ctl.ConnectActionPostCallback("TestCtlCallback", "Hello")
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

	let ctl = g:VCCheckItem.New("是否启用？", 1)
	call ctl.SetIndent(8)
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()
"===============================================================================

	call g:TestVCTable()
	let ctl = g:ctl
	call g:psdialog.AddControl(ctl)
	call g:psdialog.AddBlankLine()

"===============================================================================

"	call g:psdialog.SetSplitOpen(1)
	call g:psdialog.Display()
endfunction

" vim:fdm=marker:fen:fdl=1:ts=4
