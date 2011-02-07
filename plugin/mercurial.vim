" Mercurial vim diff mode functions.
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
endif

" Global maps, available for your own key bindings.
"
noremap <silent> <unique> <script> <Plug>DiffsCloseAll :call <SID>closeAllDiffs()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenWorkingParent :call <SID>openWorkingParentDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsCloseWorkingParent :call <SID>closeWorkingParentDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenCurrentTrunk :call <SID>openTrunkDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsCloseCurrentTrunk :call <SID>closeTrunkDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenLastMergedTrunk :call <SID>openLastMergedTrunkDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsCloseLastMergedTrunk :call <SID>closeLastMergedTrunkDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenBranchOrigin :call <SID>openBranchOriginDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsCloseBranchOrigin :call <SID>closeBranchOriginDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenPriorRelease :call <SID>openPriorReleaseDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsClosePriorRelease :call <SID>closePriorReleaseDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsOpenNewestRelease :call <SID>openNewestReleaseDiff()<CR>
noremap <silent> <unique> <script> <Plug>DiffsCloseNewestRelease :call <SID>closeNewestReleaseDiff()<CR>

" Whenever any buffer (window) goes away, if there are no more diff windows
" remaining, then turn off diff mode in the principal buffer.
autocmd BufHidden * call s:cleanUpDiffs()

" ------------------------------------------------------------------------------
" APPLICATION FUNCTIONS

let s:allDiffNames = ['workingParent', 'branchOrigin', 'mergedTrunk', 'currentTrunk', 'priorRelease', 'newestRelease']

func s:closeAllDiffs()
  for diffname in s:allDiffNames
    call s:closeDiff(diffname)
  endfor
endfunc

func s:cleanUpDiffs()
  if exists('t:turnOffDiff') && t:turnOffDiff == bufnr('%')
    " This is a kludge, to work around a bug that the :diffoff! below does not turn
	" off diff mode in the buffer that is being left.
    diffoff
	unlet t:turnOffDiff
  endif
  if !s:testAnyDiffExists()
    "echo 'exists("t:origDiffBuffer") = ' . exists('t:origDiffBuffer') . ', bufnr("%") = ' . bufnr('%')
	"echo 'wah'
	diffoff!
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
  let rel = s:newestHgReleaseName()
  if rel != ''
    call s:openHgDiff('newestRelease', rel, rel)
  endif
endfunc
func s:closeNewestReleaseDiff()
  call s:closeDiff('newestRelease')
endfunc

func s:openPriorReleaseDiff()
  let rel = s:priorHgReleaseName()
  if rel != ''
    call s:openHgDiff('priorRelease', rel, rel)
  endif
endfunc
func s:closePriorReleaseDiff()
  call s:closeDiff('priorRelease')
endfunc

" ------------------------------------------------------------------------------
" PRIVATE FUNCTIONS

" Return a list of the names of all Mercurial release branches, in lexical
" sorted order.
func s:allHgReleaseNames()
  let rels = split(system('hg branches | awk ''$1~/^release-/{print $1}'''), "\n")
  if empty(rels)
    return ''
  endif
  return sort(rels)
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
func s:newestHgReleaseName()
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
  return split(system('hg log --template "{node}\n" '.a:hgLogOpts), "\n")
endfunc

" Return much information about a specific revision.
func s:getHtRevisionInfo(rev)
  let lines = split(system('hg log --template "{rev}\n{node}\n{node|short}\n{branches}\n{parents}\n{tags}\n{author}\n{author|user}\n{date|date}\n{date|isodate}\n{date|shortdate}\n{desc}\n" --rev '.a:rev), "\n")
  let info = {}
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
  let info.summary = lines[0]
  let info.description = join(lines, "\n")
  return info
endfunc

" Return the current Mercurial branch's most recently merged trunk (default
" branch) revision.  Ie, the revision of the trunk that was merged in, not the
" resulting revision in the current branch.
func s:latestHgDefaultMergeRevision()
  let merges = s:getHgRevisions('--branch . --only-merges')
  for rev in merges
    let info = s:getHtRevisionInfo(rev)
	if info.branch != 'default'
	  for parentrev in info.parentrevs
		let parentinfo = s:getHtRevisionInfo(parentrev)
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
  let info = s:getHtRevisionInfo(a:rev)
  let annotation = info.shortnode.' '.info.user.' '.info.shortdate
  call s:openDiff(a:diffname, '!hg cat -r '.a:rev.' #', annotation, a:label)
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
  let varname = "t:".a:diffname."DiffBuf"
  if exists(varname)
    diffupdate
  else
    if exists("t:origDiffBuffer")
      exe t:origDiffBuffer 'buffer'
	else
	  let t:origDiffBuffer = bufnr("%")
    endif
  	let ft = &filetype
  	vnew
    exe 'let' varname "=" bufnr("%")
	let displayName = (a:label != '') ? a:label : a:diffname
	if a:annotation != ''
	  let displayName .= ' '.a:annotation
	endif
	silent exe 'file' fnameescape(displayName)
	silent exe '1read' a:readArg
	1d
    set buftype=nofile
  	let &filetype = ft
    set scrollbind
    set noswapfile
    set bufhidden=delete
	diffthis
	augroup TuentiMercurialDiff
      exe 'autocmd BufDelete <buffer> call s:cleanUpDiff('.string(a:diffname).')'
	augroup END
    wincmd x
	augroup TuentiMercurialDiff
      autocmd BufWinLeave <buffer> nested call s:closeAllDiffs()
	  autocmd BufWinEnter <buffer> call s:cleanUpDiffs()
	augroup END
	diffthis
  endif
endfunc

func s:closeDiff(diffname)
  let varname = 't:'.a:diffname.'DiffBuf'
  if exists(varname)
    exe 'exe' varname '"bdelete"'
  endif
endfunc

func s:cleanUpDiff(diffname)
  let varname = 't:'.a:diffname.'DiffBuf'
  exe 'unlet!' varname
  call s:cleanUpDiffs()
endfunc

func s:testAnyDiffExists()
  for diffname in s:allDiffNames
    let varname = 't:'.diffname.'DiffBuf'
	if exists(varname)
	  return 1
	endif
  endfor
  return 0
endfunc

" ------------------------------------------------------------------------------
" Standard Vim plugin boilerplate.
let &cpo= s:keepcpo
unlet s:keepcpo
