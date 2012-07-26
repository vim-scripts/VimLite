#!/usr/bin/env python
# -*- coding:utf-8 -*-

from FileReader import FileReader
import CppTokenizer
from CppTokenizer import Tokenize
import sys
import re
import json

# 必须在这个作用域 import CxxParser，走则 sys.argv 无法用于传参数给 CxxParser
# 外部可能不需要使用 CxxParser，这时候，CxxParser 很可能会在 import 的时候出错
# 外部如果不需要使用 CxxParser 的时候，不应该调用 CxxGetScopeStack，否则会出错
try:
    import CxxParser
except:
    pass

from CppTokenizer import CPP_KEYOWORD
from CppTokenizer import CPP_WORD
from CppTokenizer import C_COMMENT
from CppTokenizer import C_UNFIN_COMMENT
from CppTokenizer import CPP_COMMENT
from CppTokenizer import CPP_STRING
from CppTokenizer import CPP_CHAR
from CppTokenizer import CPP_DIGIT
from CppTokenizer import CPP_OPERATORPUNCTUATOR

# 字符占位符，主要用在字符串和字符里面
PLACEHOLDER_CHAR = ' '

def CppTokenize(s):
    '''必须把换行换成空格，方便正则处理'''
    return CppTokenizer.CppTokenize(s.replace('\n', ' '))

def EscapeStr(string, chars):
    '''用 '\\' 转义指定字符'''
    result = ''
    for char in string:
        if char in chars:
            # 转义之
            result += '\\' + char
        else:
            result += char
    return result

def SkipToNonSpace(fr):
    '''跳至第一个非空白的字符并返回该字符'''
    c = None
    while True:
        c = fr.GetCharNormalized()
        if c is None:
            break
        if c.isspace():
            continue
    return c

class TokensReader:
    def __init__(self, tokens):
        '''tokens 必须是列表'''
        self.__tokens = tokens
        self.tokens = self.__tokens[::-1] # 副本，翻转顺序
        self.popeds = [] # 已经被弹出去的 token，用于支持 PrevToken()

    def GetToken(self):
        '''获取下一个 token，若到尾部，返回 None'''
        if self.tokens:
            tok = self.tokens.pop(-1)
            self.popeds.append(tok)
            return tok
        else:
            # popeds 数据结构也要加上这个，以便统一处理
            if self.popeds and not self.popeds[-1] is None:
                self.popeds.append(None)
            return None

    def UngetToken(self, token):
        '''反推 token，外部负责 token 的正确性'''
        self.tokens.append(token)
        if self.popeds:
            self.popeds.pop(-1)

    def PeekToken(self):
        if self.tokens:
            return self.tokens[-1]
        else:
            return None

    def PrevToken(self):
        if len(self.popeds) >= 2:
            return self.popeds[-2]
        else:
            return None

    def GetOrigTokens(self):
        return self.__tokens


CppBuiltinTypes = {
    'bool': 1, 
    'char': 1, 
    'double': 1, 
    'float': 1, 
    'int': 1, 
    'long': 1, 
    'short': 1, 
    'signed': 1, 
    'unsigned': 1, 
    'void': 1, 
    'wchar_t': 1, 
    'short int': 1, 
    'long long': 1, 
    'long double': 1, 
    'long long int': 1, 
}


