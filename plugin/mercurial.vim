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
  if !hasmapto('<Plug>DiffsCloseAll')
    nmap <unique> <Leader>\ <Plug>DiffsCloseAll
    nmap <unique> <Leader>0 <Plug>DiffsCloseAll
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
  if !hasmapto('<Plug>DiffsCloseLogRevision')
    nmap <unique> <Leader>x <Plug>DiffsCloseLogRevision
    nmap <unique> <Leader>X <Plug>DiffsCloseLogRevision
  endif
  if !hasmapto('<Plug>OpenLogWindow')
    nmap <unique> <Leader>l <Plug>OpenLogWindow
  endif
  if !hasmapto('<Plug>CloseLogWindow')
    nmap <unique> <Leader>L <Plug>CloseLogWindow
  endif
endif

" Global maps, available for your own key bindings.
"
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
noremap <silent> <unique> <Plug>DiffsCloseLogRevision :call <SID>closeLogRevisionDiff()<CR>
noremap <silent> <unique> <Plug>OpenLogWindow :call g:openLogWindow()<CR>
noremap <silent> <unique> <Plug>CloseLogWindow :call g:closeLogWindow()<CR>

" Whenever any buffer (window) goes away, if there are no more diff windows
" remaining, then turn off diff mode in the principal buffer.
autocmd BufHidden * call s:cleanUpDiffs()

" ------------------------------------------------------------------------------
" APPLICATION FUNCTIONS

let s:allDiffNames = ['workingParent', 'branchOrigin', 'mergedTrunk', 'currentTrunk', 'priorRelease', 'newestRelease', 'logRevision']

func s:closeAllDiffs()
  for diffname in s:allDiffNames
    call s:closeDiff(diffname)
  endfor
endfunc

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
func s:cleanUpDiffs()
  if exists('t:turnOffDiff') && t:turnOffDiff == bufnr('%')
    " This is a kludge, to work around a bug that the :diffoff! below does not turn
    " off diff mode in the buffer that is being left.
    diffoff
    unlet t:turnOffDiff
    call s:restoreWrapMode()
  endif
  if !s:testAnyDiffExists()
    "echo 'exists("t:origDiffBuffer") = ' . exists('t:origDiffBuffer') . ', bufnr("%") = ' . bufnr('%')
    "echo 'wah'
    diffoff!
    call s:restoreWrapMode()
    if exists('t:origDiffBuffer')
      let t:turnOffDiff = t:origDiffBuffer
      unlet! t:origDiffBuffer
    endif
  endif
endfunc

func s:openWorkingParentDiff()
  call s:openHgDiff('workingParent', '.', '')
endfunc
func s:closeWorkingParentDiff()
  call s:closeDiff('workingParent')
endfunc

func s:openBranchOriginDiff()
  let rev = get(s:getHgRevisions('--branch .'), -1, '')
  if rev != ''
    call s:openHgDiff('branchOrigin', rev, '')
  endif
endfunc
func s:closeBranchOriginDiff()
  call s:closeDiff('branchOrigin')
endfunc

func s:openLastMergedTrunkDiff()
  let rev = s:latestHgDefaultMergeRevision()
  if rev != ''
    call s:openHgDiff('mergedTrunk', rev, '')
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
  let rev = g:newestHgReleaseName()
  if rev != ''
    call s:openHgDiff('newestRelease', rev, rev)
  endif
endfunc
func s:closeNewestReleaseDiff()
  call s:closeDiff('newestRelease')
endfunc

func s:openPriorReleaseDiff()
  let rev = s:priorHgReleaseName()
  if rev != ''
    call s:openHgDiff('priorRelease', rev, rev)
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

" Return a list of the names of all Mercurial release branches in the current
" file's repository, in lexical sorted order.
func s:allHgReleaseNames()
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).'&& hg --config defaults.branches= branches | awk ''$1~/^release-/{print $1}'''), "\n")
  if s:displayHgError('Could not get list of branches', lines)
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
func g:newestHgReleaseName()
  return get(s:allHgReleaseNames(), -1, '')
