#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -Eeuo pipefail

######################
## Configuration
######################

readonly GREEN="\033[32m"
readonly RED="\033[31m"
readonly ALL_OFF="\033[0m"

readonly SCRIPT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yadm"
readonly DISTRO="${1:-arch}"

# arch (systemd)
# dinit
# openrc
# runit
SYSTEM_INIT="systemd"

######################
## Utility Functions
######################

error() {
	printf "${RED}ERROR:${ALL_OFF} %s${ALL_OFF}\n" "$1" >&2
	exit 1
}

check_permissions() {
    [[ $EUID -ne 0 ]] \
        || error "Please do not run this script as root"

    sudo -v \
        || error "Failed to obtain sudo privileges"
}

######################
## UI Functions     
######################

install_msg() {
	local title="==> $1"
	printf "${GREEN}==>${ALL_OFF} %s${ALL_OFF}\n" "$1" ;
}

######################
## Package Management
######################

pac_install() {
	yay -S --noconfirm --needed "$@"
}

######################
## Helper
######################

_install_aur_helper() {
	local aur_name="yay"

	command -v "$aur_name" >/dev/null 2>&1 && {
		# install_msg "AUR helper already installed: $aur_name"
		return 0
	}

	install_msg "Installing AUR helper: $aur_name..."

	local tmp_dir=$(mktemp -d) || error "Failed to create temp dir"

	git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir" \
        || error "Failed to clone $aur_name"

	cd "$tmp_dir" || error "Failed to enter temp dir"

	makepkg -si --noconfirm \
        || error "Failed to build $aur_name"

	cd - >/dev/null 2>&1
	rm -rf "$tmp_dir"
}

######################
## Installation Steps
######################
pretty_pacmanconf() {
	install_msg "Configuring pacman (colors, parallel downloads)..."

	grep -q "^Color" /etc/pacman.conf || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
	grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
	grep -q "^ParallelDownloads" /etc/pacman.conf || sudo sed -i "s/.*ParallelDownloads.*/ParallelDownloads = 5/" /etc/pacman.conf

	local jobs
	jobs=$(nproc)

	sudo sed -i \
        -e "s/-j[0-9]\+/-j${jobs}/" \
        -e "/^#MAKEFLAGS/s/^#//" \
        /etc/makepkg.conf
}

detect_system() {
	if [[ "$DISTRO" == "artix" ]]; then
		if pacman -Q openrc >/dev/null 2>&1; then SYSTEM_INIT="openrc"
		elif pacman -Q runit >/dev/null 2>&1; then SYSTEM_INIT="runit"
		elif pacman -Q s6 >/dev/null 2>&1; then SYSTEM_INIT="s6"
		elif pacman -Q dinit >/dev/null 2>&1; then SYSTEM_INIT="dinit"
		fi
		install_msg "Detected system: $DISTRO (init: $SYSTEM_INIT)"
	fi
}

prepare_repositories() {
    case "$DISTRO" in
        artix)
            . "${SCRIPT_DIR}/enable_arch_repo.sh"
            ;;
        *)
            install_msg "Refreshing Arch keyring..."
            sudo pacman -Sy --noconfirm archlinux-keyring >/dev/null
            ;;
    esac

    install_msg "Updating system..."
    sudo pacman -Syu --noconfirm
}

install_packages() {
	local base_pkgs=(
		git
		wget
		curl
		man-db
		man-pages
		neovim
		base-devel
		ccache
		pciutils
	)
	local extra_pkgs=()

	install_msg "Installing desktop applications..."

	# Ensure AUR helper is available
	_install_aur_helper

	# Install packages from list
	if [[ -f "${SCRIPT_DIR}/pkglist-arch" ]]; then
        mapfile -t extra_pkgs < <(
			sed \
				-e 's/[[:space:]]*#.*//' \
				-e '/^[[:space:]]*$/d' \
				"${SCRIPT_DIR}/pkglist-arch"
		)
	else
		error "Package list not found: ${SCRIPT_DIR}/pkglist-arch"
	fi

	local pkgs=("${base_pkgs[@]}")
	pkgs+=("${extra_pkgs[@]}")

	pac_install "${pkgs[@]}"
}

######################
## System Setup      ##
######################

create_symlinks() {
	install_msg "Creating symlinks to personal directories..."

	if [[ -f "${SCRIPT_DIR}/_symlink.sh" ]]; then
		. "${SCRIPT_DIR}/_symlink.sh"
	else
		error "Symlink script not found: ${SCRIPT_DIR}/_symlink.sh"
	fi
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
	if [[ "$DISTRO" == "artix" ]]; then
		echo 'export $(dbus-launch)' \
            | sudo tee /etc/profile.d/dbus.sh >/dev/null
	fi
}

######################
## Main Execution   ##
######################

main() {
	check_permissions

	pretty_pacmanconf
	detect_system
	prepare_repositories
	install_packages
	create_symlinks
	finishing_up

	install_msg "Done."
}

main "$@"
