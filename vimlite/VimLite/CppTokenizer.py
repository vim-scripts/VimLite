#!/usr/bin/env python
# -*- coding:utf-8 -*-

import re

def Escape(string, chars):
    result = ''
    for char in string:
        if char in chars:
            # 转义之
            result += '\\' + char
        else:
            result += char
    return result

# C++ 的关键词列表
# From the C++ BNF
lCppKeyword = ['asm', 'auto', 'bool', 'break', 'case', 'catch', 'char', 
            'class', 'const', 'const_cast', 'continue', 'default', 'delete', 
            'do', 'double', 'dynamic_cast', 'else', 'enum', 'explicit', 
            'export', 'extern', 'false', 'float', 'for', 'friend', 'goto', 
            'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new', 
            'operator', 'private', 'protected', 'public', 'register', 
            'reinterpret_cast', 'return', 'short', 'signed', 'sizeof', 
            'static', 'static_cast', 'struct', 'switch', 'template', 'this', 
            'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union', 
            'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t', 
            'while', 'and', 'and_eq', 'bitand', 'bitor', 'compl', 'not', 
            'not_eq', 'or', 'or_eq', 'xor', 'xor_eq']

sCppKeyword = r'\b' + r'\b|\b'.join(lCppKeyword) + r'\b'

# C++ 操作符和标点符号列表, 顺序非常重要, 因为这用于生成用于标记化的正则表达式
lCppOperatorPunctuator = ['->*', '->', '--', '-=', '-', '!=', '!', '##', 
            '#', '%:%:', '%=', '%>', '%:', '%', '&&', '&=', '&', '(', ')', 
            '*=', '*', ',', '...', '.*', '.', '/=', '/', '::', ':>', ':', 
            ';', '?', '[', ']', '^=', '^', '{', '||', '|=', '|', '}', '~', 
            '++', '+=', '+', '<<=', '<%', '<:', '<<', '<=', '<', '==', '=', 
            '>>=', '>>', '>=', '>']

#lCppOperatorPunctuator = [Escape(i, '.[]*+?{}^$|()')
                          #for i in lCppOperatorPunctuator]

lCppOperatorPunctuator = [Escape(i, '.^$*+?{}[]|()')
                          for i in lCppOperatorPunctuator]
sCppOperatorPunctuator = r'|'.join(lCppOperatorPunctuator)


reCppKeyword = re.compile(sCppKeyword)
reCppOperatorPunctuator = re.compile(sCppOperatorPunctuator)
reComment = re.compile(r'/\*|\*/|//')

# 不分组版本
reTokenSearch = re.compile(r'\w+|\s+|'
                           + reComment.pattern + r'|'
                           + reCppOperatorPunctuator.pattern + '')

# ==============================================================================

# 匹配 C++ 字符串, eg. "I'm \"The One.\""
reCppString = re.compile(r'"(?:[^"]|(?<=\\)")*"')
# 匹配 C++ 单个字符, eg. '"', 'a', '\''
reCppChar = re.compile(r"'(?:[^']|(?<=\\)')'")

# 匹配 C++ 数字
reCppDigit = re.compile(r'\d+')
# 匹配单词
reWord = re.compile(r'\w+$')

# 匹配预处理行
rePreProc = re.compile(r'\s*#')

# 匹配 C++ 行注释
reCppComment = re.compile(r'(?P<cppComment>//.*$)')

# 分组匹配顺序
# 关键单词 -> 非关键单词 -> 注释('//'注释暂时无视) -> 字符串 -> 单字符 -> 数字
#          -> 操作符
# cppKeyword -> cppWord -> cComment/cppComment -> cppString -> cppChar -> 
#            -> cppDigit -> cppOperatorPunctuator
patCppKeyword = r'(?P<cppKeyword>' + sCppKeyword + ')'
patCppWord = r'(?P<cppWord>[a-zA-Z_][a-zA-Z_0-9]*)'
patCComment = r'(?P<cComment>/\*.*?\*/)'
patCppComment = r'(?P<cppComment>//.*)'
patCppString = r'(?P<cppString>' + reCppString.pattern + ')'
patCppChar = r'(?P<cppChar>' + reCppChar.pattern + ')'
patCppDigit = r'(?P<cppDigit>' + reCppDigit.pattern + ')'
patCppOperatorPunctuator = r'(?P<cppOperatorPunctuator>' \
        + reCppOperatorPunctuator.pattern + ')'

