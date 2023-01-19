#!/bin/sh

if [ ! -d  "keys" ]
then
  mkdir keys
  chmod 700 keys
  cd keys

  ssh-keygen -N "" -b 256  -t ecdsa -f ssh_host_ecdsa_key
  ssh-keygen -N "" -b 1024 -t dsa -f ssh_host_dsa_key
  ssh-keygen -N "" -b 2048 -t rsa -f ssh_host_rsa_key
fi
