" Delta.vim - commands for opening and managing diff windows in Git and Mercurial repositories
" vim: et ts=8 sts=2 sw=2
"
" Last Change: 30 Dec 2014
" Copyright: 2011 Tuenti Technologies S.L.
" Copyright: 2012-2014 Andrew Bettison
" License: GPL3
" Author: Andrew Bettison <andrew@iverin.com.au>
" Maintainer: Andrew Bettison <andrew@iverin.com.au>

" ------------------------------------------------------------------------------
" Exit if this app has already been loaded or in vi compatible mode.
"
if exists("g:loaded_DeltaVim") || &cp
  finish
endif
let g:loaded_DeltaVim = 1

" Standard Vim plugin boilerplate.
let s:keepcpo = &cpo
set cpo&vim

" Settings that can be overridden by the user.
if !exists('g:DeltaVim_gitTrunkBranch')
  let g:DeltaVim_gitTrunkBranch="master"
endif
if !exists('g:DeltaVim_hgTrunkBranch')
  let g:DeltaVim_hgTrunkBranch="default"
endif
if !exists('*DeltaVim_isReleaseTag')
  func DeltaVim_isReleaseTag(tagname)
    " Any tag with a name that looks like a version number, eg, 1.4, 0.92.7
    " is probably a release.  Also, any tag beginning with the prefix
    " 'release' (case insensitive).
    return a:tagname =~ '\(^\d\+\(\.\d\+\)*$\|^\crelease\)'
  endfunc
endif

" Save the <Leader> char as it was when the mappings were defined, so the help
" message can quote the correct key sequences even if mapleader gets changed.
let s:helpleader = '\'
if exists("g:mapleader") && g:mapleader != ''
  let s:helpleader = g:mapleader
endif
" TODO This should be integrated into the Vim help system.
func s:help()
  " TODO Adapt this message to the current window width
  let m = s:helpleader
  echomsg 'cmd  action          description'
  echomsg '================================'
  echomsg m.'?   Help            Print this message'
  echomsg m.'l   Log             Open a new window listing the log of all changes to the current file (see below for key bindings available in the log window)'
  echomsg m.'L                   Close the log window opened with '.m.'l'
  echomsg m.'w   Working copy    Open a new diff window on the working copy (uncommitted files)'
  echomsg m.'W                   Close the diff window opened with '.m.'w'
  echomsg m.'h   Head            Open a new diff window on the current branch head (Git HEAD, Hg parent 1)'
  echomsg m.'H                   Close the diff window opened with '.m.'h'
  echomsg m.'t   Trunk           Open a new diff window on the trunk branch head (Git "'.g:DeltaVim_gitTrunkBranch.'", Hg "'.g:DeltaVim_hgTrunkBranch.'")'
  echomsg m.'T                   Close the diff window opened with '.m.'t'
  echomsg m.'o   Branch origin   Open a new diff window on current branch origin (Hg only; earliest revision on current named branch)'
  echomsg m.'O                   Close the diff window opened with '.m.'o'
  echomsg m.'r   Release         Open a new diff window on latest release (tag with "release" prefix or version number)'
  echomsg m.'R                   Close the diff window opened with '.m.'r'
  echomsg m.'p   Prior release   Open a new diff window on prior release (tag with "release" prefix or version number)'
  echomsg m.'P                   Close the diff window opened with '.m.'p'
  echomsg m.'m   Merged          Open a new diff window on the revision most recently merged into the current branch'
  echomsg m.'M                   Close the diff window opened with '.m.'m'
  echomsg m.'\   Close diffs     Close all diff windows opened with the above commands'
  echomsg m.'x   Close revision  Close all diff windows opened with the <Enter> command in the log window'
  echomsg m.'-   Close diff      Close current diff window'
" echomsg m.'=   Close all       Equivalent to '.m.'\ followed by '.m.'L'
  echomsg m.'|   Toggle main     Toggle the diff mode of the main file window. This is useful when two diff windows are open, to see only the changes between them'
  echomsg ' '
  echomsg 'During a merge:'
  echomsg m.'a   Common ancestor Open a new diff window on common merge ancestor (Git stage 1)'
  echomsg m.'A                   Close the diff window opened with '.m.'a'
  echomsg m.'m   Merge incoming  Open a new diff window on incoming merge head (Git stage MERGE_HEAD, Hg parent 2)'
  echomsg m.'M                   Close the diff window opened with '.m.'m'
  echomsg ' '
  echomsg 'Inside the log window:'
  echomsg '<Enter>              Open a diff window on the version of the current line.  If several lines are selected in visual mode, then opens two diff windows,'
  echomsg '                     on the versions at the start and end of the range'
  echomsg '+    Grow            Increase the vertical size of the log window by five lines'
  echomsg '-    Shrink          Decrease the vertical size of the log window by five lines'
  echomsg '=    Default         Set the size of the log window to its default size (ten lines high)'
  echomsg '_    Biggest         Maximise the log window to as large as Vim will permit it'
  echomsg 'm                    Move the cursor to the window editing the original source file'
  echomsg 'q                    Close the log window'
endfunc

" ------------------------------------------------------------------------------
" PUBLIC INTERFACE

" Default key bindings, only set where no binding already has been defined.
" TODO Allow user to define their own prefix, use <Leader> if no prefix defined
if !exists('no_plugin_maps') && !exists('no_deltavim_plugin_maps')
  if !hasmapto('<Plug>DeltaVimHelp')
    nmap <unique> <Leader>? <Plug>DeltaVimHelp
  endif
  if !hasmapto('<Plug>DeltaVimLogOpen')
    nmap <unique> <Leader>l <Plug>DeltaVimLogOpen
  endif
  if !hasmapto('<Plug>DeltaVimLogClose')
    nmap <unique> <Leader>L <Plug>DeltaVimLogClose
  endif
  if !hasmapto('<Plug>DeltaVimOpenWorking')
    nmap <unique> <Leader>w <Plug>DeltaVimOpenWorking
  endif
  if !hasmapto('<Plug>DeltaVimCloseWorking')
    nmap <unique> <Leader>W <Plug>DeltaVimCloseWorking
  endif
  if !hasmapto('<Plug>DeltaVimOpenHead')
    nmap <unique> <Leader>h <Plug>DeltaVimOpenHead
  endif
  if !hasmapto('<Plug>DeltaVimCloseHead')
    nmap <unique> <Leader>H <Plug>DeltaVimCloseHead
  endif
  if !hasmapto('<Plug>DeltaVimOpenTrunk')
    nmap <unique> <Leader>t <Plug>DeltaVimOpenTrunk
  endif
  if !hasmapto('<Plug>DeltaVimCloseTrunk')
    nmap <unique> <Leader>T <Plug>DeltaVimCloseTrunk
  endif
  if !hasmapto('<Plug>DeltaVimOpenBranchOrigin')
    nmap <unique> <Leader>o <Plug>DeltaVimOpenBranchOrigin
  endif
  if !hasmapto('<Plug>DeltaVimCloseBranchOrigin')
    nmap <unique> <Leader>O <Plug>DeltaVimCloseBranchOrigin
  endif
  if !hasmapto('<Plug>DeltaVimOpenNewestRelease')
    nmap <unique> <Leader>r <Plug>DeltaVimOpenNewestRelease
  endif
  if !hasmapto('<Plug>DeltaVimCloseNewestRelease')
    nmap <unique> <Leader>R <Plug>DeltaVimCloseNewestRelease
  endif
  if !hasmapto('<Plug>DeltaVimOpenPriorRelease')
    nmap <unique> <Leader>p <Plug>DeltaVimOpenPriorRelease
  endif
  if !hasmapto('<Plug>DeltaVimClosePriorRelease')
    nmap <unique> <Leader>P <Plug>DeltaVimClosePriorRelease
  endif
  if !hasmapto('<Plug>DeltaVimOpenMerge')
    nmap <unique> <Leader>m <Plug>DeltaVimOpenMerge
  endif
  if !hasmapto('<Plug>DeltaVimCloseMerge')
    nmap <unique> <Leader>M <Plug>DeltaVimCloseMerge
  endif
  if !hasmapto('<Plug>DeltaVimCloseAllDiffs')
    nmap <unique> <Leader>\ <Plug>DeltaVimCloseAllDiffs
  endif
  if !hasmapto('<Plug>DeltaVimCloseLogRevisions')
    nmap <unique> <Leader>x <Plug>DeltaVimCloseLogRevisions
  endif
  if !hasmapto('<Plug>DeltaVimCloseWindow')
    nmap <unique> <Leader>- <Plug>DeltaVimCloseWindow
  endif
" if !hasmapto('<Plug>DeltaVimCloseAll')
"   nmap <unique> <Leader>= <Plug>DeltaVimCloseAll
" endif
  if !hasmapto('<Plug>DeltaVimToggleOrigBuffer')
    nmap <unique> <Leader>| <Plug>DeltaVimToggleOrigBuffer
  endif
  if !hasmapto('<Plug>DeltaVimOpenCommonAncestor')
    nmap <unique> <Leader>a <Plug>DeltaVimOpenMergeCommonAncestor
  endif
  if !hasmapto('<Plug>DeltaVimCloseCommonAncestor')
    nmap <unique> <Leader>A <Plug>DeltaVimCloseMergeCommonAncestor
  endif
endif

" Default commands, will not replace existing commands with same name.
if !exists(':Delta')
  command -nargs=1 Delta call <SID>openRevisionDiff(<q-args>)
endif

" Global maps, available for user's own key bindings.
"
noremap <silent> <unique> <Plug>DeltaVimHelp :call <SID>help()<CR>
noremap <silent> <unique> <Plug>DeltaVimLogOpen :call <SID>openLog()<CR>
noremap <silent> <unique> <Plug>DeltaVimLogClose :call <SID>closeLog()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenWorking :call <SID>openWorkingDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseWorking :call <SID>closeWorkingDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenHead :call <SID>openHeadDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseHead :call <SID>closeHeadDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenTrunk :call <SID>openTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseTrunk :call <SID>closeTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenBranchOrigin :call <SID>openBranchOriginDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseBranchOrigin :call <SID>closeBranchOriginDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenNewestRelease :call <SID>openNewestReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseNewestRelease :call <SID>closeNewestReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenPriorRelease :call <SID>openPriorReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimClosePriorRelease :call <SID>closePriorReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenMerge :call <SID>openMergeDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseMerge :call <SID>closeMergeDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseAllDiffs :call <SID>closeAllDiffs()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseLogRevisions :call <SID>closeLogRevisionDiffs()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseWindow :call <SID>closeCurrentDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseAll :call <SID>closeAll()<CR>
noremap <silent> <unique> <Plug>DeltaVimToggleOrigBuffer :call <SID>toggleOrigBufferDiffMode()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenMergeCommonAncestor :call <SID>openMergeCommonAncestorDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseMergeCommonAncestor :call <SID>closeMergeCommonAncestorDiff()<CR>

" Whenever any buffer window goes away, if there are no more diff windows
" remaining, then turn off diff mode in the principal buffer.
autocmd BufHidden * call s:cleanUp("global BufHidden *")

" ------------------------------------------------------------------------------
" APPLICATION FUNCTIONS

let s:allDiffNames = ['working', 'ancestor', 'head', 'parent1', 'parent2', 'origin', 'trunk', 'newestRelease', 'priorRelease', 'merge', 'revision1', 'revision2']

" Close all diff windows and the log window.  This operation should leave no
" windows visible that were created by any mappings or functions in this plugin.
func s:closeAll()
  call s:closeLog()
  call s:closeAllDiffs()
endfunc

" Close all diff windows, but leave any other special windows, eg, the log
" window, open.
func s:closeAllDiffs()
  for diffname in s:allDiffNames
    call s:closeDiff(diffname)
  endfor
endfunc

" Close the current diff window.
func s:closeCurrentDiff()
  let curbuf = bufnr("%")
  for diffname in s:allDiffNames
    let varname = "t:".diffname."DiffBuffer"
    if exists(varname) && eval(varname) == curbuf
      call s:closeDiff(diffname)
    endif
  endfor
endfunc

" After any buffer is hidden, check if any diff buffers are still visible.  If
" not, then turn off diff mode, restore wrap mode, and clean up variables.
func s:cleanUp(desc)
  if exists('t:turnOffDiff') && t:turnOffDiff == bufnr('%')
    " This is a kludge, to work around a bug that the :diffoff! below does not turn
    " off diff mode in the buffer that is being left.
    diffoff
    unlet t:turnOffDiff
    call s:restoreWrapMode()
  endif
  if s:countDiffs() == 0
    diffoff!
    call s:restoreWrapMode()
    set noequalalways
    if exists('t:origDiffBuffer')
      let t:turnOffDiff = t:origDiffBuffer
      if !s:testLogExists()
        unlet! t:origDiffBuffer
      endif
    endif
  endif
  if !s:testLogExists()
    unlet! t:logBuffer
  endif
endfunc

