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

	link /media/data/yay $HOME/.cache/yay

	# symlinks to HOME
	link /media/data/Documents $HOME/Documents
	link /media/data/Downloads $HOME/Downloads
	link /media/data/Pictures $HOME/Pictures

	link /media/data/Music $HOME/Music

	link /media/data/myfiles/.mozilla $HOME/.mozilla
	link /media/data/myfiles/ssh_key/.ssh $HOME/.ssh

	# symlinks to .config
	link /media/data/myfiles/BraveSoftware $HOME/.config/BraveSoftware
	link /media/data/retroarch $HOME/.config/retroarch
	link /media/data/myfiles/transmission-daemon $HOME/.config/transmission-daemon
}

create_symlinks
