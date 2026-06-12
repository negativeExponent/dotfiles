#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

######################
## Configuration    ##
######################

readonly SCRIPT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yadm"
readonly ARCH="${1:-arch}"

INIT="systemd"

######################
## Utility Functions #
######################

error() {
	printf "%s\n" "$1" >&2
	exit 1
}

check_root() {
	if [[ "$EUID" -eq 0 ]]; then
		error "Please do not run this script as root (e.g. using sudo)"
	fi
}

######################
## UI Functions     ##
######################

install_msg() {
	local title="$1"
	echo -e "\e[1;32m$title\e[0m"
}

######################
## Package Management
######################

pac_install() {
	yay -S --noconfirm --needed "$@"
}

install_needed() {
	install_msg "Installing base dependencies..."
	sudo pacman -S --needed --noconfirm \
		git wget curl man-db neovim base-devel ccache pciutils
}

install_aur_helper() {
	local aur_name="yay"

	if command -v "$aur_name" >/dev/null 2>&1; then
		install_msg "AUR helper already installed: $aur_name"
		return 0
	fi

	install_msg "Installing AUR helper: $aur_name..."

	local tmp_dir="/tmp/$aur_name"
	[[ -d "$tmp_dir" ]] && rm -rf "$tmp_dir"

	git clone "https://aur.archlinux.org/yay-bin.git" "$tmp_dir" || \
		error "Failed to clone $aur_name from GitHub"

	cd "$tmp_dir" || error "Failed to enter $tmp_dir"
	makepkg -si --noconfirm || error "Failed to build AUR helper: $aur_name"
}

install_packages() {
	install_msg "Installing desktop applications..."

	# Ensure AUR helper is available
	install_aur_helper

	# Install packages from list
	if [[ -f "${SCRIPT_DIR}/pkglist-arch" ]]; then
		mapfile -t PKGS < <(
            sed \
                -e 's/#.*//' \
                -e '/^[[:space:]]*$/d' \
                "${SCRIPT_DIR}/pkglist-arch"
        )
		pac_install "${PKGS[@]}"
	else
		error "Package list not found: ${SCRIPT_DIR}/pkglist-arch"
	fi
}

install_aur_packages() {
	install_msg "Installing AUR packages..."
	# simple-mtpfs for MTP device access
	command -v simple-mtpfs >/dev/null 2>&1 || pac_install simple-mtpfs
}

######################
## System Setup      ##
######################

detect_system() {
	if [[ "$ARCH" == "artix" ]]; then
		if pacman -Qk openrc >/dev/null 2>&1; then
			INIT="openrc"
		elif pacman -Qk runit >/dev/null 2>&1; then
			INIT="runit"
		elif pacman -Qk s6 >/dev/null 2>&1; then
			INIT="s6"
		elif pacman -Qk dinit >/dev/null 2>&1; then
			INIT="dinit"
		fi
	fi
	install_msg "Detected system: $ARCH (init: $INIT)"
}

create_symlinks() {
	install_msg "Creating symlinks to personal directories..."

	if [[ -f "${SCRIPT_DIR}/_symlink.sh" ]]; then
		# shellcheck source=/dev/null
		. "${SCRIPT_DIR}/_symlink.sh"
	else
		error "Symlink script not found: ${SCRIPT_DIR}/_symlink.sh"
	fi
}

pretty_pacmanconf() {
	install_msg "Configuring pacman (colors, parallel downloads)..."

	# Enable color output
	grep -q "^Color" /etc/pacman.conf || \
		sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf

	# Add ILoveCandy animation
	grep -q "ILoveCandy" /etc/pacman.conf || \
		sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

	# Set parallel downloads
	grep -q "^ParallelDownloads" /etc/pacman.conf || \
		sudo sed -i "s/.*ParallelDownloads.*/ParallelDownloads = 5/" /etc/pacman.conf

	CORES=$(nproc)

	if (( CORES <= 4 )); then
		JOBS=2
	else
		JOBS=$CORES
	fi

	sudo sed -i \
        -e "s/-j[0-9]\+/-j${JOBS}/" \
        -e "/^#MAKEFLAGS/s/^#//" \
        /etc/makepkg.conf
}

refreshkeys() {
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		install_msg "Refreshing Arch keyring (systemd)..."
		sudo pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
		;;
	*)
		if [[ "$ARCH" == "artix" ]]; then
			install_msg "Enabling Arch repositories and updating keyrings..."
			if [[ -f "${SCRIPT_DIR}/artix_enable_archlinux_repo.sh" ]]; then
				# shellcheck source=/dev/null
				. "${SCRIPT_DIR}/artix_enable_archlinux_repo.sh"
			else
				error "Artix repo script not found: ${SCRIPT_DIR}/artix_enable_archlinux_repo.sh"
			fi
		fi
		;;
	esac
}

update_system() {
	install_msg "Updating system (this may take a while)..."
	sudo pacman -Syu --noconfirm
}

######################
## Hardware Setup    ##
######################

configure_video() {
	install_msg "Detecting and configuring video drivers..."

	GPU=$(lspci | grep -i "vga")
	case "$GPU" in
    *NVIDIA*)
		install_msg "NVIDIA graphics detected"
		pac_install xf86-video-nouveau
		;;
    *Intel*)
		install_msg "Intel graphics detected"
		pac_install mesa mesa-utils
		;;
    *AMD*)
		install_msg "AMD graphics detected"
		pac_install mesa mesa-utils
		;;
	esac
}

finishing_up() {
	install_msg "Applying final system tweaks..."

	# Disable PC speaker beep
	echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf >/dev/null

	# Generate dbus UUID (required for Artix runit)
	local dbus_dir="/var/lib/dbus"
	[[ -d "$dbus_dir" ]] || sudo mkdir -p "$dbus_dir"
	[[ -f "${dbus_dir}/machine-id" ]] || \
        dbus-uuidgen | sudo tee "${dbus_dir}/machine-id" >/dev/null

	# Configure dbus for system notifications (Artix + Brave)
	if [[ "$ARCH" == "artix" ]]; then
		echo 'export $(dbus-launch)' \
            | sudo tee /etc/profile.d/dbus.sh >/dev/null
	fi
}

######################
## Main Execution   ##
######################

main() {
	check_root
	detect_system
	install_needed

	pretty_pacmanconf

	refreshkeys
	update_system
	install_packages
	install_aur_packages
	configure_video
	finishing_up

	create_symlinks

	install_msg "Bootstrap complete!"
}

# Run main function
main "$@"
