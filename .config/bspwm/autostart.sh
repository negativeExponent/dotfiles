#!/bin/sh

run() {
    if command -v $1 >/dev/null; then
	    if ! pgrep -x $1 >/dev/null; then
		    $@&
	    fi
    fi
}

# general system settings
xsetroot -cursor_name left_ptr &
# xset s noblank &
# xset s noexpose &
# xset -dpms &
# turn keyclick off
# xset c off &
# turn bell off
# xset b off &
run "xfce4-power-manager"

numlockx &

# daemons
run /usr/libexec/polkit-gnome-authentication-agent-1
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &
run "mpd"								# music player widget
#run "udiskie" 							# automount removable storage,replaced with gvfs for usb and android automounting
run "picom" " -b --experimental-backend" 	# compositor
run "dunst" 							# notification daemon
run "sxhkd" 							# X hotkey daemon
run "connman-gtk" "--tray" # network manager gtk ui
run "volumeicon"
run "nm-applet"
run "blueman-applet"

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
