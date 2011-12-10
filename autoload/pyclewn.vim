" pyclewn run time file
" Maintainer:   <xdegaye at users dot sourceforge dot net>
"
" Configure VIM to be used with pyclewn and netbeans
"
if exists("s:did_pyclewn")
    finish
endif
let s:did_pyclewn = 1

let s:start_err = "Error: pyclewn failed to start, "
let s:start_err .= "run the 'pyclewn' program to get the cause of the problem."

" The following variables define how pyclewn is started when
" the ':Pyclewn' vim command is run.
" They may be changed to match your preferences.

if has('win32') || has('win64')
    let s:pgm = fnamemodify($VIM . '\vimlite\bin\pyclewn', ":p")
else
    let s:pgm = fnamemodify("~/.vimlite/bin/pyclewn", ":p")
endif

if !exists('g:VLWDbgFrameSignBackground')
    let g:VLWDbgFrameSignBackground = 'DarkMagenta'
endif

if !exists('g:VLWDbgProjectFile')
    let g:VLWDbgProjectFile = ''
endif

if exists("pyclewn_args")
  let s:args = pyclewn_args
else
  let s:args = "--window=top --maxlines=10000 --foreground=Cyan,Green,none "
              \. "--background=none,none," . g:VLWDbgFrameSignBackground . " "
              \. "--frametext=''"
endif

if exists("pyclewn_connection")
  let s:connection = pyclewn_connection
else
  let s:connection = "localhost:3219:changeme"
endif

" Uncomment the following line to print full traces in a file named 'logfile'
" for debugging purpose.
" let s:args .= " --level=nbdebug --file=logfile"

" The 'Pyclewn' command starts pyclewn and vim netbeans interface.
let s:fixed = "--daemon --editor= --netbeans=" . s:connection . " --cargs="

" Run the 'Cinterrupt' command to open the console
function s:start_pdb(args)
    let argl = split(a:args)
    if index(argl, "--pdb") != -1
        " find the prefix
        let prefix = "C"
        let idx = index(argl, "-x")
        if idx == -1
            let idx = index(argl, "--prefix")
            if idx == -1
                for item in argl
                    if stridx(item, "--prefix") == 0
                        let pos = stridx(item, "=")
                        if pos != -1
                            let prefix = strpart(item, pos + 1)
                        endif
                    endif
                endfor
            endif
        endif

        if idx != -1 && len(argl) > idx + 1
            let prefix = argl[idx + 1]
        endif

        " hack to prevent Vim being stuck in the command line with '--More--'
        echohl WarningMsg
        echo "About to run the 'interrupt' command."
        call inputsave()
        call input("Press the <Enter> key to continue.")
        call inputrestore()
        echohl None
        exe prefix . "interrupt"
    endif
endfunction

" Check wether pyclewn successfully wrote the script file
function s:pyclewn_ready(filename)
    let l:cnt = 1
    let l:max = 20
    echohl WarningMsg
    while l:cnt < l:max
        echon "."
        let l:cnt = l:cnt + 1
        if filereadable(a:filename)
            break
        endif
        sleep 200m
    endwhile
    echohl None
    if l:cnt == l:max
        throw s:start_err
    endif
    call s:info("The pyclewn process has been started successfully.\n")
endfunction

