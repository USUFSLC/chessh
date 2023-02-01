#!/bin/bash

env_file=../../.env.prod

export $(cat $env_file | xargs) 

docker build ../.. -t chessh/server

docker build \
 --build-arg REACT_APP_DISCORD_OAUTH=${REACT_APP_DISCORD_OAUTH} \
 --build-arg REACT_APP_SSH_SERVER=${REACT_APP_SSH_SERVER} \
 --build-arg REACT_APP_SSH_PORT=${REACT_APP_SSH_PORT} \
 ../../front -t chessh/frontend 
