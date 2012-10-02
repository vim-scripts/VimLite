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

"""Contain classes that implement the gdb commands.

A Gdb command may be an:
    * instance of CliCommand
    * instance of MiCommand
    * instance of WhatIs
A Gdb command triggers execution of out of band (oob) commands.

An oob command may be an:
    * instance of OobCommand
    * instance of VarObjCmd
    * instance of ShowBalloon
OobCommand instances are part of a static list in OobList, while VarObjCmd and
ShowBalloon instances are pushed into this list dynamically.

The oob commands fetch from gdb, using gdb/mi, the information required to
maintain the state of the breakpoints table, the varobj data, ...
The instance of the Info class contains all this data.

The oob commands also perform actions such as: source the project file, update
the breakpoints and frame sign, create/delete/update the varobj objects.

"""

import os
import os.path
import re
import cStringIO
import collections

import clewn.misc as misc

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('mi')
Unused = critical

VAROBJ_FMT = '%%(name)-%ds: (%%(type)-%ds) %%(exp)-%ds %%(chged)s %%(value)s\n'

BREAKPOINT_CMDS = ()
FILE_CMDS = ()
FRAME_CMDS = ()
VARUPDATE_CMDS = ()

DIRECTORY_CMDS = (
    'directory',
    'source')

SOURCE_CMDS = (
    'r', 'start',
    'file', 'exec-file', 'core-file', 'symbol-file', 'add-symbol-file',
    'source')

PROJECT_CMDS = tuple(['project'] + list(SOURCE_CMDS))

# gdb objects attributes
BREAKPOINT_ATTRIBUTES = set(('number', 'type', 'enabled', 'file', 'line',
                             'original-location'))
REQ_BREAKPOINT_ATTRIBUTES = set(('number', 'type', 'enabled'))
FILE_ATTRIBUTES = set(('line', 'file', 'fullname'))
FRAMECLI_ATTRIBUTES = set(('level', 'func', 'file', 'line',))
FRAME_ATTRIBUTES = set(('level', 'func', 'file', 'line', 'fullname',))
SOURCES_ATTRIBUTES = set(('file', 'fullname'))
VARUPDATE_ATTRIBUTES = set(('name', 'in_scope'))
VARCREATE_ATTRIBUTES = set(('name', 'numchild', 'type'))
VARLISTCHILDREN_ATTRIBUTES = set(('name', 'exp', 'numchild', 'value', 'type'))
VAREVALUATE_ATTRIBUTES = set(('value',))

def keyval_pattern(attributes, comment=''):
    """Build and return a keyval pattern string."""
    unused = comment
    return '(' + '|'.join(attributes) + ')=' + misc.QUOTED_STRING

# regexp
RE_COMPLETION = r'^break\s*(?P<sym>[\w:]*)(?P<sig>\(.*\))?(?P<rest>.*)$'    \
                r'# break symbol completion'

RE_EVALUATE = r'^done,value="(?P<value>.*)"$'                               \
              r'# result of -data-evaluate-expression'

RE_DICT_LIST = r'{[^}]+}'                                                   \
               r'# a gdb list'

RE_VARCREATE = keyval_pattern(VARCREATE_ATTRIBUTES,
            'done,name="var1",numchild="0",type="int"')

RE_VARDELETE = r'^done,ndeleted="(?P<ndeleted>\d+)"$'                       \
               r'# done,ndeleted="1"'

RE_SETFMTVAR = r'^done,format="\w+",value="(?P<value>.*)"$'                 \
               r'# done,format="binary",value="1111001000101110110001011110"'

RE_VARLISTCHILDREN = keyval_pattern(VARLISTCHILDREN_ATTRIBUTES)

RE_VAREVALUATE = keyval_pattern(VAREVALUATE_ATTRIBUTES, 'done,value="14"')

RE_ARGS = r'\s*"(?P<args>.+)"\.'                                            \
             r'# "toto "begquot endquot" titi".'

RE_BREAKPOINTS = keyval_pattern(BREAKPOINT_ATTRIBUTES, 'a breakpoint')

RE_DIRECTORIES = r'(?P<path>[^' + os.pathsep + r'^\n]+)'                    \
                 r'# /path/to/foobar:$cdir:$cwd\n'

RE_FILE = keyval_pattern(FILE_ATTRIBUTES,
            'line="1",file="foobar.c",fullname="/home/xdg/foobar.c"')

RE_FRAMECLI = keyval_pattern(FRAMECLI_ATTRIBUTES,
            'frame={level="0",func="main",args=[{name="argc",value="1"},'
            '{name="argv",value="0xbfde84a4"}],file="foobar.c",line="12"}')
RE_FRAME = keyval_pattern(FRAME_ATTRIBUTES)

RE_PGMFILE = r'\s*"(?P<debuggee>[^"]+)"\.'                                  \
             r'# "/path/to/pyclewn/testsuite/foobar".'

RE_PWD = r'"(?P<cwd>[^"]+)"# "/home/xavier/src/pyclewn_wa/trunk/pyclewn"'

RE_SOURCES = keyval_pattern(SOURCES_ATTRIBUTES,
            'files=[{file="foobar.c",fullname="/home/xdg/foobar.c"},'
            '{file="foo.c",fullname="/home/xdg/foo.c"}]')

RE_VARUPDATE = keyval_pattern(VARUPDATE_ATTRIBUTES,
            'changelist='
            '[{name="var3.key",in_scope="true",type_changed="false"}]')

RE_TYPE = r'^type\s=\s(?P<name>\w+).*?[^*]?(?P<star>\*+)$'                  \
          r'# "type = char *".'

