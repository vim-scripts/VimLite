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

"""Low level module providing async_chat process communication and the use of
pipes for communicating with the forked process.

This module is used by the 'posix' and 'nt' module to provide the asyncore
event loop functionality for process communication.

"""

import os
import os.path
import time
import threading
import socket
import select
import errno
import asynchat
import subprocess
if os.name == 'posix':
    import fcntl

import clewn.misc as misc

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('proc')
Unused = warning
Unused = debug

# Peek thread states
STS_STARTED, STS_STOPPED = range(2)

class FileWrapper(object):
    """Emulate a socket with a file descriptor or file object.

    Here we override just enough to make a file look like a socket for the
    purposes of asyncore.

    Instance attributes:
        fd: int
            file descriptor
        fobj: file
            file object instance

    """

    def __init__(self, f):
        """Constructor."""
        self.fobj = None
        if isinstance(f, file):
            self.fobj = f
            self.fd = f.fileno()
        else:
            self.fd = f
        self.connected = True

    def recv(self, *args):
        """Receive data from the file."""
        return os.read(self.fd, *args)

    def send(self, *args):
        """Send data to the file."""
        return os.write(self.fd, *args)

    read = recv
    write = send

    def close(self):
        """Close the file."""
        if self.connected:
            self.connected = False
            if self.fobj is not None:
                self.fobj.close()
            else:
                os.close(self.fd)

    def fileno(self):
        """Return the file descriptor."""
        return self.fd

class FileAsynchat(asynchat.async_chat):
    """Instances of FileAsynchat are added to the asyncore socket_map.

    A FileAsynchat instance is a ProcessChannel helper, and a wrapper
    for a pipe or a pty.  When it is a pipe, it may be readable or writable.
    When it is a pseudo tty it is both.

    Instance attributes:
        f: int or file
            file descriptor or file object
        channel: ProcessChannel
            the cooperating ProcessChannel instance
        reader: True, False or None
            None: readable and writable (pty)
            True: readable
            False: writable
        ibuff: list
            list of strings read from the pipe or pty

    """

    def __init__(self, f, channel, reader=None):
        """Constructor."""
        asynchat.async_chat.__init__(self)
        self.channel = channel
        self.reader = reader
        self.connected = True
        self.ibuff = []
        if os.name == 'nt':
            self.set_terminator('\r\n')
        else:
            self.set_terminator('\n')

        if isinstance(f, file):
            self._fileno = f.fileno()
        else:
            self._fileno = f
        self.set_file(f)

        # set it to non-blocking mode
        if os.name == 'posix':
            flags = fcntl.fcntl(self._fileno, fcntl.F_GETFL, 0)
            flags = flags | os.O_NONBLOCK
            fcntl.fcntl(self._fileno, fcntl.F_SETFL, flags)

    def set_file(self, f):
        """Set the file descriptor."""
        self.socket = FileWrapper(f)
        self.add_channel()

    def recv(self, buffer_size):
        """Receive data from the file."""
        try:
            return asynchat.async_chat.recv(self, buffer_size)
        except OSError:
            self.close()
            return ''

    def send(self, data):
        """Send data to the file."""
        try:
            return asynchat.async_chat.send(self, data)
        except OSError:
            self.close()
            return 0

    def handle_error(self):
        """Process an error."""
        unused = self
        raise

    def handle_expt(self):
        """Process a select exception."""
        unused = self
        assert False, 'unhandled exception'

    def handle_connect(self):
        """Process a connect event."""
        unused = self
        assert False, 'unhandled connect event'

    def handle_accept(self):
        """Process an accept event."""
        unused = self
        assert False, 'unhandled accept event'

    def handle_close(self):
        """Process a close event."""
        self.close()

    def readable(self):
        """Is the file readable."""
        if self.reader is False:
            return False
        return asynchat.async_chat.readable(self)

    def writable(self):
        """Is the file writable."""
        if self.reader is True:
            return False
        return asynchat.async_chat.writable(self)

    def collect_incoming_data(self, data):
        """Called with data holding an arbitrary amount of received data."""
        self.ibuff.append(data)

    def found_terminator(self):
        """Have the ProcessChannel instance process the received data."""
        msg = "".join(self.ibuff)
        self.ibuff = []
        self.channel.handle_line(msg)

class ProcessChannel(object):
    """An abstract class to run a command with a process through async_chat.

    To implement a concrete subclass of ProcessChannel, one must implement
    the handle_line method that process the lines (new line terminated)
    received from the program stdout and stderr.

    Instance attributes:
        argv: tuple or list
            argv arguments
        pgm_name: str
            process name
        fileasync: tuple
            the readable and writable instances of FileAsynchat helpers
        pid: int
            spawned process pid
        ttyname: str
            pseudo tty name

    """

    def __init__(self, argv):
        """Constructor."""
        assert argv
        self.argv = argv
        self.pgm_name = os.path.basename(self.argv[0])
        self.fileasync = None
        self.pid = 0
        self.ttyname = None

    def popen(self):
        """Spawn a process using pipes."""
        proc = subprocess.Popen(self.argv,
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            close_fds=(os.name != 'nt'))
        self.fileasync = (FileAsynchat(proc.stdout, self, True),
                            FileAsynchat(proc.stdin, self, False))
        self.pid = proc.pid
        info('starting "%s" with two pipes', self.pgm_name)

    def start(self):
        """Spawn the process and connect its stdio to our fileasync tuple."""
        try:
            self.popen()
        except OSError:
            critical('cannot start process "%s"', self.pgm_name); raise
        info('program argv list: %s', str(self.argv))

    def close(self):
        """Close the channel an wait on the process."""
        if self.fileasync is not None:
            # it is safe to close the same FileAsynchat twice
            self.fileasync[0].close()
            self.fileasync[1].close()
            self.fileasync = None

    def sendintr(self):
        """Cannot send an interrupt to the program."""
        pass

    def handle_line(self, line):
        """Process the line received from the program stdout and stderr."""
        unused = line
        if self.fileasync is not None:
            raise NotImplementedError('handle_line in ProcessChannel')

    def write(self, data):
        """Write a chunk of data to the process stdin."""
        if self.fileasync is not None:
            if not data.endswith('\n'):
                data += '\n'
            self.fileasync[1].push(data)

