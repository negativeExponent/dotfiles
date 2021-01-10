#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

ARCH="$1"								# arch or artix
INIT="systemd"							# init, systemd as default
RUNSVDIR="/etc/runit/runsvdir/default" 	# artix-runit service directory

if [ "$EUID" -eq 0 ]; then
	echo "Please do not run this script as root (e.g. using sudo)"
	exit
fi

if [[ "$ARCH" = "artix" ]]; then
	sudo pacman -Qk openrc 2>/dev/null && INIT="openrc"
	sudo pacman -Qk runit 2>/dev/null && INIT="runit"
	sudo pacman -Qk s6 2>/dev/null && INIT="s6"
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
	# Xorg
	PKGS+=" base-devel xorg-server xorg-xinit xorg-xauth xf86-input-libinput"
	PKGS+=" xf86-video-intel"
	PKGS+=" arandr xorg-xrdb xorg-xset xorg-xsetroot xorg-xprop xcalib xdg-utils"
	PKGS+=" xdo xorg-setxkbmap xorg-xmodmap bash-completion ccache ntfs-3g "
	PKGS+=" git curl wget xsel wireless_tools"

	# Audio
	PKGS+=" alsa-utils"
	PKGS+=" pulseaudio-alsa pamixer pulsemixer"
	[ "$ARCH" = "obarun" ] && PKGS+=" pulseaudio-66serv"

	# Minimal bspwm apps
	PKGS+=" bspwm sxhkd kitty rofi dunst geany pcmanfm"
	PKGS+=" lxappearance perl vim"
	PKGS+=" mpv w3m neofetch"
	PKGS+=" htop zathura zathura-pdf-mupdf maim xclip feh xcompmgr"
	PKGS+=" file-roller zip unzip p7zip meld ghex gnome-calculator jq"
	PKGS+=" ttf-linux-libertine noto-fonts-emoji arc-icon-theme"

	[ "$ARCH" = "obarun" ] || PKGS+=" mpd mpc ncmpcpp" # obarun does not have libsystemd, so these will fail to install

	# ! pacman -Qk polybar >/dev/null || PKGS+=" polybar"

	# Misc apps
	PKGS+=" bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
	PKGS+=" atool imagemagick python-pillow xdotool xorg-xdpyinfo ffmpegthumbnailer ranger"
	PKGS+=" speedtest-cli"
	PKGS+=" numlockx"

	# Additional fonts and themes
	PKGS+=" ttf-croscore gtk-engine-murrine"

	# System utilities
	PKGS+=" android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices

    # redshift
    PKGS+=" redshift"

    # for calendar popup
    PKGS+=" yad"

	PKGS+=" openssh"

	pac_install $PKGS
}

install_aur_packages() {
	command -v "polybar" >/dev/null || pac_install "polybar-git"
	[ "$ARCH" = "obarun" ] || command -v "cava" >/dev/null || pac_install "cava-git"
	command -v "brave" >/dev/null || pac_install "brave-bin"
	command -v "tremc" >/dev/null || pac_install "tremc-git"
}

configure_intel_video() {
	# Detect if we are on an Intel system
	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ $CPU_VENDOR = "GenuineIntel" ]; then
		pac_install xf86-video-intel libva-intel-driver
		# gets rid of screen tearing if not using compositor/wm does not have vsync
		sudo mkdir -p /usr/share/X11/xorg.conf.d/
		sudo bash -c 'cat > /usr/share/X11/xorg.conf.d/20-intel.conf' << EOF
# /usr/share/X11/xorg.conf.d/20-intel.conf

Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
#   Option     "SwapbuffersWait"       "false"
   Option "DRI" "3"
   Option      "TearFree"     "true"
EndSection
EOF
	fi
}

######################
## Start of Script ###
######################

install_msg "Detected system = $ARCH ($INIT)"

grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

. "$HOME/.config/yadm/_symlink.sh"

sudo pacman -Syu --noconfirm

install_aur_helper
install_packages
install_aur_packages
configure_intel_video

if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

[[ ! -f "$HOME/.config/wall.jpg" ]] || feh --bg-center "$HOME/.config/wall.jpg"

echo ""
install_msg "Done."
echo ""
