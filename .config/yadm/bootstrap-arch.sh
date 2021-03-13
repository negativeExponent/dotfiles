#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

clear

ARCH="$1"								# arch or artix
INIT="systemd"							# init, systemd as default

if [ "$EUID" -eq 0 ]; then
	echo "Please do not run this script as root (e.g. using sudo)"
	exit
fi

if [[ "$ARCH" = "artix" ]]; then
	pacman -Qk openrc 2>/dev/null && INIT="openrc"
	pacman -Qk runit 2>/dev/null && INIT="runit"
	pacman -Qk s6 2>/dev/null && INIT="s6"
fi

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

pac_install() {
	# echo -e "\e[35mInstalling: $@...\e[0m"
	yay -S --needed --noconfirm "$@"
}

install_aur_helper() {
	if ! command -v yay >/dev/null; then
		[ -d /tmp/yay-bin ] && rm -rf /tmp/yay-bin
		git clone --depth 1 https://aur.archlinux.org/yay-bin /tmp/yay-bin
		cd /tmp/yay-bin
		makepkg -si --noconfirm
		if ! command -v yay >/dev/null; then
			echo "Failed to install yay-bin."
			exit 1
		fi
	fi
}

install_packages() {
	local PKGS=

	# some essential apps
	PKGS="base-devel "
	PKGS+="openssh git curl wget ccache vim "

	# X
	PKGS+="xorg-server xorg-xinit xorg-xrdb xorg-xrandr xorg-xsetroot xorg-xset xsel xdo unclutter htop neofetch zsh "

	# Audio
	PKGS+="alsa-utils alsa-firmware "
	PKGS+="pulseaudio-alsa pamixer pulsemixer "
	[ "$ARCH" = "obarun" ] && PKGS+="pulseaudio-66serv "

	# Minimal bspwm apps
	PKGS+="bspwm sxhkd kitty rofi dunst geany pcmanfm-gtk3 "

	# other apps needed but not required for WM to start
	PKGS+="mpv w3m lxappearance-gtk3 "
	PKGS+="zathura zathura-pdf-mupdf maim xclip feh "
	PKGS+="xarchiver zip unzip p7zip jq "
	PKGS+="ttf-linux-libertine noto-fonts-emoji arc-icon-theme "
	
	# some apps i personally use
	PKGS+="meld ghex gnome-calculator "

	# relies on libsystemd/systemd
	[ "$ARCH" = "obarun" ] || PKGS+="mpd mpc ncmpcpp "

	# Misc apps
	PKGS+="bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg "
	PKGS+="atool imagemagick python-pillow xdotool ffmpegthumbnailer ranger "
	PKGS+="speedtest-cli "
	PKGS+="numlockx "

	# Additional fonts and themes
	PKGS+="ttf-croscore gtk-engine-murrine "

	# System utilities
	PKGS+="android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring " # automounting of usb and android devices

    # redshift
    PKGS+="redshift "

    # for calendar popup
    PKGS+="yad "

	pac_install $PKGS
}

install_aur_packages() {
	if ! command -v "polybar" >/dev/null; then
		if pacman -Ssq polybar >/dev/null; then
			install_msg "Installing polybar from repository..."
			pac_install 'polybar'
		else
			install_msg "Installing polybar from aur..."
			pac_install 'polybar-git'
		fi
	fi
	# relies on libsystemd
	command -v "brave" >/dev/null || pac_install "brave-bin"
	command -v "tremc" >/dev/null || pac_install "tremc-git"
	command -v "picom" >/dev/null || pac_install "picom-tryone-git"
	command -v "vscodium" >/dev/null || pac_install "vscodium-bin"
	[ "$ARCH" = "obarun" ] || command -v "cava" >/dev/null || pac_install "cava-git"
	# lockscreen
	command -v "betterlockscreen" >/dev/null || pac_install "betterlockscreen"
	command -v "xautolock" >/dev/null || pac_install "xautolock"
}

configure_intel_video() {
	local ati=$(lspci | grep VGA | grep ATI)
	local nvidia=$(lspci | grep VGA | grep NVIDIA)
	local intel=$(lspci | grep VGA | grep Intel)
	local amd=$(lspci | grep VGA | grep AMD)
	
	if [ ! -z "$ati" ]; then
	    echo 'Ati graphics detected'
	    pac_install xf86-video-ati
	fi
	if [ ! -z "$nvidia" ]; then
	    echo 'Nvidia graphics detected'
	    pac_install xf86-video-nouveau
	fi
	if [ ! -z  "$intel" ]; then
	    echo 'Intel graphics detected'
	    pac_install xf86-video-intel libva-intel-driver
	fi
	if [ ! -z  "$amd" ]; then
	    echo 'AMD graphics detected'
	    pac_install xf86-video-amdgpu
	fi

	# Detect if we are on an Intel system
##	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
##	if [ $CPU_VENDOR = "GenuineIntel" ]; then
	if [ ! -z  "$intel" ]; then
		# gets rid of screen tearing if not using compositor/wm does not have vsync
		sudo mkdir -p /usr/share/X11/xorg.conf.d/
		sudo bash -c 'cat > /usr/share/X11/xorg.conf.d/20-intel.conf' << EOF
# /usr/share/X11/xorg.conf.d/20-intel.conf

Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
#   Option     "SwapbuffersWait"       "false"
#   Option "DRI" "3"
   Option      "TearFree"     "true"
EndSection
EOF
	fi
}

######################
## Start of Script ###
######################

install_msg ""
install_msg "Detected system = $ARCH ($INIT)"

install_msg ""
install_msg "Running symlinks to personal directories..."
. "$HOME/.config/yadm/_symlink.sh"

install_msg ""
install_msg "Making pacman beautiful and colorful because why not..."
grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

install_msg ""
install_msg "Updating pacman..."
sudo pacman -Syu --noconfirm

install_msg ""
install_msg "Installing AUR helper..."
install_aur_helper

install_msg ""
install_msg "Installing base packages..."
install_packages

install_msg ""
install_msg "Installing AUR packages..."
install_aur_packages

install_msg ""
install_msg "Installing and configuring intel gpu driver..."
configure_intel_video

if command -v "betterlockscreen" >/dev/null; then
	if [ -f "$HOME/.config/wall.jpg" ]; then
		install_msg "Preparing lockscreen config..."
		betterlockscreen -u ~/.config/wall.jpg
	fi
fi

install_msg ""
install_msg "Enabling ssh key..."
if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

install_msg ""
install_msg "Done."
install_msg ""
