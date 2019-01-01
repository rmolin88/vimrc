" File:				plugin.vim
" Description:Plugin specific settings
" Author:			Reinaldo Molina <rmolin88@gmail.com>
" Version:			2.0.1
" Last Modified: Thu Feb 22 2018 10:36
" Created: Fri Jun 02 2017 10:44

" List of pip requirements for your plugins:
" - pip3 install --user neovim psutil vim-vint
"   - on arch: python-vint python-neovin python-psutil
"   - However, pip is the preferred method. Not so sure becuase then you have to updated
"   manually.
" - These are mostly for python stuff
" - jedi mistune setproctitle jedi flake8 autopep8

" This function should not abort on error. Let continue configuring stuff
function! plugin#Config()
	if s:plugin_check() != 1
		return -1
	endif

	if !exists('g:vim_plugins_path')
		echoerr 'plugin#Config(): Dont know where to look for plugins!'
		return -1
	endif

	if exists('g:portable_vim') && g:portable_vim == 1
		silent! call plug#begin(g:vim_plugins_path)
	else
		call plug#begin(g:vim_plugins_path)
	endif

	call s:configure_vim_utils()

	" This call must remain atop since sets the g:lightline variable to which other
	" plugins add to
	" selection - {lightline, airline}
	call status_line#config('lightline')

	call s:configure_async_plugins()

	call s:configure_ctrlp()

	" Lightline should be one of the very first ones so that plugins can later on add to
	" it
	if executable('mutt')
		Plug 'guanqun/vim-mutt-aliases-plugin'
	endif

	if executable('gpg')
		" This plugin doesnt work with gvim. Use only from cli
		Plug 'jamessan/vim-gnupg'
		let g:GPGUseAgent = 0
	endif

	" Possible values:
	" - ycm nvim_compl_manager shuogo autocomplpop completor asyncomplete neo_clangd
	" call autocompletion#SetCompl(has('unix') ? 'nvim_compl_manager' : 'shuogo')
	call autocompletion#SetCompl(
				\ has('unix') ? 'shuogo_deo' :
				\ (exists('g:portable_vim') && g:portable_vim == 1 ? 'shuogo_neo' : 'shuogo_deo')
				\ )

	" Possible values:
	" - chromatica easytags neotags color_coded clighter8
	" Wed Jul 04 2018 13:02: No decent code highlighter at the moment 
	call cpp_highlight#Set('')

	" Possible values:
	" - neomake ale
	call linting#Set('neomake')

	" Neovim exclusive plugins
	if has('nvim')
		" Note: Thu Aug 24 2017 21:03 This plugin is actually required for the git
		" plugin to work in neovim
		Plug 'radenling/vim-dispatch-neovim'
		" nvim-qt on unix doesnt populate has('gui_running')
		Plug 'equalsraf/neovim-gui-shim'
		if executable('lldb') && has('unix')
			Plug 'critiqjo/lldb.nvim'
			" All mappings moved to c.vim
			" Note: Remember to always :UpdateRemotePlugins
			"TODO.RM-Sun May 21 2017 01:14: Create a ftplugin/lldb.vim to disable
			"folding
		endif
	endif

	" Possible Replacement `asyncvim`
	Plug 'tpope/vim-dispatch'
		let g:dispatch_no_maps = 1

	call s:configure_vim_table_mode()

	" misc
	if executable('git')
		Plug 'chrisbra/vim-diff-enhanced'
		let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=patience")'
	endif

	" Options: netranger, nerdtree
	call s:configure_file_browser((executable('ranger') ? 'ranger' : 'nerdtree'))

	call s:configure_nerdcommenter()

	Plug 'chrisbra/Colorizer', { 'for' : [ 'css','html','xml' ] }
	let g:colorizer_auto_filetype='css,html,xml'
	Plug 'tpope/vim-repeat'
	Plug 'tpope/vim-surround'

	" Fold stuff
	" Fri May 19 2017 12:50 I have tried many times to get 'fdm=syntax' to work
	" on large files but its just not possible. Too slow.
	Plug 'Konfekt/FastFold', { 'on' : 'FastFold' }
	" Stop updating folds everytime I save a file
	let g:fastfold_savehook = 0
	" To update folds now you have to do it manually pressing 'zuz'
	let g:fastfold_fold_command_suffixes =
				\['x','X','a','A','o','O','c','C','r','R','m','M','i','n','N']

	" Wed Apr 04 2018 12:55: Rooter used to be on demand but I took it.
	" - In order to make use of its FindRootDirectory() function
	Plug 'airblade/vim-rooter'
	" let g:rooter_manual_only = 1
	nnoremap <plug>cd_root :Rooter<CR>
	let g:rooter_use_lcd = 1
	let g:rooter_patterns = ['.git/', '.svn/', 'Source/']
	let g:rooter_silent_chdir = 1
	let g:rooter_resolve_links = 1
	let g:rooter_change_directory_for_non_project_files = 'current'
	" nnoremap <Leader>cr :call utils#RooterAutoloadCscope()<CR>

	Plug 'Raimondi/delimitMate'
	let g:delimitMate_expand_cr = 1
	let g:delimitMate_expand_space = 1
	let g:delimitMate_jump_expansion = 1
	" imap <expr> <CR> <Plug>delimitMateCR

	Plug 'sbdchd/neoformat', { 'on' : 'Neoformat' }
	let g:neoformat_c_clangformat = {
				\ 'exe': 'clang-format',
				\ 'args': ['-style=file'],
				\ }
	let g:neoformat_cpp_clangformat = {
				\ 'exe': 'clang-format',
				\ 'args': ['-style=file'],
				\ }
	nmap <plug>format_code :Neoformat<cr>

	" cpp
	if get(g:, 'tagbar_safe_to_use', 1)
		call s:configure_tagbar()
	endif

	" python
	" Plug 'python-mode/python-mode', { 'for' : 'python' } " Extremely
	" aggressive

	" pip install isort --user
	Plug 'fisadev/vim-isort', { 'for' : 'python' }
	let g:vim_isort_map = ''
	let g:vim_isort_python_version = 'python3'

	" Autocomplete
	" Version control
	Plug 'tpope/vim-fugitive'

	Plug 'mhinz/vim-signify', { 'on' : ['SignifyToggle', 'SignifyDiff'] }
	" Mappings are ]c next differences
	" Mappings are [c prev differences
	" Gets enabled when you call SignifyToggle
	let g:signify_vcs_list = [ 'git', 'svn' ]
	let g:signify_cursorhold_insert     = 1
	let g:signify_cursorhold_normal     = 1
	let g:signify_update_on_bufenter    = 0
	let g:signify_update_on_focusgained = 1
	let g:signify_disable_by_default = 1
	let g:signify_vcs_list = [ 'git', 'svn' ]

	Plug 'juneedahamed/svnj.vim', { 'on' : 'SVNStatus' }
	let g:svnj_allow_leader_mappings=0
	let g:svnj_cache_dir = g:std_cache_path
	let g:svnj_browse_cache_all = 1
	let g:svnj_custom_statusbar_ops_hide = 0
	" colorschemes
	Plug 'morhetz/gruvbox' " colorscheme gruvbox
	Plug 'NLKNguyen/papercolor-theme'

	let g:PaperColor_Theme_Options =
				\ {
				\		'language':
				\		{
				\			'python': { 'highlight_builtins': 1 },
				\			'c': { 'highlight_builtins': 1 },
				\			'cpp': { 'highlight_standard_library': 1 },
				\		},
				\		'theme':
				\		{
				\		 	'default': { 'transparent_background': 0 }
				\		}
				\ }

	" Mon Jan 08 2018 15:08: Do not load these schemes unless they are going to be used
	" Sun May 07 2017 16:25 - Gave it a try and didnt like it
	" Plug 'icymind/NeoSolarized'
	" Sat Oct 14 2017 15:50: Dont like this one either.
	" Plug 'google/vim-colorscheme-primary'
	" Sat Oct 14 2017 15:59: Horrible looking
	" Plug 'joshdick/onedark.vim'
	" Plug 'altercation/vim-colors-solarized'
	" Plug 'jnurmine/Zenburn'

	" Magnum is required by vim-radical. use with gA
	Plug 'glts/vim-magnum', { 'on' : '<Plug>RadicalView' }
	Plug 'glts/vim-radical', { 'on' : '<Plug>RadicalView' }
	nmap <plug>num_representation <Plug>RadicalView
	nmap <plug>num_representation <Plug>RadicalView

	" W3M - to view cpp-reference help
	if executable('w3m')
		" TODO-[RM]-(Thu Sep 14 2017 21:12): No chance to get this working on windows
		Plug 'yuratomo/w3m.vim'
		let g:w3m#history#save_file = g:std_cache_path . '/vim_w3m_hist'
		" Mon Sep 18 2017 22:37: To open html file do `:W3mLocal %'
	endif

	call s:configure_vim_sneak()

	Plug 'waiting-for-dev/vim-www'
	" TODO-[RM]-(Thu Sep 14 2017 21:02): Update this here
	let g:www_map_keys = 0
	let g:www_launch_cli_browser_command = g:browser_cmd . ' {{URL}}'
	nmap <plug>search_internet :Wcsearch duckduckgo <C-R>=expand("<cword>")<CR><CR>
	xmap <plug>search_internet "*y:call www#www#user_input_search(1, @*)<CR>

	if has('win32')
		Plug 'PProvost/vim-ps1', { 'for' : 'ps1' }
	endif

	" Plug 'vim-pandoc/vim-pandoc', { 'on' : 'Pandoc' }
	" " You might be able to get away with xelatex in unix
	" let g:pandoc#command#latex_engine = 'pdflatex'
	" let g:pandoc#folding#fdc=0
	" let g:pandoc#keyboard#use_default_mappings=0
	" Pandoc pdf --template eisvogel --listings
	" PandocTemplate save eisvogel
	" Pandoc #eisvogel

	" Plug 'vim-pandoc/vim-pandoc-syntax'
	" let g:pandoc#syntax#conceal#use = 0
	" " You can find pandoc_lang_name by `pandoc --list-highlight-languages`
	" " pandoc_lang_name = vim_lang_name
	" let g:pandoc#syntax#codeblocks#embeds#langs = [ "latex=tex", 'cpp=cpp' ]
	" augroup pandoc_syntax
		" au! FileType markdown set filetype=markdown.pandoc
	" augroup END
	
	" This plugin depends on 'godlygeek/tabular'
	Plug 'plasticboy/vim-markdown'
	let g:vim_markdown_no_default_key_mappings = 1
	let g:vim_markdown_toc_autofit = 1
	let g:vim_markdown_math = 1
	let g:vim_markdown_folding_level = 1
	let g:vim_markdown_frontmatter = 1
	let g:vim_markdown_new_list_item_indent = 0


	" Plug 'sheerun/vim-polyglot' " A solid language pack for Vim.
	Plug 'matze/vim-ini-fold', { 'for': 'dosini' }

	" Not being used but kept for dependencies
	Plug 'rbgrouleff/bclose.vim'

	call s:configure_tabular()

	" Sun Sep 10 2017 20:44 Depends on plantuml being installed
	" If you want dont want to image preview after loading the plugin put the
	" comment:
	" 'no-preview
	" in your file
	" Sun Nov 11 2018 07:30 Doesn't look well and breaks my author header 
	" Plug 'scrooloose/vim-slumlord', { 'on' : 'UtilsUmlInFilePreview' }

	Plug 'junegunn/goyo.vim', { 'on' : 'Goyo' }
		let g:goyo_width = 120
		nnoremap <plug>focus_toggle :Goyo<cr>

	Plug 'dbmrq/vim-ditto', { 'for' : 'markdown' }
	let g:ditto_dir = g:std_data_path
	let g:ditto_file = 'ditto-ignore.txt'

	" TODO-[RM]-(Sun Sep 10 2017 20:27): Dont really like it
	call s:configure_vim_wordy()

	" TODO-[RM]-(Sun Sep 10 2017 20:26): So far only working on linux
	Plug 'Ron89/thesaurus_query.vim', { 'on' : 'ThesaurusQueryReplaceCurrentWord' }
	" Very weird and confusing
		let g:tq_map_keys = 1

	" Autocorrect mispellings on the fly
	Plug 'panozzaj/vim-autocorrect', { 'for' : 'markdown' }
	" Disble this file by removing its function call from autload/markdown.vim

	" Sun Sep 10 2017 20:44 Depends on languagetool being installed
	if !empty('g:languagetool_jar')
		Plug 'dpelle/vim-LanguageTool', { 'for' : 'markdown' }
	endif

	call s:configure_pomodoro()

	Plug 'chrisbra/csv.vim', { 'for' : 'csv' }
	let g:no_csv_maps = 1
	let g:csv_strict_columns = 1
	" augroup Csv_Arrange
	" autocmd!
	" autocmd BufWritePost *.csv call CsvArrangeColumns()
	" augroup END
	" let g:csv_autocmd_arrange      = 1
	" let g:csv_autocmd_arrange_size = 1024*1024

	" Thu Jan 25 2018 17:36: Not that useful. More useful is mapping N to center the screen as well
	" Plug 'google/vim-searchindex'

	" Documentation plugins
	Plug 'rhysd/devdocs.vim', { 'on' : '<Plug>(devdocs-under-cursor)' }
	" Sample mapping in a ftplugin/*.vim
	nnoremap <plug>help_under_cursor <Plug>(devdocs-under-cursor)

	" Only for arch
	if executable('dasht')
		Plug 'sunaku/vim-dasht', { 'on' : 'Dasht' }
		" When in C++, also search C, Boost, and OpenGL:
		let g:dasht_filetype_docsets['cpp'] = ['^c$', 'boost', 'OpenGL']
	endif

	Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }
	let g:calendar_google_calendar = 1
	let g:calendar_cache_directory = g:std_cache_path . '/calendar.vim/'

	" Tue Oct 31 2017 11:30: Needs to be loaded last
	if exists('g:valid_device')
		Plug 'ryanoasis/vim-devicons'
		let g:WebDevIconsUnicodeDecorateFolderNodes = 1
		let g:DevIconsEnableFoldersOpenClose = 1
	endif

	Plug 'chaoren/vim-wordmotion'
	let g:wordmotion_spaces = '_-.'
	let g:wordmotion_mappings = {
				\ 'w' : '<c-f>',
				\ 'b' : '<c-b>',
				\ 'e' : '',
				\ 'ge' : '',
				\ 'aw' : '',
				\ 'iw' : '',
				\ '<C-R><C-W>' : ''
				\ }

	call s:configure_caps()

	Plug 'hari-rangarajan/CCTree'

	Plug 'bronson/vim-trailing-whitespace', { 'on' : 'UtilsDetectWhitespace' }

	" Mon Jun 25 2018 14:19: Depricating this in favor of custom made 
	" Plug 'mhinz/vim-grepper'
	" if exists('g:lightline')
		" let g:lightline.active.left[2] += [ 'grepper' ]
		" let g:lightline.component_function['grepper'] = 'grepper#statusline'
	" endif

	" Plug 'jalvesaq/Nvim-R'
	" Tue Apr 24 2018 14:40: Too agressive with mappings. Very hard to get it to work.
	" not seeing the huge gains at the moment. Better of just using neoterm at the
	" moment.
	" Installing manually:
	" R CMD build /path/to/Nvim-R/R/nvimcom
	" R CMD INSTALL nvimcom_0.9-39.tar.gz
	" nmap <LocalLeader>r <Plug>RStart
	" imap <LocalLeader>r <Plug>RStart
	" vmap <LocalLeader>r <Plug>RStart

  " Good for folding markdown and others
	Plug 'fourjay/vim-flexagon'

	" Abstract a region to its own buffer for editting. Then save and it will back
	Plug 'chrisbra/NrrwRgn', { 'on' : 'NR' }

	" Tue May 15 2018 17:44: All of these replaced by a single plugin
	" - Not so fast cowboy. This plugin is updated ever so ofen. Plus you dont get
	"   options. Pretty much only the defaults. Its a good source to find syntax plugins
	"   but that's all.
	" Plug 'sheerun/vim-polyglot'
	Plug 'PotatoesMaster/i3-vim-syntax'
	Plug 'elzr/vim-json', { 'for' : 'json' }
	Plug 'aklt/plantuml-syntax', { 'for' : 'plantuml' }

	" Gdb debugging
	if has('unix')
		if has('nvim')
			" Need one for nvim
			" This one below not so good
			" Plug 'huawenyu/neogdb.vim'
		else
			" Vim's built in gdb debugger
			packadd termdebug
			" Another option
			" Plug 'cpiger/NeoDebug'
		endif
	endif

	Plug 'alepez/vim-gtest', { 'for' : ['c', 'cpp'] }


	Plug 'Peaches491/vim-glog-syntax'

	call s:configure_vim_bookmark()

	Plug 'reedes/vim-pencil'
		let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
		let g:pencil#conceallevel = 0
		if exists('g:lightline')
			let g:lightline.active.right[2] += [ 'pencil' ]
			let g:lightline.component_function['pencil'] = 'PencilMode'
		endif

		augroup pencil
			autocmd!
			autocmd FileType markdown,mkd call pencil#init()
			autocmd FileType text         call pencil#init()
		augroup END

	Plug 'tenfyzhong/vim-gencode-cpp'

	call s:configure_vim_startify()

	" This already exists on config files
	" Plug 'vim-scripts/a.vim'

	Plug 'jvenant/vim-java-imports', { 'for' : 'java' }

	call s:configure_vim_which_key()

	" Plug  'tpope/vim-abolish'
	" Want to turn fooBar into foo_bar? Press crs (coerce to snake_case).
	" MixedCase (crm), camelCase (crc), snake_case (crs), UPPER_CASE (cru), dash-case (cr-),
	" dot.case (cr.), space case (cr<space>), and Title Case (crt) are all just 3 keystrokes away.

	" All of your Plugins must be added before the following line
	call plug#end()            " required

	return 1
