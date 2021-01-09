#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

ARCH="$1"
INIT="systemd"

PKGS=""
RUNSVDIR="/etc/runit/runsvdir/default"

if [[ "$ARCH" = "artix" ]]; then
	sudo pacman -Qk openrc 2>/dev/null && INIT="openrc"
	sudo pacman -Qk runit 2>/dev/null && INIT="runit"
	sudo pacman -Qk s6 2>/dev/null && INIT="s6"
fi

echo ""
echo -e "\e[34mDetected system = $ARCH ($INIT)\e[0m"


install_msg() {
	echo -e "\e[32m$@\e[0m"
}

# Creates a symlink for item1 to item2, deleting destination if it exists
link() {
	if [ -d $1 ] ; then
		status='!'
		[ ! -e $2 ] || rm -rf $2
		ln -sfv $1 $2 && status='ok'
		#install_msg "$status - Symlinking $1 to $2"
	fi
}

pac_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	yay -S --needed --noconfirm "$@"
}

get_packages() {
	# Xorg
	PKGS="${PKGS} base-devel xorg-server xorg-xinit xorg-xauth xf86-input-libinput"
	PKGS="${PKGS} xf86-video-intel"
	PKGS="${PKGS} arandr xorg-xrdb xorg-xset xorg-xsetroot xorg-xprop xcalib xdg-utils"
	PKGS="${PKGS} xdo xorg-setxkbmap xorg-xmodmap bash-completion ccache ntfs-3g "
	PKGS="${PKGS} git curl wget xsel wireless_tools"

	# Audio
	PKGS="${PKGS} alsa-utils"
	PKGS="${PKGS} pulseaudio-alsa pamixer pulsemixer"
	[ "$ARCH" = "obarun" ] && PKGS="${PKGS} pulseaudio-66serv"

	# Minimal bspwm apps
	PKGS="${PKGS} bspwm sxhkd kitty rofi dunst geany pcmanfm"
	PKGS="${PKGS} lxappearance perl vim"
	PKGS="${PKGS} mpv w3m neofetch"
	PKGS="${PKGS} htop zathura zathura-pdf-mupdf maim xclip feh xcompmgr"
	PKGS="${PKGS} file-roller zip unzip p7zip meld ghex gnome-calculator jq"
	PKGS="${PKGS} ttf-linux-libertine noto-fonts-emoji arc-icon-theme"

	[ "$ARCH" = "obarun" ] || PKGS="${PKGS} mpd mpc ncmpcpp" # obarun does not have libsystemd, so these will fail to install

	! pacman -Qk polybar >/dev/null || PKGS="${PKGS} polybar"

	# Misc apps
	PKGS="${PKGS} bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
	PKGS="${PKGS} atool imagemagick python-pillow xdotool xorg-xdpyinfo ffmpegthumbnailer ranger"
	PKGS="${PKGS} speedtest-cli"
	PKGS="${PKGS} numlockx"

	# Additional fonts and themes
	PKGS="${PKGS} ttf-croscore gtk-engine-murrine"

	# System utilities
	PKGS="${PKGS} android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices

    # redshift
    PKGS="${PKGS} redshift"

    # for calendar popup
    PKGS="${PKGS} yad"
}

configure_intel_video() {
	# Detect if we are on an Intel system
	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ $CPU_VENDOR = "GenuineIntel" ]; then
		install_msg "Installing Intel Video Acceleration"
		pac_install xf86-video-intel libva-intel-driver
		install_msg "Install Intel Xorg config"
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

# symlinks to commonly used folders/apps

create_symlinks() {
	mkdir -p $HOME/.cache
	mkdir -p $HOME/.config

	link /mnt/data/yay $HOME/.cache/yay

	# symlinks to HOME
	link /mnt/data/Documents $HOME/Documents
	link /mnt/data/Downloads $HOME/Downloads
	link /mnt/data/Pictures $HOME/Pictures

	link /mnt/data/Music $HOME/Music

	link /mnt/data/myfiles/.mozilla $HOME/.mozilla
	link /mnt/data/myfiles/ssh_key/.ssh $HOME/.ssh

	# symlinks to .config
	link /mnt/data/myfiles/BraveSoftware $HOME/.config/BraveSoftware
	link /mnt/data/retroarch $HOME/.config/retroarch
	link /mnt/data/myfiles/transmission-daemon $HOME/.config/transmission-daemon
}

######################
## Start of Script ###
######################

echo -e "\e[31mChecking permissions...\e[0m"
if [ "$EUID" -eq 0 ]; then
	echo "Please do not run this script as root (e.g. using sudo)"
	exit
fi

# Place these system tweaks ahead here to take advantage of threading
# when compiling from AUR
# use max cores/thread the processor has
install_msg "Use max cores/threads when compiling."
num=$(grep -c ^processor /proc/cpuinfo)
sudo sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${num}\"/g" /etc/makepkg.conf

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
install_msg "Make paacman and yay colorful."
grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

install_msg "Creating symlinks for some common applications."
create_symlinks

install_msg "Syncing pacman database"
sudo pacman -Syu --noconfirm

if ! command -v yay >/dev/null; then
	install_msg "Yay aur helper not found. We will compile this from AUR."
	! command -v yay >/dev/null && sudo pacman -S --needed --noconfirm git ccache
	install_msg "Fetching yay-bin"
	[ -d /tmp/yay-bin ] && rm -rf /tmp/yay-bin
	git clone --depth 1 https://aur.archlinux.org/yay-bin /tmp/yay-bin
	cd /tmp/yay-bin
	makepkg -si --noconfirm
	if ! command -v yay >/dev/null; then
		echo "Failed to install yay-bin."
		exit 1
	fi
fi

# Get a list of packages to install
get_packages

# Install selected packages
pac_install $PKGS

# Install aur packages
install_msg "Installing aur packages."
command -v "polybar" >/dev/null || pac_install "polybar"
# command -v "cava" >/dev/null || pac_install "cava-git"
command -v "brave" >/dev/null || pac_install "brave-bin"

install_msg "Configure Intel Video"
configure_intel_video

if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

[[ ! -f "$HOME/.config/wall.jpg" ]] || feh --bg-center "$HOME/.config/wall.jpg"

echo "Finished."
echo ""
