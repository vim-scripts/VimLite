Build Instruction
1. Open ctags58m.vlworkspace with VimLite.
2. Select 'Release_Min' build target. ('Release_Min_Win32' if you're on Windows)
3. Build 'IntExpr' project.
4. Build 'DataTypes' project.
5. Build 'ctags58m' project.
6. On Linux
     Copy 'Release_Min/ctags58m' -> '~/.vimlite/bin/vlctags2'
   On Windows
     Copy 'Release_Min_Win32/ctags58m.exe' -> "$VIM/vimlite/bin/vlctags2.exe"


---------- DEPRECATED ----------
Dependents libqalculate, run 'sudo apt-get install libqalculate-dev' to install it.
If you are not on ubuntu, install corresponding package, and modify the 'Linker Options' of ctags58m project.

It seems to need libxml2-dev and libglib2.0-dev
'sudo apt-get install libxml2-dev libglib2-dev'

Build Instruction
1. Open ctags58m.vlworkspace with VimLite.
2. Build 'DataTypes' project.
3. Build 'ctags58m' project.
4. Copy 'Release/ctags58m' -> '~/.vimlite/bin/vlctags2'.
