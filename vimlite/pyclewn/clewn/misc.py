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

"""Pyclewn miscellaneous classes and functions."""

import sys
import os
import os.path
import re
import tempfile
import logging
import subprocess
import atexit
import pprint
import itertools
import cStringIO

from clewn import *

VIM73_BUG_SLEEP_TIME = 0.500
DOUBLEQUOTE = '"'
QUOTED_STRING = r'"((?:\\"|[^"])+)"'
NBDEBUG = 5
NBDEBUG_LEVEL_NAME = 'nbdebug'
LOG_LEVELS = 'critical, error, warning, info, debug or ' + NBDEBUG_LEVEL_NAME

RE_TOKEN_SPLIT = r'\s*"((?:\\"|[^"])+)"\s*|\s*([^ "]+)\s*'     \
                 r'# RE: split a string in tokens, handling quotes'
RE_ESCAPE = r'["\n\t\r\\]'                                      \
            r'# RE: escaped characters in a string'
RE_UNESCAPE = r'\\["ntr\\]'                                     \
              r'# RE: escaped characters in a quoted string'
Unused = VIM73_BUG_SLEEP_TIME
Unused = NBDEBUG
Unused = LOG_LEVELS
MISSING = object()

# compile regexps
re_quoted = re.compile(QUOTED_STRING, re.VERBOSE)
re_token_split = re.compile(RE_TOKEN_SPLIT, re.VERBOSE)
re_escape = re.compile(RE_ESCAPE, re.VERBOSE)
re_unescape = re.compile(RE_UNESCAPE, re.VERBOSE)
Unused = re_quoted

def logmethods(name):
    """Return the set of logging methods for the 'name' logger."""
    logger = logging.getLogger(name)
    return (
        logger.critical,
        logger.error,
        logger.warning,
        logger.info,
        logger.debug,
    )

# set the logging methods
(critical, error, warning, info, debug) = logmethods('misc')
Unused = error
Unused = warning
Unused = info

def previous_evaluation(f, previous={}):
    """Decorator for functions returning previous result when args are unchanged."""
    def _dec(*args):
        """The decorator."""
        if f in previous and previous[f][0] == args:
            return previous[f][1]
        previous[f] = [args]
        ret = f(*args)
        previous[f].append(ret)
        return ret
    return _dec

# 'any' new in python 2.5
try:
    any = any
except NameError:
    def any(iterable):
        """Return True if any element of the iterable is true."""
        for element in iterable:
            if element:
                return True
        return False

def escape_char(matchobj):
    """Escape special characters in string."""
    if matchobj.group(0) == '"': return r'\"'
    if matchobj.group(0) == '\n': return r'\n'
    if matchobj.group(0) == '\t': return r'\t'
    if matchobj.group(0) == '\r': return r'\r'
    if matchobj.group(0) == '\\': return r'\\'
    assert False

def quote(msg):
    """Quote 'msg' and escape special characters."""
    return '"%s"' % re_escape.sub(escape_char, msg)

def dequote(msg):
    """Return the list of whitespace separated tokens from 'msg', handling
    double quoted substrings as a token.

    >>> print dequote(r'"a c" b v "this \\"is\\" foobar argument" Y ')
    ['a c', 'b', 'v', 'this "is" foobar argument', 'Y']

    """
    split = msg.split(DOUBLEQUOTE)
    if len(split) % 2 != 1:
        raise ClewnError("uneven number of double quotes in '%s'" % msg)

    match = re_token_split.findall(msg)
    return [unquote(x) or y for x, y in match]

def unescape_char(matchobj):
    """Remove escape on special characters in quoted string."""
    if matchobj.group(0) == r'\"': return '"'
    if matchobj.group(0) == r'\n': return '\n'
    if matchobj.group(0) == r'\t': return '\t'
    if matchobj.group(0) == r'\r': return '\r'
    if matchobj.group(0) == r'\\': return '\\'
    assert False

def unquote(msg):
    """Remove escapes from escaped characters in a quoted string."""
    return '%s' % re_unescape.sub(unescape_char, msg)

