" Fold expression for asciidoc files
"
" NOTE: only supports Atx-style, not Setext style sections. See
" http://asciidoctor.org/docs/asciidoc-recommended-practices/ for more info.
"
" Script's originally based on https://github.com/nelstrom/vim-markdown-folding
"
" vim:set fdm=marker:

" Fold expressions {{{1
function! StackedMarkdownFolds()
  if HeadingDepth(v:lnum) > 0
    return ">1"
  else
    return "="
  endif
endfunction

function! NestedMarkdownFolds()
  let depth = HeadingDepth(v:lnum)
  if depth > 0
    return ">".depth
  else
    return "="
  endif
endfunction

" Helpers {{{1
function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

function! HeadingDepth(lnum)
  " 5 ='s is deepest section level, according to `asciidoc --help syntax`.
  " Only 1 is the document header, which isn't really worth folding.
  let level=0
  let thisline = getline(a:lnum)
  let hashCount = len(matchstr(thisline, '^=\{2,5}'))
  " Ignore lines with too many ='s (usually block deliminators)
  if hashCount > 0 && hashCount < 5
    let level = hashCount
  endif

  if level > 0 && LineIsFenced(a:lnum)
    " Ignore ='s if they appear within fenced code blocks
    let level = 0
  endif

  return level
endfunction

function! LineIsFenced(lnum)
  if exists("b:current_syntax") && b:current_syntax ==# 'asciidoc'
    " It's cheap to check if the current line has 'markdownCode' syntax group
    return s:HasSyntaxGroup(a:lnum, 'markdownCode')
  endif
endfunction

function! s:HasSyntaxGroup(lnum, targetGroup)
  let syntaxGroup = map(synstack(a:lnum, 1), 'synIDattr(v:val, "name")')
  for value in syntaxGroup
    " Likely dependant on the asciidoc syntax file, so will need to be
    " updated accordingly
    if value =~ '\vasciidocListingBlock'
      return 1
    endif
  endfor
endfunction


function! s:FoldText()
  let level = HeadingDepth(v:foldstart)
  let indent = repeat('=', level)
  let title = substitute(getline(v:foldstart), '^=\+\s*', '', '')
  let foldsize = (v:foldend - v:foldstart)
  let linecount = '['.foldsize.' line'.(foldsize>1?'s':'').']'
  return indent.' '.title.' '.linecount
endfunction

" API {{{1
function! ToggleMarkdownFoldexpr()
  if &l:foldexpr ==# 'StackedMarkdownFolds()'
    setlocal foldexpr=NestedMarkdownFolds()
  else
    setlocal foldexpr=StackedMarkdownFolds()
  endif
endfunction
command! -buffer FoldToggle call ToggleMarkdownFoldexpr()

" Setup {{{1
if !exists('g:markdown_fold_style')
  let g:markdown_fold_style = 'stacked'
endif

if !exists('g:markdown_fold_override_foldtext')
  let g:markdown_fold_override_foldtext = 1
endif

setlocal foldmethod=expr

if g:markdown_fold_override_foldtext
  let &l:foldtext = s:SID() . 'FoldText()'
endif

let &l:foldexpr =
  \ g:markdown_fold_style ==# 'nested'
  \ ? 'NestedMarkdownFolds()'
  \ : 'StackedMarkdownFolds()'

" Teardown {{{1
" To avoid errors when undo_ftplugin not defined yet
if !exists('b:undo_ftplugin')
    let b:undo_ftplugin = ''
endif

let b:undo_ftplugin .= '
  \ | setlocal foldmethod< foldtext< foldexpr<
  \ | delcommand FoldToggle
  \ '
