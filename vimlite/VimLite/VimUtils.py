#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''一些在 vim 中使用的公共例程'''

import json

def ToVimEval(o):
    '''把 python 字符串列表和字典转为健全的能被 vim 解析的数据结构'''
    if isinstance(o, str):
        return "'%s'" % o.replace("'", "''")
    elif isinstance(o, (list, dict)):
        return json.dumps(o, ensure_ascii=False)
    else:
        return repr(o)


def test():
    pass

if __name__ == '__main__':
    test()
