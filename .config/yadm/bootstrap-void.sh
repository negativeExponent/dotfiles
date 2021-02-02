#!/bin/env bash

# My not-so minimal bspwm config!!!
# This configuration is specifically targetted for my needs. Feel free to modify as you
# see fit for your system.
# USE AT YOUR OWN RISK! I will not be held responsible for any damages or pain from using this
# config.

set -e

# REPO='https://alpha.de.repo.voidlinux.org'
# REPO='https://alpha.us.repo.voidlinux.org'
# REPO='https://mirrors.servercentral.com/voidlinux'
# REPO='https://alpha.us.repo.voidlinux.org'
# REPO='https://mirror.clarkson.edu/voidlinux'
# REPO='https://mirror.yandex.ru/mirrors/voidlinux'
REPO='https://ftp.swin.edu.au/voidlinux'

PKGS=
INSTALL_TYPE="MINIMAL" 

install_msg() {
	echo -e "\e[32m$@\e[0m"
}

xbps_install() {
	echo -e "\e[35mInstalling: $@...\e[0m"
	sudo xbps-install -Sy -R ${REPO}/current -R ${REPO}/current/nonfree "$@"
}

install_base_packages() {
	local PKGS=''
	# misc
	PKGS+='base-devel '
	PKGS+='ccache '
	PKGS+='git '
	PKGS+='curl '
	PKGS+='wget '
	PKGS+='arandr '
	# xorg
	PKGS+='xorg-minimal '
	PKGS+='xinit '
	PKGS+='xrdb '
	PKGS+='xrandr '
	PKGS+='xsetroot '
	
	PKGS+='intel-video-accel '
	PKGS+='mesa-vaapi '
	PKGS+='mesa-vdpau '
	
	# audio
	PKGS+='alsa-utils '
	PKGS+='pulseaudio '
	PKGS+='pulsemixer '
	# wm
	PKGS+='bspwm '
	PKGS+='sxhkd '
	PKGS+='polybar '
	PKGS+='rofi '
	PKGS+='kitty '
	PKGS+='dunst '
	PKGS+='geany '				# gtk text editor
	PKGS+='pcmanfm '			# gtk file manager
	PKGS+='mpd mpc ncmpcpp '    # music player
	PKGS+='mpv '				# video player
	# apps
	PKGS+='lxappearance '		
	PKGS+='feh '				# wallpaper setter
	PKGS+='gnome-calculator '
	PKGS+='firefox '
	PKGS+='maim '				# screenshot
	PKGS+='gvfs '
	PKGS+='gvfs-mtp '
	PKGS+='android-tools '
	PKGS+='polkit-gnome '
	PKGS+='gnome-keyring '
	PKGS+='gtk-engine-murrine '
	PKGS+='picom '
	PKGS+='redshift '
	# themes, fonts
	PKGS+='arc-icon-theme '
	PKGS+='fonts-croscore-ttf '
	PKGS+='font-libertine-ttf '
	PKGS+='noto-fonts-emoji '
	PKGS+='dejavu-fonts-ttf '
	# compression/decompression
	PKGS+='xarchiver '
	PKGS+='zip '
	PKGS+='unzip '
	PKGS+='p7zip '
	# polybar module optional apps
	PKGS+='yad '				# calendar popup
	PKGS+='htop '
	PKGS+='neofetch '			# fancy terminal
	PKGS+='w3m-img '			# weather widget
	# services
	PKGS+='dbus '
	PKGS+='dbus-x11 '
	PKGS+='elogind '
	PKGS+='NetworkManager '
	PKGS+='cronie '
	PKGS+='openntpd '
	PKGS+='haveged '
	PKGS+='socklog-void '
	PKGS+='vsv '
	# killall
	PKGS+='psmisc '

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

	# remove unnecessary services
	remove_svc="agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6 dhcpcd sshd"
	for svc in $remove_svc
	do
		if [ -d /var/service/$svc ] ; then
			install_msg "Removing $svc"
			sudo rm /var/service/$svc
		fi
	done

	common_srcs="NetworkManager crond dbus elogind ntpd polkitd uuid socklog-unit nanoklogd"
	for svc in $common_srcs
	do
		if [ -d /etc/sv/$svc ] ; then
			install_msg "Enabling service: $svc"
			sudo ln -sf /etc/sv/$svc $dir
		fi
	done

	cat /etc/group | grep socklog >/dev/null && sudo usermod -a -G socklog $USER

	# configure fonts
	install_msg "Configuring system fonts config"
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
	sudo ln -sf /usr/share/fontconfig/conf.avail/50-user.conf /etc/fonts/conf.d/
	# sudo ln -sf /usr/share/fontconfig/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/

	sudo xbps-reconfigure -f fontconfig
}

cleanup() {
	echo ""
}

########
# main #
########

main() {

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
echo ""
echo "Do you want to install extra applications? (yes/no):"
read ans
case $ans in
	yes|y|YES|Yes)
		echo ""
		. "$HOME/.config/yadm/bootstrap-void-extra.sh"
		echo ""
		;;
	*)
		echo ""
		echo "You can run bootstrap-void-extra.sh to install a more complete app package."
		echo ""
		echo ""
		;;
esac
}

main $@
