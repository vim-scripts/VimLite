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

"""The Gdb debugger is a frontend to GDB/MI.
"""

import os
import os.path
import subprocess
import re
import string
import time
import collections

from clewn import *
import clewn.asyncproc as asyncproc
import clewn.gdbmi as gdbmi
import clewn.misc as misc
import clewn.debugger as debugger
if os.name == 'posix':
    from clewn.posix import ProcessChannel
else:
    from asyncproc import ProcessChannel

if os.name == 'nt':
    # On Windows, the best timer is time.clock()
    _timer = time.clock
else:
    # On most other platforms the best timer is time.time()
    _timer = time.time

# minimum gdb version
GDB_VERSION = '6.2.1'
Unused = GDB_VERSION

# gdb initial settings
GDB_INIT = """
set confirm off
set height 0
set width 0
set annotate 1
"""
if os.name == 'nt':
    GDB_INIT += 'set new-console on\n'
SYMBOL_COMPLETION_TIMEOUT = 20 # seconds
SETFMTVAR_FORMATS = ('binary', 'decimal', 'hexadecimal', 'octal', 'natural')

# list of key mappings, used to build the .pyclewn_keys.gdb file
#     key : (mapping, comment)
MAPKEYS = {
    'C-Z' : ('sigint',
                'kill the inferior running program'),
    'S-B' : ('info breakpoints',),
    'S-L' : ('info locals',),
    'S-A' : ('info args',),
    'S-S' : ('step',),
    'C-N' : ('next',),
    'S-F' : ('finish',),
    'S-R' : ('run',),
    'S-Q' : ('quit',),
    'S-C' : ('continue',),
    'S-X' : ('foldvar ${lnum}',
                'expand/collapse a watched variable'),
    'S-W' : ('where',),
    'C-U' : ('up',),
    'C-D' : ('down',),
    'C-B' : ('break "${fname}":${lnum}',
                'set breakpoint at current line'),
    'C-E' : ('clear "${fname}":${lnum}',
                'clear breakpoint at current line'),
    'C-P' : ('print ${text}',
                'print value of selection at mouse position'),
    'C-X' : ('print *${text}',
                'print value referenced by word at mouse position'),
}

RE_VERSION = r'GNU\s*gdb[^\d]*(?P<version>[0-9.]+)'            \
             r'# RE: gdb version'
RE_COMPLETION = r'^(?P<cmd>\S+)\s*(?P<arg>\S+)(?P<rest>.*)$'    \
                r'# RE: cmd 1st_arg_completion'
RE_MIRECORD = r'^(?P<token>\d\d\d)[\^*+=](?P<result>.*)$'       \
              r'# gdb/mi record'
RE_ANNO_1 = r'^[~@&]"\\032\\032([a-zA-Z]:|)[^:]+:[^:]+:[^:]+:[^:]+:[^:]+$'  \
            r'# annotation level 1'                                         \
            r'# ^Z^ZFILENAME:LINE:CHARACTER:MIDDLE:ADDR'                    \
            r'# ^Z^ZD:FILENAME:LINE:CHARACTER:MIDDLE:ADDR'

# compile regexps
re_version = re.compile(RE_VERSION, re.VERBOSE|re.MULTILINE)
Unused = re_version
re_completion = re.compile(RE_COMPLETION, re.VERBOSE)
re_mirecord = re.compile(RE_MIRECORD, re.VERBOSE)
re_anno_1 = re.compile(RE_ANNO_1, re.VERBOSE)

CWINDOW = """
" open the quickfix window of breakpoints
function s:cwindow()
    let l:gp=&gp
    let l:gfm=&gfm
    set gp=${gp}
    set gfm=%f:%l:%m
    grep
    let &gp=l:gp
    let &gfm=l:gfm
    cwindow
endfunction

command! -bar ${pre}cwindow call s:cwindow()

"""

