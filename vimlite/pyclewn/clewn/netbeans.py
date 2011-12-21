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
"""The netbeans protocol implementation."""

import sys
import time
import os.path
import logging
import re
import socket
import asyncore
import asynchat
import difflib

from clewn import *
import clewn.misc as misc
import clewn.buffer as vimbuffer

NETBEANS_VERSION = '2.3'
CONSOLE = '(clewn)_console'
CONSOLE_MAXLINES = 10000
VARIABLES_BUFFER = '(clewn)_dbgvar'

RE_AUTH = r'^\s*AUTH\s*(?P<passwd>\S+)\s*$'                     \
          r'# RE: password authentication'
RE_RESPONSE = r'^\s*(?P<seqno>\d+)\s*(?P<args>.*)\s*$'          \
              r'# RE: a netbeans response'
RE_EVENT = r'^\s*(?P<buf_id>\d+):(?P<event>\S+)=(?P<seqno>\d+)' \
           r'\s*(?P<args>.*)\s*$'                               \
           r'# RE: a netbeans event message'
RE_LNUMCOL = r'^(?P<lnum>\d+)/(?P<col>\d+)'                     \
             r'# RE: lnum/col'

# compile regexps
re_auth = re.compile(RE_AUTH, re.VERBOSE)
re_response = re.compile(RE_RESPONSE, re.VERBOSE)
re_event = re.compile(RE_EVENT, re.VERBOSE)
re_lnumcol = re.compile(RE_LNUMCOL, re.VERBOSE)

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('nb')
logger = logging.getLogger('nb')
def debug(msg, *args, **kwargs):
    """Force NBDEBUG log level for debug messages."""
    logger.log(misc.NBDEBUG, msg, *args, **kwargs)

def evt_ignore(buf_id, msg, arg_list):
    """Ignore not implemented received events."""
    pass

def parse_msg(msg):
    """Parse a received netbeans message.

    Return the (None,) tuple or the tuple:
        is_event: boolean
            True: an event - False: a reply
        buf_id: int
            netbeans buffer number
        event: str
            event name
        seqno: int
            netbeans sequence number
        nbstring: str
            the netbeans string
        arg_list: list
            list of remaining args after the netbeans string

    """
    matchobj = re_event.match(msg)
    if matchobj:
        # an event
        bufid_name = matchobj.group('buf_id')
        event = matchobj.group('event')
    else:
        # a reply
        bufid_name = '0'
        event = ''
        matchobj = re_response.match(msg)
    if not matchobj:
        error('discarding invalid netbeans message: "%s"', msg)
        return (None,)

    seqno = matchobj.group('seqno')
    args = matchobj.group('args').strip()
    try:
        buf_id = int(bufid_name)
        seqno = int(seqno)
    except ValueError:
        assert False, 'error in regexp'

    # a netbeans string
    nbstring = ''
    if args and args[0] == misc.DOUBLEQUOTE:
        end = args.rfind(misc.DOUBLEQUOTE)
        if end != -1 and end != 0:
            nbstring = args[1:end]
            nbstring = misc.unquote(nbstring)
        else:
            end = -1
    else:
        end = -1
    arg_list = args[end+1:].split()

    return (matchobj.re is re_event), buf_id, event, seqno, nbstring, arg_list

def full_pathname(name):
    """Return the full pathname or None if name is a clewn buffer name."""
    if vimbuffer.is_clewnbuf(name):
        name = None
    elif not os.path.isabs(name):
        name = os.path.abspath(name)
    return name

