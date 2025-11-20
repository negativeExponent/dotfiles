# FAST, CLEAN, SELF-CONTAINED .zshrc (no plugin manager)
# Automatically clones plugins if missing, then sources them

### COLORS / PROMPT
[ -z $LS_COLORS ] && eval $(dircolors -b)
#autoload -U colors && colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# simple, readable, colored prompt
autoload -U colors && colors
PS1="%B%F{red}[%F{yellow}%n%F{green}@%F{blue}%m %F{magenta}%~%F{red}]%f%b$ "


### HISTORY
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups hist_reduce_blanks inc_append_history share_history

### BASIC OPTIONS
setopt auto_cd auto_list auto_menu always_to_end
bindkey -e

### ALIASES
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"

### ZSH PLUGIN DIR
PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

### FUNCTION: INSTALL GIT PLUGIN IF MISSING
install_plugin() {
  local dir="$1"
  local repo="$2"
  if [ ! -d "$dir" ]; then
    git clone --depth 1 "$repo" "$dir" >/dev/null 2>&1
  fi
}

### FAST-SYNTAX-HIGHLIGHTING
FSH_DIR="$PLUGIN_DIR/fast-syntax-highlighting"
install_plugin "$FSH_DIR" https://github.com/zdharma-continuum/fast-syntax-highlighting.git
source "$FSH_DIR/fast-syntax-highlighting.plugin.zsh"

### AUTOSUGGESTIONS
ASUG_DIR="$PLUGIN_DIR/zsh-autosuggestions"
install_plugin "$ASUG_DIR" https://github.com/zsh-users/zsh-autosuggestions.git
source "$ASUG_DIR/zsh-autosuggestions.zsh"

### EXTRA COMPLETIONS (OPTIONAL)
ZCOMP_DIR="$PLUGIN_DIR/zsh-completions"
install_plugin "$ZCOMP_DIR" https://github.com/zsh-users/zsh-completions.git
fpath=($ZCOMP_DIR $fpath)

### COMPINIT WITH CACHE
autoload -Uz compinit
compinit -C

### COMPLETION STYLES
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' rehash true
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

### KEYBOARD (load cached zkbd if exists)
test -f "$HOME/.zkbd/$TERM" && source "$HOME/.zkbd/$TERM"
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

### MANPAGE COLORS
export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2)
export LESS_TERMCAP_us=$(tput bold; tput setaf 2)
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)

# reverse dir color
LS_COLORS="$LS_COLORS:ow=7;34"

### OPTIONAL: ARCH COMMAND-NOT-FOUND
[ -f /usr/share/doc/pkgfile/command-not-found.zsh ] && \
  source /usr/share/doc/pkgfile/command-not-found.zsh

### OPTIONAL: STARSHIP
[ -x /usr/bin/starship ] && eval "$(starship init zsh)"
