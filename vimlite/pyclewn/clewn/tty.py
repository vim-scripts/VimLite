# vi:set ts=8 sts=4 sw=4 et tw=80:
#
# Copyright (C) 2011 Xavier de Gaye.
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
"""Gdb inferior terminal.

"""

import os
import sys
import array
import errno
import pty
import signal
import fcntl
import asyncore
from termios import tcgetattr, tcsetattr, TCSADRAIN, TIOCGWINSZ, TIOCSWINSZ
from termios import error as termios_error
from termios import INLCR, ICRNL, IXON, IXOFF, IXANY,   \
        OPOST,                                          \
        ECHO, ECHONL, ICANON, ISIG, IEXTEN,             \
        VMIN, VTIME

import clewn.misc as misc

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('tty')
Unused = critical
Unused = warning
Unused = debug

# the command character: 'C-a'
CMD_CHAR = chr(1)

def close(fd):
    """Close the file descriptor."""
    if fd != -1:
        try:
            os.close(fd)
        except OSError:
            pass

pty_instance = None

def sigwinch_handler(*args):
    """Handle SIGWINCH."""
    unused = args
    if pty_instance and pty_instance.master_dsptch:
        pty_instance.master_dsptch.update_size()

class FileDispatcher(asyncore.file_dispatcher):
    """The FileDispatcher does input/output on a file descriptor.

    Read data into 'buf'.
    Write the content of the FileDispatcher 'source' buffer 'buf'.
    When 'enable_cmds' is True, handle the command character 'C-a'.
    """

    def __init__(self, fd, source=None, reader=True, enable_cmds=False):
        """Constructor."""
        asyncore.file_dispatcher.__init__(self, fd)
        self.source = source
        self.reader = reader
        self.enable_cmds = enable_cmds
        self.cmd_char_last = False
        self.close_tty = False
        self.buf = ''

    def readable(self):
        """A readable dispatcher."""
        return self.reader

    def writable(self):
        """A writable dispatcher."""
        return self.source and self.source.buf != ''

    def handle_read(self):
        """Process data available for reading."""
        try:
            data = self.socket.recv(1024)
        except OSError, err:
            if err[0] != errno.EAGAIN and err[0] != errno.EINTR:
                if self.source.close_tty and err[0] == errno.EIO:
                    raise asyncore.ExitNow("[slave pseudo terminal closed,"
                            " pseudo tty management is terminated]")
                raise asyncore.ExitNow(err)
        else:
            if self.enable_cmds:
                if self.cmd_char_last:
                    self.cmd_char_last = False
                    if data == 'q':
                        raise asyncore.ExitNow(
                                '\n[pseudo tty management is terminated]')
                    elif data == 'c':
                        self.close_tty = True
                        return
                    elif data == 'a':
                        self.buf += CMD_CHAR
                        return
                    else:
                        self.buf += CMD_CHAR + data
                        return
                elif data == CMD_CHAR:
                    self.cmd_char_last = True
                    return
            self.buf += data

    def handle_write(self):
        """Write the content of the 'source' buffer."""
        buf = self.source.buf
        try:
            count = os.write(self.socket.fd, buf)
        except OSError, err:
            if err[0] != errno.EAGAIN and err[0] != errno.EINTR:
                raise asyncore.ExitNow(err)
        else:
            self.source.buf = buf[count:]

    def close(self):
        """Close the dispatcher."""
        self.del_channel()

    def update_size(self):
        """Set the window size to match the size of its 'source'."""
        buf = array.array('h', [0, 0, 0, 0])
        try:
            ret = fcntl.ioctl(self.source.socket.fd, TIOCGWINSZ, buf, 1)
            if ret == 0:
                fcntl.ioctl(self.socket.fd, TIOCSWINSZ, buf, 1)
            else:
                error('failed ioctl: %d', ret)
        except IOError, err:
            error('failed ioctl: %s', err)

class GdbInferiorPty(object):
    """Gdb inferior terminal."""

    def __init__(self, stderr_hdlr=None):
        """Constructor."""
        self.stderr_hdlr = stderr_hdlr
        self.master_fd = -1
        self.slave_fd = -1
        self.ptyname = ''
        self.stdin_dsptch = None
        self.master_dsptch = None
        self.orig_attr = None
        global pty_instance
        pty_instance = self

    def start(self):
        """Start the pty."""
        self.interconnect_pty()
        # postpone stderr logging while terminal is in raw mode
        if self.stderr_hdlr:
            self.stderr_hdlr.should_flush(False)
        self.stty_raw()

    def interconnect_pty(self, enable_cmds=False):
        """Interconnect pty with our terminal."""
        self.master_fd, self.slave_fd = pty.openpty()
        self.ptyname = os.ttyname(self.slave_fd)
        info('creating gdb inferior pseudo tty \'%s\'', self.ptyname)
        self.stdin_dsptch = FileDispatcher(sys.stdin.fileno(),
                                                enable_cmds=enable_cmds)
        self.master_dsptch = FileDispatcher(self.master_fd,
                                                source=self.stdin_dsptch)
        FileDispatcher(sys.stdout.fileno(), source=self.master_dsptch,
                                                reader=False)

        # update pseudo terminal size
        self.master_dsptch.update_size()
        signal.signal(signal.SIGWINCH, sigwinch_handler)

    def stty_raw(self):
        """Set raw mode."""
        stdin_fd = sys.stdin.fileno()
        self.orig_attr = tcgetattr(stdin_fd)
        # use termio from the new tty and tailor it
        attr = tcgetattr(self.slave_fd)
        attr[0] &= ~(INLCR | ICRNL | IXON | IXOFF | IXANY)
        attr[1] &= ~OPOST
        attr[3] &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN)
        attr[6][VMIN] = 1
        attr[6][VTIME] = 0
        tcsetattr(stdin_fd, TCSADRAIN, attr)

    def close(self):
        """Restore tty attributes and close pty."""
        global pty_instance
        pty_instance = None
        if self.orig_attr:
            try:
                tcsetattr(sys.stdin.fileno(), TCSADRAIN, self.orig_attr)
            except termios_error, err:
                error(err)
        close(self.master_fd)
        close(self.slave_fd)
        if self.stderr_hdlr:
            self.stderr_hdlr.should_flush(True)