SYMCOMPLETION = """
" print a warning message on vim command line
function s:message(msg)
    echohl WarningMsg
    echon a:msg
    let v:warningmsg = a:msg
    echohl None
endfunction

function s:prompt(msg)
    call s:message(a:msg)
    echon "\\nPress ENTER to continue."
    call getchar()
endfunction

" the symbols completion list
let s:symbols= ""

" the custom complete function
function s:Arg_break(A, L, P)
    return s:symbols
endfunction

" get the symbols completion list and define the new
" break and clear vim user defined commands
function s:symcompletion()
    call writefile([], ${ack_tmpfile})
    let start = localtime()
    let loadmsg = "\\rLoading gdb symbols"
    call s:nbcommand("symcompletion")
    while 1
        let loadmsg = loadmsg . "."
        call s:message(loadmsg)

        " pyclewn signals that complete_tmpfile is ready for reading
        if getfsize(${ack_tmpfile}) > 0
            " ignore empty list
            if join(readfile(${ack_tmpfile}), "") != "Ok"
                call s:prompt("\\nNo symbols found.")
                break
            endif
            let s:symbols_list = readfile(${complete_tmpfile})
            let s:symbols= join(s:symbols_list, "\\n")
            command! -bar -nargs=* -complete=custom,s:Arg_break     \
                ${pre}break call s:nbcommand("break", <f-args>)
            command! -bar -nargs=* -complete=custom,s:Arg_break     \
                ${pre}clear call s:nbcommand("clear", <f-args>)
            call s:prompt("\\n" . len(s:symbols_list)               \
                    . " symbols fetched for break and clear completion.")
            break
        endif

        " time out has expired
        if localtime() - start > ${complete_timeout}
            call s:prompt("\\nCannot get symbols completion list.")
            break
        endif
        sleep 300m
    endwhile
endfunction

command! -bar ${pre}symcompletion call s:symcompletion()

"""

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('gdb')

def tmpfile():
    """Return a closed file object to a new temporary file."""
    f = None
    try:
        f = misc.TmpFile('gdb')
        f.write('\n')
    finally:
        if f:
            f.close()
    return f

def unwrap_stream_record(lines):
    """Remove the stream record wrapper from each line.

    Return 'lines' unchanged, if one of them is not a stream record.

    """
    unwrapped = []
    for line in lines.splitlines():
        if line:
            # ignore an ASYNC-RECORD
            if line[0] in '*+=':
                continue
            elif line.startswith('~"') and line.endswith(r'\n"'):
                line = line[2:-3]
            else:
                return lines
            unwrapped.append(line)
    return '\n'.join(unwrapped)

def gdb_batch(pgm, job):
    """Run job in gdb batch mode and return the result as a string."""
    # create the gdb script as a temporary file
    f = None
    try:
        f = misc.TmpFile('gdbscript')
        f.write(job)
    finally:
        if f:
            f.close()

    result = None
    try:
        result = subprocess.Popen((pgm, '--interpreter=mi',
                                        '-batch', '-nx', '-x', f.name),
                                    stdin=subprocess.PIPE,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE).communicate()[0]
    except OSError:
        raise ClewnError('cannot start gdb as "%s"' % pgm)

    return result

@misc.previous_evaluation
def gdb_version(pgm):
    """Check that the gdb version is valid.

    gdb 6.1.1 and below are rejected because:
        gdb 6.1.1:error,msg='Undefined mi command:
                file-list-exec-source-files (missing implementation)'

    """
    # check first tty access rights
    # (gdb does the same on forking the debuggee)
    if hasattr(os, 'ttyname'):
        try:
            ttyname = os.ttyname(0)
        except OSError, err:
            info('No terminal associated with stdin: %s', err)
        else:
            try:
                f = open(ttyname, 'rw')
                f.close()
            except IOError, err:
                raise ClewnError("Gdb cannot open the terminal: %s" % err)

    version = None
    header = gdb_batch(pgm, 'show version')
    if header:
        matchobj = re_version.search(unwrap_stream_record(header))
        if matchobj:
            version = matchobj.group('version')

    if not version:
        if header:
            critical('response to "show version":\n%s%s%s',
                        '***START***\n',
                        header,
                        '***END***\n')
        raise ClewnError('cannot find the gdb version')
    elif version.split('.') < GDB_VERSION.split('.'):
        raise ClewnError('invalid gdb version "%s"' % version)
    else:
        info('gdb version: %s', version)
        return version