class LineCluster(object):
    """Group lines in a bounded list of elements of a maximum size.

    Instance attributes:
        nb_element: int
            maximum number of elements
        nb_lines: int
            maximum number of lines per element
        last_element: list
            the last element in the cluster
            each element is a list of [lines_count, bytes_count]
        cluster: list
            the list of elements

    """

    def __init__(self, nb_element, nb_lines):
        """Constructor."""
        self.nb_element = nb_element
        self.nb_lines = nb_lines
        self.last_element = [0, 0]
        self.cluster = [self.last_element]

    def append(self, msg):
        """Add 'msg' number of lines and bytes count to the last element.

        When the list of elements has reached its maximum size and the last
        element is full, the first element in the list is deleted and the number
        of bytes in this first element is returned.

        """
        self.last_element[0] += msg.count('\n')
        self.last_element[1] += len(msg)
        #print 'line_cluster: %d elements, lines/bytes %s, last_element %s' % (
        #            len(self.cluster),
        #            reduce(lambda x, y: [x[0]+y[0], x[1]+y[1]], self.cluster),
        #            self.last_element)
        if msg.endswith('\n') and self.last_element[0] >= self.nb_lines:
            self.last_element = [0, 0]
            self.cluster.append(self.last_element)
            if len(self.cluster) > self.nb_element:
                info('line_cluster: clearing %d lines', self.cluster[0][0])
                return self.cluster.pop(0)[1]
        return 0

class ClewnBuffer(object):
    """A ClewnBuffer instance is an edit port in Vim.

    Instance attributes:
        buf: Buffer
            the Buffer instance
        nbsock: netbeans.Netbeans
            the netbeans asynchat socket
        visible: boolean
            when True, the buffer is displayed in a Vim window
        editing: boolean
            when True, the buffer is being edited with netbeans
            'insert' or 'remove' functions
        nonempty_last: boolean
            when True, the last line in the vim buffer is non empty
        len: int
            buffer length
        dirty: boolean
            when True, must update the vim buffer
        getLength_count: int
            count of netbeans 'getLength' functions without a reply

    """

    def __init__(self, name, nbsock):
        """Constructor."""
        assert vimbuffer.is_clewnbuf(name)
        self.buf = nbsock._bset[name]
        self.buf.registered = False
        self.buf.editport = self
        self.nbsock = nbsock
        self.visible = False
        self.editing = False
        self.nonempty_last = False
        self.len = 0
        self.dirty = False
        self.getLength_count = 0

    def register(self):
        """Register the buffer with netbeans vim."""
        self.nbsock.send_cmd(self.buf, 'editFile', misc.quote(self.buf.name))
        self.nbsock.send_cmd(self.buf, 'setReadOnly', 'T')
        self.buf.registered = True

    def send_function(self, function, args):
        """Send a netbeans function."""
        nbsock = self.nbsock
        if not self.editing and function in ('insert', 'remove'):
            nbsock.send_cmd(None, 'startAtomic')
            nbsock.send_cmd(self.buf, 'setReadOnly', 'F')
            self.editing = True
        nbsock.send_function(self.buf, function, args)

    def setdot(self, offset=None, lnum=None):
        """Set the cursor at the requested position.

        Do not set the cursor when the 'window' command line option is 'none',
        unless there is no netbeans buffer opened yet (the console is the
        only buffer).
        """
        if ((self.nbsock.enable_setdot or not self.nbsock._bset)
                                                    and self.visible):
            if offset is not None:
                self.nbsock.send_cmd(self.buf, 'setDot', str(offset))
            else:
                self.nbsock.send_cmd(self.buf, 'setDot', '%d/0' % lnum)

    def terminate_editing(self):
        """Terminate editing a ClewnBuffer."""
        if self.editing:
            nbsock = self.nbsock
            nbsock.send_cmd(self.buf, 'setReadOnly', 'T')
            nbsock.goto_last()
            nbsock.send_cmd(None, 'endAtomic')
            self.editing = False

    def append(self, msg, *args):
        """Append text to the end of the editport."""
        if not self.buf.registered:
            return
        if self.nonempty_last:
            self.nonempty_last = False
            self.len -= 1
        if args:
            msg = msg % args
        self.send_function('insert', '%s %s' % (str(self.len), misc.quote(msg)))

        if not msg.endswith('\n'):
            self.nonempty_last = True
            self.len += 1
        self.len += len(msg)

        # show the last line if the buffer is displayed in a Vim window
        self.setdot(offset=(self.len - 1))
        self.terminate_editing()

    def update(self, content):
        """Update the buffer content in Vim."""
        unused = content
        self.dirty = False

    def remove(self, offset, count):
        """Remove 'count' bytes at 'offset'.

        Vim 7.1 remove implementation is buggy and cannot remove a single or
        partial line. In this case we insert first an empty line and remove all
        lines in one shot (NOTE that this implies this method MUST NOT be
        called when removing partial lines with a buggy vim 7.1).
        It is Ok with a more recent vim version.

        """
        send_function = self.send_function
        if self.nbsock.remove_fix == '0':
            send_function('insert', '%s %s' % (str(offset), misc.quote('\n')))
            send_function('remove', '%s %s' % (str(offset), str(count + 1)))
        else:
            send_function('remove', '%s %s' % (str(offset), str(count)))

    def clear(self, count=-1):
        """Clear the ClewnBuffer instance.

        When 'count' is -1, clear the whole buffer.
        Otherwise, delete the first 'count' bytes and set the cursor
        at the end of the buffer.

        """
        if not self.buf.registered:
            self.visible = False
        if count == -1:
            count = self.len
        assert 0 <= count <= self.len
        if count:
            if self.buf.registered:
                self.remove(0, count)
            self.len -= count
            if self.len == 0:
                self.nonempty_last = False
            else:
                self.setdot(offset=(self.len - 1))
            self.terminate_editing()
            info('%s length: %d bytes', self.buf.name, self.len)

