let s:drb_uri = $DRB_URI
" changeme delete bin/ for production 
let s:client_script = "bin/vnews_client " . shellescape(s:drb_uri) . " "

function! s:save_node()
  " get the node text and position to save
  " can get indentation position directly 
  " but we also need to know its parent and previous siblings
  " collapsed previous siblings are ok. we don't need to know how many
  " children they have, only how many prev sibs there are

  " find the last node mark 
  let text = join(getline(1, line('.')), "\n")
  let command = s:client_script . " save_node " 
  echo command
  let res = system(command, text)
  " delete
  " put! =res
endfunction

" calculates position of the cursor relative to the outline structure
function! s:calculate_position()
  " Start from line position and run upwards 
  " Can send text to Ruby and do the calc there
endfunc

noremap <silent> <buffer> <leader><cr> :call <SID>save_node()<CR>
"inoremap <silent> <buffer> <cr> <esc>:call <SID>save_node()<CR>

