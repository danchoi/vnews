" Vim script that turns Vim into a feed reader
" Maintainer:	Daniel Choi <dhchoi@gnews.com>
" License: MIT License (c) 2011 Daniel Choi

if exists("g:VnewsLoaded") || &cp || version < 700
  finish
endif
let g:VnewsLoaded = 1

let mapleader = ','
highlight VnewsSearchTerm ctermbg=green guibg=green


let s:client_script = 'vnews-client '
let s:list_folders_command = s:client_script . 'folders '
let s:list_feeds_command = s:client_script . 'feeds '
let s:list_folder_items_command = s:client_script . 'folder_items ' 
let s:list_feed_items_command = s:client_script . 'feed_items ' 
let s:show_item_command = s:client_script . 'show_item '
let s:star_item_command = s:client_script . 'star_item ' " + guid star(bool)
let s:unstar_item_command = s:client_script . 'unstar_item ' " + guid star(bool)
let s:delete_items_command = s:client_script . 'delete_items ' " + guids
let s:search_items_command = s:client_script . 'search_items '
let s:cat_items_command = s:client_script . 'cat_items '

let s:folder = "All"
let s:feed = "All"
function! VnewsStatusLine()
  let end_index = match(s:last_selection, '(\d\+)$')
  let selection = s:last_selection[0:end_index-1]
  return "%<%f\ " . s:selectiontype . " " . selection . "%r%=%-14.(%l,%c%V%)\ %P"
endfunction

func! s:trimString(string)
  let string = substitute(a:string, '\s\+$', '', '')
  return substitute(string, '^\s\+', '', '')
endfunc


function! s:common_mappings()
  nnoremap <silent> <buffer> <Space> :call <SID>toggle_maximize_window()<cr>
  nnoremap <buffer> <leader>n :call <SID>list_folders()<CR>
  nnoremap <buffer> <leader>m :call <SID>list_feeds(0)<CR>
  nnoremap <buffer> <leader>M :call <SID>list_feeds(1)<CR>
  nnoremap <buffer> <leader>* :call <SID>toggle_star()<CR>
  nnoremap <buffer> <leader>8 :call <SID>toggle_star()<CR>
  nnoremap <buffer> <leader># :call <SID>delete_item()<CR>
  nnoremap <buffer> <leader>3 :call <SID>delete_item()<CR>
  nnoremap <buffer> u :call <SID>update_feed()<CR>
  nnoremap <buffer> <leader>u :call <SID>update_feed()<CR>
  nnoremap <silent> <leader>? :call <SID>show_help()<cr>
  command! -bar -nargs=0 VNUpdateFeed  :call <SID>update_feed()
  command! -bar -nargs=1 VNSearch :call s:search_items(<f-args>)
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
  nnoremap <silent> <buffer> <cr> :call <SID>show_item_under_cursor(1)<CR>
  nnoremap <silent> <buffer> <c-l> :call <SID>show_item_under_cursor(1)<CR>:wincmd p<CR>
  nnoremap <silent> <buffer> <c-j> :call <SID>show_adjacent_item(0, 'list-window')<CR> 
  nnoremap <silent> <buffer> <c-k> :call <SID>show_adjacent_item(1, 'list-window')<CR> 
  command! -bar -nargs=0 -range VNDelete :<line1>,<line2>call s:delete_item()
  command! -bar -nargs=0 -range VNConcat :<line1>,<line2>call s:cat_items()
  call s:common_mappings()
  if !exists("g:VnewsStarredColor")
    let g:VnewsStarredColor = "ctermfg=green guifg=green guibg=grey"
  endif
  syn match VnewsBufferStarred /^*.*/hs=s
  exec "hi def VnewsBufferStarred " . g:VnewsStarredColor
endfunction

function! s:create_item_window() 
  rightbelow split item-window
  setlocal modifiable 
  setlocal buftype=nofile
  let s:itembufnr = bufnr('%')
  nnoremap <silent> <buffer> <cr> <C-W>=<C-W>p
  nnoremap <silent> <buffer> <c-j> :call <SID>show_adjacent_item(0, "item-window")<CR> 
  nnoremap <silent> <buffer> <c-k> :call <SID>show_adjacent_item(1, "item-window")<CR> 
  nnoremap <silent> <buffer> q :call <SID>close_item_window()<cr> 
  nnoremap <buffer> <leader>o :call <SID>find_next_href_and_open()<CR>
  " opens the linked item
  nnoremap <buffer> <leader>h :normal Gkk<CR>:call <SID>find_next_href_and_open()<CR>
  call s:common_mappings()
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
  let s:selectionlist = a:selectionlist 
  call s:focus_window(s:listbufnr)
  exec "leftabove split ".a:buffer_name
  setlocal textwidth=0
  setlocal completefunc=CompleteFunction
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  resize 1
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>select_folder_or_feed()<CR> 
  noremap <buffer> q <Esc>:close<cr>
  inoremap <buffer> <Esc> <Esc>:close<cr>
  call setline(1, a:prompt)
  let s:prompt = a:prompt
  normal $
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! CompleteFunction(findstart, base)
  if a:findstart
    let start = len(s:prompt) + 1
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