class Console(ClewnBuffer):
    """The clewn console.

    Instance attributes:
        line_cluster: LineCluster
            the object handling the Console maximum number of lines
        buffer: str
            the buffered console output
        time: float
            last time data was added to the buffer
        timeout_str: str
            a string that is conditionaly written to the console
        timed-out: boolean
            True when the 'timeout_str' has been written to the console

    """

    def __init__(self, nbsock):
        """Constructor."""
        ClewnBuffer.__init__(self, CONSOLE, nbsock)
        self.visible = True
        self.line_cluster = LineCluster(10, self.nbsock.max_lines / 10)
        self.buffer = ''
        self.time = time.time()
        self.count = 0
        self.timeout_str = ''
        self.timed_out = False

    def timeout_append(self, msg):
        """Add string to the buffer after a timeout."""
        self.timeout_str += msg
        self.timed_out = False
        self.time = time.time()

    def append(self, msg, *args):
        """Add a formatted string to the buffer."""
        # discard when something else is written before the timeout
        self.timeout_str = ''
        self.timed_out = False

        if args:
            msg = msg % args
        self.count += self.line_cluster.append(msg)
        self.buffer += msg
        self.time = time.time()

    def flush(self, now=None):
        """Flush the buffer to Vim.

        When 'now' is None, flush the buffer unconditionally, otherwise flush it
        after a timeout.

        """
        if ((self.buffer or self.timeout_str)
                    and (now is None or now - self.time > 0.500)):
            # write after a timeout
            if now is not None and self.timeout_str:
                self.append(self.timeout_str)
                self.timed_out = True
            self.timeout_str = ''

            ClewnBuffer.append(self, self.buffer)
            self.buffer = ''
            if self.count:
                self.clear(self.count)
                self.count = 0

class DebuggerVarBuffer(ClewnBuffer):
    """The debugger variable buffer.

    Instance attributes:
        linelist: list
            the vim buffer content as a sequence of newline terminated strings
        differ: difflib.Differ
            a differ object to compare two sequences of lines

    """

    def __init__(self, nbsock):
        """Constructor."""
        ClewnBuffer.__init__(self, VARIABLES_BUFFER, nbsock)
        self.linelist = []
        self.differ = difflib.Differ()

    def append(self, msg, *args):
        """Append 'msg' to the end of the buffer."""
        if args:
            msg = msg % args
        assert msg.endswith('\n')
        ClewnBuffer.append(self, msg)
        self.linelist.extend(msg.splitlines(1))

    def clear(self, len=-1):
        """Clear the buffer."""
        ClewnBuffer.clear(self, len)
        self.linelist = []

    def update(self, content):
        """Update the vim buffer with the new content."""
        self.dirty = False
        if not self.buf.registered:
            return

        offset = 0
        newlist = content.splitlines(1)
        send_function = self.send_function
        try:
            for line in self.differ.compare(self.linelist, newlist):
                assert len(line) > 2

                if line.startswith('  '):
                    offset += len(line) - 2
                elif line.startswith('+ '):
                    delta = len(line) - 2
                    send_function('insert',
                            '%s %s' % (str(offset), misc.quote(line[2:])))
                    self.len += delta
                    offset += delta
                elif line.startswith('- '):
                    delta = len(line) - 2
                    self.remove(offset, delta)
                    self.len -= delta
                elif line.startswith('? '):
                    pass    # skip line not present in either input sequence
                else:
                    assert False, "line not prefixed by the differ instance"
        finally:
            self.terminate_editing()

        self.linelist = newlist

