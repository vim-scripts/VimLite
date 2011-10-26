# vi:set ts=8 sts=4 sw=4 et tw=72:
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
"""This module provides the basic infrastructure for using Vim as a
front-end to a debugger.

The basic idea behind this infrastructure is to subclass the 'Debugger'
abstract class, list all the debugger commands and implement the
processing of these commands in 'cmd_<command_name>' methods in the
subclass. When the method is not implemented, the processing of the
command is dispatched to the 'default_cmd_processing' method. These
methods may call the 'Debugger' API methods to control Vim. For example,
'add_bp' may be called to set a breakpoint in a buffer in Vim, or
'console_print' may be called to write the output of a command in the
Vim debugger console.

The 'Debugger' subclass is made available to the user after adding an
option to the 'parse_options' method in the 'Vim' class, see vim.py.

The 'Simple' class in simple.py provides a simple example of a fake
debugger front-end.

"""


import os
import os.path
import re
import time
import heapq
import string
import copy

from clewn import *
import clewn.misc as misc
import clewn.netbeans as netbeans

__all__ = ['LOOP_TIMEOUT', 'restart_timer', 'Debugger']
LOOP_TIMEOUT = .040

RE_KEY =    \
    r'^\s*(?P<key>'                                                     \
        r'(?# Fn, C-Fn, S-Fn, M-Fn, C-S-Fn, C-M-Fn, S-M-Fn,C-S-M-Fn:)'  \
        r'(?:[Cc]-)?(?:[Ss]-)?(?:[Mm]-)?[Ff]\d{1,2}'                    \
        r'(?# C-A, C-S-A, C-S-M-A, C-M-A:)'                             \
        r'|(?:[Cc]-)(?:[Ss]-)?(?:[Mm]-)?[A-Za-z]'                       \
        r'(?# S-A, S-M-A:)'                                             \
        r'|(?:[Ss]-)(?:[Mm]-)?[A-Za-z]'                                 \
        r'(?#M-A:)'                                                     \
        r'|(?:[Mm]-)[A-Za-z]'                                           \
    r')'        \
    r'\s*:\s*(?P<value>[^#]*)'                                          \
    r'# RE: key:value line in .pyclewn_keys'
RE_COMMENT = r'^\s*([#].*|\s*)$'                                    \
             r'# RE: a comment line'
RE_FILENAMELNUM = r'^(?P<name>\S+):(?P<lnum>\d+)$'                  \
                  r'# RE: pathname:lnum'

# compile regexps
re_key = re.compile(RE_KEY, re.VERBOSE)
re_comment = re.compile(RE_COMMENT, re.VERBOSE)
re_filenamelnum = re.compile(RE_FILENAMELNUM, re.VERBOSE)

AUTOCOMMANDS = """
augroup clewn
    autocmd!
    autocmd BufWinEnter (clewn)_* silent! setlocal bufhidden=hide"""    \
"""                                     | setlocal buftype=nofile"""    \
"""                                     | setlocal noswapfile"""        \
"""                                     | setlocal fileformat=unix"""   \
"""                                     | setlocal expandtab"""         \
"""                                     | setlocal nowrap"""            \
"""
    ${bufferlist_autocmd}
    autocmd BufWinEnter ${console} silent! Nbkey ClewnBuffer.Console.open
    autocmd BufWinLeave ${console} silent! Nbkey ClewnBuffer.Console.close
    autocmd BufWinEnter ${variables} silent! Nbkey ClewnBuffer.DebuggerVarBuffer.open
    autocmd BufWinLeave ${variables} silent! Nbkey ClewnBuffer.DebuggerVarBuffer.close
    autocmd BufWinEnter ${variables} silent! setlocal syntax=dbgvar
augroup END

"""

BUFFERLIST_AUTOCMD = """
    autocmd VimEnter * silent! call s:BuildList()
    autocmd BufWinEnter * silent! call s:InBufferList(expand("<afile>:p"))
"""

