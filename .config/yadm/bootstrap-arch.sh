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
    echo -e "\e[1;32m$title\e[0m"
}


box2() {
    title=" $1 "
    echo -e "\e[1;32m$title\e[0m"
}


box3() {
    title=" $1 "
    edge=$(echo "$title" | sed 's/./*/g')
    echo -e "\e[1;32m$title\e[0m"
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
	for f in ${@} ; do
		paru -S --skipreview --noconfirm --needed "$f"
	done
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
	sudo pacman -S --needed --noconfirm git wget curl man-db neovim base-devel ccache
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
	local aur_name="paru-bin"
	local aur_cmd="paru"

	if ! command -v $aur_cmd >/dev/null; then
		install_msg "Installing AUR helper %s... " $aur_name

		[ -d /tmp/$aur_name ] && rm -rf /tmp/$aur_name
		git clone https://aur.archlinux.org/$aur_name /tmp/$aur_name
		cd /tmp/$aur_name || exit
		makepkg -si --noconfirm || error "Failed to build aur helper $aur_name!"
	fi
}

install_packages() {
	install_msg "Installing desktop applications..."

	install_aur_helper

	sed -e "/^#/d" -e "s/#.*//" ${HOME}/.config/yadm/pkglist-arch | while read pkg; do
		pac_install $pkg
	done

	# mpd requires systemd componemts
	if [ ! "$ARCH" = "obarun" ]; then
		pac_install dunst mpd mpc ncmpcpp
	fi

	pac_install mpv
}

install_aur_packages() {
	install_msg "Installing AUR packages..."

	command -v "simple-mtpfs" >/dev/null || pac_install simple-mtpfs
#	command -v "picom" >/dev/null || pac_install picom-ibhagwan-git
}

configure_video() {
	install_msg "Installing and configuring video drivers..."

	local ati=$(lspci | grep VGA | grep ATI)
	local nvidia=$(lspci | grep VGA | grep NVIDIA)
	local intel=$(lspci | grep VGA | grep Intel)
	local amd=$(lspci | grep VGA | grep AMD)

	if [ ! -z "$ati" ]; then
	    box2 'Ati graphics detected'
	    pac_install xf86-video-ati
	fi
	if [ ! -z "$nvidia" ]; then
	    box2 'Nvidia graphics detected'
	    pac_install xf86-video-nouveau
	fi
	if [ ! -z  "$intel" ]; then
	    box2 'Intel graphics detected'
	    pac_install xf86-video-intel libva-intel-driver
	fi
	if [ ! -z  "$amd" ]; then
	    box2 'AMD graphics detected'
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

finishing_up() {
	###################################
	# section includes patches from LARBS
	###################################

	# Most important command! Get rid of the beep!
	#sudo rmmod pcspkr
	box "Finishing touches..."

	echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

	# dbus UUID must be generated for Artix runit.
	[ -d "/var/lib/dbus" ] || sudo mkdir -p /var/lib/dbus
	sudo dbus-uuidgen >/dev/null | sudo tee /var/lib/dbus/machine-id

	# Use system notifications for Brave on Artix
	echo "export \$(dbus-launch)" >/dev/null | sudo tee /etc/profile.d/dbus.sh
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
refreshkeys 
update_system
install_packages
install_aur_packages
configure_video
finishing_up

install_msg "Done." 
