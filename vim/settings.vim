let g:filesep=!has('win32') ? '/' : '\'
set enc=utf-8
set nocompatible
set hidden
set sts=4 sw=4 ts=4 et
set guioptions=
set bs=2
set listchars =tab:»\ ,eol:¬,trail:·
set vb
set t_vb=

set undofile
let s:path=expand('<sfile>:p:h')
execute "set undodir=" . s:path . "/undo"
set noswf
set laststatus=2
set history=500
set completeopt=longest,menuone
set ignorecase smartcase
set timeoutlen=500
set cul
set list

set wildignore+=*\\target\\*,*.exe,*.class,*/target/*
colo vimbrant

augroup jsetting
  au!
  au FileType java inoremap <buffer> ,. <C-o>:s/\v;?\s*$/;/<CR><End>
augroup END


augroup html
  au!
  autocmd FileType html set ft=htmldjango
augroup END


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Abbreviations                                                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
iabbrev atov @Override
iabbrev atb @Bean


set pastetoggle=<F8>

let g:my_settings = 1

let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let g:deoplete#enable_at_startup = 1

" vim lsp
if executable('java') && filereadable(expand('~/java/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.600.v20191014-2022.jar'))
    au User lsp_setup call lsp#register_server({
        \ 'name': 'eclipse.jdt.ls',
        \ 'cmd': {server_info->[
        \     'java',
        \     '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        \     '-Dosgi.bundles.defaultStartLevel=4',
        \     '-Declipse.product=org.eclipse.jdt.ls.core.product',
        \     '-Dlog.level=ALL',
        \     '-noverify',
        \     '-Dfile.encoding=UTF-8',
        \     '-Xmx1G',
        \     '-jar',
        \     expand('~/java/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.600.v20191014-2022.jar'),
        \     '-configuration',
        \     expand('~/java/eclipse.jdt.ls/config_linux'),
        \     '-data',
        \     getcwd()
        \ ]},
        \ 'whitelist': ['java'],
        \ })
endif

let g:LanguageClient_serverCommands = {
      \ 'java': ['java',
      \     '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      \     '-Dosgi.bundles.defaultStartLevel=4',
      \     '-Declipse.product=org.eclipse.jdt.ls.core.product',
      \     '-Dlog.level=ALL',
      \     '-noverify',
      \     '-Dfile.encoding=UTF-8',
      \     '-Xmx1G',
      \     '-jar',
      \     expand('~/java/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.600.v20191014-2022.jar'),
      \     '-configuration',
      \     expand('~/java/eclipse.jdt.ls/config_linux'),
      \     '-data',
      \     getcwd()],
      \ }

" call deoplete#custom#option({
" \ 'auto_complete_delay': 100,
" \ 'smart_case': v:true,
" \ })

" vim: ts=2 sw=2 sts=2 et:
