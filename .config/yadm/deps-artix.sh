#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

ARCH="$1"

PKGS=""
RUNSVDIR="/etc/runit/runsvdir/default"



echo ""
echo -e "\e[34mDetected system = $ARCH\e[0m"

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

# Creates a symlink for item1 to item2, deleting destination if it exists
link() {
	if [ -d $1 ] ; then
		status='!'
		[ ! -e $2 ] || rm -rf $2
		ln -sfv $1 $2 && status='ok'
		#install_msg "$status - Symlinking $1 to $2"
	fi
}

pac_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	yay -S --needed --noconfirm "$@"
}

get_packages() {
	# Xorg
	PKGS="${PKGS} base-devel xorg-server xorg-xinit xorg-xauth xf86-input-libinput"
	PKGS="${PKGS} xf86-video-intel"
	PKGS="${PKGS} arandr xorg-xrdb xorg-xset xorg-xsetroot xorg-xprop xcalib xdg-utils"
	PKGS="${PKGS} xdo xorg-setxkbmap xorg-xmodmap bash-completion ccache ntfs-3g "
	PKGS="${PKGS} git curl wget xsel wireless_tools"

	# Audio
	PKGS="${PKGS} alsa-utils"
	# PKGS="${PKGS} pulseaudio-alsa pamixer pulsemixer"
	# [ "$ARCH" = "obarun" ] && PKGS="${PKGS} pulseaudio-66serv"

	# Minimal bspwm apps
	PKGS="${PKGS} bspwm sxhkd kitty rofi dunst geany pcmanfm"
	PKGS="${PKGS} lxappearance perl vim"
	PKGS="${PKGS} mpv w3m neofetch"
	PKGS="${PKGS} htop zathura zathura-pdf-mupdf maim xclip feh xcompmgr"
	PKGS="${PKGS} xarchiver zip unzip p7zip meld ghex gnome-calculator jq"
	PKGS="${PKGS} ttf-linux-libertine noto-fonts-emoji arc-icon-theme"

	[ "$ARCH" = "obarun" ] || PKGS="${PKGS} mpd mpc ncmpcpp" # obarun does not have libsystemd, so these will fail to install

	! pacman -Qk polybar >/dev/null || PKGS="${PKGS} polybar"

	# Misc apps
	PKGS="${PKGS} bc highlight fzf atool mediainfo poppler youtube-dl ffmpeg"
	PKGS="${PKGS} atool imagemagick python-pillow xdotool xorg-xdpyinfo ffmpegthumbnailer ranger"
	PKGS="${PKGS} speedtest-cli"
	PKGS="${PKGS} numlockx"

	# Additional fonts and themes
	PKGS="${PKGS} ttf-croscore gtk-engine-murrine"

	# System utilities
	PKGS="${PKGS} android-tools gvfs gvfs-mtp polkit-gnome gnome-keyring" # automounting of usb and android devices

 	# Runit services
	# [ "$ARCH" != "artix" ] || PKGS="${PKGS} haveged-runit cronie-runit ntp-runit"
}

