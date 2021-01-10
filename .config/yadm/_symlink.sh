#!/bin/bash

# Creates a symlink for item1 to item2, deleting destination if it exists
link() {
	if [ -d $1 ] ; then
		status='!'
		[ ! -e $2 ] || rm -rf $2
		ln -sfv $1 $2 && status='ok'
		#install_msg "$status - Symlinking $1 to $2"
	fi
}

create_symlinks() {
	mkdir -p $HOME/.cache
	mkdir -p $HOME/.config

	link /mnt/data/yay $HOME/.cache/yay

	# symlinks to HOME
	link /mnt/data/Documents $HOME/Documents
	link /mnt/data/Downloads $HOME/Downloads
	link /mnt/data/Pictures $HOME/Pictures

	link /mnt/data/Music $HOME/Music

	link /mnt/data/myfiles/.mozilla $HOME/.mozilla
	link /mnt/data/myfiles/ssh_key/.ssh $HOME/.ssh

	# symlinks to .config
	link /mnt/data/myfiles/BraveSoftware $HOME/.config/BraveSoftware
	link /mnt/data/retroarch $HOME/.config/retroarch
	link /mnt/data/myfiles/transmission-daemon $HOME/.config/transmission-daemon
}

create_symlinks
