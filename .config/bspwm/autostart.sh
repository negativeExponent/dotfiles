#!/bin/sh

_r() {
    if command -v $1 >/dev/null; then
	    if ! pgrep -x $1 >/dev/null; then
		    $@&
	    fi
    fi
}

# kill sxhkd first
pkill -USR1 -x sxhkd

# general system settings
xsetroot -cursor_name left_ptr &
_r "xfce4-power-manager"
numlockx &

# daemons
_r /usr/libexec/polkit-gnome-authentication-agent-1
_r /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &
_r "mpd"								# music player widget
# _r "udiskie" 							# automount removable storage,replaced with gvfs for usb and android automounting
# _r "picom" " -b --experimental-backend" 	# compositor
_r "dunst" 							# notification daemon
_r "sxhkd" 							# X hotkey daemon
_r "connman-gtk" "--tray" # network manager gtk ui

# _r "volumeicon"
# _r "nm-applet"
# _r "blueman-applet"

# reload Xresources
xrdb -merge "$HOME/.Xresources" &

# restore background
sh "$HOME/.fehbg" &

# load monitor profile
# . "$HOME/.local/bin/load_icm_profile" &

# kill and relaunch panel
. "$HOME/.local/bin/launch_polybar.sh" &

if command -v transmission-daemon >/dev/null; then
	if ! pgrep -x transmission-da >/dev/null; then
		transmission-daemon &
	fi
fi
