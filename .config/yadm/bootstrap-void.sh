#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
ALL_OFF="\033[0m"

# REPO='https://alpha.de.repo.voidlinux.org'
# REPO='https://alpha.us.repo.voidlinux.org'
REPO='https://mirrors.servercentral.com/voidlinux'
# REPO='https://alpha.us.repo.voidlinux.org'

PKGLIST=$(sed -e "/^#/d" -e "s/#.*//" ${HOME}/.config/yadm/pkglist-void)

error() {
  printf "${BOLD}${RED}ERROR:${ALL_OFF}${BOLD} %s${ALL_OFF}\n" "$1" >&2
  exit 1
}

info() {
	printf "${BOLD}${GREEN}==>${ALL_OFF}${BOLD} %s${ALL_OFF}\n" "$1" ;
}

xbps_install() {
	sudo xbps-install -y -R ${REPO}/current -R ${REPO}/current/nonfree "$@"
}

install_base_packages() {
	xbps_install $PKGLIST || error "Failed installation."
}

configure_intel_video() {
	# Detect if we are on an Intel system
	CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ $CPU_VENDOR = "GenuineIntel" ]; then
		info "Installing Intel Video Acceleration"
		xbps_install intel-ucode xf86-video-intel intel-video-accel libva-intel-driver intel-media-driver linux-firmware-intel
		info "Install Intel Xorg config"
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

enable_services() {
	# enable services
	dir="/etc/runit/runsvdir/default/"

	# remove unnecessary services
	remove_svc="acpi agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6 dhcpcd sshd"
	for svc in $remove_svc
	do
		if [ -d /var/service/$svc ] ; then
			info "Removing service $svc"
			sudo rm /var/service/$svc
		fi
	done

	common_srcs="dhcpcd crond dbus elogind ntpd polkitd socklog-unix nanoklogd udevd runit-swap"
	for svc in $common_srcs
	do
		if [ -d /etc/sv/$svc ] && ! [ -d /var/service/$svc ] ; then
			info "Enabling service: $svc"
			sudo ln -sf /etc/sv/$svc $dir
		fi
	done

	grep socklog /etc/group >/dev/null && sudo usermod -a -G socklog "$USER"

	# configure fonts
	info "Configuring system fonts config"
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/50-user.conf /etc/fonts/conf.d/
	# sudo ln -sf /usr/share/fontconfig/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/

	sudo xbps-reconfigure -f fontconfig
}

cleanup() {
	info "Change shell to zsh"
	chsh -s $(which zsh) "$USER"

	#info "Enabling ssh key..."
	#if [ -f ${HOME}/.ssh/id_rsa ] ; then
	#	eval "$(ssh-agent -s)"
	#	ssh-add ${HOME}/.ssh/id_rsa
	#fi

	info "Set initial desktop wallpaper..."
	if [ ! -f "${HOME}/wall.pmg" ] ; then
		cat > "${HOME}/.fehbg" << EOF
#!/bin/sh
feh --no-fehbg --bg-fill ${HOME}/.config/wall.png
EOF
		chmod +x "${HOME}/.fehbg"
	fi
}

########
# main #
########

info "************************"
info "Installing VoidLinux...."
info "************************"

info "Running symlinks to personal directories..."
if [ -f "${HOME}/.config/yadm/_symlink.sh" ]; then
	. "${HOME}/.config/yadm/_symlink.sh" || error "Failed to create symlinks!"
fi

info "Updating xbps database..."
echo y | sudo xbps-install -Su || error "Failed to update system!"

info "Installing base packages..."
install_base_packages || error "Failed to install base packages!"

info "Installing and configuring intel gpu driver..."
configure_intel_video || error "Failed to set video drivers!"

info "Enabling runit services system..."
enable_services || error "Faile enabling runit service!"

info "Finalizing and cleanup"
cleanup

info "============"
info "= Finished ="
info "============"
