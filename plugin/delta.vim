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
if exists("g:loaded_DeltaVim_Hg") || &cp
  finish
endif
let g:loaded_DeltaVim_Hg = 1

" Standard Vim plugin boilerplate.
let s:keepcpo = &cpo
set cpo&vim

" Save the <Leader> char as it was when the mappings were defined, so the help
" message can quote the correct key sequences even if mapleader gets changed.
let s:helpleader = g:mapleader
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
  echomsg m.'t   Trunk           Open a new diff window on the trunk branch head (Git "master", Hg "default")'
  echomsg m.'T                   Close the diff window opened with '.m.'t'
  echomsg m.'o   Branch origin   Open a new diff window on current branch origin (Hg only; earliest revision on current named branch)'
  echomsg m.'O                   Close the diff window opened with '.m.'b'
  echomsg m.'r   Release         Open a new diff window on latest release (Hg only; latest tag starting with "release")'
  echomsg m.'R                   Close the diff window opened with '.m.'n'
  echomsg m.'p   Prior release   Open a new diff window on prior release (Hg only; penultimate tag starting with "release")'
  echomsg m.'P                   Close the diff window opened with '.m.'n'
" echomsg m.'i   Incoming        Open a new diff window on the revision most recently merged into the current branch'
" echomsg m.'I                   Close the diff window opened with '.m.'m'
  echomsg m.'\   Close diffs     Close all diff windows opened with the above commands'
  echomsg m.'x   Close revision  Close all diff windows opened with the <Enter> command in the log window'
  echomsg m.'-   Close diff      Close current diff window'
  echomsg m.'=   Close all       Equivalent to '.m.'\ followed by '.m.'L'
  echomsg m.'|   Toggle main     Toggle the diff mode of the main file window. This is useful when two diff windows are open, to see only the changes between them'
  echomsg ' '
  echomsg 'During a merge:'
  echomsg m.'a   Common ancestor Open a new diff window on common merge ancestor (Git stage 1)'
  echomsg m.'A                   Close the diff window opened with '.m.'a'
  echomsg m.'b   Merge branch    Open a new diff window on merge target branch (Git stage 2, Hg parent 1)'
  echomsg m.'B                   Close the diff window opened with '.m.'b'
  echomsg m.'m   Merge incoming  Open a new diff window on incoming merge head (Git stage 3, Hg parent 2)'
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
  if !hasmapto('<Plug>DeltaVimCloseAllDiffs')
    nmap <unique> <Leader>\ <Plug>DeltaVimCloseAllDiffs
  endif
  if !hasmapto('<Plug>DeltaVimCloseLogRevisions')
    nmap <unique> <Leader>x <Plug>DeltaVimCloseLogRevisions
  endif
  if !hasmapto('<Plug>DeltaVimCloseWindow')
    nmap <unique> <Leader>- <Plug>DeltaVimCloseWindow
  endif
  if !hasmapto('<Plug>DeltaVimCloseAll')
    nmap <unique> <Leader>= <Plug>DeltaVimCloseAll
  endif
  if !hasmapto('<Plug>DeltaVimToggleOrigBuffer')
    nmap <unique> <Leader>| <Plug>DeltaVimToggleOrigBuffer
  endif
  if !hasmapto('<Plug>DeltaVimOpenCommonAncestor')
    nmap <unique> <Leader>a <Plug>DeltaVimOpenMergeCommonAncestor
  endif
  if !hasmapto('<Plug>DeltaVimCloseCommonAncestor')
    nmap <unique> <Leader>A <Plug>DeltaVimCloseMergeCommonAncestor
  endif
  if !hasmapto('<Plug>DeltaVimOpenMergeBranch')
    nmap <unique> <Leader>b <Plug>DeltaVimOpenMergeBranch
  endif
  if !hasmapto('<Plug>DeltaVimCloseMergeBranch')
    nmap <unique> <Leader>B <Plug>DeltaVimCloseMergeBranch
  endif
  if !hasmapto('<Plug>DeltaVimOpenMergeIncoming')
    nmap <unique> <Leader>m <Plug>DeltaVimOpenMergeIncoming
  endif
  if !hasmapto('<Plug>DeltaVimCloseMergeIncoming')
    nmap <unique> <Leader>M <Plug>DeltaVimCloseMergeIncoming
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
noremap <silent> <unique> <Plug>DeltaVimCloseAllDiffs :call <SID>closeAllDiffs()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseLogRevisions :call <SID>closeLogRevisionDiffs()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseWindow :call <SID>closeCurrentDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseAll :call <SID>closeAll()<CR>
noremap <silent> <unique> <Plug>DeltaVimToggleOrigBuffer :call <SID>toggleOrigBufferDiffMode()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenMergeCommonAncestor :call <SID>openMergeCommonAncestorDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseMergeCommonAncestor :call <SID>closeMergeCommonAncestorDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenMergeBranch :call <SID>openMergeBranchDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseMergeBranch :call <SID>closeMergeBranchDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimOpenMergeIncoming :call <SID>openMergeIncomingDiff()<CR>
noremap <silent> <unique> <Plug>DeltaVimCloseMergeIncoming :call <SID>closeMergeIncomingDiff()<CR>

