call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'SirVer/ultisnips'
Plug 'itchyny/lightline.vim'
Plug 'insanum/votl'
Plug 'flazz/vim-colorschemes'
Plug 'mattn/emmet-vim'
Plug 'humus/ultisnips_snippets'
Plug 'humus/transplant.vim'
Plug 'humus/vim-recipesj'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-fugitive'
call plug#end()


let s:path=expand('<sfile>:p:h')
execute "source " . s:path . "/settings.vim"
execute "source " . s:path . "/mappings.vim"

command! Esettings execute "e " . s:path . "/settings.vim"
command! Emappings execute "e " . s:path . "/mappings.vim"

function! MkDir() "{{{
    silent! call system("mkdir -p " . expand("%:p:h"))
endfunction "}}}

function! s:history(arg, bang)
  let bang = a:bang || a:arg[len(a:arg)-1] == '!'
  if a:arg[0] == ':'
    call fzf#vim#command_history(bang)
  elseif a:arg[0] == '/'
    call fzf#vim#search_history(bang)
  else
    call fzf#vim#history(bang)
  endif
endfunction
command!      -bang -nargs=* History                   call s:history(<q-args>, <bang>0)
command! -bar -bang -nargs=? -complete=buffer Buffers  call fzf#vim#buffers(<q-args>, <bang>0)

fun! s:find_serial_ver() "{{{
    let l:fqcn=s:search_package() . '.' . expand('%:t:r')
    let l:fqcn=substitute(l:fqcn, '^\.', '', '')
    let l:indent=&et? '    ' : "\t"
    let l:pom_xml=findfile('pom.xml', expand('%:p:h').';')
    let l:base_dir=fnamemodify(l:pom_xml, ':h')
    let l:cmd='serialver -classpath ' . l:base_dir .
                \ '/target/classes:' . l:base_dir .
                \ '/target/test-classes:' . l:base_dir . ' ' .
                \ l:fqcn
    let l:serial_ver=l:indent . 'private ' . matchstr(system(l:cmd), '\v^[^:]+:\s+\zs.+')
    let l:serial_ver = substitute(l:serial_ver, 'private private', 'private', '')
    let l:serial_ver=substitute(l:serial_ver, "\n", '', '')
    return l:serial_ver
endfunction "}}}

fun! s:search_package() "{{{
  for line_nr in range(line('$'))
    let l:line = getline(line_nr)
    if  l:line =~ '\v^package.*'
      return matchstr(l:line, '\vpackage \zs.+\ze;')
    endif
  endfor
  return ''
endfunction "}}}


fun! s:serial_ver() "{{{
  let l:line_serial_ver=search('\v^\s+(private )?static final long serialVersionUID.*', 'n')
  if l:line_serial_ver != 0
    echohl warningmsg | echo 'already has serialVersionUID' | echohl none
    return
  endif
  let serial_ver=s:find_serial_ver()
  if serial_ver !~ '\v\s+private static'
    echohl warningmsg | echo 'Class not serializable' | echohl none
    return
  endif
  call s:append_serial_ver(serial_ver)
endfunction "}}}

fun! s:append_serial_ver(serialver) "{{{
  let l:lines = ['', a:serialver]
  let l:public_class_line = search('\v^public class \S+.*', 'n')
  call append(l:public_class_line, l:lines)
endfunction "}}}

fun! s:gen_tostring() "{{{
  let l:pos = getpos('.')
  let to_string_l = s:search_tostring()
  if to_string_l > 0
    echohl WarningMsg | echo 'toString alreadyExists' | echohl None
    return
  endif
  let l:properties = s:handle_props_for_stdmethods('Include property in toString?')
  if !empty(l:properties)
    call s:append_tostring(l:properties)
  else
    echohl WarningMsg | echo 'toString not generated' | echohl None
  endif
  call cursor(l:pos[1], l:pos[2])
endfunction "}}}

fun! s:append_tostring(properties) "{{{
  let l:indent = &et ? '    ' : '	'
  call s:ensure_import('org.apache.commons.lang3.builder.ToStringBuilder')
  let l:method = [l:indent.'public String toString() {', 
        \ repeat(l:indent, 2).'return new ToStringBuilder(this)']
  for l:prop in a:properties
    let l:str_body = [repeat(l:indent, 4),
          \'.append("', l:prop, '"', ', ', l:prop, ')']
    call add(l:method, join(l:str_body, ''))
  endfor
  call add(l:method, repeat(l:indent, 4) . '.toString();')
  call add(l:method, l:indent . '}')
  call add(l:method, '')
  call cursor(line('$'), 1)
  call search('\v^\}\s*$', 'bc')
  call append(line('.')-1, l:method)
