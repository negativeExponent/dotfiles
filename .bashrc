#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1=""
EXIT="$?"
RCol='\[\e[0m\]'
Red='\[\e[0;31m\]'
Gre='\[\e[0;32m\]'
BYel='\[\e[1;33m\]'
BBlu='\[\e[1;34m\]'
Pur='\[\e[0;35m\]'

if [ $EXIT != 0 ]; then
   PS1+=" ${Red}$EXIT"
fi

PS1+="${BBlu}\w \$${RCol} "

# Source configs
for f in ~/.config/shell/*; do source "$f"; done

[[ "$(whoami)" = "root" ]] && return

[[ -z "$FUNCNEST" ]] && export FUNCNEST=100          # limits recursive functions, see 'man bash'

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

eval $(dircolors -b $HOME/.config/dir_colours)

[ ! -f /etc/bash/bashrc.d/bash_completion.sh ] || source /etc/bash/bashrc.d/bash_completion.sh

neofetch --backend 'ascii'
