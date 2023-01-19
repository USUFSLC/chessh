#!/bin/bash

datestamp=$(date +%Y%m%d-%H%M)
env_file=.env.prod
project_name=chessh
port=8080
host=127.0.0.1

container_names=("chessh-database" "chessh-server" "chessh-frontend")

for name in ${container_names[@]}; do
  docker stop $name
  docker rm $name
done

# Create network for chessh
docker network ls | grep -q $project_name || docker network create --driver bridge $project_name

# Start postgres container
# Firstly create pg volume if it does not exist
docker volume ls | grep -q $project_name-pgdata || docker volume create $project_name-pgdata

# Then run the pg container
docker run \
	-d \
	--restart unless-stopped \
	--env-file $env_file \
	--network $project_name \
	--name $project_name-database \
	--net-alias database \
	--volume $project_name-pgdata:/var/lib/postgresql/data/ \
	postgres

# Start backend container
# Check if running; if so, stop, and rename
docker run \
	-d \
	--restart unless-stopped \
	--env-file $env_file \
	--network $project_name \
	--name $project_name-server \
	--net-alias server \
  chessh/server

# Start frontend container
# Check if running; if so, stop, and rename
docker run \
	-d \
	--restart unless-stopped \
	--env-file $env_file \
	--network $project_name \
	--name $project_name-frontend \
  --publish "${host}:${port}:80/tcp" \
	--net-alias frontend \
  chessh/frontend