endfunction "}}}

fun! s:ensure_import(clazz) "{{{
  call cursor(line('$'), 1)
  let exists_import = search('\v^import\s+' . a:clazz, 'bn')
  if !exists_import
    let l:line = search('\v^(package[^;]+;|import[^;]+;)', 'bn')
    if l:line == 1
      call append(1, '')
      let l:line += 1
    endif
    call append(l:line, 'import ' . a:clazz . ';')
  endif
endfunction "}}}


fun! s:search_tostring() "{{{
  return s:search_std_method('\v^\s+public\s+String\s+toString')
endfunction "}}}

fun! s:search_std_method(method_expr) "{{{
  let l:pos = getpos('.')
  call cursor(line('$'), 1)
  let l:found = search(a:method_expr, 'bn')
  call cursor(l:pos[1], l:pos[2])
  return l:found
endfunction "}}}

fun! s:gen_equals() "{{{
  let l:pos = getpos('.')
  let l:equals_l = s:search_equals()
  if l:equals_l > 0
    echohl WarningMsg | echo 'equals alreadyExists' | echohl None
    return
  endif
  let l:properties = s:handle_props_for_stdmethods('Include property in Equals?')
  if !empty(l:properties)
    call s:append_equals(l:properties)
  else
    echohl WarningMsg | echo 'equals not generated' | echohl None
  endif
  call cursor(l:pos[1], l:pos[2])
endfunction "}}}

fun! s:gen_hashcode() "{{{
  let l:pos = getpos('.')
  let to_hashcode_l = s:search_hashcode()
  if to_hashcode_l > 0
    echohl WarningMsg | echo 'hashCode alreadyExists' | echohl None
    return
  endif
  let l:properties = s:handle_props_for_stdmethods('Include property in hashCode?')
  if !empty(l:properties)
    call s:append_hashcode(l:properties)
  else
    echohl WarningMsg | echo 'hashCode not generated' | echohl None
  endif
  call cursor(l:pos[1], l:pos[2])
endfunction "}}}

fun! s:append_hashcode(properties) "{{{
  let l:indent = &et ? '    ' : '	'
  call s:ensure_import('org.apache.commons.lang3.builder.HashCodeBuilder')
  let l:method = [l:indent.'public int hashCode() {', 
        \ repeat(l:indent, 2).'return new HashCodeBuilder(7, 3)']
  for l:prop in a:properties
    let l:str_body = [repeat(l:indent, 4),
          \'.append(', l:prop, ')']
    call add(l:method, join(l:str_body, ''))
  endfor
  call add(l:method, repeat(l:indent, 4) . '.hashCode();')
  call add(l:method, l:indent . '}')
  call add(l:method, '')
  call cursor(line('$'), 1)
  let l:line = s:calculate_hashcode_pos()
  call append(l:line, l:method)
endfunction "}}}


fun! s:handle_props_for_stdmethods(prompt) "{{{
  let l:prop_line_numbers = s:get_property_line_numbers()
  let l:cmdheight = &cmdheight
  let &cmdheight = s:prompt_height
  set cul
  try
    let l:properties = s:prompt_for_generated_method(l:prop_line_numbers
          \, a:prompt)
  finally
    let &cmdheight = l:cmdheight
  endtry
  return l:properties
endfunction "}}}

fun! s:get_property_lines() "{{{
  let l:props = []
  for line in range(1, line('$'))
    if getline(line) =~# s:matching_properties
      call add(l:props, getline(line))
    endif
  endfor
  return l:props
endfunction "}}}

fun! s:get_property_line_numbers() "{{{
  let l:line_numbers = []
  for line in range(1, line('$'))
    if getline(line) =~# s:matching_properties
      call add(l:line_numbers, line)
    endif
  endfor
  return l:line_numbers
endfunction "}}}

