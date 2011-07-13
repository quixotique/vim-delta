" Mercurial vim diff mode functions.
" vim: et ts=8 sts=2 sw=2
"
" Copyright 2011 Tuenti Technologies S.L.
" License: This file can only be stored on servers belonging to Tuenti Technologies S.L.
" Author: Andrew Bettison <abettison@tuenti.com>
" Maintainer: Andrew Bettison <abettison@tuenti.com>

" ------------------------------------------------------------------------------
" Exit if this app has already been loaded or in vi compatible mode.
if exists("g:loaded_TuentiMercurialDiff") || &cp
  finish
endif
let g:loaded_TuentiMercurialDiff = 1

" Standard Vim plugin boilerplate.
let s:keepcpo = &cpo
set cpo&vim

" ------------------------------------------------------------------------------
" PUBLIC INTERFACE

" Default key bindings, only set where no binding already has been defined.
if !exists('no_plugin_maps') && !exists('no_tuenti_tools_maps')
  if !hasmapto('<Plug>CloseAll')
    nmap <unique> <Leader>0 <Plug>CloseAll
  endif
  if !hasmapto('<Plug>DiffsCloseAll')
    nmap <unique> <Leader>\ <Plug>DiffsCloseAll
  endif
  if !hasmapto('<Plug>DiffsCloseWindow')
    nmap <unique> <Leader>- <Plug>DiffsCloseWindow
  endif
  if !hasmapto('<Plug>DiffsOpenWorkingParent')
    nmap <unique> <Leader>w <Plug>DiffsOpenWorkingParent
  endif
  if !hasmapto('<Plug>DiffsCloseWorkingParent')
    nmap <unique> <Leader>W <Plug>DiffsCloseWorkingParent
  endif
  if !hasmapto('<Plug>DiffsOpenCurrentTrunk')
    nmap <unique> <Leader>t <Plug>DiffsOpenCurrentTrunk
  endif
  if !hasmapto('<Plug>DiffsCloseCurrentTrunk')
    nmap <unique> <Leader>T <Plug>DiffsCloseCurrentTrunk
  endif
  if !hasmapto('<Plug>DiffsOpenLastMergedTrunk')
    nmap <unique> <Leader>m <Plug>DiffsOpenLastMergedTrunk
  endif
  if !hasmapto('<Plug>DiffsCloseLastMergedTrunk')
    nmap <unique> <Leader>M <Plug>DiffsCloseLastMergedTrunk
  endif
  if !hasmapto('<Plug>DiffsOpenBranchOrigin')
    nmap <unique> <Leader>b <Plug>DiffsOpenBranchOrigin
  endif
  if !hasmapto('<Plug>DiffsCloseBranchOrigin')
    nmap <unique> <Leader>B <Plug>DiffsCloseBranchOrigin
  endif
  if !hasmapto('<Plug>DiffsOpenNewestRelease')
    nmap <unique> <Leader>n <Plug>DiffsOpenNewestRelease
  endif
  if !hasmapto('<Plug>DiffsCloseNewestRelease')
    nmap <unique> <Leader>N <Plug>DiffsCloseNewestRelease
  endif
  if !hasmapto('<Plug>DiffsOpenPriorRelease')
    nmap <unique> <Leader>p <Plug>DiffsOpenPriorRelease
  endif
  if !hasmapto('<Plug>DiffsClosePriorRelease')
    nmap <unique> <Leader>P <Plug>DiffsClosePriorRelease
  endif
  if !hasmapto('<Plug>DiffsToggleOrigBuffer')
    nmap <unique> <Leader>| <Plug>DiffsToggleOrigBuffer
  endif
  if !hasmapto('<Plug>DiffsCloseLogRevisions')
    nmap <unique> <Leader>x <Plug>DiffsCloseLogRevisions
  endif
  if !hasmapto('<Plug>LogOpen')
    nmap <unique> <Leader>l <Plug>LogOpen
  endif
  if !hasmapto('<Plug>LogClose')
    nmap <unique> <Leader>L <Plug>LogClose
  endif
endif

" Default commands, will not replace existing commands with same name.
if !exists(':HgDiff')
  command -nargs=1 HgDiff call <SID>openRevisionDiff(<q-args>)
endif

" Global maps, available for your own key bindings.
"
noremap <silent> <unique> <Plug>CloseAll :call <SID>closeAll()<CR>
noremap <silent> <unique> <Plug>DiffsCloseAll :call <SID>closeAllDiffs()<CR>
noremap <silent> <unique> <Plug>DiffsCloseWindow :call <SID>closeCurrentDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenWorkingParent :call <SID>openWorkingParentDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseWorkingParent :call <SID>closeWorkingParentDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenCurrentTrunk :call <SID>openTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseCurrentTrunk :call <SID>closeTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenLastMergedTrunk :call <SID>openLastMergedTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseLastMergedTrunk :call <SID>closeLastMergedTrunkDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenBranchOrigin :call <SID>openBranchOriginDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseBranchOrigin :call <SID>closeBranchOriginDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenPriorRelease :call <SID>openPriorReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DiffsClosePriorRelease :call <SID>closePriorReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DiffsOpenNewestRelease :call <SID>openNewestReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseNewestRelease :call <SID>closeNewestReleaseDiff()<CR>
noremap <silent> <unique> <Plug>DiffsCloseLogRevisions :call <SID>closeLogRevisionDiffs()<CR>
noremap <silent> <unique> <Plug>DiffsToggleOrigBuffer :call <SID>toggleOrigBufferDiffMode()<CR>
noremap <silent> <unique> <Plug>LogOpen :call <SID>openLog()<CR>
noremap <silent> <unique> <Plug>LogClose :call <SID>closeLog()<CR>

" Whenever any buffer window goes away, if there are no more diff windows
" remaining, then turn off diff mode in the principal buffer.
autocmd BufHidden * call s:cleanUp()

" ------------------------------------------------------------------------------
" APPLICATION FUNCTIONS

let s:allDiffNames = ['workingParent', 'branchOrigin', 'mergedTrunk', 'currentTrunk', 'priorRelease', 'newestRelease', 'revision1', 'revision2']

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

" After any buffer is hidden, check if any diff buffers are still visible.  If
" not, then turn off diff mode, restore wrap mode, and clean up variables.
func s:cleanUp()
  if exists('t:turnOffDiff') && t:turnOffDiff == bufnr('%')
    " This is a kludge, to work around a bug that the :diffoff! below does not turn
    " off diff mode in the buffer that is being left.
    diffoff
    unlet t:turnOffDiff
    call s:restoreWrapMode()
  endif
  if s:countDiffs() == 0
    "echo 'exists("t:origDiffBuffer") = ' . exists('t:origDiffBuffer') . ', bufnr("%") = ' . bufnr('%')
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
    unlet! t:hgLogBuffer
  endif
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

func s:openWorkingParentDiff()
  try
    call s:openHgDiff('workingParent', '.', '')
  endtry
endfunc

func s:closeWorkingParentDiff()
  call s:closeDiff('workingParent')
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

func s:openLastMergedTrunkDiff()
  let rev = s:latestHgDefaultMergeRevision()
  if rev != ''
    try
      call s:openHgDiff('mergedTrunk', rev, '')
    endtry
  endif
endfunc

func s:closeLastMergedTrunkDiff()
  call s:closeDiff('mergedTrunk')
endfunc

func s:openTrunkDiff()
  call s:openHgDiff('currentTrunk', 'default', '')
endfunc

func s:closeTrunkDiff()
  call s:closeDiff('currentTrunk')
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
  let lines = split(system('cd '.shellescape(dir).' >/dev/null && hg --config defaults.log= log --template "{rev}\n{node}\n{node|short}\n{branches}\n{parents}\n{tags}\n{author}\n{author|user}\n{date|date}\n{date|isodate}\n{date|shortdate}\nDESCRIPTION\n{desc}\n" --rev '.a:rev), "\n")
  if !s:displayHgError('Could not get information for revision "'.a:rev.'"', lines)
    if len(lines) < 13 || lines[11] != 'DESCRIPTION'
      echoerr 'Malformed output from "hg log":'
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

" Return the current Mercurial branch's most recently merged trunk (default
" branch) revision.  Ie, the revision of the trunk that was merged in, not the
" resulting revision in the current branch.
func s:latestHgDefaultMergeRevision()
  let merges = s:getHgRevisions('--branch . --only-merges')
  for rev in merges
    let info = s:getHgRevisionInfo(rev)
    if !len(info)
      return ''
    endif
    if info.branch != 'default'
      for parentrev in info.parentrevs
        let parentinfo = s:getHgRevisionInfo(parentrev)
        if !len(parentinfo)
          return ''
        endif
        if parentinfo.branch == 'default'
          return parentinfo.node
        endif
      endfor
    endif
  endfor
  return ''