" Start pyclewn and vim netbeans interface.
function s:start(args)
    if !exists(":nbstart")
        throw "Error: the ':nbstart' vim command does not exist."
    endif
    if has("netbeans_enabled")
        throw "Error: netbeans is already enabled and connected."
    endif
    if has('unix') && !executable(s:pgm)
        throw "Error: '" . s:pgm . "' cannot be found or is not an executable."
    endif
    let l:tmpfile = tempname()

    " remove console and dbgvar buffers from previous session
    if bufexists("(clewn)_console")
        bwipeout (clewn)_console
    endif
    if bufexists("(clewn)_dbgvar")
        bwipeout (clewn)_dbgvar
    endif

    let sProjFileOpt = ''
    if g:VLWDbgProjectFile !=# ''
        let sProjFileOpt = ',' . shellescape(g:VLWDbgProjectFile)
    endif

    " start pyclewn and netbeans
    call s:info("Starting pyclewn, please wait...\n")
    let b:cmd = "silent !" . s:pgm . " " . a:args . " " . s:fixed . l:tmpfile . " &"
    if 0
        exe "silent !" . s:pgm . " " . a:args . " " . s:fixed . l:tmpfile . " &"
    else
        let sTerminal = 'xterm'
        let sTitleSw = '-T'
        if executable('gnome-terminal')
            let sTerminal = 'gnome-terminal'
            let sTitleSw = '-t'
        endif
python << PYTHON_EOF
import subprocess
import platform
import os
import vim
envDict = os.environ.copy()
envDict['VIM_SERVERNAME'] = vim.eval("v:servername")
if platform.system() == 'Windows':
    pyclewnProcess = subprocess.Popen(
        r'"C:\Windows\system32\cmd.exe" /c '
        + '"python "%s" %s --gdb=async%s --netbeans=%s --cargs=%s"' \
            % (vim.eval('s:pgm'), vim.eval('a:args'), vim.eval('sProjFileOpt'),
               vim.eval('s:connection'), vim.eval('l:tmpfile')),
        env=envDict)
else:
    envDict['LC_ALL'] = 'en_US.UTF-8'
    pyclewnProcess = subprocess.Popen(
        [vim.eval("sTerminal"), 
         vim.eval("sTitleSw"), 
         'Pyclewn', 
         '-e', 
         "sh -c '%s %s --gdb=async%s --netbeans=%s --cargs=%s'" \
             % (vim.eval('s:pgm'), vim.eval('a:args'), vim.eval('sProjFileOpt'),
                vim.eval('s:connection'), vim.eval('l:tmpfile'))],
        env=envDict)
PYTHON_EOF
    endif
    call s:info("'pyclewn' has been started.\n")
    call s:info("Running nbstart, <C-C> to interrupt.\n")
    call s:pyclewn_ready(l:tmpfile)
    exe "nbstart :" . s:connection

    " source vim script
    if has("netbeans_enabled")
        if !filereadable(l:tmpfile)
            nbclose
            throw s:start_err
        endif
        " the pyclewn generated vim script is sourced only once
        if ! exists("s:source_once")
            let s:source_once = 1
            exe "source " . l:tmpfile
        endif
        call s:info("The netbeans socket is connected.\n")
        call s:start_pdb(a:args)
    else
        throw "Error: the netbeans socket could not be connected."
    endif
endfunction

function pyclewn#StartClewn(...)
    " command to start pdb: Pyclewn pdb foo.py arg1 arg2 ....
    let l:args = s:args
    if a:0 != 0
        if has("gui_win32")
            call s:error("The Pyclewn command on Windows does not accept arguments.")
            return
        endif
        if a:1 == "pdb"
            if a:0 == 2 && filereadable(a:2) == 0
                call s:error("File '" . a:2 . "' is not readable.")
                return
            endif
            let l:args .= " --pdb"
            if a:0 > 1
                let l:args .= " --args \"" . join(a:000[1:], ' ') . "\""
            endif
        else
            call s:error("Invalid optional first argument: must be 'pdb'.")
            return
        endif
    endif

    try
        call s:start(l:args)
    catch /.*/
        call s:info("The 'Pyclewn' command has been aborted.\n")
        call s:error(v:exception)
        " vim console screen is garbled, redraw the screen
        if !has("gui_running")
            redraw!
        endif
        " clear the command line
        echo "\n"
    endtry
endfunction

function s:info(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

function s:error(msg)
    echohl ErrorMsg
    echo a:msg
    call inputsave()
    call input("Press the <Enter> key to continue.")
    call inputrestore()
    echohl None
endfunction