# compile regexps
re_completion = re.compile(RE_COMPLETION, re.VERBOSE)
re_evaluate = re.compile(RE_EVALUATE, re.VERBOSE)
re_dict_list = re.compile(RE_DICT_LIST, re.VERBOSE)
re_varcreate = re.compile(RE_VARCREATE, re.VERBOSE)
re_vardelete = re.compile(RE_VARDELETE, re.VERBOSE)
re_setfmtvar = re.compile(RE_SETFMTVAR, re.VERBOSE)
re_varlistchildren = re.compile(RE_VARLISTCHILDREN, re.VERBOSE)
re_varevaluate = re.compile(RE_VAREVALUATE, re.VERBOSE)
re_args = re.compile(RE_ARGS, re.VERBOSE)
re_breakpoints = re.compile(RE_BREAKPOINTS, re.VERBOSE)
re_directories = re.compile(RE_DIRECTORIES, re.VERBOSE)
re_file = re.compile(RE_FILE, re.VERBOSE)
re_framecli = re.compile(RE_FRAMECLI, re.VERBOSE)
re_frame = re.compile(RE_FRAME, re.VERBOSE)
re_pgmfile = re.compile(RE_PGMFILE, re.VERBOSE)
re_pwd = re.compile(RE_PWD, re.VERBOSE)
re_sources = re.compile(RE_SOURCES, re.VERBOSE)
re_varupdate = re.compile(RE_VARUPDATE, re.VERBOSE)
re_type = re.compile(RE_TYPE, re.VERBOSE)

def compare_filename(a, b):
    """Compare two filenames."""
    if os.name == 'nt':
        return a.lower() == b.lower()
    else:
        return a == b

def fullname(name, source_dict):
    """Return 'fullname' value, matching name in the source_dict dictionary."""
    try:
        if source_dict and compare_filename(source_dict['file'], name):
            return source_dict['fullname']
    except KeyError:
        pass
    return ''

class VarObjList(misc.OrderedDict):
    """A dictionary of {name:VarObj instance}."""

    def collect(self, parents, lnum, stream, indent=0):
        """Collect all varobj children data.

        Return True when dbgvarbuf must be set as dirty
        for the next update run (for syntax highlighting).

        """
        if not self:
            return False

        # follow positional parameters in VAROBJ_FMT
        table = [(len(x['name']), len(x['type']), len(x['exp']))
                                            for x in self.values()]
        tab = (max([x[0] for x in table]),
                        max([x[1] for x in table]),
                        max([x[2] for x in table]))

        dirty = False
        for name in self.keys():
            status = self[name].collect(parents, lnum, stream, indent, tab)
            if status:
                dirty = True
        return dirty

class RootVarObj(object):
    """The root of the tree of varobj objects.

    Instance attributes:
        root: VarObjList
            the root of all varobj objects
        parents: dict
            dictionary {lnum:varobj parent}
        dirty: boolean
            True when there is a change in the varobj objects
        str_content: str
            string representation of the varobj objects

    """

    def __init__(self):
        """Constructor."""
        self.root = VarObjList()
        self.parents = {}
        self.dirty = False
        self.str_content = ''

    def clear(self):
        """Clear all varobj elements.

        Return False when there were no varobj elements to remove.

        """
        if not self.root:
            return False

        self.root.clear()
        self.parents = {}
        self.dirty = True
        self.str_content = ''
        return True

    def leaf(self, childname):
        """Return childname VarObj and the VarObjList of the parent of childname.

        'childname' is a string with format: varNNN.child_1.child_2....

        """
        branch = childname.split('.')
        l = len(branch)
        assert l
        curlist = self.root
        try:
            for i in range(l):
                name = '.'.join(branch[:i+1])
                if i == l - 1:
                    return (curlist[name], curlist)
                curlist = curlist[name]['children']
        except KeyError:
            warning('bad key: "%s", cannot find "%s" varobj'
                                                % (name, childname))
        return (None, None)

    def collect(self):
        """Return the string representation of the varobj objects.

        This method has the side-effect of building the parents dictionary.

        """
        if self.dirty:
            self.dirty = False
            self.parents = {}
            lnum = [0]
            output = cStringIO.StringIO()
            self.dirty = self.root.collect(self.parents, lnum, output)
            self.str_content = output.getvalue()
            output.close()
        return self.str_content

class VarObj(dict):
    """A gdb/mi varobj object."""

    def __init__(self, vardict={}):
        """Constructor."""
        self['name'] = ''
        self['exp'] = ''
        self['type'] = ''
        self['value'] = ''
        self['chged'] = '={=}'
        self['in_scope'] = 'true'
        self['numchild'] = 0
        self['children'] = VarObjList()
        self.chged = True
        self.update(vardict)

    def collect(self, parents, lnum, stream, indent, tab):
        """Collect varobj data."""
        dirty = False

        if self.chged:
            self['chged'] = '={*}'
            self.chged = False
            dirty = True
        elif self['in_scope'] != 'true':
            self['chged'] = '={-}'
        else:
            self['chged'] = '={=}'

        lnum[0] += 1
        if self['numchild'] != '0':
            parents[lnum[0]] = self
            if self['children']:
                fold = '[-] '
            else:
                fold = '[+] '
        else:
            fold = ' *  '
        format = VAROBJ_FMT % tab
        stream.write(' ' * indent + fold + format % self)
        if self['children']:
            assert self['numchild'] != 0
            status = self['children'].collect(parents, lnum, stream, indent + 2)
            dirty = dirty or status

        return dirty

