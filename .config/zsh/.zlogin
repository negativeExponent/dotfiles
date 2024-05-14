#if [ -f "$HOME/.xinitrc" ]; then
#	[ "$(tty)" = "/dev/tty1" ] && ! pidof Xorg >/dev/null 2>&1  && exec startx
#fi
