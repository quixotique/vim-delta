" Vim syntax file
" Copyright 2011 Tuenti Technologies S.L.
" Language:	Delta.Vim Mercurial Plugin compact log window
" Maintainer:	Andrew Bettison <andrew@iverin.com.au>
" License:	GPL 3.0
" Last change:	2011 02 25

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

syn match	hgclRev		"^\d\+ *"			nextgroup=hgclSep1
syn match	hgclSep1	"|"					nextgroup=hgclNode contained
syn match	hgclNode	"[0-9a-f]\{12\}"	nextgroup=hgclSep2 contained
syn match	hgclSep2	"|"					nextgroup=hgclDate contained
syn match	hgclDate	"\d\d\d\d-\d\d-\d\d \d\d:\d\d" nextgroup=hgclSep3 contained
syn match	hgclSep3	"|"					nextgroup=hgclUser contained
syn match	hgclUser	"[^|]*"			    nextgroup=hgclSep4 contained
syn match	hgclSep4	"|"					nextgroup=hgclBranch contained
syn match	hgclBranch	"[^|]*"			    nextgroup=hgclSep5 contained
syn match	hgclSep5	"|"					nextgroup=hgclFlags contained
syn match	hgclFlags	"[^|]*"				nextgroup=hgclSep6 contains=hgclMergeFlag contained
syn match	hgclSep6	"|"					nextgroup=hgclComment contained
syn match	hgclComment	".*$"				contains=hgclTicket contained

syn match	hgclMergeFlag	"M" contained
syn match	hgclTicket	    "#\d\+" contained

" The default highlighting.
hi def link hgclRev		Label
hi def link hgclNode	Constant
hi def link hgclUser	Type
hi def link hgclTicket	Identifier
hi def link hgclBranch	Tag
hi def link hgclComment Comment

let b:current_syntax = "hglogcompact"

" vim: et sts=2 sw=2