class Info(object):
    """Container for the debuggee state information.

    It includes the breakpoints table, the varobj data, etc.
    This class is named after the gdb "info" command.

    Instance attributes:
        gdb: gdb.Gdb
            the Gdb debugger instance
        args: list
            the debuggee arguments
        breakpoints: list
            list of breakpoints, result of a previous OobGdbCommand
        bp_dictionary: dict
            breakpoints dictionary, with bp number as key
        cwd: list
            current working directory
        debuggee: list
            program file
        directories: list
            list of gdb directories
        file: dict
            current gdb source attributes
        frame: dict
            gdb frame attributes
        frame_location: dict
            current frame location
        frame_prefix: str
            completion prefix for the 'frame' command
        sources: list
            list of gdb sources
        varobj: RootVarObj
            root of the tree of varobj objects
        changelist: list
            list of changed varobjs

    """

    def __init__(self, gdb):
        """Constructor."""
        self.gdb = gdb
        self.args = []
        self.breakpoints = []
        self.bp_dictionary = {}
        self.cwd = []
        self.debuggee = []
        self.directories = ['$cdir', '$cwd']
        self.file = {}
        self.frame = {}
        self.frame_location = {}
        self.frame_prefix = ''
        self.sources = []
        self.varobj = RootVarObj()
        self.changelist = []
        # _root_varobj is only used for pretty printing with Cdumprepr
        self._root_varobj = self.varobj.root

    def get_fullpath(self, name):
        """Get the full path name for the file named 'name' and return it.

        If name is an absolute path, just stat it. Otherwise, add name to
        each directory in gdb source directories and stat the result.
        Path names are unix normalized with forward slashes.
        """

        # an absolute path name
        if os.path.isabs(name):
            if os.path.exists(name):
                return misc.norm_unixpath(name, True)
            else:
                # strip off the directory part and continue
                name = os.path.split(name)[1]

        if not name:
            return None

        # proceed with each directory in gdb source directories
        for dirname in self.directories:
            if dirname == '$cdir':
                pathname = fullname(name, self.file)
                if not pathname:
                    for source_dict in self.sources:
                        pathname = fullname(name, source_dict)
                        if pathname:
                            break
                    else:
                        continue # main loop
            elif dirname == '$cwd':
                pathname = os.path.abspath(name)
            else:
                pathname = os.path.normpath(name)

            if os.path.exists(pathname):
                return misc.norm_unixpath(pathname, True)

        return None

    def update_breakpoints(self, cmd):
        """Update the breakpoints."""
        unused = cmd
        is_changed = False

        # build the breakpoints dictionary
        bp_dictionary = {}
        for bp in self.breakpoints:
            if 'breakpoint' in bp['type']:
                bp_dictionary[bp['number']] = bp

        nset = set(bp_dictionary.keys())
        oldset = set(self.bp_dictionary.keys())
        # update sign status of common breakpoints
        for num in (nset & oldset):
            state = bp_dictionary[num]['enabled']
            if state != self.bp_dictionary[num]['enabled']:
                is_changed = True
                enabled = (state == 'y')
                self.gdb.update_bp(int(num), not enabled)

        # delete signs for non-existent breakpoints
        for num in (oldset - nset):
            number = int(self.bp_dictionary[num]['number'])
            self.gdb.delete_bp(number)

        # create signs for new breakpoints
        for num in (nset - oldset):
            # when file/line is missing (template function), use the
            # original-location
            if ('line' not in bp_dictionary[num]
                    and 'file' not in bp_dictionary[num]):
                fn, lno = bp_dictionary[num]['original-location'].split(':')
                bp_dictionary[num]['file'] = fn.strip(misc.DOUBLEQUOTE)
                bp_dictionary[num]['line'] = lno

            pathname = self.get_fullpath(bp_dictionary[num]['file'])
            if pathname is not None:
                lnum = int(bp_dictionary[num]['line'])
                self.gdb.add_bp(int(num), pathname, lnum)

        self.bp_dictionary = bp_dictionary

        if (oldset - nset) or (nset - oldset):
            is_changed = True
        if is_changed:
            f_bps = open(self.gdb.globaal.f_bps.name, 'w')
            for num in sorted(bp_dictionary.keys()):
                pathname = self.get_fullpath(bp_dictionary[num]['file'])
                if pathname is not None:
                    lnum = bp_dictionary[num]['line']
                    state = bp_dictionary[num]['enabled']
                    if state == 'y':
                        state = 'enabled'
                    else:
                        state = 'disabled'
                    f_bps.write('%s:%s:breakpoint %s %s\n'
                                        % (pathname, lnum, num, state))
            f_bps.close()

    def update_frame(self, cmd='', hide=False):
        """Update the frame sign."""
        if hide:
            self.frame = {}
        if self.frame and isinstance(self.frame, dict):
            line = int(self.frame['line'])
            # gdb 6.4 and above
            if 'fullname' in self.frame:
                source = self.frame['fullname']
            else:
                fullname = self.file['fullname']
                source = self.frame['file']
                if os.path.basename(fullname) == source:
                    source = fullname
            pathname = self.get_fullpath(source)

            if pathname is not None:
                frame_location = {'pathname':pathname, 'lnum':line}
                if not self.frame_prefix:
                    keys = self.gdb.cmds.keys()
                    keys.remove('frame')
                    self.frame_prefix = misc.smallpref_inlist('frame', keys)
                # when the frame location has changed or when running the
                # 'frame' command
                if (self.frame_location != frame_location or
                            cmd.startswith(self.frame_prefix)):
                    self.gdb.show_frame(**frame_location)
                    self.frame_location = frame_location
                return

        # hide frame sign
        self.gdb.show_frame()
        self.frame_location = {}

    def update_changelist(self, cmd):
        """Process a varobj changelist event."""
        unused = cmd
        for vardict in self.changelist:
            (varobj, varlist) = self.varobj.leaf(vardict['name'])
            unused = varlist
            if varobj is not None:
                varobj['in_scope'] = vardict['in_scope']
                self.gdb.oob_list.push(VarObjCmdEvaluate(self.gdb, varobj))
        if self.changelist:
            self.varobj.dirty = True
            self.changelist = []

    def __repr__(self):
        """Return the pretty formated self dictionary."""
        return misc.pformat(self.__dict__)

