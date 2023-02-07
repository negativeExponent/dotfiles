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

killall -9 picom
while pgrep -x picom; do sleep 1; done

# load Xresources
if [ -f "$HOME/.Xresources" ]; then
	xrdb -merge "$HOME/.Xresources"
else
	xrdb -merge "${XDG_CONFIG_HOME:-$HOME/.config}/shell/xresources"
fi

xset s off
xset -dpms

~/.fehbg
xsetroot -cursor_name left_ptr &
unclutter &
autotiling &

run /usr/libexec/polkit-gnome-authentication-agent-1
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg) &

run "mpd"
run "udiskie" " --automount --notify --tray"

if command -v transmission-daemon >/dev/null; then
	if ! pgrep -x transmission-da >/dev/null; then
		transmission-daemon &
	fi
fi

# Ensure that xrdb has finished running before moving on to start the WM/DE.
[ -n "$xrdbpid" ] && wait "$xrdbpid"

. "$HOME/.local/bin/setcolors" &			# exports color configs to rofi, kitty ...
. "$HOME/.local/bin/launch_picom" &         # kills and relaunch compositor
. "$HOME/.local/bin/launch_polybar" "mainbar-i3" &       # kills and relaunch panel
. "$HOME/.local/bin/launch_dunst" &         # kills and relaunch notification daemon
# . "$HOME/.local/bin/autolock" 5 &
