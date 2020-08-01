#!/bin/bash

# Application Defaults
export BROWSER="firefox"
export TERMINAL="kitty"
export EDITOR="vim"
export VISUAL="vim"
export FILEMANAGER="pcmanfm"

# ~/ Clean-up:
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export ZPLUG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zplug"

#export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority" # This line will break some DMs.
#export NOTMUCH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/notmuch-config"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc-2.0"
#export LESSHISTFILE="-"
#export WGETRC="${XDG_CONFIG_HOME:-$HOME/.config}/wget/wgetrc"
#export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/inputrc"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
#export GNUPGHOME="$XDG_DATA_HOME/gnupg"
#export WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/default"
#export KODI_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/kodi"
#export PASSWORD_STORE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/password-store"
#export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
#export ANDROID_SDK_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/android"
#export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
#export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
#export ANSIBLE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ansible/ansible.cfg"
#export UNISON="${XDG_DATA_HOME:-$HOME/.local/share}/unison"
#export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/history"

#export EDITOR="vim"
#export FMANAGER="ranger"
#export READER="zathura"

#export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
#export ZDOTDIR="$HOME/.config/zsh"
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share/zsh}/history"
#export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
#export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
#export XAUTHORITY="$HOME/.config/X11/xauthority"
#export GNUPGHOME="$XDG_DATA_HOME"/gnupg

export SUDO_ASKPASS="$HOME/.local/bin/dmenupass"
export QT_QPA_PLATFORMTHEME="gtk2"	# Have QT use gtk2 theme.

export PATH=/usr/lib/ccache/bin:$PATH:$HOME/.local/bin:$PATH:$HOME/.local/bin/transmission

# Make sure everything is set to exectuable
chmod +x ~/.local/bin/*
chmod +x ~/.local/bin/*/*