class Result(dict):
    """Storage for Command objects whose command has been sent to gdb.

    A dictionary: {token:command}

    Instance attributes:
        token: str
            gdb/mi token number; range 100..199

    """

    def __init__(self):
        """Constructor."""
        self.token = 100

    def add(self, command):
        """Add a command object to the dictionary."""
        assert isinstance(command, Command)
        # do not add an OobGdbCommand if the dictionary contains
        # an object of the same class
        if isinstance(command, OobGdbCommand)  \
                and misc.any([command.__class__ is obj.__class__
                        for obj in self.values()]):
            return None
        t = str(self.token)
        if t in self:
            error('token "%s" already exists as an expected pending result', t)
        self[t] = command
        self.token = (self.token + 1) % 100 + 100
        return t

    def remove(self, token):
        """Remove a command object from the dictionary and return the object."""
        if token not in self:
            # do not report as an error: may occur on quitting
            info('no token "%s" as an expected pending result', token)
            return None
        command = self[token]
        del self[token]
        return command

class OobList(object):
    """List of instances of OobCommand subclasses.

    An instance of OobList return two different types of iterator:
        * implicit: iterator over the list of OobCommand objects
        * through the call to iterator: list of OobCommand objects
          and VarObjCmd objects

    Instance attributes:
        gdb: Gdb
            the Gdb instance
        static_list: list
            ordered list of OobCommand objects
        running_list: list
            list of VarObjCmd objects
        fifo: deque
            fifo of OobCommand and VarObjCmd objects.
            VarObjCmd objects may be pushed into the fifo while
            the fifo iterator is being run.
    """

    def __init__(self, gdb):
        """Constructor."""
        self.running_list = []
        self.fifo = None

        # build the OobCommand objects list
        # object ordering is important
        cmdlist = [
            Args(gdb),
            Directories(gdb),
            File(gdb),
            FrameCli(gdb),      # after File
            Frame(gdb),
            PgmFile(gdb),
            VarUpdate(gdb),     # not last after gdb 7.0
            Pwd(gdb),
            Sources(gdb),
            Breakpoints(gdb),   # after File and Sources
            Project(gdb),
            Quit(gdb),
        ]
        cmdlist = [cmd for cmd in cmdlist if not hasattr(cmd, 'version_min')
                                            or gdb.version >= cmd.version_min]
        self.static_list = [cmd for cmd in cmdlist if not hasattr(cmd,
                            'version_max') or gdb.version <= cmd.version_max]

    def __iter__(self):
        """Return an iterator over the list of OobCommand objects."""
        return self.static_list.__iter__()

    def __len__(self):
        """Length of the OobList."""
        if self.fifo is not None:
            return len(self.fifo)
        return 0

    def iterator(self):
        """Return an iterator over OobCommand and VarObjCmd objects."""
        self.fifo = collections.deque(self.static_list + self.running_list)
        self.running_list = []
        return self

    def next(self):
        """Iterator next method."""
        if self.fifo is not None and len(self.fifo):
            return self.fifo.popleft()
        else:
            self.fifo = None
            raise StopIteration

    def push(self, obj):
        """Push a Command object.

        When the iterator is not running, push the object to the
        running_list (as a result of a dbgvar, delvar or foldvar command).
        """
        assert callable(obj)
        if self.fifo is not None:
            self.fifo.append(obj)
        else:
            self.running_list.append(obj)

class Command(object):
    """Abstract class to send gdb command and process the result.

    Instance attributes:
        gdb: Gdb
            the Gdb instance

    """

    def __init__(self, gdb):
        """Constructor."""
        self.gdb = gdb

    def handle_result(self, result):
        """Process the result of the gdb command."""
        unused = self
        unused = result
        raise NotImplementedError('must be implemented in subclass')

    def handle_strrecord(self, stream_record):
        """Process the stream records output by the command."""
        unused = self
        unused = stream_record
        raise NotImplementedError('must be implemented in subclass')

    def send(self, fmt, *args):
        """Send the command and add oneself to the expected pending results."""
        token = self.gdb.results.add(self)
        if token is not None:
            if args:
                fmt = fmt % args
            self.gdb.write(token + fmt)
            return True
        return False

class CliCommand(Command):
    """All cli commands."""

    def sendcmd(self, cmd):
        """Send a cli command."""
        if not self.gdb.accepting_cmd():
            self.gdb.console_print(
                    "gdb busy: command discarded, please retry\n")
            return False

        self.gdb.gdb_busy = True
        cmd = misc.norm_unixpath(cmd)
        return self.send('-interpreter-exec console %s\n', misc.quote(cmd))

    def handle_result(self, line):
        """Handle gdb/mi result, print an error message."""
        errmsg = 'error,msg='
        if line.startswith(errmsg):
            line = line[len(errmsg):]
            matchobj = misc.re_quoted.match(line)
            if matchobj:
                line = misc.unquote(matchobj.group(1))
                self.gdb.console_print('%s\n' % line)
                return
        info(line)

    def handle_strrecord(self, stream_record):
        """Process the stream records output by the command."""
        self.gdb.console_print(stream_record)

class CliCommandNoPrompt(CliCommand):
    """The prompt is printed by one of the OobCommands."""
    pass