# 返回 TypeInfo {"name": "", "til": [], "types": []}
# A<B>::C::D<E<Z>, F>::G<Y> g;
# ->
# {
# "name": "A::C::D::G",
# "til": [" Y"],
# "types": [{'name': 'A', 'til': [' B']}, 
#           {'name': 'C', 'til': []}, 
#           {'name': 'D', 'til': [' E < Z >', ' F']}, 
#           {'name': 'G', 'til': []}]
# }
# TODO
def ParseVariableType(stmt, var = ''):
    '''var 为变量名字'''
    trd = TokensReader(CppTokenize(stmt))

    # GO
    ti = {'name': '', 'til': [], 'types': []}
    state = 0
    # 0 -> 期望 '::' 和 单词, 作为解析的起点. eg1. |::A eg2. |A::B
    # 1 -> 期望 单词. eg. A::|B
    # 2 -> 期望 '::'. eg. A|::B 也可能是 A|<B>::C
    while True:
        curToken = trd.GetToken()
        if curToken is None:
            break

        # state 0 start
        if state == 0:
            if curToken.value == '::':
                # eg. ::A a
                ti['name'] += curToken.value
                st = {'name': '', 'til': []}
                st['name'] = '<global>'
                ti['types'].append(st)

                state = 1
            elif curToken.kind == CPP_WORD:
                if curToken.value == var:
                    # 遇到同名的, 检查前一个 token, 若不是 'struct' 之类的, 
                    # 肯定不是有效的声明, 肯定在之前已经定义了, 结束
                    if not trd.PrevToken() is None \
                       and trd.PrevToken().value \
                            in set(['struct', 'union', 'enum']):
                        # 有效的声明，不做任何事
                        pass
                    else:
                        # 无效声明，结束
                        break

                ti['name'] += curToken.value
                st = {'name': '', 'til': []}
                st['name'] = curToken.value
                ti['types'].append(st)

                state = 2
            elif curToken.kind == CPP_KEYOWORD \
                    and CppBuiltinTypes.has_key(curToken.value):
                ti['name'] += curToken.value

                # unsigned *
                if curToken.value == 'unsigned' and trd.PeekToken():
                    curToken = trd.GetToken()
                    if curToken.kind == CPP_KEYOWORD \
                       and CppBuiltinTypes.has_key(curToken.value):
                        ti['name'] += ' ' + curToken.value

                # short int
                # long long
                # long long int
                # long double
                if curToken.value == 'long':
                    while True:
                        curToken = trd.GetToken()
                        if curToken is None:
                            break
                        if curToken.value in set(['long', 'int', 'double']):
                            ti['name'] += ' ' + curToken.value
                        else:
                            trd.UngetToken(curToken)
                            break
                elif curToken.value == 'short':
                    if not trd.PeekToken() is None \
                       and trd.PeekToken().value == 'int':
                        ti['name'] += ' ' + trd.PeekToken().value
                        curToken = trd.GetToken()

                st = {'name': '', 'til': []}
                st['name'] = curToken.value
                ti['types'].append(st)

                # 内置类型, 可能结束, 需要检查此语法是否有函数
                state = 2
            elif curToken.value == '(':
                # 可能是一个 cast, 需要跳至匹配的 ')' 之后的位置
                # eg. (A *)&B;
                # 也可能是 for ( A a
                if not trd.PrevToken() is None \
                   and trd.PrevToken().value == 'for':
                    # for ( A a
                    pass
                else:
                    # 跳过
                    tmpNest = 1
                    while tmpNest != 0:
                        curToken = trd.GetToken()
                        if curToken is None:
                            break
                        if curToken.value == '(':
                            tmpNest += 1
                        elif curToken.value == ')':
                            tmpNest -= 1
        # state 0 end

        # state 1 start
        elif state == 1:
            if curToken.kind == CPP_WORD:
                ti['name'] += curToken.value
                st = {'name': '', 'til': []}
                st['name'] = curToken.value
                ti['types'].append(st)

                state = 2
            else:
                # 有语法错误?
                # eg. A::| *
                break
        # state 1 end

        # state 2 start
        elif state == 2:
            if curToken.value == '::':
                ti['name'] += curToken.value
                state = 1
            elif curToken.value == '<':
                # 上一个解析完毕的标识符是模版类
                tmpNest = 1
                unitType = ''
                while True:
                    curToken = trd.GetToken()
                    if curToken is None:
                        break
                    if curToken.value == '<':
                        tmpNest += 1
                        if tmpNest == 1:
                            unitType = ''
                        else:
                            unitType += ' ' + curToken.value
                    elif curToken.value == '>':
                        tmpNest -= 1
                        if tmpNest == 0:
                            # TODO: check
                            ti['types'][-1]['til'].append(unitType)
                            break
                        else:
                            unitType += ' ' + curToken.value
                    elif curToken.value == ',':
                        if tmpNest == 1:
                            # TODO: check
                            ti['types'][-1]['til'].append(unitType)
                            unitType = ''
                        else:
                            unitType += ' ' + curToken.value
                    else:
                        unitType += ' ' + curToken.value

            elif curToken.value == '(':
                # 可能是函数形参中的变量声明, 即之前分析的是函数, 需重新再来
                # 也可能是 A (*a)[];, 也需要重新再来
                # 先检查后者
                if not trd.PeekToken() is None and trd.PeekToken().value == '*':
                    # 此情况视作类型 A
                    # 完成
                    break

                # 处理函数形参用的变量声明，算是一种轻量递归
                ti = {'name': '', 'til': [], 'types': []}
                state = 0

                # 如果指定了变量名，寻找匹配变量名的那个参数，然后重新解析
                tmpNest = 0
                if var:
                    restartTokens = []
                    while True:
                        curToken = trd.GetToken()
                        restartTokens.append(curToken)
                        if curToken is None:
                            break
                        if curToken.value == '<':
                            tmpNest += 1
                        elif curToken.value == '>':
                            tmpNest -= 1
                        elif curToken.value == ',':
                            if tmpNest == 0:
                                restartTokens = []
                        elif curToken.kind == CPP_WORD \
                                and curToken.value == var:
                            # 找到了
                            break
                    trd = TokensReader(restartTokens)

                continue
            else:
                # 期望 '::', 遇到了其他东东
                if curToken.value == ':':
                    # 遇到标签, 重新开始
                    # eg. Label: A a;
                    state = 0
                    ti = {'name': '', 'til': [], 'types': []}
                    continue
                elif curToken.value == '=':
                    # 应该是一个赋值表达式，要么跳过这个语句，要么直接返回失败
                    # 暂时假设传进来的参数都是一个语句，直接返回失败
                    # eg. a = |b * c;
                    # TODO: 返回什么表示失败？
                    ti = {'name': '', 'til': [], 'types': []}
                    break
                elif curToken.value == '.' or curToken.value == '->':
                    # 应该可以确定不是一个声明语句
                    # eg. a.|b = b->c * d;
                    ti = {'name': '', 'til': [], 'types': []}
                    # TODO: 返回什么表示失败？
                    break
                else:
                    # 检查是否有函数
                    # eg. int |A(B b, C c)
                    hasFunc = False
                    while True:
                        curToken = trd.GetToken()
                        if curToken is None:
                            break
                        if curToken.value == '(':
                            # 有函数，进入函数处理入口
                            # TODO: 函数参数解析应该独立出来
                            trd.UngetToken(curToken)
                            hasFunc = True
                            break
                    if hasFunc:
                        continue
                    else:
                        break
        # state 2 end

    if ti['types']:
        ti['til'] = ti['types'][-1]['til']
    return ti

