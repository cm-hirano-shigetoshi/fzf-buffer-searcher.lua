scriptencoding utf-8
if exists('g:load_FzfBufferSearcher')
 finish
endif
let g:load_FzfBufferSearcher = 1

let s:save_cpo = &cpo
set cpo&vim

nnoremap <silent> <Plug>fzf-buffer-searcher :lua require('FzfBufferSearcher').run()<cr>

let &cpo = s:save_cpo
unlet s:save_cpo