class CompleteBreakCommand(CliCommand):
    """CliCommand sent to get the symbols completion list."""

    def sendcmd(self, cmd=''):
        """Send the gdb command."""
        unused = cmd
        if not CliCommand.sendcmd(self, 'complete break '):
            self.handle_strrecord('')
            return False
        return True

    def handle_strrecord(self, stream_record):
        """Process the gdb/mi stream records."""
        f_clist = f_ack = None
        try:
            if not stream_record:
                f_ack = open(self.gdb.globaal.f_ack.name, 'w')
                f_ack.write('Nok\n')
                self.gdb.console_print(
                        'Break and clear completion not changed.\n')
            else:
                invalid = 0
                f_clist = open(self.gdb.globaal.f_clist.name, 'w')
                completion_list = stream_record.splitlines()
                for result in completion_list:
                    matchobj = re_completion.match(result)
                    if matchobj:
                        symbol = matchobj.group('sym')
                        signature = matchobj.group('sig')
                        rest = matchobj.group('rest')
                        if symbol and not rest:
                            if signature:
                                symbol += signature
                            f_clist.write('%s\n' % symbol)
                        else:
                            invalid += 1
                            warning('invalid symbol completion: %s', result)
                    else:
                        error('invalid symbol completion: %s', result)
                        break
                else:
                    f_ack = open(self.gdb.globaal.f_ack.name, 'w')
                    f_ack.write('Ok\n')
                    info('%d symbols fetched for break and clear completion',
                            len(completion_list) - invalid)
        finally:
            if f_clist:
                f_clist.close()
            if f_ack:
                f_ack.close()
            else:
                self.gdb.console_print('Failed to fetch symbols completion.\n')

class MiCommand(Command):
    """The MiCommand abstract class.

    Instance attributes:
        gdb: Gdb
            the Gdb instance
        varobj: VarObj
            the VarObj instance
        result: str
            the result of the mi command

    """

    def __init__(self, gdb, varobj):
        """Constructor."""
        self.gdb = gdb
        self.varobj = varobj
        self.result = ''

    def docmd(self, fmt, *args):
        """Send the gdb command."""
        if not self.gdb.accepting_cmd():
            self.gdb.console_print(
                    "gdb busy: command discarded, please retry\n")
            return False

        self.gdb.gdb_busy = True
        self.result = ''
        return self.send(fmt, *args)

    def handle_strrecord(self, stream_record):
        """Process the gdb/mi stream records."""
        if not self.result and stream_record:
            self.gdb.console_print(stream_record)

class VarCreateCommand(MiCommand):
    """Create a variable object."""

    def sendcmd(self):
        """Send the gdb command."""
        return MiCommand.docmd(self, '-var-create - * %s\n',
                                    misc.quote(self.varobj['exp']))

    def handle_result(self, line):
        """Process gdb/mi result."""
        parsed = misc.parse_keyval(re_varcreate, line)
        if parsed is not None and VARCREATE_ATTRIBUTES.issubset(parsed):
            rootvarobj = self.gdb.info.varobj
            varobj = self.varobj
            varobj.update(parsed)
            try:
                rootvarobj.root[varobj['name']] = varobj
                rootvarobj.dirty = True
                self.result = line
            except KeyError:
                error('in varobj creation of %s', str(parsed))

class VarDeleteCommand(MiCommand):
    """Delete the variable object and its children."""

    def sendcmd(self):
        """Send the gdb command."""
        return MiCommand.docmd(self, '-var-delete %s\n',
                                            self.varobj['name'])

    def handle_result(self, line):
        """Process gdb/mi result."""
        matchobj = re_vardelete.match(line)
        if matchobj:
            self.result = matchobj.group('ndeleted')
            if self.result:
                name = self.varobj['name']
                rootvarobj = self.gdb.info.varobj
                (varobj, varlist) = rootvarobj.leaf(name)
                unused = varobj
                if varlist is not None:
                    del varlist[name]
                    rootvarobj.dirty = True
                    self.gdb.console_print(
                                '%s watched variables have been deleted\n',
                                                                self.result)

class VarSetFormatCommand(MiCommand):
    """Set the output format of the value of the watched variable."""

    def sendcmd(self, format):
        """Send the gdb command."""
        return MiCommand.docmd(self, '-var-set-format %s %s\n',
                                        self.varobj['name'], format)

    def handle_result(self, line):
        """Process gdb/mi result."""
        matchobj = re_setfmtvar.match(line)
        if matchobj:
            self.gdb.console_print('%s = %s\n',
                        self.varobj['name'], matchobj.group('value'))

class NumChildrenCommand(MiCommand):
    """Get how many children this object has."""

    def sendcmd(self):
        """Send the gdb command."""
        return MiCommand.docmd(self, '-var-info-num-children %s\n',
                                                        self.varobj['name'])

    def handle_result(self, line):
        """Process gdb/mi result."""
        # used as a nop command by the foldvar command
        pass

# 'type' and 'value' are not always present in -var-list-children output
LIST_CHILDREN_KEYS = VARLISTCHILDREN_ATTRIBUTES.difference(set(('type', 'value')))
class ListChildrenCommand(MiCommand):
    """Return a list of the object's children."""

    def sendcmd(self):
        """Send the gdb command."""
        return MiCommand.docmd(self, '-var-list-children --all-values %s\n',
                                                        self.varobj['name'])

    def handle_result(self, line):
        """Process gdb/mi result."""
        varlist = [VarObj(x) for x in
                        [misc.parse_keyval(re_varlistchildren, list_element)
                            for list_element in re_dict_list.findall(line)]
                if x is not None and LIST_CHILDREN_KEYS.issubset(x)]
        for varobj in varlist:
            self.varobj['children'][varobj['name']] = varobj
        self.gdb.info.varobj.dirty = True

