#!/bin/bash

env_file=.env.prod
started_in=$PWD

export $(cat $env_file | xargs) 

cd front
docker build \
 --build-arg REACT_APP_GITHUB_OAUTH=${REACT_APP_GITHUB_OAUTH} \
 --build-arg REACT_APP_SSH_SERVER=${REACT_APP_SSH_SERVER} \
 --build-arg REACT_APP_SSH_PORT=${REACT_APP_SSH_PORT} \
 . -t chessh/frontend 

cd $started_in
docker build . -t chessh/server
