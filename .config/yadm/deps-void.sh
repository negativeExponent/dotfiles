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

# Creates a symlink for item1 to item2, deleting destination if it exists
link() {
	if [ -d $1 ] ; then
		status='!'
		[ ! -e $2 ] || rm -rf $2
		ln -sf $1 $2 && status='ok'
		install_msg "$status - Symlinking $1 to $2"
	fi
}

xbps_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	sudo xbps-install -y "$@"
}

get_packages() {
	# Xorg
	PKGS="${PKGS} base-devel xorg-minimal xinit xauth xorg-server xf86-input-libinput" 
	PKGS="${PKGS} xf86-video-intel"
	PKGS="${PKGS} arandr xrdb xset xsetroot xprop xcalib xdg-utils"
	PKGS="${PKGS} xdo setxkbmap xmodmap bash-completion ccache ntfs-3g "
	PKGS="${PKGS} git curl wget xtools xsel wireless_tools"
	PKGS="${PKGS} dcron" # lightweight cron daemon
	PKGS="${PKGS} chrony" # ntp

	# Audio
	PKGS="${PKGS} alsa-utils alsa-plugins-pulseaudio"
	PKGS="${PKGS} pamixer pulsemixer"

	# Minimal bspwm apps
	PKGS="${PKGS} bspwm sxhkd kitty rofi polybar dunst geany pcmanfm firefox"
	PKGS="${PKGS} lxappearance vim mpd mpc ncmpcpp mpv w3m w3m-img neofetch"
	PKGS="${PKGS} htop zathura zathura-pdf-mupdf maim xclip feh"
	PKGS="${PKGS} file-roller zip unzip p7zip meld ghex gnome-calculator jq"
	PKGS="${PKGS} font-libertine-ttf noto-fonts-emoji arc-icon-theme"

	# Misc apps
	PKGS="${PKGS} bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
	PKGS="${PKGS} atool ImageMagick python3-Pillow xdotool xdpyinfo ffmpegthumbnailer"
    PKGS="${PKGS} cava ranger"
	PKGS="${PKGS} speedtest-cli geoip geoip-data"

	# Additional fonts and themes
	PKGS="${PKGS} fonts-croscore-ttf gtk-engine-murrine"

	# System utilities
	PKGS="${PKGS} android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices

	# DBus
	PKGS="${PKGS} elogind"
	PKGS="${PKGS} dbus-elogind dbus-elogind-libs dbus-elogind-x11" 	# required for rootless xorg
}

install_networkmanager() {
	xbps_install NetworkManager

	sudo sv down dhcpcd
	sudo sv down wpa_supplicant
	sudo rm /var/service/dhcpcd
	sudo rm /var/service/wpa_supplicant
	sudo ln -sf /etc/sv/dbus /var/service/
	sudo ln -sf /etc/sv/NetworkManager /var/service/
	sudo sv up NetworkManager

	echo 'polkit.addRule(function(action, subject) {
  if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.isInGroup("network")) {
	return polkit.Result.YES;
  }
});' | sudo tee /etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules
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

# symlinks to commonly used folders/apps

create_symlinks() {
	# symlinks to HOME
	link /mnt/data/Documents $HOME/Documents
	link /mnt/data/Downloads $HOME/Downloads
	link /mnt/data/Pictures $HOME/Pictures

	link /mnt/storage/Music $HOME/Music

	link /mnt/data/myfiles/.mozilla $HOME/.mozilla
	link /mnt/data/myfiles/#ssh_key/.ssh $HOME/.ssh

	# symlinks to .config
	link /mnt/data/myfiles/BraveSoftware $HOME/.config/BraveSoftware
	link /mnt/data/retroarch $HOME/.config/retroarch
	link /mnt/data/myfiles/transmission-daemon $HOME/.config/transmission-daemon
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

install_msg "Updating and installing packages."
sudo xbps-install -Su

# Get a list of packages to install
get_packages

# Install selected packages
xbps_install $PKGS

install_msg "Configure Intel Video"
configure_intel_video

install_msg "Configuring new system"
configure_system

install_msg "Creating application symlinks"
create_symlinks

install_msg "Finalizing and cleanup"
cleanup

if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

# switch shell to zsh
#chsh -s /bin/zsh $USERNAME
#exec zsh

echo "Finished."
echo ""
echo "To use rootless Xorg, xorg-server needs to be compiled with elogind support."
echo "Compile: # './xbps-src pkg xorg-server -o elogind'"
echo "Install: # 'sudo xbps-install --force --repository=hostdir/binpkgs xorg-server'"
echo "Edit '/etc/X11/Xwapper.config' and change 'needs_root_rights' from 'yes' to 'no'"
echo ""
