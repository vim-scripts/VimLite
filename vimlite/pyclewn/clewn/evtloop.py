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

"""Pyclewn event loop."""

import os
import time
import select
import errno
import asyncore
if os.name == 'nt':
    from clewn.nt import PipePeek
else:
    from clewn.posix import PipePeek

import clewn.asyncproc as asyncproc
import clewn.misc as misc

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('loop')
Unused = critical
Unused = error
Unused = warning
Unused = info
Unused = debug

use_select_emulation = ('CLEWN_PIPES' in os.environ or os.name == 'nt')

def get_asyncobj(fd, file_type, fdmap):
    """Return an asyncore instance from 'fdmap' if matching 'file_type'."""
    asyncobj = fdmap.get(fd)
    assert asyncobj is not None
    if isinstance(asyncobj.socket, file_type):
        return asyncobj
    return None

def strip_asyncobj(wtd, file_type, fdmap):
    """Remove all 'file_type' file descriptors in 'wtd'."""
    tmp_list = wtd[:]
    for fd in tmp_list:
        asyncobj = get_asyncobj(fd, file_type, fdmap)
        if asyncobj is not None:
            wtd.remove(fd)

def clewn_select(iwtd, owtd, ewtd, timeout, static_select=[]):
    """Windows select emulation on pipes and sockets.

    The select_peeker thread, once created, is never destroyed.

    """
    select_peeker = None
    pipe_objects = []
    fdmap = asyncore.socket_map
    # pipes send only read events
    strip_asyncobj(owtd, asyncproc.FileWrapper, fdmap)
    strip_asyncobj(ewtd, asyncproc.FileWrapper, fdmap)

    # start the peek threads
    for fd in iwtd:
        asyncobj = get_asyncobj(fd, asyncproc.FileWrapper, fdmap)
        if asyncobj is not None:
            assert hasattr(asyncobj, 'reader') and asyncobj.reader
            if not hasattr(asyncobj, 'peeker'):
                asyncobj.peeker = PipePeek(asyncobj.socket.fileno(), asyncobj)
                asyncobj.peeker.start()
            pipe_objects.append(asyncobj)
            iwtd.remove(fd)
            asyncobj.peeker.start_thread()
    if iwtd or owtd or ewtd:
        if not static_select:
            static_select.append(asyncproc.SelectPeek(fdmap))
        elif not static_select[0].isAlive():
            # when running the testsuite, static_select is the same
            # list across all tests: replace previous dead thread
            static_select[0] = asyncproc.SelectPeek(fdmap)
        select_peeker = static_select[0]
        if not select_peeker.isAlive():
            select_peeker.start()

        select_peeker.set_waitable(iwtd, owtd, ewtd)
        select_peeker.start_thread()

    # wait for events
    if select_peeker is None and not pipe_objects:
        time.sleep(timeout)
    else:
        asyncproc.Peek.select_event.wait(timeout)

    # stop the select threads
    iwtd = []
    owtd = []
    ewtd = []
    if select_peeker is not None:
        iwtd, owtd, ewtd = select_peeker.stop_thread()
    for asyncobj in pipe_objects:
        asyncobj.peeker.stop_thread()
        if asyncobj.peeker.read_event:
            iwtd.append(asyncobj.socket.fileno())
    asyncproc.Peek.select_event.clear()

    return iwtd, owtd, ewtd

def poll(map, timeout=0.0):
    """Asyncore poll function."""
    if map:
        r = []; w = []; e = []
        for fd, obj in map.items():
            is_r = obj.readable()
            is_w = obj.writable()
            if is_r:
                r.append(fd)
            if is_w:
                w.append(fd)
            if is_r or is_w:
                e.append(fd)
        if [] == r == w == e:
            time.sleep(timeout)
        else:
            try:
                if use_select_emulation:
                    r, w, e = clewn_select(r, w, e, timeout)
                else:
                    r, w, e = select.select(r, w, e, timeout)
            except select.error, err:
                if err[0] != errno.EINTR:
                    raise
                else:
                    return

        for fd in r:
            obj = map.get(fd)
            if obj is None:
                continue
            asyncore.read(obj)

        for fd in w:
            obj = map.get(fd)
            if obj is None:
                continue
            asyncore.write(obj)

        for fd in e:
            obj = map.get(fd)
            if obj is None:
                continue
            asyncore._exception(obj)

