#!/usr/bin/env python
# -*- encoding:utf-8 -*-

import os
import timeit

if __name__ == '__main__':
    def QuickTest(expression):
        tmpExp = ''
        i = 0
        while i < len(expression):
            c = expression[i]
            if c == '`':
                backtick = ''
                found = False
                i += 1
                while i < len(expression):
                    if expression[i] == '`':
                        found = True
                        break
                    backtick += expression[i]
                    i += 1

                if not found:
                    print 'Syntax error in expression: ' + expression \
                            + ': expecting \'`\''
                    return expression
                else:
                    expandedBacktick = backtick

                    output = os.popen(expandedBacktick).read()
                    tmp = ' '.join([x for x in output.split('\n') if x])
                    tmpExp += tmp
            else:
                tmpExp += c
            i += 1

        return tmpExp

#    print QuickTest('`pwd`, `echo "hello"`, `ls`')
    #print QuickTest('ff;wenngegneg')


    #s = 'hello'
    #def say():
        #print s
    #say()