FUNCTION_BUFLIST = """
let s:bufList = {}
let s:bufLen = 0

" Build the list as an hash of active buffers
" This is the list of buffers loaded on startup,
" that must be advertized to pyclewn
function s:BuildList()
    let wincount = winnr("$")
    let index = 1
    while index <= wincount
        let s:bufList[expand("#". winbufnr(index) . ":p")] = 1
        let index = index + 1
    endwhile
    let s:bufLen = len(s:bufList)
endfunction

" Return true when the buffer is in the list, and remove it
function s:InBufferList(pathname)
    if s:bufLen && has_key(s:bufList, a:pathname)
        unlet s:bufList[a:pathname]
        let s:bufLen = len(s:bufList)
        return 1
    endif
    return 0
endfunction

" Function that can be used for testing
" Remove 's:' to expand function scope to runtime
function! s:PrintBufferList()
    for key in keys(s:bufList)
       echo key
    endfor
endfunction

"""

FUNCTION_SPLIT = """
" Split a window and return to the initial window,
" if 'location' is not ''
"   'location' may be: '', 'top', 'bottom', 'left' or 'right'
function s:split(bufname, location)
    let nr = winnr()
    let split = "split"
    let spr = &splitright
    let sb = &splitbelow
    let ei = &eventignore
    set nosplitright
    set nosplitbelow
    set eventignore+=WinEnter,WinLeave
    let prevbuf_winnr = bufwinnr(bufname("%"))
    if winnr("$") == 1 && (a:location == "right" || a:location == "left")
        let split = "vsplit"
        if a:location == "right"
            set splitright
        else
            let prevbuf_winnr = 2
        endif
    else
        if a:location == "bottom"
            let nr = winnr("$")
            set splitbelow
        else
            let prevbuf_winnr = prevbuf_winnr + 1
        endif
        if a:location != ""
            exe nr . "wincmd w"
        endif
    endif

    exe &previewheight . split . " " . a:bufname
    setlocal winfixheight

    let &splitright = spr
    let &splitbelow = sb
    exe prevbuf_winnr . "wincmd w"
    let &eventignore = ei
endfunc

"""

FUNCTION_CONSOLE = """
" Split a window and display a buffer with previewheight.
function s:winsplit(bufname, location)
    if a:location == "none"
        return
    endif

    " The console window does not exist
    if bufwinnr(a:bufname) == -1
        call s:split(a:bufname, a:location)
    " Split the console window (when the only window)
    " this is required to prevent Vim display toggling between
    " clewn console and the last buffer where the cursor was
    " positionned (clewn does not know that this buffer is not
    " anymore displayed)
    elseif winnr("$") == 1
        call s:split("", a:location)
    endif
endfunction

"""

FUNCTION_NBCOMMAND = """
" Run the nbkey netbeans Vim command.
function s:nbcommand(...)
    if !has("netbeans_enabled")
        echohl ErrorMsg
        echo "Error: netbeans is not connected."
        echohl None
        return
    endif

    " Allow '' as first arg: the 'C' command followed by a mandatory parameter
    if a:0 != 0
        if a:1 != "" || (a:0 > 1 && a:2 != "")
            if bufname("%") == ""
                edit ${console}
            else
                call s:winsplit("${console}", "${location}")
            endif
            ${split_dbgvar_buf}
            let cmd = "Nbkey " . join(a:000, ' ')
            exe cmd
        endif
    endif
endfunction

"""

FUNCTION_NBCOMMAND_RESTRICT = """
" Run the nbkey netbeans Vim command.
function s:nbcommand(...)
    if bufname("%") == ""
        echohl ErrorMsg
        echo "Cannot run a pyclewn command on the '[No Name]' buffer."
        echo "Please edit a file first."
        echohl None
        return
    endif

    " Allow '' as first arg: the 'C' command followed by a mandatory parameter
    if a:0 != 0
        if a:1 != "" || (a:0 > 1 && a:2 != "")
            " edit the buffer that was loaded on startup and call input() to
            " give a chance for vim72 to process the putBufferNumber netbeans
            " message in the idle loop before the call to nbkey
            let l:currentfile = expand("%:p")
            if s:InBufferList(l:currentfile)
                exe "edit " . l:currentfile
                echohl WarningMsg
                echo "Files loaded on Vim startup must be registered with pyclewn."
                echo "Registering " . l:currentfile . " with pyclewn."
                call inputsave()
                call input("Press the <Enter> key to continue.")
                call inputrestore()
                echohl None
            endif
            call s:winsplit("${console}", "${location}")
            ${split_dbgvar_buf}
            let cmd = "Nbkey " . join(a:000, ' ')
            exe cmd
        endif
    endif
endfunction

"""