class Peek(threading.Thread):
    """A generic peek thread as an abstract class.

    Class attribute:
        select_event: Event
            The Event object that the clewn_select emulation is waiting on.

    """

    select_event = threading.Event()

    def __init__(self, name):
        """Constructor."""
        threading.Thread.__init__(self, name=name)
        self.state = STS_STOPPED
        self.start_peeking = threading.Event()
        self.stop_peeking = threading.Event()
        self.have_started = threading.Event()
        self.have_stopped = threading.Event()

    def run(self):
        """The thread peeks the file object(s).

        The thread is notified by an event of the transition to perform:
            start_peeking
            stop_peeking
        The thread sends a select_event to clewn_select when a read,
        write or except event is available.
        The thread reports its state with a have_started or have_stopped event.

        """
        info('thread started: %s', self)
        while self.isRunning():
            self.wait_event('start_peeking')
            self.have_started.set()

            while self.isRunning():
                if self.peek():
                    self.select_event.set()
                    self.wait_event('stop_peeking')
                    break
                else:
                    if self.stop_peeking.isSet():
                        self.stop_peeking.clear()
                        break
                time.sleep(.001) # allow a thread context switch
            self.have_stopped.set()

        # logger may be closed when terminating pyclewn
        if not isinstance(self, SelectPeek):
            info('thread terminated: %s', self)

    def peek(self):
        """Peek the file object for one or more events.

        Return True when an event is available, False otherwise.

        """
        unused = self
        assert False, 'missing implementation of the peek method'

    def isRunning(self):
        """Return the thread status."""
        unused = self
        assert False, 'missing implementation of the isRunning method'

    def wait_event(self, event_name):
        """Block forever waiting on 'event_name'."""
        event = getattr(self, event_name)
        while self.isRunning() and not event.isSet():
            event.wait(.010)
        event.clear()

    def start_thread(self):
        """Called by clewn_select to start the thread."""
        if self.isAlive():
            # debug('ask the thread to start: %s', self)
            self.start_peeking.set()

            # debug('wait until thread have_started: %s', self)
            self.wait_event('have_started')

            # debug('the thread is now started: %s', self)
            self.state = STS_STARTED

    def stop_thread(self):
        """Called by clewn_select to stop the thread."""
        if self.state != STS_STARTED:
            return
        if self.isAlive():
            # debug('ask the thread to stop: %s', self)
            self.stop_peeking.set()

            # debug('wait until thread have_stopped: %s', self)
            self.wait_event('have_stopped')

            # debug('the thread is now stopped: %s', self)
            self.state = STS_STOPPED

class SelectPeek(Peek):
    """The select peek thread.

    The thread peeks on all waitable sockets set in clewn_select.

    """
    def __init__(self, fdmap):
        """Constructor."""
        Peek.__init__(self, 'socketThread')
        self.fdmap = fdmap
        self.iwtd = []
        self.owtd = []
        self.ewtd = []
        self.iwtd_out = []
        self.owtd_out = []
        self.ewtd_out = []

    def set_waitable(self, iwtd, owtd, ewtd):
        """Set each waitable file descriptor list."""
        self.iwtd = iwtd
        self.owtd = owtd
        self.ewtd = ewtd
        self.iwtd_out = []
        self.owtd_out = []
        self.ewtd_out = []

    def peek(self):
        """Run select on all sockets."""
        assert self.iwtd or self.owtd or self.ewtd
        # debug('%s, %s, %s', self.iwtd, self.owtd, self.ewtd)
        try:
            iwtd, owtd, ewtd = select.select(self.iwtd, self.owtd, self.ewtd, 0)
        except select.error, err:
            if err[0] != errno.EINTR:
                error('failed select call: ', err); raise
            else:
                return False
        if iwtd or owtd or ewtd:
            (self.iwtd_out, self.owtd_out, self.ewtd_out) = (iwtd, owtd, ewtd)
            return True
        return False

    def isRunning(self):
        """Return the thread status."""
        return len(self.fdmap)

    def stop_thread(self):
        """Called by clewn_select to stop the select thread."""
        Peek.stop_thread(self)
        # debug('select return: %s, %s, %s',
        #           self.iwtd_out, self.owtd_out, self.ewtd_out)
        return self.iwtd_out, self.owtd_out, self.ewtd_out

class PipePeek(Peek):
    """The abstract pipe peek class."""

    def __init__(self, fd, asyncobj):
        """Constructor."""
        Peek.__init__(self, 'pipeThread')
        self.fd = fd
        self.asyncobj = asyncobj
        self.read_event = False

    def isRunning(self):
        """Return the thread status."""
        return self.asyncobj.socket.connected

    def start_thread(self):
        """Called by clewn_select to start the thread."""
        self.read_event = False
        Peek.start_thread(self)