install_networkmanager() {
	# THIS IS INCOMPLETE AND UNUSED FOR ARTIX-RUNIT
	# NO PLAN TO USE THIS FOR NOW, KEEPING IT JUST INCASE
	pac_install NetworkManager

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

install_samba() {
    if [ "$ARCH" = "artix" ]; then
        pac_install samba-runit gvfs-smb
    elif [ "$ARCH" = "obarun" ]; then
        pac_install samba-66serv gvfs-smb
    fi
    [ -d /etc/samba ] || sudo mkdir /etc/samba 2>/dev/null
    sudo bash -c 'cat > /etc/samba/smb.conf' << EOF
[global]
workgroup = WORKGROUP
server string = Samba Server
server role = standalone server
log file = /var/log/samba/smb.log
log level = 0
max log size = 300
map to guest = Bad User
[homes]
comment = Home Directories
browseable = no
writable = yes
[printers]
comment = All Printers
path = /usr/spool/samba
guest ok = yes
printable = yes
browseable = yes
writable = no
[Anonymous]
# comment = Public share folder
browseable = yes
guest ok = yes
read only = no
create mask = 777
writeable = yes
path = /mnt/data/Public
force user = nobody
EOF
}

install_printer() {
    local pkg="cups cups-pdf system-config-printer"
    [ "$ARCH" = "artix" ] && pkg="${pkg} cups-runit"
    [ "$ARCH" = "obarun" ] && pkg="${pkg} cupsd-66serv"
    pac_install $pkg
}

configure_system() {
    # enable static DNS when using DHCP
    if [ -f /etc/dhcpcd.conf ]; then
        grep "static domain_name_servers" /etc/dhcpcd.conf || echo "static domain_name_servers=1.1.1.1 1.0.0.1" | sudo tee -a /etc/dhcpcd.conf
    fi
    # enable runit services
    if [ "$ARCH" = "artix" ]; then
        svc_common="cronie dbus dhcpcd elogind haveged ntpd udevd smbd nmbd cupsd"
        for svc in $svc_common
        do
            if [ -d /etc/runit/sv/$svc ] ; then
                install_msg "Enabling service: $RUNSVDIR/$svc"
                sudo ln -sf "/etc/runit/sv/$svc" "$RUNSVDIR/$svc"
            fi
        done
    fi
}

configure_intel_video() {
	# Detect if we are on an Intel system
	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ $CPU_VENDOR = "GenuineIntel" ]; then
		install_msg "Installing Intel Video Acceleration"
		pac_install xf86-video-intel libva-intel-driver
		install_msg "Install Intel Xorg config"
		# gets rid of screen tearing if not using compositor/wm does not have vsync
		sudo mkdir -p /usr/share/X11/xorg.conf.d/
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
	mkdir -p $HOME/.cache
	mkdir -p $HOME/.config

	link /mnt/data/yay $HOME/.cache/yay

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
	if [ "$ARCH" = "artix" ]; then
		remove_svc="agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6 sshd"
		for svc in $remove_svc
		do
			if [ -d $RUNSVDIR/$svc ] ; then
				install_msg "Removing $RUNSVDIR/$svc"
				sudo rm $RUNSVDIR/$svc
			fi
		done
	fi
}

echo -e "\e[31mChecking permissions...\e[0m"
if [ "$EUID" -eq 0 ]; then
	echo "Please do not run this script as root (e.g. using sudo)"
	exit
fi

# Place these system tweaks ahead here to take advantage of threading
# when compiling from AUR
# use max cores/thread the processor has
install_msg "Use max cores/threads when compiling."
num=$(grep -c ^processor /proc/cpuinfo)
sudo sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${num}\"/g" /etc/makepkg.conf

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
install_msg "Make paacman and yay colorful."
grep "^Color" /etc/pacman.conf >/dev/null || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

install_msg "Creating symlinks for some common applications."
create_symlinks

if ! command -v yay >/dev/null; then
	install_msg "Yay aur helper not found. We will compile this from AUR."
	! command -v yay >/dev/null && sudo pacman -S --needed --noconfirm git ccache
	install_msg "Fetching yay-bin"
	[ -d /tmp/yay-bin ] && rm -rf /tmp/yay-bin
	git clone --depth 1 https://aur.archlinux.org/yay-bin /tmp/yay-bin
	cd /tmp/yay-bin
	makepkg -si --noconfirm
	if ! command -v yay >/dev/null; then
		echo "Failed to install yay-bin."
		exit 1
	fi
fi

install_msg "Syncing pacman database"
yay -Syy --noconfirm

# Get a list of packages to install
get_packages

# Install selected packages
pac_install $PKGS

# Install aur packages
install_msg "Installing aur packages."
command -v "polybar" >/dev/null || pac_install "polybar"
# command -v "cava" >/dev/null || pac_install "cava-git"
command -v "brave" >/dev/null || pac_install "brave-bin"

install_msg "Configure Intel Video"
configure_intel_video

install_msg "Configuring new system"
configure_system

install_msg "Installing samba"
install_samba

install_msg "Installing printer"
install_printer

install_msg "Finalizing and cleanup"
cleanup

if [ -f $HOME/.ssh/id_rsa ] ; then
	eval "$(ssh-agent -s)"
	ssh-add $HOME/.ssh/id_rsa
fi

echo "Finished."
echo ""
