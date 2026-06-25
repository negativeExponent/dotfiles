#!/usr/bin/env bash

set -euo pipefail

# Only run on Artix Linux
grep -qi '^ID=artix$' /etc/os-release || exit 0

PACMAN_CONF="/etc/pacman.conf"

printf "\033[32m==>\033[0m Enabling Arch Linux repositories...\n"

# Install required support packages
sudo pacman -Sy --noconfirm --needed \
    artix-keyring \
    artix-archlinux-support \
    >/dev/null

# Add missing repositories
for repo in extra multilib; do
    if ! grep -qE "^\[$repo\]" "$PACMAN_CONF"; then
        printf '\n[%s]\nInclude = /etc/pacman.d/mirrorlist-arch\n' "$repo" |
            sudo tee -a "$PACMAN_CONF" >/dev/null

        echo "  • Added [$repo]"
    fi
done

# Refresh package databases
sudo pacman -Sy >/dev/null

# Import Arch Linux signing keys
sudo pacman-key --populate archlinux >/dev/null

#printf "\033[32m==>\033[0m Done.\n"