def test_ParseVariableType():
    s1 = 'const MyClass&'
    s2 = 'const map < int, int >&'
    s3 = 'MyNs::MyClass'
    s4 = '::MyClass**'
    s5 = 'MyClass a, *b = NULL, c[1] = {};'
    s6 = 'A<B>::C::D<E<Z>, F>::G g;'
    s7 = 'hello(MyClass1 a, MyClass2* b'
    s8 = 'Label: A a;'
    s9 = 'A (*a)[10];'
    print s1
    print ParseVariableType(s1)
    print s2
    print ParseVariableType(s2)
    print s3
    print ParseVariableType(s3)
    print s4
    print ParseVariableType(s4)
    print s5
    print ParseVariableType(s5)
    print s6
    print ParseVariableType(s6)
    print s7
    print ParseVariableType(s7)
    print ParseVariableType(s7, 'a')
    print ParseVariableType(s7, 'b')
    print s8
    print ParseVariableType(s8)
    print s9
    print ParseVariableType(s9)

    print ParseVariableType('A<B>::<B>')


# TODO: "class Z::A"
def ParseScopes(stmt):
    '''返回 Scope 列表，每个项目是 CppScope 对象
    对于每个 CppScope 对象，只填写 kind 和 name 字段'''
    trd = TokensReader(CppTokenize(stmt))
    scopes = []

    # GO
    SCOPTTYPE_COMMON = 0
    SCOPETYPE_CONTAINER = 1
    SCOPETYPE_SCOPE = 2
    SCOPETYPE_FUNCTION = 3
    scopeType = SCOPTTYPE_COMMON # 0 表示无名块类型
    while True:
        # 首先查找能确定类别的关键字符
        # 0. 无名块(if, while, etc.)
        # 1. 容器类别 'namespace|class|struct|union'. eg. class A
        # 2. 作用域类别 '::'. eg. A B::C::D(E)
        # 3. 函数类别 '('. eg. A B(C)
        curToken = trd.GetToken()
        if curToken is None:
            break

        if curToken.kind == CPP_KEYOWORD \
           and curToken.value in set(['namespace', 'class', 'struct', 'union']):
            # 容器类别
            # 取最后的 cppWord, 因为经常在名字前有修饰宏
            # eg. class WXDLLIMPEXP_SDK BuilderGnuMake;
            while True:
                curToken = trd.GetToken()
                if curToken is None or curToken.kind != CPP_WORD:
                    break
            prevTok = trd.PrevToken()
            scopeType = SCOPETYPE_CONTAINER
            newScope = CppScope()
            newScope.kind = 'container'
            newScope.name = prevTok.value

            # 也可能是函数，例如: 'struct tm * A::B::C(void *p)'
            needRestart = False
            # added on 2012-07-04
            tmpToks = [] # 用来恢复的
            # 不是这样的时候才需要继续检查 'struct xx {'
            if not trd.PeekToken() is None and trd.PeekToken().value != '{':
                while True: # 检查是否函数，方法是检查后面是否有 '('
                    curToken = trd.GetToken()
                    if curToken is None:
                        break
                    tmpToks.append(curToken)
                    if curToken.kind == CPP_OPERATORPUNCTUATOR \
                       and curToken.value == '(':
                        needRestart = True
                        # 恢复
                        for t in tmpToks[::-1]:
                            trd.UngetToken(t)
                        break
                # added on 2012-07-04 -*- END -*-

            if needRestart:
                continue
            else:
                scopes.append(newScope)
                # OK
                break
        elif curToken.kind == CPP_KEYOWORD and curToken.value == 'else':
            if not trd.PeekToken() is None and trd.PeekToken().value == 'if':
                # 也可能是 else if {
                pass
            else:
                # else 条件语句
                newScope = CppScope()
                newScope.kind = 'other'
                newScope.name = curToken.value
                scopes.append(newScope)
                # OK
                break
        elif curToken.kind == CPP_KEYOWORD and curToken.value == 'extern':
            # 忽略 'extern "C" {'
            peekTok = trd.PeekToken()
            if peekTok is None:
                break
            if peekTok.kind == CPP_STRING \
               or peekTok.kind == CPP_OPERATORPUNCTUATOR:
                break
        elif curToken.kind == CPP_OPERATORPUNCTUATOR and curToken.value == '::':
            scopeType = SCOPETYPE_SCOPE
            # FIXME: 不能处理释构函数 eg. A::~A()
            # 现在会把析构函数解析为构造函数
            # 由于现在基于 ctags 的 parser, 会无视函数作用域,
            # 所以暂时工作正常
            prevTok = trd.PrevToken()
            tempScopes = []
            if not prevTok is None:
                newScope = CppScope()
                newScope.kind = 'container'
                newScope.name = trd.PrevToken().value
                tempScopes.append(newScope)
            # 继续分析
            # 方法都是遇到操作符('::', '(')后确定前一个 token 的类别
            needRestart = False
            # 连续单词数，若大于 1，重新开始
            serialWordCount = 0
            while True:
                curToken = trd.GetToken()
                if curToken is None:
                    break
                if curToken.kind == CPP_OPERATORPUNCTUATOR \
                   and curToken.value == '(':
                    newScope = CppScope()
                    newScope.kind = 'function'
                    prevTok = trd.PrevToken()
                    if prevTok.kind == CPP_KEYOWORD:
                        newScope.kind = 'other'
                    newScope.name = prevTok.value
                    tempScopes.append(newScope)
                    # 到了函数参数或条件判断位置, 已经完成
                    break
                elif curToken.kind == CPP_OPERATORPUNCTUATOR \
                        and curToken.value == '::':
                    serialWordCount = 0
                    newScope = CppScope()
                    newScope.kind = 'container'
                    newScope.name = trd.PrevToken().value
                    tempScopes.append(newScope)
                elif curToken.kind == CPP_KEYOWORD or curToken.kind == CPP_WORD:
                    serialWordCount += 1
                    if serialWordCount > 1: # 连续的单词，如 std::a func()
                        needRestart = True
                        trd.UngetToken(curToken)
                        break
            if needRestart:
                # 例如: std::string func() {
                pass
            else:
                # OK
                scopes.extend(tempScopes)
                break
        elif curToken.kind == CPP_OPERATORPUNCTUATOR and curToken.value == '(':
            # 函数或条件类型
            scopeType = SCOPETYPE_FUNCTION
            prevTok = trd.PrevToken()
            if not prevTok is None:
                newScope = CppScope()
                newScope.kind = 'function'
                if prevTok.kind == CPP_KEYOWORD:
                    newScope.kind = 'other'
                newScope.name = prevTok.value
                scopes.append(newScope)
                # OK
                break
        else:
            if trd.PeekToken() is None:
                # 到达最后但是还不能确定为上面的其中一种
                # 应该是一个无名块, 视为 other 类型
                newScope = CppScope()
                newScope.kind = 'other'
                newScope.name = curToken.value
                scopes.append(newScope)
    # while END
    return scopes

