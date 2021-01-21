#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

PKGS=

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

xbps_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	sudo xbps-install -y "$@"
}

install_base_packages() {
	# Xorg
	PKGS+=" base-devel xorg-minimal xinit xauth xorg-server xf86-input-libinput" 
	PKGS+=" xf86-video-intel"
	PKGS+=" arandr xrdb xset xsetroot xprop xcalib xdg-utils"
	PKGS+=" xdo setxkbmap xmodmap bash-completion ccache ntfs-3g "
	PKGS+=" git curl wget xtools xsel wireless_tools"
	# PKGS+=" dcron" # lightweight cron daemon
	# PKGS+=" chrony" # ntp
	
	# for killall amongst others
	PKGS+=" psmisc"

	# Audio
	PKGS+=" alsa-utils"
	PKGS+=" alsa-plugins-pulseaudio pamixer pulsemixer"

	# Minimal bspwm apps
	PKGS+=" bspwm sxhkd kitty rofi polybar dunst geany pcmanfm firefox"
	PKGS+=" lxappearance vim mpd mpc ncmpcpp mpv w3m w3m-img neofetch"
	PKGS+=" htop zathura zathura-pdf-mupdf maim xclip feh"
	PKGS+=" file-roller zip unzip p7zip meld ghex gnome-calculator jq"
	PKGS+=" font-libertine-ttf noto-fonts-emoji arc-icon-theme"

	# Misc apps
	PKGS+=" bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
	PKGS+=" atool ImageMagick python3-Pillow xdotool xdpyinfo ffmpegthumbnailer"
    PKGS+=" cava ranger geoip"
	# PKGS+=" speedtest-cli geoip-data"

	# Additional fonts and themes
	PKGS+=" fonts-croscore-ttf gtk-engine-murrine"

	# System utilities
	PKGS+=" android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices
	
	# redshift
	PKGS+=" redshift"

	xbps_install $PKGS
}

configure_intel_video() {
	# Detect if we are on an Intel system
	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ $CPU_VENDOR = "GenuineIntel" ]; then
		install_msg "Installing Intel Video Acceleration"
		xbps_install xf86-video-intel libva-intel-driver
		install_msg "Install Intel Xorg config"
		# gets rid of screen tearing if not using compositor/wm does not have vsync
		sudo bash -c 'cat > /usr/share/X11/xorg.conf.d/20-intel.conf' << EOF
# /usr/share/X11/xorg.conf.d/20-intel.conf

Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
#   Option     "SwapbuffersWait"       "false"
   Option "DRI" "3"
   Option      "TearFree"     "true"
EndSection
EOF
	fi
}

configure_system() {
	# enable services
	dir="/etc/runit/runsvdir/default/"
	common_srcs="crond dbus elogind ntpd polkitd uuid"
	for svc in $common_srcs
	do
		if [ -d /etc/sv/$svc ] ; then
			install_msg "Enabling service: $svc"
			sudo ln -sf /etc/sv/$svc $dir
		fi
	done
	# configure fonts
	install_msg "Configuring system fonts config"
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/50-user.conf /etc/fonts/conf.d/
	# sudo ln -sf /usr/share/fontconfig/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/
}

cleanup() {
	# remove unnecessary services
	remove_svc="agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6 sshd"
	for svc in $remove_svc
	do
		if [ -d /var/service/$svc ] ; then
			install_msg "Removing $svc"
			sudo rm /var/service/$svc
		fi
	done
}

########
# main #
########

install_msg ""
install_msg "Installing VoidLinux..."
install_msg ""

install_msg ""
install_msg "Running symlinks to personal directories..."
. "$HOME/.config/yadm/_symlink.sh"

install_msg ""
install_msg "Updating xbps database..."
sudo xbps-install -Su

install_msg
install_msg "Installing base packages..."
install_base_packages

install_msg ""
install_msg "Installing and configuring intel gpu driver..."
configure_intel_video

install_msg ""
install_msg "Configuring system..."
configure_system

install_msg ""
install_msg "Finalizing and cleanup"
cleanup

install_msg ""
install_msg "Enabling ssh key..."
if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

install_msg ""
install_msg "Setting default wallpaper..."
if [ ! -f "$HOME/.fehbg" ] ; then
	cat > "$HOME/.fehbg" << EOF
#!/bin/sh
feh --no-fehbg --bg-fill $HOME/.config/wall.jpg
EOF
	chmod +x "$HOME/.fehbg"
fi

echo ""
echo ""
echo "============"
echo "= Finished ="
echo "============"
echo ""
echo "To use rootless Xorg, xorg-server needs to be compiled with elogind support."
echo "Compile: # './xbps-src pkg xorg-server -o elogind'"
echo "Install: # 'sudo xbps-install --force --repository=hostdir/binpkgs xorg-server'"
echo "Edit '/etc/X11/Xwapper.config' and change 'needs_root_rights' from 'yes' to 'no'"
echo ""