def norm_unixpath(line, ispath=False):
    """Convert backward slashes to forward slashes on Windows.

    If 'ispath' is True, then convert the whole line.
    Otherwise, this is done for all existing paths in line
    and handles quoted paths.
    """
    if os.name != 'nt':
        return line
    if ispath:
        return line.replace('\\', '/')

    # match is a list of tuples
    # first element of tuple is '' when it is a keyword
    # second element of tuple is '' when it is a quoted string
    match = re_token_split.findall(line)
    if not match:
        return line
    result = []
    changed = False
    for elem in match:
        quoted = False
        if not elem[0]:
            token = elem[1]
        elif not elem[1]:
            quoted = True
            token = elem[0]
        else:
            assert False
        if os.path.exists(token) and '\\' in token:
            token = token.replace('\\', '/')
            changed = True
        if quoted:
            token = '"' + token + '"'
        result.append(token)
    if not changed:
        return line
    return ' '.join(result)

def parse_keyval(regexp, line):
    """Return a dictionary built from a string of 'key="value"' pairs.

    The regexp format is:
        r'(key1|key2|...)=%s' % QUOTED_STRING

    """
    parsed = regexp.findall(line)
    if parsed and isinstance(parsed[0], tuple) and len(parsed[0]) == 2:
        keyval_dict = {}
        for (key, value) in parsed:
            keyval_dict[key] = unquote(value)
        return keyval_dict
    debug('not an iterable of key/value pairs: "%s"', line)
    return None

# subprocess.check_call does not exist in Python 2.4
def check_call(*popenargs, **kwargs):
    """Run command with arguments.  Wait for command to complete.  If
    the exit code was zero then return, otherwise raise
    CalledProcessError.  The CalledProcessError object will have the
    return code in the returncode attribute.

    The arguments are the same as for the Popen constructor.  Example:

    check_call(["ls", "-l"])

    """
    retcode = subprocess.call(*popenargs, **kwargs)
    cmd = kwargs.get("args")
    if cmd is None:
        cmd = popenargs[0]
    if retcode:
        raise CalledProcessError(retcode, cmd)
    return retcode

def smallest_prefix(word, other):
    """Return the smallest prefix of 'word', not prefix of 'other'."""
    assert word
    if other.startswith(word):
        return ''
    for i in range(len(word)):
        p = word[0:i+1]
        if p != other[0:i+1]:
            break
    return p

def smallpref_inlist(word, strlist):
    """Return the smallest prefix of 'word' that allows completion in 'strlist'.

    Return 'word', when it is a prefix of one of the keywords in 'strlist'.

    """
    assert strlist
    assert word not in strlist
    s = sorted(strlist + [word])
    i = s.index(word)
    previous = next = ''
    if i > 0:
        previous = smallest_prefix(word, s[i - 1]) or word
    if i < len(s) - 1:
        next = smallest_prefix(word, s[i + 1]) or word
    return max(previous, next)

def unlink(filename):
    """Unlink a file."""
    if filename and os.path.exists(filename):
        try:
            os.unlink(filename)
        except OSError:
            pass

def last_traceback():
    """Return the last trace back."""
    t, v, tb = sys.exc_info()
    assert tb
    while tb:
        filename = tb.tb_frame.f_code.co_filename
        lnum = tb.tb_lineno
        last_tb = tb
        tb = tb.tb_next
    del tb

    return t, v, filename, lnum, last_tb


class PrettyPrinterString(pprint.PrettyPrinter):
    """Strings are printed with str() to avoid duplicate backslashes."""

    def format(self, object, context, maxlevels, level):
        """Format un object."""
        unused = self
        if type(object) is str:
            return "'" + str(object) + "'", True, False
        return pprint._safe_repr(object, context, maxlevels, level)

def pformat(object, indent=1, width=80, depth=None):
    """Format a Python object into a pretty-printed representation."""
    return PrettyPrinterString(
                    indent=indent, width=width, depth=depth).pformat(object)

class CalledProcessError(ClewnError):
    """This exception is raised when a process run by check_call() returns
    a non-zero exit status.  The exit status will be stored in the
    returncode attribute.

    """

    def __init__(self, returncode, cmd):
        """Constructor."""
        ClewnError.__init__(self)
        self.returncode = returncode
        self.cmd = cmd

    def __str__(self):
        """Return the error message."""
        return "Command '%s' returned non-zero exit status %d"  \
                                        % (self.cmd, self.returncode)

class TmpFile(file):
    """An instance of this class is a writtable temporary file object."""

    def __init__(self, prefix):
        """Constructor."""
        self.tmpname = None
        try:
            fd, self.tmpname = tempfile.mkstemp('.clewn', prefix)
            os.close(fd)
            file.__init__(self, self.tmpname, 'w')
        except (OSError, IOError):
            unlink(self.tmpname)
            critical('cannot create temporary file'); raise
        else:
            atexit.register(unlink, self.tmpname)

    def __del__(self):
        """Unlink the file."""
        unlink(self.tmpname)