class GlobalSetup(misc.Singleton):
    """Container for gdb data constant across all Gdb instances.

    Class attributes:
        filename_complt: tuple
            list of gdb commands with file name completion
        illegal_cmds: tuple
            list of gdb illegal commands
        run_cmds: tuple
            list of gdb commands that cause the frame sign to be turned off
        illegal_setargs: tuple
            list of illegal arguments to the gdb set command
        symbol_complt: tuple
            list of gdb commands with symbol completion
            they are initialized with file name completion and are set to
            symbol completion after running the Csymcompletion pyclewn command

    Instance attributes:
        gdbname: str
            gdb program name to execute
        cmds: dict
            See the description of the Debugger 'cmds' attribute dictionary.
        f_bps: closed file object
            temporary file used to store the list of breakpoints
        f_ack: closed file object
            temporary file used to acknowledge the end of writing to f_clist
        f_clist: closed file object
            temporary file containing the symbols completion list
        illegal_cmds_prefix: list
            List of the illegal command prefix built from illegal_cmds and the
            list of commands
        run_cmds_prefix: list
            List of the run command prefix built from run_cmds and the
            list of commands
        illegal_setargs_prefix: list
            List of the illegal arguments to the set command, built from
            illegal_setargs and the list of the 'set' arguments

    """

    # defeating pychecker check on non-initialized data members
    _cmds = None
    _illegal_cmds_prefix = None
    _run_cmds_prefix = None
    _illegal_setargs_prefix = None
    _f_bps = None
    _f_ack = None
    _f_clist = None

    filename_complt = (
        'cd',
        'directory',
        'file',
        'load',
        'make',
        'path',
        'restore',
        'run',
        'source',
        'start',
        'tty',
        )
    illegal_cmds = (
        '-', '+', '<', '>',
        'commands',
        'complete',
        'define',
        'edit',
        'end',
        # tui commands
        'layout',
        'focus',
        'fs',
        'refresh',
        'tui',
        'update',
        'winheight',
        )
    run_cmds = (
        'attach', 'detach', 'kill',
        'run', 'start', 'continue', 'fg', 'step', 'next', 'finish', 'until', 'advance',
        'jump', 'signal', 'return',
        'file', 'exec-file', 'core-file',
        )
    illegal_setargs = (
        'annotate',
        'confirm',
        'height',
        'width',
        )
    symbol_complt = (
        'break',
        'clear',
        )

    def init(self, gdbname, pyclewn_cmds):
        """Singleton initialisation."""
        self.gdbname = gdbname
        self.pyclewn_cmds = pyclewn_cmds

        self.cmds = self._cmds = {}
        self.illegal_cmds_prefix = []
        self.run_cmds_prefix = []
        self.illegal_setargs_prefix = []

        self.gdb_cmds()

        self._illegal_cmds_prefix = self.illegal_cmds_prefix
        self._run_cmds_prefix = self.run_cmds_prefix
        self._illegal_setargs_prefix = self.illegal_setargs_prefix

        self._f_bps = tmpfile()
        self._f_ack = tmpfile()
        self._f_clist = tmpfile()

    def __init__(self, gdbname, pyclewn_cmds):
        """Constructor."""
        self.gdbname = gdbname
        self.pyclewn_cmds = pyclewn_cmds

        # tricking pychecker
        self.cmds = self._cmds
        self.illegal_cmds_prefix = self._illegal_cmds_prefix
        self.run_cmds_prefix = self._run_cmds_prefix
        self.illegal_setargs_prefix = self._illegal_setargs_prefix
        self.f_bps = self._f_bps
        self.f_ack = self._f_ack
        self.f_clist = self._f_clist

    def gdb_cmds(self):
        """Get the completion lists from gdb and build the GlobalSetup lists.

        Build the following lists:
            cmds: gdb commands
            illegal_cmds_prefix
            run_cmds_prefix
            illegal_setargs_prefix

        """
        dash_cmds = []  # list of gdb commands including a '-'
        firstarg_complt = ''

        nocomplt_cmds = (self.illegal_cmds + self.filename_complt +
                                                        self.symbol_complt)
        # get the list of gdb commands
        cmdlist = unwrap_stream_record(gdb_batch(self.gdbname, 'complete'))
        for cmd in cmdlist.splitlines():
            if not cmd:
                continue
            else:
                cmd = cmd.split()[0]

            if cmd in nocomplt_cmds:
                continue
            elif '-' in cmd:
                dash_cmds.append(cmd)
            else:
                self.cmds[cmd] = []
                firstarg_complt += 'complete %s \n' % cmd

        # get first arg completion commands
        cmdlist = unwrap_stream_record(gdb_batch(self.gdbname, firstarg_complt))
        for result in cmdlist.splitlines():
            matchobj = re_completion.match(result)
            if matchobj:
                cmd = matchobj.group('cmd')
                arg = matchobj.group('arg')
                rest = matchobj.group('rest')
                if not rest:
                    self.cmds[cmd].append(arg)
                else:
                    warning('invalid completion returned by gdb: %s', result)
            else:
                error('invalid completion returned by gdb: %s', result)

        # add file name completion commands
        for cmd in self.filename_complt:
            self.cmds[cmd] = None
        for cmd in self.symbol_complt:
            self.cmds[cmd] = None

        # add commands including a '-' and that can't be made to a vim command
        self.cmds[''] = dash_cmds

        # add pyclewn commands
        for cmd, completion in self.pyclewn_cmds.iteritems():
            if cmd and cmd != 'help':
                self.cmds[cmd] = completion

        keys = self.cmds.keys()
        self.illegal_cmds_prefix = set([misc.smallpref_inlist(x, keys)
                                            for x in self.illegal_cmds])

        keys = list(set(keys).difference(set(self.run_cmds)))
        self.run_cmds_prefix = set([misc.smallpref_inlist(x, keys)
                                            for x in self.run_cmds])

        if 'set' in self.cmds and self.cmds['set']:
            # remove the illegal arguments
            self.cmds['set'] = list(
                                    set(self.cmds['set'])
                                    .difference(set(self.illegal_setargs)))
            setargs = self.cmds['set']
            self.illegal_setargs_prefix = set(
                                        [misc.smallpref_inlist(x, setargs)
                                            for x in self.illegal_setargs])