class WhatIs(Command):
    """The WhatIs command.

    Instance attributes:
        gdb: Gdb
            the Gdb instance
        text: str
            the selected text under the mouse

    """

    def __init__(self, gdb, text):
        """Constructor."""
        self.gdb = gdb
        self.text = text

    def sendcmd(self):
        """Send the gdb command."""
        if self.gdb.accepting_cmd():
            self.gdb.gdb_busy = True
            return self.send('-interpreter-exec console %s\n',
                                misc.quote('whatis %s' % self.text))
        return False

    def handle_result(self, line):
        """Process gdb/mi result."""
        # ignore the error
        return

    def handle_strrecord(self, stream_record):
        """Process the gdb/mi stream records."""
        if self.gdb.dereference:
            matchobj = re_type.match(stream_record.strip())
            if (matchobj
                        and len(matchobj.group('star')) == 1
                        and matchobj.group('name') != 'char'):
                self.text = '* %s' % self.text
        self.gdb.oob_list.push(ShowBalloon(self.gdb, self.text))

class ShowBalloon(Command):
    """The ShowBalloon command.

    Instance attributes:
        gdb: Gdb
            the Gdb instance
        text: str
            the selected text under the mouse as an expression to evaluate
        result: str
            the result of the mi command

    """

    def __init__(self, gdb, text):
        """Constructor."""
        self.gdb = gdb
        self.text = text
        self.result = ''

    def sendcmd(self):
        """Send the gdb command."""
        self.result = ''
        return self.send('-data-evaluate-expression %s\n',
                                    misc.quote(self.text))

    def handle_result(self, line):
        """Process gdb/mi result."""
        matchobj = re_evaluate.match(line)
        if matchobj:
            self.result = misc.unquote(matchobj.group('value'))
            if self.result:
                self.gdb.show_balloon('%s = "%s"' % (self.text, self.result))
        elif not 'Attempt to use a type name as an expression' in line:
            self.gdb.show_balloon('%s: %s' % (self.text, line))

    def handle_strrecord(self, stream_record):
        """Process the gdb/mi stream records."""
        if not self.result and stream_record:
            self.gdb.show_balloon(stream_record)

    def __call__(self):
        """Run the gdb command.

        Return True when the command has been sent to gdb, False otherwise.

        """
        return self.sendcmd()

class VarObjCmd(Command):
    """The VarObjCmd abstract class.

    Instance attributes:
        gdb: Gdb
            the Gdb instance
        varobj: VarObj
            the VarObj instance
        result: str
            the result of the mi command

    """

    def __init__(self, gdb, varobj):
        """Constructor."""
        self.gdb = gdb
        self.varobj = varobj
        self.result = ''

    def handle_strrecord(self, stream_record):
        """Process the gdb/mi stream records."""
        if not self.result and stream_record:
            self.gdb.console_print(stream_record)

    def sendcmd(self):
        """Send the gdb command.

        Return True when the command has been sent to gdb, False otherwise.

        """
        unused = self
        raise NotImplementedError('must be implemented in subclass')

    def __call__(self):
        """Run the gdb command.

        Return True when the command has been sent to gdb, False otherwise.

        """
        return self.sendcmd()

class VarObjCmdEvaluate(VarObjCmd):
    """The VarObjCmdEvaluate class."""

    def sendcmd(self):
        """Send the gdb command.

        Return True when the command has been sent to gdb, False otherwise.

        """
        name = self.varobj['name']
        if not name:
            return False
        self.result = ''
        return self.send('-var-evaluate-expression %s\n', name)

    def handle_result(self, line):
        """Send the gdb command."""
        parsed = misc.parse_keyval(re_varevaluate, line)
        if parsed is not None and VAREVALUATE_ATTRIBUTES.issubset(parsed):
            self.result = line
            value = parsed['value']
            if value != self.varobj['value']:
                self.varobj.chged = True
                self.gdb.info.varobj.dirty = True
                self.varobj['value'] = value

class VarObjCmdDelete(VarObjCmd):
    """The VarObjCmdDelete class."""

    def sendcmd(self):
        """Send the gdb command.

        Return True when the command has been sent to gdb, False otherwise.

        """
        name = self.varobj['name']
        if not name:
            return False
        self.result = ''
        return self.send('-var-delete %s\n', name)

    def handle_result(self, line):
        """Send the gdb command."""
        matchobj = re_vardelete.match(line)
        if matchobj:
            self.result = matchobj.group('ndeleted')
            if self.result:
                name = self.varobj['name']
                rootvarobj = self.gdb.info.varobj
                (varobj, varlist) = rootvarobj.leaf(name)
                unused = varobj
                if varlist is not None:
                    del varlist[name]
                    rootvarobj.dirty = True

class OobCommand(object):
    """Abstract class for all static OobCommands.

    An OobCommand can either send a gdb command, or process the result of other
    OobCommands as with the Project OobCommand.

    """

    def __init__(self, gdb):
        """Constructor."""
        self.gdb = gdb

    def notify(self, cmd):
        """Notify of the cmd being processed."""
        unused = self
        unused = cmd
        raise NotImplementedError('must be implemented in subclass')

    def __call__(self):
        """Run the gdb command or perform the task.

        Return True when the command has been sent to gdb, False otherwise.

        """
        unused = self
        raise NotImplementedError('must be implemented in subclass')