def test_ParseScopes():
    li = [
        'class Z::A',
        'for ( ;; )',
        'class A',
        'namespace std {',
        'struct pw;',
        'A B::C::D(E);',
        'A B(C);',
        'else if (0) {',
        'A::~A(){',
        'std::string abc::func(std::string &);',
        'struct tm * A::B::C(void *p)',
    ]
    for l in li:
        print '-' * 10
        print l
        scps = ParseScopes(l)
        PrintList(scps)


# Scope 数据结构
# {
# 'kind':       <'file'|'container'|'function'|'other'>, 
# 'name':       <scope name>, 
# 'nsinfo':     <NSInfo>, 
# 'includes':   [<header1>, <header2>, ...]
# }
#
# NSInfo 字典
# {
# 'nsalias': {}     <- namespace alias
# 'using': {}       <- using 语句，{"string": "std::strng"}
# 'usingns': []     <- using namespace
# }
# ScopeStack 数据结构
# [<scope1>, <scope2>, ...]
class CppScope:
    '''Cpp 中一个作用域的数据结构'''
    def __init__(self):
        self.kind = ''
        self.name = ''
        self.nsinfo = NSInfo()
        self.includes = [] # 这个暂不支持
        self.vars = {} # 变量字典
                       # {'name': {"line": 10, "type": {"types": [<types>]]}}, ...}
        self.stmt = '' # 'file' 类型为空
        self.cusrstmt = '' # 光标前的未完成的语句

    def ToEvalStr(self):
        nsinfoEvalStr = '{}'
        s = '{"stmt": "%s", "kind": "%s", "name": "%s", '\
                '"nsinfo": %s, "vars": %s, "cusrstmt": "%s", "includes": []}' \
                % (EscapeStr(self.stmt, '"\\'),
                   self.kind, self.name, self.nsinfo.ToEvalStr(),
                   json.dumps(self.vars), EscapeStr(self.cusrstmt, '"\\'))
        return s

    def __repr__(self):
        return self.ToEvalStr()

    def Print(self):
        print self.ToEvalStr()

