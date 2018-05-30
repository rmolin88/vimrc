" File:					c.vim
" Description:	After default ftplugin for c
" Author:				Reinaldo Molina <rmolin88@gmail.com>
" Version:			1.0.0
" Last Modified: Sat Jun 03 2017 19:02
" Created:			Nov 25 2016 23:16

" Only do this when not done yet for this buffer
if exists('b:did_cpp_ftplugin')
	finish
endif

" Don't load another plugin for this buffer
let b:did_cpp_ftplugin = 1

let b:match_words .= '\<if\>:\<else\>,'
			\ . '\<while\>:\<continue\>:\<break\>,'
			\ . '\<for\>:\<continue\>:\<break\>,'
			\ . '\<try\>:\<catch\>'
if exists('g:omnifunc_clang')
	let &l:omnifunc=g:omnifunc_clang
endif
setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal foldenable
setlocal foldnestmax=88
setlocal define=^\\(#\\s*define\\|[a-z]*\\s*const\\s*[a-z]*\\)
setlocal nospell
" setlocal cursorline
" So that you can jump from = to ; and viceversa
setlocal matchpairs+==:;
" This is that delimate doesnt aut fill the newly added matchpairs
let b:delimitMate_matchpairs = '(:),[:],{:}'

" Add mappings, unless the user didn't want this.
if !exists('no_plugin_maps') && !exists('no_c_maps')
	" Quote text by inserting "> "
	if exists(':Neomake')
		nmap <silent> <buffer> <plug>make_check :Neomake clangtidy clangcheck cppcheck<cr>
	else
		nmap <buffer> <Plug>make_project :make!<cr>
		nmap <buffer> <Plug>make_file :make!<cr>
	endif
	" Alternate between header and source file
	nmap <buffer> <unique> <plug>switch_header_source :call utils#SwitchHeaderSource()<cr>

	if executable('lldb') && exists(':LLmode')
		" TODO-[RM]-(Wed May 23 2018 11:06): Make all of these guys <FX> mappings
		" nmap <buffer> <unique> <LocalLeader>db <Plug>LLBreakSwitch
		" vmap <F2> <Plug>LLStdInSelected
		" nnoremap <F4> :LLstdin<cr>
		" nnoremap <F5> :LLmode debug<cr>
		" nnoremap <S-F5> :LLmode code<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dc :LL continue<cr>
		" nnoremap <buffer> <unique> <LocalLeader>do :LL thread step-over<cr>
		" nnoremap <buffer> <unique> <LocalLeader>di :LL thread step-in<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dt :LL thread step-out<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dD :LLmode code<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dd :LLmode debug<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dp :LL print <C-R>=expand('<cword>')<cr>
		" nnoremap <S-F8> :LL process interrupt<cr>
		" nnoremap <F9> :LL print <C-R>=expand('<cword>')<cr>
		" vnoremap <F9> :<C-U>LL print <C-R>=lldb#util#get_selection()<cr><cr>
	endif

	if exists('g:clang_format_py')
		nmap <buffer> <plug>format_code :execute('pyf ' . g:clang_format_py)<cr>
	endif
endif

function! s:set_compiler_and_others() abort
	if exists('b:current_compiler')
		return
	endif

	if has('unix')
		setlocal foldmethod=syntax

		if exists('g:LanguageClient_serverCommands')
			setlocal completefunc=LanguageClient#complete
			setlocal formatexpr=LanguageClient_textDocument_rangeFormatting()

			" TODO-[RM]-(Sat Jan 27 2018 11:23): Figure out these mappings
			" nnoremap <buffer> <silent> gh :call LanguageClient_textDocument_hover()<CR>
			" nnoremap <buffer> <silent> gd :call LanguageClient_textDocument_definition()<CR>
			" nnoremap <buffer> <silent> gr :call LanguageClient_textDocument_references()<CR>
			" nnoremap <buffer> <silent> gs :call LanguageClient_textDocument_documentSymbol()<CR>
			nmap <buffer> <silent> <plug>refactor_code :call LanguageClient_textDocument_rename()<CR>
			xmap <buffer> <silent> <plug>refactor_code :call LanguageClient_textDocument_rename()<CR>
		endif
		return 1
	endif

	" Commands for windows
	command! -buffer UtilsCompilerGcc execute("compiler gcc<bar>:setlocal makeprg=mingw32-make")
	command! -buffer UtilsCompilerBorland call linting#SetNeomakeBorlandMaker()
	command! -buffer UtilsCompilerMsbuild call linting#SetNeomakeMsBuildMaker()
	command! -buffer UtilsCompilerClangNeomake call linting#SetNeomakeClangMaker()

	if exists(':Dispatch')
		" Time runtime of a specific program. Pass as Argument executable with arguments. Pass as Argument executable with
		" arguments. Example sep_calc.exe seprc.
		command! -nargs=+ -buffer UtilsTimeExec execute('Dispatch powershell -command "& {&'Measure-Command' {.\<f-args>}}"<cr>')
	endif

	" Set compiler now depending on folder and system. Auto set the compiler
	let folder_name = expand('%:p:h')

	if folder_name =~? 'onewings'
		" Load cscope database
		" Note: inside the '' is a pat which is a regex. That is why \\
		if folder_name =~? 'Onewings\\Source'
			call linting#SetNeomakeBorlandMaker()
			return
		endif
		call linting#SetNeomakeMsBuildMaker()
	endif
endfunction

" Setup Compiler and some specific stuff
call <SID>set_compiler_and_others()

" Setup AutoHighlight
call utils#AutoHighlight()

let b:undo_ftplugin = 'setl cursorline< omnifunc< ts< sw< sts< foldenable< define< spell< matchpairs< foldmethod< foldnestmax<| unlet! b:delimitMate_matchpairs b:match_words'
