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

"""The clewn package.

"""
import sys
try:
    import clewn.__version__
    __tag__ = clewn.__version__.tag
    __changeset__ = clewn.__version__.changeset
except ImportError:
    __tag__ = 'unknown'
    __changeset__ = ''

__all__ = ['__tag__', '__changeset__', 'ClewnError']
Unused = __tag__
Unused = __changeset__

class ClewnError(Exception):
    """Base class for pyclewn exceptions."""

# the subprocess module is required (new in python 2.4)
if sys.version_info < (2, 4):
    print >> sys.stderr, "Python 2.4 or above is required by pyclewn."
    sys.exit(1)
elif sys.version_info >= (3, 0):
    sys.stderr.write("This version of pyclewn does not support Python 3.\n")
    sys.exit(1)

