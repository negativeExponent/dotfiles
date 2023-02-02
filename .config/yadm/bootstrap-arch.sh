#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

box() {
    title=" $1 "
    edge=$(echo "$title" | sed 's/./*/g')
    echo "$edge"
    echo -e "\e[1;32m$title\e[0m"
    echo "$edge"
}


box1() {
    title=" $1 "
    edge=$(echo "$title" | sed 's/./*/g')
    echo "$edge"
    echo -e "\e[1;31m$title\e[0m"
}


box2() {
    title=" $1 "
    echo -e "\e[1;31m$title\e[0m"
}


box3() {
    title=" $1 "
    edge=$(echo "$title" | sed 's/./*/g')
    echo -e "\e[1;31m$title\e[0m"
    echo "$edge"
}

install_msg() {
	box "$1"
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

install_needed() {
	sudo pacman -S --needed --noconfirm git wget curl man-db vim base-devel ccache xorg-server xorg-xinit
}

create_symlinks() {
	install_msg "Running symlinks to personal directories..."
	. "${XDG_CONFIG_HOME:-$HOME/.config}/yadm/_symlink.sh"
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
			box "Enabling Arch repositories and updating keyrings..."
			. "${XDG_CONFIG_HOME:-$HOME/.config}/yadm/artix_enable_archlinux_repo.sh"
		fi
		;;
	esac
}

update_system() {
	install_msg "Updating system, please wait..."
	sudo pacman -Syu --noconfirm
}

install_aur_helper() {
	if ! command -v yay >/dev/null; then
		install_msg "Installing AUR helper..."
		[ -d /tmp/yay-bin ] && rm -rf /tmp/yay-bin
		git clone https://aur.archlinux.org/yay-bin /tmp/yay-bin
		cd /tmp/yay-bin || exit
		makepkg -si --noconfirm
		if ! command -v yay >/dev/null; then
			error "Failed to install aur helper (yay)."
		fi
	fi
}

install_packages() {
	install_msg "Installing desktop applications..."
	install_aur_helper
	pac_install xorg-xrdb xorg-xrandr xorg-xsetroot xorg-xset xorg-xwininfo
	pac_install rofi kitty geany nitrogen
	[ "$ARCH" = "obarun" ] || pac_install dunst
	#pac_install xfce4-settings thunar thunar-volman thunar-archive-plugin 
	pac_install lxappearance pcmanfm
	pac_install xarchiver zip unzip p7zip
	pac_install arc-gtk-theme papirus-icon-theme
	pac_install ttf-liberation libertinus-font ttf-jetbrains-mono noto-fonts-emoji
	pac_install meld ghex gnome-calculator polkit-gnome gnome-keyring # gnome trash
	pac_install zsh zsh-completions lua thefuck starship
	# terminal apps
	pac_install sxiv maim htop yad unclutter xdotool numlockx w3m xclip
	pac_install mlocate pacman-contrib
	#pac_install zathura zathura-pdf-mupdf
	# window manager
	pac_install bspwm sxhkd
	#pac_install i3
	# Misc apps
	#pac_install bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg
	#pac_install atool imagemagick python-pillow xdotool ffmpegthumbnailer ranger
	#pac_install speedtest-cli
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
	command -v "ksuperkey" >/dev/null || pac_install ksuperkey
	#[ -x "/usr/lib/xfce-polkit/xfce-polkit" ] || pac_install xfce-polkit
	command -v "picom" >/dev/null || pac_install picom-ibhagwan-git
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
	install_msg "Installing and configuring video drivers..."

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
	box "Finishing touches..."

	echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

	if [[ "$ARCH" = "artix" ]]; then
		# dbus UUID must be generated for Artix runit.
		[ -d "/var/lib/dbus" ] || sudo mkdir -p /var/lib/dbus
		sudo dbus-uuidgen >/dev/null | sudo tee /var/lib/dbus/machine-id

		# Use system notifications for Brave on Artix
		echo "export \$(dbus-launch)" >/dev/null | sudo tee /etc/profile.d/dbus.sh
	fi
}

check_root() {
	if [ "$EUID" -eq 0 ]; then
		error "Please do not run this script as root (e.g. using sudo)"
	fi
}

######################
## Start of Script ###
######################

set -e

ARCH="$1"								# arch or artix
INIT="systemd"							# init, systemd as default

check_root
detect_system
create_symlinks
install_needed

pretty_pacmanconf
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."
update_system
install_packages
install_aur_packages
configure_video
#install_theme
finishing_up

install_msg "Done."