SPLIT_DBGVAR_BUF = """
            if a:1 == "dbgvar"
                call s:winsplit("${dbgvar_buf}", "")
            endif
"""

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('dbg')
Unused = error
Unused = warning
Unused = debug

def name_lnum(name_lnum):
    """Parse name_lnum as the string 'name:lnum'.

    Return the tuple (full_pathname, lnum) if success, (None, lnum)
    when name is the name of a clewn buffer, and ('', -1) after
    failing to parse name_lnum.

    """
    name = ''
    lnum = -1
    matchobj = re_filenamelnum.match(name_lnum)
    if matchobj:
        name = matchobj.group('name')
        name = netbeans.full_pathname(name)
        lnum = int(matchobj.group('lnum'))
    return name, lnum

def restart_timer(timeout):
    """Decorator to re-schedule the method at 'timeout', after it has run."""
    def decorator(f):
        """The decorator."""
        def _newf(self, *args, **kwargs):
            """The decorated method."""
            job = getattr(self, f.func_name)
            ret = f(self, *args, **kwargs)
            self.timer(job, timeout)
            return ret
        return _newf
    return decorator

class Job:
    """Job instances are pushed in an ordered heapq queue."""

    def __init__(self, time, job):
        """Constructor."""
        self.time = time
        self.job = job

    def __lt__(self, o): """Comparison method."""; return self.time < o.time
    def __le__(self, o): """Comparison method."""; return self.time <= o.time
    def __eq__(self, o): """Comparison method."""; return self.time == o.time
    def __ne__(self, o): """Comparison method."""; return self.time != o.time
    def __gt__(self, o): """Comparison method."""; return self.time > o.time
    def __ge__(self, o): """Comparison method."""; return self.time <= o.time