class OobGdbCommand(OobCommand, Command):
    """Base abstract class for oob commands.

    Instance attributes:
        mi: bool
            True when the gdb command is a mi command
        gdb_cmd: str
            new line terminated command to send to gdb
        info_attribute: str
            gdb.info attribute name, this is where the result of the
            command is stored, after parsing the result
        prefix: str
            prefix in the result or stream_record string
        regexp: a compiled regular expression
            gdb.info.info_attribute is set with list of regexp groups tuples
        gdblist: bool
            True when the result is a gdb list
        action: str
            optional: not present in all subclasses
            name of the gdb.info method that is called after parsing the result
        cmd: str
            the command being currently processed
        trigger: boolean
            when True, invoke __call__()
        trigger_list: tuple
            list of commands that trigger the invocation of __call__()
        trigger_prefix: set
            set of the trigger_list command prefixes built from the
            trigger_list and the list of gdb commands

    """

    def __init__(self, gdb):
        """Constructor."""
        OobCommand.__init__(self, gdb)
        assert self.__class__ is not OobGdbCommand
        assert hasattr(self, 'gdb_cmd') and isinstance(self.gdb_cmd, str)
        self.mi = not self.gdb_cmd.startswith('-interpreter-exec console')
        assert hasattr(self, 'info_attribute')              \
                and isinstance(self.info_attribute, str)    \
                and hasattr(self.gdb.info, self.info_attribute)
        assert hasattr(self, 'prefix')                      \
                and isinstance(self.prefix, str)
        assert hasattr(self, 'regexp')                      \
                and hasattr(self.regexp, 'findall')
        assert hasattr(self, 'gdblist')                     \
                and isinstance(self.gdblist, bool)
        if hasattr(self, 'action'):
            assert hasattr(self.gdb.info, self.action)
        assert hasattr(self, 'trigger_list')                \
                and isinstance(self.trigger_list, tuple)
        assert hasattr(self, 'reqkeys')                     \
                and isinstance(self.reqkeys, set)
        self.cmd = ''
        self.trigger = False

        # build prefix list that triggers the command after being notified
        keys = list(set(self.gdb.cmds.keys()).difference(set(self.trigger_list)))
        self.trigger_prefix = set([misc.smallpref_inlist(x, keys)
                                                for x in self.trigger_list])

    def notify(self, cmd):
        """Notify of the cmd being processed.

        The OobGdbCommand is run when the trigger_list is empty, or when a
        prefix of the notified command matches in the trigger_prefix list.

        """
        self.cmd = cmd
        if not self.trigger_list or     \
                    misc.any([cmd.startswith(x) for x in self.trigger_prefix]):
            self.trigger = True

    def __call__(self):
        """Send the gdb command.

        Return True when the command was sent, False otherwise.

        """
        if self.trigger:
            setattr(self.gdb.info, self.info_attribute, [])
            self.trigger = False
            return self.send(self.gdb_cmd)
        return False

    def parse(self, data):
        """Parse 'data' with the regexp after removing prefix.

        When successful, set the info_attribute.

        """
        try:
            remain = data[data.index(self.prefix) + len(self.prefix):]
        except ValueError:
            debug('bad prefix in oob parsing of "%s",'
                    ' requested prefix: "%s"', data.strip(), self.prefix)
        else:
            if self.gdblist:
                # a list of dictionaries
                parsed = [x for x in
                           [misc.parse_keyval(self.regexp, list_element)
                            for list_element in re_dict_list.findall(remain)]
                                 if x is not None and self.reqkeys.issubset(x)]
            else:
                if self.reqkeys:
                    parsed = misc.parse_keyval(self.regexp, remain)
                    if parsed is not None and not self.reqkeys.issubset(parsed):
                        parsed = None
                else:
                    parsed = self.regexp.findall(remain)
            if parsed:
                setattr(self.gdb.info, self.info_attribute, parsed)
            else:
                debug('no match for "%s"', remain)

    def handle_result(self, result):
        """Process the result of the mi command."""
        if self.mi:
            self.parse(result)
            # call the gdb.info method
            if hasattr(self, 'action'):
                try:
                    getattr(self.gdb.info, self.action)(self.cmd)
                except (KeyError, ValueError):
                    info_attribute = getattr(self.gdb.info,
                                            self.info_attribute)
                    if info_attribute:
                        error('bad format: %s', info_attribute)

    def handle_strrecord(self, stream_record):
        """Process the stream records output by the cli command."""
        if not self.mi:
            self.parse(stream_record)

# instantiate the OobGdbCommand subclasses
Args =          \
    type('Args', (OobGdbCommand,),
            {
                '__doc__': """Get the program arguments.""",
                'gdb_cmd': '-interpreter-exec console "show args"\n',
                'info_attribute': 'args',
                'prefix': 'Argument list to give program being'     \
                          ' debugged when it is started is',
                'regexp': re_args,
                'reqkeys': set(),
                'gdblist': False,
                'trigger_list': PROJECT_CMDS,
            })

Breakpoints =   \
    type('Breakpoints', (OobGdbCommand,),
            {
                '__doc__': """Get the breakpoints list.""",
                'gdb_cmd': '-break-list\n',
                'info_attribute': 'breakpoints',
                'prefix': 'done,',
                'regexp': re_breakpoints,
                'reqkeys': REQ_BREAKPOINT_ATTRIBUTES,
                'gdblist': True,
                'action': 'update_breakpoints',
                'trigger_list': BREAKPOINT_CMDS,
            })

Directories =   \
    type('Directories', (OobGdbCommand,),
            {
                '__doc__': """Get the directory list.""",
                'gdb_cmd': '-interpreter-exec console "show directories"\n',
                'info_attribute': 'directories',
                'prefix': 'Source directories searched: ',
                'regexp': re_directories,
                'reqkeys': set(),
                'gdblist': False,
                'trigger_list': DIRECTORY_CMDS,
            })

File =          \
    type('File', (OobGdbCommand,),
            {
                '__doc__': """Get the source file.""",
                'gdb_cmd': '-file-list-exec-source-file\n',
                'info_attribute': 'file',
                'prefix': 'done,',
                'regexp': re_file,
                'reqkeys': FILE_ATTRIBUTES,
                'gdblist': False,
                'trigger_list': FILE_CMDS,
            })