endfunction

function! s:plugin_check() abort
	if !exists('g:plug_path')
		echoerr 'plugin_check(): Dont know where to download plug.vim to!'
		return -1
	endif

	" If already loaded files cool
	if !empty(glob(g:plug_path))
		return 1
	endif

	let l:link = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	if utils#DownloadFile(g:plug_path, l:link) != 1
		return -1
	endif

	augroup install_plugin
		autocmd!
		autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
	augroup END

	" Source the newly downloaded file
	" execute 'source ' . g:plug_path
	" Return 1 so that Plugs get loaded and install later
	return 1
endfunction

" Called on augroup VimEnter search augroup.vim
function! plugin#AfterConfig() abort
	if exists('g:loaded_deoplete')
		" call deoplete#custom#source('javacomplete2', 'mark', '')
		" call deoplete#custom#source('_', 'matchers', ['matcher_full_fuzzy'])
		" c c++
		call deoplete#custom#source('clang2', 'mark', '')
		call deoplete#custom#source('LanguageClient',
					\ 'min_pattern_length',
					\ 2)
	endif

	" Plugin function names are never detected. Only plugin commands
	if exists('g:loaded_denite')
		" Change mappings.
		call denite#custom#map('insert','<C-j>','<denite:move_to_next_line>','noremap')
		call denite#custom#map('insert','<C-k>','<denite:move_to_previous_line>','noremap')
		call denite#custom#map('insert','<C-v>','<denite:do_action:vsplit>','noremap')
		call denite#custom#map('insert','<C-d>','<denite:scroll_window_downwards>','noremap')
		call denite#custom#map('insert','<C-u>','<denite:scroll_window_upwards>','noremap')
		" Change options
		call denite#custom#option('default', 'winheight', 15)
		call denite#custom#option('_', 'highlight_matched_char', 'Function')
		call denite#custom#option('_', 'highlight_matched_range', 'Function')
		if executable('rg')
			call denite#custom#var('file_rec', 'command',
						\ ['rg', '--glob', '!.{git,svn}', '--files', '--no-ignore',
						\ '--smart-case', '--follow', '--hidden'])
			" Ripgrep command on grep source
			call denite#custom#var('grep', 'command', ['rg'])
			call denite#custom#var('grep', 'default_opts',
						\ ['--vimgrep', '--no-heading', '--smart-case', '--follow', '--hidden',
						\ '--glob', '!.{git,svn}'])
			call denite#custom#var('grep', 'recursive_opts', [])
			call denite#custom#var('grep', 'pattern_opt', ['--regexp'])
			call denite#custom#var('grep', 'separator', ['--'])
			call denite#custom#var('grep', 'final_opts', [])
		elseif executable('ag')
			call denite#custom#var('file_rec', 'command',
						\ ['ag', '--follow', '--nocolor', '--nogroup', '-g', '--hidden', ''])
			call denite#custom#var('grep', 'command', ['ag'])
			call denite#custom#var('grep', 'default_opts',
						\ ['--vimgrep', '--no-heading', '--smart-case', '--follow', '--hidden',
						\ '--glob', '!.{git,svn}'])
			call denite#custom#var('grep', 'recursive_opts', [])
			call denite#custom#var('grep', 'pattern_opt', [])
			call denite#custom#var('grep', 'separator', ['--'])
			call denite#custom#var('grep', 'final_opts', [])
		endif
		" Change ignore_globs
		call denite#custom#filter('matcher_ignore_globs', 'ignore_globs',
					\ [ '.git/', '.svn/', '.ropeproject/', '__pycache__/',
					\   'venv/', 'images/', '*.min.*', 'img/', 'fonts/', 'Obj/', '*.obj'])
	endif

	" Run neomake everytime you save a file
	if exists('g:loaded_neomake')
		call neomake#configure#automake('w')
	endif

	if exists('g:loaded_grepper')
		if executable('rg')
			nmap <plug>search_grep :Grepper -tool rg<cr>
			xmap <plug>search_grep :Grepper -tool rg<cr>
			if has('unix')
				let g:grepper.rg.grepprg .= " --smart-case --follow --fixed-strings --hidden --iglob '!.{git,svn}'"
			else
				let g:grepper.rg.grepprg .= ' --smart-case --follow --fixed-strings --hidden --iglob !.{git,svn}'
			endif
		else
			nmap <plug>search_grep <plug>(GrepperOperator)
			xmap <plug>search_grep <plug>(GrepperOperator)
		endif
		if executable('pdfgrep')
			let g:grepper.tools += ['pdfgrep']
			let g:grepper.pdfgrep = {
						\ 'grepprg':    'pdfgrep --ignore-case --page-number --recursive --context 1',
						\ }
		endif
	endif
