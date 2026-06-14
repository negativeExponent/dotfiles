#!/bin/env bash
set -e

is_artix() {
    [[ -f /etc/artix-release ]] || return 1
}

enable_repo_if_missing() {
    local repo="$1"

    if ! grep -q "^\[$repo\]" /etc/pacman.conf; then
        echo "Enabling [$repo] repository..."
        echo "
[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee -a /etc/pacman.conf >/dev/null
    fi
}

main() {
    # 1. Must be Artix
    is_artix || {
        echo "Error: This script requires Artix Linux." >&2
        exit 1
    }

    # 2. Ensure support package exists
    sudo pacman --noconfirm --needed -S artix-keyring artix-archlinux-support

    # 3. Enable required repos if missing
    enable_repo_if_missing extra
    enable_repo_if_missing multilib

    # 4. Sync + keyring
    sudo pacman -Sy
    sudo pacman-key --populate archlinux
}

main
