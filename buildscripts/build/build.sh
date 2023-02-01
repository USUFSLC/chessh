#!/usr/bin/bash

frontend_port=3000
server_port=8080
ssh_port=34355

frontend_node_ids=(2)
server_node_ids=(4 5 6)

build_dir="${HOME}/src/chessh/buildscripts/build"

server_name="chessh.linux.usu.edu"
erlang_hosts_file="${build_dir}/.hosts.erlang"
load_balancer_nginx_site_file="/etc/nginx/sites-enabled/${server_name}.conf"
ha_proxy_cfg_file="/etc/haproxy/haproxy.cfg"
ssl_cert_path="/etc/letsencrypt/live/${server_name}"
certbot_webroot_path="/var/www/html/${server_name}"
load_balancer_nginx_site="
upstream frontend {
	$(printf "server 192.168.100.%s:${frontend_port};\n" ${frontend_node_ids[@]})
}

upstream api {
	$(printf "server 192.168.100.%s:${server_port};\n" ${server_node_ids[@]})
}

server {
	default_type  application/octet-stream;

	server_name ${server_name};

	listen 443 ssl;
	ssl_certificate ${ssl_cert_path}/fullchain.pem;
	ssl_certificate_key ${ssl_cert_path}/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

	location ~ /.well-known {
		allow all;
		default_type "text/plain";
		alias ${certbot_webroot_path};
	}	

	location /api/ {
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_pass http://api/;
	}

	location / {
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_pass http://frontend/;
	}
}

server {
	if (\$host = ${server_name}) {
		return 301 https://\$host\$request_uri;
	}

	server_name ${server_name};
	listen 80;
	return 404;
}
"

ha_proxy_cfg="
global
	log /dev/log 	local0
	log /dev/log	local1 notice
	maxconn 2500
	user haproxy
	group haproxy
	daemon
defaults
	log 	global
	mode	tcp
	timeout connect 10s
	timeout client 36h
	timeout server 36h
	option 	dontlognull
listen ssh
	bind 	0.0.0.0:${ssh_port}
	balance	leastconn
	mode	tcp

$(echo "${server_node_ids[@]}" | python3 -c "print(\"\\n\".join([f\"\\tserver pi{i} 192.168.100.{i}:${ssh_port} check inter 30s fall 5 rise 1 \" for i in input().split()]))")
"

ssh_opts="-oStrictHostKeyChecking=no"

function make_pi_node_conn_str() {
    echo "pi$(printf "%04d" $1)@192.168.100.${1}"
}

function copy_ssh_keys() {
    if [ ! -d  "${build_dir}/keys" ]
    then
        mkdir "${build_dir}/keys"
        chmod 700 "${build_dir}/keys"
        cd "${build_dir}/keys"

        ssh-keygen -N "" -b 256  -t ecdsa -f ssh_host_ecdsa_key
        ssh-keygen -N "" -b 1024 -t dsa -f ssh_host_dsa_key
        ssh-keygen -N "" -b 2048 -t rsa -f ssh_host_rsa_key
    fi
    for node_id in "${server_node_ids[@]}"
    do
        node_conn=$(make_pi_node_conn_str $node_id)
        scp -r $ssh_opts "${build_dir}/keys" $node_conn:~
    done
}

function reload_loadbalancer_conf() {
    dead_files=("/etc/nginx/sites-enabled/default" "/etc/nginx/nginx.conf" "$load_balancer_nginx_site_file" "$ha_proxy_cfg_file")
    for file in "${dead_files[@]}"
    do
        [ -e $file ] && sudo rm $file
    done
    
    sudo cp "${build_dir}/nginx.conf" /etc/nginx/nginx.conf
    echo $load_balancer_nginx_site | sudo tee $load_balancer_nginx_site_file
    
    sudo systemctl restart nginx

    printf "$ha_proxy_cfg" | sudo tee $ha_proxy_cfg_file

    sudo systemctl restart haproxy
}

function build_frontend() {
    node_id=$1
    node_conn=$(make_pi_node_conn_str $node_id)
    
    scp $ssh_opts "${build_dir}/.env" $node_conn:~
    scp $ssh_opts "${build_dir}/build_front.sh" $node_conn:~/
    ssh $ssh_opts $node_conn "~/build_front.sh"    
}

function build_frontend_nodes() {
    for node_id in "${frontend_node_ids[@]}"
    do
        build_frontend $node_id
    done
}

function build_server() {
    node_id=$1
    node_conn=$(make_pi_node_conn_str $node_id)
    temp_file=$(mktemp)
    
    cp "${build_dir}/.env" $temp_file
    printf "\nNODE_ID=$node_conn\nRELEASE_NODE=chessh@192.168.100.${node_id}\n" >> $temp_file
    scp $ssh_opts $temp_file $node_conn:~/.env

    cp "${build_dir}/chessh.service" $temp_file
    sed -i "s/\$BUILD_ENV/\/home\/pi$(printf "%04d" $1)\/.env/" $temp_file
    scp -r $ssh_opts $temp_file $node_conn:~/chessh.service
    
    scp $ssh_opts "${build_dir}/build_server.sh" $node_conn:~/

    scp $ssh_opts $erlang_hosts_file $node_conn:~/

    ssh $ssh_opts $node_conn "~/build_server.sh"
}

function build_server_nodes() {
    copy_ssh_keys
    printf "'192.168.100.%s'\n" ${server_node_ids[@]} > $erlang_hosts_file
    
    for node_id in "${server_node_ids[@]}"
    do
        build_server $node_id
    done
}

reload_loadbalancer_conf
build_server_nodes
#build_frontend_nodes
