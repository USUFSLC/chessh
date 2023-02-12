#!/usr/bin/bash

export $(cat ~/.env | xargs)

chessh_source="https://github.com/Simponic/chessh"
chessh_path="$HOME/src/chessh"
build_output="/var/www/html/chessh_front"
nginx_site="/etc/nginx/sites-enabled/chessh_front.conf"
front_port=3000
nginx_conf="
server {
	listen ${front_port};
	listen [::]:${front_port};

	location / {
		root ${build_output};
		index index.html;
		try_files \$uri \$uri/ /index.html;
	}
}
"

# Grab deps
if [ $(which node) == "" ]
then
	  curl -sSL https://deb.nodesource.com/setup_16.x | sudo bash -
	  sudo apt install -y nodejs
fi
[ "$(which git)" != "" ] || sudo apt install -y git
[ "$(which nginx)" != "" ] || sudo apt install -y nginx

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
cd $chessh_path/front
npm ci
npm run build

# Copy to nginx root
sudo rm -rf $build_output
sudo mkdir -p $build_output
sudo cp -r $chessh_path/front/build/* $build_output
sudo chown -R www-data $build_output

# Copy nginx config
echo "$nginx_conf" | sudo tee $nginx_site

# Restart nginx
sudo systemctl restart nginx
