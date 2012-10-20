#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import subprocess

def main():
    if len(sys.argv) <= 1:
        ret = 0
    else:
        ret = subprocess.call(sys.argv[1:])
    raw_input('Press ENTER to continue...\n')
    return ret

if __name__ == '__main__':
    ret = main()
    sys.exit(ret)
