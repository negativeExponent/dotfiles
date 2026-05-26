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
readonly INIT_DEFAULT="systemd"

INIT="$INIT_DEFAULT"

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

_print_edge() {
	local title="$1"
	printf '%*s\n' "${#title}" | tr ' ' '*'
}

box() {
	local title=" $1 "
	local edge
	edge=$(_print_edge "$title")
	echo "$edge"
	echo -e "\e[1;32m$title\e[0m"
	echo "$edge"
}

box_top() {
	local title=" $1 "
	local edge
	edge=$(_print_edge "$title")
	echo "$edge"
	echo -e "\e[1;32m$title\e[0m"
}

box_plain() {
	local title=" $1 "
	echo -e "\e[1;32m$title\e[0m"
}

box_bottom() {
	local title=" $1 "
	local edge
	edge=$(_print_edge "$title")
	echo -e "\e[1;32m$title\e[0m"
	echo "$edge"
}

install_msg() {
	box "$1"
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

	git clone "https://github.com/Jguer/yay.git" "$tmp_dir" || \
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
		while IFS= read -r pkg || [[ -n "$pkg" ]]; do
			# Skip comments and empty lines
			[[ "$pkg" =~ ^[[:space:]]*# ]] && continue
			[[ -z "${pkg// }" ]] && continue
			pac_install "$pkg"
		done < <(sed -e '/^[[:space:]]*#/d' -e 's/#.*//' "${SCRIPT_DIR}/pkglist-arch")
	else
		error "Package list not found: ${SCRIPT_DIR}/pkglist-arch"
	fi

	# Install init-system specific packages
	if [[ "$ARCH" != "obarun" ]]; then
		pac_install dunst mpd mpc ncmpcpp
	fi

	pac_install mpv
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

	# Use all CPU cores for compilation
	sudo sed -i \
		-e "s/-j2/-j$(nproc)/" \
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
			box "Enabling Arch repositories and updating keyrings..."
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

	local ati nvidia intel amd

	# Detect graphics hardware
	ati=$(lspci 2>/dev/null | grep -i "VGA.*ATI" || true)
	nvidia=$(lspci 2>/dev/null | grep -i "VGA.*NVIDIA" || true)
	intel=$(lspci 2>/dev/null | grep -i "VGA.*Intel" || true)
	amd=$(lspci 2>/dev/null | grep -i "VGA.*AMD" || true)

	# Install appropriate drivers
	if [[ -n "$ati" ]]; then
		box_plain "ATI graphics detected"
		pac_install xf86-video-ati
	fi

	if [[ -n "$nvidia" ]]; then
		box_plain "NVIDIA graphics detected"
		pac_install xf86-video-nouveau
	fi

	if [[ -n "$intel" ]]; then
		box_plain "Intel graphics detected"
		pac_install xf86-video-intel libva-intel-driver
		_configure_intel_xorg
	fi

	if [[ -n "$amd" ]]; then
		box_plain "AMD graphics detected"
		pac_install xf86-video-amdgpu
	fi
}

_configure_intel_xorg() {
	# Configure Intel graphics to prevent screen tearing
	local xorg_dir="/usr/share/X11/xorg.conf.d"
	local xorg_conf="${xorg_dir}/20-intel.conf"

	sudo mkdir -p "$xorg_dir"
	sudo tee "$xorg_conf" >/dev/null << 'EOF'
# /usr/share/X11/xorg.conf.d/20-intel.conf
# Prevents screen tearing when not using a compositor with vsync

Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   Option      "TearFree"     "true"
EndSection
EOF
}

finishing_up() {
	box "Applying final system tweaks..."

	# Disable PC speaker beep
	echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf >/dev/null

	# Generate dbus UUID (required for Artix runit)
	local dbus_dir="/var/lib/dbus"
	[[ -d "$dbus_dir" ]] || sudo mkdir -p "$dbus_dir"
	dbus-uuidgen | sudo tee "${dbus_dir}/machine-id" >/dev/null

	# Configure dbus for system notifications (Artix + Brave)
	echo 'export $(dbus-launch)' | sudo tee /etc/profile.d/dbus.sh >/dev/null
}

######################
## Main Execution   ##
######################

main() {
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

	install_msg "Bootstrap complete!"
}

# Run main function
main "$@"