endfunc

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
      call s:openDiff(a:diffname, '!hg --config defaults.cat= cat -r '.a:rev.' #', info.rev, annotation, a:label)
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
      let filename = expand("%")
      let filedir = expand('%:h')
      set equalalways
      set eadirection=hor
      vnew
      let b:fileDir = filedir
      let b:revision = a:rev
      " turn off wrap mode in the new diff buffer
      call s:setBufferWrapMode(0)
      exe 'let' varname "=" bufnr("%")
      let displayName = filename
      if a:annotation != ''
        let displayName .= ' '.a:annotation
      endif
      let displayName .= ' ' . ((a:label != '') ? a:label : a:diffname)
      silent exe 'file' fnameescape(displayName)
      silent exe '1read' a:readArg
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
        endif
        wincmd c
        call s:restoreWrapMode()
        echoerr substitute(v:exception, '^Vim(\a\+):', '', '')
      endtry
      augroup TuentiMercurialDiff
        exe 'autocmd BufDelete <buffer> call s:cleanUpDiff('.string(a:diffname).')'
      augroup END
      wincmd x
      setlocal scrollbind
      diffthis
      augroup TuentiMercurialDiff
        autocmd BufWinLeave <buffer> nested call s:closeAll()
        autocmd BufWinEnter <buffer> call s:cleanUp()
      augroup END
      diffupdate
    endif
  endif
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

func s:cleanUpDiff(diffname)
  let varname = 't:'.a:diffname.'DiffBuffer'
  exe 'unlet!' varname
  call s:cleanUp()
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
    let filedir = expand('%:h')
    " save the current wrap modes to restore them later
    call s:recordWrapMode()
    " open the log navigation window
    botright 10 new
    let t:hgLogBuffer = bufnr('%')
    let b:fileDir = filedir
	" read the mercurial log into it -- all ancestors of the current parent,
	" sorted in reverse order of date (most recent first)
    silent exe 'file' fnameescape('log '.filepath)
    silent exe '1read !hg log --rev "sort(ancestors(parents(.)), -date)" --template "{rev}|{node|short}|{date|isodate}|{author|user}|{branches}|{parents}|{desc|firstline}\n" '.shellescape(filepath)
    1d
    " justify the first column (rev number)
    silent %s@^\d\+@\=submatch(0).repeat(' ', 6-len(submatch(0)))@
    " clean up the date column
    silent %s@^\(\%([^|]*|\)\{2\}\)\([^|]*\) +\d\d\d\d|@\1\2|@
    " justify/truncate the username column
    silent %s@^\(\%([^|]*|\)\{3\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,10).repeat(' ', 10-len(submatch(2)))@
    " justify/truncate the branch column
    silent %s@^\(\%([^|]*|\)\{4\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,30).repeat(' ', 30-len(submatch(2)))@
    " condense the parents column into "M" flag
    silent %s@^\(\%([^|]*|\)\{5\}\)\([^|]*\)@\=submatch(1).call('s:mergeFlag', [submatch(2)])@
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
    augroup TuentiMercurialDiff
      autocmd BufDelete <buffer> call s:cleanUp()
    augroup END
  endif
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
  unlet! t:hgLogBuffer
endfunc

func s:openLogRevisionDiffs(visual)
  call s:closeLogRevisionDiff(1)
  call s:closeLogRevisionDiff(2)
  if a:visual
    let rev1 = matchstr(getline(line("'>")), '\d\+') " earliest
    let rev2 = matchstr(getline(line("'<")), '\d\+') " latest
    try
      if rev1 != rev2
        call s:openLogRevisionDiff(1, rev1)
        call s:openLogRevisionDiff(2, rev2)
      else
        call s:openLogRevisionDiff(1, rev1)
      endif
    endtry
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
" 	:call s:setGlobalWrapMode(0) equivalent to :setglobal nowrap
" 	:call s:setGlobalWrapMode(1) equivalent to :setglobal wrap
" 	:call s:setGlobalWrapMode() equivalent to most recent of the above
func s:setGlobalWrapMode(...)
  if a:0
    let t:wrapMode = a:1
  endif
  if exists('g:wrapMode')
    let &g:wrap = t:wrapMode
  endif
endfunc

" Use this function instead of :setlocal [no]wrap.  There are three use cases:
" 	:call s:setBufferWrapMode(0) equivalent to :setlocal nowrap
" 	:call s:setBufferWrapMode(1) equivalent to :setlocal wrap
" 	:call s:setBufferWrapMode() equivalent to most recent of the above
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
