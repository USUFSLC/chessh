#!/usr/bin/bash

export $(cat ~/.env | xargs)

chessh_source="https://github.com/Simponic/chessh"
chessh_path="$HOME/src/chessh"

# Grab deps
[ "$(which git)" != "" ] || sudo apt install -y git
if [ "$(which docker)" = "" ]
then
	curl -sSL https://get.docker.com | sh
fi

# Checkout source
if [ ! -d $chessh_path ]
then
	mkdir -p $chessh_path
	cd $chessh_path
	git init
	git remote add origin $chessh_source
	git pull origin
	git checkout main
	git config pull.rebase true
else
	cd $chessh_path
	git pull origin main
fi

# Build
cd $chessh_path
[ -d "$chessh_path/priv/keys" ] && cp ~/keys/* "$chessh_path/priv/keys/" || cp -r ~/keys "$chessh_path/priv"
sudo docker build . -t chessh/server

# Systemd service
cd $HOME
sudo mv chessh.service /etc/systemd/system/chessh.service
sudo systemctl daemon-reload
sudo systemctl enable chessh
sudo systemctl stop chessh
sudo systemctl start chessh