class NSInfo:
    '''名空间信息'''
    def __init__(self):
        '''using 的时候，不需要考虑 usingns 了，是绝对路径'''
        self.usingns = []   # using namespace std;
        self.using = {}     # using std::string;
        self.nsalias = {}   # namespace s = std;

    def AddUsingNamespace(self, nsName):
        self.usingns.append(nsName)

    def AddUsing(self, usingStr):
        if usingStr:
            self.using[usingStr.split('::')[-1]] = usingStr

    def AddNamespaceAlias(self, s1, s2):
        if s1: # vim 不允许空字符串为键值
            self.nsalias[s1] = s2

    def ToEvalStr(self):
        s = '{"usingns": %s, "using": %s, "nsalias": %s}' \
                % (json.dumps(self.usingns),
                   json.dumps(self.using),
                   json.dumps(self.nsalias))
        return s

    def __repr__(self):
        return self.ToEvalStr()

# 五种全局状态：常规、字符串、字符、C 注释、C++ 注释。
# 其中字符串和字符状态里面的 '\' 会转义，所有状态的续行都有效
class CppFileReader(FileReader):
    STATE_NORMAL = 0
    STATE_STRING = 1
    STATE_CHAR = 2
    STATE_C_COMENT = 3
    STATE_CPP_COMMENT = 4

    def __init__(self, fn):
        FileReader.__init__(self, fn)
        self.state = self.STATE_NORMAL

    # 获取 C 源代码字符串中的字符，透明化注释
    def __GetCharWithoutComment(self):
        ''' 必须确保是常规状态时调用此函数
        None == "/" 这个语句没有问题'''
        c = self.GetChar()
        # 处理注释
        if c == '/':
            nc = self.GetChar()
            if nc == '*':
                c = self.__SkipOverCComment()
            elif nc == '/':
                c = self.__SkipOverCppComment()
            else:
                self.UngetChar(nc)
        return c

    def GetCharNormalized(self):
        '''规格化获取 Cpp 的字符
        处理完续行，注释，同时把字符串和字符里面的内容替换成指定占位符'''
        c = self.GetChar()
        if c == '\\' and self.PeekChar() == '\n': # 续行处理
            self.GetChar() # 扔掉 '\n'
            c = self.GetChar()

        if self.state == self.STATE_NORMAL:
            if c == '"':
                self.state = self.STATE_STRING
            elif c == "'":
                self.state = self.STATE_CHAR
            elif c == '/' and self.state == self.STATE_NORMAL:
                self.UngetChar(c)
                c = self.__GetCharWithoutComment()
        elif self.state == self.STATE_STRING:
            if c == '\\':
                c = self.GetChar() # 扔掉 '\\'
                c = PLACEHOLDER_CHAR # 用这个字符代替
            elif c == '"':
                self.state = self.STATE_NORMAL
            else:
                c = PLACEHOLDER_CHAR
        elif self.state == self.STATE_CHAR:
            if c == '\\':
                c = self.GetChar() # 扔掉 '\\'
                c = PLACEHOLDER_CHAR # 用这个字符代替
            elif c == "'":
                self.state = self.STATE_NORMAL
            else:
                c = PLACEHOLDER_CHAR
        else:
            pass

        #if not c is None:
            #sys.stdout.write(c)

        return c

    def __SkipOverCComment(self):
        '''跳过 C 注释
        如果遇到注释结束符号返回空格，
        如果直到文件结束都找不到结束符号，返回 None 以示结束'''
        c = None
        while True:
            c = self.GetChar()
            if c is None:
                break
            if c == '*' and self.PeekChar() == '/':
                self.GetChar() # 扔掉
                c = ' '
                break
        return c

    def __SkipOverCppComment(self):
        '''跳过 Cpp 注释
        如果到达文件结尾，返回 None，
        如果到达行末，返回 "\n"'''
        c = None
        while True:
            c = self.GetChar()
            if c is None:
                break
            elif c == '\\':
                self.GetChar() # 转义，扔掉下一个字符
            if c == '\n':
                break
        return c



