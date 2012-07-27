#!/usr/bin/env python
# -*- coding:utf-8 -*-


class FileReader:
    def __init__(self, fileName):
        '''fileName 为字符串或可双重迭代的对象'''
        self.file = None
        self.lineIter = None
        self.currLine = None
        self.charIter = None

        self.lineNum = 0 # 行号，从 1 开始，0 表示非法
        self.colNum = 0 # 列号，从 1 开始，0 表示非法，这个比较麻烦，暂不实现

        self.lineNumOff = 0 # unget buffer 对于行号的偏移
        self.willAddLineOff = False # 下一次要对 lineNumOff 加一，
                                    # GetChar() 遇到 '\n' 是这个变量就为 True

        self.ungetBuf = [] # 反推回来的字符缓冲

        if isinstance(fileName, str):
            self.file = open(fileName)
        else:
            self.file = fileName

        self.lineIter = iter(self.file)

    def __del__(self):
        if isinstance(self.file, file):
            self.file.close()

    def GetLineNum(self):
        return self.lineNum + self.lineNumOff

    def GetLine(self):
        line = self.__GetLine()
        if line is None:
            return None
        self.lineNum += 1
        # 统一换行符为 unix 风格
        if line.endswith('\r'): # mac
            return line.rstrip('\r') + '\n'
        elif line.endswith('\r\n'): # win
            return line.rstrip('\r\n') + '\n'
        elif line.endswith('\n'):
            return line
        else:
            return line + '\n'

    def GetChar(self):
        '''若到文件尾，返回 None
        与 __GetChar() 的差别在于，这里处理反推缓冲和要实时更新列号'''
        if self.ungetBuf: # 先使用反推的字符缓冲
            c = self.ungetBuf.pop(-1)
            if self.willAddLineOff:
                self.lineNumOff += 1
            if c == '\n':
                self.willAddLineOff = True
            else:
                self.willAddLineOff = False
            return c

        return self.__GetChar()

    def PeekChar(self):
        c = self.GetChar()
        self.UngetChar(c)
        return c

    def UngetChar(self, c):
        '''要处理行号和列号，不要反推 "\r"'''
        if c == '\n' and self.ungetBuf: # 很诡异
            self.lineNumOff -= 1
        self.willAddLineOff = False
        self.__UngetChar(c)

    # ==========================================================================
    # private
    # ==========================================================================
    def __GetLine(self):
        '''若到文件尾，返回 None'''
        try:
            return self.lineIter.next()
        except StopIteration:
            return None

    def __GetChar(self):
        '''内部的 raw 方法'''
        if self.currLine is None:
            self.currLine = self.GetLine()
            if self.currLine is None:
                # 到文件尾部了
                return None
            # 更新 charIter 以便继续
            self.charIter = iter(self.currLine)

        try:
            return self.charIter.next()
        except StopIteration:
            self.currLine = None
            return self.GetChar()

    def __UngetChar(self, c):
        self.ungetBuf.append(c)


def test():
    import sys
    fileName = sys.argv[0]

    fileName = ['abc', '', '', 'end']

    cnt = 100

    fr = FileReader(fileName)
    li = []
    for i in range(cnt):
        c = fr.GetChar()
        if c is None: break
        li.append(c)
        sys.stdout.write(c)
    print ''
    print 'line: %d' % fr.GetLineNum()

    for c in li[::-1]:
        fr.UngetChar(c)
    print 'line: %d' % fr.GetLineNum()

    for i in range(cnt):
        c = fr.GetChar()
        if c is None: break
        li.append(c)
        sys.stdout.write(c)
    print ''
    print 'line: %d' % fr.GetLineNum()
    for i in range(cnt):
        c = fr.GetChar()
        if c is None: break
        li.append(c)
        sys.stdout.write(c)
    print ''
    print 'line: %d' % fr.GetLineNum()

    return

    fr = FileReader(fileName)
    line = fr.GetLine()
    while line:
        sys.stdout.write(line)
        line = fr.GetLine()
    print '=' * 40
    fr = FileReader(sys.argv[0])
    char = fr.GetChar()
    while char:
        sys.stdout.write(char)
        char = fr.GetChar()

if __name__ == '__main__':
    #test()
    pass
