#!/usr/bin/env bash

sudo pacman -S --needed xf86-video-ati
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/20-radeon.conf >/dev/null <<'EOF'
Section "Device"
    Identifier "AMD Radeon"
    Driver "radeon"
    Option "TearFree" "true"
EndSection
EOF
