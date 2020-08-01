#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Bash colors
NORMAL=$(echo -e "\001\033[00m\002")
GREEN=$(echo -e "\001\033[00;32m\002")
RED=$(echo -e "\001\033[00;31m\002")
BLUE=$(echo -e "\001\033[00;94m\002")
YELLOW=$(echo -e "\001\033[00;33m\002")
MAGENTA=$(echo -e "\001\033[00;35m\002")
CYAN=$(echo -e "\001\033[00;36m\002")

# Customize terminal prompt
#PS1="${MAGENTA}\w ${GREEN}-> ${NORMAL}"

#_set_my_PS1() {
#    PS1='[\u@\h \W]\$ '
#    PS1="\[\033[01;32m\]\u\[\033[00m\]: \[\033[01;34m\]\w \$\[\033[00m\] "
#    if [ "$(whoami)" = "liveuser" ] ; then
#        local iso_version="$(grep ^VERSION= /etc/os-release | cut -d '=' -f 2)"
#        if [ -n "$iso_version" ] ; then
#            local prefix="eos-"
#            local iso_info="$prefix$iso_version"
#            PS1="[\u@$iso_info \W]\$ "
#        fi
#    fi
#}
#_set_my_PS1
#unset -f _set_my_PS1

function __prompt_command() {
    PS1=""
    local EXIT="$?"
    local RCol='\[\e[0m\]'
    local Red='\[\e[0;31m\]'
    local Gre='\[\e[0;32m\]'
    local BYel='\[\e[1;33m\]'
    local BBlu='\[\e[1;34m\]'
    local Pur='\[\e[0;35m\]'

    if [ $EXIT != 0 ]; then
        PS1+=" ${Red}$EXIT"
    fi

    PS1+=" ${BBlu}\u${RCol}  \W  "
}

export PROMPT_COMMAND=__prompt_command

alias ls='ls --color=auto'
alias ll='ls -lav --ignore=..'   # show long listing of all except ".."
alias l='ls -lav --ignore=.?*'   # show long listing but no hidden dotfiles except "."

[[ "$(whoami)" = "root" ]] && return

[[ -z "$FUNCNEST" ]] && export FUNCNEST=100          # limits recursive functions, see 'man bash'

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

eval $(dircolors -b $HOME/.config/dir_colours)

[ ! -f /etc/bash/bashrc.d/bash_completion.sh ] || source /etc/bash/bashrc.d/bash_completion.sh

term_emulator=$(ps -h -o comm -p $PPID)
if [[ $term_emulator == *"kitty"* ]]; then
	neofetch --backend 'kitty'
else
	neofetch --backend 'ascii'
fi