" Whenever any buffer window goes away, if there are no more diff windows
" remaining, then turn off diff mode in the principal buffer.
autocmd BufHidden * call s:cleanUp("global BufHidden *")

" Whenever a buffer is written, refresh all the diff windows
autocmd BufWritePost * call s:refreshWorkingCopyDiff()

" ------------------------------------------------------------------------------
" APPLICATION FUNCTIONS

let s:allDiffNames = ['working', 'ancestor', 'parent1', 'parent2', 'branchOrigin', 'trunk', 'newestRelease', 'priorRelease', 'revision1', 'revision2']

" Close all diff windows and the log window.  This operation should leave no
" windows visible that were created by any mappings or functions in this plugin.
func s:closeAll()
  call s:closeAllDiffs()
  call s:closeLog()
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

" After a buffer is written, check if the working copy diff is visible.  If
" so, then refresh it.
func s:refreshWorkingCopyDiff()
  if exists("t:workingDiffBuffer")
    exe bufwinnr(t:workingDiffBuffer) 'wincmd w'
    setlocal modifiable
    silent %d
    silent exe '1read' '#'
    silent 1d
    setlocal nomodifiable
    diffupdate
    wincmd p
  endif
endfunc

" After any buffer is hidden, check if any diff buffers are still visible.  If
" not, then turn off diff mode, restore wrap mode, and clean up variables.
func s:cleanUp(desc)
  "echo 'cleanUp("'.a:desc.'"): bufnr("%") = ' . bufnr('%')
  "echo 'exists("t:origDiffBuffer") = ' . exists('t:origDiffBuffer')
  "if exists('t:origDiffBuffer')
  "  echo 't:origDiffBuffer = ' . t:origDiffBuffer
  "  echo 'bufwinnr(t:origDiffBuffer) = ' . bufwinnr(t:origDiffBuffer)
  "endif
  if exists('t:turnOffDiff') && t:turnOffDiff == bufnr('%')
    " This is a kludge, to work around a bug that the :diffoff! below does not turn
    " off diff mode in the buffer that is being left.
    diffoff
    unlet t:turnOffDiff
    call s:restoreWrapMode()
  endif
  "echo 's:countDiffs() == ' . s:countDiffs() . '  s:testLogExists() == ' . s:testLogExists()
  if s:countDiffs() == 0
    diffoff!
    call s:restoreWrapMode()
    set noequalalways
    if exists('t:origDiffBuffer')
      let t:turnOffDiff = t:origDiffBuffer
      if !s:testLogExists()
        unlet! t:origDiffBuffer
        "echo 'unlet! t:origDiffBuffer (A)'
      endif
    endif
  endif
  if !s:testLogExists()
    unlet! t:hgLogBuffer
  endif
  "echo 'WAH'
endfunc

func s:openRevisionDiff(rev)
  if a:rev != ''
    try
      call s:openHgDiff('revision1', a:rev, a:rev)
    endtry
  endif
endfunc

func s:closeRevisionDiff(rev)
  call s:closeDiff('revision1')
endfunc

func s:openWorkingDiff()
  try
    call s:openDiff('working', '#', '', '', '')
  endtry
endfunc

func s:closeWorkingDiff()
  call s:closeDiff('working')
