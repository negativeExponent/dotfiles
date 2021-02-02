#!/bin/env bash

set -e

# REPO='https://alpha.de.repo.voidlinux.org'
# REPO='https://alpha.us.repo.voidlinux.org'
# REPO='https://mirrors.servercentral.com/voidlinux'
# REPO='https://alpha.us.repo.voidlinux.org'
# REPO='https://mirror.clarkson.edu/voidlinux'
# REPO='https://mirror.yandex.ru/mirrors/voidlinux'
REPO='https://ftp.swin.edu.au/voidlinux'

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

xbps_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	sudo xbps-install -Sy -R ${REPO}/current -R ${REPO}/current/nonfree "$@"
}	

# Xorg
PKGS=" base-devel xorg-minimal xinit xauth xorg-server xf86-input-libinput" 
PKGS+=" xf86-video-intel"
PKGS+=" arandr xrdb xset xsetroot xprop xcalib xdg-utils"
PKGS+=" xdo setxkbmap xmodmap bash-completion ccache ntfs-3g "
PKGS+=" git curl wget xtools xsel wireless_tools"

# killall
PKGS+=" psmisc"

# Audio
PKGS+=" alsa-utils"
PKGS+=" alsa-plugins-pulseaudio pamixer pulsemixer"

# Minimal bspwm apps
PKGS+=" bspwm sxhkd kitty rofi polybar dunst geany pcmanfm firefox"
PKGS+=" lxappearance vim mpd mpc ncmpcpp mpv w3m w3m-img neofetch"
PKGS+=" htop zathura zathura-pdf-mupdf maim xclip feh"
PKGS+=" file-roller zip unzip p7zip meld ghex gnome-calculator jq"
PKGS+=" font-libertine-ttf noto-fonts-emoji arc-icon-theme"

# Misc apps
PKGS+=" bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
PKGS+=" atool ImageMagick python3-Pillow xdotool xdpyinfo ffmpegthumbnailer"
PKGS+=" cava ranger geoip"
PKGS+=" speedtest-cli geoip-data"

# Additional fonts and themes
PKGS+=" fonts-croscore-ttf gtk-engine-murrine"

# System utilities
PKGS+=" android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices
	
# redshift
PKGS+=" redshift"

# compositor
PKGS+=" picom"

if ! command -v xbps-install >/dev/null; then
	echo "ERROR! Cannot install on non VoidLinux system"
	exit
fi

xbps_install $PKGS