endfunc

" Return the penultimate Mercurial release name, or '' if there are fewer than
" two release branches.
func s:priorHgReleaseName()
  return get(s:allHgReleaseNames(), -2, '')
endfunc

" Return a list of Mercurial revision IDs (nodes) determined by the given
" hg log options, in reverse chronological order (most recent first).
func s:getHgRevisions(hgLogOpts)
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).' && hg --config defaults.log= log --template "{node}\n" '.a:hgLogOpts), "\n")
  if s:displayHgError('Could not get revisions from "hg log '.a:hgLogOpts.'"', lines)
    return []
  endif
  return lines
endfunc

" Return much information about a specific revision.
func s:getHgRevisionInfo(rev)
  let info = {}
  let dir = s:getHgCwd()
  let lines = split(system('cd '.shellescape(dir).' && hg --config defaults.log= log --template "{rev}\n{node}\n{node|short}\n{branches}\n{parents}\n{tags}\n{author}\n{author|user}\n{date|date}\n{date|isodate}\n{date|shortdate}\nDESCRIPTION\n{desc}\n" --rev '.a:rev), "\n")
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
    let annotation = info.shortnode.' '.info.user.' '.info.shortdate
    call s:openDiff(a:diffname, '!hg --config defaults.cat= cat -r '.a:rev.' #', annotation, a:label)
  endif
endfunc