let s:matching_properties = '\v^\s+(protected|private)( final)@!( static)@!\s+(.+)\s+[^[:space:]]+;\s*$'
let s:match_highlight_suffix = '\s+(protected|private)( final)@!( static)@!\s+(.+)\s+\zs[^[:space:]]+\ze;\s*$'
let s:method_def_expr =
\ '\v^%(\t|    )%((private |protected |public )%((public|private|protected)@!))?[[:alnum:]]+(\<.+\>)?[[:space:]\n]{1,}[[:alnum:]\$_]+\s{-}\('
let s:method_bodystart_expr = '\v\{'
let s:prompt_height = 4

fun! s:search_equals() "{{{
  return s:search_std_method('\v^\s+public\s+boolean\s+equals')
endfunction "}}}

fun! s:prompt_for_generated_method(lines, prompt) "{{{
  let l:responses = []
  let l:response = ''
  echohl Question
  for ln in a:lines
    call cursor(ln, 1)
    let prop = matchstr(getline(ln), '\v.+\s\zs[^;]+\ze;')
    let l:highlighted = matchadd('Question', join(['\v%', ln, 'l^', s:match_highlight_suffix], ''))
    if l:response != 'a'
      let l:response = s:prompt_while_invalid(a:prompt)
    endif
    call matchdelete(l:highlighted)
    if l:response == 'y' || l:response == 'a'
      call add(l:responses, prop)
    endif
    if l:response == 'q'
      let l:responses = []
      let l:response = 'd'
    endif
    if l:response == 'd'
      break
    endif
  endfor
  echohl None
  return l:responses
endfunction "}}}

fun! s:prompt_while_invalid(promptstr) "{{{
  redraw
  let &cmdheight = s:prompt_height
  echo a:promptstr
  echo "y/n/a/d/q\n"
  let l:response=tolower(nr2char(getchar()))
  let &cmdheight=1
  if l:response !~ "\\v[ynadq\<Esc>]"
    call s:prompt_while_invalid(a:promptstr)
  endif
  return l:response
endfunction "}}}

fun! s:search_hashcode() "{{{
  return s:search_std_method('\v^\s+public\s+int\s+hashCode')
endfunction "}}}

fun! s:append_equals(properties) "{{{
  let l:indent = &et ? '    ' : '	'
  call s:ensure_import('org.apache.commons.lang3.builder.EqualsBuilder')
  let l:method = [l:indent.'public boolean equals(Object o) {',
        \ repeat(l:indent, 2).'if (o == null) { return false; }',
        \ repeat(l:indent, 2).'if (o == this) { return true; }',
        \ repeat(l:indent, 2).'if (this.getClass() != o.getClass()) { return false; }',
        \ repeat(l:indent, 2).s:get_class_name() . ' other = ' .
        \ '(' . s:get_class_name() . ')o;',
        \ repeat(l:indent, 2).'return new EqualsBuilder()']
  for l:prop in a:properties
    let l:str_body = [repeat(l:indent, 4),
          \'.append(this.', l:prop, ', other.' , l:prop, ')']
    call add(l:method, join(l:str_body, ''))
  endfor
  call add(l:method, repeat(l:indent, 4).'.isEquals();')
  call add(l:method, l:indent . '}')
  call add(l:method, '')
  let l:line = s:calculate_equals_pos()
  call append(l:line, l:method)
endfunction "}}}

fun! s:autowrite_type_var() "{{{
  let l:pos = getpos('.')
  let l:col_1 = s:find_first_word_column(l:pos[2]-3)
  let l:col_2 = s:find_last_word_column(l:pos[2]-3)
  let l:candidate = getline(line('.'))[l:col_1 : l:col_2]
  let l:needs_space = l:candidate =~ '\s$' ? 0 : 1
  if l:candidate =~# '^[A-Z]'
    let l:ret_val = (l:needs_space ? ' ' : '') .
          \ substitute(l:candidate, '^\w', '\l&', '')
  else
    let l:ret_val = repeat("\<BS>", len(l:candidate))
    let l:ret_val .= substitute(l:candidate, '^\w', '\u&', '')
    if l:needs_space
      let l:ret_val .= ' '
    endif
    let l:ret_val .= l:candidate
  endif
  return l:ret_val
endfunction "}}}

fun! s:autowrite_new_from_var() "{{{
  let l:pos = getpos('.')
  let l:col_ = s:find_first_word_column(l:pos[2]-3, 0)
  let l:candidate = getline(line('.'))[col_ : l:pos[2]-1]
  if l:candidate =~# '^[a-z]'
    let l:space_or_blank = l:candidate =~ '\s$' ? '' : ' '
    let l:ret_val = l:space_or_blank . "= new "
          \ . substitute(l:candidate, '^\w', '\u&', '')
          \ . "();\<Left>\<Left>"
  else
    let l:ret_val = " \<BS>"
  endif
  return l:ret_val