class Reply(object):
    """Abstract class. A Reply instance is a callable used to process
    the result of a  function call in the reply received from netbeans.

    Instance attributes:
        buf: Buffer
            the buffer in use when the function is invoked
        seqno: int
            netbeans sequence number
        nbsock: netbeans.Netbeans
            the netbeans asynchat socket
    """

    def __init__(self, buf, seqno, nbsock):
        """Constructor."""
        self.buf = buf
        self.seqno = seqno
        self.nbsock = nbsock

    def clear_onerror(self, err):
        """Clear the clewn buffer on error in the reply."""
        clewnbuffer = self.buf.editport
        assert clewnbuffer is not None
        clewnbuffer.dirty = True
        clewnbuffer.clear()
        err += '\nThe buffer will be restored on the next gdb command.'
        self.nbsock.show_balloon(err)
        error(err)

    def __call__(self, seqno, nbstring, arg_list):
        """Process the netbeans reply."""
        unused = self
        unused = seqno
        unused = nbstring
        unused = arg_list
        raise NotImplementedError('must be implemented in subclass')

class insertReply(Reply):
    """Check the reply to an insert function."""

    def __call__(self, seqno, nbstring, arg_list):
        """Check the reply to an insert or remove netbeans function."""
        unused = nbstring
        if seqno != self.seqno:
             error('%s: invalid sequence number on edit', self.buf.name)
             return
        if len(arg_list):
            err = '%s: got edit error from netbeans: %s' %      \
                            (self.buf.name, ' '.join(arg_list))
            self.nbsock.send_function(self.buf, 'getLength')
            self.clear_onerror(err)

# Check the reply to a remove function.
removeReply = insertReply

class getLengthReply(Reply):
    """Check the reply to a getLength function."""

    def __init__(self, buf, seqno, nbsock):
        """Constructor."""
        Reply.__init__(self, buf, seqno, nbsock)
        clewnbuffer = buf.editport
        assert clewnbuffer is not None
        clewnbuffer.getLength_count += 1

    def __call__(self, seqno, nbstring, arg_list):
        """Check the length of the Vim buffer."""
        unused = nbstring
        if seqno != self.seqno:
            error('%s: invalid sequence number on getLength', self.buf.name)
            return
        clewnbuffer = self.buf.editport
        assert clewnbuffer is not None
        assert len(arg_list) == 1
        length = int(arg_list[0])
        clewnbuffer.getLength_count -= 1
        if clewnbuffer.len != length:
            err= ('%s: invalid buffer length (pyclewn:%d - vim: %d)'
                        % (self.buf.name, clewnbuffer.len, length))
            if clewnbuffer.getLength_count == 0:
                clewnbuffer.len = length
                self.clear_onerror(err)
            else:
                debug('ignoring: %s', err)

