#!/bin/env bash

enable_arch_repo() {
    if ! grep -q "^\[universe\]" /etc/pacman.conf; then
        install_msg "Enabling ArchLinux Repositories..."
        echo "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" | sudo tee -a /etc/pacman.conf
	fi
	sudo pacman --noconfirm --needed -Sy \
		artix-keyring artix-archlinux-support >/dev/null 2>&1
	for repo in extra community; do
		grep -q "^\[$repo\]" /etc/pacman.conf ||
			echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee -a /etc/pacman.conf
	done
	sudo pacman -Sy >/dev/null 2>&1
	sudo pacman-key --populate archlinux >/dev/null 2>&1
}

enable_arch_repo
