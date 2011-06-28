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

"""The Simple class implements a simple debugger used for testing pyclewn and
for giving an example of a simple debugger.

The debuggee is running in another thread as a Target instance. To display the
frame sign, add a breakpoint first and then run the step command, or run the
continue command and send an interrupt.  One can step into the current buffer
from the first line up to the first enabled breakpoint. There is no run
command, use continue instead.

The quit command removes all the signs set by pyclewn in Vim. After the quit
command, the dispatcher instantiates a new instance of Simple.

"""
import sys
import threading
import time

import clewn.misc as misc
import clewn.debugger as debugger

# set the logging methods
(critical, error, warning, info, debug) = misc.logmethods('simp')
Unused = critical
Unused = error
Unused = warning
Unused = debug

# list of key mappings, used to build the .pyclewn_keys.simple file
#     key : (mapping, comment)
MAPKEYS = {
    'C-B' : ('break ${fname}:${lnum}',
                'set breakpoint at current line'),
    'C-E' : ('clear ${fname}:${lnum}',
                'clear breakpoint at current line'),
    'C-P' : ('print ${text}',
                'print value of selection at mouse position'),
    'C-Z' : ('interrupt',
                'interrupt the execution of the target'),
    'S-C' : ('continue',),
    'S-Q' : ('quit',),
    'S-S' : ('step',),
}

# list of the simple commands mapped to vim user commands C<command>
SIMPLE_CMDS = {
    'break'     : None,   # file name completion
    'clear'     : None,   # file name completion
    'continue'  : (),
    'disable'   : (),
    'enable'    : (),
    'interrupt' : (),
    'print'     : (),
    'quit'      : (),
    'step'      : (),
}

class Target(threading.Thread):
    """Simulate the debuggee behaviour in another thread."""

    TARGET_TIMEOUT = 0.100  # interruptible loop timer

    def __init__(self, daemon):
        """Constructor."""
        threading.Thread.__init__(self)
        self.daemon = daemon
        self.bp = threading.Event()
        self.closed = False
        self.running = False
        self.cnt = 0

        # do not print on stdout when running unittests
        self.testrun = reduce(lambda x, y: x or (y == 'unittest'),
                                        [False] + sys.modules.keys())

    def close(self):
        """Close the target."""
        self.closed = True

    def interrupt(self):
        """Interrupt the debuggee."""
        if not self.running:
            return False
        self.running = False
        self.bp.clear()
        return True

    def run_continue(self):
        """Start or continue the debuggee."""
        if self.running:
            return False
        self.running = True
        self.bp.set()
        return True

    def step(self):
        """Do a single step."""
        if self.running:
            return False
        self.bp.set()
        return True

    def __repr__(self):
        """Return the target representation."""
        return "Target: {'running': %s, 'closed': %s}" % (self.running,
                                                                self.closed)

    def run(self):
        """Run the target."""
        while not self.closed:
            if self.bp.isSet():
                if self.cnt == 0 and not self.daemon and not self.testrun:
                    print >> sys.stderr, 'Inferior starting.\n'
                self.cnt += 1
                if not self.daemon and not self.testrun:
                    print >> sys.stderr, 'value %d\n' % self.cnt

                # end the step command, when not running
                if not self.running:
                    self.bp.clear()
                else:
                    time.sleep(1)

            self.bp.wait(self.TARGET_TIMEOUT)

class Varobj(object):
    """The Simple varobj class.

    Instance attributes:
        var: dict
            dictionary of {name:value}, name: str, value: int
        current: str
            the currently hilited name
        hilite: boolean
            when True, current is hilited
        dirty: boolean
            True when there is a change in the varobj instance

    """

    def __init__(self):
        """Constructor."""
        self.var = {}
        self.current = None
        self.hilite = False
        self.dirty = False

    def add(self, name):
        """Add a varobj."""
        self.var[name] = 1
        self.current = name
        self.hilite = True
        self.dirty = True

    def _next(self):
        """Return the next candidate for hilite."""
        size = len(self.var)
        if size == 0:
            return None
        l = self.var.keys()
        try:
            i = (l.index(self.current) + 1) % size
            return l[i]
        except ValueError:
            return l[0]

    def next(self):
        """Set next name to hilite and increment its value."""
        self.current = self._next()
        if self.current is not None:
            self.var[self.current] += 1
            self.hilite = True
            self.dirty = True

    def delete(self, name):
        """Delete a varobj."""
        try:
            del self.var[name]
            self.dirty = True
            if name == self.current:
                self.current = None
                self.hilite = False
        except KeyError:
            return False
        return True

    def stale(self):
        """Make all varobjs stale."""
        self.hilite = False

    def clear(self):
        """Clear all varobjs."""
        if self.var:
            self.dirty = True
        self.var.clear()
        self.current = None
        self.hilite = False

    def __str__(self):
        """Return a string representation of the varobj."""
        varstr = ''
        for (name, value) in self.var.iteritems():
            if name == self.current and self.hilite:
                hilite = '*'
            else:
                hilite = '='
            varstr += '%12s ={%s} %d\n' % (name, hilite, value)
        self.dirty = False
        return varstr

