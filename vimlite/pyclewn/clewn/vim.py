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

"""
A Vim instance starts a Debugger instance and dispatches the netbeans messages
exchanged by vim and the debugger. A new Debugger instance is restarted whenever
the current one dies.

"""
import os
import sys
import time
import os.path
import tempfile
import subprocess
import asyncore
import inspect
import optparse
import logging
import errno
import thread
import threading
import atexit

from clewn import *
import clewn.misc as misc
import clewn.gdb as gdb
import clewn.simple as simple
import clewn.netbeans as netbeans
import clewn.buffer as vimbuffer
import clewn.evtloop as evtloop
if os.name == 'nt':
    from clewn.nt import hide_console as daemonize
    from clewn.nt import platform_data
    pydb = tty = None
else:
    from clewn.posix import daemonize, platform_data
    import clewn.pydb as pydb
    import clewn.tty as tty


WINDOW_LOCATION = ('top', 'bottom', 'left', 'right', 'none')
CONNECTION_DEFAULTs = '', 3219, 'changeme'
CONNECTION_TIMEOUT = 30
CONNECTION_ERROR = """Connection to Vim timed out after %s seconds.
Please check that the netbeans_intg feature is compiled
in your Vim version by running the Vim command ':version',
and checking that this command displays '+netbeans_intg'."""

BG_COLORS =( 'none', 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed',
             'DarkMagenta', 'Brown', 'DarkYellow', 'LightGray', 'LightGrey',
             'Gray', 'Grey', 'DarkGray', 'DarkGrey', 'Blue', 'LightBlue',
             'Green', 'LightGreen', 'Cyan', 'LightCyan', 'Red', 'LightRed',
             'Magenta', 'LightMagenta', 'Yellow', 'LightYellow', 'White',)

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('vim')
Unused = error
Unused = warning

def exec_vimcmd(commands, pathname='', error_stream=None):
    """Run a list of Vim 'commands' and return the commands output."""
    try:
        perror = error_stream.write
    except AttributeError:
        perror = sys.stderr.write

    if not pathname:
        pathname = os.environ.get('EDITOR', 'gvim')

    args = [pathname, '-u', 'NONE', '-esX', '-c', 'set cpo&vim']
    fd, tmpname = tempfile.mkstemp(prefix='runvimcmd', suffix='.clewn')
    commands.insert(0,  'redir! >%s' % tmpname)
    commands.append('quit')
    for cmd in commands:
        args.extend(['-c', cmd])

    output = f = None
    try:
        try:
            subprocess.Popen(args).wait()
            f = os.fdopen(fd)
            output = f.read()
        except (OSError, IOError), err:
            if isinstance(err, OSError) and err.errno == errno.ENOENT:
                perror("Failed to run '%s' as Vim.\n" % args[0])
                perror("Please run 'pyclewn"
                                      " --editor=/path/to/(g)vim'.\n\n")
            else:
                perror("Failed to run Vim as:\n'%s'\n\n" % str(args))
            raise
    finally:
        if f is not None:
            f.close()
        if tmpname and os.path.exists(tmpname):
            try:
                os.unlink(tmpname)
            except OSError:
                pass

    if not output:
        raise ClewnError(
            "Error trying to start Vim with the following command:\n'%s'\n"
            % ' '.join(args))

    return output

def pformat(name, obj):
    """Pretty format an object __dict__."""
    if obj:
        return '%s:\n%s\n' % (name, misc.pformat(obj.__dict__))
    else: return ''

def vim73_workaround(vim):
    """Work around a bug in Vim73."""
    # vim73 'netbeans close SEGV' bug (fixed by 7.3.060).
    # Allow vim to process all netbeans PDUs before receiving the disconnect
    # event.
    if not vim.closed:
        info('enter vim73_workaround')
        time.sleep(misc.VIM73_BUG_SLEEP_TIME)

        debug('Vim instance: ' + str(vim))
        vim.shutdown()