class Singleton(object):
    """A singleton, there is only one instance of this class."""

    def __new__(cls, *args, **kwds):
        """Create the single instance."""
        it = cls.__dict__.get("__it__")
        if it is not None:
            return it
        cls.__it__ = it = object.__new__(cls)
        it.init(*args, **kwds)
        return it

    def init(self, *args, **kwds):
        """Override in subclass."""
        pass

class OrderedDict(dict):
    """An ordered dictionary.

    Ordered dictionaries are just like regular dictionaries but they
    remember the order that items were inserted. When iterating over an
    ordered dictionary, the items are returned in the order their keys were
    first added.
    """

    def __init__(self, *args, **kwds):
        """Constructor."""
        if len(args) > 1:
            raise TypeError('expected at most 1 arguments, got %d' % len(args))
        if not hasattr(self, '_keys'):
            self._keys = []
        self.update(*args, **kwds)

    def clear(self):
        """Remove all items."""
        del self._keys[:]
        dict.clear(self)

    def update(self, other=None, **kwargs):
        """Update and overwrite key/value pairs."""
        # make progressively weaker assumptions about "other"
        if other is None:
            pass
        elif hasattr(other, 'iteritems'):
            for k, v in other.iteritems():
                self[k] = v
        elif hasattr(other, 'keys'):
            for k in other.keys():
                self[k] = other[k]
        else:
            for k, v in other:
                self[k] = v
        if kwargs:
            self.update(kwargs)

    def copy(self):
        """A  shallow copy."""
        return self.__class__(self)

    def keys(self):
        """An ordered copy of the list of keys."""
        return self._keys[:]

    def values(self):
        """An ordered of the list of values by keys."""
        return map(self.get, self._keys)

    def items(self):
        """An ordered copy of the list of (key, value) pairs."""
        return zip(self._keys, self.values())

    def iteritems(self):
        """Return an ordered iterator over (key, value) pairs."""
        return itertools.izip(self._keys, self.itervalues())

    def pop(self, key, default=MISSING):
        """self[key] if key in self, else default (and remove key)."""
        if key in self:
            self._keys.remove(key)
            return dict.pop(self, key)
        elif default is MISSING:
            return dict.pop(self, key)
        return default

    def popitem(self):
        """Remove the (key, value) pair of the last added key."""
        if not self:
            raise KeyError('dictionary is empty')
        key = self._keys.pop()
        value = dict.pop(self, key)
        return key, value

    def setdefault(self, key, failobj=None):
        """self[key] if key in self, else failobj (also setting it)."""
        value = dict.setdefault(self, key, failobj)
        if key not in self._keys:
            self._keys.append(key)
        return value

    def itervalues(self):
        """Return an ordered iterator over the values."""
        return itertools.imap(self.get, self._keys)

    def __setitem__(self, key, value):
        """Called to implement assignment to self[key]."""
        if key not in self:
            self._keys.append(key)
        dict.__setitem__(self, key, value)

    @classmethod
    def fromkeys(cls, iterable, value=None):
        """Create a new dictionary with keys from seq and values set to value."""
        d = cls()
        for key in iterable:
            d[key] = value
        return d

    def __delitem__(self, key):
        """Called to implement deletion of self[key]."""
        dict.__delitem__(self, key)
        self._keys.remove(key)

    def __iter__(self):
        """Return an ordered iterator over the keys."""
        return iter(self._keys)
    iterkeys = __iter__

    def __repr__(self):
        """Return the string representation."""
        if not self:
            return '%s()' % (self.__class__.__name__,)
        return '%s(%r)' % (self.__class__.__name__, self.items())

class StderrHandler(logging.StreamHandler):
    """Stderr logging handler."""

    def __init__(self):
        """Constructor."""
        self.strbuf = cStringIO.StringIO()
        self.doflush = True
        logging.StreamHandler.__init__(self, self.strbuf)

    def should_flush(self, doflush):
        """Set flush mode."""
        self.doflush = doflush

    def write(self, string):
        """Write to the StringIO buffer."""
        self.strbuf.write(string)

    def flush(self):
        """Flush to stderr when enabled."""
        if self.doflush:
            value = self.strbuf.getvalue()
            if value:
                print >>sys.stderr, value
                self.strbuf.truncate(0)

    def close(self):
        """Close the handler."""
        self.flush()
        self.strbuf.close()
        logging.StreamHandler.close(self)

def _test():
    """Run the doctests."""
    import doctest
    doctest.testmod()

if __name__ == "__main__":
    _test()