endfunc

func s:openHeadDiff()
  try
    call s:openHgDiff('parent1', '.', '')
  endtry
endfunc

func s:closeHeadDiff()
  call s:closeDiff('parent1')
endfunc

func s:openMergeCommonAncestorDiff()
  let rev = get(s:getHgRevisions('--rev "ancestor(parents())"'), -1, '')
  if rev != ''
    try
      call s:openHgDiff('ancestor', rev, '')
    endtry
  endif
endfunc

func s:closeMergeCommonAncestorDiff()
  call s:closeDiff('ancestor')
endfunc

"func s:toggleMergeBranchDiff()
"  if s:isDiffOpen('parent1')
"    try
"      call s:closeMergeBranchDiff()
"    endtry
"  else
"    try
"      call s:openMergeBranchDiff()
"    endtry
"  endif
"endfunc

func s:openMergeBranchDiff()
  try
    call s:openHgDiff('parent1', 'p1()', '')
  endtry
endfunc

func s:closeMergeBranchDiff()
  call s:closeDiff('parent1')
endfunc

"func s:toggleMergeIncomingDiff()
"  if s:isDiffOpen('parent2')
"    try
"      call s:closeMergeIncomingDiff()
"    endtry
"  else
"    try
"      call s:openMergeIncomingDiff()
"    endtry
"  endif
"endfunc

func s:openMergeIncomingDiff()
  try
    call s:openHgDiff('parent2', 'p2()', '')
  endtry
endfunc

func s:closeMergeIncomingDiff()
  call s:closeDiff('parent2')
endfunc

func s:openBranchOriginDiff()
  let rev = get(s:getHgRevisions('--branch .'), -1, '')
  if rev != ''
    try
      call s:openHgDiff('branchOrigin', rev, '')
    endtry
  endif
endfunc

func s:closeBranchOriginDiff()
  call s:closeDiff('branchOrigin')
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

func s:openTrunkDiff()
  call s:openHgDiff('trunk', 'default', '')
endfunc

func s:closeTrunkDiff()
  call s:closeDiff('trunk')
endfunc

func s:openNewestReleaseDiff()
  let rev = s:newestHgReleaseRev()
  if rev != ''
    try
      call s:openHgDiff('newestRelease', rev, rev)
    endtry
  endif
endfunc

func s:closeNewestReleaseDiff()
  call s:closeDiff('newestRelease')
endfunc

func s:openPriorReleaseDiff()
  let rev = s:priorHgReleaseRev()
  if rev != ''
    try
      call s:openHgDiff('priorRelease', rev, rev)
    endtry
  endif
endfunc

func s:closePriorReleaseDiff()
  call s:closeDiff('priorRelease')
endfunc

" ------------------------------------------------------------------------------
" PRIVATE FUNCTIONS

" If the given Mercurial output lines contain any error message, or the command
" itself returned an error exit status, then display an error message and quote
" any error message from Mercurial, then return 1 to indicate an error
" condition.  Otherwise return 0.
func s:displayHgError(message, lines)
  let errorlines = filter(copy(a:lines), 'v:val =~ "^\\*\\*\\*"')
  if v:shell_error || len(errorlines)
    echohl ErrorMsg
    echomsg a:message
    echohl None
    if len(errorlines)
      echohl WarningMsg
      echomsg join(errorlines, "\n")
      echohl None
    endif
    return 1
  endif
  return 0
endfunc

" Return a list of the names of all Mercurial release tags in the current
" file's repository, in lexical sorted order.
func s:allHgReleaseTags()
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).' >/dev/null && hg --config defaults.tags= tags | awk ''$1~/^release_[0-9]+_finished$/{print $1}'''), "\n")
  if s:displayHgError('Could not get list of tags', lines)
    return []
  endif
  return sort(lines)
endfunc

" Extract a release date from a release name in the form "release-DATE", or
" return the whole name if not of this form.
func s:extractReleaseDate(name)
  if strpart(a:name, 0, 8) == 'release-'
    return strpart(a:name, 8)
  endif
  return a:name
endfunc

" Return the latest Mercurial release name, or '' if there are no release
" branches.
func s:newestHgReleaseRev()
  return get(s:allHgReleaseTags(), -1, '')