def _pdb(vim, attach=False):
    """Start the python debugger thread."""
    if os.name != 'posix':
        print >> sys.stderr, 'Error, pdb is only supported on unix systems.'
        sys.exit(1)

    Vim.pdb_running = True
    atexit.register(vim73_workaround, vim)
    vim.debugger = vim.clazz(vim.options)
    pdb = vim.debugger
    pdb.target_thread_ident = thread.get_ident()

    # use a daemon thread
    class ClewnThread(threading.Thread):
        def __init__(self):
            threading.Thread.__init__(self, name='Clewn-thread')
            self.setDaemon(True)
        def run(self):
            vim.run_pdb()

    ClewnThread().start()
    pdb.started_event.wait(1)
    if not pdb.started_event.isSet():
        print >> sys.stderr, 'Aborting, failed to start the clewn thread.'
        sys.exit(1)

    if attach:
        if vim.options.run:
            pdb.let_target_run = True
        pdb.set_trace(sys._getframe(2))
    else:
        pydb.main(pdb, vim.options)

def pdb(run=False, **kwds):
    """Start pdb from within a python process.

    The 'kwds' keyword arguments may be any of the pyclewn options that set a
    value (no boolean option allowed).
    """
    if Vim.pdb_running:
        return

    argv = ['pyclewn', '--pdb']
    if run:
        argv.append('--run')
    argv.extend(['--' + k + '=' + str(v) for k,v in kwds.iteritems()])
    _pdb(Vim(False, argv), True)

if os.name == 'nt':
    del pdb

def main(testrun=False):
    """Main.

    Return the vim instance to avoid its 'f_script' member to be garbage
    collected and the corresponding 'TmpFile' to be unlinked before Vim has a
    chance to start and source the file (only needed for the pdb test suite).

    """
    vim = Vim(testrun, sys.argv[1:])
    options = vim.options
    if options.pdb:
        if testrun:
            vim.debugger = vim.clazz(options)
            vim.spawn_vim()
        elif options.args:
            # run pdb to debug the 'args' python script
            _pdb(vim)
        else:
            # vim is running the command: 'Pyclewn pdb'
            # vim is attaching to a python process,
            # just write the vim script
            vim.vim_version()
            vim.clazz(options)._vim_script(options)
        return vim

    except_str = ''
    try:
        gdb_pty = None
        if os.name != 'nt' and not testrun:
            gdb_pty = tty.GdbInferiorPty(vim.stderr_hdlr)
        try:
            if (vim.clazz == gdb.Gdb
                        and gdb_pty
                        and not options.daemon
                        and os.isatty(sys.stdin.fileno())):
                # Use pyclewn pty as the debuggee standard input and output, but
                # not when vim is run as 'vim' or 'vi'.
                vim_pgm = os.path.basename(options.editor)
                if vim_pgm != 'vim' and vim_pgm != 'vi':
                    gdb_pty.start()
                    options.tty = gdb_pty.ptyname

            vim.debugger = vim.clazz(options)
            vim.setup(True)
            vim.loop()
        except (KeyboardInterrupt, SystemExit):
            pass
        except:
            t, v, filename, lnum, last_tb = misc.last_traceback()

            # get the line where exception occured
            try:
                lines, top = inspect.getsourcelines(last_tb)
                location = 'source line: "%s"\nat %s:%d' \
                        % (lines[lnum - top].strip(), filename, lnum)
            except IOError:
                sys.exc_clear()
                location = ''

            except_str = '\nException in pyclewn:\n\n'  \
                            '%s\n"%s"\n%s\n\n'          \
                            'pyclewn aborting...\n'     \
                                    % (str(t), str(v), location)
            critical(except_str)
            if vim.nbserver.netbeans:
                vim.nbserver.netbeans.show_balloon(except_str)
    finally:
        if gdb_pty:
            gdb_pty.close()
        debug('Vim instance: ' + str(vim))
        vim.shutdown()
        if os.name == 'nt' and except_str:
            time.sleep(5)

    return vim

