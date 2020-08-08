#!/bin/sh
# Simple script that uses maim to take a screenshot

[ -d "$HOME/Pictures/screenshots" ] || mkdir -p $HOME/Pictures/screenshots
output=$HOME/Pictures/screenshots/"$(date +%s_%Y_%m_%d_%H:%M:%S).png"
case "$1" in
    "full") maim "$output" || exit;;
    "window") maim -s "$output" || exit ;;
esac
notify-send "Screenshot saved to ${output}"