class Gdb(debugger.Debugger, ProcessChannel):
    """The Gdb debugger is a frontend to GDB/MI.

    Instance attributes:
        version: str
            current gdb version
        state: enum
            gdb state
        pgm: str
            gdb command or pathname
        arglist: list
            gdb command line arguments
        globaal: GlobalSetup
            gdb global data
        results: gdbmi.Result
            storage for expected pending command results
        oob_list: gdbmi.OobList
            list of OobCommand instances
        cli: gdbmi.CliCommand
            the CliCommand instance
        info: gdbmi.Info
            container for the debuggee state information
        gdb_busy: boolean
            False when gdb is ready to accept commands
        oob: iterator
            iterator over the list of OobCommand and VarObjCmd instances
        stream_record: list
            list of gdb/mi stream records output by a command
        lastcmd: gdbmi.MiCommand or gdbmi.CliCommand or gdbmi.WhatIs
                 instance
            + the last Command instance whose result is being processed
            + the empty string '' on startup or after a SIGINT
        token: string
            the token of the last gdb/mi result or out of band record
        curcmdline: str
            the current gdb command line
        firstcmdline: None, str or ''
            the first cli command line that starts gdb
        f_init: closed file object
            temporary file containing the gdb initialisation script
        time: float
            time of the startup of the sequence of oob commands
        multiple_choice: float
            time value, keeping track of a breakpoint multiple choice setting
            on an overloaded class method
        cmd_fifo: deque
            fifo of (method, cmd, args) tuples.
        async: boolean
            when True, store the commands in the cmd_fifo
        dereference: boolean
            when True (the default), dereference pointers in balloon evaluation
        project: string
            project file pathname
        foldlnum: int
            line number of the current fold operation
        doprompt: boolean
            True when the prompt must be printed to the console

    """

    # gdb states
    STATE_INIT, STATE_RUNNING, STATE_QUITTING, STATE_CLOSING = range(4)

    def __init__(self, *args):
        """Constructor."""
        debugger.Debugger.__init__(self, *args)
        self.pyclewn_cmds.update(
            {
                'dbgvar':(),
                'delvar':(),
                'foldvar':(),
                'setfmtvar':(),
                'project':True,
                'sigint':(),
                'cwindow':(),
                'symcompletion':(),
            })
        self.mapkeys.update(MAPKEYS)

        self.state = self.STATE_INIT
        self.pgm = self.options.pgm or 'gdb'
        self.arglist = self.options.args
        self.version = gdb_version(self.pgm)
        self.f_init = None
        ProcessChannel.__init__(self, self.getargv())

        self.info = gdbmi.Info(self)
        self.globaal = GlobalSetup(self.pgm, self.pyclewn_cmds)
        self.cmds = self.globaal.cmds
        self.results = gdbmi.Result()
        self.oob_list = gdbmi.OobList(self)
        self.cli = gdbmi.CliCommand(self)
        self.gdb_busy = True
        self.oob = None
        self.stream_record = []
        self.lastcmd = ''
        self.doprompt = False
        self.token = ''
        self.curcmdline = ''
        self.firstcmdline = None
        self.time = None
        self.multiple_choice = 0
        self.cmd_fifo = collections.deque()
        self.async = False
        self.dereference = True
        self.project = ''
        self.foldlnum = None
        self.parse_paramlist(self.options.gdb)

        # schedule the first 'gdb_background_jobs' method
        self.timer(self.gdb_background_jobs, debugger.LOOP_TIMEOUT)

    def parse_paramlist(self, parameters):
        """Process the class parameter list."""
        for param in [x.strip() for x in parameters.split(',') if x]:
            param_lower = param.lower()
            if param_lower == 'async':
                self.async = True
                continue
            elif param_lower == 'nodereference':
                self.dereference = False
                continue

            pathname = os.path.expanduser(param)
            if os.path.isabs(pathname)          \
                        or pathname.startswith(os.path.curdir):
                if not os.path.isdir(pathname)  \
                        and os.path.isdir(os.path.dirname(pathname)):
                    if not self.project:
                        if os.path.isfile(pathname):
                            try:
                                f = open(pathname, 'r+b')
                                f.close()
                            except IOError, err:
                                raise ClewnError(
                                        'project file %s: %s' % (param, err))
                        self.project = pathname
                        continue
                    raise ClewnError(
                                'cannot have two project file names:'
                                        ' %s and %s' % (self.project, param))
                raise ClewnError(
                        'not a valid project file pathname: %s' % param)
            raise ClewnError(
                    'invalid parameter for the \'--gdb\' option: %s' % param)

    def getargv(self):
        """Return the gdb argv list."""
        argv = [self.pgm]
        if os.name != 'nt':
            argv += ['-tty=%s' % self.options.tty]

        # build the gdb init temporary file
        try:
            self.f_init = misc.TmpFile('gdbscript')
            self.f_init.write(GDB_INIT)
        finally:
            if self.f_init:
                self.f_init.close()

        argv += ['-x'] + [self.f_init.name] + ['--interpreter=mi']
        if self.arglist:
            argv += self.arglist
        return argv

    def vim_script_custom(self, prefix):
        """Return gdb specific vim statements to add to the vim script.

        This is used to load the symbols completion list to the break and clear
        gdb commands.

        """
        symcompletion = string.Template(SYMCOMPLETION).substitute(pre=prefix,
                        ack_tmpfile=misc.quote(self.globaal.f_ack.name),
                        complete_tmpfile=misc.quote(self.globaal.f_clist.name),
                        complete_timeout=SYMBOL_COMPLETION_TIMEOUT)

        if os.name == 'nt':
            grepprg = 'cmd\\ /c\\ type'
        else:
            grepprg = 'cat'
        grepprg += '\\ ' + self.globaal.f_bps.name
        cwindow = string.Template(CWINDOW).substitute(pre=prefix, gp=grepprg)

        return symcompletion + cwindow

    def _start(self):
        """Start gdb."""
        debugger.Debugger._start(self)
        ProcessChannel.start(self)

    def prompt(self):
        """Print the prompt."""
        if not self.gdb_busy:   # print prompt only after gdb has started
            debugger.Debugger.prompt(self)

    @debugger.restart_timer(debugger.LOOP_TIMEOUT)
    def gdb_background_jobs(self):
        """Run a scheduled job on a timer event.

        Set all breakpoints on a multiple choice after a timeout.
        Pop a command from the fifo and run it.

        """
        if self.multiple_choice:
            if _timer() - self.multiple_choice > 0.500:
                self.multiple_choice = 0
                self.write('1\n')
            # do not pop a command from fifo while multiple_choice pending
            return

        if self.cmd_fifo and self.accepting_cmd():
            (method, cmd, args) = self.cmd_fifo.popleft()
            debugger.Debugger._do_cmd(self, method, cmd, args)

    def accepting_cmd(self):
        """Return True when gdb is ready to process a new command."""
        return not self.gdb_busy and self.oob is None

    def terminate_cmd(self):
        """Do the command end processing."""
        self.gdb_busy = False
        self.multiple_choice = 0
        if self.doprompt:
            self.doprompt = False
            self.prompt()

        # source the project file
        if self.state == self.STATE_INIT:
            self.state = self.STATE_RUNNING
            if self.project:
                self.clicmd_notify('source %s' % self.project)
                return

        # send the first cli command line
        if self.firstcmdline:
            self.clicmd_notify(self.firstcmdline)
        self.firstcmdline = ''

        varobj = self.info.varobj
        debugger.Debugger.update_dbgvarbuf(
                self, varobj.collect, varobj.dirty, self.foldlnum)
        self.foldlnum = None

        if self.time is not None:
            info('oob commands execution: %f second' % (_timer() - self.time))
            self.time = None

    def handle_strrecord(self, cmd):
        """Process the stream records."""
        stream_record = ''.join(self.stream_record)
        if stream_record:
            cmd.handle_strrecord(stream_record)
        self.stream_record = []

    def handle_line(self, line):
        """Process the line received from gdb."""
        if self.fileasync is None:
            return

        debug(line)
        if not line:
            error('handle_line: processing an empty line')
            return

        # gdb/mi stream record
        if line.startswith('> ~"'):
            # remove the '> ' prompt after a multiple choice
            line = line[2:]
        if line[0] in '~@':
            self.process_stream_record(line)
        elif line[0] in '&':
            # ignore a 'log' stream record
            matchobj = misc.re_quoted.match(line[1:])
            if matchobj:
                line = misc.unquote(matchobj.group(1))
                info(line)
            else:
                warning('bad format in gdb/mi log: "%s"', line)
        elif line[0] in '*+=':
            # ignore ''async' records
            info(line[1:])
        else:
            matchobj = re_mirecord.match(line)
            # a gdb/mi result or out of band record
            if matchobj:
                self.process_mi_record(matchobj)
            # gdb/mi prompt
            elif line == '(gdb) ':
                self.process_prompt()
            else:
                # on Windows, the inferior output is redirected by gdb
                # to the pipe when 'new-console' is not set
                warning('handle_line: bad format: "%s"', line)

    def process_stream_record(self, line):
        """Process a received gdb/mi stream record."""
        matchobj = misc.re_quoted.match(line[1:])
        annotation_lvl1 = re_anno_1.match(line)
        if annotation_lvl1 is not None:
            return
        if matchobj:
            line = misc.unquote(matchobj.group(1))
            if (not self.stream_record and line == '[0] cancel\n[1] all\n') \
                    or (not self.multiple_choice                            \
                            and len(self.stream_record) == 1                \
                            and self.stream_record[0] == '[0] cancel\n'     \
                            and line.startswith('[1] all\n')):
                self.multiple_choice = _timer()
            self.stream_record.append(line)
        else:
            warning('process_stream_record: bad format: "%s"', line)

    def process_mi_record(self, matchobj):
        """Process a received gdb/mi record."""
        token = matchobj.group('token')
        result = matchobj.group('result')
        cmd = self.results.remove(token)
        if cmd is None:
            if token == self.token:
                # ignore received duplicate token
                pass
            elif self.state != self.STATE_QUITTING:
                # may occur on quitting with the debuggee still running
                raise ClewnError('invalid token "%s"' % token)
        else:
            self.token = token
            if isinstance(cmd, (gdbmi.CliCommand, gdbmi.MiCommand,
                                                        gdbmi.WhatIs)):
                self.lastcmd = cmd

            self.handle_strrecord(cmd)
            cmd.handle_result(result)

            self.process_oob()

    def process_prompt(self):
        """Process the gdb/mi prompt."""
        # process all the stream records
        cmd = self.lastcmd or self.cli
        self.handle_strrecord(cmd)

        # starting or after a SIGINT
        if self.lastcmd == '':
            self.process_oob()

    def process_oob(self):
        """Process OobCommands."""
        # got the prompt for a user command
        if self.lastcmd is not None:
            # prepare the next sequence of oob commands
            self.time = _timer()
            self.oob = self.oob_list.iterator()
            if len(self.results):
                if self.state != self.STATE_QUITTING:
                    # may occur on quitting with the debuggee still running
                    error('all cmds have not been processed in results')
                self.results.clear()

            if not isinstance(self.lastcmd, (gdbmi.CliCommandNoPrompt,
                                                            gdbmi.WhatIs)):
                self.doprompt = True

            self.lastcmd = None

        # send the next oob command
        if self.oob is not None:
            try:
                # loop over oob commands that don't send anything
                while True:
                    if self.oob.next()():
                        break
            except StopIteration:
                self.oob = None
                self.terminate_cmd()

    def clicmd_notify(self, cmd, console=True, gdb=True):
        """Send a cli command after having notified the OobCommands.

        When 'console' is True, print 'cmd' on the console.
        When 'gdb' is True, send the command to gdb, otherwise send
        an empty command.

        """
        if console:
            self.console_print("%s\n", cmd)
        # notify each OobCommand instance
        for oob in self.oob_list:
            oob.notify(cmd)
        if gdb:
            self.cli.sendcmd(cmd)
        else:
            gdbmi.CliCommandNoPrompt(self).sendcmd('')

    def write(self, data):
        """Write data to gdb."""
        ProcessChannel.write(self, data)
        debug(data.rstrip('\n'))

    def close(self):
        """Close gdb."""
        # This method may be called by the SIGCHLD handler and therefore must be
        # reentrant.
        if self.state == self.STATE_RUNNING:
            self.cmd_quit()
            return

        if self.state == self.STATE_CLOSING and not self.closed:
            debugger.Debugger.close(self)
            ProcessChannel.close(self)

            # clear varobj
            rootvarobj = self.info.varobj
            cleared = rootvarobj.clear()
            self.update_dbgvarbuf(rootvarobj.collect, cleared)

            # remove temporary files
            try:
                del self.f_init
            except AttributeError:
                pass

    #-----------------------------------------------------------------------
    #   commands
    #-----------------------------------------------------------------------

    def _do_cmd(self, method, cmd, args):
        """Process 'cmd' and its 'args' with 'method'.

        Execute directly the command when running in non-async mode.
        Otherwise, flush the cmd_fifo on receiving a sigint and send it,
        or queue the command to the fifo.
        """
        if method == self.cmd_sigint:
            self.lastcmd = ''

        if not self.async:
            debugger.Debugger._do_cmd(self, method, cmd, args)
            return

        if method == self.cmd_sigint:
            self.cmd_fifo.clear()
            debugger.Debugger._do_cmd(self, method, cmd, args)
            return

        # queue the command as a tuple
        self.cmd_fifo.append((method, cmd, args))

    def pre_cmd(self, cmd, args):
        """The method called before each invocation of a 'cmd_xxx' method."""
        self.curcmdline = cmd
        if args:
            self.curcmdline = '%s %s' % (self.curcmdline, args)

        # echo the cmd, but not the first one and when not busy
        if self.firstcmdline is not None and cmd != 'sigint':
            if self.accepting_cmd():
                self.console_print('%s\n', self.curcmdline)

    def post_cmd(self, cmd, args):
        """The method called after each invocation of a 'cmd_xxx' method."""
        pass

    def default_cmd_processing(self, cmd, args):
        """Process any command whose cmd_xxx method does not exist."""
        assert cmd == self.curcmdline.split()[0]
        if misc.any([cmd.startswith(x)
                for x in self.globaal.illegal_cmds_prefix]):
            self.console_print('Illegal command in pyclewn.\n')
            self.prompt()
            return

        if cmd == 'set' and args:
            firstarg = args.split()[0]
            if misc.any([firstarg.startswith(x)
                    for x in self.globaal.illegal_setargs_prefix]):
                self.console_print('Illegal argument in pyclewn.\n')
                self.prompt()
                return

        # turn off the frame sign after a run command
        if misc.any([cmd.startswith(x)
                    for x in self.globaal.run_cmds_prefix])     \
                or misc.any([cmd == x
                    for x in ('d', 'r', 'c', 's', 'n', 'u', 'j')]):
            self.info.update_frame(hide=True)

        if self.firstcmdline is None:
            self.firstcmdline = self.curcmdline
        else:
            self.clicmd_notify(self.curcmdline, console=False)

    def cmd_help(self, *args):
        """Print help on gdb and on pyclewn specific commands."""
        cmd, line = args
        if not line:
            self.console_print('Pyclewn specific commands:\n')
            debugger.Debugger.cmd_help(self, cmd)
            self.console_print('\nGdb help:\n')
        self.default_cmd_processing(cmd, line)

    def cmd_cwindow(self, *args):
        """List the breakpoints in a quickfix window."""
        # never called dummy method, its documentation is used for the help
        unused = self
        unused = args

    def cmd_symcompletion(self, *args):
        """Populate the break and clear commands with symbols completion."""
        unused = args
        gdbmi.CompleteBreakCommand(self).sendcmd()

    def cmd_dbgvar(self, cmd, args):
        """Add a variable to the debugger variable buffer."""
        unused = cmd
        varobj = gdbmi.VarObj({'exp': args})
        if gdbmi.VarCreateCommand(self, varobj).sendcmd():
            self.oob_list.push(gdbmi.VarObjCmdEvaluate(self, varobj))

    def cmd_delvar(self, cmd, args):
        """Delete a variable from the debugger variable buffer."""
        unused = cmd
        args = args.split()
        # one argument is required
        if len(args) != 1:
            self.console_print('Invalid arguments.\n')
        else:
            name = args[0]
            (varobj, varlist) = self.info.varobj.leaf(name)
            unused = varlist
            if varobj is not None:
                gdbmi.VarDeleteCommand(self, varobj).sendcmd()
                return
            self.console_print('"%s" not found.\n' % name)
        self.prompt()

    def cmd_foldvar(self, cmd, args):
        """Collapse/expand a variable from the debugger variable buffer."""
        unused = cmd
        args = args.split()
        errmsg = ''
        # one argument is required
        if len(args) != 1:
            errmsg = 'Invalid arguments.'
        else:
            try:
                lnum = int(args[0])
            except ValueError:
                errmsg = 'Not a line number.'
        if not errmsg:
            rootvarobj = self.info.varobj
            if lnum in rootvarobj.parents:
                varobj = rootvarobj.parents[lnum]
                # collapse
                if varobj['children']:
                    for child in varobj['children'].values():
                        self.oob_list.push(gdbmi.VarObjCmdDelete(self, child))
                    # nop command used to trigger execution of the oob_list
                    if not gdbmi.NumChildrenCommand(self, varobj).sendcmd():
                        return
                # expand
                else:
                    if not gdbmi.ListChildrenCommand(self, varobj).sendcmd():
                        return
                self.foldlnum = lnum
                return
            else:
                errmsg = 'Not a valid line number.'
        if errmsg:
            self.console_print('%s\n' % errmsg)
        self.prompt()

    def cmd_setfmtvar(self, cmd, args):
        """Set the output format of the value of the watched variable."""
        unused = cmd
        args = args.split()
        # two arguments are required
        if len(args) != 2:
            self.console_print('Invalid arguments.\n')
        else:
            name = args[0]
            format = args[1]
            if format not in SETFMTVAR_FORMATS:
                self.console_print(
                    '\'%s\' is an invalid format, must be one of %s.\n'
                                            % (format, SETFMTVAR_FORMATS))
            else:
                (varobj, varlist) = self.info.varobj.leaf(name)
                unused = varlist
                if varobj is not None:
                    if gdbmi.VarSetFormatCommand(self, varobj).sendcmd(format):
                        self.oob_list.push(gdbmi.VarObjCmdEvaluate(self, varobj))
                    return
                self.console_print('"%s" not found.\n' % name)
        self.prompt()

    def cmd_project(self, cmd, args):
        """Save information to a project file."""
        if not args:
            self.console_print('Invalid argument.\n')
            self.prompt()
            return
        self.clicmd_notify('%s %s\n' % (cmd, args), console=False, gdb=False)
        self.gdb_busy = False

    def cmd_quit(self, *args):
        """Quit gdb."""
        unused = args
        if self.state == self.STATE_INIT:
            self.console_print("Ignoring 'quit' command on startup.\n")
            return


        # handle abnormal termination of gdb
        if hasattr(self, 'pid_status') and self.pid_status:
            self.state = self.STATE_CLOSING
            self.console_print('\n%s\n', self.pid_status)
            # save the project file
            if self.project:
                pobj = gdbmi.Project(self)
                pobj.notify('project %s' % self.project)
                pobj()
            self.console_print("Closing this gdb session.\n")
            self.console_print('\n===========\n')
            self.console_flush()
            self.close()
            return

        # Attempt to save the project file.
        # When oob commands are being processed, or gdb is busy in a
        # 'continue' statement, the project file is not saved.
        # The clicmd_notify nop command must not be run in this case, to
        # avoid breaking pyclewn state (assert on self.gdb_busy).
        self.state = self.STATE_QUITTING
        self.sendintr()
        if not self.gdb_busy and self.oob is None:
            if self.project:
                self.clicmd_notify('project %s' % self.project,
                                        console=False, gdb=False)
            else:
                self.clicmd_notify('dummy', console=False, gdb=False)
        else:
            self.state = self.STATE_CLOSING
            self.close()

    def cmd_sigint(self, *args):
        """Send a <C-C> character to the debugger."""
        unused = args
        if self.state == self.STATE_INIT:
            self.console_print("Ignoring 'sigint' command on startup.\n")
            return

        self.sendintr()
        if self.ttyname is None:
            self.cmd_sigint.im_func.__doc__ = \
                'Command ignored: gdb does not handle interrupts over pipes.'
            self.console_print('\n%s\n', self.cmd_sigint.__doc__)
            if os.name == 'posix':
                self.console_print('To interrupt the program being debugged, '
                    'send a SIGINT signal\n'
                    'from the shell. For example, type from the vim command'
                    ' line:\n'
                    '    :!kill -SIGINT $(pgrep program_name)\n'
                )
        self.console_print("Quit\n")

    #-----------------------------------------------------------------------
    #   netbeans events
    #-----------------------------------------------------------------------

    def balloon_text(self, text):
        """Process a netbeans balloonText event."""
        debugger.Debugger.balloon_text(self, text)
        if self.info.frame:
            gdbmi.WhatIs(self, text).sendcmd()