class Vim(object):
    """The Vim instance dispatches netbeans messages.

    Class attributes:
        pdb_running: boolean
            True when pdb is running

    Instance attributes:
        testrun: boolean
            True when run from a test suite
        argv: list
            pyclewn options as a list
        file_hdlr: logger.FileHandler
            log file
        stderr_hdlr: misc.StderrHandler
            sdterr stream handler
        socket_map: asyncore socket dictionary
            socket and socket-like objects listening on the select
            event loop
        debugger: debugger.Debugger
            the debugger instance run by Vim
        clazz: class
            the selected Debugger subclass
        f_script: file
            the Vim script file object
        nbserver: netbeans.Server
            the netbeans listening server instance
        vim: subprocess.Popen
            the vim Popen instance
        options: optparse.Values
            the command line options
        closed: boolean
            True when shutdown has been run

    """

    pdb_running = False

    def __init__(self, testrun, argv):
        """Constructor"""
        self.testrun = testrun
        # reinitialize the sernum counter
        if testrun:
            vimbuffer.Sernum(0)

        self.file_hdlr = None
        self.stderr_hdlr = None
        self.socket_map = asyncore.socket_map
        self.debugger = None
        self.clazz = None
        self.f_script = None
        self.nbserver = netbeans.Server()
        self.vim = None
        self.options = None
        self.parse_options(argv)
        self.setlogger()
        self.closed = False

    def vim_version(self):
        """Check Vim version."""
        # test if Vim contains the netbeans 'remove' fix
        # test if Vim contains the netbeans 'getLength' fix
        # test if Vim contains the netbeans 'cmd on NoName buffer ignored' fix

        # pyclewn is started from within vim
        if not self.options.editor:
            netbeans.Netbeans.remove_fix = '1'
            netbeans.Netbeans.getLength_fix = '1'
            self.options.noname_fix = '1'
            return

        cmds = ['echo v:version > 701 || v:version == 701 && has("patch207")',
                'echo v:version > 702 || v:version == 702 && has("patch253")',
                'echo v:version > 702 || v:version == 702 && has("patch334")',
                'echo v:version',
                'runtime plugin/pyclewn.vim',
                'if exists("g:pyclewn_version")'
                    ' | echo g:pyclewn_version'
                    ' | endif',
                ]
        output = exec_vimcmd(cmds, self.options.editor,
                                   self.stderr_hdlr).strip().split('\n')
        output = [x.strip('\r') for x in output]
        length = len(output)
        version = ''
        if length == 5:
            (netbeans.Netbeans.remove_fix,
             netbeans.Netbeans.getLength_fix,
             self.options.noname_fix,
             vimver, version) = output
        elif length == 4:
            (netbeans.Netbeans.remove_fix,
             netbeans.Netbeans.getLength_fix,
             self.options.noname_fix,
             vimver) = output
        else:
            raise ClewnError('output of %s: %s' % (cmds, output))
        info('Vim version: %s', vimver)

        # check pyclewn version
        pyclewn_version = 'pyclewn-' + __tag__
        if version != pyclewn_version:
            raise ClewnError('pyclewn.vim version does not match pyclewn\'s:\n'\
                        '\t\tpyclewn version: "%s"\n'\
                        '\t\tpyclewn.vim version: "%s"'
                        % (pyclewn_version, version))
        info('pyclewn.vim version: %s', version)

    def spawn_vim(self):
        """Spawn vim."""
        self.vim_version()
        args = self.options.cargs or []
        self.f_script = self.debugger._vim_script(self.options)
        info('sourcing the Vim script file: %s', self.f_script.name)
        args[:0] = [self.f_script.name]
        args[:0] = ['-S']
        if not self.options.cargs \
                or not                  \
                [a for a in self.options.cargs if a.startswith('-nb')]:
            args[:0] = ['-nb']
        args[:0] = [self.options.editor]

        # uncomment next lines to run Valgrind on Vim
        # args[:0] = ["--leak-check=yes"]
        # args[:0] = ["valgrind"]

        info('Vim argv list: %s', str(args))
        try:
            #args += ['--servername', 
                     #'%s' % os.environ.get('VIM_SERVERNAME', 'GVIM2'), 
                     #'--remote-send', 
                     #"<C-\><C-n>:echom '%s'<CR>" % self.f_script.name, 
                    #]
            #args += ['--servername', 
                     #'%s' % os.environ.get('VIM_SERVERNAME', 'GVIM2'), 
                    #]
            #print os.environ.get('VIM_SERVERNAME', 'GVIM2')
            #print self.f_script.name
            if os.environ.get('VIM_SERVERNAME'):
                # if VIM_SERVERNAME not null, means request a terminal emulator
                self.vim = None
            else:
                self.vim = subprocess.Popen(args,
                                    close_fds=(os.name != 'nt'))
        except OSError:
            critical('cannot start Vim'); raise

    def setup(self, oneshot):
        """Listen to netbeans and start vim.

        Method parameters:
            oneshot: boolean
                when True, 'nbserver' accepts only a single connection
        """
        # log platform information for debugging
        info(platform_data())

        # read keys mappings
        self.debugger._read_keysfile()

        # listen on netbeans port
        conn = list(CONNECTION_DEFAULTs)
        if self.options.netbeans:
            conn = self.options.netbeans.split(':')
            conn[1:] = conn[1:] or [CONNECTION_DEFAULTs[1]]
            conn[2:] = conn[2:] or [CONNECTION_DEFAULTs[2]]
        assert len(conn) == 3, 'too many netbeans connection parameters'
        conn[1] = conn[1] or CONNECTION_DEFAULTs[1]
        self.nbserver.bind_listen(oneshot, *conn)

        if self.options.editor:
            self.spawn_vim()
        # pyclewn is started from within vim
        else:
            self.vim_version()
            script = self.debugger._vim_script(self.options)
            info('building the Vim script file: %s', script)

    def shutdown(self):
        """Shutdown the asyncore dispatcher."""
        if self.closed:
            return
        self.closed = True

        # remove the Vim script file in case the script failed to remove it
        if self.f_script:
            del self.f_script

        if self.nbserver.netbeans:
            self.nbserver.netbeans.close()
        self.nbserver.close()
        info('pyclewn exiting')

        if self.testrun:
            # wait for Vim to close all files
            if self.vim is not None:
                try:
                    self.vim.wait()
                except OSError:
                    # ignore: [Errno 4] Interrupted system call
                    pass
            if self.file_hdlr is not None:
                logging.getLogger().removeHandler(self.file_hdlr)
                self.file_hdlr.close()
            # get: IOError: [Errno 2] No such file or directory: '@test_out'
            # sleep does help avoiding this error
            time.sleep(0.100)

        else:
            logging.shutdown()

        for asyncobj in self.socket_map.values():
            asyncobj.close()

    def parse_options(self, argv):
        """Parse the command line options."""
        def args_callback(option, opt_str, value, parser):
            unused = opt_str
            try:
                args = misc.dequote(value)
            except ClewnError, e:
                raise optparse.OptionValueError(e)
            if option._short_opts[0] == '-c':
                parser.values.cargs = args
            else:
                parser.values.args = args

        def bpcolor_callback(option, opt_str, value, parser):
            unused = option
            unused = opt_str
            colors = value.split(',')
            if len(colors) != 3:
                raise optparse.OptionValueError('Three colors are required for'
                ' the \'--background\' option.')
            if not set(colors).issubset(BG_COLORS):
                raise optparse.OptionValueError('These colors are invalid: %s.'
                    % str(tuple(set(colors).difference(BG_COLORS))))
            if opt_str == '--foreground':
                parser.values.foreground = colors
            else:
                parser.values.bg_colors = colors
                parser.values.background = colors

        editor = os.environ.get('EDITOR', 'gvim')
        formatter = optparse.IndentedHelpFormatter(max_help_position=30)
        parser = optparse.OptionParser(
                        version='%prog ' + __tag__,
                        usage='usage: python %prog [options]',
                        formatter=formatter)

        parser.add_option('-s', '--simple',
                action="store_true", default=False,
                help='select the simple debugger')
        if os.name != 'nt':
            parser.add_option('--pdb',
                    action="store_true", default=False,
                    help='select \'pdb\', the python debugger')
        parser.add_option('-g', '--gdb',
                type='string', metavar='PARAM_LIST', default='',
                help='select the gdb debugger (the default)'
                     ', with a mandatory, possibly empty, PARAM_LIST')
        parser.add_option('-d', '--daemon',
                action="store_true", default=False,
                help='run as a daemon (default \'%default\')')
        if os.name != 'nt':
            parser.add_option('--run',
                    action="store_true", default=False,
                    help=('allow the debuggee to run after the pdb() call'
                    ' (default \'%default\')'))
        parser.add_option('--tty',
                type='string', metavar='TTY', default=os.devnull,
                help=('use TTY for input/output by the python script being'
                ' debugged (default \'%default\')'))
        parser.add_option('-e', '--editor', default=editor,
                help='set Vim pathname to VIM (default \'%default\');'
                + ' Vim is not spawned by pyclewn when this parameter is'
                + ' set to an empty string')
        parser.add_option('-c', '--cargs', metavar='ARGS',
                type='string', action='callback', callback=args_callback,
                help='set Vim arguments to ARGS')
        parser.add_option('-p', '--pgm',
                help='set the debugger pathname to PGM')
        parser.add_option('-a', '--args',
                type='string', action='callback', callback=args_callback,
                help='set the debugger arguments to ARGS')
        parser.add_option('-w', '--window', default='top',
                type='string', metavar='LOCATION',
                help="%s%s%s" % ("open the debugger console window at LOCATION "
                "which may be one of ", WINDOW_LOCATION,
                ", the default is '%default'"))
        parser.add_option('-m', '--maxlines',
                metavar='LNUM', default=netbeans.CONSOLE_MAXLINES, type='int',
                help='set the maximum number of lines of the debugger console'
                ' window to LNUM (default %default lines)')
        parser.add_option('-x', '--prefix', default='C',
                help='set the commands prefix to PREFIX (default \'%default\')')
        parser.add_option('-b', '--background',
                type='string', action='callback', callback=bpcolor_callback,
                metavar='COLORS',
                help='COLORS is a comma separated list of the three colors of'
                ' the breakpoint enabled, breakpoint disabled and frame sign'
                ' background colors, in this order'
                ' (default \'Cyan,Green,Magenta\')')
        parser.add_option('--foreground',
                type='string', action='callback', callback=bpcolor_callback,
                metavar='COLORS',
                help='COLORS is a comma separated list of the three colors of'
                ' the breakpoint enabled, breakpoint disabled and frame sign'
                ' foreground colors, in this order'
                ' (default \'none,none,none\')')
        parser.add_option('--frametext',
                type='string', metavar='TEXT', default='=>',
                help="frame sign text, it can be null string, "
                          "if it is null string, "
                          "then the frame sign will not display text "
                          "(default '=>')")
        parser.add_option('-n', '--netbeans', metavar='CONN',
                help='set netBeans connection parameters to CONN with CONN as'
                ' \'host[:port[:passwd]]\', (the default is \'%s\''
                ' where the empty host represents INADDR_ANY)' %
                ':'.join([str(x) for x in CONNECTION_DEFAULTs]))
        parser.add_option('-l', '--level', metavar='LEVEL',
                type='string', default='',
                help='set the log level to LEVEL: %s (default error)'
                % misc.LOG_LEVELS)
        parser.add_option('-f', '--file', metavar='FILE',
                help='set the log file name to FILE')
        (self.options, args) = parser.parse_args(args=argv)

        if os.name == 'nt':
            self.options.pdb = None

        if self.options.simple:
            self.clazz = simple.Simple
        elif self.options.pdb:
            self.clazz = pydb.Pdb
        else:
            self.clazz = gdb.Gdb

        location = self.options.window.lower()
        if location in WINDOW_LOCATION:
            self.options.window = location
        else:
            parser.error(
                    '"%s" is an invalid window LOCATION, must be one of %s'
                    % (self.options.window, WINDOW_LOCATION))

        # set Netbeans class members
        if location == 'none':
            netbeans.Netbeans.enable_setdot = False

        if self.options.maxlines <= 0:
            parser.error('invalid number for maxlines option')
        netbeans.Netbeans.max_lines = self.options.maxlines

        if self.options.background:
            netbeans.Netbeans.bg_colors = self.options.background

        if self.options.foreground:
            netbeans.Netbeans.fg_colors = self.options.foreground

        netbeans.Netbeans.frametext = self.options.frametext

        level = self.options.level.upper()
        if level:
            if hasattr(logging, level):
                 self.options.level = getattr(logging, level)
            elif level == misc.NBDEBUG_LEVEL_NAME.upper():
                self.options.level = misc.NBDEBUG
            else:
                parser.error(
                    '"%s" is an invalid log LEVEL, must be one of: %s'
                    % (self.options.level, misc.LOG_LEVELS))

    def setlogger(self):
        """Setup the root logger with handlers: stderr and optionnaly a file."""
        # do not handle exceptions while emit(ing) a logging record
        logging.raiseExceptions = False
        # add nbdebug log level
        logging.addLevelName(misc.NBDEBUG, misc.NBDEBUG_LEVEL_NAME.upper())

        # can't use basicConfig with kwargs, only supported with 2.4
        root = logging.getLogger()
        if not root.handlers:
            root.manager.emittedNoHandlerWarning = True
            fmt = logging.Formatter('%(name)-4s %(levelname)-7s %(message)s')

            if self.options.file:
                try:
                    file_hdlr = logging.FileHandler(self.options.file, 'w')
                except IOError:
                    logging.exception('cannot setup the log file')
                else:
                    file_hdlr.setFormatter(fmt)
                    root.addHandler(file_hdlr)
                    self.file_hdlr = file_hdlr

            # default level: CRITICAL
            level = logging.CRITICAL
            if self.options.level:
                level = self.options.level

            # add an handler to stderr, except when running the testsuite
            # or a log file is used with a level not set to critical
            if (not self.testrun and
                        not (self.options.file and level != logging.CRITICAL)):
                self.stderr_hdlr = misc.StderrHandler()
                self.stderr_hdlr.setFormatter(fmt)
                root.addHandler(self.stderr_hdlr)

            root.setLevel(level)

    def loop(self):
        """The dispatch loop."""

        start = time.time()
        nbsock = None
        while True:
            # start the debugger
            if start is not False:
                if time.time() - start > CONNECTION_TIMEOUT:
                    raise IOError(CONNECTION_ERROR % str(CONNECTION_TIMEOUT))
                nbsock = self.nbserver.netbeans
                if nbsock and nbsock.ready:
                    start = False
                    info(nbsock)
                    nbsock.set_debugger(self.debugger)

                    # can daemonize now, no more critical startup errors to
                    # print on the console
                    if self.options.daemon:
                        daemonize()
                    version = __tag__
                    if __changeset__:
                        version += '.' + __changeset__
                    info('pyclewn version %s and the %s debugger',
                                        version, self.clazz.__name__)
            elif nbsock.connected:
                # instantiate a new debugger
                if self.debugger.closed:
                    self.debugger = self.clazz(self.options)
                    nbsock.set_debugger(self.debugger)
                    info('new "%s" instance', self.clazz.__name__.lower())
            else:
                if not self.debugger.started or self.debugger.closed:
                    break

            timeout = self.debugger._call_jobs()
            evtloop.poll(self.socket_map, timeout=timeout)

        self.debugger.close()

    def run_pdb(self):
        """Run the clewn pdb thread."""
        pdb = self.debugger

        # do not start vim
        self.options.editor = ''
        self.setup(False)
        pdb.thread = threading.currentThread()
        pdb.clewn_thread_ident = thread.get_ident()

        pdb.started_event.set()
        last_nbsock = None
        session_logged = True
        while self.socket_map:
            nbsock = self.nbserver.netbeans
            # a new netbeans connection, the server has closed last_nbsock
            if nbsock != last_nbsock and nbsock.ready:
                info(nbsock)
                nbsock.set_debugger(pdb)
                if last_nbsock is None:
                    version = __tag__
                    if __changeset__:
                        version += '.' + __changeset__
                    info('pyclewn version %s and the %s debugger',
                                        version, self.clazz.__name__)
                last_nbsock = nbsock
                session_logged = False

            # log the vim instance
            if not session_logged and nbsock and not nbsock.connected:
                session_logged = True
                debug('Vim instance: ' + str(self))

            timeout = pdb._call_jobs()
            evtloop.poll(self.socket_map, timeout=timeout)

        self.shutdown()

    def __str__(self):
        """Return a representation of the whole stuff."""
        self_str = ''
        if self.nbserver.netbeans is not None:
            self_str = '\n%s%s' % (pformat('options', self.options),
                            pformat('netbeans', self.nbserver.netbeans))
        if self.debugger is not None:
            self_str += ('debugger %s:\n%s\n'
                                % (self.clazz.__name__, self.debugger))
        return self_str