func s:openRevisionDiff(rev)
  try
    if a:rev != ''
      if s:isGit()
        call s:openGitDiff('revision1', a:rev, a:rev)
      elseif s:isHg()
        call s:openHgDiff('revision1', a:rev, a:rev)
      endif
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeRevisionDiff(rev)
  call s:closeDiff('revision1')
endfunc

func s:openWorkingDiff()
  try
    call s:openDiff('working', '!cat %%:E', '', '', '')
  endtry
endfunc

" Whenever a buffer is written, refresh all the diff windows
autocmd BufWritePost * call s:refreshWorkingCopyDiff()

" After a buffer is written, check if the working copy diff is visible.  If
" so, then refresh it.
func s:refreshWorkingCopyDiff()
  if exists("t:workingDiffBuffer") && getbufvar(t:workingDiffBuffer, "readArg") != ''
    exe bufwinnr(t:workingDiffBuffer) 'wincmd w'
    setlocal modifiable
    silent %d
    silent exe '1read' b:readArg
    silent 1d
    setlocal nomodifiable
    diffupdate
    wincmd p
  endif
endfunc

func s:closeWorkingDiff()
  call s:closeDiff('working')
endfunc

func s:openHeadDiff()
  try
    if s:isGit()
      call s:openGitDiff('head', 'HEAD', '')
    elseif s:isHg()
      call s:openHgDiff('parent1', '.', '')
    else
      call s:notRepository(expand('%'))
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeHeadDiff()
  call s:closeDiff('head')
  call s:closeDiff('parent1')
endfunc

func s:openTrunkDiff()
  try
    if s:isGit()
      call s:openGitDiff('trunk', g:DeltaVim_gitTrunkBranch, '')
    elseif s:isHg()
      call s:openHgDiff('trunk', g:DeltaVim_hgTrunkBranch, '')
    else
      call s:notRepository(expand('%'))
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeTrunkDiff()
  call s:closeDiff('trunk')
endfunc

func s:openBranchOriginDiff()
  try
    if s:isGit()
      let rev = s:getGitForkPoint("origin/master")
      call s:openGitDiff('origin', rev, '')
    elseif s:isHg()
      let rev = get(s:getHgRevisions('--branch .'), -1, '')
      if rev != ''
        call s:openHgDiff('origin', rev, '')
      else
        call s:displayError('Cannot determine branch origin revision', [])
      endif
    else
      call s:notRepository(expand('%'))
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:commandfail/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeBranchOriginDiff()
  call s:closeDiff('origin')
endfunc

func s:openMergeDiff()
  try
    if s:isGit()
      if s:isGitWorkingMerge()
        call s:openGitDiff('merge', ':3', '')
      else
        call s:openGitDiff('merge', s:getGitLatestMerge("HEAD"), '')
      endif
    elseif s:isHg()
      " TODO: if a Mercurial merge is not in progress, then diff with the most recent p2
      " on the current branch
      call s:openHgDiff('parent2', 'p2()', '')
    else
      call s:notRepository(expand('%'))
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:notsupported/
  catch /^VimDelta:commandfail/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeMergeDiff()
  call s:closeDiff('merge')
endfunc

func s:openMergeCommonAncestorDiff()
  try
    if s:isGit()
      if !s:isGitWorkingMerge()
        call s:notMerging()
      endif
      call s:openGitDiff('ancestor', ':1', '')
    elseif s:isHg()
      if !s:isHgWorkingMerge()
        call s:notMerging()
      endif
      let rev = get(s:getHgRevisions('--rev "ancestor(parents())"'), -1, '')
      if rev == ''
        call s:displayError('Cannot determine ancestor revision', [])
        throw "VimDelta:notfound"
      endif
      call s:openHgDiff('ancestor', rev, '')
    else
      call s:notRepository(expand('%'))
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:notsupported/
  catch /^VimDelta:notmerge/
  catch /^VimDelta:commandfail/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeMergeCommonAncestorDiff()
  call s:closeDiff('ancestor')
endfunc

"func s:openLastMergedTrunkDiff()
"  let rev = s:latestHgDefaultMergeRevision()
"  if rev != ''
"    try
"      call s:openHgDiff('mergedTrunk', rev, '')
"    endtry
"  endif
"endfunc

"func s:closeLastMergedTrunkDiff()
"  call s:closeDiff('mergedTrunk')
"endfunc

func s:openReleaseDiff(diffname, rev, message)
  if a:rev == ''
    echohl WarningMsg
    echomsg a:message
    echohl None
    throw "VimDelta:notfound"
  endif
  if s:isGit()
    call s:openGitDiff(a:diffname, a:rev, a:rev)
  elseif s:isHg()
    call s:openHgDiff(a:diffname, a:rev, a:rev)
  endif
endfunc

func s:openNewestReleaseDiff()
  try
    call s:openReleaseDiff('newestRelease', s:newestReleaseTag(), "No release tag")
  catch /^VimDelta:norepo/
  catch /^VimDelta:commandfail/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closeNewestReleaseDiff()
  call s:closeDiff('newestRelease')
endfunc

func s:openPriorReleaseDiff()
  try
    call s:openReleaseDiff('priorRelease', s:priorReleaseTag(), "No prior release tag")
  catch /^VimDelta:norepo/
  catch /^VimDelta:commandfail/
  catch /^VimDelta:notfound/
  endtry
endfunc

func s:closePriorReleaseDiff()
  call s:closeDiff('priorRelease')
endfunc

" ------------------------------------------------------------------------------
" PRIVATE FUNCTIONS

" Expand a path into an absolute real path, without treating '~' and
" '~username' specially.  This function is needed to overcome shortcomings of
" resolve() and expand('%:p').
func s:abspath(path)
  let path = a:path
  if path == '/'
    return '/'
  endif
  if path[0] == '~'
    let path = './'.path
  endif
  return resolve(fnamemodify(path, ':p'))
endfunc

func s:displayError(message, lines)
  if a:message != ''
    echohl ErrorMsg
    echomsg a:message
    echohl None
  endif
  if len(a:lines)
    echohl WarningMsg
    echomsg join(a:lines, "\n")
    echohl None
  endif
endfunc

func s:notMerging()
  call s:displayError('', ["Not available unless merging"])
  throw "VimDelta:notmerge"
endfunc

func s:notRepository(path)
  call s:displayError('', ["Not in any repository".(a:path != '' ? ": ".a:path : "")])
  throw "VimDelta:norepo"
endfunc

func s:notSupported(what)
  call s:displayError('', ["Not supported in "a:what])
  throw "VimDelta:notsupported"
endfunc