class Server(asyncore.dispatcher):
    """Accept a connection on the netbeans port

    Instance attributes:
        oneshot: boolean
            accept a single connection
        netbeans: Netbeans
            the netbeans data socket
        passwd: string
            the connection password
    """

    def __init__(self):
        """Constructor."""
        asyncore.dispatcher.__init__(self)
        self.oneshot = False
        self.netbeans = None
        self.passwd = ''
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)

    def handle_error(self):
        """Raise the exception."""
        unused = self
        raise

    def handle_expt(self):
        """We are not listening on exceptional conditions."""
        unused = self
        assert False, 'unhandled exceptional condition'

    def handle_read(self):
        """Not implemented."""
        unused = self
        assert False, 'unhandled read event in server'

    def handle_write(self):
        """Not implemented."""
        unused = self
        assert False, 'unhandled write event in server'

    def handle_connect(self):
        """Not implemented."""
        unused = self
        assert False, 'unhandled connect event in server'

    def bind_listen(self, oneshot, host, port, passwd):
        """Listen on the netbeans port."""
        self.oneshot = oneshot
        self.passwd = passwd
        try:
            port = int(port)
        except ValueError:
            critical('"%s" is not a port number', port); raise
        try:
            self.set_reuse_addr()
            self.bind((host, port))
            self.listen(1)
        except socket.error:
            critical('cannot listen on "(%s, %s)"', host, port); raise

    def handle_accept(self):
        """Accept the connection from Vim."""
        try:
            conn, addr = self.socket.accept()
            if self.netbeans and self.netbeans.connected:
                conn.close()
                info('rejecting connection from %: netbeans already connected',
                                                                        addr)
                return

            conn.setblocking(0)
            self.netbeans = Netbeans(addr, self.passwd)
            self.netbeans.set_socket(conn)
            self.netbeans.connected = True
            if self.oneshot:
                self.close()
            info('connected to %s', str(addr))
        except socket.error:
            critical('error accepting a connection on the server socket'); raise

    def handle_close(self):
        """Handle an asyncore close event."""
        unused = self
        assert False, 'unhandled close event in server'