" selection window pick
function! s:select_folder_or_feed()
  " let folder_or_feed = s:trimString(join(split(getline(line('.')), ":")[1:-1], ":"))
  let folder_or_feed = getline('.')[len(s:prompt):]
  close
  call s:focus_window(s:listbufnr)
  if (folder_or_feed == '') " no selection
    return
  end
  call s:fetch_items(folder_or_feed)
endfunction

func! s:list_folders()
  let folders = split(system(s:list_folders_command), "\n")
  if len(folders) == 0
    echom "There are no folders."
  else
    let s:selectiontype = "folder"
    call s:open_selection_window(folders, 'select-folder', "Select folder: ")
  end
endfunc

func! s:list_feeds(popular_first)
  " default is alphabetical 
  " 1 means order by popular_first
  let res = system(s:list_feeds_command . " " . a:popular_first) 
  let promptsuffix =  a:popular_first ? "(num of item views)" : "(num of items)"
  let feeds = split(res, "\n")
  if len(feeds) == 0
    echom "There are no feeds."
  else
    let s:selectiontype = "feed"
    call s:open_selection_window(feeds, 'select-feed', "Select feed ". promptsuffix .": ")
  end
endfunc

func! s:display_items(res)
  setlocal modifiable
  silent! 1,$delete
  silent! put! =a:res
  silent normal Gdd
  setlocal nomodifiable
  normal zz
endfunc

" right now, just does folders
function! s:fetch_items(selection)
  " take different actions depending on whether a feed or folder?
  call s:focus_window(s:itembufnr)
  call clearmatches()
  call s:focus_window(s:listbufnr)
  call clearmatches()
  if exists("s:selectionlist") && index(s:selectionlist, a:selection) == -1
    return
  end
  if s:selectiontype == "folder"
    let command = s:list_folder_items_command 
  else
    let command = s:list_feed_items_command
  endif
  let command .= winwidth(0) . ' ' .shellescape(a:selection)
  let s:last_fetch_command = command " in case user later updates the feed in place
  let s:last_selection = a:selection
  let res = system(command)
  call s:display_items(res)
  normal G
  call s:focus_window(s:itembufnr)
  close
  normal z-
  " call s:show_item_under_cursor(0)
  " call s:focus_window(s:listbufnr)
endfunction

func! s:get_guid(line)
  let line = getline(a:line)
  let s:guid = matchstr(line, '[^|]\+$')
  return s:trimString(s:guid)
endfunc

"------------------------------------------------------------------------
" SHOW ITEM
" blank arg is not used yet
func! s:show_item_under_cursor(inc_read_count)
  let s:guid = s:get_guid(line('.'))
  if s:guid == ""
    return
  end
  " mark as read
  set modifiable
  let newline = substitute(getline('.'), '^+', ' ', '')
  call setline(line('.'), newline)
  set nomodifiable
  let res = system(s:show_item_command . shellescape( s:guid) . ' '. ( a:inc_read_count ? "1" : "" ) )
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
  normal zz
  call s:show_item_under_cursor(1) " TOD0 is 1 right arg?
  normal zz
  call s:focus_window(bufnr(a:focusbufname))
  redraw
endfunction

func! s:close_item_window()
  if winnr('$') > 1
    close!
  else
    call s:focus_window(s:listbufnr)
    wincmd p
    close!
    normal zz
  endif
endfunc

func! s:toggle_maximize_window()
  if bufwinnr(s:listbufnr) != -1 &&  bufwinnr(s:itembufnr) != -1 
    if bufwinnr(s:listbufnr) == winnr()
      call s:focus_window(s:itembufnr)
      close
    else
      call s:focus_window(s:listbufnr)
      close
    endif
  elseif bufwinnr(s:listbufnr) == winnr()
    call s:show_item_under_cursor(1)
  elseif bufwinnr(s:itembufnr) == winnr()
    call s:focus_window(s:listbufnr)
    wincmd p
  endif
endfunc

"------------------------------------------------------------------------
let s:http_link_pattern = 'https\?:[^ >)\]]\+'