class Simple(debugger.Debugger):
    """The Simple debugger is a concrete subclass of Debugger.

    Instance attributes:
        bp_id: int
            breakpoint number
        inferior: Target
            the debuggee
        step_bufname: str
            name of the buffer we are stepping into, this is the first buffer
            where a breakpoint has been set
        lnum: int
            frame lnum
        varobj: Varobj
            the list of varobjs

    """

    def __init__(self, *args):
        """Constructor."""
        debugger.Debugger.__init__(self, *args)
        self.pyclewn_cmds.update(
            {
                'dbgvar':(),
                'delvar':(),
                'sigint':(),
                'symcompletion':(),
            })
        self.cmds.update(SIMPLE_CMDS)
        self.mapkeys.update(MAPKEYS)
        self.bp_id = 0
        self.inferior = None
        self.step_bufname = None
        self.lnum = 0
        self.varobj = Varobj()

    def _start(self):
        """Start the debugger."""
        debugger.Debugger._start(self)
        self.prompt()

        # start the debuggee
        if self.inferior is None:
            self.inferior = Target(self.options.daemon)
            self.inferior.start()

    def close(self):
        """Close the debugger."""
        debugger.Debugger.close(self)

        # close the debuggee
        if self.inferior is not None:
            self.inferior.close()
            self.inferior = None

    def move_frame(self, show):
        """Show the frame sign or hide it when show is False.

        The frame sign is displayed from the first line (lnum 1), to the
        first enabled breakpoint in the stepping buffer.

        """
        # a stepping buffer is required
        if show and self.step_bufname:
            lnum_list = self.get_lnum_list(self.step_bufname)
            assert lnum_list
            self.show_frame(self.step_bufname, self.lnum + 1)
            self.lnum += 1
            self.lnum %= min(lnum_list)
            self.varobj.next()
        else:
            # hide frame
            self.show_frame()

    #-----------------------------------------------------------------------
    #   commands
    #-----------------------------------------------------------------------

    def pre_cmd(self, cmd, args):
        """The method called before each invocation of a 'cmd_xxx' method."""
        if args:
            cmd = '%s %s' % (cmd, args)
        self.console_print('%s\n', cmd)

        # turn off all hilited variables
        self.varobj.stale()

    def post_cmd(self, cmd, args):
        """The method called after each invocation of a 'cmd_xxx' method."""
        unused = cmd
        unused = args
        # to preserve window order appearance, all the writing to the
        # console must be done before starting to handle the (clewn)_dbgvar
        # buffer when processing Cdbgvar
        # update the vim debugger variable buffer with the variables values
        varobj = self.varobj
        self.update_dbgvarbuf(varobj.__str__, varobj.dirty)

    def default_cmd_processing(self, cmd, args):
        """Process any command whose cmd_xxx method does not exist."""
        unused = cmd
        unused = args
        self.console_print('Command ignored.\n')
        self.prompt()

    def cmd_break(self, cmd, args):
        """Set a breakpoint at a specified line.

        The required argument of the vim user command is 'fname:lnum'.

        """
        unused = cmd
        result = 'Invalid arguments.\n'

        name, lnum = debugger.name_lnum(args)
        if name is None:
            return
        if name:
            self.bp_id += 1
            self.add_bp(self.bp_id, name, lnum)
            result = 'Breakpoint %d at file %s, line %d.\n' % \
                                            (self.bp_id, name, lnum)

            # initialize the name of the stepping buffer
            if not self.step_bufname:
                self.step_bufname = name
                self.lnum = 0

        self.console_print(result)
        self.prompt()

    def cmd_clear(self, cmd, args):
        """Clear all breakpoints at a specified line.

        The required argument of the vim user command is 'fname:lnum'.

        """
        unused = cmd
        result = 'Invalid arguments.\n'

        name, lnum = debugger.name_lnum(args)
        if name is None:
            return
        if name:
            deleted  = self.delete_all(name, lnum)
            if not deleted:
                result = 'No breakpoint at %s:%d.\n'    \
                                % (name, lnum)
            else:
                result = 'Deleted breakpoints %s\n'     \
                                % ' '.join([str(num) for num in deleted])

                # disable stepping when no enabled breakpoints
                if name == self.step_bufname \
                        and not self.get_lnum_list(name):
                    self.step_bufname = None
                    self.lnum = 0

        self.console_print(result)
        self.prompt()

    def cmd_dbgvar(self, cmd, args):
        """Add a variable to the debugger variable buffer."""
        unused = cmd
        args = args.split()
        # two arguments are required
        if len(args) != 2:
            self.console_print('Invalid arguments.\n')
        else:
            self.varobj.add(args[0])
        self.prompt()

    def cmd_delvar(self, cmd, args):
        """Delete a variable from the debugger variable buffer."""
        unused = cmd
        args = args.split()
        # one argument is required
        if len(args) != 1:
            self.console_print('Invalid arguments.\n')
        elif not self.varobj.delete(args[0]):
            self.console_print('"%s" not found.\n' % args[0])
        self.prompt()

    def cmd_help(self, *args):
        """Print help on the simple commands."""
        debugger.Debugger.cmd_help(self, *args)
        self.prompt()

    def set_bpstate(self, cmd, args, enable):
        """Change the state of one breakpoint."""
        unused = cmd
        args = args.split()
        result = 'Invalid arguments.\n'

        # accept only one argument, for now
        if len(args) == 1:
            try:
                bp_id = int(args[0])
            except ValueError:
                pass
            else:
                result = ''
                if not self.update_bp(bp_id, not enable):
                    result = 'No breakpoint number %d.\n' % bp_id

        self.console_print(result)
        self.prompt()

    def cmd_disable(self, cmd, args):
        """Disable one breakpoint.

        The required argument of the vim user command is the breakpoint number.

        """
        self.set_bpstate(cmd, args, False)

    def cmd_enable(self, cmd, args):
        """Enable one breakpoint.

        The required argument of the vim user command is the breakpoint number.

        """
        self.set_bpstate(cmd, args, True)

    def cmd_print(self, cmd, args):
        """Print a value."""
        unused = cmd
        if args:
            self.console_print('%s\n', args)
        self.prompt()

    def cmd_step(self, *args):
        """Step program until it reaches a different source line."""
        unused = args
        assert self.inferior is not None
        if not self.get_lnum_list(self.step_bufname):
            self.console_print('No breakpoint enabled at %s.\n', self.step_bufname)
            self.move_frame(False)
        else:
            if self.inferior.step():
                self.move_frame(True)
            else:
                self.console_print('The inferior progam is running.\n')
        self.prompt()

    def cmd_continue(self, *args):
        """Continue the program being debugged, also used to start the program."""
        unused = args
        assert self.inferior is not None
        if not self.get_lnum_list(self.step_bufname):
            self.console_print('No breakpoint enabled at %s.\n', self.step_bufname)
        else:
            if not self.inferior.run_continue():
                self.console_print('The inferior progam is running.\n')
        self.move_frame(False)
        self.prompt()

    def cmd_interrupt(self, *args):
        """Interrupt the execution of the debugged program."""
        unused = args
        assert self.inferior is not None
        if self.inferior.interrupt():
            self.move_frame(True)
        self.prompt()

    def cmd_quit(self, *args):
        """Quit the current simple session."""
        unused = args
        self.varobj.clear()
        self.close()

    def cmd_sigint(self, *args):
        """Send a <C-C> character to the debugger (not implemented)."""
        unused = self
        unused = args
        self.console_print('Not implemented.\n')
        self.prompt()

    def cmd_symcompletion(self, *args):
        """Populate the break and clear commands with symbols completion (not implemented)."""
        unused = self
        unused = args
        self.console_print('Not implemented.\n')
        self.prompt()

    #-----------------------------------------------------------------------
    #   netbeans events
    #-----------------------------------------------------------------------

    def balloon_text(self, text):
        """Process a netbeans balloonText event.

        Used when 'ballooneval' is set and the mouse pointer rests on
        some text for a moment. "text" is a string, the text under
        the mouse pointer. Here we just show the text in a balloon.

        """
        debugger.Debugger.balloon_text(self, text)
        self.show_balloon('value: "%s"' % text)