reForWord = re.compile(r'\bfor\b')
reNSInfoCheck = re.compile(r'^\s*(?:using|namespace)\s+')
reUsingNSDump = re.compile(r'^\s*using\s+namespace\s+([a-zA-Z0-9_:]+)')
reUsingDump = re.compile(r'^\s*using\s+([a-zA-Z0-9_:]+)')
reNSAliasDump = re.compile(
    r'^\s*namespace\s+([a-zA-Z0-9_]\w+)\s*=\s*([a-zA-Z0-9_:]+)')
def t1():
    s1 = '   using  namespace   std;'
    s2 = '  using    std::string;    '
    s3 = '   namespace xyz  =  abc::def::ghi ; '
    s4 = ' void std::string();'
    assert reNSInfoCheck.match(s1)
    assert reNSInfoCheck.match(s2)
    assert reNSInfoCheck.match(s3)
    assert not reNSInfoCheck.match(s4)
    assert reUsingNSDump.match(s1).group(1) == 'std'
    assert not reUsingNSDump.match(s2)
    assert not reUsingNSDump.match(s3)
    assert reUsingDump.match(s1).group(1) == 'namespace'
    assert reUsingDump.match(s2).group(1) == 'std::string'
    assert not reUsingDump.match(s3)
    assert not reNSAliasDump.match(s1)
    assert not reNSAliasDump.match(s2)
    assert reNSAliasDump.match(s3).group(1, 2) == ('xyz', 'abc::def::ghi')
