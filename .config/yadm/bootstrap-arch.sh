#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

ARCH="$1"								# arch or artix
INIT="systemd"							# init, systemd as default

## Xorg ##
PKGS+="xorg-server "
PKGS+="xorg-xinit "
PKGS+="xorg-xprop "
PKGS+="xorg-xrdb "
PKGS+="xorg-xrandr "
PKGS+="xorg-xsetroot "
PKGS+="xorg-xset "
PKGS+="xorg-xwininfo "

## BSPWM Desktop ##
PKGS+="bspwm sxhkd kitty rofi geany "
# arch has forced systemd crap as dunst dependency
[ "$ARCH" = "obarun" ] || PKGS+="dunst "

## filemanager and appearance (xfce4) ##
PKGS+="xfce4-settings xfce4-power-manager thunar thunar-volman thunar-archive-plugin udiskie "
PKGS+="xarchiver zip unzip p7zip "

## Audio/Video/Media ##
PKGS+="alsa-utils "
PKGS+="pipewire pipewire-pulse wireplumber "
PKGS+="pulsemixer "
PKGS+="mpv " # Video player
# relies on libsystemd/systemd
[ "$ARCH" = "obarun" ] || PKGS+="mpd mpc ncmpcpp " # music player

#fonts and themes
PKGS+="libertinus-font " # libertine replacement
PKGS+="noto-fonts-emoji "
PKGS+="ttf-jetbrains-mono "
PKGS+="arc-gtk-theme "
PKGS+="papirus-icon-theme "
PKGS+="nitrogen " # wallpaper setter and changer

## misc utilities ##
PKGS+="meld "
PKGS+="ghex "
PKGS+="gnome-calculator "
PKGS+="ccache "
PKGS+="sxiv " # image viewer
PKGS+="vim " # text editor
PKGS+="curl " # weather widget
PKGS+="maim " # screenshot
PKGS+="unclutter htop neofetch "
PKGS+="zsh zsh-completions thefuck lua starship "
#	PKGS+="xsel "
#	PKGS+="xdo "
PKGS+="xdotool "
PKGS+="numlockx "
PKGS+="yad " # for calendar popup
PKGS+="mlocate "
PKGS+="pacman-contrib " # update widget

## Document viewer ##
PKGS+="w3m zathura zathura-pdf-mupdf maim xclip "
# Misc apps
#PKGS+="bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg "
#PKGS+="atool imagemagick python-pillow xdotool ffmpegthumbnailer ranger "
#PKGS+="speedtest-cli "

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

error() {
	# Log to stderr and exit with failure.
	printf "%s\n" "$1" >&2
	exit 1
}

pac_install() {
	yay -S --needed --noconfirm "$@"
}

detect_system() {
	if [[ "$ARCH" = "artix" ]]; then
		pacman -Qk openrc 2>/dev/null && INIT="openrc"
		pacman -Qk runit 2>/dev/null && INIT="runit"
		pacman -Qk s6 2>/dev/null && INIT="s6"
	fi
	install_msg "Detected system = $ARCH ($INIT)"
}

create_symlinks() {
	install_msg "Running symlinks to personal directories..."
	. "$XDG_CONFIG_HOME/yadm/_symlink.sh"
}

pretty_pacmanconf() {
	install_msg "Making pacman beautiful and colorful because why not..."
	grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
	grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
	grep "^ParallelDownloads" /etc/pacman.conf >/dev/null || sudo sed -i "s/.*ParallelDownloads.*/ParallelDownloads = 5/" /etc/pacman.conf

	# Use all cores for compilation.
	sudo sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf
}

refreshkeys() {
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		install_msg "Refreshing Arch Keyring..."
		sudo pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
		;;
	*)
		if [ "$ARCH" = "artix" ]; then
		. "$XDG_CONFIG_HOME/yadm/artix_enable_archlinux_repo.sh"
		fi
		;;
	esac
}

update_system() {
	install_msg "Updating pacman..."
	sudo pacman -Syu --noconfirm
}

install_aur_helper() {
	if ! command -v yay >/dev/null; then
		install_msg "Installing AUR helper..."
		[ -d /tmp/yay-bin ] && rm -rf /tmp/yay-bin
		git clone --depth 1 https://aur.archlinux.org/yay-bin /tmp/yay-bin
		cd /tmp/yay-bin
		makepkg -si --noconfirm
		if ! command -v yay >/dev/null; then
			error "Failed to install aur helper (yay)."
		fi
	fi
}

install_packages() {
	install_msg "Installing packages..."
	pac_install $PKGS
}

install_aur_packages() {
	install_msg "Installing AUR packages..."
	install_aur_helper
	if ! command -v "polybar" >/dev/null; then
		if pacman -Ssq polybar >/dev/null; then
			install_msg "Installing polybar from repository..."
			pac_install 'polybar'
		else
			install_msg "Installing polybar from aur..."
			pac_install 'polybar-git'
		fi
	fi
	command -v "simple-mtpfs" >/dev/null || pac_install simple-mtpfs
	#command -v "brave" >/dev/null || pac_install "brave-bin"
	#command -v "tremc" >/dev/null || pac_install "tremc-git"
	#command -v "picom" >/dev/null || pac_install "picom-git"
	#command -v "vscodium" >/dev/null || pac_install "vscodium-bin"
	#[ "$ARCH" = "obarun" ] || command -v "cava" >/dev/null || pac_install "cava-git"
	# lockscreen
	#command -v "betterlockscreen" >/dev/null || pac_install "betterlockscreen"
	#command -v "xautolock" >/dev/null || pac_install "xautolock"
}

configure_video() {
	install_msg "Installing and configuring intel gpu driver..."

	local ati=$(lspci | grep VGA | grep ATI)
	local nvidia=$(lspci | grep VGA | grep NVIDIA)
	local intel=$(lspci | grep VGA | grep Intel)
	local amd=$(lspci | grep VGA | grep AMD)

	if [ ! -z "$ati" ]; then
	    install_msg 'Ati graphics detected'
	    pac_install xf86-video-ati
	fi
	if [ ! -z "$nvidia" ]; then
	    install_msg 'Nvidia graphics detected'
	    pac_install xf86-video-nouveau
	fi
	if [ ! -z  "$intel" ]; then
	    install_msg 'Intel graphics detected'
	    pac_install xf86-video-intel libva-intel-driver
	fi
	if [ ! -z  "$amd" ]; then
	    install_msg 'AMD graphics detected'
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
   Option      "TearFree"     "true"
EndSection
EOF
	fi
}

install_theme() {
	if [ ! -d "$HOME/.local/share/themes/Dracula" ]; then
	install_msg "Installing Dracula GTK Theme"
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
	fi
}

finishing_up() {
	###################################
	# section includes patches from LARBS
	###################################

	# Most important command! Get rid of the beep!
	#sudo rmmod pcspkr
	echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

	if [[ "$ARCH" = "artix" ]]; then
		# dbus UUID must be generated for Artix runit.
		[ -d "/var/lib/dbus" ] || sudo mkdir -p /var/lib/dbus
		sudo dbus-uuidgen >/dev/null | sudo tee /var/lib/dbus/machine-id

		# Use system notifications for Brave on Artix
		echo "export \$(dbus-launch)" >/dev/null | sudo tee /etc/profile.d/dbus.sh
	fi
}

######################
## Start of Script ###
######################

clear

[ "$EUID" -eq 0 ] && error "Please do not run this script as root (e.g. using sudo)"

detect_system
create_symlinks
pretty_pacmanconf
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."
update_system
install_packages
install_aur_packages
configure_video
install_theme
finishing_up

install_msg "Done."
