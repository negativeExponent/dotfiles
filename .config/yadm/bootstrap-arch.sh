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


error() {
	# Log to stderr and exit with failure.
	printf "%s\n" "$1" >&2
	exit 1
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

	# some base apps
	PKGS="base-devel "
	PKGS+="openssh "
	PKGS+="git "
	PKGS+="curl "
	PKGS+="wget "
	PKGS+="ccache " 
	PKGS+="vim "

	# X
	PKGS+="xorg-server "
	PKGS+="xorg-xinit "
	PKGS+="xorg-xrdb "
	PKGS+="xorg-xrandr "
	PKGS+="xorg-xsetroot " 
	PKGS+="xorg-xset "
	PKGS+="xorg-xwininfo "
	PKGS+="xsel "
	PKGS+="xdo "
    PKGS+="xdotool "

	# Audio

	#[ "$ARCH" = "obarun" ] && PKGS+="pulseaudio-66serv "
	#PKGS+="pulseaudio "
	#PKGS+="pulseaudio-alsa "
	#PKGS+="pulseaudio-jack "
	
	PKGS+="alsa-utils "

	PKGS+="pipewire "
	PKGS+="pipewire-alsa "
	PKGS+="pipewire-pulse "
	PKGS+="gst-plugin-pipewire "

	if [ "$ARCH" = "obarun" ]; then
		# Because pipewire-media-session if dependency of pipewire-66serv, for now
		PKGS+="pipewire-66serv "
		PKGS+="pipewire-media-session "
	else
		PKGS+="wireplumber "
	fi

	PKGS+="libpulse "
	PKGS+="pamixer "
	PKGS+="pulsemixer "
	PKGS+="playerctl "

	# BSPWM Desktop
	PKGS+="bspwm sxhkd kitty rofi geany "

	# arch has forced systemd crap as dunst dependency
	[ "$ARCH" = "obarun" ] || PKGS+="dunst "

	PKGS+="xfce4-settings thunar thunar-volman thunar-archive-plugin maim "

	#archiver manager
	PKGS+="xarchiver "

	#compression support files
	PKGS+="zip unzip p7zip "

	PKGS+="unclutter htop neofetch zsh thefuck lua starship xclip "

	# Video player
	PKGS+="mpv  "

	#fonts and themes
	PKGS+="ttf-linux-libertine "
	PKGS+="noto-fonts "
	PKGS+="noto-fonts-emoji "
	PKGS+="noto-fonts-cjk "
	PKGS+="ttf-jetbrains-mono "
	PKGS+="ttf-font-awesome "
	
	PKGS+="papirus-icon-theme "

	PKGS+="nitrogen " # wallpaper setter and changer


	PKGS+="mlocate pacman-contrib "
	
	# some apps i personally use
	PKGS+="meld ghex gnome-calculator "

	# relies on libsystemd/systemd
	[ "$ARCH" = "obarun" ] || PKGS+="mpd mpc ncmpcpp "

	PKGS+="numlockx "

	# System utilities
	PKGS+="android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring udisks2 udiskie " # automounting of usb and android devices

    # for calendar popup
    PKGS+="yad "

	# Document viewer
	# PKGS+="w3m zathura zathura-pdf-mupdf maim xclip "
	# Misc apps
	#PKGS+="bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg "
	#PKGS+="atool imagemagick python-pillow xdotool ffmpegthumbnailer ranger "
	#PKGS+="speedtest-cli "

	pac_install $PKGS
}

refreshkeys() {
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		install_msg "Refreshing Arch Keyring..."
		sudo pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
		;;
	*)
		if [ "$ARCH" = "artix" ]; then
			install_msg "Enabling Arch Repositories..."
			if ! grep -q "^\[universe\]" /etc/pacman.conf; then
				echo "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" | sudo tee -a /etc/pacman.conf
				sudo pacman -Sy --noconfirm >/dev/null 2>&1
			fi
			sudo pacman --noconfirm --needed -S \
				artix-keyring artix-archlinux-support >/dev/null 2>&1
			for repo in extra community; do
				grep -q "^\[$repo\]" /etc/pacman.conf ||
					echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee -a /etc/pacman.conf
			done
			sudo pacman -Sy >/dev/null 2>&1
			sudo pacman-key --populate archlinux >/dev/null 2>&1
		fi
		;;
	esac
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
	#command -v "brave" >/dev/null || pac_install "brave-bin"
	#command -v "tremc" >/dev/null || pac_install "tremc-git"
	#command -v "picom" >/dev/null || pac_install "picom-git"
	#command -v "vscodium" >/dev/null || pac_install "vscodium-bin"
	#[ "$ARCH" = "obarun" ] || command -v "cava" >/dev/null || pac_install "cava-git"
	# lockscreen
	#command -v "betterlockscreen" >/dev/null || pac_install "betterlockscreen"
	#command -v "xautolock" >/dev/null || pac_install "xautolock"
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

install_theme() {
	cd
	wget -c https://github.com/dracula/gtk/archive/master.zip
	[ -d ./gtk-master ] && rm -rf gtk-master
	unzip -q master.zip
	mkdir -p ~/.local/share/themes
	[ -d ~/.local/share/themes/Dracula ] && rm -rf ~/.local/share/themes/Dracula
	mv gtk-master ~/.local/share/themes/Dracula
	rm master.zip
	gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
	gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
}

######################
## Start of Script ###
######################


install_msg "Detected system = $ARCH ($INIT)"

! command -v ntpdate > /dev/null 2>&1  && sudo pacman -S ntp --needed --noconfirm
install_msg "Synchronizing system time to ensure successful and secure installation of software..."
##ntpdate 0.us.pool.ntp.org >/dev/null 2>&1


install_msg "Running symlinks to personal directories..."
. "$HOME/.config/yadm/_symlink.sh"


install_msg "Making pacman beautiful and colorful because why not..."
grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
grep "^ParallelDownloads" /etc/pacman.conf >/dev/null || sudo sed -i "s/.*ParallelDownloads.*/ParallelDownloads = 5/" /etc/pacman.conf

# Use all cores for compilation.
sudo sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

# Refresh Arch keyrings.
refreshkeys ||
	error "Error automatically refreshing Arch keyring. Consider doing so manually."


install_msg "Updating pacman..."
sudo pacman -Syu --noconfirm


install_msg "Installing AUR helper..."
install_aur_helper


install_msg "Installing base packages..."
install_packages


install_msg "Installing AUR packages..."
install_aur_packages


install_msg "Installing and configuring intel gpu driver..."
configure_intel_video


install_msg "Installing Dracula GTK Theme"
install_theme

###################################
# section includes patches from LARBS
###################################

# Most important command! Get rid of the beep!
#sudo rmmod pcspkr
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# dbus UUID must be generated for Artix runit.
! [ "$ARCH" = "obarun" ] && sudo dbus-uuidgen >/dev/null | sudo tee /var/lib/dbus/machine-id

# Use system notifications for Brave on Artix
echo "export \$(dbus-launch)"| sudo tee /etc/profile.d/dbus.sh

#######
# END #
#######

install_msg "Done."