t1()

def ParseNamespaceInfo(stmt, nsinfo):
    '''nsinfo 为 NSInfo 对象，可能会修改
    若能解析出名空间信息，修改 nsinfo 并返回 True
    否则返回 False，不会修改 nsinfo'''
    if not reNSInfoCheck.match(stmt):
        return False

    # 检查 using namespace
    m = reUsingNSDump.match(stmt)
    if m:
        nsinfo.AddUsingNamespace(m.group(1))
        return True

    # 再检查 using
    m = reUsingDump.match(stmt)
    if m:
        nsinfo.AddUsing(m.group(1))
        return True

    # 最后检查 namespace alias
    m = reNSAliasDump.match(stmt)
    if m:
        k, v = m.group(1, 2)
        nsinfo.AddNamespaceAlias(k, v)
        return True

    # 都搞不定，应该是语法错误了
    return False

def SkipToChar(fr, ch):
    '''跳到指定的字符，如果一直找不到，将会返回 None，表示到文件尾'''
    c = None
    while True:
        c = fr.GetCharNormalized()
        if c is None:
            break
        if c == ch:
            break
    return c

def PyGetScopeStack(lines, var = ''):
    fr = CppFileReader(lines)
    # 项目为字典 {'type': '', 'stmt': '', 'vars': ['name': '', 'stmt': '']}
    rawScopes = []
    nestLv = 0 # scope 嵌套级别
    stmt = ''
    needCheckPreproc = False # 当遇到 '\n' 时，这个为 True，要剔除掉预处理行
    nsinfo = NSInfo()

    reVarCheck = None
    if var:
        reVarCheck = re.compile(r'\b%s\b' % var)

    # 先建一个全局的 scope 并添加
    scope = CppScope()
    scope.kind = 'file'
    scope.name = ''
    rawScopes.append(scope)

    while True:
        #c = fr.GetChar()
        c = fr.GetCharNormalized()
        if c is None:
            break
        stmt += c

        if c == '\n':
            needCheckPreproc = True
            continue

        if needCheckPreproc:
            if c.isspace():
                continue
            elif c == '#': # 应该不会有其他状况吧...
                SkipToChar(fr, '\n')
                stmt = '' # 清空句子缓存
                continue

        needCheckPreproc = False

        # 已经处理完毕预处理行了
        # ====================================================================

        if c == '{':
            nestLv += 1
            # 加入 rawScopes
            #rawScopes.append({'type': '', 'stmt': stmt.rstrip('{').strip()})
            scope = CppScope()
            scope.stmt = stmt.rstrip('{').strip()
            rawScopes.append(scope)
        elif c == '}':
            nestLv -= 1
            # 弹出最后的 scope
            rawScopes.pop(-1)

        if c == ';' or c == '{' or c == '}': # 句子结束的标志，理论上 ':' 也是
            # for ( ;; ) <- for 语句比较特别
            if c == ';' and reForWord.match(stmt.lstrip()):
                # 跳到 ')'
                while True:
                    tc = fr.GetCharNormalized()
                    if tc is None:
                        break
                    stmt += tc
                    if tc == ')':
                        break
            else:
                # 清空 stmt 之前需要分析 stmt，主要包括名空间和指定变量的声明
                if not ParseNamespaceInfo(stmt, scope.nsinfo):
                    # 解析名空间信息失败，再尝试解析变量声明
                    if reVarCheck:
                        m = reVarCheck.search(stmt)
                        if m:
                            # TODO: 解析变量
                            ParseVariableType(stmt, var)
                stmt = ''
    #PrintList(rawScopes)

    # 把不完整的语句添加到尾部 scope 的 cusrstmt
    scope.cusrstmt = stmt.strip()

    scopeStack = []
    for idx, rawScope in enumerate(rawScopes):
        if idx == 0:
            # 第一个 scope 直接用即可
            scopeStack.append(rawScope)
            continue
        #print rawScope.stmt
        scopes = ParseScopes(rawScope.stmt)
        if scopes:
            scopes[-1].nsinfo = rawScope.nsinfo
            scopes[-1].includes = rawScope.includes
            scopes[-1].vars = rawScope.vars
            #scopes[-1].stmt = rawScope.stmt
            scopes[-1].cusrstmt = rawScope.cusrstmt
        scopeStack.extend(scopes)
    #print '=' * 20, 'scope stack'
    #PrintList(scopeStack)
    return scopeStack

