#!/bin/bash

LOC=$LOCATION_RS
CTEMP=5500:4500
AUTOLOCK_TIMEOUT=10 # timeout in minutes
LOCKSCREEN_CMD="betterlockscreen -l"

run() {
    if command -v $1 >/dev/null; then
	    if ! pgrep -x $1 >/dev/null; then
			echo "$@"
		    $@&
	    fi
    fi
}

# load Xresources
if [ -f "$HOME/.Xresources" ]; then
	xrdb -merge "$HOME/.Xresources"
else
	xrdb -merge "${XDG_CONFIG_HOME:-$HOME/.config}/shell/xresources"
fi

xset s off
xset -dpms

nitrogen --restore &
xsetroot -cursor_name left_ptr &
numlockx &
unclutter &
autotiling &

/usr/libexec/polkit-gnome-authentication-agent-1 &
/usr/lib/xfce-polkit/xfce-polkit &
eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &

run "mpd"
run "xfsettingsd"
run "xfce4-power-manager"
run "ksuperkey" " -e Super_L=Alt_L|F1"
run "ksuperkey" " -e Super_R=Alt_L|F1"
run "udiskie -a -n -s"

if command -v transmission-daemon >/dev/null; then
	if ! pgrep -x transmission-da >/dev/null; then
		transmission-daemon &
	fi
fi

# Ensure that xrdb has finished running before moving on to start the WM/DE.
[ -n "$xrdbpid" ] && wait "$xrdbpid"

. "$HOME/.local/bin/setcolors" &			# exports color configs to rofi, kitty ...
. "$HOME/.local/bin/launch_picom" &         # kills and relaunch compositor
. "$HOME/.local/bin/launch_polybar" "i3-bar" &       # kills and relaunch panel
. "$HOME/.local/bin/launch_dunst" &         # kills and relaunch notification daemon
# . "$HOME/.local/bin/autolock" 5 &