class Debugger(object):
    """Abstract base class for pyclewn debuggers.

    The debugger commands received through netbeans 'keyAtPos' events
    are dispatched to methods whose name starts with the 'cmd_' prefix.

    The signature of the cmd_<command_name> methods are:

        cmd_<command_name>(self, str cmd, str args)
            cmd: the command name
            args: the arguments of the command

    The '__init__' method of the subclass must call the '__init__'
    method of 'Debugger' as its first statement and forward the method
    parameters as an opaque list. The __init__ method must update the
    'cmds' and 'mapkeys' dict attributes with its own commands and key
    mappings.

    Instance attributes:
        cmds: dict
            The debugger command names are the keys. The values are the
            sequence of available completions on the command first
            argument. The sequence is possibly empty, meaning no
            completion. When the value is not a sequence (for example
            None), this indicates file name completion.
        mapkeys: dict
            Key names are the dictionary keys. See the 'keyCommand'
            event in Vim netbeans documentation for the definition of a
            key name. The values are a tuple made of two strings
            (command, comment):
                'command' is the debugger command mapped to this key
                'comment' is an optional comment
            One can use template substitution on 'command', see the file
            runtime/.pyclewn_keys.template for a description of this
            feature.
        options: optparse.Values
            The pyclewn command line parameters.
        started: boolean
            True when the debugger is started.
        closed: boolean
            True when the debugger is closed.
        pyclewn_cmds: dict
            The subset of 'cmds' that are pyclewn specific commands.
        __nbsock: netbeans.Netbeans
            The netbeans asynchat socket.
        _jobs: list
            list of pending jobs to run on a timer event in the
            dispatch loop
        _jobs_enabled: bool
            process enqueued jobs when True
        _last_balloon: str
            The last balloonText event received.
        _prompt_str: str
            The prompt printed on the console.
        _consbuffered: boolean
            True when output to the vim debugger console is buffered

    """

    def __init__(self, options):
        """Initialize instance variables and the prompt."""
        self.options = options

        self.cmds = {
            'dumprepr':(),
            'help':(),
            'mapkeys':(),
            'unmapkeys':(),
        }
        self.pyclewn_cmds = self.cmds
        self.mapkeys = {}
        self.cmds[''] = []
        self.started = False
        self.closed = False
        self._jobs = []
        self._jobs_enabled = False
        self._last_balloon = ''
        self._prompt_str = '(%s) ' % self.__class__.__name__.lower()
        self._consbuffered = False
        self.__nbsock = None

        # schedule the first 'debugger_background_jobs' method
        self.timer(self.debugger_background_jobs, LOOP_TIMEOUT)

    def set_nbsock(self, nbsock):
        """Set the netbeans socket."""
        self.__nbsock = nbsock

    def switch_map(self, map):
        """Attach nbsock to another asyncore map."""
        if self.__nbsock:
            return self.__nbsock.switch_map(map)
        return None

    #-----------------------------------------------------------------------
    #   Overidden methods by the Debugger subclass.
    #-----------------------------------------------------------------------

    def pre_cmd(self, cmd, args):
        """The method called before each invocation of a 'cmd_<name>'
        method.

        This method must be implemented in a subclass.

        Method parameters:
            cmd: str
                The command name.
            args: str
                The arguments of the command.

        """
        unused = self
        unused = cmd
        unused = args
        raise NotImplementedError('must be implemented in subclass')

    def default_cmd_processing(self, cmd, args):
        """Fall back method for commands not handled by a 'cmd_<name>'
        method.

        This method must be implemented in a subclass.

        Method parameters:
            cmd: str
                The command name.
            args: str
                The arguments of the command.

        """
        unused = self
        unused = cmd
        unused = args
        raise NotImplementedError('must be implemented in subclass')

    def post_cmd(self, cmd, args):
        """The method called after each invocation of a 'cmd_<name>'
        method.

        This method must be implemented in a subclass.

        Method parameters:
            cmd: str
                The command name.
            args: str
                The arguments of the command.

        """
        unused = self
        unused = cmd
        unused = args
        raise NotImplementedError('must be implemented in subclass')

    def vim_script_custom(self, prefix):
        """Return debugger specific Vim statements as a string.

        A Vim script is run on Vim start-up, for example to define all
        the debugger commands in Vim. This method may be overriden to
        add some debugger specific Vim statements or functions to this
        script.

        Method parameter:
            prefix: str
                The prefix used for the debugger commands in Vim.

        """
        return ''

    #-----------------------------------------------------------------------
    #   The Debugger API.
    #-----------------------------------------------------------------------

    def add_bp(self, bp_id, pathname, lnum):
        """Add a breakpoint to a Vim buffer at lnum.

        Load the buffer in Vim and set an highlighted sign at 'lnum'.

        Method parameters:
            bp_id: object
                The debugger breakpoint id.
            pathname: str
                The absolute pathname to the Vim buffer.
            lnum: int
                The line number in the Vim buffer.

        """
        self.__nbsock.add_bp(bp_id, pathname, lnum)

    def update_bp(self, bp_id, disabled=False):
        """Update the enable/disable state of a breakpoint.

        The breakpoint must have been already set in a Vim buffer with
        'add_bp'.
        Return True when successful.

        Method parameters:
            bp_id: object
                The debugger breakpoint id.
            disabled: bool
                When True, set the breakpoint as disabled.

        """
        return self.__nbsock.update_bp(bp_id, disabled)

    def delete_bp(self, bp_id):
        """Delete a breakpoint.

        The breakpoint must have been already set in a Vim buffer with
        'add_bp'.

        Method parameter:
            bp_id: object
                The debugger breakpoint id.

        """
        self.__nbsock.delete_bp(bp_id)

    def delete_all(self, pathname=None, lnum=None):
        """Delete all the breakpoints in a Vim buffer or in all buffers.

        Delete all the breakpoints in a Vim buffer at 'lnum'.
        Delete all the breakpoints in a Vim buffer when 'lnum' is None.
        Delete all the breakpoints in all the buffers when 'pathname' is
        None.

        Method parameters:
            pathname: str
                The absolute pathname to the Vim buffer.
            lnum: int
                The line number in the Vim buffer.

        """
        return self.__nbsock.delete_all(pathname, lnum)

    def remove_all(self):
        """Remove all annotations.

        Vim signs are unplaced.
        Annotations are not deleted.

        """
        self.__nbsock.remove_all()

    def get_lnum_list(self, pathname):
        """Return a list of line numbers of all enabled breakpoints in a
        Vim buffer.

        A line number may be duplicated in the list.
        This is used by Simple and may not be useful to other debuggers.

        Method parameter:
            pathname: str
                The absolute pathname to the Vim buffer.

        """
        return self.__nbsock.get_lnum_list(pathname)

    def update_dbgvarbuf(self, getdata, dirty, lnum=None):
        """Update the variables buffer in Vim.

        Update the variables buffer in Vim when one the following
        conditions is
        True:
            * 'dirty' is True
            * the content of the Vim variables buffer and the content of
              pyclewn 'dbgvarbuf' are not consistent after an error in the
              netbeans protocol occured
        Set the Vim cursor at 'lnum' after the buffer has been updated.

        Method parameters:
            getdata: callable
                A callable that returns the content of the variables
                buffer as a string.
            dirty: bool
                When True, force updating the buffer.
            lnum: int
                The line number in the Vim buffer.

        """
        dbgvarbuf = self.__nbsock.dbgvarbuf
        if dbgvarbuf is None:
            return
        if dirty and not dbgvarbuf.buf.registered:
            dbgvarbuf.register()

        # race condition: must note the state of the buffer before
        # updating the buffer, since this will change its visible state
        # temporarily
        if dirty or dbgvarbuf.dirty:
            dbgvarbuf.update(getdata())
            # set the cursor on the current fold when visible
            if lnum is not None:
                dbgvarbuf.setdot(lnum=lnum)

    def show_frame(self, pathname=None, lnum=1):
        """Show the frame highlighted sign in a Vim buffer.

        The frame sign is unique.
        Remove the frame sign when 'pathname' is None.

        Method parameters:
            pathname: str
                The absolute pathname to the Vim buffer.
            lnum: int
                The line number in the Vim buffer.

        """
        self.__nbsock.show_frame(pathname, lnum)

    def balloon_text(self, text):
        """Process a netbeans balloonText event.

        Used when 'ballooneval' is set and the mouse pointer rests on
        some text for a moment.

        Method parameter:
            text: str
                The text under the mouse pointer.

        """
        self._last_balloon = text

    def show_balloon(self, text):
        """Show 'text' in the Vim balloon.

        Method parameter:
            text: str
                The text to show in the balloon.

        """
        self.__nbsock.show_balloon(text)

    def prompt(self):
        """Print the prompt in the Vim debugger console."""
        # no buffering until the first prompt:
        # workaround to a bug in netbeans/Vim that does not redraw the
        # console on the first 'insert'
        self._consbuffered = True
        self.console_print(self._prompt_str)
        console = self.__nbsock.console
        if self.started and console.buf.registered:
            console.flush()

    # prompt is a Cmd class attribute, do not use it with pdb
    print_prompt = prompt

    def get_console(self):
        """Return the console."""
        return self.__nbsock.console

    def console_print(self, format, *args):
        """Print a format string and its arguments to the console.

        Method parameters:
            format: str
                The message format string.
            args: str
                The arguments which are merged into 'format' using the
                python string formatting operator.

        """
        console = self.__nbsock.console
        if self.started and console.buf.registered:
            console.append(format, *args)
            if not self._consbuffered:
                console.flush()

    def console_flush(self):
        """Flush the console."""
        self.__nbsock.console.flush()

    def timer(self, callme, delta):
        """Schedule the 'callme' job at 'delta' time from now.

        The timer granularity is LOOP_TIMEOUT, so it does not make sense
        to request a 'delta' time less than LOOP_TIMEOUT.

        Method parameters:
            callme: callable
                the job being scheduled
            delta: float
                time interval

        """
        heapq.heappush(self._jobs, Job(time.time() + delta, callme))

    def close(self):
        """Close the debugger and remove all signs in Vim."""
        info('enter close')
        if not self.closed:
            self.started = False
            self.closed = True
            info('in close: remove all annotations')
            self.remove_all()

    def netbeans_detach(self):
        """Close the netbeans session."""
        # A bug in vim73 prevents closing netbeans from pyclewn: send
        # the 'DETACH' message instead, and make sure that no other data
        # is sent after this message to avoid triggering the vim crash.
        info('enter netbeans_detach')
        self.started = False
        self.closed = True
        if self.__nbsock.connected:
            self.remove_all()
            msg = 'DETACH'
            info('sending netbeans message \'%s\'', msg)
            self.__nbsock.push(msg + '\n')

        # vim73 'netbeans close SEGV' bug (fixed by 7.3.060).
        # Allow vim to process all netbeans PDUs before receiving the disconnect
        # event.
        time.sleep(misc.VIM73_BUG_SLEEP_TIME)

    #-----------------------------------------------------------------------
    #   Internally used methods.
    #-----------------------------------------------------------------------

    def _start(self):
        """Start the debugger and print the banner.

        The debugger is automatically started on the first received keyAtPos
        event.

        """
        if not self.started:
            self.started = True
            # print the banner only with the first netbeans instance
            if not self.closed:
                self.console_print(
                    'Pyclewn version %s starting a new instance of %s.\n\n',
                            __tag__, self.__class__.__name__.lower())
            else:
                self.console_print(
                    'Pyclewn restarting the %s debugger.\n\n',
                            self.__class__.__name__.lower())
            self.closed = False

    @restart_timer(LOOP_TIMEOUT)
    def debugger_background_jobs(self):
        """Flush the console buffer."""
        if not self.__nbsock:
            return
        console = self.__nbsock.console
        if self.started and console.buf.registered and self._consbuffered:
            console.flush(time.time())

    def _get_cmds(self):
        """Return the commands dictionary."""
        # the 'C' command by itself has the whole list of commands
        # as its 1st arg completion list, excluding the '' command
        self.cmds[''] += [x for x in self.cmds.keys() if x]

        return self.cmds

    def _vim_script(self, options):
        """Build the vim script.

        Each clewn vim command can be invoked as 'prefix' + 'cmd' with optional
        arguments.  The command with its arguments is invoked with ':nbkey' and
        received by pyclewn in a keyAtPos netbeans event.

        Return the file object of the vim script.

        """
        # MOD1
        #return open(os.path.expanduser("~/pyclewn_script.vim"), "rb")
        # create the vim script in a temporary file
        prefix = options.prefix.capitalize()
        f = None
        try:
            # pyclewn is started from within vim
            if not options.editor:
                if options.cargs:
                    f = open(options.cargs[0], 'w')
                else:
                    return None
            # MOD2
            elif os.environ.get('VIM_SERVERNAME') and options.cargs:
                f = open(options.cargs[0], 'w')
            else:
                # MOD3
                #f = misc.TmpFile('vimscript')
                f = open(os.path.expanduser("~/pyclewn_script.vim"), "wb")

            # set 'cpo' option to its vim default value
            f.write('let s:cpo_save=&cpo\n')
            f.write('set cpo&vim\n')

            # vim autocommands
            bufferlist_autocmd = ''
            if options.noname_fix == '0':
                bufferlist_autocmd = BUFFERLIST_AUTOCMD
            f.write(string.Template(AUTOCOMMANDS).substitute(
                                        console=netbeans.CONSOLE,
                                        variables=netbeans.VARIABLES_BUFFER,
                                        bufferlist_autocmd=bufferlist_autocmd))

            # popup gdb console on pyclewn mapped keys
            #f.write(string.Template(
                #'cnoremap nbkey call <SID>winsplit'
                #'("${console}", "${location}") <Bar> nbkey'
                #).substitute(console=netbeans.CONSOLE,
                            #location=options.window))
            # MODs
            f.write(string.Template(
                'command! -nargs=* Nbkey call <SID>winsplit'
                '("${console}", "${location}") <Bar> nbkey <args>'
                ).substitute(console=netbeans.CONSOLE,
                            location=options.window))

            # utility vim functions
            if options.noname_fix == '0':
                f.write(FUNCTION_BUFLIST)
            f.write(FUNCTION_SPLIT)
            f.write(FUNCTION_CONSOLE)

            # unmapkeys script
            f.write('function s:unmapkeys()\n')
            for key in self.mapkeys:
                f.write('unmap <%s>\n' % key)
            f.write('endfunction\n')

            # setup pyclewn vim user defined commands
            if options.noname_fix != '0':
                function_nbcommand = FUNCTION_NBCOMMAND
            else:
                function_nbcommand = FUNCTION_NBCOMMAND_RESTRICT

            split_dbgvar_buf = ''
            if netbeans.Netbeans.getLength_fix != '0':
                split_dbgvar_buf = string.Template(SPLIT_DBGVAR_BUF).substitute(
                                        dbgvar_buf=netbeans.VARIABLES_BUFFER)
            f.write(string.Template(function_nbcommand).substitute(
                                        console=netbeans.CONSOLE,
                                        location=options.window,
                                        split_dbgvar_buf=split_dbgvar_buf))
            noCompletion = string.Template('command -bar -nargs=* ${pre}${cmd} '
                                    'call s:nbcommand("${cmd}", <f-args>)\n')
            fileCompletion = string.Template('command -bar -nargs=* '
                                    '-complete=file ${pre}${cmd} '
                                    'call s:nbcommand("${cmd}", <f-args>)\n')
            listCompletion = string.Template('command -bar -nargs=* '
                                    '-complete=custom,s:Arg_${cmd} ${pre}${cmd} '
                                    'call s:nbcommand("${cmd}", <f-args>)\n')
            argsList = string.Template('function s:Arg_${cmd}(A, L, P)\n'
                                    '\treturn "${args}"\n'
                                    'endfunction\n')
            unmapkeys = string.Template('command -bar ${pre}unmapkeys '
                                        'call s:unmapkeys()\n')
            for cmd, completion in self._get_cmds().iteritems():
                if cmd == 'unmapkeys':
                    f.write(unmapkeys.substitute(pre=prefix))
                    continue
                try:
                    iter(completion)
                except TypeError:
                    f.write(fileCompletion.substitute(pre=prefix, cmd=cmd))
                else:
                    if not completion:
                        f.write(noCompletion.substitute(pre=prefix, cmd=cmd))
                    else:
                        f.write(listCompletion.substitute(pre=prefix, cmd=cmd))
                        args = '\\n'.join(completion)
                        f.write(argsList.substitute(args=args, cmd=cmd))

            # add debugger specific vim statements
            f.write(self.vim_script_custom(prefix))

            # reset 'cpo' option
            f.write('let &cpo = s:cpo_save\n')

            # delete the vim script after it has been sourced
            f.write('\n"call delete(expand("<sfile>"))\n')
        finally:
            if f:
                f.close()

        return f

    def _call_jobs(self):
        """Call the scheduled jobs.

        This method is called in Vim dispatch loop.
        Return the timeout for the next iteration of the event loop.

        """
        if not self.__nbsock:
            return
        timeout = LOOP_TIMEOUT
        if not self._jobs_enabled and self.__nbsock.ready:
            self._jobs_enabled = True
        if self._jobs_enabled:
            now = time.time()
            while self._jobs and now >= self._jobs[0].time:
                callme = heapq.heappop(self._jobs).job
                callme()
                now = time.time()
            if self._jobs:
                timeout = min(timeout, abs(self._jobs[0].time - now))
        return timeout

    def _do_cmd(self, method, cmd, args):
        """Process 'cmd' and its 'args' with 'method'."""
        self.pre_cmd(cmd, args)
        method(cmd, args)
        self.post_cmd(cmd, args)

    def _dispatch_keypos(self, cmd, args, buf, lnum):
        """Dispatch the keyAtPos event to the proper cmd_xxx method."""
        if not self.started:
            self._start()

        # do key mapping substitution
        mapping = self._keymaps(cmd, buf, lnum)
        if mapping:
            cmd, args = (lambda a, b='': (a, b))(*mapping.split(None, 1))

        try:
            method = getattr(self, 'cmd_%s' % cmd)
        except AttributeError:
            method = self.default_cmd_processing

        self._do_cmd(method, cmd, args)

    def _keymaps(self, key, buf, lnum):
        """Substitute a key with its mapping."""
        cmdline = ''
        if key in self.mapkeys.keys():
            t = string.Template(self.mapkeys[key][0])
            cmdline = t.substitute(fname=buf.name, lnum=lnum,
                                            text=self._last_balloon)
            assert len(cmdline) != 0
        return cmdline

    def _read_keysfile(self):
        """Read the keys mappings file.

        An empty entry deletes the key in the mapkeys dictionary.

        """
        path = os.environ.get('CLEWNDIR')
        if not path:
            path = os.environ.get('HOME')
        if not path:
            return
        path = os.path.join(path,
                    '.pyclewn_keys.' + self.__class__.__name__.lower())
        if not os.path.exists(path):
            return

        info('reading %s', path)
        try:
            f = open(path)
            for line in f:
                matchobj = re_key.match(line)
                if matchobj:
                    k = matchobj.group('key').upper()
                    v = matchobj.group('value')
                    # delete key when empty value
                    if not v:
                        if k in self.mapkeys:
                            del self.mapkeys[k]
                    else:
                        self.mapkeys[k] = (v.strip(),)
                elif not re_comment.match(line):
                    raise ClewnError('invalid line in %s: %s' % (path, line))
            f.close()
        except IOError:
            critical('reading %s', path); raise

    def cmd_help(self, *args):
        """Print help on all pyclewn commands in the Vim debugger
        console."""
        unused = args
        for cmd in sorted(self.pyclewn_cmds):
            if cmd:
                method = getattr(self, 'cmd_%s' % cmd, None)
                if method is not None:
                    doc = ''
                    if method.__doc__ is not None:
                        doc = method.__doc__.split('\n')[0]
                    self.console_print('%s -- %s\n', cmd, doc)

    def cmd_dumprepr(self, *args):
        """Print debugging information on netbeans and the debugger."""
        unused = args
        self.console_print(
                'netbeans:\n%s\n' % misc.pformat(self.__nbsock.__dict__)
                + '%s:\n%s\n' % (self.__class__.__name__.lower(), self))
        self.print_prompt()

    def cmd_mapkeys(self, *args):
        """Map the pyclewn keys."""
        unused = args
        for k in sorted(self.mapkeys):
            self.__nbsock.special_keys(k)

        text = ''
        for k in sorted(self.mapkeys):
            if len(self.mapkeys[k]) == 2:
                comment = ' # ' + self.mapkeys[k][1]
                text += '  %s%s\n' %                        \
                            (('%s : %s' %                   \
                                    (k, self.mapkeys[k][0])).ljust(30), comment)
            else:
                text += '  %s : %s\n' % (k, self.mapkeys[k][0])

        self.console_print(text)
        self.print_prompt()

    def cmd_unmapkeys(self, *args):
        """Unmap the pyclewn keys.

        This is actually a Vim command and it does not involve pyclewn.

        """
        pass

    def __str__(self):
        """Return the string representation."""
        shallow = copy.copy(self.__dict__)
        for name in ('cmds', 'pyclewn_cmds', 'mapkeys'):
            if name in shallow:
                del shallow[name]
        return misc.pformat(shallow)