def CxxGetScopeStack(lines):
    '''使用 libCxxParser.so 的版本'''
    if isinstance(lines, list):
        li = eval(
            CxxParser.GetCharPStr(CxxParser.GetScopeStack('\n'.join(lines))))
    else:
        li = eval(CxxParser.GetCharPStr(CxxParser.GetScopeStack(lines)))
    #print li
    scopeStack = []
    for idx, rawScope in enumerate(li):
        if idx == 0:
            # 第一个 scope 直接用即可
            cxxnsinfo = rawScope["nsinfo"]
            tmpScope = CppScope()
            tmpScope.kind = "file"
            tmpScope.nsinfo.usingns = cxxnsinfo["usingns"]
            tmpScope.nsinfo.using = cxxnsinfo["using"]
            tmpScope.nsinfo.nsalias = cxxnsinfo["nsalias"]
            tmpScope.vars = rawScope["vars"]
            tmpScope.cusrstmt = rawScope["cusrstmt"] # added on 2012-07-04
            scopeStack.append(tmpScope)
            continue
        #print rawScope["stmt"]
        scopes = ParseScopes(rawScope["stmt"])
        if scopes:
            cxxnsinfo = rawScope["nsinfo"]
            scopes[-1].nsinfo.usingns = cxxnsinfo["usingns"]
            scopes[-1].nsinfo.using = cxxnsinfo["using"]
            scopes[-1].nsinfo.nsalias = cxxnsinfo["nsalias"]
            scopes[-1].vars = rawScope["vars"]
            scopes[-1].cusrstmt = rawScope["cusrstmt"] # added on 2012-07-04
        scopeStack.extend(scopes)
    #print '=' * 20, 'scope stack'
    #PrintList(scopeStack)
    return scopeStack

def PrintList(li):
    for i in li:
        print i

# 使用 libCxxParser
GetScopeStack = CxxGetScopeStack
# 使用 python 原生的
#GetScopeStack = PyGetScopeStack

def main():
    import time
    #print '=' * 20
    #test_ParseVariableType()
    #print '=' * 20
    #test_ParseScopes()

    if not sys.argv[1:]:
        print "usage: %s {file} [line]" % sys.argv[0]
        sys.exit(1)

    line = 1000000
    if sys.argv[1:]:
        fn = sys.argv[1]
        if sys.argv[2:]:
            line = int(sys.argv[2])

    f = open(fn)
    allLines = f.readlines()
    f.close()
    lines = allLines[: line]
    t1 = time.time()
    print "PyGetScopeStack()"
    print eval(repr(PyGetScopeStack(lines)))
    t2 = time.time(); print "consume time:", t2 - t1
    t1 = time.time()
    print "CxxGetScopeStack()"
    print eval(repr(CxxGetScopeStack(lines)))
    t2 = time.time(); print "consume time:", t2 - t1
    t1 = time.time()
    print "GetScopeStack"
    print eval(repr(GetScopeStack(lines)))
    t2 = time.time(); print "consume time:", t2 - t1

if __name__ == '__main__':
    main()
