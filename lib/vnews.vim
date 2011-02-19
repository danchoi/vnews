" Vim script that turns Vim into a feed reader
" Maintainer:	Daniel Choi <dhchoi@gnews.com>
" License: MIT License (c) 2011 Daniel Choi

if exists("g:VnewsLoaded") || &cp || version < 700
  finish
endif
let g:VnewsLoaded = 1

let mapleader = ','

"let s:client_script = 'vnews-client '
let s:client_script = 'bin/vnews-client '
let s:list_folders_command = s:client_script . 'folders '
let s:list_feeds_command = s:client_script . 'feeds '
let s:list_folder_items_command = s:client_script . 'folder_items ' 
let s:list_feed_items_command = s:client_script . 'feed_items ' 
let s:show_item_command = s:client_script . 'show_item '
let s:set_window_width_command = s:client_script . "window_width= "

let s:folder = "All"
let s:feed = "All"
function! VnewsStatusLine()
  return "%<%f\ " . s:folder . " " . s:feed . "%r%=%-14.(%l,%c%V%)\ %P"
endfunction

func! s:trimString(string)
  let string = substitute(a:string, '\s\+$', '', '')
  return substitute(string, '^\s\+', '', '')
endfunc

function! s:create_list_window()
  new list-window
  wincmd p 
  close
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal modifiable
  setlocal textwidth=0
  setlocal nowrap
  setlocal number
  setlocal foldcolumn=0
  setlocal nospell
  " setlocal noreadonly
  " hi CursorLine cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white 
  setlocal cursorline
  " we need to find the window later
  let s:listbufnr = bufnr('')
  let s:listbufname = bufname('')
  setlocal statusline=%!VnewsStatusLine()
  noremap <silent> <buffer> <cr> :call <SID>show_item_under_cursor(0)<CR>
  noremap <silent> <buffer> <c-j> :call <SID>show_adjacent_item(0, 'list-window')<CR> 
  noremap <silent> <buffer> <c-k> :call <SID>show_adjacent_item(1, 'list-window')<CR> 
endfunction

function! s:create_item_window() 
  rightbelow split item-window
  setlocal modifiable 
  setlocal buftype=nofile
  let s:itembufnr = bufnr('%')
  
  noremap <silent> <buffer> <cr> <C-W>p<CR> 
  noremap <silent> <buffer> <c-j> :call <SID>show_adjacent_item(0, "item-window")<CR> 
  noremap <silent> <buffer> <c-k> :call <SID>show_adjacent_item(1, "item-window")<CR> 

  close
endfunction

function! s:focus_window(target_bufnr)
  if bufwinnr(a:target_bufnr) == winnr() 
    return
  end
  let winnr = bufwinnr(a:target_bufnr) 
  if winnr == -1
    if a:target_bufnr == s:listbufnr
      leftabove split
    else
      rightbelow split
    endif
    exec "buffer" . a:target_bufnr
  else
    exec winnr . "wincmd w"
  endif
  " set up syntax highlighting
  if has("syntax")
    " 
  endif
endfunction

function! s:open_selection_window(selectionlist, buffer_name, prompt)
  let s:return_to_winnr = winnr()
  let s:return_to_bufname = bufname('')
  let s:selectionlist = a:selectionlist 
  exec "leftabove split ".a:buffer_name
  setlocal completefunc=CompleteFunction
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  resize 1
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>select_folder_or_feed()<CR> 
  noremap <buffer> q <Esc>:close<cr>
  inoremap <buffer> <Esc> <Esc>:close<cr>
  call setline(1, a:prompt)
  normal $
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! CompleteFunction(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\m[[:alnum:]]'
      let start -= 1
    endwhile
    return start
  else
    let base = s:trimString(a:base)
    if (base == '')
      return s:selectionlist
    else
      let res = []
      for m in s:selectionlist
        if m =~ '\c' . base 
          call add(res, m)
        endif
      endfor
      return res
    endif
  endif
endfun

function! s:select_folder_or_feed()
  let folder_or_feed = s:trimString(get(split(getline(line('.')), ": "), 1) )
  close
  exe s:return_to_winnr . "wincmd w"
  if (folder_or_feed == '') " no selection
    return
  end
  call s:fill_folder_or_feeds(folder_or_feed)
endfunction

func! s:list_folders()
  let folders = split(system(s:list_folders_command), "\n")
  if len(folders) == 0
    echom "There are no folders."
  else
    call s:open_selection_window(folders, 'select-folder', "Select folder: ")
  end
endfunc

" right now, just does folders
function! s:fill_items(selection)
  " take different actions depending on whether a feed or folder?

  call s:focus_window(s:listbufnr)
  setlocal modifiable
  let res = system(s:list_folder_items_command . shellescape(a:selection))
  silent! 1,$delete
  silent! put! =res
  silent normal Gdd
  setlocal nomodifiable
  normal z.
endfunction

" blank arg is not used yet
func! s:show_item_under_cursor(blank)
  let line = getline(line("."))
  let s:guid = matchstr(line, '\S\+$')
  if s:guid == ""
    return
  end
  echo s:guid
  let res = system(s:show_item_command . s:guid)
  call s:focus_window(s:itembufnr)
  set modifiable
  silent 1,$delete
  silent put =res
  silent 1delete
  silent normal 1Gjk
  set nomodifiable
endfunc

" from message window
function! s:show_adjacent_item(up, focusbufname)
  if (bufwinnr(s:listbufnr) == -1) " we're in full screen item mode
    3split " make small nav window on top
    exec 'b'. s:listbufnr
  else
    call s:focus_window(s:listbufnr)
  end
  if a:up
    normal k
  else
    normal j
  endif
  call s:show_item_under_cursor(1) " TOD0 is 1 right arg?
  normal zz
  call s:focus_window(bufnr(a:focusbufname))
  redraw
endfunction


call s:create_list_window()
call s:create_item_window()
call s:focus_window(s:listbufnr) 

call s:fill_items("Main")

nnoremap <leader>m :call <SID>list_folders()<CR>

