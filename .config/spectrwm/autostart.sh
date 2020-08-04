#!/bin/bash

# general system settings
xsetroot -cursor_name left_ptr &
xset s noblank &
xset s noexpose &
xset -dpms &
# turn keyclick off
xset c off &
# turn bell off
xset b off &

# daemons
/usr/libexec/polkit-gnome-authentication-agent-1 &
eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &
mpd &								# music player widget
#run "udiskie" 							# automount removable storage,replaced with gvfs for usb and android automounting
#picom -b --experimental-backend 	# compositor
xcompmgr &
dunst & 							# notification daemon

# reload Xresources
xrdb -merge "$HOME/.Xresources" &

# restore background
. "$HOME/.fehbg" &

# load monitor profile
. "$HOME/.local/bin/load_icm_profile" &

if command -v transmission-daemon >/dev/null; then
	if ! pgrep -x transmission-da >/dev/null; then
		transmission-daemon &
	fi
fi