" Return the current working directory in which commands relating to the current
" buffer's file should be executed.  In diff and log windows, we use the
" buffer's 'fileDir' variable, if set, otherwise we use the directory of the
" file being edited if there is one, otherwise we use the current working directory.
func s:getFileWorkingDirectory(...)
" echomsg "getFileWorkingDirectory()"
  if a:0 > 1
    let path = s:abspath(a:1)
"   echomsg "getFileWorkingDirectory: a:1=".a:1." path=".path
    return isdirectory(path) ? path : fnamemodify(path, ':h')
  elseif exists('b:fileDir')
"   echomsg "getFileWorkingDirectory: s:abspath(b:fileDir)=".s:abspath(b:fileDir)
    return s:abspath(b:fileDir)
  elseif expand('%') != ''
"   echomsg "getFileWorkingDirectory: expand('%')=".expand('%')
"   echomsg "getFileWorkingDirectory: fnamemodify(s:abspath(expand('%')),':h')=".fnamemodify(s:abspath(expand('%')),':h')
    return fnamemodify(s:abspath(expand('%')), ':h')
  else
"   echomsg "getFileWorkingDirectory: s:abspath(getcwd())=".s:abspath(getcwd())
    return s:abspath(getcwd())
  endif
endfunc

" Return the current working file.  In diff and log windows, we use the
" buffer's 'filePath' variable, if set, otherwise we use the current buffer's
" file name.
func s:getFilePath()
  if exists('b:filePath')
"   echomsg "getFilePath: b:filePath=".b:filePath
    return b:filePath
  elseif expand('%') != ''
"   echomsg "getFilePath: s:abspath(expand('%'))=".s:abspath(expand('%'))
    return s:abspath(expand('%'))
  endif
  throw "VimDelta:nofile"
endfunc

" Return a list of the names of all tags in the current file's repository, in
" lexical sorted order.
func s:allTagsSorted()
  let dir = s:getFileWorkingDirectory()
  if s:isGit(dir)
    let lines = s:allGitTags(dir)
  elseif s:isHg(dir)
    let lines = s:allHgTags(dir)
  else
    call s:notRepository(dir)
  endif
  return sort(lines)
endfunc

" Return a list of the names of all release tags in the current file's
" repository, in lexical sorted order.
func s:allReleaseTagsSorted()
  let tags = s:allTagsSorted()
  return filter(tags, 'DeltaVim_isReleaseTag(v:val)')
endfunc

" Return the latest release tag, or '' if there are no releases.
func s:newestReleaseTag()
  return get(s:allReleaseTagsSorted(), -1, '')
endfunc

" Return the penultimate release tag, or '' if there are fewer than two release tags.
func s:priorReleaseTag()
  return get(s:allReleaseTagsSorted(), -2, '')
endfunc