func! s:open_href_under_cursor()
  let href = expand("<cWORD>") 
  let command = g:Vnews#browser_command . " '" . href . "' "
  call system(command)
  echom command 
endfunc

func! s:find_next_href_and_open()
  let res = search(s:http_link_pattern, 'cw')
  if res != 0
    call s:open_href_under_cursor()
  endif
endfunc

if !exists("g:Vnews#browser_command")
  for cmd in ["gnome-open", "open"] 
    if executable(cmd)
      let g:Vnews#browser_command = cmd
      break
    endif
  endfor
  if !exists("g:Vnews#browser_command")
    echom "Can't find the to open your web browser."
  endif
endif

"------------------------------------------------------------------------
" TOGGLE STAR

function! s:toggle_star() 
  let original_winnr = winnr()
  call s:focus_window(s:listbufnr)
  let s:guid = s:get_guid(line('.'))
  let flag_symbol = "^*"
  if match(getline('.'), flag_symbol) != -1
    let already_starred = 1
  else
    let already_starred = 0
  end
  if !already_starred
    let command = s:star_item_command 
  else
    let command = s:unstar_item_command 
  endif
  let command .=  shellescape(s:guid )
  let res = system(command)
  setlocal modifiable
  let line = getline('.')
  " toggle * on line
  if !already_starred
    let newline = substitute(line, '^ ', '*', '')
    let newline = substitute(newline, '^+', '*', '')
  else
    let newline = substitute(line, '^*', ' ', '')
  endif
  call setline(line('.'), newline)
  setlocal nomodifiable
  exec original_winnr . "wincmd w"
  redraw
endfunction

"------------------------------------------------------------------------
" DELETE ITEMS

func! s:delete_item()  range
  call s:focus_window(s:listbufnr)
  let lnum = a:firstline
  let items = []
  while lnum <= a:lastline
    let guid = s:get_guid(lnum)
    call add(items, shellescape(guid))
    let lnum += 1
  endwhile
  let command = s:delete_items_command . join(items, ' ')
  call system(command)
  setlocal modifiable
  exec "silent " . a:firstline . "," . a:lastline . "delete"
  setlocal nomodifiable
  redraw
endfunc

"------------------------------------------------------------------------
" PRINT ITEMS

" must be called from list window
func! s:cat_items() range
  let lnum = a:firstline
  let items = []
  while lnum <= a:lastline
    let guid = s:get_guid(lnum)
    call add(items, shellescape(guid))
    let lnum += 1
  endwhile
  call s:focus_window(s:itembufnr)
  only
  let command = s:cat_items_command . join(items, ' ')
  let res = system(command)
  setlocal modifiable
  silent 1,$delete
  silent put =res
  silent 1delete
  silent normal 1Gjk
  setlocal nomodifiable
  redraw
  echom "Concatenated ".len(items)." item".(len(items) == 1 ? '' : 's')
endfunc


"------------------------------------------------------------------------
" SEARCH
func! s:search_items(term)
  call s:focus_window(s:listbufnr)
  let command = s:search_items_command . winwidth(0) . ' ' . shellescape(a:term)
  let res = system(command)
  call s:display_items(res)
  " show item for top match
  call s:show_item_under_cursor(0)
  " item window will be focused
  call clearmatches()
  for word in split(a:term, '\s\+') 
    call matchadd("VnewsSearchTerm", '\c' . word)
  endfor
  call s:focus_window(s:listbufnr)
  call clearmatches()
  for word in split(a:term, '\s\+') 
    call matchadd("VnewsSearchTerm", '\c' . word)
  endfor
endfunc

"------------------------------------------------------------------------
" UPDATE FEED

func! s:update_feed()
  call s:focus_window(s:listbufnr)
  if exists("s:last_selection")
    if s:selectiontype == "folder"
      exec ":!vnews-client update_folder ".shellescape(s:last_selection)
    elseif s:selectiontype == "feed"
      exec ":!vnews-client update_feed ".shellescape(s:last_selection)
    end
  endif
  if exists("s:last_fetch_command")
    let res = system(s:last_fetch_command)
    call s:display_items(res)
  end
  redraw!
  normal G
  call s:show_item_under_cursor(0)
  redraw!
endfunc


" -------------------------------------------------------------------------------- 
"  HELP
func! s:show_help()
  let command = g:Vnews#browser_command . ' ' . shellescape('http://danielchoi.com/software/vnews.html')
  call system(command)
endfunc


call s:create_list_window()
call s:create_item_window()
call s:focus_window(s:listbufnr) 
let s:selectiontype = "folder"
call s:fetch_items("All (0)") " number won't show but is assumed by function VnewsStatusLine()