" Open a new diff window containing the contents of the given file, which is
" fetched using the :read command, so can be specified using '!' notation to
" capture the output of a command.
"
" Param: diffname The symbolic name of the new diff buffer
" Param: readArg The argument passed to :read to fill the new buffer
" Param: annotation Extra information appended the buffer's label
" Param: label If set, replaces diffName as the displayed label
"
func s:openDiff(diffname, readArg, annotation, label)
  "echo "openDiff(".string(a:diffname).', '.string(a:readArg).', '.string(a:annotation).', '.string(a:label).')'
  let varname = "t:".a:diffname."DiffBuffer"
  if exists(varname)
    diffupdate
    call s:setBufferWrapMode()
  else
    if exists("t:origDiffBuffer")
      exe bufwinnr(t:origDiffBuffer) 'wincmd w'
    elseif exists("t:hgLogFileBuffer")
      exe bufwinnr(t:hgLogFileBuffer) 'wincmd w'
    else
      let t:origDiffBuffer = bufnr("%")
    endif
    " if there are no diff buffers in existence, save the wrap mode of the
    " original file buffer and the global wrap mode too, so that we can restore
    " them after :diffoff
    if !exists('g:preDiffWrapMode')
      let g:preDiffWrapMode = &g:wrap
    endif
    if !exists('b:preDiffWrapMode')
      let b:preDiffWrapMode = &l:wrap
    endif
    " turn off wrap mode in the original file buffer
    call s:setBufferWrapMode(0)
    let ft = &filetype
    let filedir = expand('%:h')
    vnew
    let b:fileDir = filedir
    " turn off wrap mode in the new diff buffer
    call s:setBufferWrapMode(0)
    exe 'let' varname "=" bufnr("%")
    let displayName = (a:label != '') ? a:label : a:diffname
    if a:annotation != ''
      let displayName .= ' '.a:annotation
    endif
    silent exe 'file' fnameescape(displayName)
    silent exe '1read' a:readArg
    1d
    let &l:filetype = ft
    setlocal buftype=nofile
    setlocal nomodifiable
    setlocal noswapfile
    setlocal bufhidden=delete
    setlocal scrollbind
    diffthis
    augroup TuentiMercurialDiff
      exe 'autocmd BufDelete <buffer> call s:cleanUpDiff('.string(a:diffname).')'
    augroup END
    wincmd x
    setlocal scrollbind
    diffthis
    augroup TuentiMercurialDiff
      autocmd BufWinLeave <buffer> nested call s:closeAllDiffs()
      autocmd BufWinEnter <buffer> call s:cleanUpDiffs()
    augroup END
    diffupdate
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
  call s:cleanUpDiffs()
endfunc

func s:testAnyDiffExists()
  for diffname in s:allDiffNames
    let varname = 't:'.diffname.'DiffBuffer'
    if exists(varname)
      return 1
    endif
  endfor
  return 0
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

func g:openLogWindow()
  if exists('t:hgLogBuffer')
    call g:closeLogWindow()
  endif
  " first switch to the original diff buffer, if there is one, otherwise operate
  " on the current buffer
  if exists("t:origDiffBuffer")
    exe t:origDiffBuffer 'buffer'
  endif
  " only proceed for normal buffers
  if &buftype == ''
    " figure out the file name and number of the current buffer
    let t:hgLogFileBuffer = bufnr("%")
    let filepath = expand('%')
    let filedir = expand('%:h')
    " open the log navigation window
    botright 10 new
    let t:hgLogBuffer = bufnr('%')
    let b:fileDir = filedir
    " read the mercurial log into it
    silent exe 'file' fnameescape('log '.filepath)
    silent exe '1read !hg log --template "{rev}|{node|short}|{date|isodate}|{author|user}|{desc}\n" '.shellescape(filepath)
    1d
    " justify the first column (rev number)
    silent %s@^\d\+@\=submatch(0).repeat(' ', 5-len(submatch(0)))@
    " clean up the date column
    silent %s@^\(\%([^|]*|\)\{2\}\)\([^|]*\) +\d\d\d\d|@\1\2|@
    " justify/truncate the username column
    silent %s@^\(\%([^|]*|\)\{3\}\)\([^|]*\)@\=submatch(1).strpart(submatch(2),0,14).repeat(' ', 14-len(submatch(2)))@
    " go the first line (most recent revision)
    1
    " set the buffer properties
    setlocal buftype=nofile
    setlocal nomodifiable
    setlocal noswapfile
    setlocal bufhidden=delete
    call s:setBufferWrapMode(0)
    " Set up some useful key mappings.
    " The crap after the <CR> is a kludge to force Vim to synchronise the
    " scrolling of the diff windows, which it does not do correctly
    nmap <silent> <CR> :call <SID>openLogRevisionDiff(matchstr(getline('.'), '\d\+'))<CR>0kj
    " housekeeping for buffer close
    augroup TuentiMercurialDiff
      autocmd BufDelete <buffer> call s:cleanUpLog()
    augroup END
  endif
endfunc

func g:closeLogWindow()
  if exists('t:hgLogBuffer')
    " delete the buffer and let the BufDelete autocmd do the clean-up
    exe t:hgLogBuffer 'bdelete'
  endif
endfunc

func s:cleanUpLog()
  unlet! t:hgLogBuffer
  unlet! t:hgLogFileBuffer
endfunc

func s:openLogRevisionDiff(rev)
  call s:closeDiff('logRevision')
  if a:rev != '' && exists('t:hgLogFileBuffer')
    " put the focus in the file window so that openHgDiff() works
    exe bufwinnr(t:hgLogFileBuffer) 'wincmd w'
    call s:openHgDiff('logRevision', a:rev, a:rev)
    " return the focus to the log window
    if exists('t:hgLogBuffer')
      exe bufwinnr(t:hgLogBuffer) 'wincmd w'
      call s:setBufferWrapMode(0)
    endif
  endif
endfunc
func s:closeLogRevisionDiff()
  call s:closeDiff('logRevision')
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

func s:setGlobalWrapMode(...)
  if a:0
    let g:wrapMode = a:1
  endif
  if exists('g:wrapMode')
    let &g:wrap = g:wrapMode
  endif
endfunc

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