endfunc

" Return the penultimate Mercurial release name, or '' if there are fewer than
" two release branches.
func s:priorHgReleaseRev()
  return get(s:allHgReleaseTags(), -2, '')
endfunc

" Return a list of Mercurial revision IDs (nodes) determined by the given
" hg log options, in reverse chronological order (most recent first).
func s:getHgRevisions(hgLogOpts)
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).' >/dev/null  && hg --config defaults.log= log --template "{node}\n" '.a:hgLogOpts), "\n")
  if s:displayHgError('Could not get revisions from "hg log '.a:hgLogOpts.'"', lines)
    return []
  endif
  return lines
endfunc

" Return much information about a specific revision.
func s:getHgRevisionInfo(rev)
  let info = {}
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).' >/dev/null && hg --config defaults.log= log --template "{rev}\n{node}\n{node|short}\n{branches}\n{parents}\n{tags}\n{author}\n{author|user}\n{date|date}\n{date|isodate}\n{date|shortdate}\nDESCRIPTION\n{desc}\n" --rev '.shellescape(a:rev)), "\n")
  if !s:displayHgError('Could not get information for revision "'.a:rev.'"', lines)
    if len(lines) == 0
      echohl ErrorMsg
      echomsg 'Revision "'.a:rev.'" does not exist'
      echohl None
    elseif len(lines) < 13 || lines[11] != 'DESCRIPTION'
      echohl ErrorMsg
      echomsg 'Malformed output from "hg log":'
      echohl None
      for line in lines
        echomsg line
      endfor
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
  if len(info)
    let annotation = info.shortnode.' '.info.shortdate
    try
      call s:openDiff(a:diffname, '!cd %:h >/dev/null && hg --config defaults.cat= cat -r '.info.rev.' %:t', info.rev, annotation, a:label)
    endtry
  endif
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
  "echo "openDiff(".string(a:diffname).', '.string(a:readArg).', '.string(a:rev).', '.string(a:annotation).', '.string(a:label).')'
  let varname = "t:".a:diffname."DiffBuffer"
  if exists(varname)
    diffupdate
    call s:setBufferWrapMode()
  else
    if s:countDiffs() == 4
      echoerr "Cannot have more than four diffs at once"
    endif
    " put focus in the window containing the original file
    call s:gotoOrigWindow()
    " only proceed for normal buffers
    if &buftype == ''
      let t:origDiffBuffer = bufnr("%")
      " if there are no diff buffers in existence, save the wrap mode of the
      " original file buffer and the global wrap mode too, so that we can restore
      " them after :diffoff
      call s:recordWrapMode()
      " turn off wrap mode in the original file buffer
      call s:setBufferWrapMode(0)
      let ft = &filetype
      let readarg = s:expandReadarg(a:readArg, resolve(expand('%')))
      let realfiledir = fnamemodify(resolve(expand('%')), ':h')
      set equalalways
      set eadirection=hor
      vnew
      let b:fileDir = realfiledir
      let b:revision = a:rev
      " turn off wrap mode in the new diff buffer
      call s:setBufferWrapMode(0)
      exe 'let' varname "=" bufnr("%")
      let displayName = expand('%')
      if a:annotation != ''
        let displayName .= ' '.a:annotation
      endif
      let displayName .= ' ' . ((a:label != '') ? a:label : a:diffname)
      silent exe 'file' fnameescape(displayName)
      silent exe '1read' readarg
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
      augroup DeltaVim_Hg
        exe 'autocmd BufDelete <buffer> call s:cleanUpDiff('.string(a:diffname).')'
      augroup END
      wincmd x
      setlocal scrollbind
      diffthis
      augroup DeltaVim_Hg
        " When the source file's buffer ceases to be visible in any window,
        " close all associated buffers, including the diff buffer.
        autocmd BufWinLeave <buffer> nested call s:closeAll()
        "autocmd BufWinEnter <buffer> call s:cleanUp("BufWinEnter ".expand('<abuf>').' (diff)')
      augroup END
      diffupdate
    endif
  endif
endfunc

func s:ident(text)
  return a:text
endfunc

" Transform a string into text suitable as an argument to ':read':
"  - substitute all '%' with the 'percent' path
"  - substitute all '%:h' with the head of the 'percent' path
"  - substitute all '%:t' with the tail of the 'percent' path
"  - escape shell metacharacters in all substituted values if the argument is a
"    shell command (starts with '!')
func s:expandReadarg(text, percent)
  let escapefn = a:text[0] == '!' ? 'shellescape' : 's:ident'
  return substitute(a:text, '%\(:[ht~.]\|\)', '\='.escapefn.'(fnamemodify(a:percent, submatch(1)))', "g")
endfunc

" Put the focus in the original diff file window and return 1 if it exists.
" Otherwise return 0.
func s:gotoOrigWindow()
  if exists('t:origDiffBuffer')
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
  if exists('t:origDiffBuffer')
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

" Return the current working directory in which hg commands relating to the
" current buffer's file should be executed.
func s:getHgCwd()
  if exists('b:fileDir')
    return b:fileDir
  else
    return expand('%:h')
  endif
endfunc

" ------------------------------------------------------------------------------
" Mercurial log navigation.

func s:openLog()
  " close the log window if it already exists
  call s:closeLog()
  " first switch to the original diff buffer, if there is one, otherwise operate
  " on the current buffer
  if exists("t:origDiffBuffer")
    exe t:origDiffBuffer 'buffer'
  endif
  " only proceed for normal buffers
  if &buftype == ''
    " figure out the file name and number of the current buffer
    let t:origDiffBuffer = bufnr("%")
    let filepath = expand('%')
    let realfilepath = resolve(filepath)
    let realfiledir = fnamemodify(realfilepath, ':h')
    " save the current wrap modes to restore them later
    call s:recordWrapMode()
    augroup DeltaVim_Hg
      " When the source file's buffer ceases to be visible in any window, close
      " all associated buffers, including the log buffer.
      autocmd BufWinLeave <buffer> nested call s:closeAll()
    augroup END
    " create the log navigation window
    botright 10 new
    let t:hgLogBuffer = bufnr('%')
    let b:fileDir = realfiledir
    " give the buffer a helpful name
    silent exe 'file' fnameescape('log '.filepath)
    " read the mercurial log into it -- all ancestors of the current working revision
    if s:isWorkingMerge()
      " if currently merging, show '1' and '2' flags to indicate which revisions contributed to each parent
      silent exe '$read '.s:expandReadarg('!cd %:h >/dev/null && hg --config defaults.log= log --rev "ancestors(p1())-ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|1 +{parents}|{desc|firstline}\n" %:t', realfilepath)
      silent exe '$read '.s:expandReadarg('!cd %:h >/dev/null && hg --config defaults.log= log --rev "ancestors(p2())-ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}| 2+{parents}|{desc|firstline}\n" %:t', realfilepath)
      silent exe '$read '.s:expandReadarg('!cd %:h >/dev/null && hg --config defaults.log= log --rev "ancestors(ancestor(p1(),p2()))" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|12+{parents}|{desc|firstline}\n" %:t', realfilepath)
    else
      silent exe '$read '.s:expandReadarg('!cd %:h >/dev/null && hg --config defaults.log= log --rev "ancestors(parents())" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branch}|+{parents}|{desc|firstline}\n" %:t', realfilepath)
    endif
    1d
    " sort by reverse date (most recent first)
    sort! /^\([^|]*|\)\{2\}/
    " justify the first column (rev number)
    silent %s@^\d\+@\=submatch(0).repeat(' ', 6-len(submatch(0)))@
    " clean up the date column
    silent %s@^\(\%([^|]*|\)\{2\}\)\([^|]*\) +\d\d\d\d|@\1\2|@
    " justify/truncate the username column
    silent %s@^\(\%([^|]*|\)\{3\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,10).repeat(' ', 10-len(submatch(2)))@
    " justify/truncate the branch column
    silent %s@^\(\%([^|]*|\)\{4\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,30).repeat(' ', 30-len(submatch(2)))@
    " condense the parents column into "M" flag
    silent %s@^\(\%([^|]*|\)\{5\}\)\([^+]*+\)\([^|]*\)@\=submatch(1).submatch(2)[:-2].call('s:mergeFlag', [submatch(3)])@
    " go the first line (most recent revision)
    1
    " set the buffer properties
    call s:setBufferWrapMode(0)
    setlocal buftype=nofile
    setlocal nomodifiable
    setlocal noswapfile
    setlocal bufhidden=delete
    setlocal filetype=hglogcompact
    set syntax=hglogcompact
    setlocal winfixheight
    " Set up some useful key mappings.
    " The crap after the <CR> is a kludge to force Vim to synchronise the
    " scrolling of the diff windows, which it does not do correctly
    nnoremap <buffer> <silent> <CR> 10_:call <SID>openLogRevisionDiffs(0)<CR>0kj
    vnoremap <buffer> <silent> <CR> 10_:<C-U>call <SID>openLogRevisionDiffs(1)<CR>0kj
    nnoremap <buffer> <silent> - 5-
    nnoremap <buffer> <silent> + 5+
    nnoremap <buffer> <silent> _ _
    nnoremap <buffer> <silent> = 10_
    nnoremap <buffer> <silent> m :call <SID>gotoOrigWindow()<CR>
    nnoremap <buffer> <silent> q :call <SID>closeLog()<CR>
    " housekeeping for buffer close
    augroup DeltaVim_Hg
      autocmd BufDelete <buffer> call s:cleanUpLog()
    augroup END
  endif
endfunc

" Return 1 if the current working directory is a merge (has two parents).
func s:isWorkingMerge()
  let dir = s:getHgCwd()
  let nparents = system('cd '.shellescape(dir).' >/dev/null && hg --config defaults.parents= parents --template "x\n" | wc --lines')
  if v:shell_error
    echohl ErrorMsg
    echomsg 'Could not count Mercurial parents of working directory'
    echohl None
    return 0
  endif
  if str2nr(nparents) == 2
    return 1
  endif
  return 0
endfunc

" Convert a list of parent revisions into a single character: "M" if there are
" two (or more) parents, " " otherwise.
func s:mergeFlag(hgParents)
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

" Called when the log buffer is about to be deleted.
func s:cleanUpLog()
  unlet! t:hgLogBuffer
  call s:cleanUp('cleanUpLog()')
endfunc

" Return 1 if the log buffer exists.
func s:testLogExists()
  return exists('t:hgLogBuffer') && buflisted(t:hgLogBuffer)
endfunc

" Put the focus in the log buffer window and return 1 if it exists.  Otherwise
" return 0.
func s:gotoLogWindow()
  if exists('t:hgLogBuffer')
    exe bufwinnr(t:hgLogBuffer) 'wincmd w'
    return 1
  endif
  return 0
endfunc

func s:closeLog()
  if s:testLogExists()
    " delete the buffer and let the BufDelete autocmd do the clean-up
    exe t:hgLogBuffer 'bdelete'
  endif
endfunc

func s:openLogRevisionDiffs(visual)
  call s:closeLogRevisionDiff(1)
  call s:closeLogRevisionDiff(2)
  if a:visual
    let rev1 = matchstr(getline(line("'>")), '\d\+') " earliest
    let rev2 = matchstr(getline(line("'<")), '\d\+') " latest
    let info = s:getHgRevisionInfo('p1(rev('.rev1.'))')
    if len(info)
      try
        call s:openLogRevisionDiff(1, info.rev)
        call s:openLogRevisionDiff(2, rev2)
      endtry
    endif
  else
    let rev = matchstr(getline('.'), '\d\+')
    try
      call s:openLogRevisionDiff(1, rev)
    endtry
  endif
endfunc

func s:openLogRevisionDiff(n, rev)
  let bufname = 'revision'.a:n
  if a:rev != '' && exists('t:origDiffBuffer')
    try
      call s:openHgDiff(bufname, a:rev, a:rev)
    finally
      " return the focus to the log window
      if s:gotoLogWindow()
        call s:setBufferWrapMode(0)
      endif
    endtry
  endif
endfunc

func s:closeLogRevisionDiff(n)
  let bufname = 'revision'.a:n
  call s:closeDiff(bufname)
endfunc

func s:closeLogRevisionDiffs()
  call s:closeLogRevisionDiff(1)
  call s:closeLogRevisionDiff(2)
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
" Standard Vim plugin boilerplate.
let &cpo= s:keepcpo
unlet s:keepcpo