# 四组 (单词, 空白, 注释符, 字符串, 单字符, 操作符)
reTokenSearchGroups = re.compile(patCppKeyword + '|'
                                 + patCppWord + '|'
                                 + patCComment + '|'
                                 + patCppComment + '|'
                                 + patCppString + '|'
                                 + patCppChar + '|'
                                 + patCppDigit + '|' 
                                 + patCppOperatorPunctuator)
#reTokenSearchGroups = re.compile(r'(?P<cppWord>\w+)|(\s+)|('
                                 #+ reComment.pattern + r')|('
                                 #+ reCppString.pattern + r')|('
                                 #+ reCppChar.pattern + r')|('
                                 #+ reCppOperatorPunctuator.pattern + ')')

# ==============================================================================

def Tokenize_old(sCode):
    '''使用 omnicppcomplete 的 Tokenize 算法, 可改进'''
    lResult = []

    m = reTokenSearch.search(sCode)
    nStartPos = 0
    while m:
        sToken = re.sub(r'\s', '', sCode[nStartPos : m.end(0)])

        nStartPos = m.end(0)
        m = reTokenSearch.search(sCode, nStartPos)

        if not sToken:
            continue

        dToken = {'kind': 'unknow', 'value': sToken}

        # 区分类型
        #if re.match(r'\d+', sToken):
        if reCppDigit.match(sToken):
            # 数字
            dToken['kind'] = 'cppDigit'
        #elif re.match(r'\w+$', sToken):
        elif reWord.match(sToken):
            # 单词
            dToken['kind'] = 'cppWord'

            # 也有可能是 C++ 关键词
            if reCppKeyword.match(sToken):
                dToken['kind'] = 'cppKeyword'
        else:
            if reComment.match(sToken):
                # 注释符
                if sToken == '/*' or sToken == '*/':
                    dToken['kind'] = 'cComment'
                else:
                    dToken['kind'] = 'cppComment'
            else:
                # 操作符
                dToken['kind'] = 'cppOperatorPunctuator'

        lResult.append(dToken)

    return lResult

def Tokenize(sCode):
    '''使用最适合的算法重写
    如果需要把多行代码用空格连接成一行, 请剔除所有单行注释(//)后再调用此函数
    
    如果类型为注释, 字符串, 单字符, 把 value 置空, 避免转为 vim 字典时的麻烦'''
    lResult = []
    for m in reTokenSearchGroups.finditer(sCode):
        if m.lastgroup:
            sValue = m.group(m.lastgroup)
            if m.lastgroup == 'cppString' or m.lastgroup == 'cppChar' \
               or m.lastgroup == 'cComment' or m.lastgroup == 'cppComment':
                sValue = ''
            dToken = {'kind': m.lastgroup, 'value': sValue}
            lResult.append(dToken)
    return lResult


def TokenizeLines(lLines):
    '''处理多行'''
    lResult = []
    li = []
    #sLines = ''
    for sLine in lLines:
        # vim.eval() 返回的列表中的项可能是 None
        # 排除预处理行
        if sLine and not rePreProc.match(sLine):
            #lResult.extend(Tokenize(sLine))
            li.append(reCppComment.sub('', sLine))
            #sLines += ' ' + sLine

    sLines = ' '.join(li)

    lResult = Tokenize(sLines)
    return lResult


def Test():
    s = r'''cout << CEnumDB::GetEnumVarName("em", 1) /* comment */ << endl /*xy*/;
    printf("%d\n", n); // abc'''
    print s
    print sCppKeyword
    print reCppKeyword.pattern
    print lCppOperatorPunctuator
    print sCppOperatorPunctuator
    print Escape(r'c:\program files\vim', ' \\')
    print reCppOperatorPunctuator.findall(
        'cout << CEnumDB::GetEnumVarName("em", 1) << endl;')
    print reComment.pattern
    print reTokenSearch.search(s).groups()
    #print reTokenSearch.findall(s)

    lTokens = Tokenize_old(s)
    for dToken in lTokens:
        print dToken
    #print len(s)
    print '-' * 60
    lTokens = Tokenize(s)
    for dToken in lTokens:
        print dToken
    #print reTokenSearchGroups.pattern
    print '-' * 60
    li = [r'cout << CEnumDB::GetEnumVarName("em", 1) /* comment */ << endl /*xy*/;',
         r'printf("%d\n", n); // abc']
    li = [r'class C;// CppComment', r'/*', r'CComments.', r'*/', r'class Cls;']
    lTokens = TokenizeLines(li)
    for dToken in lTokens:
        print dToken


if __name__ == "__main__":
    Test()

