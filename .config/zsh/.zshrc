# Enable colors and change prompt
autoload -U colors && colors

# Allow for functions in the prompt.
setopt PROMPT_SUBST

if [ ! -d "$ZPLUG_HOME" ]; then
 git clone https://github.com/zplug/zplug "$ZPLUG_HOME"
fi
source "$ZPLUG_HOME/init.zsh"

# zplug
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

zplug "zsh-users/zsh-completions"
# zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# zplug "dracula/zsh", as:theme # requires OH-MY-ZSH
zplug "denysdovhan/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

# History
# HISTFILE="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Load aliases
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"

# Install plugins if there are plugins that have not been installed
if ! zplug check; then
    printf "Install plugins? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load

# history
if zplug check "zsh-users/zsh-history-substring-search"; then
	zmodload zsh/terminfo
	bindkey "$terminfo[kcuu1]" history-substring-search-up
	bindkey "$terminfo[kcud1]" history-substring-search-down
	bindkey "^[[1;5A" history-substring-search-up
	bindkey "^[[1;5B" history-substring-search-down
fi

# highlighting
if zplug check "zsh-users/zsh-syntax-highlighting"; then
	#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
	ZSH_HIGHLIGHT_PATTERNS=('rm -rf *' 'fg=white,bold,bg=red')

	typeset -A ZSH_HIGHLIGHT_STYLES
	ZSH_HIGHLIGHT_STYLES[cursor]='bg=yellow'
	ZSH_HIGHLIGHT_STYLES[globbing]='none'
	ZSH_HIGHLIGHT_STYLES[path]='fg=white'
	ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=grey'
	ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
	ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan'
	ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
	ZSH_HIGHLIGHT_STYLES[command]='fg=green'
	ZSH_HIGHLIGHT_STYLES[precommand]='fg=green'
	ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=green'
	ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=yellow'
	ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta'
	ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=cyan,bold'
	ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
	ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta,bold'
	ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=yellow,bold'
fi

if zplug check "denysdovhan/spaceship-prompt"; then
	SPACESHIP_PROMPT_ADD_NEWLINE=false
	SPACESHIP_PROMPT_SEPARATE_LINE=false
	SPACESHIP_CHAR_SYMBOL=❯
	SPACESHIP_CHAR_SUFFIX=" "
	SPACESHIP_HG_SHOW=false
	SPACESHIP_PACKAGE_SHOW=false
	SPACESHIP_NODE_SHOW=false
	SPACESHIP_RUBY_SHOW=false
	SPACESHIP_ELM_SHOW=false
	SPACESHIP_ELIXIR_SHOW=false
	SPACESHIP_XCODE_SHOW_LOCAL=false
	SPACESHIP_SWIFT_SHOW_LOCAL=false
	SPACESHIP_GOLANG_SHOW=false
	SPACESHIP_PHP_SHOW=false
	SPACESHIP_RUST_SHOW=false
	SPACESHIP_JULIA_SHOW=false
	SPACESHIP_DOCKER_SHOW=false
	SPACESHIP_DOCKER_CONTEXT_SHOW=false
	SPACESHIP_AWS_SHOW=false
	SPACESHIP_CONDA_SHOW=false
	SPACESHIP_VENV_SHOW=false
	SPACESHIP_PYENV_SHOW=false
	SPACESHIP_DOTNET_SHOW=false
	SPACESHIP_EMBER_SHOW=false
	SPACESHIP_KUBECONTEXT_SHOW=false
	SPACESHIP_TERRAFORM_SHOW=false
	SPACESHIP_TERRAFORM_SHOW=false
	SPACESHIP_VI_MODE_SHOW=false
	SPACESHIP_JOBS_SHOW=false
fi

setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.

neofetch

