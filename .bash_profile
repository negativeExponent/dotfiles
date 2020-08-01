#!/bin/bash

# source .bashrc
[ -f ~/.bashrc ] && source ~/.bashrc

# source .profile
[ -f ~/.profile ] && source ~/.profile

# Start graphical server on tty1 if not already running.
[ "$(tty)" = "/dev/tty1" ] && ! pidof Xorg >/dev/null 2>&1  && exec startx
