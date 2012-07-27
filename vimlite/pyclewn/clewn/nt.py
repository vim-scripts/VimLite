# vi:set ts=8 sts=4 sw=4 et tw=80:
#
# Copyright (C) 2007 Xavier de Gaye.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
#

"""Pyclewn windows miscellaneous classes and functions."""

import os
import sys
import platform
assert os.name == 'nt'

import msvcrt
import win32pipe
import win32con
import win32gui
import win32console

import clewn.asyncproc as asyncproc
import clewn.misc as misc

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('nt')
Unused = error
Unused = warning
Unused = info
Unused = debug

def platform_data():
    """Return Windows platform information."""
    return ('platform: %s\nWindows version: %s'
                    % (platform.platform(), sys.getwindowsversion()))

class PipePeek(asyncproc.PipePeek):
    """The pipe peek thread."""

    def __init__(self, fd, asyncobj):
        """Constructor."""
        asyncproc.PipePeek.__init__(self, fd, asyncobj)
        try:
            self.handle = msvcrt.get_osfhandle(fd)
        except IOError:
            critical('cannot get a Windows handle'); raise

    def peek(self):
        """Peek the pipe."""
        try:
            (buf, avail, remain) = win32pipe.PeekNamedPipe(self.handle, 0)
        except Exception, why:
            # this may occur on exit
            debug('got Exception %s', why)
            info('closing debugger after failed PeekNamedPipe syscall')
            # the main thread is busy waiting on the select_event in the
            # asyncore poll loop, so it's ok to close the debugger in
            # this thread
            self.asyncobj.channel.close()
            return False
        unused = buf
        unused = remain
        if avail > 0:
            self.read_event = True
            return True
        return False

def hide_console():
    """Hide the pyclewn console window."""
    hwnd = win32console.GetConsoleWindow()
    if hwnd:
        debug('hiding window %d => %s', hwnd, win32gui.GetWindowText(hwnd))
        win32gui.ShowWindow(hwnd, win32con.SW_HIDE)