" Open a new diff window containing the contents of the given file, which is
" fetched using the :read command, so can be specified using '!' notation to
" capture the output of a command.
"
" Param: diffname The symbolic name of the new diff buffer
" Param: readArg The argument passed to :read to fill the new buffer
" Param: rev Stored in the buffer's b:revision variable
" Param: annotation Extra information appended the buffer's label
" Param: label If set, replaces diffName as the displayed label
"
func s:openDiff(diffname, readArg, rev, annotation, label)
" echomsg "openDiff(".string(a:diffname).', '.string(a:readArg).', '.string(a:rev).', '.string(a:annotation).', '.string(a:label).')'
  let varname = "t:".a:diffname."DiffBuffer"
  if exists(varname)
    diffupdate
    call s:setBufferWrapMode()
  else
    if s:countDiffs() == 4
      echoerr "Cannot have more than four diffs at once"
      return 0
    endif
    " put focus in the window containing the original file
    call s:gotoOrigWindow()
    " only proceed for normal buffers
    if &buftype != ''
      return 0
    else
      let t:origDiffBuffer = bufnr("%")
      " if there are no diff buffers in existence, save the wrap mode of the
      " original file buffer and the global wrap mode too, so that we can restore
      " them after :diffoff
      call s:recordWrapMode()
      " turn off wrap mode in the original file buffer
      call s:setBufferWrapMode(0)
      let ft = &filetype
      let readarg = s:expandPath(a:readArg, s:abspath(expand('%')))
"     echomsg "readarg=".string(readarg)
      let realfilepath = s:abspath(expand('%'))
      let realfiledir = fnamemodify(realfilepath, ':h')
      let abbrfilepath = fnamemodify(realfilepath, ':~:.')
      set equalalways
      set eadirection=hor
      vnew
      let b:readArg = readarg
      let b:filePath = realfilepath
      let b:fileDir = realfiledir
      let b:revision = a:rev
      " turn off wrap mode in the new diff buffer
      call s:setBufferWrapMode(0)
      exe 'let' varname "=" bufnr("%")
      let displayName = abbrfilepath
      if a:annotation != ''
        let displayName .= ' '.a:annotation
      endif
      let displayName .= ' ' . ((a:label != '') ? a:label : a:diffname)
      silent exe 'file' fnameescape(displayName)
      silent exe '1read' b:readArg
      if v:shell_error
        let readarg = b:readArg
        let errorlines = getbufline('%', 1, 10)
        exe 'exe' varname '"bdelete!"'
        exe 'unlet!' varname
        redraw
        "call s:displayError("Failure reading ".readarg, errorlines)
        call s:displayError('', errorlines)
        return 0
      endif
      1d
      let &l:filetype = ft
      setlocal buftype=nofile
      setlocal nomodifiable
      setlocal noswapfile
      setlocal bufhidden=delete
      setlocal scrollbind
      try
        diffthis
      catch /Vim(diffthis):E96:.*/ " Diffing more than 4 buffers
        exe 'unlet' varname
        if s:countDiffs() == 0
          unlet t:origDiffBuffer
          "echo 'unlet! t:origDiffBuffer (C)'
        endif
        wincmd c
        call s:restoreWrapMode()
        echoerr substitute(v:exception, '^Vim(\a\+):', '', '')
      endtry
      augroup DeltaVim
        exe 'autocmd BufDelete <buffer> call s:cleanUpDiff('.string(a:diffname).')'
      augroup END
      wincmd x
      setlocal scrollbind
      diffthis
      augroup DeltaVim
        " When the source file's buffer ceases to be visible in any window,
        " close all associated buffers, including the diff buffer.
        autocmd BufWinLeave <buffer> nested call s:closeAll()
        "autocmd BufWinEnter <buffer> call s:cleanUp("BufWinEnter ".expand('<abuf>').' (diff)')
      augroup END
      diffupdate
    endif
  endif
  return 1
endfunc

" Helpful for debugging
func s:echo(prefix, text)
  echo a:prefix.a:text
  return a:text
endfunc

" Expand a file path into a string template:
"  - substitute all '%%' with 'path'
"  - substitute all '%%:h' with the head of 'path'
"  - substitute all '%%:t' with the tail of 'path'
"  - escape shell metacharacters for passing to system() by appending ':S' to any of the above
"  - escape Vim metacharacters (fnameescape()) for passing to :read by appending ':E' to any of the above
func s:expandPath(text, path)
  " In Vim 7.4, a bug in fnamemodify() fails when the modifiers are ':h:S' and
  " the path ends in '.h'.  We work around it by invoking fnamemodify() twice,
  " once for the ':h' and once for the ':S'
  return substitute(a:text, '%%\(\%(:[ht~.]\)\?\)\(\%(:[S]\)\?\)\(\%(:[E]\)\?\)', '\=s:expandPathSubstitute(a:path, submatch(1), submatch(2), submatch(3))', "g")
endfunc
func s:expandPathSubstitute(path, ...)
" echomsg "expandPathSubstitute(path=".a:path." ...=".join(a:000, ",").")"
  let path = a:path
  for modifier in a:000
    if modifier == ':E'
      let path = fnameescape(path)
    elseif modifier != ''
      let path = fnamemodify(path, modifier)
    endif
  endfor
  return path
endfunc

" Put the focus in the original diff file window and return 1 if it exists.
" Otherwise return 0.
func s:gotoOrigWindow()
  if exists('t:origDiffBuffer') && bufwinnr(t:origDiffBuffer) != -1
    exe bufwinnr(t:origDiffBuffer) 'wincmd w'
    return 1
  endif
  return 0
endfunc

func s:setOrigBufferDiffMode(flag)
  if s:gotoOrigWindow()
    if a:flag
      diffthis
    else
      diffoff
      setlocal scrollbind
    endif
    call s:setBufferWrapMode(0)
    wincmd p
  endif
endfunc

func s:toggleOrigBufferDiffMode()
  if exists('t:origDiffBuffer') && bufwinnr(t:origDiffBuffer) != -1
    let diff = getwinvar(bufwinnr(t:origDiffBuffer), '&diff')
    if diff
      call s:setOrigBufferDiffMode(0)
    elseif s:countDiffs() != 0
      call s:setOrigBufferDiffMode(1)
    endif
  endif
endfunc

func s:closeDiff(diffname)
  let varname = 't:'.a:diffname.'DiffBuffer'
  if exists(varname)
    " delete the buffer and let the BufDelete autocmd do the clean-up
    exe 'exe' varname '"bdelete"'
  endif
endfunc

func s:isDiffOpen(diffname)
  let varname = 't:'.a:diffname.'DiffBuffer'
  return exists(varname)
endfunc

func s:cleanUpDiff(diffname)
  let varname = 't:'.a:diffname.'DiffBuffer'
  exe 'unlet!' varname
  call s:cleanUp('cleanUpDiff("'.a:diffname.'")')
endfunc

func s:countDiffs()
  let n = 0
  for diffname in s:allDiffNames
    let varname = 't:'.diffname.'DiffBuffer'
    if exists(varname)
      let n += 1
    endif
  endfor
  " If any diffs are present, count the original file window too.
  if n != 0
    let n += 1
  endif
  return n
endfunc

" Open a new window containing the log history of the current file.
"
func s:openLog()
  try
    " close the log window if it already exists
    call s:closeLog()
    " first switch to the original diff buffer, if there is one, otherwise operate
    " on the current buffer
    if exists('t:origDiffBuffer') && bufwinnr(t:origDiffBuffer) != -1
      exe t:origDiffBuffer 'buffer'
    endif
    " only proceed for normal buffers
    if &buftype == ''
      " figure out the file name and number of the current buffer
      let t:origDiffBuffer = bufnr("%")
      let filepath = expand('%')
      let realfilepath = s:abspath(expand('%'))
      let realfiledir = fnamemodify(realfilepath, ':h')
      " save the current wrap modes to restore them later
      call s:recordWrapMode()
      augroup DeltaVim
        " When the source file's buffer ceases to be visible in any window, close
        " all associated buffers, including the log buffer.
        autocmd BufWinLeave <buffer> nested call s:closeAll()
      augroup END
      " create the log navigation window
      botright 10 new
      let t:logBuffer = bufnr('%')
      let b:fileDir = realfiledir
      " give the buffer a helpful name
      silent exe 'file' fnameescape('log '.filepath)
      if s:isGit(realfiledir)
        " read the Git log into it -- all ancestors of the current working revision
        let heads = "HEAD"
        if s:isGitWorkingMerge(realfiledir)
          let heads = "HEAD MERGE_HEAD"
        endif
        let command = s:expandPath("cd %%:h:E >/dev/null && git log --follow --format='format:\\%h|\\%ai|\\%an|\\%s' ".heads." -- %%:t:S", realfilepath)
        silent exe '$read !'.command
        if s:displayGitError('Cannot read Git log', getline(1,'$'))
          call s:closeLog()
          return
        endif
        1d
        " justify the first column (graph number)
        let w = max([4, max(map(getline(1,'$'), "len(substitute(v:val, '\\x.*$', '', ''))"))])
        silent g/\x\{6,\}|/s/^\X*/\=submatch(0).repeat(' ', w-len(submatch(0)))/e
        " remove seconds from the date column
        silent g/^\(\X*\x\{6,\}|\)\(\d\d\d\d-\d\d-\d\d \d\d:\d\d\):\d\d/s//\1\2/e
        " remove timezone from the date column
        "silent g/^\(\%([^|]*|\)\{1\}\)\([^|]*\) +\d\d\d\d|/s//\1\2|/e
        " justify/truncate the username column
        silent g/^\(\X*\x\{6,\}|[^|]*|\)\([^|]*\)/s//\=submatch(1).strpart(submatch(2),0,16).repeat(' ', 16-len(submatch(2)))/e
        setlocal filetype=gitlogcompact
        set syntax=gitlogcompact
      elseif s:isHg(realfiledir)
        " read the mercurial log into it -- all ancestors of the current working revision
        if s:isHgWorkingMerge(realfiledir)
          " if currently merging, show '1' and '2' flags to indicate which revisions contributed to each parent
          silent exe '$read !'.s:expandPath('cd %%:h:E >/dev/null && hg --config defaults.log= log --follow --rev "ancestors(p1())-ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|1 +{parents}|{desc|firstline}\n" %%:t:E', realfilepath)
          silent exe '$read !'.s:expandPath('cd %%:h:E >/dev/null && hg --config defaults.log= log --follow --rev "ancestors(p2())-ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}| 2+{parents}|{desc|firstline}\n" %%:t:E', realfilepath)
          silent exe '$read !'.s:expandPath('cd %%:h:E >/dev/null && hg --config defaults.log= log --follow --rev "ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|12+{parents}|{desc|firstline}\n" %%:t:E', realfilepath)
          1d
          if s:displayHgError('Cannot read Mercurial log', getline(1,'$'))
            call s:closeLog()
            return
          endif
          " sort by date
          sort /^\([^|]*|\)\{2\}/
          " reverse order (most recent first)
          g/^/m0
        else
          silent exe '$read !'.s:expandPath('cd %%:h:E >/dev/null && hg --config defaults.log= log --follow --rev "ancestors(parents())" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|+{parents}|{desc|firstline}\n" %%:t:E', realfilepath)
          1d
          if s:displayHgError('Cannot read Mercurial log', getline(1,'$'))
            call s:closeLog()
            return
          endif
        endif
        " justify the first column (rev number)
        silent %s@^\d\+@\=submatch(0).repeat(' ', 6-len(submatch(0)))@e
        " clean up the date column
        silent %s@^\(\%([^|]*|\)\{2\}\)\([^|]*\) +\d\d\d\d|@\1\2|@e
        " justify/truncate the username column
        silent %s@^\(\%([^|]*|\)\{3\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,10).repeat(' ', 10-len(submatch(2)))@e
        " justify/truncate the branch column
        silent %s@^\(\%([^|]*|\)\{4\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,30).repeat(' ', 30-len(submatch(2)))@e
        " condense the parents column into "M" flag
        silent %s@^\(\%([^|]*|\)\{5\}\)\([^+]*+\)\([^|]*\)@\=submatch(1).submatch(2)[:-2].call('s:hgMergeFlag', [submatch(3)])@e
        setlocal filetype=hglogcompact
        set syntax=hglogcompact
      else
        call s:notRepository(realfiledir)
        return
      endif
      " go the first line (most recent revision)
      1
      " set the buffer properties
      call s:setBufferWrapMode(0)
      setlocal buftype=nofile
      setlocal nomodifiable
      setlocal noswapfile
      setlocal bufhidden=delete
      setlocal winfixheight
      " Set up some useful key mappings.
      " (Vim used to fail to synchronise the scrolling of the diff windows, so after :call
      " <SID>openLogRevisionDiffs(...)<CR> the following incantation was used: 0kj
      " but that had the unfortunate side effect of erasing any error message shown in the
      " status line.  No longer needed in Vim 7.4.)
      nnoremap <buffer> <silent> <CR> 10_:call <SID>openLogRevisionDiffs(0)<CR>
      vnoremap <buffer> <silent> <CR> 10_:<C-U>call <SID>openLogRevisionDiffs(1)<CR>
      nnoremap <buffer> <silent> - 5-
      nnoremap <buffer> <silent> + 5+
      nnoremap <buffer> <silent> _ _
      nnoremap <buffer> <silent> = 10_
      nnoremap <buffer> <silent> m :call <SID>gotoOrigWindow()<CR>
      nnoremap <buffer> <silent> q :call <SID>closeLog()<CR>
      " housekeeping for buffer close
      augroup DeltaVim
        autocmd BufDelete <buffer> call s:cleanUpLog()
      augroup END
    endif
  catch /^VimDelta:norepo/
    call s:closeLog()
  catch /^VimDelta:commandfail/
    call s:closeLog()
  endtry
endfunc

" Called when the log buffer is about to be deleted.
func s:cleanUpLog()
  unlet! t:logBuffer
  call s:cleanUp('cleanUpLog()')
endfunc

" Return 1 if the log buffer exists.
func s:testLogExists()
  return exists('t:logBuffer') && buflisted(t:logBuffer)
endfunc

" Put the focus in the log buffer window and return 1 if it exists.  Otherwise
" return 0.
func s:gotoLogWindow()
  if exists('t:logBuffer')
    exe bufwinnr(t:logBuffer) 'wincmd w'
    return 1
  endif
  return 0
endfunc

func s:closeLog()
  if s:testLogExists()
    " delete the buffer and let the BufDelete autocmd do the clean-up
    exe t:logBuffer 'bdelete'
  endif
endfunc

func s:openLogRevisionDiffs(visual)
" echomsg "openLogRevisionDiffs(".a:visual.")"
  call s:closeLogRevisionDiffs()
  if !exists('t:origDiffBuffer') || bufwinnr(t:origDiffBuffer) == -1
    return
  endif
  try
    if a:visual
      if s:isGit()
        let rev1 = matchstr(getline(line("'>")), '\x\{6,\}').'^' " earliest
        let rev2 = matchstr(getline(line("'<")), '\x\{6,\}') " latest
        if len(rev1) && len(rev2)
          call s:openGitDiff('revision1', rev1, rev1)
          call s:openGitDiff('revision2', rev2, rev2)
        endif
      elseif s:isHg()
        let rev1 = matchstr(getline(line("'>")), '\d\+') " earliest
        let rev2 = matchstr(getline(line("'<")), '\d\+') " latest
        let info = s:getHgRevisionInfo('p1(rev('.rev1.'))')
        if len(info) && len(rev2)
          call s:openHgDiff('revision1', info.rev, info.rev)
          call s:openHgDiff('revision2', rev2, rev2)
        endif
      endif
    else
      if s:isGit()
        let rev = matchstr(getline('.'), '\x\{6,\}')
        if len(rev)
          call s:openGitDiff('revision1', rev, rev)
        endif
      elseif s:isHg()
        let rev = matchstr(getline('.'), '\d\+')
        if len(rev)
          call s:openHgDiff('revision1', rev, rev)
        endif
      endif
    endif
  catch /^VimDelta:norepo/
  catch /^VimDelta:nofile/
  catch /^VimDelta:notfound/
  finally
    " return the focus to the log window
    if s:gotoLogWindow()
      call s:setBufferWrapMode(0)
    endif
  endtry
endfunc

func s:closeLogRevisionDiffs()
  call s:closeDiff('revision2')
  call s:closeDiff('revision1')
endfunc

" Record the global wrap mode and the wrap mode of the current buffer.
func s:recordWrapMode()
  if !exists('g:preDiffWrapMode')
    let g:preDiffWrapMode = &g:wrap
  endif
  if !exists('b:preDiffWrapMode')
    let b:preDiffWrapMode = &l:wrap
  endif
endfunc

" Restore the global wrap mode and the wrap mode of the current buffer.
" Does not touch other buffers, because this can be called in a BufUnload
" or BufDelete autocmd, in which changing the current buffer is lethal.
func s:restoreWrapMode()
  if exists('g:preDiffWrapMode')
    call s:setGlobalWrapMode(g:preDiffWrapMode)
    unlet g:preDiffWrapMode
  else
    call s:setGlobalWrapMode()
  endif
  if exists('b:preDiffWrapMode')
    call s:setBufferWrapMode(b:preDiffWrapMode)
    unlet b:preDiffWrapMode
  else
    call s:setBufferWrapMode()
  endif
endfunc

" Use this function instead of :setglobal [no]wrap.  There are three use cases:
"       :call s:setGlobalWrapMode(0) equivalent to :setglobal nowrap
"       :call s:setGlobalWrapMode(1) equivalent to :setglobal wrap
"       :call s:setGlobalWrapMode() equivalent to most recent of the above
func s:setGlobalWrapMode(...)
  if a:0
    let t:wrapMode = a:1
  endif
  if exists('g:wrapMode')
    let &g:wrap = t:wrapMode
  endif
endfunc

" Use this function instead of :setlocal [no]wrap.  There are three use cases:
"       :call s:setBufferWrapMode(0) equivalent to :setlocal nowrap
"       :call s:setBufferWrapMode(1) equivalent to :setlocal wrap
"       :call s:setBufferWrapMode() equivalent to most recent of the above
func s:setBufferWrapMode(...)
  if a:0
    let b:wrapMode = a:1
  endif
  if exists('b:wrapMode')
    let &l:wrap = b:wrapMode
  endif
endfunc

" ------------------------------------------------------------------------------
" PRIVATE FUNCTIONS - Git

func s:isGit(...)
  return findfile('.git/config', fnamemodify(call('s:getFileWorkingDirectory', a:000), ':gs/ /\\ /').';') != ''
endfunc

" If the given Git output lines contain any error message, or the command
" itself returned an error exit status, then display an error message and quote
" any error message from Git, then return 1 to indicate an error
" condition.  Otherwise return 0.
func s:displayGitError(message, lines)
  let errorlines = filter(copy(a:lines), 'v:val =~ "^fatal:"')
  if v:shell_error || len(errorlines)
    call s:displayError(a:message, errorlines)
    return 1
  endif
  return 0
endfunc

" Return much information about a specific Git commit.
func s:getGitRevisionInfo(refspec)
  let info = {}
  let command = s:expandPath('cd %%:S >/dev/null && git log -1 --format="%h%n%H%n%ai%n%an%n%ae%nSUMMARY%n%s%nBODY%n%b" '.shellescape(a:refspec), s:getFileWorkingDirectory())
  let lines = split(system(command), "\n")
  if !s:displayGitError('Could not get information for refspec "'.a:refspec.'"', lines)
    if len(lines) == 0
      call s:displayError('', ['Revision "'.a:refspec.'" does not exist'])
    elseif len(lines) < 7 || lines[5] != 'SUMMARY' || lines[7] != 'BODY'
      call s:displayError('Malformed output from "git log":', lines)
    else
      let info.ahash = remove(lines, 0)
      let info.hash = remove(lines, 0)
      let info.date = remove(lines, 0)
      let info.author = remove(lines, 0)
      let info.email = remove(lines, 0)
      call remove(lines, 0) " SUMMARY
      let info.summary = remove(lines, 0)
      call remove(lines, 0) " BODY
      let info.body = join(lines, "\n")
    endif
  endif
  return info
endfunc

" Return a list of the names of all tags in the current file's repository,
" unsorted.
func s:allGitTags(dir)
  let lines = split(system('cd '.shellescape(a:dir).' >/dev/null && git tag --list'), "\n")
  if s:displayGitError('Could not get list of Git tags', lines)
    throw "VimDelta:commandfail"
  endif
  return lines
endfunc

" Return commit ref of fork point of current branch from given trunk
func s:getGitForkPoint(trunkref)
  let ref = ''
  let command = s:expandPath('cd %%:S >/dev/null && git merge-base --fork-point ', s:getFileWorkingDirectory()).shellescape(a:trunkref)
  let lines = split(system(command), "\n")
  if s:displayGitError('Could not get fork-point for trunk "'.a:trunkref.'"', lines)
    throw "VimDelta:commandfail"
  endif
  if len(lines) == 0
    echohl WarningMsg
    echomsg 'Branch does not fork from '.a:trunkref
    echohl None
    throw "VimDelta:notfound"
  endif
  if len(lines) != 1
    call s:displayError('Malformed output from "git merge-base --fork-point":', lines)
    throw "VimDelta:commandfail"
  endif
  return lines[0]
endfunc

" Return commit ref of most recent merge at or before given commit
func s:getGitLatestMerge(ref)
  let ref = ''
  let command = s:expandPath('cd %%:S >/dev/null && git rev-list -n1 --min-parents=2 '.shellescape(a:ref), s:getFileWorkingDirectory())
  let lines = split(system(command), "\n")
  if s:displayGitError('Could not get latest merge before '.a:ref, lines)
    throw "VimDelta:commandfail"
  endif
  if len(lines) == 0
    echohl WarningMsg
    echomsg 'No merge before '.a:ref
    echohl None
    throw "VimDelta:notfound"
  endif
  if len(lines) != 1
    call s:displayError('Malformed output from "git rev-list -n1 --min-parents=2":', lines)
    throw "VimDelta:commandfail"
  endif
  return lines[0]
endfunc

" Open a new diff window containing the given Git commit.
"
" Param: diffname The symbolic name of the new diff buffer
" Param: refspec The Git commit to fetch
" Param: label If set, replaces diffName as the displayed label
"
func s:openGitDiff(diffname, refspec, label)
" echomsg "s:openGitDiff(diffname=".a:diffname.", refspec=".a:refspec.", label=".a:label.")"
  let annotation = a:refspec.':'
  let hash = ''
  if a:refspec[0] != ':'
    let info = s:getGitRevisionInfo(a:refspec)
"   echomsg "info=".string(info)
    if len(info)
      let annotation = info.ahash.' '.info.date
      let hash = info.hash
    endif
  endif
  try
    call s:openDiff(a:diffname, '!cd %%:h:E >/dev/null && git show '.fnameescape(a:refspec).':./%%:t:E', hash, annotation, a:label)
  endtry
endfunc

" Return 1 if the current Git working directory is a merge (has any staged files).
func s:isGitWorkingMerge(...)
  let command = s:expandPath('cd %%:S >/dev/null && git ls-files --stage', call('s:getFileWorkingDirectory', a:000))
  let lines = split(system(command), "\n")
  if s:displayGitError('Failed command: '.command, lines)
    throw "VimDelta:commandfail"
  endif
  let nstaged = 0
  for line in lines
    let words = split(line)
    if len(words) >= 2 && words[2] != '0'
      let nstaged += 1
    endif
  endfor
  if nstaged != 0
    return 1
  endif
  return 0
endfunc

" ------------------------------------------------------------------------------
" PRIVATE FUNCTIONS - Mercurial

func s:isHg(...)
  return findfile('.hg/hgrc', fnamemodify(call('s:getFileWorkingDirectory', a:000), ':gs/ /\\ /').';') != ''
endfunc

" If the given Mercurial output lines contain any error message, or the command
" itself returned an error exit status, then display an error message and quote
" any error message from Mercurial, then return 1 to indicate an error
" condition.  Otherwise return 0.
func s:displayHgError(message, lines)
  let errorlines = filter(copy(a:lines), 'v:val =~ "^\\*\\*\\*"')
  if v:shell_error || len(errorlines)
    call s:displayError(a:message, errorlines)
    return 1
  endif
  return 0
endfunc

" Return much information about a specific Mercurial revision.
func s:getHgRevisionInfo(rev)
  let info = {}
  let dir = s:getFileWorkingDirectory()
  let lines = split(system('cd '.shellescape(dir).' >/dev/null && hg --config defaults.log= log --template "{rev}\n{node}\n{node|short}\n{branches}\n{parents}\n{tags}\n{author}\n{author|user}\n{date|date}\n{date|isodate}\n{date|shortdate}\nDESCRIPTION\n{desc}\n" --rev '.shellescape(a:rev)), "\n")
  if !s:displayHgError('Could not get information for revision "'.a:rev.'"', lines)
    if len(lines) == 0
      call s:displayError('', ['Revision "'.a:rev.'" does not exist'])
    elseif len(lines) < 13 || lines[11] != 'DESCRIPTION'
      call s:displayError('Malformed output from "hg log":', lines)
    else
      let info.rev = remove(lines, 0)
      let info.node = remove(lines, 0)
      let info.shortnode = remove(lines, 0)
      let info.branch = remove(lines, 0)
      if info.branch == ''
        let info.branch = 'default'
      endif
      let parents = remove(lines, 0)
      let info.parents = map(split(parents), 'split(v:val,":")[1]')
      let info.parentrevs = map(split(parents), 'split(v:val,":")[0]')
      let info.tags = split(remove(lines, 0))
      let info.author = remove(lines, 0)
      let info.user = remove(lines, 0)
      let info.date = remove(lines, 0)
      let info.isodate = remove(lines, 0)
      let info.shortdate = remove(lines, 0)
      call remove(lines, 0)
      let info.summary = lines[0]
      let info.description = join(lines, "\n")
    endif
  endif
  return info
endfunc

" Return a list of Mercurial revision IDs (nodes) determined by the given
" hg log options, in reverse chronological order (most recent first).
func s:getHgRevisions(hgLogOpts)
  let dir = s:getFileWorkingDirectory()
  let lines = split(system('cd '.shellescape(dir).' >/dev/null  && hg --config defaults.log= log --follow --template "{node}\n" '.a:hgLogOpts), "\n")
  if s:displayHgError('Could not get revisions from "hg log --follow '.a:hgLogOpts.'"', lines)
    throw "VimDelta:commandfail"
  endif
  return lines
endfunc

" Return a list of the names of all tags in the current file's repository,
" unsorted.
func s:allHgTags(dir)
  let lines = split(system('cd '.shellescape(a:dir).' >/dev/null && hg --config defaults.tags= tags'), "\n")
  if s:displayHgError('Could not get list of Mercurial tags', lines)
    throw "VimDelta:commandfail"
  endif
  call map(lines, 'substitute(v:val, "\s\+\d\+:\x{8-}$", "", "")')
  return lines
endfunc

"" Return the current Mercurial branch's most recently merged trunk (default
"" branch) revision.  Ie, the revision of the trunk that was merged in, not the
"" resulting revision in the current branch.
"func s:latestHgDefaultMergeRevision()
"  let merges = s:getHgRevisions('--branch . --only-merges')
"  for rev in merges
"    let info = s:getHgRevisionInfo(rev)
"    if !len(info)
"      return ''
"    endif
"    if info.branch != 'default'
"      for parentrev in info.parentrevs
"        let parentinfo = s:getHgRevisionInfo(parentrev)
"        if !len(parentinfo)
"          return ''
"        endif
"        if parentinfo.branch == 'default'
"          return parentinfo.node
"        endif
"      endfor
"    endif
"  endfor
"  return ''
"endfunc

" Open a new diff window containing the given Mercurial revision.
"
" Param: diffname The symbolic name of the new diff buffer
" Param: rev The Mercurial revision to fetch
" Param: label If set, replaces diffName as the displayed label
"
func s:openHgDiff(diffname, rev, label)
  let info = s:getHgRevisionInfo(a:rev)
  if len(info) == 0
    throw "VimDelta:notfound"
  endif
  let annotation = info.shortnode.' '.info.shortdate
  try
    call s:openDiff(a:diffname, '!cd %%:h:E >/dev/null && hg --config defaults.cat= cat -r '.shellescape(info.rev).' %%:t:E', info.rev, annotation, a:label)
  endtry
endfunc

" Return 1 if the current Mercurial working directory is a merge (has two parents).
func s:isHgWorkingMerge(...)
  let command = s:expandPath('cd %%:S >/dev/null && hg --config defaults.parents= parents --template "{node}\n"', call('s:getFileWorkingDirectory', a:000))
  let parents = split(system(command), "\n")
  if s:displayHgError('Failed command: '.command, parents)
    throw "VimDelta:commandfail"
  endif
  if len(parents) == 2
    return 1
  endif
  return 0
endfunc

" Convert a list of parent revisions into a single character: "M" if there are
" two (or more) parents, " " otherwise.
func s:hgMergeFlag(hgParents)
  let i = stridx(a:hgParents, ':')
  if i == -1
    return ' '
  endif
  let j = strridx(a:hgParents, ':')
  if i == j
    return ' '
  endif
  return 'M'
endfunc

" ------------------------------------------------------------------------------
" Standard Vim plugin boilerplate.
let &cpo= s:keepcpo
unlet s:keepcpo
