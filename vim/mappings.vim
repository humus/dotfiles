nnoremap ygl :<C-u><C-r>=getline('.')<cr><cr>
nnoremap <Space> :
nnoremap ,. <C-^>
nnoremap gs :w<cr>

noremap! <C-j><C-j> ^
noremap! ,g <
noremap! ,f >
noremap! ,s *
noremap! ,e =
noremap! ,a ''<left>
noremap! ,q ""<left>
noremap! ,b \
noremap! ,x {}<left>
noremap! ,c ()<left>
noremap! ,r []<left>
noremap! ,1 /
noremap! ,Q @
noremap! jk <Esc>
noremap! kj <Esc>
noremap! gf <Right>
noremap! fg <Left>
noremap! %% <C-r>=expand('%:h') . g:filesep<cr>
noremap! jj <Esc>
nnoremap <C-c> <Esc>
inoremap gc <Esc>
inoremap <C-f> <Right>
noremap! <C-b> <Left>
noremap! <C-g><C-g> <Esc>

inoremap {{ {}<C-o>O

nnoremap <C-p> :GitFiles<cr>
nnoremap <C-n> :Buffers<cr>
nnoremap <C-g><C-e> :History:<cr>
nnoremap <F3> :History<cr>

let mapleader=','

augroup diffmapping
  au!
  au FilterWritePre * if &diff | nnoremap }c ]c| endif
  au FilterWritePre * if &diff | nnoremap {c [c| endif
augroup END



" vim: sw=2 ts=2 sts=2 et