class Netbeans(asynchat.async_chat, object):
    """A Netbeans instance exchanges netbeans messages on a socket.

    Instance attributes:
        _bset: buffer.BufferSet
            the buffer list
        _fileno: int
            nbsock file descriptor
        last_buf: Buffer
            the last buffer (non ClewnBuffer) where the cursor was positioned
        console: Console
            the pyclewn console
        dbgvarbuf: DebuggerVarBuffer
            the pyclewn debugger var buffer
        reply_fifo: fifo
            the fifo containing Reply instances used to check netbeans replies
        addr: tuple
            IP address: host, port tuple
        ready: boolean
            startupDone event has been received
        debugger: clewn.debugger.Debugger or subclass
            the debugger instance
        passwd: str
            netbeans password
        nbversion: str
            remote netbeans version
        ibuff: list
            list of strings received from netbeans
        seqno: int
            netbeans sequence number
        last_seqno: int
            last reply sequence number

    Class attributes:
        remove_fix: str
            '0' with vim 7.1 before patch 207
        getLength_fix: str
            '0' with vim 7.2 before patch 253
        enable_setdot: boolean
            False when the console and dbgvarbuf are not redrawn
        max_lines: int
            Console maximum number of lines
        bg_colors: tuple
            The three sign background colors of the bp enabled, bp disabled and
            the frame (in this order)

    """

    remove_fix = '0'
    getLength_fix = '0'
    enable_setdot = True
    max_lines = CONSOLE_MAXLINES
    frametext = '=>'
    fg_colors = ('none', 'none', 'none')
    bg_colors = ('Cyan', 'Green', 'Magenta')

    def __init__(self, addr, passwd):
        """Constructor."""
        asynchat.async_chat.__init__(self)
        self._fileno = None
        self.addr = addr
        self.passwd = passwd

        self._bset = vimbuffer.BufferSet(self)
        self.last_buf = None
        self.console = None
        self.dbgvarbuf = None
        self.reply_fifo = asynchat.fifo()
        self.ready = False
        self.debugger = None
        self.nbversion = None
        self.ibuff = []
        self.seqno = 0
        self.last_seqno = 0
        self.set_terminator('\n')

    def set_debugger(self, debugger):
        """Notify of the current debugger."""
        self.debugger = debugger
        debugger.set_nbsock(self)

    def switch_map(self, map):
        """Attach this dispatcher to another asyncore map."""
        fd = self._fileno
        if fd is not None:
            cur_map = self._map
            if fd in cur_map:
                del cur_map[fd]
            self._map = map
            self.add_channel()
            return cur_map
        return None

    def close(self):
        """Close netbeans and the debugger."""
        if not self.connected:
            return

        info('enter close')
        # close the debugger on a netbeans disconnect
        if self.debugger is not None:
            self.debugger.close()

        # vim73 'netbeans close SEGV' bug (fixed by 7.3.060).
        # Allow vim to process all netbeans PDUs before receiving the disconnect
        # event.
        time.sleep(misc.VIM73_BUG_SLEEP_TIME)

        asynchat.async_chat.close(self)
        self.connected = False

    def handle_error(self):
        """Raise the exception."""
        unused = self
        raise

    def handle_expt(self):
        """We are not listening on exceptional conditions."""
        unused = self
        assert False, 'unhandled exceptional condition'

    def handle_connect(self):
        """Not implemented."""
        unused = self

    def handle_accept(self):
        """Not implemented."""
        unused = self
        assert False, 'unhandled accept event'

    def handle_close(self):
        """Handle an async_chat close event."""
        info('netbeans socket disconnected')
        self.ready = False
        self.close()

    def collect_incoming_data(self, data):
        """Process async_chat received data."""
        self.ibuff.append(data)

    def found_terminator(self):
        """Process new line terminated netbeans message."""
        msg = "".join(self.ibuff)
        self.ibuff = []
        debug(msg)

        if not self.ready:
            self.open_session(msg)
            return

        if not self.debugger:
            warning('ignoring "%s": the debugger is not started', msg)
            return

        # handle variable number of elements in returned tuple
        is_event, buf_id, event, seqno, nbstring, arg_list =        \
                (lambda a, b=None, c=None, d=None, e=None, f=None:
                            (a, b, c, d, e, f))(*parse_msg(msg))

        if is_event is None:
            # ignore invalid message
            pass
        elif is_event:
            evt_handler = getattr(self, "evt_%s" % event, evt_ignore)
            evt_handler(buf_id, nbstring, arg_list)

        # a function reply: process the reply
        else:
            # vim may send multiple replies for one function request
            if seqno == self.last_seqno:
                return

            if self.reply_fifo.is_empty():
                raise ClewnError(
                        'got a reply with no matching function request')
            n, reply = self.reply_fifo.pop()
            unused = n
            reply(seqno, nbstring, arg_list)
            self.last_seqno = seqno


    def open_session(self, msg):
        """Process initial netbeans messages."""
        # 'AUTH changeme'
        matchobj = re_auth.match(msg)
        if matchobj:
            if matchobj.group('passwd') == self.passwd:
                return
            else:
                raise ClewnError('invalid password: "%s"' % self.passwd)
        # '0:version=0 "2.3"'
        # '0:startupDone=0'
        else:
            # handle variable number of elements in returned tuple
            is_event, buf_id, event, seqno, nbstring, arg_list =        \
                    (lambda a, b=None, c=None, d=None, e=None, f=None:
                                (a, b, c, d, e, f))(*parse_msg(msg))
            unused = arg_list
            unused = buf_id
            unused = seqno

            if is_event:
                if event == "version":
                    if nbstring >= NETBEANS_VERSION:
                        self.nbversion = nbstring
                        if self.nbversion < '2.5':
                            self.bg_colors = ('802287', '4190027', '15710005')
                        return
                    else:
                        raise ClewnError(
                                'invalid netbeans version: "%s"' % nbstring)
                elif event == "startupDone":
                    self.ready = True
                    return
        raise ClewnError('received unexpected message: "%s"' % msg)

    def goto_last(self):
        """Go to the last cursor position."""
        if self.last_buf is not None:
            self.send_cmd(self.last_buf, 'setDot', '%d/%d' %
                                    (self.last_buf.lnum, self.last_buf.col))

    #-----------------------------------------------------------------------
    #   Events
    #-----------------------------------------------------------------------
    def evt_balloonText(self, buf_id, nbstring, arg_list):
        """Process a balloonText netbeans event."""
        unused = arg_list
        unused = buf_id
        if not nbstring:
            error('empty string in balloonText')
        else:
            self.debugger.balloon_text(nbstring)

    def evt_disconnect(self, buf_id, nbstring, arg_list):
        """Process a disconnect netbeans event."""
        unused = arg_list
        unused = nbstring
        unused = buf_id
        self.close()

    def evt_fileOpened(self, buf_id, pathname, arg_list):
        """A file was opened by the user."""
        unused = arg_list
        if pathname:
            clewnbuf = vimbuffer.is_clewnbuf(pathname)
            if os.path.isabs(pathname) or clewnbuf:
                if clewnbuf:
                    buf = self._bset[os.path.basename(pathname)]
                    if buf.editport is not None:
                        buf.editport.visible = True
                else:
                    buf = self._bset[pathname]

                if buf.buf_id != buf_id:
                    if buf_id == 0:
                        self.send_cmd(buf, 'putBufferNumber',
                                                misc.quote(pathname))
                        self.send_cmd(buf, 'stopDocumentListen')
                        buf.registered = True
                        buf.update()
                    else:
                        warning('got fileOpened with wrong bufId')
                elif clewnbuf and not isinstance(buf.editport, Console):
                    self.send_function(buf, 'getLength')

            else:
                warning('absolute pathname required')
        else:
            self.show_balloon(
                '\nYou cannot use netbeans on a "[No Name]" file.\n'
                'Please, edit a file.\n'
                )

    def is_editport_evt(self, cmd):
        """Return True when this is an editport open/close event.

        The event notifies clewn of a change in the state of the editport,
        as visible (open) or not visible (close) in a Vim window.

        """
        tokens = cmd.split('.')
        if len(tokens) == 3 and tokens[0] == 'ClewnBuffer':
            if tokens[2] == 'open':
                visible = True
            elif tokens[2] == 'close':
                visible = False
            else:
                return False
            try:
                clss = eval(tokens[1])
            except NameError:
                return False
            if not issubclass(clss, ClewnBuffer):
                return False
            for buf in self._bset.values():
                editport = buf.editport
                if editport and isinstance(editport, clss):
                    editport.visible = visible
                    return True
        return False

    def evt_keyAtPos(self, buf_id, nbstring, arg_list):
        """Process a keyAtPos netbeans event."""
        if self.console is None or not self.console.buf.registered:
            self.console = Console(self)
            self.console.register()

        if self.dbgvarbuf is None:
            self.dbgvarbuf = DebuggerVarBuffer(self)

        buf = self._bset.getbuf(buf_id)
        if buf is None:
            error('invalid bufId: "%d" in keyAtPos', buf_id)
        elif not nbstring:
            warning('empty string in keyAtPos')
        elif len(arg_list) != 2:
            warning('invalid arg in keyAtPos')
        else:
            matchobj = re_lnumcol.match(arg_list[1])
            if not matchobj:
                error('invalid lnum/col: %s', arg_list[1])
            else:
                lnum = int(matchobj.group('lnum'))
                col = int(matchobj.group('col'))
                if not buf.editport or not isinstance(buf.editport, Console):
                    self.last_buf = buf
                    self.last_buf.lnum = lnum
                    self.last_buf.col = col

                cmd, args = (lambda a='', b='':
                                    (a, b))(*nbstring.split(None, 1))

                if self.is_editport_evt(cmd):
                    return

                self.debugger._dispatch_keypos(cmd, args, buf, lnum)

    def evt_killed(self, buf_id, nbstring, arg_list):
        """A file was closed by the user."""
        unused = nbstring
        unused = arg_list
        # buffer killed by netbeans, signs are already removed by Vim
        buf = self._bset.getbuf(buf_id)
        if buf is None:
            error('invalid bufId: "%s" in killed', buf_id)
        else:
            buf.registered = False
            buf.remove_all()

            if buf is self.last_buf:
                self.last_buf = None
            if buf.editport:
                buf.editport.clear()

    #-----------------------------------------------------------------------
    #   Commands - Functions
    #-----------------------------------------------------------------------

    def initiate_send (self):
        """Keep messages sent to Vim buffered in the fifo, while the netbeans
        connection is not ready.
        """
        if self.ready:
            try:
                asynchat.async_chat.initiate_send(self)
            except socket.error:
                self.close()

    def show_balloon(self, text):
        """Show the Vim balloon."""
        # do not show a balloon when the debugger is not started
        if not self.debugger or not self.debugger.started:
            return

        # restrict size to 2000 chars, about...
        size = 2000
        if len(text) > size:
            size //= 2
            text = text[:size] + '...' + text[-size:]
        self.send_cmd(None, 'showBalloon', misc.quote(text))

    def special_keys(self, key):
        """Send the specialKeys netbeans command."""
        self.send_cmd(None, 'specialKeys', misc.quote(key))

    def send_cmd(self, buf, cmd, args=''):
        """Send a command to Vim."""
        self.send_request('%d:%s!%d%s%s\n', buf, cmd, args)

    def send_function(self, buf, function, args=''):
        """Send a function call to Vim."""
        # race condition: queue the pending reply first, before the
        # reply received on the socket gets a chance to be processed
        try:
            clss = eval('%sReply' % function)
        except NameError:
            assert False, 'internal error, no reply class for %s' % function
        assert issubclass(clss, Reply)
        reply = clss(buf, self.seqno + 1, self)
        self.reply_fifo.push(reply)

        self.send_request('%d:%s/%d%s%s\n', buf, function, args)

        # Due to the asynchronous exchanges between pyclewn and Vim, the reply
        # to a nebeans 'getLength' function may arrive after the call to an
        # 'insert' or 'remove' netbeans function. In that case the length
        # reported by Vim is outdated. The workaround is to force a new
        # 'getLength' after insert/remove (in that case only), and to ignore
        # nested 'getLength' replies (all replies except the last one).
        if function == 'insert' or function == 'remove':
            clewnbuffer = buf.editport
            if clewnbuffer is not None and clewnbuffer.getLength_count != 0:
                self.send_function(buf, 'getLength')

    def send_request(self, fmt, buf, request, args):
        """Send a netbeans function or command."""
        self.seqno += 1
        buf_id = 0
        space = ' '
        if isinstance(buf, vimbuffer.Buffer):
            buf_id = buf.buf_id
        if not args:
            space = ''
        msg = fmt % (buf_id, request, self.seqno, space, args)
        debug(msg.strip('\n'))

        if self.connected:
            self.push(msg)
        else:
            info('failed to send_request: not connected')

    def __repr__(self):
        """Return the async_chat representation."""
        return self.__str__()

    def __str__(self):
        """Return the string representation."""
        status = ''
        if self.ready:
            status = 'ready, netbeans version "%s"'                     \
                     ' (vim "netbeans remove function" bug: "%s",'      \
                     ' vim "netbeans getLength" bug: "%s"), remote '    \
                     % (self.nbversion, self.remove_fix, self.getLength_fix)
        elif not self.connected and self.addr:
            status = 'listening to '
        elif self.connected:
            status = 'connected to '
        if self.addr is not None:
            status += str(self.addr)
        return status

    #-----------------------------------------------------------------------
    #   debugger interface
    #-----------------------------------------------------------------------

    def add_bp(self, bp_id, pathname, lnum):
        """Add a breakpoint to pathname at lnum."""
        self._bset.add_bp(bp_id, pathname, lnum)

    def delete_bp(self, bp_id):
        """Delete the breakpoint."""
        self._bset.delete_anno(bp_id)

    def delete_all(self, pathname, lnum):
        """Delete all breakpoints."""
        return self._bset.delete_all(pathname, lnum)

    def remove_all(self):
        """Remove all annotations.

        Vim signs are unplaced.
        Annotations are not deleted.

        """
        self._bset.remove_all()

    def update_bp(self, bp_id, disabled):
        """Update the breakpoint state.

        Return True when successful.

        """
        return self._bset.update_bp(bp_id, disabled)

    def show_frame(self, pathname, lnum):
        """Show the frame annotation."""
        self._bset.show_frame(pathname, lnum)

    def get_lnum_list(self, pathname):
        """Return the list of line numbers of all enabled breakpoints."""
        return self._bset.get_lnum_list(pathname)

