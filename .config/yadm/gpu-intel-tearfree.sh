#!/usr/bin/env bash

sudo pacman -S --needed xf86-video-ati
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/20-intel.conf >/dev/null <<'EOF'
Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   Option      "TearFree"     "true"
EndSection
EOF