endfunction

function! s:configure_ctrlp() abort
	Plug 'ctrlpvim/ctrlp.vim'
	nmap <plug>buffer_browser :CtrlPBuffer<CR>
	nmap <plug>mru_browser :CtrlPMRU<CR>
	let g:ctrlp_map = ''
	let g:ctrlp_cmd = 'CtrlPMRU'
	" submit ? in CtrlP for more mapping help.
	let g:ctrlp_lazy_update = 1
	let g:ctrlp_show_hidden = 1
	let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:10,results:10'
	" It says cache dir but dont want to keep loosing history everytime cache gets cleaned up
	" Fri Jan 05 2018 14:38: Now that denite's file_rec is working much better no need
	" to keep this innacurrate list of files around. Rely on it less.
	" Thu May 03 2018 05:55: Giving ctrlp another chance. There is like a 1 sec delay
	" with Denite file_mru and file/old doesnt really work.
	let g:ctrlp_cache_dir = g:std_data_path . '/ctrlp'
	let g:ctrlp_working_path_mode = 'wra'
	let g:ctrlp_max_history = &history
	let g:ctrlp_clear_cache_on_exit = 0
	let g:ctrlp_switch_buffer = 0
	let g:ctrlp_mruf_max = 10000
	if has('win32')
		let g:ctrlp_mruf_exclude = '^C:\\dev\\tmp\\Temp\\.*'
		set wildignore+=*\\.git\\*,*\\.hg\\*,*\\.svn\\*  " Windows ('noshellslash')
		let g:ctrlp_custom_ignore = {
					\ 'dir':  '\v[\/]\.(git|hg|svn)$',
					\ 'file': '\v\.(tlog|log|db|obj|o|exe|so|dll|dfm)$',
					\ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
					\ }
	else
		let g:ctrlp_mruf_exclude =  '/tmp/.*\|/temp/.*'
		set wildignore+=*/.git/*,*/.hg/*,*/.svn/*        " Linux/MacOSX
		let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
	endif
	let g:ctrlp_prompt_mappings = {
				\ 'PrtBS()': ['<bs>', '<c-h>'],
				\ 'PrtCurLeft()': ['<left>', '<c-^>'],
				\ 'PrtCurRight()': ['<right>'],
				\ }
	" Lightline settings
	if exists('g:lightline')
		let g:lightline.active.left[2] += [ 'ctrlpmark' ]
		let g:lightline.component_function['ctrlpmark'] = string(function('s:ctrlp_lightline_mark'))

		let g:ctrlp_status_func = {
					\ 'main': string(function('s:ctrlp_lightline_func1')),
					\ 'prog': string(function('s:ctrlp_lightline_func2')),
					\ }
	endif
endfunction

function! s:ctrlp_lightline_mark() abort
	if expand('%:t') !~# 'ControlP' || !has_key(g:lightline, 'ctrlp_item')
		return ''
	endif

	call lightline#link('iR'[g:lightline.ctrlp_regex])
	return lightline#concatenate([g:lightline.ctrlp_prev, g:lightline.ctrlp_item
				\ , g:lightline.ctrlp_next], 0)
endfunction

function! s:ctrlp_lightline_func1(focus, byfname, regex, prev, item, next, marked) abort
	let g:lightline.ctrlp_regex = a:regex
	let g:lightline.ctrlp_prev = a:prev
	let g:lightline.ctrlp_item = a:item
	let g:lightline.ctrlp_next = a:next
	return lightline#statusline(0)
endfunction

function! s:ctrlp_lightline_func2(str) abort
	return lightline#statusline(0)
endfunction

function! s:configure_async_plugins() abort
	if !has('nvim') && v:version < 800
		if &verbose > 0
			echomsg 'No async support in this version. No neoterm, no denite.'
		endif
		return -1
	endif

	Plug 'kassio/neoterm'
	let g:neoterm_use_relative_path = 1
	let g:neoterm_default_mod = 'vertical'
	let g:neoterm_autoinsert=1
	nnoremap <Plug>terminal_toggle :Ttoggle<CR>
	" Use gx{text-object} in normal mode
	nmap <plug>terminal_send <Plug>(neoterm-repl-send)
	" Send selected contents in visual mode.
	xmap <plug>terminal_send <Plug>(neoterm-repl-send)
	nmap <plug>terminal_send_line <Plug>(neoterm-repl-send-line)

	Plug 'Shougo/denite.nvim', { 'do' : has('nvim') ? ':UpdateRemotePlugins' : '' }
	nmap <plug>fuzzy_command_history :Denite command_history<CR>
	nmap <plug>fuzzy_vim_help :Denite help<CR>
	" nnoremap <C-S-h> :Denite help<CR>
	" nmap <plug>mru_browser :Denite file_mru<CR>
	" Wed Jan 10 2018 15:46: Have tried several times to use denite buffer but its
	" just too awkard. Kinda slow and doesnt show full path.
	" nnoremap <S-k> :Denite buffer<CR>

	" It includes file_mru source for denite.nvim.
	Plug 'Shougo/neomru.vim'
endfunction

function! s:configure_vim_table_mode() abort
	Plug 'dhruvasagar/vim-table-mode', { 'on' : 'TableModeToggle' }
	" To start using the plugin in the on-the-fly mode use :TableModeToggle
	" mapped to <Leader>tm by default Enter the first line, delimiting columns
	" by the | symbol. In the second line (without leaving Insert mode), enter
	" | twice For Markdown-compatible tables use
	let g:table_mode_corner='|'
	" let g:table_mode_corner = '+'
	let g:table_mode_align_char = ':'
	" TODO.RM-Wed Jul 19 2017 21:10: Fix here these mappings are for terminal
	let g:table_mode_map_prefix = '<Leader>T'
	let g:table_mode_disable_mappings = 1
	nnoremap <Leader>ta :TableModeToggle<CR>
	" <Leader>tr	Realigns table columns
endfunction


function! s:configure_nerdcommenter() abort
	Plug 'scrooloose/nerdcommenter'
	" NerdCommenter
	let g:NERDSpaceDelims=1  " space around comments
	let g:NERDUsePlaceHolders=0 " avoid commenter doing weird stuff
	let g:NERDCommentWholeLinesInVMode=2
	let g:NERDCreateDefaultMappings=0 " Eliminate default mappings
	let g:NERDRemoveAltComs=1 " Remove /* comments
	let g:NERD_c_alt_style=0 " Do not use /* on C nor C++
	let g:NERD_cpp_alt_style=0
	let g:NERDMenuMode=0 " no menu
	let g:NERDCustomDelimiters = {
				\ 'vim': { 'left': '"', 'right': '', 'leftAlt': '#', 'rightAlt': ''},
				\ 'markdown': { 'left': '//', 'right': '' },
				\ 'dosini': { 'left': ';', 'leftAlt': '//', 'right': '', 'rightAlt': '' },
				\ 'csv': { 'left': '#', 'right': '' },
				\ 'plantuml': { 'left': "'", 'right': '', 'leftAlt': "/'", 'rightAlt': "'/"},
				\ 'wings_syntax': { 'left': '//', 'right': '', 'leftAlt': '//', 'rightAlt': '' },
				\ 'sql': { 'left': '--', 'right': '', 'leftAlt': 'REM', 'rightAlt': '' }
				\ }

	let g:NERDTrimTrailingWhitespace = 1
endfunction

function! s:configure_tagbar() abort
	Plug 'majutsushi/tagbar'
	let g:tagbar_ctags_bin = 'ctags'
	let g:tagbar_autofocus = 1
	let g:tagbar_show_linenumbers = 2
	let g:tagbar_map_togglesort = 'r'
	let g:tagbar_map_nexttag = '<c-j>'
	let g:tagbar_map_prevtag = '<c-k>'
	let g:tagbar_map_openallfolds = '<c-n>'
	let g:tagbar_map_closeallfolds = '<c-c>'
	let g:tagbar_map_togglefold = '<c-x>'
	let g:tagbar_autoclose = 1

	" These settings do not use patched fonts
	" Fri Feb 02 2018 15:38: Its number one thing slowing down vim right now.
	if exists('g:lightline')
		let g:lightline.active.right[2] += [ 'tagbar' ]
		let g:lightline.component_function['tagbar'] = string(function('s:tagbar_lightline'))
	endif
endfunction

function! s:tagbar_lightline() abort
	" If file is too big dont try it
	if getfsize(expand('%s')) > 150000
		return ''
	endif

	try
		let ret =  tagbar#currenttag('%s','')
	catch
		return ''
	endtry
	return empty(ret) ? '' :
				\ (exists('g:valid_device') ? "\uf02c" : '')
				\ . ' ' . ret
endfunction

function! s:tagbar_statusline_func(current, sort, fname, ...) abort
	let g:lightline.fname = a:fname
	return lightline#statusline(0)
endfunction

function! s:configure_vim_sneak() abort
	Plug 'justinmk/vim-sneak'
	" replace 'f' with 1-char Sneak
	nmap f <Plug>Sneak_f
	nmap F <Plug>Sneak_F
	xmap f <Plug>Sneak_f
	xmap F <Plug>Sneak_F
	omap f <Plug>Sneak_f
	omap F <Plug>Sneak_F
	" replace 't' with 1-char Sneak
	nmap t <Plug>Sneak_t
	nmap T <Plug>Sneak_T
	xmap t <Plug>Sneak_t
	xmap T <Plug>Sneak_T
	omap t <Plug>Sneak_t
	omap T <Plug>Sneak_T
	xnoremap s s
endfunction

function! s:configure_vim_wordy() abort
	Plug 'reedes/vim-wordy', { 'for' : 'markdown' }
	let g:wordy#ring = [
				\ 'weak',
				\ ['being', 'passive-voice', ],
				\ 'business-jargon',
				\ 'weasel',
				\ 'puffery',
				\ ['problematic', 'redundant', ],
				\ ['colloquial', 'idiomatic', 'similies', ],
				\ 'art-jargon',
				\ ['contractions', 'opinion', 'vague-time', 'said-synonyms', ],
				\ 'adjectives',
				\ 'adverbs',
				\ ]
endfunction

function! s:configure_pomodoro() abort
	Plug 'rmolin88/pomodoro.vim'
	" let g:pomodoro_show_time_remaining = 0
	" let g:pomodoro_time_slack = 1
	" let g:pomodoro_time_work = 1
	let g:pomodoro_use_devicons = exists('g:valid_device') ? 1 : 0
	if executable('twmnc')
		let g:pomodoro_notification_cmd = 'twmnc -t Vim -i nvim -c "Pomodoro done"
					\ && mpg123 ~/.config/dotfiles/notification_sounds/cool_notification1.mp3 2>/dev/null&'
	elseif executable('dunst')
		let g:pomodoro_notification_cmd = "notify-send 'Pomodoro' 'Session ended'
					\ && mpg123 ~/.config/dotfiles/notification_sounds/cool_notification1.mp3 2>/dev/null&"
	elseif executable('powershell')
		let notif = $APPDATA . '/dotfiles/scripts/win_vim_notification.ps1'
		if filereadable(notif)
			let g:pomodoro_notification_cmd = 'powershell ' . notif
		endif
	endif
	let g:pomodoro_log_file = g:std_data_path . '/pomodoro_log'

	if exists('g:lightline')
		let g:lightline.active.left[2] += [ 'pomodoro' ]
		let g:lightline.component_function['pomodoro'] = 'pomo#status_bar'
	endif
endfunction

" choice - One of netranger, nerdtree, or ranger
function! s:configure_file_browser(choice) abort
	" file_browser
	" Wed May 03 2017 11:31: Tried `vifm` doesnt work in windows. Doesnt
	" follow `*.lnk` shortcuts. Not close to being Replacement for `ranger`.
	" Main reason it looks appealing is that it has support for Windows. But its
	" not very good
	" Fri Feb 23 2018 05:16: Also tried netranger. Not that great either. Plus only
	" supports *nix.


	if a:choice ==# 'nerdtree'
		nnoremap <plug>file_browser :NERDTree<CR>

		Plug 'scrooloose/nerdtree', { 'on' : 'NERDTree' }
		Plug 'Xuyuanp/nerdtree-git-plugin', { 'on' : 'NERDTree' }
		" Nerdtree (Dont move. They need to be here)
		let g:NERDTreeShowBookmarks=1  " B key to toggle
		let g:NERDTreeShowLineNumbers=1
		let g:NERDTreeShowHidden=1 " i key to toggle
		let g:NERDTreeQuitOnOpen=1 " AutoClose after openning file
		let g:NERDTreeBookmarksFile= g:std_data_path . '/.NERDTreeBookmarks'
	elseif a:choice ==# 'netranger'
		Plug 'ipod825/vim-netranger'
		let g:NETRRootDir = g:std_data_path . '/netranger/'
		let g:NETRIgnore = [ '.git', '.svn' ]
	elseif a:choice ==# 'ranger'
		nmap <plug>file_browser :RangerCurrentDirectory<CR>
		Plug 'francoiscabrol/ranger.vim', { 'on' : 'RangerCurrentDirectory' }
		let g:ranger_map_keys = 0
	endif
endfunction

" Wed Apr 04 2018 10:51: Neither of them seemed to work. Tags file handling is a
" difficult thing. Specially to support in multi OS environments.
" choice - One of ['gen_tags', 'gutentags']
function! s:configure_tag_handler(choice) abort
	if a:choice ==? 'gen_tags'
		Plug 'jsfaint/gen_tags.vim' " Not being suppoprted anymore
		let g:gen_tags#ctags_auto_gen = 1
		let g:gen_tags#gtags_auto_gen = 1
		let g:gen_tags#use_cache_dir = 1
		let g:gen_tags#ctags_prune = 1
		let g:gen_tags#ctags_opts = '--sort=no --append'
	elseif a:choice ==? 'gutentags'
		Plug 'ludovicchabant/vim-gutentags'
		let g:gutentags_modules = []
		if executable('ctags')
			let g:gutentags_modules += ['ctags']
		endif
		if executable('cscope')
			let g:gutentags_modules += ['cscope']
		endif
		" if executable('gtags')
		" let g:gutentags_modules += ['gtags']
		" endif

		let g:gutentags_project_root = ['.svn']
		let g:gutentags_add_default_project_roots = 1

		let g:gutentags_cache_dir = g:std_data_path . '/ctags'

		" if executable('rg')
		" let g:gutentags_file_list_command = 'rg --files'
		" endif

		" Debugging
		let g:gutentags_trace = 1
		" let g:gutentags_fake = 1
		" let g:gutentags_ctags_extra_args = ['--sort=no', '--append']
		let g:lightline.active.left[2] += [ 'tags' ]
		let g:lightline.component_function['tags'] = 'gutentags#statusline'

		augroup MyGutentagsStatusLineRefresher
			autocmd!
			autocmd User GutentagsUpdating call lightline#update()
			autocmd User GutentagsUpdated call lightline#update()
		augroup END

	endif
endfunction

function! s:configure_tabular() abort
	Plug 'godlygeek/tabular'
	let g:no_default_tabular_maps = 1

	augroup tabularize
		autocmd!
		autocmd FileType * call <SID>tabular_align()
	augroup end

endfunction

function! s:tabular_align() abort
	let comment = &commentstring[0]
	if comment ==# '/'
		let comment = '\/\/'
	endif

	execute 'vnoremap <buffer> <Leader>oa :Tabularize /' . comment . '<cr>'
endfunction

function! s:configure_caps() abort
	" Software caps lock. imap <c-l> ToggleSoftwareCaps
	Plug 'tpope/vim-capslock'


	if exists('g:lightline')
		let g:lightline.active.right[2] += [ 'caps' ]
		let g:lightline.component_function['caps'] = string(function('s:get_caps'))
		let g:lightline.component_type = {
	      \   'caps': 'error',
	      \ }
	endif
endfunction

function! s:get_caps() abort
	if !exists('*CapsLockStatusline')
		return ''
	endif

	return CapsLockStatusline() ==? '[caps]' ? 'CAPS' : ''
endfunction

function! s:configure_vim_utils() abort
	" Tue Dec 25 2018 17:43
	" This has been moved to the auto 'rtp'
	" Plug g:location_vim_utils
	" Load the rest of the stuff and set the settings
	let g:svn_repo_url = 'svn://odroid@copter-server/'
	let g:svn_repo_name = 'UnrealEngineCourse/BattleTanks_2/'
	nnoremap <Leader>vw :call SVNSwitch<CR>
	nnoremap <Leader>vb :call SVNCopy<CR>

	nnoremap <Leader>of :Dox<CR>
	" Other commands
	" command! -nargs=0 DoxLic :call <SID>DoxygenLicenseFunc()
	" command! -nargs=0 DoxAuthor :call <SID>DoxygenAuthorFunc()
	" command! -nargs=1 DoxUndoc :call <SID>DoxygenUndocumentFunc(<q-args>)
	" command! -nargs=0 DoxBlock :call <SID>DoxygenBlockFunc()
	" let g:DoxygenToolkit_paramTag_pre= '@param '
	" let g:DoxygenToolkit_returnTag=	'@returns '
	let g:DoxygenToolkit_blockHeader=''
	let g:DoxygenToolkit_blockFooter=''
	let g:DoxygenToolkit_authorName='Reinaldo Molina'
	" let g:DoxygenToolkit_authorTag =	'@author '
	" let g:DoxygenToolkit_fileTag =		'@file '
	" let g:DoxygenToolkit_briefTag_pre= '@brief '
	" let g:DoxygenToolkit_dateTag = '@date '
	" let g:DoxygenToolkit_versionTag = '@version	'
	let g:DoxygenToolkit_commentType = 'C++'
	let g:DoxygenToolkit_versionString = ' 0.0.0'
	let g:DoxygenToolkit_compactOneLineDoc = "yes"
	let g:DoxygenToolkit_compactDoc = "yes"

	let g:ctags_create_spell=1
	let g:ctags_spell_script= g:std_config_path . '/tagstospl.py'
	let g:ctags_output_dir = g:std_data_path . (has('unix') ? '/ctags/' : '\ctags\')
	" Cscope databases and spell files will only be created for the following filetypes
	let g:ctags_use_spell_for = ['c', 'cpp']
	let g:ctags_use_cscope_for = ['c', 'cpp', 'java']
endfunction

function! s:configure_vim_bookmark() abort
	Plug 'MattesGroeger/vim-bookmarks'
		let g:bookmark_no_default_key_mappings = 1
		" let g:bookmark_sign = '>>'
		" let g:bookmark_annotation_sign = '##'
		let g:bookmark_manage_per_buffer = 0
		let g:bookmark_save_per_working_dir = 0
		let g:bookmark_dir = g:std_data_path . '/bookmarks'
		let g:bookmark_auto_save = 0
		let g:bookmark_auto_save_file = g:bookmark_dir . '/bookmarks'
		let g:bookmark_highlight_lines = 1
		" let g:bookmark_show_warning = 0
		" let g:bookmark_show_toggle_warning = 0

		nnoremap <Plug>BookmarkLoad :call <SID>bookmark_load()<cr>
		nnoremap <Plug>BookmarkSave :call <SID>bookmark_save()<cr>
endfunction

function! s:bookmark_save() abort
	if !exists('*BookmarkSave()')
		echoerr 'Please install the vim-bookmark plugin'
		return
	endif

	let l:folder = utils#GetFullPathAsName(getcwd())

	let l:path = g:bookmark_dir . '/' . l:folder

	if empty(finddir(l:folder, g:bookmark_dir . '/**1'))
		call mkdir(l:path, 'p')
	endif

	let l:cd = getcwd()
	execute 'silent lcd ' . l:path
	let l:msg = 'Enter name for bookmark at "' . l:folder . '": '
	let l:book = input(l:msg, '', 'file')
	execute 'silent lcd ' . l:cd
	if empty(l:book)
		return
	endif

	let l:book = l:path . '/' . l:book

	return BookmarkSave(l:book, 0)
endfunction

function! s:bookmark_load() abort
	if !exists('*BookmarkLoad()')
		echoerr 'Please install the vim-bookmark plugin'
		return
	endif

	let l:folder = utils#GetFullPathAsName(getcwd())

	let l:path = g:bookmark_dir . '/' . l:folder

	if empty(finddir(l:folder, g:bookmark_dir . '/**1'))
		echomsg 'There are no bookmarks for current directory'
		return
	endif

	let l:book = l:path . '/' . utils#DeniteYank(l:path)
	if empty(l:book)
		return
	endif

	if &verbose > 0
		echomsg '[bookmark_load]: l:book = ' . l:book
	endif

	return BookmarkLoad(l:book, 0, 0)
endfunction

function! s:configure_vim_startify() abort
	Plug 'mhinz/vim-startify'

  " Session options
	if exists('g:std_data_path')
		let g:startify_session_dir = g:std_data_path . '/sessions/'
	endif

	let g:startify_lists = [
				\ { 'type': 'sessions',  'header': ['   Sessions']       },
				\ { 'type': 'files',     'header': ['   MRU']            },
				\ ]
	let g:startify_change_to_dir = 0
	let g:startify_session_sort = 1
	let g:startify_session_number = 10
endfunction

" Additional settings at:
" 'options.vim' as well
" s:which_key_format also 
function! s:configure_vim_which_key() abort
	" Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }
	let g:exists_vim_which_key = 1

	Plug 'liuchengxu/vim-which-key'
	nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
	vnoremap <silent> <leader> :WhichKeyVisual '<Space>'<CR>
	nnoremap <silent> <localleader> :WhichKey 'g'<CR>
	vnoremap <silent> <localleader> :WhichKeyVisual 'g'<CR>

	nnoremap <silent> ] :WhichKey ']'<CR>
	vnoremap <silent> ] :WhichKeyVisual ']'<CR>
	nnoremap <silent> [ :WhichKey '['<CR>
	vnoremap <silent> [ :WhichKeyVisual '['<CR>

	let g:which_key_flatten = 0
	let g:which_key_hspace = 80
	let g:WhichKeyFormatFunc = function('s:which_key_format')
endfunction

function! s:which_key_format(mapping) abort
	let l:ret = a:mapping
	let l:ret = substitute(l:ret, '\c<cr>$', '', '')
	let l:ret = substitute(l:ret, '^:', '', '')
	let l:ret = substitute(l:ret, '^\c<c-u>', '', '')
	let l:ret = substitute(l:ret, '^<[Pp]lug>', '', '')
	return l:ret
endfunction