#!/bin/env bash

enable_arch_repo() {
    if ! grep -q "^\[universe\]" /etc/pacman.conf; then
        echo "Enabling ArchLinux Repositories..."
        echo "
[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" | sudo tee -a /etc/pacman.conf
	fi
	sudo pacman --noconfirm --needed -Sy \
		artix-keyring artix-archlinux-support
	for repo in extra community; do
		grep -q "^\[$repo\]" /etc/pacman.conf ||
			echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee -a /etc/pacman.conf
	done
	sudo pacman -Sy
	sudo pacman-key --populate archlinux
}

enable_arch_repo
