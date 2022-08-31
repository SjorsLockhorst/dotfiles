[1mdiff --git a/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl b/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl[m
[1mindex 73ce81c..a0db462 100644[m
[1m--- a/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl[m
[1m+++ b/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl[m
[36m@@ -11,6 +11,7 @@[m
 	"python3-pip"[m
 	"tmux"[m
 	"silversearcher-ag"[m
[32m+[m	[32m"jq"[m
 -}}[m
 [m
 #!/bin/sh[m
[1mdiff --git a/dot_vim/ftplugin/javascript.vim b/dot_vim/ftplugin/javascript.vim[m
[1mindex 09949bf..e69de29 100644[m
[1m--- a/dot_vim/ftplugin/javascript.vim[m
[1m+++ b/dot_vim/ftplugin/javascript.vim[m
[36m@@ -1 +0,0 @@[m
[31m-let g:ale_fixers = {'javascript': ['prettier']}[m
[1mdiff --git a/dot_vim/ftplugin/python.vim b/dot_vim/ftplugin/python.vim[m
[1mindex 18f6155..b152af3 100644[m
[1m--- a/dot_vim/ftplugin/python.vim[m
[1m+++ b/dot_vim/ftplugin/python.vim[m
[36m@@ -5,6 +5,3 @@[m [mset expandtab[m
 set shiftwidth=4[m
 [m
 set colorcolumn=88[m
[31m-[m
[31m-let b:ale_linters = ["pylint", "flake8"][m
[31m-let b:ale_fixers = ["black"][m
[1mdiff --git a/dot_vim/ftplugin/vue.vim b/dot_vim/ftplugin/vue.vim[m
[1mindex 82f75f8..e69de29 100644[m
[1m--- a/dot_vim/ftplugin/vue.vim[m
[1m+++ b/dot_vim/ftplugin/vue.vim[m
[36m@@ -1 +0,0 @@[m
[31m-let g:ale_fixers = {'vue': ['prettier']}[m
[1mdiff --git a/dot_vimrc.tmpl b/dot_vimrc.tmpl[m
[1mindex 3471b1a..e348cd5 100644[m
[1m--- a/dot_vimrc.tmpl[m
[1m+++ b/dot_vimrc.tmpl[m
[36m@@ -134,7 +134,6 @@[m [maugroup numbertoggle[m
 :augroup END[m
 [m
 [m
[31m-" TODO: Move this to fpplugins[m
 " Set proper tabs and spaces per filetype[m
 autocmd Filetype html setlocal ts=2 sw=2 expandtab[m
 autocmd Filetype json setlocal ts=2 sw=2 expandtab[m
[36m@@ -187,6 +186,14 @@[m [mlet g:ale_sign_column_always = 1[m
 let g:airline#extensions#ale#enabled = 1[m
 nmap <F10> :ALEFix<cr>[m
 let g:ale_fix_on_save = 1[m
[32m+[m[32mlet g:ale_fixers = {[m
[32m+[m[32m      \'vue': ['prettier'],[m
[32m+[m[32m      \'javascript': ['prettier'],[m
[32m+[m[32m      \'python': ["black"],[m
[32m+[m[32m      \}[m
[32m+[m[32mlet b:ale_linters = {[m
[32m+[m[32m      \"python": ["pylint", "flake8"],[m
[32m+[m[32m      \}[m
 [m
 " --------------------------------[m
 " | HTML auto close tag settings |[m
[1mdiff --git a/dot_zshrc.tmpl b/dot_zshrc.tmpl[m
[1mindex 8661bbc..5ad84b3 100644[m
[1m--- a/dot_zshrc.tmpl[m
[1m+++ b/dot_zshrc.tmpl[m
[36m@@ -70,7 +70,10 @@[m [mZSH_THEME="robbyrussell"[m
 # Custom plugins may be added to $ZSH_CUSTOM/plugins/[m
 # Example format: plugins=(rails git textmate ruby lighthouse)[m
 # Add wisely, as too many plugins slow down shell startup.[m
[31m-plugins=(git)[m
[32m+[m[32mplugins=([m
[32m+[m	[32mgit[m
[32m+[m	[32mpython[m
[32m+[m[32m)[m
 [m
 source $ZSH/oh-my-zsh.sh[m
 [m
