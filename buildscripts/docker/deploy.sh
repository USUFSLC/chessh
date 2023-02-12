#!/bin/bash

datestamp=$(date +%Y%m%d-%H%M)
env_file=../../.env.prod
project_name=chessh
container_names=("chessh-redis" "chessh-database" "chessh-server" "chessh-frontend")

export $(cat $env_file | xargs)

for name in ${container_names[@]}; do
    docker stop $name
    docker rm $name
done

docker network ls | grep -q $project_name || docker network create --driver bridge $project_name
docker volume ls | grep -q $project_name-redisdata || docker volume create $project_name-redisdata

docker run \
	     -d \
	     --restart unless-stopped \
	     --env-file $env_file \
	     --network $project_name \
	     --name $project_name-redis \
	     --net-alias redis \
	     --volume $project_name-redisdata:/data/ \
	     redis

docker volume ls | grep -q $project_name-pgdata || docker volume create $project_name-pgdata
docker run \
       -d \
       --restart unless-stopped \
       --env-file $env_file \
       --network $project_name \
       --name $project_name-database \
       --net-alias database \
       --volume $project_name-pgdata:/var/lib/postgresql/data/ \
       postgres

docker run \
       -d \
       --restart unless-stopped \
       --env-file $env_file \
       --network $project_name \
       --name $project_name-server \
       --publish "${HOST}:${SSH_PORT}:${SSH_PORT}/tcp" \
       --net-alias server \
       chessh/server

docker run \
       -d \
       --restart unless-stopped \
       --env-file $env_file \
       --network $project_name \
       --name $project_name-frontend \
       --publish "${HOST}:${WEB_PORT}:80/tcp" \
       --net-alias frontend \
       chessh/frontend