FrameCli =      \
    type('FrameCli', (OobGdbCommand,),
            {
                '__doc__': """Get the frame information.""",
                'version_max': '6.3',
                'gdb_cmd': 'frame\n',
                'info_attribute': 'frame',
                'prefix': 'done,',
                'regexp': re_framecli,
                'reqkeys': FRAMECLI_ATTRIBUTES,
                'gdblist': False,
                'action': 'update_frame',
                'trigger_list': FRAME_CMDS,
            })

Frame=          \
    type('Frame', (OobGdbCommand,),
            {
                '__doc__': """Get the frame information.""",
                'version_min': '6.4',
                'gdb_cmd': '-stack-info-frame\n',
                'info_attribute': 'frame',
                'prefix': 'done,',
                'regexp': re_frame,
                'reqkeys': FRAME_ATTRIBUTES,
                'gdblist': False,
                'action': 'update_frame',
                'trigger_list': FRAME_CMDS,
            })

PgmFile =       \
    type('PgmFile', (OobGdbCommand,),
            {
                '__doc__': """Get the program file.""",
                'gdb_cmd': '-interpreter-exec console "info files"\n',
                'info_attribute': 'debuggee',
                'prefix': 'Symbols from',
                'regexp': re_pgmfile,
                'reqkeys': set(),
                'gdblist': False,
                'trigger_list': PROJECT_CMDS,
            })

Pwd =           \
    type('Pwd', (OobGdbCommand,),
            {
                '__doc__': """Get the current working directory.""",
                'gdb_cmd': '-environment-pwd\n',
                'info_attribute': 'cwd',
                'prefix': 'done,cwd=',
                'regexp': re_pwd,
                'reqkeys': set(),
                'gdblist': False,
                'trigger_list': PROJECT_CMDS,
            })

Sources =       \
    type('Sources', (OobGdbCommand,),
            {
                '__doc__': """Get the list of source files.""",
                'gdb_cmd': '-file-list-exec-source-files\n',
                'info_attribute': 'sources',
                'prefix': 'done,',
                'regexp': re_sources,
                'reqkeys': SOURCES_ATTRIBUTES,
                'gdblist': True,
                'trigger_list': SOURCE_CMDS,
            })

VarUpdate =     \
    type('VarUpdate', (OobGdbCommand,),
            {
                '__doc__': """Update the variable and its children.""",
                'gdb_cmd': '-var-update *\n',
                'info_attribute': 'changelist',
                'prefix': 'done,',
                'regexp': re_varupdate,
                'reqkeys': VARUPDATE_ATTRIBUTES,
                'gdblist': True,
                'action': 'update_changelist',
                'trigger_list': VARUPDATE_CMDS,
            })

class Project(OobCommand):
    """Save project information.

    Instance attributes:
        project_name: str
            project file pathname

    """

    def __init__(self, gdb):
        """Constructor."""
        OobCommand.__init__(self, gdb)
        self.project_name = ''

    def notify(self, line):
        """Set the project filename on notification."""
        self.project_name = ''
        cmd = 'project '
        if line.startswith(cmd):
            self.project_name = line[len(cmd):].strip()

    def save_breakpoints(self, project):
        """Save the breakpoints in a project file.

        Save at most one breakpoint per line.

        """
        gdb_info = self.gdb.info
        bp_list = []
        for num in sorted(gdb_info.bp_dictionary.keys(), key=int):
            bp_element = gdb_info.bp_dictionary[num]
            pathname = gdb_info.get_fullpath(bp_element['file'])
            breakpoint = '%s:%s' % (pathname, bp_element['line'])
            if pathname is not None and breakpoint not in bp_list:
                project.write('break %s\n' % breakpoint)
                bp_list.append(breakpoint)

    def __call__(self):
        """Write the project file."""
        if self.project_name:
            # write the project file
            errmsg = ''
            gdb_info = self.gdb.info
            quitting = (self.gdb.state == self.gdb.STATE_QUITTING)
            if gdb_info.debuggee:
                try:
                    project = open(self.project_name, 'w+b')

                    if gdb_info.cwd:
                        cwd = gdb_info.cwd[0]
                        if not cwd.endswith(os.sep):
                            cwd += os.sep
                        project.write('cd %s\n'
                            % misc.norm_unixpath(misc.unquote(cwd), True))

                    project.write('file %s\n'
                            % misc.norm_unixpath(gdb_info.debuggee[0], True))

                    if gdb_info.args:
                        project.write('set args %s\n' % gdb_info.args[0])

                    self.save_breakpoints(project)

                    project.close()

                    msg = 'Project \'%s\' has been saved.' % self.project_name
                    info(msg)
                    self.gdb.console_print('%s\n', msg)
                    if not quitting:
                        self.gdb.prompt()
                except IOError, errmsg:
                    pass
            else:
                errmsg = 'Project \'%s\' not saved:'    \
                         ' no executable file specified.' % self.project_name
            if errmsg:
                error(errmsg)
                self.gdb.console_print('%s\n', errmsg)
                if not quitting:
                    self.gdb.prompt()
        return False

class Quit(OobCommand):
    """Quit gdb.

    """

    def notify(self, cmd):
        """Ignore the notification."""
        unused = self
        unused = cmd

    def __call__(self):
        """Quit gdb."""
        if self.gdb.state == self.gdb.STATE_QUITTING:
            self.gdb.write('quit\n')

            # the Debugger instance is closing, its dispatch loop timer is
            # closing as well and we cannot rely on this timer anymore to handle
            # buffering on the console, so switch to no buffering
            self.gdb.console_print('\n===========\n')
            self.gdb.console_flush()

            self.gdb.state = self.gdb.STATE_CLOSING
            self.gdb.close()

        return False