endfunction "}}}

fun! s:get_class_name() "{{{
  let l:expr = '\v^public class \zs\w+\ze'
  let l:line = search(l:expr, 'bnw')
  if l:line == 0
    throw 'Something is wrong with java file'
  endif
  return matchstr(getline(l:line), l:expr)
endfunction "}}}


fun! s:calculate_hashcode_pos() "{{{
  let l:lines = []
  call add(l:lines, search('\v^}$', 'wcn'))
  call add(l:lines, search('\v^\s+public String toString', 'wcn'))
  return s:find_first_line(l:lines)
endfunction "}}}

fun! s:calculate_equals_pos() "{{{
  let l:lines = []
  call add(l:lines, search('\v^}$', 'wcn'))
  call add(l:lines, search('\v^\s+public String toString', 'wcn'))
  call add(l:lines, search('\v^\s+public int hashCode', 'wcn'))
  return s:find_first_line(l:lines)
endfunction "}}}

fun! s:find_first_line(lines) "{{{
  let l:lines = filter(a:lines, 'v:val > 0')
  let l:lines = sort(l:lines, "NumCompare")
  return l:lines[0] - 1
endfunction "}}}

fun! s:find_last_word_column(column, ...) "{{{
  let l:search_expr = '\v[^[:alnum:]\$_]'
  if len(a:000) > 0 && a:1
    let l:search_expr = '\v[^[:alnum:]\$_.]'
  endif

  let cur_line = getline(line('.'))
  if cur_line[a:column] =~ l:search_expr
        \ || a:column >= len(cur_line)
    return a:column - 1
  endif
  if len(a:000) > 0 && a:1
    return s:find_last_word_column(a:column + 1, a:1)
  endif
  return s:find_last_word_column(a:column + 1)
endfunction "}}}

fun! s:find_first_word_column(column, ...) "{{{
  let l:search_expr = '\v[^[:alnum:]\$_]'
  if len(a:000) > 0 && a:1
    let l:search_expr = '\v[^[:alnum:]\$_.]'
  endif

  let cur_line = getline(line('.'))
  if cur_line[a:column] =~ l:search_expr || a:column < 0
    return a:column + 1
  endif
  if len(a:000) > 0 && a:1
    return s:find_first_word_column(a:column - 1, a:1)
  endif
  return s:find_first_word_column(a:column - 1)
endfunction "}}}

fun! NumCompare(i1, i2)
  return a:i1 - a:i2
endfun

fun! s:setup_javavimmess() "{{{
    inoremap <expr> <C-g><C-e> <SID>autowrite_type_var()
    inoremap <expr> <C-g>e     <SID>autowrite_type_var()
    inoremap <expr> <C-g>E     <SID>autowrite_new_from_var()
    command! -buffer GetSet call s:getters_setters()
    command! -buffer ToString call s:gen_tostring()
    command! -buffer HashCode call s:gen_hashcode()
    command! -buffer Equalsj call s:gen_equals()
    command! SerialVer call s:serial_ver()
    nnoremap <silent><buffer> gS :ToString<cr>
    nnoremap <silent><buffer> gH :HashCode<cr>
    nnoremap <silent><buffer> gQ :Equalsj<cr>
endfunction "}}}

fun! Rg_list_imports() "{{{
  let rg_command = "rg --no-heading --no-line-number --no-filename -o '^import[[:space:]][^;]+' | sort -u"
  let local_imports = systemlist(rg_command)
  return map(local_imports, "Clean_import(v:val)")
endfunction "}}}

fun! Clean_import(import) "{{{
  return substitute(a:import, '\v^import[[:space:]]+|;.*$', '', 'g')
endfunction "}}}

fun! Insert_imports(...) "{{{
  for x in a:000
    call imports#insert_import(x)
  endfor
endfunction "}}}

function! s:insert_imports(...)
  return fzf#run({
        \ 'source': Rg_list_imports(),
        \ 'sink': function('Insert_imports'),
        \ 'options': '--multi --reverse'})
endfunction

nnoremap  :call <SID>insert_imports()<CR>

augroup setupjava
    au!
    au FileType java call s:setup_javavimmess()
augroup END

command! Mkdir call MkDir()
